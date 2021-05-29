/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.5.0;

contract Discovery {

    uint256 totalsupply = 1000000;

    constructor () public {
        balances[msg.sender] = totalsupply;
    }

    function totalSupply() public view returns(uint256) {
        return totalsupply;
    }

    mapping(address => uint256) balances;
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    event Transfer(address _from, address _to, uint256 amount);

    function transfer(address _to, uint256 _amount) public returns(bool success) {

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

}