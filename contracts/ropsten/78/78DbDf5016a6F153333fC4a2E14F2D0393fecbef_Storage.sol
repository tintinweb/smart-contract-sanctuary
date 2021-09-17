/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint[1000][100] public numbers;
    uint public counter = 0;
    uint[1000] private _arr;

    
    function init() public {
        uint i;
        uint j;
        for(j = 0; j < 1000; j++) {
            _arr[j] = 0;
        }
        for (i = 0; i < 100; i++) {
            numbers[i] = _arr;
        }
    }
 
    function addcounter() public {
        counter = counter + 5;
    }
    
   
    function store(uint256 num) public {
        uint i;
        uint j;
        for (i= 0; i < num; i++) {
            for (j = 0; j < counter; j++) {
              numbers[i][j] = i * 2;
            }
        }
    }
    
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve(uint id) public view returns (uint){
        uint result = 0;
        uint j;
        for (j = 0; j < counter; j++) {
              result += numbers[id][j];
        }
        return result;
    }
}