pragma solidity ^0.4.20;

contract FiatContract {
  function USD(uint _id) constant returns (uint256);
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract BimCoinToken is owned, TokenERC20 {

    FiatContract private fiatService;
    uint256 public buyPrice;
    bool private useFiatService;
    bool private onSale;
    uint256 private buyPriceInCent;
    uint256 private etherPerCent;
    uint256 constant TOKENS_PER_DOLLAR = 100000;
    uint256 storageAmount;
    address store;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        bool _useFiatContract
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        fiatService = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
        useFiatService = _useFiatContract;
        buyPriceInCent = 100;
        onSale = true;
        storageAmount = (2 * (initialSupply * 10 ** uint256(decimals)))/10;
        store = msg.sender;
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth
    /// @param newBuyPrice Price users can buy from the contract
    function setPrice(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    
    /// @notice Allow users to buy tokens for `newBuyPrice` eth
    /// @param newBuyPrice Price users can buy from the contract
    function setPriceInCents(uint256 newBuyPrice) onlyOwner public {
        buyPriceInCent = newBuyPrice;
    }
    
    /// @notice Buy tokens from contract by sending ether
    function () payable public {
        buy();
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        require(onSale);
        
        uint256 price = getPrice();
        
        uint amount = msg.value * TOKENS_PER_DOLLAR * 10 ** uint256(decimals) / price;               // calculates the amount
        
        require(balanceOf[owner] - amount >= storageAmount);
        
        store.transfer(msg.value);
        
        _transfer(owner, msg.sender, amount);              // makes the transfers
    }
    
    function getPrice() private view returns (uint256){
        if(useFiatService){
            return fiatService.USD(0) * buyPriceInCent;
        }else{
            return etherPerCent * buyPriceInCent;
        }
    }
    
    function setUseService(bool status) external onlyOwner{
        useFiatService = status;
    }
    
    function setEtherCentPrice(uint256 _newValue) external onlyOwner {
        etherPerCent = (10 ** uint256(decimals))/(_newValue);
    }
    
    function setStore(address _newValue) external onlyOwner {
        store = _newValue;
    }
    
    function toggleSale(bool _value) external onlyOwner {
        onSale = _value;
    }
    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        if(balance > 0){
            store.transfer(balance);
        }
    }
}