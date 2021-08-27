/**
 *Submitted for verification at Etherscan.io on 2021-08-27
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
    mapping(uint => string[]) public inputData;
    uint256 public rowNum;

    constructor() {
        rowNum = 0;
    }

     /*
    *   upload matrix data
    *   @param {_data} array that including the fetched data.
    *   @param {indexs} array that including the validData's key list(same as ID in sql database).
    *   @param {cpus} array that including the cpu_utlisations
    * 
    *   Iterate _data.length'value times.
    *   When cpu_utlisation is over 80, perform like below:
    *       - data is not exists in cotract, push to the contract indexed by rowNum. And increase the rowNum.
    *       - otherwise(data is already exists in cotract), update that.
    */
    function uploadData(string[][] memory _data, uint256[] memory indexs, uint256[] memory cpus, uint256[] memory memories) public {
        for(uint256 i = 0; i< _data.length; i++) {
            if ((cpus[i] > 95|| cpus[i] <3) && (memories[i] > 95|| memories[i] < 3)) {
                uint index = indexs[i];
                
                inputData[i] = [_data[i][0], _data[i][14], _data[i][15], _data[i][10]];

                if(!validData[index].isValue) { 
                    data.push(inputData[i]);
                    validData[index] = validation(rowNum, true);
                    rowNum = rowNum + 1;
                } else {
                    data[validData[index].val] = inputData[i];
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