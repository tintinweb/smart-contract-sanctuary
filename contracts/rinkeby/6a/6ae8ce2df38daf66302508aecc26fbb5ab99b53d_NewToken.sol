/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract NewToken {
    mapping(address => uint256) public balances;
    
    constructor() {
        balances[msg.sender] = 10000e18;
    }
    
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] - _amount >= 0, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
    
    function balanceOf(address _user) public view returns(uint256) {
        return balances[_user];
    }
    
    function mint(address _to, uint256 _amount) public {
        balances[_to] += _amount;
    }
}