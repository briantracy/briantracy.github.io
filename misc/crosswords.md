
# Crosswords


<div id="all-crosswords"></div>
<!-- <div class="container">

<div class="puzzle">

</div>
<h2>Across</h2>
<ol>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
</ol>

<h2>Down</h2>
<ol>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
</ol>
</div>
<br>
<div class="container">

<div class="puzzle">

</div>
<h2>Across</h2>
<ol>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
    <li>Across ere that has something to do with clues.</li>
</ol>

<h2>Down</h2>
<ol>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
    <li>Down that has something to do with clues.</li>
</ol>
</div> -->
<style>

.puzzle {
    width: 300px;
    height: 300px;
    background-color: black;
}
.container {
    background-color: gray;
    column-count: 3;
    padding: 10px;
}
.crossword {
    background-color: white;
    column-count: 2;
    border: 1px solid black;
}
.board {
}
.all-clues {
    background-color: orange;
}
.clue-box {

}
td {
    width: 40px;
    height: 40px;
}
.blocked {
    background-color: black;
}
input {
    width: 40px;
    height: 40px;
    font-size: 30px;
    text-align: center;
    font-weight: bold;
    border: none;
    padding: none;

}
.number {
    position: absolute;
    color: blue;
}
.clue-highlight {
    background-color: lightblue;
}
</style>

<script>

/*
Algorithm for assigning numbers to squares

Start in top left, proceed across each row.
If the square is not part of an existing across, it becomes the start of an across
If the square is not part of an existing down, it becomes the start of a down.

1(a,d) 2(d) 3(d)
4(a)  
5(a)

"part of an existing across" == there exists a white space immediately left
"part of an existing down" == there exists a white space immediately above

add_numbers(grid: bool[][]) -> {
    across: {
        1: [0, 0],
        4: [0, 1],
        5: [0, 2],
    },
    down: {
        1: [0, 0],
        2: [1, 0],
        3: [2, 0],
    }
}

"Please highlight 2 down" -> "starts at [1,0]"

Maybe we want to compute full bounds for each clue.

How do I want to encode a crossword in the densest way possible?

For clicking a clue and highlighting the correct squares:
    We need a mapping from [num][dir] -> [r][c] and then we can
    run across/down from there.
For clicking a square and highlighting the correct clue, this
 is a one to many relationship where a square can be part of
 a down and an across. We can encode by [r][c] -> [across#, down#],
 and then cycle between them on repeated clicks. No state necessary,
  just swap the order of those elements each click.



squareToClues = { "r_c": ["4a", "1d"] }
answerStarts = ["r_c", "r_c"]
For each row r:
    for each col c:
        if isStartOfAnswer(r, c):
            clueNum++
            if isDown:
                starts[clueNum][down] = [(r, c)


*/

function computeClueAssociations(crossword) {
    const board = crossword.board;
    const squareToClues = {};
    const answerStarts = [];

    const isStartOfAcross = (r, c) => c == 0 || board[r][c - 1] == '*';
    const isStartOfDown   = (r, c) => r == 0 || board[r - 1][c] == '*';
    const isStartOfAnswer = (r, c) => {
        return isStartOfAcross(r, c) || isStartOfDown(r, c);
    };

    const addClue = (r, c, clue) => {
        const key = `${r}_${c}`;
        if (key in squareToClues) {
            squareToClues[key].push(clue);
        } else {
            squareToClues[key] = [clue];
        }
    };

    let answerNum = 0;
    for (let r = 0; r < board.length; ++r) {
        for (let c = 0; c < board[r].length; ++c) {
            if (board[r][c] == '*' || !isStartOfAnswer(r, c)) { continue; }
            ++answerNum;
            answerStarts.push(`${r}_${c}`);
            if (isStartOfAcross(r, c)) {
                for (let i = 0; c + i < board[r].length && board[r][c + i] != '*'; ++i) {
                    addClue(r, c + i, `${answerNum}a`);
                }
            }
            if (isStartOfDown(r, c)) {
                for (let i = 0; r + i < board.length && board[r + i][c] != '*'; ++i) {
                    addClue(r + i, c, `${answerNum}d`);
                }
            }
        }
    }
    crossword.squareToClues = squareToClues;
    crossword.answerStarts = answerStarts;
}

// index is [0 .. n]
function renderCrossword(crossword, index) {
    computeClueAssociations(crossword);
    console.log(crossword);
    const div = document.createElement('div');
    div.classList.add('crossword');
    renderBoard(div, crossword, index);
    addCheckRevealButtons(div, crossword.board, index);
    renderClues(div, crossword.clues, index);
    document.getElementById('all-crosswords').appendChild(div);
}

function addCheckRevealButtons(parent, board, index) {
    const check = document.createElement('button');
    check.textContent = 'Check';
    check.onclick = () => { checkCrossword(board, index); };
    parent.appendChild(check);

    const reveal = document.createElement('button');
    reveal.textContent = 'Reveal';
    reveal.onclick = () => { revealCrossword(board, index); };
    parent.appendChild(reveal);
}

function renderClues(parent, clues, index) {
    for (const direction of ['across', 'down']) {
        const clueTitle = document.createElement('h2');
        clueTitle.appendChild(document.createTextNode(
            `${direction[0].toUpperCase()}${direction.substring(1)}`)
        );
        parent.appendChild(clueTitle);
        const ol = document.createElement('ol');
        parent.appendChild(ol);
        for (const [num, phrase] of Object.entries(clues[direction])) {
            const li = document.createElement('li');
            li.id = `clue_${index}_${num}${direction[0]}`;
            li.appendChild(document.createTextNode(`${phrase}`));
            li.value = num;
            ol.appendChild(li);
        }
    }
}

function clearHighlightFromClues(clues, index) {
    for (const direction of ['across', 'down']) {
        for (const num of Object.keys(clues[direction])) {
            document.getElementById(`clue_${index}_${num}${direction[0]}`).classList.remove('clue-highlight');
        }
    }
}

const inputId = (index, row, col) => `input_${index}_${row}_${col}`;

function renderBoard(parent, crossword, index) {
    const board = crossword.board;
    const table = document.createElement('table');
    table.classList.add('board');
    parent.appendChild(table);


    const isStartOfWord = (r, c) => {
        return  r == 0 || c == 0 ||
                board[r - 1][c] == '*' ||
                board[r][c - 1] == '*';
    };

    let i = 1;
    for (let rowIdx = 0; rowIdx < board.length; ++rowIdx) {
        const rowElement = table.insertRow(rowIdx);
        for (let colIdx = 0; colIdx < board[rowIdx].length; ++colIdx) {
            const td = rowElement.insertCell(colIdx);
            if (board[rowIdx][colIdx] == '*') {
                td.className = 'blocked';
            } else {

                if (isStartOfWord(rowIdx, colIdx)) {
                    const number = document.createElement('span');
                    number.classList.add('number');
                    number.appendChild(document.createTextNode(`${i}`));
                    td.appendChild(number);
                    ++i;
                }

                const input = document.createElement('input');
                input.setAttribute('type', 'text');
                input.maxLength = 1;
                input.id = inputId(index, rowIdx, colIdx);
                input.onchange = (e) => {
                    input.parentElement.style.backgroundColor = 'white';
                };
                input.onfocus = (e) => {
                    console.log('input focus: ' + input.id);
                };
                input.addEventListener('focusout', (e) => {
                    console.log('focus out');
                    clearHighlightFromClues(crossword.clues, index);
                });
                input.onclick = (e) => {
                    clearHighlightFromClues(crossword.clues, index);
                    console.log('input onclick: ' + input.id);
                    for (const clueName of crossword.squareToClues[`${rowIdx}_${colIdx}`]) {
                        console.log(`clue_${index}_${clueName}`);
                        document.getElementById(`clue_${index}_${clueName}`).classList.add('clue-highlight');
                    }
                };
                td.appendChild(input);
            }
        }
    }
}


function checkCrossword(board, index) {
    console.log(`checking board ${board} idx ${index}`);
    for (let rowIdx = 0; rowIdx < board.length; ++rowIdx) {
        for (let colIdx = 0; colIdx < board[rowIdx].length; ++colIdx) {
            if (board[rowIdx][colIdx] != '*') {
                const input = document.getElementById(inputId(index, rowIdx, colIdx));
                if (input.value == board[rowIdx][colIdx]) {
                    input.parentElement.style.backgroundColor = 'green';
                } else {
                    input.parentElement.style.backgroundColor = 'red';
                }
            }
        }
    }
}

function revealCrossword(board, index) {
    console.log(`checking board ${board} idx ${index}`);
    for (let rowIdx = 0; rowIdx < board.length; ++rowIdx) {
        for (let colIdx = 0; colIdx < board[rowIdx].length; ++colIdx) {
            if (board[rowIdx][colIdx] != '*') {
                const input = document.getElementById(inputId(index, rowIdx, colIdx));
                input.value = board[rowIdx][colIdx];
                input.parentElement.style.backgroundColor = 'brown';
                input.disabled = true;
            }
        }
    }
}


const crosswords = [
// {
//     board: [
//         ['*', 'a', 'b', 'r'],
//         ['c', 'p', '*', 'q'],
//         ['e', 'f', 'r', '*'],
//     ],
//     clues: {
//         across: {
//             1: 'First two letters',
//             4: 'Third letter',
//             5: 'Fourth letter',
//             6: 'E and F'
//         },
//         down: {
//             1: 'First letter',
//             2: 'B for brian',
//             3: 'hol up',
//             4: 'another one',
//             7: 'final one'
//         }
//     }
// },
{
    board: [
        ['a', 's', 'p', '*'],
        ['r', 'o', 'a', 'm'],
        ['m', 'a', 'r', 'e'],
        ['*', 'p', 'e', 't'],
    ],
    clues: {
        across: {
            1: 'Venomous snake',
            4: 'Travel freely',
            6: 'Stallion\'s mate',
            7: 'You do this to 7 across'
        },
        down: {
            1: 'To render explosive',
            2: 'Bacterial bane',
            3: 'Reduce by slivers',
            5: 'Well __, an archaic greeting',
        }
    }
}];

for (let i = 0; i < crosswords.length; ++i) {
    renderCrossword(crosswords[i], i);
}


/*
const table = document.getElementById('crossword');

for (let rowIdx = 0; rowIdx < crossword.board.length; rowIdx++) {
    const rowElement = table.insertRow(rowIdx);
    for (let colIdx = 0; colIdx < crossword.board[rowIdx].length; colIdx++) {
        const square = rowElement.insertCell(colIdx);
        const number = document.createElement('span');
        number.innerHTML = rowIdx;
        number.className = 'number';
        square.appendChild(number);
        square.appendChild(document.createTextNode(crossword.board[rowIdx][colIdx]));
    }
}

const writeClues = (direction) => {
    for (const [num, phrase] of Object.entries(crossword.clues[direction])) {
        console.log(`${num}${direction}: ${phrase}`)
    }
};

writeClues('down');
writeClues('across');
*/
</script>
