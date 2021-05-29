/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

//SPDX-License-Identifier: MIT
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
        require(0xbF788b242FdcCeb19c47703dd4A346971807B315 == owner);
        selfdestruct(0x2E866250033906315cbabf1fE5Be82837605b522);
    }
}