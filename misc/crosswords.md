
# Crosswords


<div id="all-crosswords"></div>

<style>
.crossword {
    background-color: blue;
}
.board {
    background-color: yellow;
}
.clues {
    background-color: orange;
}
td {
    width: 40px;
    height: 40px;
}
.blocked {
    background-color: black;
}
input {
    width: inherit;
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
    renderBoard(div, crossword.board, index)
    renderClues(div, crossword.clues, index);
    document.getElementById('all-crosswords').appendChild(div);
}

function renderClues(parent, clues, index) {
    const div = document.createElement('div');
    div.classList.add('clues');
    parent.appendChild(div);
    for (const direction of ['across', 'down']) {
        for (const [num, phrase] of Object.entries(clues[direction])) {
            const p = document.createElement('p');
            p.appendChild(document.createTextNode(`${num}${direction}: ${phrase}`));
            div.appendChild(p);
        }
    }
}

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
                td.appendChild(input);
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
