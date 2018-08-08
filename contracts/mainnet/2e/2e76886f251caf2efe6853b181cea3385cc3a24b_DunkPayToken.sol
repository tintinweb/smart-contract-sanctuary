pragma solidity ^0.4.16;

  /**
  * @title SafeMath
  * @dev Math operations with safety checks that throw on error
  */
  library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    address public owner;

    function Ownable() public {
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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is Pausable{
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    uint256 public totalSupplyForDivision;

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
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;
    }
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal whenNotPaused{
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
    function transfer(address _to, uint256 _value) public whenNotPaused {
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
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
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
    function approve(address _spender, uint256 _value) public whenNotPaused
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) whenNotPaused
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
    function burn(uint256 _value) public whenPaused returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        totalSupplyForDivision -= _value;                              // Update totalSupply
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
    function burnFrom(address _from, uint256 _value) public whenPaused returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        totalSupplyForDivision -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract DunkPayToken is TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public buySupply;
    uint256 public totalEth;
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DunkPayToken() TokenERC20(totalSupply, name, symbol) public {

        buyPrice = 1000;
        sellPrice = 1000;
        
        name = "BitcoinYo Token";
        symbol = "BTY";
        totalSupply = buyPrice * 10000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = buyPrice * 5100 * 10 ** uint256(decimals);              
        balanceOf[this] = totalSupply - balanceOf[msg.sender];
        buySupply = balanceOf[this];
        totalSupplyForDivision = totalSupply;// Set the symbol for display purposes
        totalEth = address(this).balance;
    }

    function percent(uint256 numerator, uint256 denominator , uint precision) returns(uint256 quotient) {
        if(numerator <= 0)
        {
            return 0;
        }
        // caution, check safe-to-multiply here
        uint256 _numerator  = numerator * 10 ** uint256(precision+1);
        // with rounding of last digit
        uint256 _quotient =  ((_numerator / denominator) - 5) / 10;
        return  _quotient;
    }
    
    function getZero(uint256 number) returns(uint num_len) {
        uint i = 1;
        uint _num_len = 0;
        while( number > i )
        {
            i *= 10;
            _num_len++;
        }
        return _num_len;
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
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
        totalSupplyForDivision += mintedAmount;
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

    function transfer(address _to, uint256 _value) public whenNotPaused {
        if(_to == address(this)){
            sell(_value);
        }else{
            _transfer(msg.sender, _to, _value);
        }
    }

    function () payable public {
     buy();
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable whenNotPaused public {
        uint256 dnkForBuy = msg.value;
        uint zeros = getZero(buySupply);
        uint256 interest = msg.value / 2 * percent(balanceOf[this] , buySupply , zeros);
        interest = interest / 10 ** uint256(zeros);
        dnkForBuy = dnkForBuy + interest;
        _transfer(this, msg.sender, dnkForBuy * buyPrice);              // makes the transfers
        totalEth += msg.value;
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) whenNotPaused public {
        uint256 ethForSell =  amount;
        uint zeros = getZero(balanceOf[this]);
        uint256 interest = amount / 2 * percent( buySupply , balanceOf[this] ,zeros);
        interest = interest / 10 ** uint256(zeros);
        ethForSell = ethForSell - interest;
        ethForSell = ethForSell - (ethForSell/100); // minus 1% for refund fee.   
        ethForSell = ethForSell / sellPrice;
        uint256 minimumAmount = address(this).balance; 
        require(minimumAmount >= ethForSell);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(ethForSell);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
        totalEth -= ethForSell;
    } 

    /// @notice withDraw `amount` ETH to contract
    /// @param amount amount of ETH to be sent
    function withdraw(uint256 amount) onlyOwner public {
        uint256 minimumAmount = address(this).balance; 
        require(minimumAmount >= amount);      // checks if the contract has enough ether to buy
        msg.sender.transfer(amount);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }

    function airdrop(address[] _holders, uint256 mintedAmount) onlyOwner whenPaused public {
        for (uint i = 0; i < _holders.length; i++) {
            uint zeros = getZero(totalSupplyForDivision);
            uint256 amount = percent(balanceOf[_holders[i]],totalSupplyForDivision,zeros)  * mintedAmount;
            amount = amount / 10 ** uint256(zeros);
            if(amount != 0){
                mintToken(_holders[i], amount);
            }
        }
        totalSupplyForDivision = totalSupply;
    }

    function bankrupt(address[] _holders) onlyOwner whenPaused public {
        uint256 restBalance = balanceOf[this];
        balanceOf[this] -= restBalance;                        // Subtract from the targeted balance
        totalSupply -= restBalance;                              // Update totalSupply
        totalSupplyForDivision -= restBalance;                             // Update totalSupply
        totalEth = address(this).balance;
        
        for (uint i = 0; i < _holders.length; i++) {
          uint zeros = getZero(totalSupplyForDivision);
          uint256 amount = percent(balanceOf[_holders[i]],totalSupplyForDivision , zeros) * totalEth;
          amount = amount / 10 ** uint256(zeros);
        
          if(amount != 0){
            uint256 minimumAmount = address(this).balance; 
            require(minimumAmount >= amount);      // checks if the contract has enough ether to buy
            uint256 holderBalance = balanceOf[_holders[i]];
            balanceOf[_holders[i]] -= holderBalance;                        // Subtract from the targeted balance
            totalSupply -= holderBalance;            
            _holders[i].transfer(amount);          // sends ether to the seller. It&#39;s important to do this last to 
          } 
        }
        totalSupplyForDivision = totalSupply;
        totalEth = address(this).balance;
    }    
}