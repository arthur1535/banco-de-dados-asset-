from flask import Flask
from db_interface import list_triggers

app = Flask(__name__)

@app.route("/")
def trigger_page():
    rows = list_triggers()
    table_rows = "".join(
        f"<tr><td>{table}</td><td>{name}</td><td>{timing}</td><td>{event}</td><td><pre>{stmt}</pre></td></tr>"
        for table, name, timing, event, stmt in rows
    )
    html = f"""
    <html>
    <head><title>Triggers</title></head>
    <body>
        <h1>Triggers</h1>
        <table border='1' cellpadding='5'>
            <tr><th>Table</th><th>Name</th><th>Timing</th><th>Event</th><th>Statement</th></tr>
            {table_rows}
        </table>
    </body>
    </html>
    """
    return html


if __name__ == "__main__":
    app.run(debug=True)
