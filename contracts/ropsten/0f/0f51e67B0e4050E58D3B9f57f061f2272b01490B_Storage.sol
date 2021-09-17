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

    uint256[] public numbers;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        uint256 i;
        for (i = 0; i< num; i++) {
            if (numbers[i] > 0) { numbers[i] = i; } else { numbers.push(i); }
        }
    }
    
    function storemul(uint256 num) public {
        uint256 i;
        for (i= 0; i< num; i++) {
            if (numbers[i]  > 0) { numbers[i] = i * 2; } else { numbers.push(i*2); }
        }
    }
    
    function storereq(uint256 num) public {
        uint256 i;
        uint256 j;
        for (i= 0; i< num; i++) {
            for (j = i; j < i + 5; j++) {
                if (numbers[i]  > 0) { numbers[i] = i+j; } else { numbers.push(i+j); }
            }
        }
    }
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve(uint256 id) public view returns (uint256){
        return numbers[id];
    }
}