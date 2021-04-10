pragma solidity ^0.4.24;

import "./erc20Interface.sol";

contract WSB is ERC20Interface{
 
    /*
     @var = Token Name
     */
    string public name = "WallStreetBits";
    
    /*
     @var = Token Symbol
     */
    string public symbol = "WSB";
    
    /*
     @var = Token decimal places
     */
    uint public decimals = 18;
    
    /*
     @var = Token decimal places
     */    
    uint public supply;
    
    /*
     @var = Total Supply
     */ 
    address public founder;
    
    /*
     @var = balances, store address balances
     */    
    mapping(address => uint) public balances;
    
    /*
     @var = allowed, store address allowed values
     */    
    mapping(address => mapping(address => uint)) allowed;

    /*
     @from = From address
     @to = To address
     @value = Ammount to transfer
     => returns true for successful transfer
     */
    event Transfer(address indexed from, address indexed to, uint value);
    
    /*
     @owner = Owner address
     @spender = Spender address
     @value = Ammount approved to spend
     => returns 
     */
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     Init
     */
    constructor() public{
        supply = 69000000*10**decimals;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    /*
     => returns total supply of tokens
     */
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    /*
     @owner = Token Owner
     => returns value of balance
     */
    function balanceOf(address owner) public view returns (uint balance){
         return balances[owner];
    }
    
    /*
     @to = To address
     @value = Ammount to transfer
     => returns true if successful transfer / false if not
     */
    function transfer(address to, uint value) public returns (bool success){
         require(balances[msg.sender] >= value && value > 0);
         
         balances[to] += value;
         balances[msg.sender] -= value;
         emit Transfer(msg.sender, to, value);
         return true;
    }
        
    /*
     @from = From address
     @to = To address
     @value = Ammount to transfer
     => returns true for successful transfer
     */
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(allowed[from][to] >= value);
        require(balances[from] >= value);
        
        balances[from] -= value;
        balances[to] += value;
        
        
        allowed[from][to] -= value;
        
        return true;
    }

    /*
     @owner = Token Owner address
     @spender = Token Spender address
     => returns allowance of owner to spender
     */
    function allowance(address owner, address spender) view public returns(uint){
        return allowed[owner][spender];
    }
    
    /*
     @spender = Spender address
     @value = Value to for allowance
     => returns true if approval successful
     */
    function approve(address spender, uint value) public returns(bool){
        require(balances[msg.sender] >= value);
        require(value > 0);
        
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }    
}