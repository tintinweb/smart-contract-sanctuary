/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract wallet {
    
    mapping (address => uint256) balances;
    
    modifier ifBalanceIsEnough(uint256 _eth) {
        require(balances[msg.sender] >= _eth * 10 ** 18);
        _;
    }
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 _eth) public ifBalanceIsEnough(_eth) {
        payable(msg.sender).transfer(_eth * 10 ** 18);
    }
    
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}