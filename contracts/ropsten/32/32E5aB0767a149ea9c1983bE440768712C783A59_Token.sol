/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Token {
    string constant name="TestToken";
    string constant symbol="TT";
    uint8 constant decimals=10;
    address owner;
    uint totalSupply=0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(){
        owner = msg.sender;
    }

    event Transfer(address, address, uint);
    event Approval(address, address, uint);

    function mint(address _to, uint _value)public {
        require(msg.sender == owner);
        totalSupply += _value;
        balances[_to] += _value;
    }

    function balanceOf() public view returns(uint) {
        return balances[msg.sender];
    }

    function balanceOf(address _adr) public view returns(uint) {
        return balances[_adr];
    }

    function transfer(address _to, uint _value) public {
        require(balances[msg.sender]>_value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public {
        require(balances[_from]>_value);
        require(allowed[_from][msg.sender]>=_value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _from, address _spender) public view returns(uint) {
        return allowed[_from][_spender];
    }
}