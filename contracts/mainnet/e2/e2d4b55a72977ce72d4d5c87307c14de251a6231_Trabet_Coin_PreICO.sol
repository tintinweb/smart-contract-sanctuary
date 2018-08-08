pragma solidity ^0.4.16;

contract owned {
    address public owner;

    constructor () public {
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

contract Trabet_Coin is owned {
    // Public variables of the token
    string public name = "Trabet Coin";
    string public symbol = "TC";
    uint8 public decimals = 4;
    uint256 public totalSupply = 7000000 * 10 ** uint256(decimals);

    bool public released = false;

    /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
    address public crowdsaleAgent;

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
        require(released);
       _;
     }

    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }

    function releaseToken() public onlyOwner {
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
    function mintToken(address target, uint256 mintedAmount) onlyCrowdsaleAgent public {
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

    /// @dev Set the contract that can call release and make the token transferable.
    /// @param _crowdsaleAgent crowdsale contract address
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner public {
        crowdsaleAgent = _crowdsaleAgent;
    }
}

contract Killable is owned {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}

contract Trabet_Coin_PreICO is owned, Killable {
    /// The token we are selling
    Trabet_Coin public token;

    ///fund goes to
    address public beneficiary;

    /// the UNIX timestamp start date of the crowdsale
    uint public startsAt = 1521748800;

    /// the UNIX timestamp end date of the crowdsale
    uint public endsAt = 1532563200;

    /// the price of token
    uint256 public TokenPerETH = 1065;

    /// Has this crowdsale been finalized
    bool public finalized = false;

    /// the number of tokens already sold through this contract
    uint public tokensSold = 0;

    /// the number of ETH raised through this contract
    uint public weiRaised = 0;

    /// How many distinct addresses have invested
    uint public investorCount = 0;

    /// How much wei we have given back to investors.
    uint public weiRefunded = 0;

    /// Has this crowdsale reFunding
    bool public reFunding = false;

    /// How much ETH each address has invested to this crowdsale
    mapping (address => uint256) public investedAmountOf;

    /// A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount);
    /// Crowdsale Start time has been changed
    event StartsAtChanged(uint startsAt);
    /// Crowdsale end time has been changed
    event EndsAtChanged(uint endsAt);
    /// Calculated new price
    event RateChanged(uint oldValue, uint newValue);
    /// Refund was processed for a contributor
    event Refund(address investor, uint weiAmount);

    constructor (address _token, address _beneficiary) public {
        token = Trabet_Coin(_token);
        beneficiary = _beneficiary;
    }

    function investInternal(address receiver, address refer) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);
        require(msg.value >= 100000000000000);

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
        }

        // Update investor
        uint tokensAmount = msg.value * TokenPerETH / 100000000000000;
        investedAmountOf[receiver] += msg.value;
        // Update totals
        tokensSold += tokensAmount;
        weiRaised += msg.value;

        // Tell us invest was success
        emit Invested(receiver, msg.value, tokensAmount);

        token.mintToken(receiver, tokensAmount);

        if (refer != 0x0) {
            refer.transfer(msg.value/10);
        }

        // Transfer Fund to owner&#39;s address
        beneficiary.transfer(address(this).balance);

    }

    function buy(address refer) public payable {
        investInternal(msg.sender, refer);
    }
    
    function () public payable {
        investInternal(msg.sender, 0x0);
    }
    
    function payforRefund () public payable {
    }
    function setStartsAt(uint time) onlyOwner public {
        require(!finalized);
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    function setEndsAt(uint time) onlyOwner public {
        require(!finalized);
        endsAt = time;
        emit EndsAtChanged(endsAt);
    }
    function setRate(uint value) onlyOwner public {
        require(!finalized);
        require(value > 0);
        emit RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }

    function finalize() public onlyOwner {
        // Finalized Pre ICO crowdsele.
        finalized = true;
    }

    function EnableRefund() public onlyOwner {
        // Finalized Pre ICO crowdsele.
        reFunding = true;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        // Finalized Pre ICO crowdsele.
        beneficiary = _beneficiary;
    }

    /// @dev Investors can claim refund.
    function refund() public {
        require(reFunding);
        uint256 weiValue = investedAmountOf[msg.sender];
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded + weiValue;
        emit Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }
}