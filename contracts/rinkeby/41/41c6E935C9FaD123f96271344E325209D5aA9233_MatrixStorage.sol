/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MatrixStorage {

    string[][] private data;
    uint256 public rowNum;

    constructor() {
        rowNum = 0;
    }

    /**
    *   upload matrix data
    */
    function uploadData(string[][] memory _data) public {
        rowNum = _data.length;
        data = _data;
    }

    /**
    *   get matrix size;
    */
    function getDataSize() public view returns(uint256){
        return rowNum;
    }

    /**
    *   get all data
    */
    function viewAllData() public view returns(string[][] memory) {
        return data;
    }

    /**
    *   get selected data
    */
    function viewSelectedData(uint256 id) public view returns (string[] memory) {
        require(id < rowNum, "invalid ID");
        return data[id];
    }
}