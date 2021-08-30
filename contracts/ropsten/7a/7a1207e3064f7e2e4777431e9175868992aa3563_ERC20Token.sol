/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity ^0.5.6;


contract ERC20Token  {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply)
        public {
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            totalSupply = _totalSupply;
            balances[msg.sender] = _totalSupply;
        }
        
    function transfer(address to, uint value) public  {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
       
    }
    
    function transferFrom(address from, address to, uint value) public {
        uint allowance = allowed[from][msg.sender];
        require(balances[msg.sender] >= value && allowance >= value);
        allowed[from][msg.sender] -= value;
        balances[msg.sender] -= value;
        balances[to] += value;
       
    }
    
    function approve(address spender, uint value) public {
        require(spender != msg.sender);
        allowed[msg.sender][spender] = value;
        
    }
    
    function allowance(address owner, address spender) public view returns(uint) {
        return allowed[owner][spender];
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
}