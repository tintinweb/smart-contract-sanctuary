pragma solidity ^0.4.15;

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface
{
    function totalSupply() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Additional desired wallet functionality
contract ERC20Burnable is ERC20Interface
{
    function burn(uint256 value) returns (bool);

    event Burn(address indexed owner, uint256 value);
}



// Wallet implementation
contract VRFtoken is ERC20Burnable
{
    // Public data
    string public constant name = "VRF token";
    string public constant symbol = "VRF";
    uint256 public constant decimals = 2; 
    address public owner;  

    // Internal data
    uint256 private constant initialSupply = 690000000; // 690,000,000
    uint256 private currentSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;

    function VRFtoken()
    {
        // Increase initial supply by appropriate factor to allow
        // for the desired number of decimals
        currentSupply = initialSupply * (10 ** uint(decimals));

        owner = msg.sender;
        balances[owner] = currentSupply;
      
    }

    function totalSupply() public constant 
        returns (uint256)
    {
        return currentSupply;
    }

    function balanceOf(address tokenOwner) public constant 
        returns (uint256)
    {
        return balances[tokenOwner];
    }
  
    function transfer(address to, uint256 amount) public 
        returns (bool)
    {
        if (balances[msg.sender] >= amount && // Sender has enough?
            balances[to] + amount > balances[to]) // Transfer won&#39;t cause overflow?
        {
            balances[msg.sender] -= amount;
            balances[to] += amount;
            Transfer(msg.sender, to, amount);
            return true;
        } 
        else // Invalid transfer
        {
            return false;
        }
    }
  
    function transferFrom(address from, address to, uint256 amount) public 
        returns (bool)
    {
        if (balances[from] >= amount && // Account has enough?
            allowed[from][msg.sender] >= amount && // Sender can act for account for this amount?
            balances[to] + amount > balances[to]) // Transfer won&#39;t cause overflow?
        {
            balances[from] -= amount;
            allowed[from][msg.sender] -= amount;
            balances[to] += amount;
            Transfer(from, to, amount);
            return true;
        }
        else // Invalid transfer
        {
            return false;
        }
    }

    function approve(address spender, uint256 amount) public 
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant 
        returns (uint256)
    {
        return allowed[tokenOwner][spender];
    }

    function burn(uint256 amount) public 
        returns (bool)
    {
        require(msg.sender == owner); // Only the owner can burn

        if (balances[msg.sender] >= amount) // Account has enough?
        {
            balances[msg.sender] -= amount;
            currentSupply -= amount;
            Burn(msg.sender, amount);
            return true;
        }
        else // Not enough to burn
        {
            return false;
        }
    }
}