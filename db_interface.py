import os
import psycopg2


def get_connection():
    return psycopg2.connect(
        host=os.getenv('PGHOST', 'localhost'),
        port=os.getenv('PGPORT', '5432'),
        dbname=os.getenv('PGDATABASE', 'volt_capital'),
        user=os.getenv('PGUSER', 'postgres'),
        password=os.getenv('PGPASSWORD', '')
    )


def list_consultas(limit=10):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT consulta_id, usuario_id, cliente_id, descricao "
        "FROM volt.consultas ORDER BY consulta_id LIMIT %s;",
        (limit,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows


if __name__ == "__main__":
    for row in list_consultas():
        print(row)
