/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MatrixStorage {
    struct validation {
        uint256 val;
        bool isValue;
    }
    mapping(uint => validation) validData;
    string[][] private data;
    uint256 public rowNum;

    constructor() {
        rowNum = 0;
    }

    /**
    *   upload matrix data
    */
    function uploadData(string[][] memory _data, uint256[] memory indexs) public {
        for(uint256 i = 0; i< _data.length; i++) {
            uint index = indexs[i];
            if(!validData[index].isValue) {
                data.push(_data[i]);
                validData[index] = validation(rowNum, true);
                rowNum = rowNum + 1;
            } else {
                data[validData[index].val] = _data[i];
            }
        }
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
        require(validData[id].isValue, "invalid ID");
        return data[validData[id].val];
    }
}