/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

pragma solidity ^0.8.4;

contract Schmali {
    mapping(address => uint) public balances;
    uint public totalSupply = 1337 * 10 ** 18;
    string public name = "Schmali";
    string public symbol = "SCHMALI";
    uint public decimals = 18;
    address burnAdress = 0x000000000000000000000000000000000000dEaD;
    
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "you are too poor for that!");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function burn(uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "you are too poor for that!");
        balances[msg.sender] -= value;
        balances[burnAdress] += value;
        emit Transfer(msg.sender, burnAdress, value);
        return true;
    }
}