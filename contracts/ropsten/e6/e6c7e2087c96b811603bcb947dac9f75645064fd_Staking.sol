/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

contract Staking {
    mapping (address => uint8) balances;
    function staking(uint8 _amount) public{
        balances[msg.sender] += _amount;
    }

     function withdraw(uint8 _amount) public{
        balances[msg.sender] -= _amount;
    }

    function balanceOf(address _user) public view returns (uint8) {
        return balances[_user];
    }
  
}