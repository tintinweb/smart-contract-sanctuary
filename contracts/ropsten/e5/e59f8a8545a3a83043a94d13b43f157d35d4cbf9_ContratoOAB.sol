/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.1;

contract ContratoOAB{
    mapping(address => uint256) public balances;
    address payable wallet;
    
    constructor(address payable _wallet) public {
        wallet = _wallet;
    }
    
    function buyToken() public payable {
        // buy OAB
        balances[msg.sender] ++;
        
        // send ether to wallet
        wallet.transfer(msg.value);
    }
}