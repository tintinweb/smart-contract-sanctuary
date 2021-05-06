/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    struct Number {
        uint256 index;
        uint256 value;
        string name;
    }
    
    Number[] public numbers;
    
    function push(uint256 _amount) public {
        for(uint256 i = 0; i < _amount; i++) {
            Number memory number;
            number.index = numbers.length;
            number.value = i;
            number.name = "Number";
            numbers.push(number);
        }
    }
    
    function getNumbers() public view returns(Number[] memory) {
        return numbers;
    }
    
    function numbersSize() public view returns(uint256) {
        return numbers.length;
    }
    
}