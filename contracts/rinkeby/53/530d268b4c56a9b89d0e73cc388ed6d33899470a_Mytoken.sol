/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.4.22;
//整数溢出攻击
contract Mytoken{
    mapping (address => uint) balances;
    
    event balancesAndAmount(uint, uint);
    function balanceof(address _user) returns(uint) { return balances[_user]; }
    function deposit() payable {balances[msg.sender] += msg.value; }
    function withdraw(uint _amount) {
        balancesAndAmount(balances[msg.sender], _amount);
        require(balances[msg.sender] - _amount > 0); // 存在整数溢出
        msg.sender.transfer(_amount);
        balances[msg.sender] -= _amount;
    }
}