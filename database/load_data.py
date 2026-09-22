"""Load CSVs by column name, validate keys, then execute all SQL examples."""
from pathlib import Path
import sqlite3
import pandas as pd
ROOT = Path(__file__).resolve().parents[1]

def main():
    with sqlite3.connect(ROOT / "covid_vacinacao.db") as con:
        con.executescript((ROOT / "database/schema.sql").read_text())
        con.execute("PRAGMA foreign_keys=ON")
        for table, filename, keys in [("covid_casos", "covid_casos.csv", ["data", "estado"]),
                                      ("vacinacao", "vacinacao.csv", ["data", "estado", "faixa_etaria"])]:
            df = pd.read_csv(ROOT / "data" / filename)
            if df[keys].isna().any().any() or df.duplicated(keys).any():
                raise ValueError(f"Invalid business key: {table}")
            cols = [row[1] for row in con.execute(f"PRAGMA table_info({table})") if row[1] != "id"]
            if df[cols].drop(columns=["data", "estado", "faixa_etaria"], errors="ignore").isna().any().any():
                raise ValueError(f"Missing numeric values: {table}")
            df[cols].to_sql(table, con, if_exists="append", index=False)
        assert not con.execute("PRAGMA foreign_key_check").fetchall()
        checked = 0
        for p in sorted((ROOT / "queries").glob("*.sql")):
            statement = ""
            for line in p.read_text().splitlines(True):
                statement += line
                if sqlite3.complete_statement(statement):
                    con.execute(statement).fetchall()
                    checked += 1
                    statement = ""
        print(f"Loaded and validated: {checked} SQL statements executed.")
if __name__ == "__main__":
    main()
