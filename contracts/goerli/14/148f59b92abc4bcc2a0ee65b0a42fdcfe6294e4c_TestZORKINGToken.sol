/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

//SPDX-Licence-Identifier: ExagonSoft

pragma solidity >=0.7.0 <0.9.0;


contract TestZORKINGToken{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allows;
    uint public totalSupply = 2000000000000 * 10 ** 5;
    string public name = "TestZORKING";
    string public symbol = "TZKG";
    uint public decimals = 5;

    event Transfer(address indexed origin, address indexed destiny, uint amount);
    event Appruve(address indexed owner, address indexed spender, uint amount);

    constructor(){
        balances[msg.sender] = totalSupply;
    } 

    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }

    function transfer(address reciver, uint amount) public returns(bool){
        require(balanceOf(msg.sender) >= amount, 'You do not have enough clipss');
        balances[reciver] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, reciver, amount);
        return true;
    }

    function transferFrom(address origin, address destiny, uint amount) public returns (bool){
        require(balanceOf(origin) >= amount, 'You do not have enough clipss');
        require(allows[origin][msg.sender] >= amount, 'You do not have enough clipss approuved');
        balances[destiny] += amount;
        balances[origin] -= amount;
        emit Transfer(origin, destiny, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns(bool){
        allows[msg.sender][spender] = amount;
        emit Appruve(msg.sender, spender, amount);
        return true;
    }
}