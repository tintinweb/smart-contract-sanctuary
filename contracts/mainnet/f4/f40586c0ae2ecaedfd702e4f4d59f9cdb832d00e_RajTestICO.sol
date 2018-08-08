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
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract RajTest is owned {
    // Public variables of the token
    string public name = "RajTest";
    string public symbol = "RT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    
    uint256 public sellPrice = 1045;
    uint256 public buyPrice = 1045;

    bool public released = false;
    
    /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
    address public crowdsaleAgent;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
   
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function RajTest() public {
    }
    modifier canTransfer() {
        require(released);
       _;
     }

    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }

    function releaseTokenTransfer() public onlyCrowdsaleAgent {
        released = true;
    }
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) canTransfer internal {
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

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyCrowdsaleAgent public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) canTransfer public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }

    /// @dev Set the contract that can call release and make the token transferable.
    /// @param _crowdsaleAgent crowdsale contract address
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner public {
        crowdsaleAgent = _crowdsaleAgent;
    }
}

contract Killable is owned {
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

contract RajTestICO is owned, Killable {
    /// The token we are selling
    RajTest public token;

    /// Current State Name
    string public state = "Pre ICO";

    /// the UNIX timestamp start date of the crowdsale
    uint public startsAt = 1521709200;

    /// the UNIX timestamp end date of the crowdsale
    uint public endsAt = 1521711000;

    /// the price of token
    uint256 public TokenPerETH = 1045;

    /// Has this crowdsale been finalized
    bool public finalized = false;

    /// the number of tokens already sold through this contract
    uint public tokensSold = 0;

    /// the number of ETH raised through this contract
    uint public weiRaised = 0;

    /// How many distinct addresses have invested
    uint public investorCount = 0;

    /// How much ETH each address has invested to this crowdsale
    mapping (address => uint256) public investedAmountOf;

    /// How much tokens this crowdsale has credited for each investor address
    mapping (address => uint256) public tokenAmountOf;

    /// A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount);
    /// Crowdsale end time has been changed
    event EndsAtChanged(uint endsAt);
    /// Calculated new price
    event RateChanged(uint oldValue, uint newValue);

    function RajTestICO(address _token) {
        token = RajTest(_token);
    }

    function investInternal(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
        }

        // Update investor
        uint tokensAmount = msg.value * TokenPerETH;
        investedAmountOf[receiver] += msg.value;
        tokenAmountOf[receiver] += tokensAmount;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;

        // Tell us invest was success
        Invested(receiver, msg.value, tokensAmount);

        token.mintToken(receiver, tokensAmount);
    }

    function buy() public payable {
        investInternal(msg.sender);
    }

    function() payable {
        buy();
    }

    function setEndsAt(uint time) onlyOwner {
        require(!finalized);
        endsAt = time;
        EndsAtChanged(endsAt);
    }
    function setRate(uint value) onlyOwner {
        require(!finalized);
        require(value > 0);
        RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }

    function finalize(address receiver) public onlyOwner {
        require(endsAt < now);
        // Finalized Pre ICO crowdsele.
        finalized = true;
        // Make tokens Transferable
        token.releaseTokenTransfer();
        // Transfer Fund to owner&#39;s address
        receiver.transfer(this.balance);
    }
}