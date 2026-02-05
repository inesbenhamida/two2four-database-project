from flask import Flask, render_template, request, redirect, url_for, session, flash
import db
from datetime import datetime
import psycopg2.extras
import secrets
from werkzeug.security import check_password_hash
from werkzeug.security import generate_password_hash
from functools import wraps
import random
import string
from datetime import datetime, timedelta


app = Flask(__name__)
app.secret_key =  secrets.token_hex(16)




def login_required(f):
    """
    Décorateur pour restreindre l'accès aux utilisateurs connectés.
    Redirige vers la page de connexion si l'utilisateur n'est pas authentifié.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if "id_abonne" not in session:
            return redirect(url_for("connexion"))
        return f(*args, **kwargs)
    return decorated_function


@app.route("/")
def accueil():
    """
    Page d'accueil du site Vélib.
    Affiche un message si une action précédente a été réalisée avec succès.

    """
    message = request.args.get("success")
    return render_template("accueil.html",message=message)


@app.route("/stations", methods=["GET"])
def stations():
    """
    Affiche la liste des stations disponibles.
    Permet de filtrer par ville si une ville est sélectionnée.
    Affiche les informations sur les véhicules disponibles et les emplacements libres.
    """
    ville_selectionnee = request.args.get("ville")  

    with db.connect() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
            cur.execute("SELECT DISTINCT ville FROM station ORDER BY ville;")
            villes = [row.ville for row in cur.fetchall()]

            if ville_selectionnee:
                cur.execute("""
                    SELECT 
                        s.id_station,
                        s.ville,
                        s.adresse,
                        COUNT(DISTINCT v.id_vehicule) FILTER (WHERE v.statut = 'Disponible') AS vehicules_disponibles,
                        COUNT(DISTINCT e.id_emplacement) FILTER (
                            WHERE e.id_emplacement NOT IN (
                                SELECT id_emplacement 
                                FROM reserveplace 
                                WHERE reservation_emplacement + INTERVAL '1 hour' > NOW()
                            )
                        ) AS emplacements_libres
                    FROM station s
                    LEFT JOIN vehicule v ON s.id_station = v.id_station
                    LEFT JOIN emplacement e ON s.id_station = e.id_station
                    WHERE s.ville = %s
                    GROUP BY s.id_station, s.ville, s.adresse
                    ORDER BY s.adresse;
                """, (ville_selectionnee,))
            else:
                cur.execute("""
                    SELECT 
                        s.id_station,
                        s.ville,
                        s.adresse,
                        COUNT(DISTINCT v.id_vehicule) FILTER (WHERE v.statut = 'Disponible') AS vehicules_disponibles,
                        COUNT(DISTINCT e.id_emplacement) FILTER (
                            WHERE e.id_emplacement NOT IN (
                                SELECT id_emplacement 
                                FROM reserveplace 
                                WHERE reservation_emplacement + INTERVAL '1 hour' > NOW()
                            )
                        ) AS emplacements_libres
                    FROM station s
                    LEFT JOIN vehicule v ON s.id_station = v.id_station
                    LEFT JOIN emplacement e ON s.id_station = e.id_station
                    GROUP BY s.id_station, s.ville, s.adresse
                    ORDER BY s.ville, s.adresse;
                """)
            stations = cur.fetchall()

    return render_template("stations.html", stations=stations, villes=villes, ville_selectionnee=ville_selectionnee)


@app.route("/reservations", methods=["GET", "POST"])
@login_required
def reservations():
    """
    Gère les réservations de véhicules et d'emplacements.
    - Affiche les stations, véhicules disponibles, et emplacements libres.
    - Permet de créer une nouvelle réservation.
    - Valide les conflits de réservation et les contraintes spécifiques.
    """
    id_abonne = session["id_abonne"]
    abonne_nom_complet = f"{session['prenom_abonne']} {session['nom_abonne']}"

    nettoyer_reservations_expirees()

    stations, vehicules, emplacements, reservations = [], [], [], []
    reservations_imminentes = []

    station_id = request.args.get("station")
    type_reservation = request.args.get("type_reservation")
    debut_reservation = request.args.get("debut")
    fin_reservation = request.args.get("fin")

    now = datetime.now()

    with db.connect() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
            cur.execute("""
                SELECT id_station, ville, adresse
                FROM station
                ORDER BY ville, adresse;
            """)
            stations = cur.fetchall()

            cur.execute("""
            SELECT 'Véhicule' AS type, v.modele AS details, r.debut_reservation AS debut, 
                r.fin_reservation AS fin, r.id_vehicule AS id_reservation,
                s.adresse AS station_adresse, s.ville AS station_ville
            FROM reserve r
            JOIN vehicule v ON r.id_vehicule = v.id_vehicule
            JOIN station s ON v.id_station = s.id_station
            WHERE r.id_abonne = %s
            UNION ALL
            SELECT 'Emplacement' AS type, e.type_emplacement || ' à Station ' || e.id_station AS details,
                rp.reservation_emplacement AS debut, 
                rp.reservation_emplacement + INTERVAL '1 hour' AS fin,
                rp.id_emplacement AS id_reservation,
                s.adresse AS station_adresse, s.ville AS station_ville
            FROM reserveplace rp
            JOIN emplacement e ON rp.id_emplacement = e.id_emplacement
            JOIN station s ON e.id_station = s.id_station
            WHERE rp.id_abonne = %s;
        """, (id_abonne, id_abonne))

            reservations = cur.fetchall()

            reservations_imminentes = [
                res for res in reservations if (res.fin - now).total_seconds() <= 600
            ]

            if station_id and type_reservation and debut_reservation:
                debut_dt = datetime.fromisoformat(debut_reservation)
                if debut_dt >= now:
                    if type_reservation == "vehicule":
                        cur.execute("""
                            SELECT v.id_vehicule, v.modele, v.categorie
                            FROM vehicule v
                            WHERE v.id_station = %s AND v.statut != 'En réparation'
                            AND NOT EXISTS (
                                SELECT 1 FROM reserve r
                                WHERE r.id_vehicule = v.id_vehicule 
                                  AND (%s, %s) OVERLAPS (r.debut_reservation, r.fin_reservation)
                            );
                        """, (station_id, debut_reservation, fin_reservation))
                        vehicules = cur.fetchall()
                    elif type_reservation == "emplacement":
                        cur.execute("""
                            SELECT e.id_emplacement, e.type_emplacement
                            FROM emplacement e
                            WHERE e.id_station = %s AND NOT EXISTS (
                                SELECT 1 FROM reserveplace rp
                                WHERE rp.id_emplacement = e.id_emplacement
                                AND (%s, %s) OVERLAPS (
                                    rp.reservation_emplacement,
                                    rp.reservation_emplacement + INTERVAL '1 hour'
                                )
                            );
                        """, (station_id, debut_dt, debut_dt))
                        emplacements = cur.fetchall()

    if request.method == "POST":
        station_id = request.form.get("station")
        type_reservation = request.form.get("type_reservation")
        debut_reservation = request.form.get("debut")
        fin_reservation = request.form.get("fin")
        id_vehicule = request.form.get("vehicule")
        id_emplacement = request.form.get("emplacement")

        if not station_id or not type_reservation or not debut_reservation:
            flash("Veuillez remplir tous les champs obligatoires.", "error")
            return redirect(url_for("reservations"))

        debut_dt = datetime.fromisoformat(debut_reservation)
        if type_reservation == "vehicule":
            if not fin_reservation:
                flash("Veuillez indiquer une date de fin pour les véhicules.", "error")
                return redirect(url_for("reservations"))

            fin_dt = datetime.fromisoformat(fin_reservation)
            if fin_dt <= debut_dt:
                flash("La date de fin doit être après la date de début.", "error")
                return redirect(url_for("reservations"))

            duree_seconds = (fin_dt - debut_dt).total_seconds()
            with db.connect() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT categorie FROM vehicule WHERE id_vehicule = %s;", (id_vehicule,))
                    categorie = cur.fetchone().categorie
            if categorie == 'Vélo' and duree_seconds > 3600:
                flash("Un vélo ne peut être emprunté que pour une heure maximum.", "error")
                return redirect(url_for("reservations"))
            if categorie == 'Voiture' and duree_seconds > 10800:
                flash("Une voiture ne peut être empruntée que pour trois heures maximum.", "error")
                return redirect(url_for("reservations"))
        elif type_reservation == "emplacement":
            fin_dt = debut_dt + timedelta(hours=1)

        with db.connect() as conn:
            with conn.cursor() as cur:
                if type_reservation == "vehicule":
                    cur.execute("""
                        SELECT 1 FROM reserve
                        WHERE id_abonne = %s
                        AND (%s, %s) OVERLAPS (debut_reservation, fin_reservation);
                    """, (id_abonne, debut_dt, fin_dt))
                elif type_reservation == "emplacement":
                    cur.execute("""
                        SELECT 1 FROM reserveplace
                        WHERE id_abonne = %s
                        AND (%s, %s) OVERLAPS (reservation_emplacement, reservation_emplacement + INTERVAL '1 hour');
                    """, (id_abonne, debut_dt, fin_dt))

                if cur.fetchone():
                    flash(f"Vous avez déjà une réservation {type_reservation} qui chevauche cette plage horaire.", "error")
                    return redirect(url_for("reservations"))

                if type_reservation == "vehicule":
                    cur.execute("""
                        INSERT INTO reserve (id_vehicule, id_abonne, debut_reservation, fin_reservation)
                        VALUES (%s, %s, %s, %s);
                    """, (id_vehicule, id_abonne, debut_dt, fin_dt))
                    cur.execute("""
                        UPDATE vehicule SET statut = 'Occupé' WHERE id_vehicule = %s;
                    """, (id_vehicule,))
                    flash("Réservation de véhicule enregistrée avec succès.", "success")
                elif type_reservation == "emplacement":
                    cur.execute("""
                        INSERT INTO reserveplace (id_abonne, id_emplacement, reservation_emplacement)
                        VALUES (%s, %s, %s);
                    """, (id_abonne, id_emplacement, debut_dt))
                    flash("Réservation d'emplacement enregistrée avec succès.", "success")

            conn.commit()

        return redirect(url_for("reservations"))

    return render_template(
        "reservations.html",
        stations=stations,
        vehicules=vehicules,
        emplacements=emplacements,
        reservations=reservations,
        reservations_imminentes=reservations_imminentes,
        abonne_nom_complet=abonne_nom_complet,
    )


@app.route("/reservations/signaler/<int:id_vehicule>", methods=["POST"])
@login_required
def signaler_vehicule(id_vehicule):
    """
    Permet à un abonné de signaler un véhicule comme étant hors-service.
    Vérifie si l'abonné a une réservation active pour le véhicule signalé.
    """
    id_abonne = session["id_abonne"]

    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 1
                FROM reserve
                WHERE id_vehicule = %s AND id_abonne = %s AND fin_reservation > NOW();
            """, (id_vehicule, id_abonne))

            if not cur.fetchone():
                flash("Vous ne pouvez signaler qu'un véhicule lié à votre réservation active.", "error")
                return redirect(url_for("reservations"))

            cur.execute("""
                UPDATE vehicule
                SET statut = 'En réparation'
                WHERE id_vehicule = %s;
            """, (id_vehicule,))
            conn.commit()

    flash("Le véhicule a été signalé comme hors-service.", "success")
    return redirect(url_for("reservations"))


@app.route("/vehicules")
def vehicules():
    """
    Affiche la liste des véhicules disponibles, avec des filtres pour station et catégorie.
    """
    station_selectionnee = request.args.get('station', '')
    categorie_selectionnee = request.args.get('categorie', '')

    query = """
        SELECT v.id_vehicule, v.categorie, v.numimmat, v.modele, v.statut, s.ville, s.adresse
        FROM vehicule v
        JOIN station s ON v.id_station = s.id_station
    """
    params = []

    filtres = []
    if station_selectionnee:
        filtres.append("s.id_station = %s")
        params.append(station_selectionnee)
    if categorie_selectionnee:
        filtres.append("v.categorie = %s")
        params.append(categorie_selectionnee)

    if filtres:
        query += " WHERE " + " AND ".join(filtres)

    query += " ORDER BY s.ville, s.adresse, v.categorie, v.modele;"

    with db.connect() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
            cur.execute("""
                SELECT id_station, ville, adresse
                FROM station
                ORDER BY ville, adresse;
            """)
            stations = cur.fetchall()

            cur.execute(query, params)
            vehicules = cur.fetchall()

    return render_template(
        "vehicules.html",
        vehicules=vehicules,
        stations=stations,
        station_selectionnee=station_selectionnee,
        categorie_selectionnee=categorie_selectionnee
    )



@app.route("/annuler_reservation_vehicule/<int:id_vehicule>", methods=["POST"])
@login_required
def annuler_reservation_vehicule(id_vehicule):
    """
    Permet à un abonné d'annuler une réservation de véhicule.
    Met à jour l'état du véhicule s'il n'est pas en réparation.
    """
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT statut
                FROM vehicule
                WHERE id_vehicule = %s;
            """, (id_vehicule,))
            vehicule = cur.fetchone()

            if not vehicule:
                flash("Véhicule introuvable.", "error")
                return redirect(url_for("reservations"))
            print(f"Statut actuel avant suppression : {vehicule.statut}")

            
            cur.execute("""
                DELETE FROM reserve
                WHERE id_vehicule = %s AND id_abonne = %s;
            """, (id_vehicule, session["id_abonne"]))

            if vehicule.statut != "En réparation":
                print(f"Met à jour le statut à 'Disponible' pour le véhicule {id_vehicule}")
                cur.execute("""
                    UPDATE vehicule
                    SET statut = 'Disponible'
                    WHERE id_vehicule = %s;
                """, (id_vehicule,))
            print(f"Le véhicule {id_vehicule} reste en réparation.")

            conn.commit()
            flash("Réservation annulée avec succès.", "success")

    return redirect(url_for("reservations"))


@app.route("/reservations/emplacement/annuler/<int:id_emplacement>", methods=["POST"])
@login_required
def annuler_reservation_emplacement(id_emplacement):
    """
    Permet à un abonné d'annuler une réservation d'emplacement.
    Supprime les réservations non expirées associées à l'abonné et à l'emplacement.
    """
    id_abonne = session["id_abonne"]

    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                DELETE FROM reserveplace
                WHERE id_emplacement = %s AND id_abonne = %s AND reservation_emplacement + INTERVAL '1 hour' > NOW();
            """, (id_emplacement, id_abonne))
            conn.commit()

    flash("Réservation d'emplacement annulée avec succès.", "success")
    return redirect(url_for("reservations"))

def nettoyer_reservations_expirees():
    """
    Supprime les réservations expirées de la base de données.
    Met à jour les états des véhicules et emplacements devenus disponibles.
    Archive les réservations dans l'historique.
    """
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO historique_vehicules (id_abonne, modele, categorie, debut_reservation, fin_reservation)
                SELECT r.id_abonne, v.modele, v.categorie, r.debut_reservation, r.fin_reservation
                FROM reserve r
                JOIN vehicule v ON r.id_vehicule = v.id_vehicule
                WHERE r.fin_reservation < NOW();
            """)

            cur.execute("""
                INSERT INTO historique_emplacements (id_abonne, type_emplacement, id_station, debut_reservation, fin_reservation)
                SELECT rp.id_abonne, e.type_emplacement, e.id_station, rp.reservation_emplacement,
                       rp.reservation_emplacement + INTERVAL '1 hour'
                FROM reserveplace rp
                JOIN emplacement e ON rp.id_emplacement = e.id_emplacement
                WHERE rp.reservation_emplacement + INTERVAL '1 hour' < NOW();
            """)

            cur.execute("""
                DELETE FROM reserve
                WHERE fin_reservation < NOW();
            """)
            cur.execute("""
                DELETE FROM reserveplace
                WHERE reservation_emplacement + INTERVAL '1 hour' < NOW();
            """)

            cur.execute("""
                UPDATE vehicule
                SET statut = 'Disponible'
                WHERE statut != 'En réparation'
                AND id_vehicule NOT IN (
                    SELECT id_vehicule FROM reserve
                );
            """)

            conn.commit()





@app.route("/statistiques")
def statistiques():
    """
    Affiche des statistiques :
    - Taux d'utilisation journalier des stations
    - Disponibilités des véhicules
    - Stations fréquemment vides
    """
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id_station, adresse, ville, jour_semaine, nombre_reservations
                FROM stats_reservations
                WHERE nombre_reservations > 0
                ORDER BY id_station, jour_semaine;
            """)
            stats_journalieres = cur.fetchall()

            cur.execute("""
                SELECT id_station, adresse, ville, vehicules_disponibles
                FROM stats_reservations
                GROUP BY id_station, adresse, ville, vehicules_disponibles
                ORDER BY id_station;
            """)
            disponibilites = cur.fetchall()

            cur.execute("""
                SELECT id_station, adresse, ville, vehicules_disponibles
                FROM stats_reservations
                WHERE vehicules_disponibles < 3
                GROUP BY id_station, adresse, ville, vehicules_disponibles
                ORDER BY vehicules_disponibles ASC;
            """)
            stations_vides = cur.fetchall()

    return render_template(
        "statistiques.html",
        stats_journalieres=stats_journalieres,
        disponibilites=disponibilites,
        stations_vides=stations_vides
    )


@app.route("/abonnes")
def abonnes():
    """
    Affiche la liste des abonnés avec leurs informations personnelles (nom, prénom, email, téléphone).
    """
    with db.connect() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
                cur.execute("""
                    SELECT id_abonne, nom, prenom, email, num_tel 
                    FROM abonne
                    ORDER BY nom, prenom;
                     """)
                abonnes = cur.fetchall()

    return render_template("abonnes.html", abonnes=abonnes)



def generer_numero_carte():
    return "CARD" + ''.join(random.choices(string.digits, k=6))


@app.route("/abonnes/ajouter", methods=["GET", "POST"])
def ajouter_abonne():
    """
    Permet d'ajouter un nouvel abonné à la base de données.
    - Génère un numéro de carte unique pour chaque abonné.
    - Hache le mot de passe avant de le stocker.
    """
    if request.method == "POST":
        nom = request.form.get("nom")
        prenom = request.form.get("prenom")
        email = request.form.get("email")
        num_tel = request.form.get("num_tel") or None
        mdp = request.form.get("mdp")

        if not nom or not prenom or not email or not mdp:
            return "Erreur : Tous les champs obligatoires doivent être remplis.", 400

        hashed_mdp = generate_password_hash(mdp, method='pbkdf2:sha256')
 
        while True:
            num_carte = generer_numero_carte()
            with db.connect() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1 FROM abonne WHERE num_carte = %s;", (num_carte,))
                    if not cur.fetchone():
                        break

        with db.connect() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO abonne (nom, prenom, email, num_tel, mdp,num_carte)
                    VALUES (%s, %s, %s, %s, %s,%s);
                """, (nom, prenom, email, num_tel, hashed_mdp,num_carte))

        return redirect(url_for("abonnes"))

    return render_template("ajouter_abonne.html")

@app.route("/abonnes/supprimer/<int:id_abonne>")
def supprimer_abonne(id_abonne):
    """
    Supprime un abonné de la base de données en fonction de son identifiant.
    """
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM abonne WHERE id_abonne = %s;", (id_abonne,))

    return redirect(url_for("abonnes"))


@app.route("/abonnes/modifier/<int:id_abonne>", methods=["GET", "POST"])
def modifier_abonne(id_abonne):
    """
    Permet de modifier les informations d'un abonné existant.
    - Met à jour le mot de passe si un nouveau est fourni.
    - Sinon, met à jour uniquement les autres informations.
    """
    if request.method == "POST":
        nom = request.form.get("nom")
        prenom = request.form.get("prenom")
        email = request.form.get("email")
        num_tel = request.form.get("num_tel")
        mdp = request.form.get("mdp")

        with db.connect() as conn:
            with conn.cursor() as cur:
                if mdp :
                    hashed_mdp = generate_password_hash(mdp, method='pbkdf2:sha256')
                    cur.execute("""
                         UPDATE abonne
                        SET nom = %s, prenom = %s, email = %s, num_tel = %s, mdp = %s
                        WHERE id_abonne = %s;
                    """, (nom, prenom, email, num_tel, mdp, id_abonne))
                else :
                    cur.execute("""
                        UPDATE abonne
                        SET nom = %s, prenom = %s, email = %s, num_tel = %s
                        WHERE id_abonne = %s;
                    """, (nom, prenom, email, num_tel,hashed_mdp, id_abonne))

        
        return redirect(url_for("abonnes"))

    with db.connect() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
            cur.execute("SELECT * FROM abonne WHERE id_abonne = %s;", (id_abonne,))
            abonne = cur.fetchone()

    return render_template("modifier_abonne.html", abonne=abonne)



@app.route("/connexion", methods=["GET", "POST"])
def connexion():
    """
    Gère l'authentification des abonnés.
    - Vérifie les identifiants fournis (email et mot de passe).
    - Stocke les informations dans la session en cas de succès.
    """
    if request.method == "POST":
        email = request.form.get("email")
        mdp = request.form.get("mdp")

        if not email or not mdp:
            flash("Tous les champs sont obligatoires.", "error")
            return render_template("connexion.html")

        with db.connect() as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
                cur.execute("""
                    SELECT id_abonne, nom, prenom, mdp
                    FROM abonne
                    WHERE email = %s;
                """, (email,))
                abonne = cur.fetchone()

        if abonne:
            print(f"Debug: Abonné trouvé: {abonne}")
            is_password_correct = check_password_hash(abonne.mdp, mdp)
            print(f"Debug: Mot de passe vérifié: {is_password_correct}")

            if is_password_correct:
                session["id_abonne"] = abonne.id_abonne
                session["nom_abonne"] = abonne.nom
                session["prenom_abonne"] = abonne.prenom
                flash("Connexion réussie !", "success")
                return redirect(url_for("accueil"))
        else:
            print("Debug: Aucun abonné trouvé pour cet email.")

        flash("Identifiants invalides.", "error")
        return render_template("connexion.html")

    return render_template("connexion.html")


@app.route("/deconnexion")
def deconnexion():
    """
    Déconnecte l'utilisateur en supprimant ses informations de la session.
    Redirige vers la page d'accueil.
    """
    session.clear()  
    flash("Vous avez été déconnecté avec succès.", "success") 
    return redirect(url_for("accueil"))


@app.route("/historique", methods=["GET"])
@login_required
def historique():
    """
    Affiche l'historique des trajets et des réservations d'emplacements pour l'utilisateur connecté.
    Trie les réservations par date décroissante.
    """
    id_abonne = session["id_abonne"]

    with db.connect() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.NamedTupleCursor) as cur:
            cur.execute("""
                SELECT modele, categorie, debut_reservation, fin_reservation
                FROM historique_vehicules
                WHERE id_abonne = %s
                ORDER BY debut_reservation DESC;
            """, (id_abonne,))
            historique_vehicules = cur.fetchall()

            cur.execute("""
                SELECT type_emplacement, id_station, debut_reservation, fin_reservation
                FROM historique_emplacements
                WHERE id_abonne = %s
                ORDER BY debut_reservation DESC;
            """, (id_abonne,))
            historique_emplacements = cur.fetchall()

    return render_template(
        "historique.html",
        historique_vehicules=historique_vehicules,
        historique_emplacements=historique_emplacements
    )


if __name__ == '__main__':
    app.run(debug="True")
