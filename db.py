import psycopg2
import psycopg2.extras


def connect():
    """
    Établit une connexion à la base de données PostgreSQL.
    Retourne la connexion avec un NamedTupleCursor pour un accès plus lisible.
    """
    conn = psycopg2.connect(
        host="localhost",         
        dbname="ines",       
        password="",  
        cursor_factory = psycopg2.extras.NamedTupleCursor
        )
    conn.autocommit = True  
    return conn