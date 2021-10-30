/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Store { 
    
    uint256 number;
    
    function storeNumber(uint256 _number) public {
        number = _number;
    }

    function getNumber() public view returns(uint256){
        return number;
    }
}