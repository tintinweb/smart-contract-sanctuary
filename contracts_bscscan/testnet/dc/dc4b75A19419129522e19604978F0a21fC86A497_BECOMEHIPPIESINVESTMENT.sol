/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

pragma solidity >=0.7.0 <0.9.0;

contract BECOMEHIPPIESINVESTMENT {
    
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowance;
    
    uint private totalSupply = 60000 * 10 ** 18;
    uint public decimals = 18;
    
    string public name = "Become Hippies Investment Token";
    string public symbol = "BHIT";
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address user) public view returns (uint) {
        return balances[user];
    }
    
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function TransferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf(from) >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}