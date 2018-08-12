pragma solidity 0.4.23;

// Implements the ERC20 standard contract
contract ERC20Standard 
{
    // #region Fields
    
    // The total token supply
    uint256 internal totalSupply_;
    
    // This creates a dictionary with all the balances
    mapping (address => uint256) internal balances;
    
    // This creates a dictionary with allowances
    mapping (address => mapping (address => uint256)) internal allowed;
    
    // #endregion
    
    // #region Events
    
    // Public events on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // #endregion
    
    // #region Public methods
    
    /// @return Total number of tokens in existence
    function totalSupply() public view returns (uint256) 
    {
        return totalSupply_;
    }
    
    /// @dev Gets the balance of the specified address
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance of the account with address _owner
    function balanceOf(address _owner) public view returns (uint256) 
    {
        return balances[_owner];
    }

    /// @dev Transfers _value amount of tokens to address _to
    /// @param _to The address of the recipient
    /// @param _value The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool) 
    {
        require(msg.data.length >= 68);                   // Guard against short address
        require(_to != 0x0);                              // Prevent transfer to 0x0 address
        require(balances[msg.sender] >= _value);          // Check if the sender has enough tokens
        require(balances[_to] + _value >= balances[_to]); // Check for overflows
        
        // Update balance
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        // Raise the event
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    /// @dev Transfers _value amount of tokens from address _from to address _to
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
    {
        require(msg.data.length >= 68);                   // Guard against short address
        require(_to != 0x0);                              // Prevent transfer to 0x0 address
        require(balances[_from] >= _value);               // Check if the sender has enough tokens
        require(balances[_to] + _value >= balances[_to]); // Check for overflows
        require(allowed[_from][msg.sender] >= _value);    // Check allowance
        
        // Update balance
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        
        // Raise the event
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    /// Sets allowance for another address, i.e. allows _spender to spend _value tokens on behalf of msg.sender.
    /// ERC20 standard at https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md recommends not implementing 
    /// checks for the approval double-spend attack, as this should be implemented in user interfaces.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        
        // Raise the event
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner
    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spend
    function allowance(address _owner, address _spender) public view returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    // #endregion
}

// Token that is ERC20 compliant
contract BinvToken is ERC20Standard 
{
    // #region Constants
    
    string public constant name = "BINV";              
    string public constant symbol = "BINV";            
    uint256 public constant initialSupply = 100000000;
    uint8 public constant decimals = 18;               
    
    // #endregion
    
    // #region Getters
    
    address public owner;                     
    address public contractAddress;            
    bool public payableEnabled = false;        
    uint256 public payableWeiReceived = 0;    
    uint256 public payableFinneyReceived = 0;  
    uint256 public payableEtherReceived = 0;       
    uint256 public milliTokensPaid = 0;        
    uint256 public milliTokensSent = 0;        
    
    uint256 public tokensPerEther = 10000;     
    uint256 public hardCapInEther = 7000;      
    uint256 public maxPaymentInEther = 50; 
    
    // #endregion
    
    // #region Constructors
    
    /// @dev Constructor
    constructor() public
    {
        totalSupply_ = initialSupply * (10 ** uint256(decimals));  
        balances[msg.sender] = totalSupply_;                      
        
        owner = msg.sender;              
        contractAddress = address(this); 
    }
    
    // #endregion
    
    // #region Public methods
    
    /// @dev payable
    function() payable public
    {
        require(payableEnabled);
        require(msg.sender != 0x0);
     
        require(maxPaymentInEther > uint256(msg.value / (10 ** 18)));
        require(hardCapInEther > payableEtherReceived);
        
        uint256 actualTokensPerEther = getActualTokensPerEther();
        uint256 tokensAmount = msg.value * actualTokensPerEther;
        
        require(balances[owner] >= tokensAmount);
        
        balances[owner] -= tokensAmount;
        balances[msg.sender] += tokensAmount;

        payableWeiReceived += msg.value;  
        payableFinneyReceived = uint256(payableWeiReceived / (10 ** 15));
        payableEtherReceived = uint256(payableWeiReceived / (10 ** 18));
        milliTokensPaid += uint256(tokensAmount / (10 ** uint256(decimals - 3)));

        emit Transfer(owner, msg.sender, tokensAmount); 
               
        owner.transfer(msg.value); 
    }
    
    /// @dev getOwnerBalance
    function getOwnerBalance() public view returns (uint256)
    {
        return balances[owner];
    }
    
    /// @dev getOwnerBalanceInMilliTokens
    function getOwnerBalanceInMilliTokens() public view returns (uint256)
    {
        return uint256(balances[owner] / (10 ** uint256(decimals - 3)));
    }
        
    /// @dev getActualTokensPerEther
    function getActualTokensPerEther() public view returns (uint256)
    {
       uint256 etherReceived = payableEtherReceived;
       
       uint256 bonusPercent = 0;
       if(etherReceived < 1000)
           bonusPercent = 16;
       else if(etherReceived < 2200)
           bonusPercent = 12; 
       else if(etherReceived < 3600)
           bonusPercent = 8; 
       else if(etherReceived < 5200)
           bonusPercent = 4; 
       
       uint256 actualTokensPerEther = tokensPerEther * (100 + bonusPercent) / 100;
       return actualTokensPerEther;
    }
    
    /// @dev setTokensPerEther
    function setTokensPerEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); 
       require(amount > 0);
       tokensPerEther = amount;
       
       return true;
    }
    
    /// @dev setHardCapInEther
    function setHardCapInEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); 
       require(amount > 0);
       hardCapInEther = amount;
       
       return true;
    }
    
    /// @dev setMaxPaymentInEther
    function setMaxPaymentInEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); 
       require(amount > 0);
       maxPaymentInEther = amount;
       
       return true;
    }
    
    /// @dev enablePayable
    function enablePayable() public returns (bool)
    {
       require(msg.sender == owner); 
       payableEnabled = true;
       
       return true;
    }
    
    /// @dev disablePayable
    function disablePayable() public returns (bool)
    {
       require(msg.sender == owner); 
       payableEnabled = false;
       
       return true;
    }
    
    /// @dev sendTokens
    function sendTokens(uint256 milliTokensAmount, address destination) public returns (bool) 
    {
        require(msg.sender == owner); 
        
        uint256 tokensAmount = milliTokensAmount * (10 ** uint256(decimals - 3));
        
        require(balances[owner] >= tokensAmount);

        balances[owner] -= tokensAmount;
        balances[destination] += tokensAmount;
        
        milliTokensSent += milliTokensAmount;

        emit Transfer(owner, destination, tokensAmount);
        
        return true;
    }
    
    // #endregion
}