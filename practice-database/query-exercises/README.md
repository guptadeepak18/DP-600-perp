# Query Exercises

This folder contains graded T-SQL query exercises based on the **Contoso Retail Analytics** practice database. Each exercise includes a question prompt and a collapsible solution block.

## Exercise Levels

| File | Level | Topics |
|---|---|---|
| [beginner-exercises.md](beginner-exercises.md) | Beginner | SELECT, WHERE, ORDER BY, GROUP BY, basic JOINs, aggregate functions |
| [intermediate-exercises.md](intermediate-exercises.md) | Intermediate | Window functions, CTEs, HAVING, subqueries, multi-table JOINs, CASE expressions |
| [advanced-exercises.md](advanced-exercises.md) | Advanced | COPY INTO, CTAS, cross-database queries, stored procedures, performance optimization, medallion architecture |

## How to Use

1. Make sure you have created the schema and loaded the seed data (see the [parent README](../README.md)).
2. Start with the **beginner** exercises and work your way up.
3. Try to write each query yourself before expanding the solution.
4. Run your query against the practice database to verify the results.

## Tips

- Read each question carefully — pay attention to sort order, column aliases, and filtering conditions.
- If you get stuck, review the schema in [`schemas/schema.sql`](../schemas/schema.sql) to understand table relationships.
- The advanced exercises cover Fabric-specific SQL features that are heavily weighted on the DP-600 exam.
