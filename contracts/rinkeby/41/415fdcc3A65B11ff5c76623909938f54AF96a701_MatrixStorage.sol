/**
 *Submitted for verification at Etherscan.io on 2021-08-15
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

     
    function uploadData(string[][] memory _data, uint256[] memory indexs, uint256[] memory cpus, uint256[] memory memories) public {
        for(uint256 i = 0; i< _data.length; i++) {
            if (cpus[i] > 80 || cpus[i] <30) {
                uint index = indexs[i];
                if(!validData[index].isValue) {
                    data.push(_data[i]);
                    validData[index] = validation(rowNum, true);
                    rowNum = rowNum + 1;
                } else {
                    data[validData[index].val] = _data[i];
                }
            }

            if (memories[i] > 80 || memories[i] < 30) {
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
    }
    
    /**
    *   get all data
    *   view all uploaded data
    */
    function viewAllData() public view returns(string[][] memory) {
        return data;
    }

    /**
    *   get selected data
    *   view selected data by id
    */
    function viewSelectedData(uint256 id) public view returns (string[] memory) {
        require(validData[id].isValue, "invalid ID");
        return data[validData[id].val];
    }
}