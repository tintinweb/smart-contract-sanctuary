/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

pragma solidity >=0.4.22 <0.6.0;


contract TokenBegin {
    uint public totalSupply;
    mapping(address => uint) public balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    constructor(uint _value) public {
        totalSupply = _value;
        balances[msg.sender] = totalSupply;
    }
    function transfer(address to, uint _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, to, _value);
        return true;
    }
    function balanceOf(address owner) view public returns (uint){
        return balances[owner];
    }
    
}