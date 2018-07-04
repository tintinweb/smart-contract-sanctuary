pragma solidity ^0.4.18;

contract owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

contract NecashTokenBase {
    string public constant _myTokeName = &#39;Necash Token&#39;;
    string public constant _mySymbol = &#39;NEC&#39;;
    uint public constant _myinitialSupply = 20000000;
    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public decimals = 18;
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
    function NecashTokenBase() public {
        totalSupply = _myinitialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = _myTokeName;                                   // Set the name for display purposes
        symbol = _mySymbol;                               // Set the symbol for display purposes
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
        Transfer(_from, _to, _value);
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


contract NecashToken is owned, NecashTokenBase {
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function NecashToken() NecashTokenBase() public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is owned {
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
        Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
  @title NeCashTokenSale
**/
contract NeCashTokenSale is owned, Pausable {

    using SafeMath for uint256;

    /**
        EVENTS
    **/
    event Purchase(address indexed buyer, uint256 weiAmount, uint256 tokenAmount);
    event Finalized(uint256 tokensSold, uint256 weiAmount);

    /**
        CONTRACT VARIABLES
    **/
    NecashToken public necashToken;

    uint256 public startTime;
    uint256 public weiRaised;
    uint256 public tokensSold;
    bool public finalized = false;
    address public wallet;

    uint256 public maxGasPrice = 50000000000;
    uint256 public tokenPerEth = 1000;

    uint256[4] public rates;

    mapping (address => uint256) public contributors;

    uint256 public constant minimumPurchase = 0.1 ether;
    uint256 public constant maximumPurchase = 10 ether;

    /**
      @dev ICO CONSTRUCTOR
    **/
    function NeCashTokenSale() public
    {
        necashToken = NecashToken(address(0xd4e179eadf65d230c0c0ab7540edf03715596c92));

        startTime = 1530362569;
        wallet = address(0xBC03d69aF2E5c329F5b4eE09ad01AcC8A7e8F719);
    }


    /**
        PUBLIC FUNCTIONS

    **/

    /**
      @dev Fallback function that accepts eth and buy tokens
    **/
    function () payable whenNotPaused public {
        buyTokens();
    }

    /**
      @dev Allows participants to buy tokens
    **/
    function buyTokens() payable whenNotPaused public {
        require(isValidPurchase());

        uint256 amount = msg.value;
        uint256 tokens = calculateTokenAmount(amount);

        uint256 maxSellToken = necashToken.balanceOf(address(this));
        if(tokens > maxSellToken){
            uint256 possibleTokens = maxSellToken.sub(tokens);
            uint256 change = calculatePriceForTokens(tokens.sub(possibleTokens));
            msg.sender.transfer(change);
            tokens = possibleTokens;
            amount = amount.sub(change);
        }

        contributors[msg.sender] = contributors[msg.sender].add(amount);
        necashToken.transfer(msg.sender, tokens);

        tokensSold = tokensSold.add(tokens);
        weiRaised = weiRaised.add(amount);
        forwardFunds(amount);
        Purchase(msg.sender, amount, tokens);
    }

    /**
      @dev allows the owner to change the max gas price
      @param _gasPrice uint256 the new maximum gas price
    **/
    function changeMaxGasprice(uint256 _gasPrice)
      public onlyOwner whenNotPaused
    {
        maxGasPrice = _gasPrice;
    }

    /**
      @dev allows the owner to change token price
      @param _tokens uint256 the new token price
    **/
    function changeTokenPrice(uint256 _tokens)
      public onlyOwner whenNotPaused
    {
        tokenPerEth = _tokens;
    }

    /**
      @dev Triggers the finalization process
    **/
    function endSale() public onlyOwner whenNotPaused {
        require(finalized == false);
        finalizeSale();
    }

    /**
        INTERNAL FUNCTIONS

    **/

    /**
      @dev Checks if purchase is valid
      @return Bool Indicating if purchase is valid
    **/
    function isValidPurchase() view internal returns(bool valid) {
        require(now >= startTime);
        require(msg.value >= minimumPurchase);
        require(msg.value <= maximumPurchase);
        require(tx.gasprice <= maxGasPrice);
        
        return true;
    }

    /**
      @dev Internal function that redirects recieved funds to wallet
      @param _amount uint256 The amount to be fowarded
    **/
    function forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }

    /**
      @dev Calculates the amount of tokens that buyer will recieve
      @param weiAmount uint256 The amount, in Wei, that will be bought
      @return uint256 Representing the amount of tokens that weiAmount buys in
      the current stage of the sale
    **/
    function calculateTokenAmount(uint256 weiAmount) view internal returns(uint256 tokenAmount){
        return weiAmount.mul(tokenPerEth);
    }

    /**
      @dev Calculates wei cost of specific amount of tokens
      @param tokenAmount uint256 The amount of tokens to be calculated
      @return uint256 Representing the total cost, in wei, for tokenAmount
    **/
    function calculatePriceForTokens(uint256 tokenAmount) view internal returns(uint256 weiAmount){
        return tokenAmount.div(tokenPerEth);
    }

    /**
      @dev Triggers the sale finalizations process
    **/
    function finalizeSale() internal {
        finalized = true;
        Finalized(tokensSold, weiRaised);
    }
}