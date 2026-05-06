# task-loop Workflow

1. Read the task's **What to do** section completely before writing any code.
2. Read every file listed under **Files** to understand current state.
3. Implement the described change. Stay within the listed files only —
   do not touch other files unless the task explicitly permits it.
4. Run the **Acceptance Criterion** command exactly as written.
5. PASS: report `TASK [NNN] PASSED — [one-line summary]`.
   Commit: `git add -A && git commit -m "task NNN: [title]"`
6. FAIL: report `TASK [NNN] FAILED — [criterion] — [observed] — [error text]`.
   Do not commit. Do not silently attempt a fix. Report and stop.
7. Never begin the next task without an explicit instruction.