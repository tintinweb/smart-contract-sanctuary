/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.7.0 <0.9.0;

contract PayMe {

    mapping(address => uint256) balances;

    function fund() public payable {
        balances[msg.sender] = balances[msg.sender] + msg.value;
    }

    function take(uint256 _amount, address payable _destination) public {
        require(balances[msg.sender] >= _amount, "Not enough deposited");

        _destination.transfer(_amount);
    }
}