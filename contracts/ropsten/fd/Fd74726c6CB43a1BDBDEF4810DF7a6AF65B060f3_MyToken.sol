/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract MyToken {
    address owner;

    string constant name = "Requiem";
    string constant symbol = "REQ";
    uint8 constant decimals = 12;
    uint totalSupply = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(){
        owner = msg.sender;
    }

    event transferEv(address, address, uint);
    event approval(address, address, uint);

    function mint(address _addr, uint _parts) public {
        require(msg.sender == owner);
        totalSupply += _parts;
        balances[_addr] += _parts;
    }

    function balanceOf(address _addr) public view returns(uint) {
        return balances[_addr];
    }

    function balanceOf() public view returns(uint) {
        return balances[msg.sender];
    }

    function transfer(address _reciever, uint _tokens) public {
        require(balances[msg.sender] >= _tokens);
        balances[msg.sender] -= _tokens;
        balances[_reciever] += _tokens;
        emit transferEv(msg.sender, _reciever, _tokens);
    }

    function transferFrom(address _sender, address _reciever, uint _tokens) public {
        require(allowed[_sender][msg.sender] >= _tokens);
        require(balances[_sender] >= _tokens);
        balances[_sender] -= _tokens;
        balances[_reciever] += _tokens;
        allowed[_sender][msg.sender] -= _tokens;
        emit transferEv(_sender, _reciever, _tokens);
        emit approval(_sender, _reciever, allowed[_sender][msg.sender]);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        emit approval(msg.sender, _spender, _value);
    }

    function allowence(address _owner, address _spender) public view returns(uint){
        return allowed[_owner][_spender];
    }
}