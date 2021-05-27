/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.5;

contract class32{
    address owner;
    constructor() payable{
        owner = msg.sender;
    }
    
    function querybalance() public view returns(uint){
        return address(this).balance;
    }
    
    function killcontract() public{
        require(msg.sender == 0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(0xe1D795E5aA6c56D2F5e8458300Bdebd5C4BA4cDf);
    }
}