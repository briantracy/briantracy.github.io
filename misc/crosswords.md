
# Crosswords


<!-- <div id="all-crosswords"></div> -->
<div id="container">

<div id="puzzle">

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
<style>

#puzzle {
    width: 300px;
    height: 300px;
    background-color: black;
}
#container {
    column-count: 2;
}
.crossword {
    background-color: blue;
}
.board {
    background-color: yellow;
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

*/

// index is [0 .. n]
function renderCrossword(crossword, index) {
    const div = document.createElement('div');
    div.classList.add('crossword');
    renderBoard(div, crossword.board, index);
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
    const div = document.createElement('div');
    div.classList.add('all-clues');
    parent.appendChild(div);
    for (const direction of ['across', 'down']) {
        const clueBox = document.createElement('div');
        clueBox.classList.add('clue-box');
        div.appendChild(clueBox);
        const clueTitle = document.createElement('span');
        clueTitle.appendChild(document.createTextNode(
            `${direction[0].toUpperCase()}${direction.substring(1)}`)
        );
        clueBox.appendChild(clueTitle);
        for (const [num, phrase] of Object.entries(clues[direction])) {
            const p = document.createElement('p');
            p.appendChild(document.createTextNode(`${num}) ${phrase}`));
            clueBox.appendChild(p);
        }
    }
}

const inputId = (index, row, col) => `input_${index}_${row}_${col}`;

function renderBoard(parent, board, index) {
    const table = document.createElement('table');
    table.classList.add('board');
    parent.appendChild(table);

    for (let rowIdx = 0; rowIdx < board.length; ++rowIdx) {
        const rowElement = table.insertRow(rowIdx);
        for (let colIdx = 0; colIdx < board[rowIdx].length; ++colIdx) {
            const td = rowElement.insertCell(colIdx);
            if (board[rowIdx][colIdx] == '*') {
                td.className = 'blocked';
            } else {
                const input = document.createElement('input');
                input.setAttribute('type', 'text');
                input.maxLength = 1;
                input.id = inputId(index, rowIdx, colIdx);
                input.onchange = (e) => {
                    input.parentElement.style.backgroundColor = 'white';
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
            }
        }
    }
}


const crosswords = [{
    board: [
        ['*', 'a', 'b'],
        ['c', '*', 'd'],
        ['e', 'f', '*'],
    ],
    clues: {
        across: {
            1: 'First two letters',
            2: 'Third letter',
            3: 'Fourth letter',
            4: 'E and F'
        },
        down: {
            1: 'First letter',
            2: 'B for brian',
            3: 'hol up',
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
