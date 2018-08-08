pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract ERC20 is owned {
    // Public variables of the token
    string public name = "PerfectChain Network";
    string public symbol = "PNN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * 10 ** uint256(decimals);

    bool public released = false;

    /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
    address public ICO_Contract;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
   
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor () public {
        balanceOf[owner] = totalSupply;
    }
    modifier canTransfer() {
        require(released ||  msg.sender == ICO_Contract || msg.sender == owner);
       _;
     }

    function releaseToken() public onlyOwner {
        released = true;
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
    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool success) {
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

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
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

contract ERC20_ICO is owned, Killable {
    /// The token we are selling
    ERC20 public token;

    /// the UNIX timestamp start date of the crowdsale
    uint256 public startsAt = 1528761600;

    /// the UNIX timestamp end date of the crowdsale
    uint256 public endsAt = 1531389600;

    /// the price of token
    uint256 public TokenPerETH = 5600;

    /// Has this crowdsale been finalized
    bool public finalized = false;

    /// the number of tokens already sold through this contract
    uint256 public tokensSold = 0;

    /// the number of ETH raised through this contract
    uint256 public weiRaised = 0;

    /// How many distinct addresses have invested
    uint256 public investorCount = 0;

    /// How much Token minimum sale.
    uint256 public Soft_Cap = 40000000000000000000000000;

    /// How much Token maximum sale.
    uint256 public Hard_Cap = 140000000000000000000000000;

    /// How much ETH each address has invested to this crowdsale
    mapping (address => uint256) public investedAmountOf;

    /// list of investor
    address[] public investorlist;

    /// A new investment was made
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    /// Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    /// Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);
    /// Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    /// Refund was processed for a contributor
    event Refund(address investor, uint256 weiAmount);

    constructor (address _token) public {
        token = ERC20(_token);
    }

    function investInternal(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);
        require(tokensSold <= Hard_Cap);
        require(msg.value >= 10000000000000000);

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
            investorlist.push(receiver) -1;
        }

        // Update investor
        uint256 tokensAmount = msg.value * TokenPerETH;
        investedAmountOf[receiver] += msg.value;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;

        // Tell us invest was success
        emit Invested(receiver, msg.value, tokensAmount);

        if (msg.value >= 100000000000000000 && msg.value < 10000000000000000000 ) {
            // 0.1-10 ETH 20% Bonus
            tokensAmount = tokensAmount * 120 / 100;
        }
        if (msg.value >= 10000000000000000000 && msg.value < 30000000000000000000) {
            // 10-30 ETH 30% Bonus
            tokensAmount = tokensAmount * 130 / 100;
        }
        if (msg.value >= 30000000000000000000) {
            // 30 ETh and more 40% Bonus
            tokensAmount = tokensAmount * 140 / 100;
        }

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