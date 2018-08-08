pragma solidity ^0.4.18;

// File: contracts/zeppelin/math/SafeMath.sol

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

// File: contracts/CrowdsaleAuthorizer.sol

/**
 * @title CrowdsaleAuthorizer
 * @dev Crowd Sale Authorizer
 */
contract CrowdsaleAuthorizer {
    mapping(address => uint256)    public participated;
    mapping(address => bool)       public whitelistAddresses;

    address                        public admin;
    uint256                        public saleStartTime;
    uint256                        public saleEndTime;
    uint256                        public increaseMaxContribTime;
    uint256                        public minContribution;
    uint256                        public maxContribution;

    using SafeMath for uint256;

    /**
    * @dev Modifier for only admin
    */
    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

    /**
    * @dev Modifier for valid address
    */
    modifier validAddress(address _addr) {
      require(_addr != address(0x0));
      require(_addr != address(this));
      _;
    }

    /**
     * @dev Contract Constructor
     * @param _saleStartTime - The Start Time of the Token Sale
     * @param _saleEndTime - The End Time of the Token Sale
     * @param _increaseMaxContribTime - Time to increase Max Contribution of the Token Sale
     * @param _minContribution - Minimum ETH contribution per contributor
     * @param _maxContribution - Maximum ETH contribution per contributor
     */
    function CrowdsaleAuthorizer(
        address _admin,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _increaseMaxContribTime,
        uint256 _minContribution,
        uint256 _maxContribution
    )
        validAddress(_admin)
        public
    {
        require(_saleStartTime > now);
        require(_saleEndTime > now);
        require(_increaseMaxContribTime > now);
        require(_saleStartTime < _saleEndTime);
        require(_increaseMaxContribTime > _saleStartTime);
        require(_maxContribution > 0);
        require(_minContribution < _maxContribution);

        admin = _admin;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        increaseMaxContribTime = _increaseMaxContribTime;

        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    event UpdateWhitelist(address _user, bool _allow, uint _time);

    /**
     * @dev Update Whitelist Address
     * @param _user - Whitelist address
     * @param _allow - eligibility
     */
    function updateWhitelist(address _user, bool _allow)
        public
        onlyAdmin
    {
        whitelistAddresses[_user] = _allow;
        UpdateWhitelist(_user, _allow, now);
    }

    /**
     * @dev Batch Update Whitelist Address
     * @param _users - Array of Whitelist addresses
     * @param _allows - Array of eligibilities
     */
    function updateWhitelists(address[] _users, bool[] _allows)
        external
        onlyAdmin
    {
        require(_users.length == _allows.length);
        for (uint i = 0 ; i < _users.length ; i++) {
            address _user = _users[i];
            bool _allow = _allows[i];
            whitelistAddresses[_user] = _allow;
            UpdateWhitelist(_user, _allow, now);
        }
    }

    /**
     * @dev Get Eligible Amount
     * @param _contributor - Contributor address
     * @param _amount - Intended contribution amount
     */
    function eligibleAmount(address _contributor, uint256 _amount)
        public
        view
        returns(uint256)
    {
        // If sales has not started or sale ended, there&#39;s no allocation
        if (!saleStarted() || saleEnded()) {
            return 0;
        }

        // Amount lesser than minimum contribution will be rejected
        if (_amount < minContribution) {
            return 0;
        }

        uint256 userMaxContribution = maxContribution;
        // If sale has past 24hrs, increase max cap
        if (now >= increaseMaxContribTime) {
            userMaxContribution = maxContribution.mul(10);
        }

        // Calculate remaining contribution for the contributor
        uint256 remainingCap = userMaxContribution.sub(participated[_contributor]);

        // Return either the amount contributed or cap whichever is lower
        return (remainingCap > _amount) ? _amount : remainingCap;
    }

    /**
     * @dev Get if sale has started
     */
    function saleStarted() public view returns(bool) {
        return now >= saleStartTime;
    }

    /**
     * @dev Get if sale has ended
     */
    function saleEnded() public view returns(bool) {
        return now > saleEndTime;
    }

    /**
     * @dev Check for eligible amount and modify participation map
     * @param _contributor - Contributor address
     * @param _amount - Intended contribution amount
     */
    function eligibleAmountCheck(address _contributor, uint256 _amount)
        internal
        returns(uint256)
    {
        // Check if contributor is whitelisted
        if (!whitelistAddresses[_contributor]) {
            return 0;
        }

        uint256 result = eligibleAmount(_contributor, _amount);
        participated[_contributor] = participated[_contributor].add(result);

        return result;
    }
}

// File: contracts/zeppelin/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/zeppelin/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/zeppelin/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: contracts/zeppelin/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

// File: contracts/zeppelin/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/zeppelin/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/PolicyPalNetworkToken.sol

/**
 * @title PolicyPalNetwork Token
 * @dev A standard ownable token
 */
contract PolicyPalNetworkToken is StandardToken, BurnableToken, Ownable {
    /**
    * @dev Token Contract Constants
    */
    string    public constant name     = "PolicyPal Network Token";
    string    public constant symbol   = "PAL";
    uint8     public constant decimals = 18;

    /**
    * @dev Token Contract Public Variables
    */
    address public  tokenSaleContract;
    bool    public  isTokenTransferable = true;


    /**
    * @dev   Token Contract Modifier
    *
    * Check if a transfer is allowed
    * Transfers are restricted to token creator & owner(admin) during token sale duration
    * Transfers after token sale is limited by `isTokenTransferable` toggle
    *
    */
    modifier onlyWhenTransferAllowed() {
        require(isTokenTransferable || msg.sender == owner || msg.sender == tokenSaleContract);
        _;
    }

    /**
     * @dev Token Contract Modifier
     * @param _to - Address to check if valid
     *
     *  Check if an address is valid
     *  A valid address is as follows,
     *    1. Not zero address
     *    2. Not token address
     *
     */
    modifier isValidDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    /**
     * @dev Enable Transfers (Only Owner)
     */
    function toggleTransferable(bool _toggle) external
        onlyOwner
    {
        isTokenTransferable = _toggle;
    }
    

    /**
    * @dev Token Contract Constructor
    * @param _adminAddr - Address of the Admin
    */
    function PolicyPalNetworkToken(
        uint _tokenTotalAmount,
        address _adminAddr
    ) 
        public
        isValidDestination(_adminAddr)
    {
        require(_tokenTotalAmount > 0);

        totalSupply_ = _tokenTotalAmount;

        // Mint all token
        balances[msg.sender] = _tokenTotalAmount;
        Transfer(address(0x0), msg.sender, _tokenTotalAmount);

        // Assign token sale contract to creator
        tokenSaleContract = msg.sender;

        // Transfer contract ownership to admin
        transferOwnership(_adminAddr);
    }

    /**
    * @dev Token Contract transfer
    * @param _to - Address to transfer to
    * @param _value - Value to transfer
    * @return bool - Result of transfer
    * "Overloaded" Function of ERC20Basic&#39;s transfer
    *
    */
    function transfer(address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Token Contract transferFrom
    * @param _from - Address to transfer from
    * @param _to - Address to transfer to
    * @param _value - Value to transfer
    * @return bool - Result of transferFrom
    *
    * "Overloaded" Function of ERC20&#39;s transferFrom
    * Added with modifiers,
    *    1. onlyWhenTransferAllowed
    *    2. isValidDestination
    *
    */
    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Token Contract burn
    * @param _value - Value to burn
    * "Overloaded" Function of BurnableToken&#39;s burn
    */
    function burn(uint256 _value)
        public
    {
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }

    /**
    * @dev Token Contract Emergency Drain
    * @param _token - Token to drain
    * @param _amount - Amount to drain
    */
    function emergencyERC20Drain(ERC20 _token, uint256 _amount) public
        onlyOwner
    {
        _token.transfer(owner, _amount);
    }
}

// File: contracts/PolicyPalNetworkCrowdsale.sol

/**
 * @title PPN Crowdsale
 * @dev Crowd Sale Contract
 */
contract PolicyPalNetworkCrowdsale is CrowdsaleAuthorizer {
    /**
    * @dev Token Crowd Sale Contract Public Variables
    */
    address                 public multiSigWallet;
    PolicyPalNetworkToken   public token;
    uint256                 public raisedWei;
    bool                    public haltSale;
    uint                    public rate;

    /**
    * @dev Modifier for valid sale
    */
    modifier validSale() {
      require(!haltSale);
      require(saleStarted());
      require(!saleEnded());
      _;
    }

    /**
     * @dev Buy Event
     */
    event Buy(address _buyer, uint256 _tokens, uint256 _payedWei);

    /**
     * @dev Token Crowd Sale Contract Constructor
     * @param _admin - Address of the Admin
     * @param _multiSigWallet - Address of Multisig wallet
     * @param _totalTokenSupply - Total Token Supply
     * @param _premintedTokenSupply - Total preminted token supply
     * @param _saleStartTime - The Start Time of the Token Sale
     * @param _saleEndTime - The End Time of the Token Sale
     * @param _increaseMaxContribTime - Time to increase max contribution
     * @param _rate - Rate of ETH to PAL
     * @param _minContribution - Minimum ETH contribution per contributor
     * @param _maxContribution - Maximum ETH contribution per contributor
     */
    function PolicyPalNetworkCrowdsale(
        address _admin,
        address _multiSigWallet,
        uint256 _totalTokenSupply,
        uint256 _premintedTokenSupply,
        uint256 _presaleTokenSupply,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _increaseMaxContribTime,
        uint    _rate,
        uint256 _minContribution,
        uint256 _maxContribution
    )
    CrowdsaleAuthorizer(
        _admin,
        _saleStartTime,
        _saleEndTime,
        _increaseMaxContribTime,
        _minContribution,
        _maxContribution
    )
        validAddress(_multiSigWallet)
        public
    {
        require(_totalTokenSupply > 0);
        require(_premintedTokenSupply > 0);
        require(_presaleTokenSupply > 0);
        require(_rate > 0);
        
        require(_premintedTokenSupply < _totalTokenSupply);
        require(_presaleTokenSupply < _totalTokenSupply);

        multiSigWallet = _multiSigWallet;
        rate = _rate;

        token = new PolicyPalNetworkToken(
            _totalTokenSupply,
            _admin
        );

        // transfer preminted tokens to company wallet
        token.transfer(multiSigWallet, _premintedTokenSupply);
        // transfer presale tokens to admin
        token.transfer(_admin, _presaleTokenSupply);
    }

    /**
     * @dev Token Crowd Sale Contract Halter
     * @param _halt - Flag to halt sale
     */
    function setHaltSale(bool _halt)
        onlyAdmin
        public
    {
        haltSale = _halt;
    }

    /**
     * @dev Token Crowd Sale payable
     */
    function() public payable {
        buy(msg.sender);
    }

    /**
     * @dev Token Crowd Sale Buy
     * @param _recipient - Address of the recipient
     */
    function buy(address _recipient) public payable
        validSale
        validAddress(_recipient)
        returns(uint256)
    {
        // Get the contributor&#39;s eligible amount
        uint256 weiContributionAllowed = eligibleAmountCheck(_recipient, msg.value);
        require(weiContributionAllowed > 0);

        // Get tokens remaining for sale
        uint256 tokensRemaining = token.balanceOf(address(this));
        require(tokensRemaining > 0);

        // Get tokens that the contributor will receive
        uint256 receivedTokens = weiContributionAllowed.mul(rate);

        // Check remaining tokens
        // If lesser, update tokens to be transfer and contribution allowed
        if (receivedTokens > tokensRemaining) {
            receivedTokens = tokensRemaining;
            weiContributionAllowed = tokensRemaining.div(rate);
        }

        // Transfer tokens to contributor
        assert(token.transfer(_recipient, receivedTokens));

        // Send ETH payment to MultiSig Wallet
        sendETHToMultiSig(weiContributionAllowed);
        raisedWei = raisedWei.add(weiContributionAllowed);

        // Check weiContributionAllowed is larger than value sent
        // If larger, transfer the excess back to the contributor
        if (msg.value > weiContributionAllowed) {
            msg.sender.transfer(msg.value.sub(weiContributionAllowed));
        }

        // Broadcast event
        Buy(_recipient, receivedTokens, weiContributionAllowed);

        return weiContributionAllowed;
    }

    /**
     * @dev Token Crowd Sale Emergency Drain
     *      In case something went wrong and ETH is stuck in contract
     * @param _anyToken - Token to drain
     */
    function emergencyDrain(ERC20 _anyToken) public
        onlyAdmin
        returns(bool)
    {
        if (this.balance > 0) {
            sendETHToMultiSig(this.balance);
        }
        if (_anyToken != address(0x0)) {
            assert(_anyToken.transfer(multiSigWallet, _anyToken.balanceOf(this)));
        }
        return true;
    }

    /**
     * @dev Token Crowd Sale
     *      Transfer ETH to MultiSig Wallet
     * @param _value - Value of ETH to send
     */
    function sendETHToMultiSig(uint256 _value) internal {
        multiSigWallet.transfer(_value);
    }
}