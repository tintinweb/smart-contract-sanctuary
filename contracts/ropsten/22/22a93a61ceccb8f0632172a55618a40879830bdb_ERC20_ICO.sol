pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// &#39;CNB&#39;  token contract
//
// Owner Address : 0x3917492c197b61d7D8F66255E073E8ff582197f0
// Symbol      : CNB
// Name        : Cannabnc
// Total supply: 400000000
// Decimals    : 18
// Website     : https://www.ramlogics.com/cannabanc
// Email       : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2043414e4e4142414e436043414e4e4142414e430e434f4d">[email&#160;protected]</a>
// POWERED BY Cannabanc.

// (c) by Team @ cannabanc 2018.
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
*/

library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
    }
    
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
    }
    
     /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract ERC20 is owned {
    
    using SafeMath for uint;
    // Public variables of the token
    string public name = "Cannabnc Token";
    string public symbol = "CNB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 400000000 * 10 ** uint256(decimals);
    
    /// the price of 1 eth tokenBuy
    uint256 public BuyPrice = 4000;
    
    /// the price of 1 eth tokenSell
    uint256 public SellPrice = 4000;
    
    // Ico Contract Address
    address public ICO_Contract;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
   
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    // This notifies clients about the new Buy price
    event BuyRateChanged(uint256 oldValue, uint256 newValue);
    
    // This notifies clients about the new Sell price
    event SellRateChanged(uint256 oldValue, uint256 newValue);
    
    
    // Log the event about a deposit being made by an address and its amount
    event LogDepositMade(address indexed accountAddress, uint amount);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor (address _owner) public {
        owner = _owner;
        balanceOf[owner] = totalSupply;
    }
   /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value)  internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Check if sender is frozen
        require(!frozenAccount[_from]);
        // Check if recipient is frozen
        require(!frozenAccount[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
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

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
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
    
     /**
     * Set price function for Buy
     *
     * @param value the amount new Buy Price
     */
    
    function setBuyRate(uint256 value) onlyOwner public {
        require(value > 0);
        emit BuyRateChanged(BuyPrice, value);
        BuyPrice = value;
    }
    
     /**
     * Set price function for Sell
     *
     * @param value the amount new Sell Price
     */
    
    function setSellRate(uint256 value) onlyOwner public {
        require(value > 0);
        emit SellRateChanged(SellPrice, value);
        SellPrice = value;
    }
    
    /**
    *  function for Buy Token
    */
    
    function buy() payable public returns (uint amount){
          require(msg.value > 0);
          amount = ((msg.value.mul(BuyPrice)).mul( 10 ** uint256(decimals))).div(1 ether);
          balanceOf[this] -= amount;                        // adds the amount to owner&#39;s balance
          balanceOf[msg.sender] += amount; 
          _transfer(this, msg.sender, amount);
          return amount;
    }
    
    /**
    *  function for Sell Token
    */
    
    function sell(uint amount) public returns (uint revenue){
        
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = (amount.mul(1 ether)).div(SellPrice.mul(10 ** uint256(decimals))) ;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        _transfer(msg.sender, this, amount);               // executes an event reflecting on the change
       return revenue;                                   // ends function and returns
        
    }
    
    /**
    * Deposit Ether in owner account, requires method is "payable"
    */
    
    function deposit() public payable  {
       
    }
    
    /**
    *@notice Withdraw for Ether
    */
     function withdraw(uint withdrawAmount) onlyOwner public  {
          if (withdrawAmount <= address(this).balance) {
            owner.transfer(withdrawAmount);
        }
        
     }
    
    function () public payable {
        buy();
    }
    
    /// @dev Set the ICO_Contract.
    /// @param _ICO_Contract crowdsale contract address
    function setICO_Contract(address _ICO_Contract) onlyOwner public {
        ICO_Contract = _ICO_Contract;
    }
    
}

contract Killable is owned {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}
contract ERC20_ICO is Killable {
    
     /// The token we are selling
    ERC20 public token;

    /// the UNIX timestamp start date of the crowdsale
    uint256 public startsAt = 1545739200;

    /// the UNIX timestamp end date of the crowdsale
    uint256 public endsAt = 1556193600;

    /// the price of token
    uint256 public TokenPerETH = 4000;

    /// Has this crowdsale been finalized
    bool public finalized = false;
    
     /// the number of tokens already sold through this contract
    uint256 public tokensSold = 0;

    /// the number of ETH raised through this contract
    uint256 public weiRaised = 0;

    /// How many distinct addresses have invested
    uint256 public investorCount = 0;
    
     /// How much ETH each address has invested to this crowdsale
    mapping (address => uint256) public investedAmountOf;

    /// A new investment was made
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    /// Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    /// Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);
    /// Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    
    
    constructor (address _token) public {
        token = ERC20(_token);
    }

    function investInternal(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
        }

        // Update investor
        uint256 tokensAmount = msg.value * TokenPerETH;
        investedAmountOf[receiver] += msg.value;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;

        // Emit an event that shows invested successfully
        emit Invested(receiver, msg.value, tokensAmount);
        
        // Transfer Token to owner&#39;s address
        token.transfer(receiver, tokensAmount);

        // Transfer Fund to owner&#39;s address
        owner.transfer(address(this).balance);

    }
     function () public payable {
        investInternal(msg.sender);
    }

    function setStartsAt(uint256 time) onlyOwner public {
        require(!finalized);
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    
    function setEndsAt(uint256 time) onlyOwner public {
        require(!finalized);
        endsAt = time;
        emit EndsAtChanged(endsAt);
    }
    
    function setRate(uint256 value) onlyOwner public {
        require(!finalized);
        require(value > 0);
        emit RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }
    function finalize() public onlyOwner {
        // Finalized Pre ICO crowdsele.
        finalized = true;
        uint256 tokensAmount = token.balanceOf(this);
        token.transfer(owner, tokensAmount);
    }
}