pragma solidity 0.4.21;

contract owned {
    address public owner;

    function owned() public {
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    

    /// Constructor
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[this] = totalSupply;                // Give the contract, not the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
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

/********************* Landcoin Token *********************/

contract LandCoin is owned, TokenERC20 {

    /************ 0.1 Initialise variables and events ************/

    uint256 public buyPrice;
    uint256 public icoStartUnix;
    uint256 public icoEndUnix;
    bool public icoOverride;
    bool public withdrawlsEnabled;

    mapping (address => uint256) public paidIn;
    mapping (address => bool) public frozenAccount;

    /// Freezing and burning events
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);
    event FundTransfer(address recipient, uint256 amount);

    /************ 0.2 Constructor ************/

    /// Initializes contract with initial supply tokens to the creator of the contract
    function LandCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 _buyPrice,    //IN WEI. Default: 100000000000000000 (100 finney, or 100 * 10**15)
        uint256 _icoStartUnix,      // Default: 1524182400 (20 April 2018 00:00:00 UTC)
        uint256 _icoEndUnix         // Default: 1526774399 (19 May 2018 23:59:59 UTC)
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        buyPrice = _buyPrice;
        icoStartUnix = _icoStartUnix;
        icoEndUnix = _icoEndUnix;
        icoOverride = false;
        withdrawlsEnabled = false;
        // Grant owner allowance to the contract&#39;s supply
        allowance[this][owner] = totalSupply;
    }

    /************ 1. Transfers ************/

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        uint previousBalances = balanceOf[_from] + balanceOf[_to];  // for final check in a couple of lines
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        require(balanceOf[_from] + balanceOf[_to] == previousBalances); // Final check (basically an assertion)
        emit Transfer(_from, _to, _value);                       // Broadcast event       
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

    /************ 2. Buying ************/

    /// Modifier to only allow after ICO has started
    modifier inICOtimeframe() {
        require((now >= icoStartUnix * 1 seconds && now <= icoEndUnix * 1 seconds) || (icoOverride == true));
        _;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() inICOtimeframe payable public {
        uint amount = msg.value * (10 ** uint256(decimals)) / buyPrice;            // calculates the amount
        _transfer(this, msg.sender, amount);              				// makes the transfers
        paidIn[msg.sender] += msg.value;
    }

    /// also make this the default payable function
    function () inICOtimeframe payable public {
        uint amount = msg.value * (10 ** uint256(decimals)) / buyPrice;            // calculates the amount
        _transfer(this, msg.sender, amount);              				// makes the transfers
        paidIn[msg.sender] += msg.value;
    }

    /************ 3. Currency Control ************/

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Only central mint can burn from their own supply
    function burn(uint256 _value, uint256 _confirmation) onlyOwner public returns (bool success) {
        require(_confirmation==7007);                 // To make sure it&#39;s not done by mistake
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /// @notice Allow users to buy tokens for &#39;newBuyPrice&#39;, in wei
    /// @param newBuyPrice Price users can buy from the contract, in wei
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }

    /// Run this if ownership transferred
    function setContractAllowance(address allowedAddress, uint256 allowedAmount) onlyOwner public returns (bool success) {
    	require(allowedAmount <= totalSupply);
    	allowance[this][allowedAddress] = allowedAmount;
    	return true;
    }

    /************ 4. Investor Withdrawls ************/
   
   	/// Function to override ICO dates to allow secondary ICO
    function secondaryICO(bool _icoOverride) onlyOwner public {
    	icoOverride = _icoOverride;
    }

    /// Function to allow investors to withdraw ETH
    function enableWithdrawal(bool _withdrawlsEnabled) onlyOwner public {
    	withdrawlsEnabled = _withdrawlsEnabled;
    }

     function safeWithdrawal() public {
    	require(withdrawlsEnabled);
    	require(now > icoEndUnix);
    	uint256 weiAmount = paidIn[msg.sender]; 	
    	uint256 purchasedTokenAmount = paidIn[msg.sender] * (10 ** uint256(decimals)) / buyPrice;

    	// A tokenholder can&#39;t pour back into the system more Landcoin than you have 
    	if(purchasedTokenAmount > balanceOf[msg.sender]) { purchasedTokenAmount = balanceOf[msg.sender]; }
    	// A tokenholder gets the Eth back for their remaining token max
    	if(weiAmount > balanceOf[msg.sender] * buyPrice / (10 ** uint256(decimals))) { weiAmount = balanceOf[msg.sender] * buyPrice / (10 ** uint256(decimals)); }
    	
        if (purchasedTokenAmount > 0 && weiAmount > 0) {
	        _transfer(msg.sender, this, purchasedTokenAmount);
            if (msg.sender.send(weiAmount)) {
                paidIn[msg.sender] = 0;
                emit FundTransfer(msg.sender, weiAmount);
            } else {
                _transfer(this, msg.sender, purchasedTokenAmount);
            }
        }
    }

    function withdrawal() onlyOwner public returns (bool success) {
		require(now > icoEndUnix && !icoOverride);
		address thisContract = this;
		if (owner == msg.sender) {
            if (msg.sender.send(thisContract.balance)) {
                emit FundTransfer(msg.sender, thisContract.balance);
                return true;
            } else {
                return false;
            }
        }
    }

    function manualWithdrawalFallback(address target, uint256 amount) onlyOwner public returns (bool success) {
    	require(now > icoEndUnix && !icoOverride);
    	address thisContract = this;
    	require(amount <= thisContract.balance);
		if (owner == msg.sender) {
		    if (target.send(amount)) {
		        return true;
		    } else {
		        return false;
		    }
        }
    }
}