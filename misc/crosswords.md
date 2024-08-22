
# Crosswords

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

*/

const crossword = [
    '*', 'a', 'b',
    'c', '*', 'd',
    'e', 'f', '*',
];
const clues = {
    across: ["some clue"],
    down: ["another clue down"],
};
</script>

<table>
</table>
