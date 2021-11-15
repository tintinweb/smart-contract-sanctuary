pragma solidity ^0.8.0;

contract PascalTriangle {
    uint256[] currRow;
    uint256[] nextRow;

    function newTriangle(uint256 size) public {
        currRow.push(1);

        for (uint256 r = 2; r <= size; r++) {
            nextRow.push(1);

            for (uint256 c = 1; c < r - 1; c++) {
                nextRow.push(currRow[c - 1] + currRow[c]);
            }
            nextRow[r - 1] = 1;

            uint256[] memory temp;
            temp = currRow;
            currRow = nextRow;
            nextRow = temp;
        }
    }
}

