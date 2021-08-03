/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.2;


contract ERC20Token  {
    string public name = "Ember Token";
    string public symbol = "EMB";
    uint8 public decimals = 18;
    uint public totalSupply = 10000000 * 10 ** 18;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    constructor()
        public {
            balances[msg.sender] = totalSupply;
        }
        
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        require(spender != msg.sender);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
}