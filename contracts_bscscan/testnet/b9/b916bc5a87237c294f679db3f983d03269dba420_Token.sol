/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract Token
{
    mapping(address => uint) balances;
    string public name = 'TokenX';
    string public symbol = 'TOX';
    uint public TotalSupply = 10000 * 10 ** 18;
    uint public Decimal = 18;
    address public Owner;
    
    event TokenTransfer( address indexed to , uint value);
    event Buy(uint value);
    
    
    constructor()
    {
        balances[msg.sender] = TotalSupply;
        Owner = msg.sender;
    }
    
    function BalanceInBNB() public view returns(uint)
    {
        return msg.sender.balance;
    }
    
    function TokenBalance() public view returns(uint)
    {
        return balances[msg.sender];
    }
    
    function ContractBalance() public view returns(uint)
    {
        return balances[address(this)];
    }
    
    function BalanceOf(address user) public view returns(uint)
    {
        return balances[user];
    }
    
    function tokenTransfer( address to , uint value) public returns(bool)
    {
        require(msg.sender.balance >= value , 'Balance Too Low !');
        require(balances[msg.sender]>= value , 'Token Balance Too Low !');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit TokenTransfer( to , value );
        return true;
    }
    
    function buy(uint value) public returns(bool)
    {
        require(msg.sender.balance >= value , 'Balance Too Low !');
        balances[msg.sender] += value;
        balances[address(this)] -= value;
        emit Buy( value );
        return true;
    }
}