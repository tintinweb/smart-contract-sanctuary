pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    address owner=msg.sender;

    // This creates an array with all balances, allowances, frozen, master and admin accounts
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping(address => bool) public master;
    mapping(address => bool) public admin;
    
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event unFrozenFunds(address target, bool unfrozen);
    event AdminAddressAdded(address addr);
    event AdminAddressRemoved(address addr);
    event MasterAddressAdded(address addr);
    event MasterAddressRemoved(address addr);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    // Setting the ownership function of this contract
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    // setting the master function of this contract
     modifier onlyMaster() {
     require(master[msg.sender]);
    _;
    }
    
    // setting the addition / removal of master addresses
     function addAddressToMaster(address addr) onlyOwner public returns(bool success) {
     if (!master[addr]) {
       master[addr] = true;
       MasterAddressAdded(addr);
       success = true; 
     }
     }
    
     function removeAddressFromMaster(address addr) onlyOwner public returns(bool success) {
     if (master[addr]) {
       master[addr] = false;
       MasterAddressRemoved(addr);
       success = true;
     }
     }
    
    // setting the admin function of this contract
     modifier onlyAdmin() {
     require(admin[msg.sender]);
    _;
    }
    
    // setting the addition / removal of admin addresses
     function addAddressToAdmin(address addr) onlyMaster public returns(bool success) {
     if (!admin[addr]) {
       admin[addr] = true;
       AdminAddressAdded(addr);
       success = true; 
     }
     }
    
     function removeAddressFromAdmin(address addr) onlyMaster public returns(bool success) {
     if (admin[addr]) {
       admin[addr] = false;
       AdminAddressRemoved(addr);
       success = true;
     }
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
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        // Check for frozen accounts
        require(!frozenAccount[_from]);         // Check if sender is frozen
        require(!frozenAccount[_to]);           // Check if recipient is frozen

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
     * Send `_value` tokens to `_to` on behalf of `_from`
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
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
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
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
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

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
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
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    // This part is for Token Pricing and advanced portions
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyMaster public {
        require(balanceOf[msg.sender]<= totalSupply/10);
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
     
    function unfreezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = !freeze;
        unFrozenFunds(target, !freeze);
    }

    // dividend payout section
    // when user wants to claim for dividend, they should press this function
    // which will freeze their account temporarily after diviendend payout is
    // complete
    function claimfordividend() public {
        freezeAccount(msg.sender , true);
    }
    
    // owner will perform this action to payout the dividend and unfreeze the 
    // frozen accounts
    function payoutfordividend (address target, uint256 divpercentage) onlyOwner public{
        _transfer(msg.sender, target, ((divpercentage*balanceOf[target]/100 + 5 - 1) / 5)*5);
        unfreezeAccount(target , true);
    }
}