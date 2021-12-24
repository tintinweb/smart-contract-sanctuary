/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;


contract Mytoken {
    string constant name = "Sozopolis";
    string constant symbol = "SZP";
    uint8 constant devide = 6;
    uint total = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address owner;

    event Transfer(address _from, address _to, uint amount);
    event Approval(address _spender, address _to, uint amount);
    

    constructor(){
        owner = msg.sender;
    }

    function mint(address _to, uint amount) public {
        require(owner == msg.sender, "You are not an owner");
        total += amount;
        balances[_to] += amount;
    }

    function balanceOf(address _address) public view returns(uint) {
        return balances[_address];
    }

    function balanceOf() public view returns(uint) {
        return balances[msg.sender];
    }

    function transfer(address _to, uint amount) public {
        require(balances[msg.sender] >= amount, "Not enough SZP");
        
        balances[msg.sender] -= amount;
        balances[_to] += amount;

        emit Transfer(msg.sender, _to, amount);
    }

    function transferFrom(address _from, address _to, uint amount) public {
        require(balances[_from] >= amount);
        require(allowed[_from][msg.sender] <= amount);

        balances[_from] -= amount;
        balances[_to] += amount;
        allowed[_from][msg.sender] -= amount;

        emit Transfer(_from, _to, amount);
        emit Approval(_from, _to, amount);
    }

    function approve(address _spender, uint _value) public {
        address _from = msg.sender;
        allowed[_from][_spender] = _value;
        
    }

    function allowance(address _from, address _spender) public view returns(uint) {
        return allowed[_from][_spender];
    }
}