pragma solidity ^0.4.16;

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
    // function balanceOf(address _owner) constant returns (uint256 balance) {
    //     return balances[_owner];
    // }

}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract HngCoin {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;                 // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    uint256 public coinunits;                 // How many units of your coin can be bought by 1 ETH?
    uint256 public ethereumWei;            // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.
    address public tokensWallet;             // Safe Address could be changed so owner isnt same address
    address public owner;             // Safe Address could be changed so owner isnt same address
    address public salesaccount;           // Where should the raised ETH be sent to?
    uint256 public sellPrice;             //sellprice if need be we ever call rates that are dynamic from api
    uint256 public buyPrice;             //sellprice if need be we ever call rates that are dynamic from api
    //uint256 public investreturns;
    bool public isActive; //check if we are seling or not

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    //event TransferSender(address indexed _from, address indexed _to, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function HngCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        //initialSupply = 900000000000000000000000000;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "HNGCOIN";                                   // Set the name for display purposes
        symbol = "HNGC";                               // Set the symbol for display purposes
        coinunits = 100;                                      // Set the price of your token for the ICO (CHANGE THIS)
        tokensWallet = msg.sender;
        salesaccount = msg.sender;
        ethereumWei = 1000000000000000000;                                    // The owner of the contract gets ETH
        isActive = true;               //set true or false for sale or not
        owner = msg.sender;
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
     //function sendit(address _to, uint256 _value) public returns (bool success) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
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
    // change salesaccount address
    function salesAddress(address sales) public returns (bool success){
        require(msg.sender == tokensWallet);
        salesaccount = sales;
        return true;
    }
    // change units address
    function coinsUnit(uint256 amount) public returns (bool success){
        require(msg.sender == tokensWallet);
        coinunits = amount;
        return true;
    }
    // transfer balance to owner withdraw owner
  	function withdrawEther(uint256 amount) public returns (bool success){
  		require(msg.sender == tokensWallet);
      //require(msg.value == multiply(amount, ethereumWei));
      amount = amount * ethereumWei;
  		salesaccount.transfer(amount);
  		return true;
  	}

    /* /// @notice Buy tokens from contract by sending ether
    function buy(uint256 amount) public payable{
      //  uint amount = msg.value * buyPrice;               // calculates the amount
        require(msg.value == multiply(amount, ethereumWei));
        _transfer(this,msg.sender, amount);              // makes the transfers
    } */
    function startSale() external {
      require(msg.sender == owner);
      isActive = true;
    }
    function stopSale() external {
      require(msg.sender == owner);
      isActive = false;
    }

    function() payable public {
    //  ethereumWei = ethereumWei + msg.value;
    //  investreturns = msg.value + ethereumWei;
      //investreturns = investreturns + msg.value;
      //investreturns = investreturns + msg.value;
      require(isActive);
      uint256 amount = msg.value * coinunits;
      //uint256 amount = 100000000000000000;
      require(balanceOf[tokensWallet] >= amount);

      balanceOf[tokensWallet] -= amount;
      balanceOf[msg.sender] += amount;

      Transfer(tokensWallet, msg.sender, amount); // Broadcast a message to the blockchain

      //Transfer ether to tokensWallet
    //  tokensWallet.transfer(msg.value);
    //  _transfer(msg.sender, tokensWallet, msg.value);
      }

}

/******************************************/
/*      Token Sale       */
/******************************************/

contract HngCoinSale is owned, HngCoin {



    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function HngCoinSale(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) HngCoin(initialSupply, tokenName, tokenSymbol) public {}

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

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    /* /// @notice Buy tokens from contract by sending ether
    function buy(uint256 amount) public payable{
      //  uint amount = msg.value * buyPrice;               // calculates the amount
        require(msg.value == multiply(amount, buyPrice));
        _transfer(owner,msg.sender, amount);              // makes the transfers
    } */
    /* function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        Sell(msg.sender, _numberOfTokens);
    } */

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    /* function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, owner, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    } */

}