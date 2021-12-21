// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract easyContract{
     address public minter;
     uint private number;


    constructor() {
        minter = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
       
        
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function getMinter() public view returns (address){
        return minter;
    }

}