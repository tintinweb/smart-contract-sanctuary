/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract wallet {
    
    mapping (address => uint256) balances;
    
    modifier ifBalanceIsEnough(uint256 _amount) {
        require(balances[msg.sender] >= _amount);
        _;
    }
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public ifBalanceIsEnough(amount) {
        payable(msg.sender).transfer(amount);
    }
    
    function getBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }
}