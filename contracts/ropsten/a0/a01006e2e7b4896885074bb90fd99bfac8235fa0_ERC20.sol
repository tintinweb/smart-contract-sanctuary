pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// &#39;World meds&#39;  token contract
//
// Owner Address : 0x52CBC6346C0E040190280D0483B9E99641465111
// Symbol      : wdmd
// Name        : World meds
// Total supply: 1000000000
// Decimals    : 18
// Website     : https://worldwidemeds.online
// Email       : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f592879092b5829a879991829c919098909186db9a9b999c9b90">[email&#160;protected]</a>
// POWERED BY World Wide Meds.

// (c) by Team @ World Wide Meds 2018.
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
    
   /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
   
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract ERC20 is owned {
    
    using SafeMath for uint;
    // Public variables of the token
    string public name = "World meds";
    string public symbol = "wdmd";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10 ** uint256(decimals);
    
     bool public released = false;

    /// the price of tokenBuy
    uint256 public TokenPerETHBuy = 5000;
    
    /// the price of tokenSell
    uint256 public TokenPerETHSell = 5000;

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
    
    /// This notifies clients about the new Buy price
    event BuyRateChanged(uint256 oldValue, uint256 newValue);
    
    /// This notifies clients about the new Sell price
    event SellRateChanged(uint256 oldValue, uint256 newValue);
    
    /// This notifies clients about the Buy Token
    event BuyToken(address user, uint256 eth, uint256 token);
    
    /// This notifies clients about the Sell Token
    event SellToken(address user, uint256 eth, uint256 token);
    
    /// Log the event about a deposit being made by an address and its amount
    event LogDepositMade(address indexed accountAddress, uint amount);
    
    modifier canTransfer() {
        require(released ||  msg.sender == owner);
       _;
     }

    function releaseToken() public onlyOwner {
        released = true;
    }

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
    function _transfer(address _from, address _to, uint256 _value) canTransfer internal {
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
        emit BuyRateChanged(TokenPerETHBuy, value);
        TokenPerETHBuy = value;
    }
    
     /**
     * Set price function for Sell
     *
     * @param value the amount new Sell Price
     */
    
    function setSellRate(uint256 value) onlyOwner public {
        require(value > 0);
        emit SellRateChanged(TokenPerETHSell, value);
        TokenPerETHSell = value;
    }
    
    /**
    *  function for Buy Token
    */
    
    function buy() payable public returns (uint amount){
          require(msg.value > 0);
          amount = ((msg.value.mul(TokenPerETHBuy)).mul( 10 ** uint256(decimals))).div(1 ether);
          balanceOf[this] -= amount;                        // adds the amount to owner&#39;s balance
          balanceOf[msg.sender] += amount; 
          emit BuyToken(msg.sender,msg.value,amount);
          return amount;
    }
    
    /**
    *  function for Sell Token
    */
    
    function sell(uint amount) public returns (uint revenue){
        
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = (amount.mul(1 ether)).div(TokenPerETHSell.mul(10 ** uint256(decimals))) ;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
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
    
  
}