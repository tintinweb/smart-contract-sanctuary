pragma solidity ^0.4.8;

//Kings Distributed Systems
//ERC20 Compliant SPARC Token
contract SPARCToken {
    string public constant name     = "Science Power and Research Coin";
    string public constant symbol   = "SPARC";
    uint8  public constant decimals = 18;

    uint256 public totalSupply      = 0;
    
    bool    public frozen           = false;
    
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    
    mapping(address => bool) admins;
    address public owner;
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    
    modifier onlyAdmin() {
        if (!admins[msg.sender]) {
            throw;
        }
        _;
    }
 
    event Transfer(address indexed from,  address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Constructor
    function SPARCToken() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }
    
    function addAdmin (address admin) onlyOwner {
        admins[admin] = true;
    }
    
    function removeAdmin (address admin) onlyOwner {
        admins[admin] = false;
    }
    
    function totalSupply() external constant returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address owner) external constant returns (uint256) {
        return balances[owner];
    }
    
    // Open support ticket to prove transfer mistake to unusable address.
    // Not to be used to dispute transfers. Only for trapped tokens.
    function recovery(address from, address to, uint256 amount) onlyAdmin external {
        assert(balances[from] >= amount);
        assert(amount > 0);
    
        balances[from] -= amount;
        balances[to] += amount;
        Transfer(from, this, amount);
        Transfer(this, to, amount);
    }
 
    function approve(address spender, uint256 amount) external returns (bool){
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if(frozen
        || amount == 0
        || amount > allowed[from][msg.sender]
        || amount > balances[from]
        || amount + balances[to] < balances[to]){
            return false;
        }
        
        balances[from] -= amount;
        balances[to] += amount;
        allowed[from][msg.sender] -= amount;
        Transfer(from, to, amount);
        
        return true;
    }
 
    function allowance(address owner, address spender) external constant returns (uint256) {
        return allowed[owner][spender];
    }
 
    function create(address to, uint256 amount) onlyAdmin external returns (bool) {
        if (amount == 0
        || balances[to] + amount < balances[to]){
            return false;
        }
        
        totalSupply += amount;
        balances[to] += amount;
        Transfer(this, to, amount);
        
        return true;
    }
    
    function destroy(address from, uint256 amount) onlyAdmin external returns (bool) {
        if(amount == 0
        || balances[from] < amount){
            return false;
        }
        
        balances[from] -= amount;
        totalSupply -= amount;
        Transfer(from, this, amount);
        
        return true;
    }
 
    function transfer(address to, uint256 amount) external returns (bool) {
        if (frozen
        || amount == 0
        || balances[msg.sender] < amount
        || balances[to] + amount < balances[to]){
            return false;
        }
    
        balances[msg.sender] -= amount;
        balances[to] += amount;
        Transfer(msg.sender, to, amount);
        
        return true;
    }
    
    function freeze () onlyAdmin external {
        frozen = true;
    }
    
    function unfreeze () onlyAdmin external {
        frozen = false;
    }
    
    // Do not transfer ether to this contract.
    function () payable {
        throw;
    }
}