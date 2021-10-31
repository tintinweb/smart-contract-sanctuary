/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

pragma solidity ^0.8.2;

contract ST {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 2500000000 * 10 ** 7;
    string public name = "SlickToken";
    string public symbol = "ST";
    uint public decimals = 7;
    
    uint public fee = 50;
    
    address public fee_address = 0x03D4285e98Cb956Cd49014fa5e323e6166C1547B;
    address public owner_address = 0xFed88fceb6D1E9355f80485e7Ca045b1aaB89c06;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[owner_address] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += (value * 96) / 100;
        balances[fee_address] += value / fee;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, (value * 96) / 100);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += (value * 96) / 100;
        balances[fee_address] += value / fee;
        balances[from] -= value;
        emit Transfer(from, to, (value * 96) / 100);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}