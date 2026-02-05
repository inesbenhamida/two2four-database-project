Two2Four - Gestion de Mobilité Urbaine
Two2Four est une application web complète permettant la gestion d'une flotte de vélos et de voitures en libre-service dans les zones urbaines. Ce projet a été réalisé dans le cadre du module de Base de Données.

Auteure :
Inès Benhamida

Technologies utilisées :
Backend : Flask (Python)

Base de données : PostgreSQL

Frontend : HTML, CSS (via des templates et fichiers statiques)

Fonctionnalités principales : 
Consultation en temps réel : Affichage des véhicules disponibles et des emplacements libres par station.

Système de réservation : Possibilité pour les abonnés de réserver un véhicule ou une place de stationnement avec des limites de durée (1h pour les vélos, 3h pour les voitures).

Historique complet : Suivi des trajets passés et des réservations d'emplacements.

Signalement : Fonctionnalité permettant de déclarer un véhicule en panne pour maintenance.

Statistiques : Analyse du taux d'utilisation journalier des stations et identification des zones fréquemment vides.

Installation et Lancement : 
Base de données : Importez le fichier dump.sql dans votre instance PostgreSQL pour créer les tables (abonne, vehicule, station, etc.).

Configuration : Modifiez les identifiants de connexion (host, dbname, password) dans le fichier db.py pour qu'ils correspondent à votre environnement local.

Lancement de l'application : Ouvrez un terminal dans le dossier du projet et lancez le serveur Flask avec la commande suivante :
python3 main.py
