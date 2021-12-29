// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract getandset {

    uint256 private number;
    address private minter;

     constructor(){
        minter = msg.sender;
    }

    
    function set(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256){
        return number;
    }
    function getMinter() public view returns (address){
        return minter;
    }
    

}