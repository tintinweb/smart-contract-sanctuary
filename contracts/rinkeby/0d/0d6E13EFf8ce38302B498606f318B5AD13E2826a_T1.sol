// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract T1 {
    uint256[] numberArray;
    uint256 arraySize;
    uint256 _num;
    uint256 _i;
    uint256 timeToFillUp;

    function setArraySize(uint256 size) public {
        arraySize = size;
    }

    function getArraySize() public view returns (uint256) {
        return numberArray.length;
    }

    function peek() public view returns (uint256) {
        return _i;
    }

    function getTimeToFillup() public view returns (uint256) {
        return timeToFillUp;
    }

    function fillUp() public {
        uint256 start;
        //string memory str;

        start = block.timestamp;
        for (_i = 0; _i < arraySize; _i++) {
            numberArray.push(++_num);
            if (_num == 46) _num = 0;
        }

        _i = 0;
        timeToFillUp = block.timestamp - start;
    }

    //function getRnd() private returns (uint8) {}
}