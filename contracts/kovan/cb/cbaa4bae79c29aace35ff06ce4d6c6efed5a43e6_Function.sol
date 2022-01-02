/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract Function {
    // 方法可以回傳多個值
    function returnMany() public pure returns (uint, bool, uint) {
        return (1, true, 2);
    }

    // 回傳的值可以被命名
    function named() public pure returns (uint x, bool b, uint y) {
        return (1, true, 2);
    }

    // 回傳的值, 可以利用賦值, 省略 return
    function assigned() public pure returns (uint x, bool b, uint y) {
        x = 1;
        b = true;
        y = 2;
    }

    // 也可利用解構賦值, 來傳遞參數
    function destructingAssigments() public pure returns (uint, bool, uint, uint, uint) {
        (uint i, bool b, uint j) = returnMany();

        // 解構賦值也容許超出範圍
        (uint x, , uint y) = (4, 5, 6);

        return (i, b, j, x, y);
    }

    // 可以使用陣列作為輸入與輸出
    function arrayInput(uint[] memory _arr) public {}

    uint[] public arr;

    function arrayOutput() public view returns (uint[] memory) {
        return arr;
    }
}