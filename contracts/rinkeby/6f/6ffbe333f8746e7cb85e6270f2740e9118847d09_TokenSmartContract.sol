/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract TokenSmartContract {
    
    address public _owner;

    constructor(){
        _owner = msg.sender;
    }
    
    
    function getBalance() public view returns (uint256) {
        return _owner.balance;
    }
    
    function sendEther() payable public{
         
         payable(_owner).transfer(msg.value);
     }

}