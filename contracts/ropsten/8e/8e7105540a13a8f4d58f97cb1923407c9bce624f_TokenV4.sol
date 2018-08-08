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
contract TokenV4 is ERC20Standard 
{
    // #region Constants
    
    /// FIX - set the token name, token symbol and the number of tokens issued (Production: 100 million tokens)
    string public constant name = "TokenV4";           // Token name for display purposes
    string public constant symbol = "TKV4";            // Token symbol for display purposes 
    uint256 public constant initialSupply = 100000000; // Initial number of tokens (the actual number of tokens)
    uint8 public constant decimals = 18;               // Amount of decimals for display purposes (must be 18)
    
    // #endregion
    
    // #region Getters
    
    // The compiler automatically creates getter functions for all the public state variables
    address public owner;                      // Owner address
    address public contractAddress;            // Contract address
    bool public payableEnabled = false;        // Controls the payment operation
    uint256 public payableWeiReceived = 0;     // Keeps track of wei received (1 ether = 10^18 wei)
    uint256 public payableFinneyReceived = 0;  // Keeps track of finney received (1 ether = 10^3 finney) 
    uint256 public payableEtherReceived = 0;   // Keeps track of ether received     
    uint256 public milliTokensPaid = 0;        // Keeps track of tokens paid during ICO
    uint256 public milliTokensSent = 0;        // Keeps track of tokens sent
    
    /// FIX - set the base value for how many tokens an ETH can buy, i.e. without bonus (Production: 1 ETH = 10,000 tokens)
    uint256 public tokensPerEther = 10000;     // How many tokens an ETH can buy (this will be changed based on bonus)  
    /// FIX - set the hard cap and maximum payment in ether (Production: hard cap = 7000 ETH, max payment = 50 ETH)
    uint256 public hardCapInEther = 20;      // The hard cap used to control the ICO (this is needed as safeguard to avoid spending all the tokens in ICO)
    uint256 public maxPaymentInEther = 3;     // The maximum payment that can be made one time by users during ICO (this is also needed as safeguard)
    
    // #endregion
    
    // #region Constructors
    
    /// @dev Constructor
    constructor() public
    {
        totalSupply_ = initialSupply * (10 ** uint256(decimals));  // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply_;                       // Give the creator all initial tokens
        
        owner = msg.sender;              // NOTE: This is the owner address
        contractAddress = address(this); // NOTE: This is the contract address
    }
    
    // #endregion
    
    // #region Public methods
    
    /// @dev Function that allows the contract to receive ether. The function without name is the default function 
    /// that is called whenever anyone sends funds to a contract.
    function() payable public
    {
        require(payableEnabled);
        require(msg.sender != 0x0);
     
        // NOTE: msg.value is expressed in wei (1 ETH = 10^18 wei). For example:
        // user sends 0.035 ETH => msg.value = 0.035 * 10^18 =  35,000,000,000,000,000
        // user sends 12 ETH =>    msg.value = 12 * 10^18 = 12,000,000,000,000,000,000
        require(maxPaymentInEther > uint256(msg.value / (10 ** 18)));
        require(hardCapInEther > payableEtherReceived);
        
        uint256 actualTokensPerEther = getActualTokensPerEther();
        uint256 tokensAmount = msg.value * actualTokensPerEther;
        
        require(balances[owner] >= tokensAmount);
        
        // Update token balances (remove tokens from owner and give them to the user)
        balances[owner] -= tokensAmount;
        balances[msg.sender] += tokensAmount;
        
        // Update the state variables
        payableWeiReceived += msg.value;  
        payableFinneyReceived = uint256(payableWeiReceived / (10 ** 15));
        payableEtherReceived = uint256(payableWeiReceived / (10 ** 18));
        milliTokensPaid += uint256(tokensAmount / (10 ** uint256(decimals - 3)));
        
        // Broadcast a message to the blockchain
        emit Transfer(owner, msg.sender, tokensAmount); 
        
        // Transfer the ETH received to owner
        // NOTE: Users should be instructed to send the ETH to the contract address. Contract owner can later 
        // send the ETH received to any other account, for example using the Send button in Mematask (i.e. no
        // special withdrawal function is needed)        
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
       // Calculate the current bonus based on the amount of ether raised
       uint256 etherReceived = payableEtherReceived;
       
       /// FIX - calculate the bonus accordingly (Production: see distribution documentation)
       uint256 bonusPercent = 0;
       if(etherReceived < 5)
           bonusPercent = 16;
       else if(etherReceived < 7)
           bonusPercent = 12; 
       else if(etherReceived < 9)
           bonusPercent = 8; 
       else if(etherReceived < 10)
           bonusPercent = 4; 
       
       uint256 actualTokensPerEther = tokensPerEther * (100 + bonusPercent) / 100;
       return actualTokensPerEther;
    }
    
    /// @dev setTokensPerEther
    function setTokensPerEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); // Only owner can call this function
       require(amount > 0);
       tokensPerEther = amount;
       
       return true;
    }
    
    /// @dev setHardCapInEther
    function setHardCapInEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); // Only owner can call this function
       require(amount > 0);
       hardCapInEther = amount;
       
       return true;
    }
    
    /// @dev setMaxPaymentInEther
    function setMaxPaymentInEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); // Only owner can call this function
       require(amount > 0);
       maxPaymentInEther = amount;
       
       return true;
    }
    
    /// @dev enablePayable - call this on ICO start to allow user to buy tokens
    function enablePayable() public returns (bool)
    {
       require(msg.sender == owner); // Only owner can call this function
       payableEnabled = true;
       
       return true;
    }
    
    /// @dev disablePayable - call this on ICO end to disable tokens buying
    function disablePayable() public returns (bool)
    {
       require(msg.sender == owner); // Only owner can call this function
       payableEnabled = false;
       
       return true;
    }
    
    /// @dev sendTokens
    function sendTokens(uint256 milliTokensAmount, address destination) public returns (bool) 
    {
        require(msg.sender == owner); // Only owner can call this function
       
        // NOTE: to send X actual tokens, tokensAmount must be equal to X * 10^decimals
        // For example, to send 25 tokens when decimals = 18, use tokensAmount = 25 * 10^18
        // The function works as expected, i.e. the tokens are sent to the destination address
        uint256 tokensAmount = milliTokensAmount * (10 ** uint256(decimals - 3));
        
        require(balances[owner] >= tokensAmount);
        
        // Update token balances
        balances[owner] -= tokensAmount;
        balances[destination] += tokensAmount;
        
        milliTokensSent += milliTokensAmount;
        
        // Broadcast a message to the blockchain
        emit Transfer(owner, destination, tokensAmount);
        
        return true;
    }
    
    // #endregion
}