<%@page contentType="text/html" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="es">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sudoku</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
            .sudoku-grid {
                display: grid;
                grid-template-columns: repeat(9, minmax(0, 1fr));
                border: 3px solid #1e293b;
                transition: filter .25s
            }

            .sudoku-grid.locked {
                filter: blur(8px);
                pointer-events: none;
                user-select: none
            }

            .cell {
                aspect-ratio: 1;
                min-width: 0;
                border-right: 1px solid #cbd5e1;
                border-bottom: 1px solid #cbd5e1
            }

            .cell:nth-child(3n) {
                border-right: 3px solid #1e293b
            }

            .cell:nth-child(9n) {
                border-right: 0
            }

            .cell:nth-child(n+19):nth-child(-n+27),
            .cell:nth-child(n+46):nth-child(-n+54),
            .cell:nth-child(n+73):nth-child(-n+81) {
                border-bottom: 3px solid #1e293b
            }

            .cell:nth-child(n+73) {
                border-bottom: 0
            }

            .cell input {
                width: 100%;
                height: 100%;
                text-align: center;
                font-size: clamp(1.05rem, 4vw, 1.7rem);
                outline: none;
                transition: background .15s, box-shadow .15s
            }

            .cell input:focus {
                box-shadow: inset 0 0 0 3px #2563eb;
                position: relative;
                z-index: 1
            }

            .given input {
                background: #e2e8f0;
                color: #0f172a;
                font-weight: 800;
                cursor: not-allowed
            }

            .user input {
                background: #fff;
                color: #1d4ed8
            }

            .focused input {
                background: #eff6ff
            }

            .error input {
                background: #fee2e2 !important;
                color: #b91c1c !important;
                box-shadow: inset 0 0 0 2px #ef4444
            }
        </style>
    </head>

    <body class="min-h-screen bg-slate-100 text-slate-800">
        <main class="mx-auto max-w-5xl px-4 py-8">
            <section class="rounded-3xl bg-white p-5 shadow-xl sm:p-8">
                <div class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
                    <div>
                        <h1 class="text-4xl font-black text-slate-900">
                            Sudoku
                        </h1>
                        <p class="mt-1 text-slate-500">
                            Completa la cuadrícula usando los números del 1 al 9.
                        </p>
                    </div>
                    <div class="rounded-2xl bg-slate-900 px-5 py-3 text-center text-white">
                        <div class="text-xs uppercase tracking-widest text-slate-400">
                            Tiempo
                        </div>
                        <button id="startBtn" class="mt-1 rounded-lg bg-blue-500 px-5 py-2 font-bold hover:bg-blue-400">
                            Iniciar
                        </button>
                        <div id="timer" class="hidden font-mono text-3xl font-bold">
                            00:00
                        </div>

                    </div>

                </div>
                <div class="mx-auto max-w-2xl">
                    <div id="board" class="sudoku-grid locked" aria-label="Tablero de Sudoku"></div>
                    <div class="mt-5 flex flex-col gap-3 sm:flex-row sm:items-center">
                        <label class="flex items-center gap-2 font-semibold text-slate-600">
                            Dificultad
                            <select id="difficulty"
                                    class="rounded-xl border border-slate-300 bg-white px-3 py-3 font-normal outline-none focus:border-blue-500">
                                <option value="easy">Fácil</option>
                                <option value="normal" selected>Normal</option>
                                <option value="hard">Difícil</option>
                            </select>
                        </label>
                        <button id="randomBtn"
                                class="flex-1 rounded-xl bg-blue-600 px-5 py-3 font-bold text-white hover:bg-blue-700">↻
                            Nueva partida</button>
                        <button id="checkBtn"
                                class="flex-1 rounded-xl bg-slate-800 px-5 py-3 font-bold text-white hover:bg-slate-900">Verificar</button>
                        <button id="solutionBtn" title="Mantén presionado para ver la solución"
                                aria-label="Mantén presionado para ver la solución"
                                class="rounded-xl bg-amber-500 px-5 py-3 text-xl font-bold text-white hover:bg-amber-600">👁</button>
                    </div>
                    <p id="message" class="mt-4 min-h-6 text-center font-semibold" role="status"></p>
                </div>
                <div class="mt-8 grid gap-3 text-sm text-slate-500 sm:grid-cols-2">
                    <p><span class="mr-2 inline-block h-4 w-4 rounded bg-slate-200 align-middle">
                        </span>Pista inicial (bloqueada)</p>
                    <p>
                        <span
                            class="mr-2 inline-block h-4 w-4 rounded border border-blue-400 bg-white align-middle"></span>
                        Celda editable
                    </p>
                </div>
            </section>
        </main>
        <script>
            const API_KEY = 'xKIANstCnF6BZE03a7Q3J9rGMYqa170Derm2kEdijjc';

            const board = document.getElementById('board'),
                    timerEl = document.getElementById('timer'),
                    startBtn = document.getElementById('startBtn'),
                    message = document.getElementById('message'),
                    checkBtn = document.getElementById('checkBtn'),
                    difficulty = document.getElementById('difficulty'),
                    solutionBtn = document.getElementById('solutionBtn');

            let solution = [],
                    puzzle = [],
                    seconds = 0,
                    timerId = null,
                    finished = false,
                    started = false,
                    previewCells = [];

            function shuffled(a) {
                return [...a].sort(() => Math.random() - .5)
            }

            function safe(g, r, c, n) {
                for (let i = 0; i < 9; i++)
                    if (g[r][i] === n || g[i][c] === n)
                        return false;
                let R = Math.floor(r / 3) * 3,
                        C = Math.floor(c / 3) * 3;
                for (let i = R; i < R + 3; i++)
                    for (let j = C; j < C + 3; j++)
                        if (g[i][j] === n)
                            return false;
                return true
            }

            function fill(g) {
                for (let r = 0; r < 9; r++)
                    for (let c = 0; c < 9; c++)
                        if (!g[r][c]) {
                            for (const n of shuffled([1, 2, 3, 4, 5, 6, 7, 8, 9]))
                                if (safe(g, r, c, n)) {
                                    g[r][c] = n;
                                    if (fill(g))
                                        return true;
                                    g[r][c] = 0
                                }
                            return false
                        }
                return true
            }

            function render() {
                board.innerHTML = '';
                for (let r = 0; r < 9; r++)
                    for (let c = 0; c < 9; c++) {
                        let w = document.createElement('div')
                        w.className = 'cell ' + (puzzle[r][c] ? 'given' : 'user');
                        let i = document.createElement('input');
                        i.type = 'text';
                        i.inputMode = 'numeric';
                        i.maxLength = 1;
                        i.value = puzzle[r][c] || '';
                        i.dataset.row = r;
                        i.dataset.col = c;
                        i.setAttribute('aria-label', 'Fila ' + (r + 1) + ', columna ' + (c + 1));
                        if (puzzle[r][c])
                            i.readOnly = true;
                        else
                            i.addEventListener('input', e => {
                                e.target.value = e.target.value.replace(/[^1-9]/g, '');
                                updateButton();
                                clearErrors()
                            });
                        i.addEventListener('focus', () => highlight(r, c));
                        i.addEventListener('blur', clearFocus);
                        w.appendChild(i);
                        board.appendChild(w)
                    }
                updateButton()
            }

            function highlight(r, c) {
                document.querySelectorAll('.cell').forEach((e, k) => e.classList.toggle('focused', Math.floor(k / 9) === r || k % 9 === c))
            }

            function clearFocus() {
                document.querySelectorAll('.cell').forEach(e => e.classList.remove('focused'))
            }

            function inputs() {
                return [...board.querySelectorAll('input')]
            }

            function clearErrors() {
                document.querySelectorAll('.error').forEach(e => e.classList.remove('error'))
            }

            function updateButton() {
                checkBtn.textContent = inputs().every(i => i.value) ? 'Terminar' : 'Verificar'
            }

            function validate(finalCheck) {
                clearErrors();
                let wrong = [];
                inputs().forEach((i, k) => {
                    let r = Math.floor(k / 9), c = k % 9;
                    if (!i.value || +i.value !== solution[r][c])
                        wrong.push(i.parentElement)
                });
                if (wrong.length) {
                    wrong.forEach(e => e.classList.add('error'));
                    message.textContent = finalCheck ? 'Hay errores. Corrige las celdas marcadas.' : 'Hay números incorrectos; revisa las celdas marcadas.';
                    message.className = 'mt-4 min-h-6 text-center font-semibold text-red-600';
                    setTimeout(clearErrors, 1800);
                    return
                }
                clearInterval(timerId);
                finished = true;
                message.textContent = '¡Felicidades! Sudoku resuelto en ' + timerEl.textContent + '.';
                message.className = 'mt-4 min-h-6 text-center font-semibold text-emerald-600';
                checkBtn.disabled = true;
                checkBtn.classList.add('opacity-60', 'cursor-not-allowed')
            }
            function countSolutions(g, limit = 2) {
                let best = null;
                for (let r = 0; r < 9; r++)
                    for (let c = 0; c < 9; c++)
                        if (!g[r][c] && (best === null || 0)) {
                            best = [r, c]
                        }
                if (best === null)
                    return 1;
                let total = 0
                , [r, c] = best;
                for (let n = 1; n <= 9; n++)
                    if (safe(g, r, c, n)) {
                        g[r][c] = n;
                        total += countSolutions(g, limit - total);
                        g[r][c] = 0;
                        if (total >= limit)
                            return total
                    }
                return total
            }

            async function newGame() {
                clearInterval(timerId);
                seconds = 0;
                finished = false;
                started = false;
                previewCells = [];
                startBtn.classList.remove('hidden');
                timerEl.classList.add('hidden');
                board.classList.add('locked');
                checkBtn.disabled = true;
                checkBtn.classList.add('opacity-60', 'cursor-not-allowed');
                timerEl.textContent = '00:00';
                message.textContent = 'Cargando tablero...';
                message.className = 'mt-4 min-h-6 text-center font-semibold text-slate-500';

                try {
                    let level = difficulty.value === 'normal' ? 'medium' : difficulty.value;
                    let response = await fetch('sudoku-api.jsp?difficulty=' + encodeURIComponent(level), {
                        method: 'POST', headers: {'Accept': 'application/json', 'x-api-key': API_KEY}
                    });
                    let data = await response.json();
                    if (!response.ok)
                        throw new Error(data.error || ('Error HTTP ' + response.status));
                    solution = parseGrid(data.solution);
                    puzzle = parseGrid(data.puzzle);
                    if (solution.flat().length !== 81 || puzzle.flat().length !== 81)
                        throw new
                                Error('La API devolvió un tablero incompleto')
                } catch (error) {
                    console.error('Error al cargar Sudoku:', error);
                    message.textContent = 'No se pudo cargar: ' + error.message;
                    message.className = 'mt-4 min-h-6 text-center font-semibold text-red-600';
                    return
                }
                render();
                board.classList.add('locked');
                checkBtn.disabled = false;
                checkBtn.classList.remove('opacity-60', 'cursor-not-allowed');
                message.textContent = 'Pulsa Iniciar para comenzar';
                message.className = 'mt-4 min-h-6 text-center font-semibold text-slate-500'
            }
            function parseGrid(value) {
                if (Array.isArray(value))
                    return value.length === 9 && Array.isArray(value[0]) ?
                            value.map(row => row.map(Number)) : Array.from({
                        length: 9
                    },
                            (_, r) => value.slice(r * 9, r * 9 + 9).map(Number));
                if (typeof value === 'string') {
                    let numbers = value.match(/[0-9]/g).map(Number);
                    return Array.from({length: 9}, (_, r) => numbers.slice(r * 9, r * 9 + 9))
                }
                throw new Error('Formato de respuesta no válido')
            }
            function startGame() {
                if (started)
                    return;
                started = true;
                startBtn.classList.add('hidden');
                timerEl.classList.remove('hidden');
                board.classList.remove('locked');
                timerId = setInterval(() => {
                    seconds++;
                    timerEl.textContent = String(Math.floor(seconds / 60)).padStart(2, '0') + ':' + String(seconds % 60).padStart(2, '0')
                },
                        1000)
            }
            function showSolution() {
                if (!started || finished)
                    return;
                previewCells = [];
                inputs().forEach((input, k) => {
                    if (!input.value) {
                        let r = Math.floor(k / 9), c = k % 9;
                        input.value = solution[r][c];
                        input.dataset.preview = 'true';
                        previewCells.push(input)
                    }
                })
            }
            function hideSolution() {
                previewCells.forEach(input => {
                    if (input.dataset.preview === 'true') {
                        input.value = '';
                        delete input.dataset.preview
                    }
                });
                previewCells = [];
                updateButton()
            }

            startBtn.addEventListener('click', startGame);
            difficulty.addEventListener('change', newGame);
            checkBtn.addEventListener('click', () => {
                if (started && !finished)
                    validate(checkBtn.textContent === 'Terminar')
            });
            document.getElementById('randomBtn').addEventListener('click', newGame);
            solutionBtn.addEventListener('pointerdown', e => {
                e.preventDefault();
                showSolution()
            });
            ['pointerup', 'pointercancel', 'pointerleave'].
                    forEach(event => solutionBtn.addEventListener(event, hideSolution));
            newGame();
        </script>
    </body>
</html>