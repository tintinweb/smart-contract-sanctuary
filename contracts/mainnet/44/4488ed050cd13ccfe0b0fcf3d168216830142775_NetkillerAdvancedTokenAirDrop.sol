pragma solidity ^0.4.21;

/******************************************/
/*       Netkiller ADVANCED TOKEN         */
/******************************************/
/* Author netkiller <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="610f04150a080d0d0413210c120f4f020e0c">[email&#160;protected]</a>>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-05-16 - Add Global lock   */
/******************************************/

contract NetkillerAdvancedTokenAirDrop {
    address public owner;
    // Public variables of the token
    string public name;
    string public symbol;
    uint public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
    // This creates an array with all balances
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address indexed target, bool frozen);

    bool public lock = false;                   // Global lock
    bool public airdropStatus = false;          // Airdrop Status
    uint256 public airdropTotalSupply;          // Airdrop Total Supply
    uint256 public airdropCurrentTotal;    	    // Airdrop Current Total 
    uint256 public airdropAmount;        		// Airdrop amount
    mapping(address => bool) public touched;    // Airdrop history account
    
    event AirDrop(address indexed target, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function NetkillerAdvancedTokenAirDrop(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) public {
        owner = msg.sender;
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol; 
        decimals = decimalUnits;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                // Give the creator all initial token
        airdropAmount = 1 * 10 ** uint256(decimals);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier isLock {
        require(!lock);
        _;
    }
    
    function setLock(bool _lock) onlyOwner public returns (bool status){
        lock = _lock;
        return lock;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    function balanceOf(address _address) public returns (uint256 balance) {
        return getBalance(_address);
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) isLock internal {
        initialize(_from);

        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);               // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balances[_from] -= _value;                         // Subtract from the sender
        balances[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
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
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _value;
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        uint256 _amount = mintedAmount * 10 ** uint256(decimals);
        balances[target] += _amount;
        totalSupply += _amount;
        emit Transfer(this, target, _amount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    // mint airdrop 
    function mintAirdropToken(uint256 _mintedAmount) onlyOwner public {
        uint256 _amount = _mintedAmount * 10 ** uint256(decimals);
        totalSupply += _amount;
        airdropTotalSupply += _amount;
    }

    function setAirdropStatus(bool _status) onlyOwner public returns (bool status){
        require(airdropTotalSupply > 0);
        airdropStatus = _status;
        return airdropStatus;
    }
    function setAirdropAmount(uint256 _amount) onlyOwner public{
        airdropAmount = _amount * 10 ** uint256(decimals);
    }
    // internal private functions
    function initialize(address _address) internal returns (bool success) {
        if (airdropStatus && !touched[_address] && airdropCurrentTotal < airdropTotalSupply) {
            touched[_address] = true;
            airdropCurrentTotal += airdropAmount;
            balances[_address] += airdropAmount;
            emit AirDrop(_address, airdropAmount);
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (airdropStatus && !touched[_address] && airdropCurrentTotal < airdropTotalSupply) {
            balances[_address] += airdropAmount;
        }
        return balances[_address];
    }
}