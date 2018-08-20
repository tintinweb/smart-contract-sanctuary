pragma solidity ^0.4.24;

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Ownable {

  // Owner&#39;s address
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnerChanged(owner, _newOwner);
    owner = _newOwner;
  }

  event OwnerChanged(address indexed previousOwner,address indexed newOwner);

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Stoppable is Ownable {
    
    // Indicates if crowdsale is stopped
    bool public stopped = false;

    // Indicates if ELP or ETH withdrawal is enabled
    bool public withdrawalEnabled = false;

    /**
    * @dev Modifier to make a function callable only when the contract is stopped.
    */
    modifier whenStopped() {
        require(stopped);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not stopped.
    */
    modifier whenNotStopped() {
        require(!stopped);
        _;
    }

    modifier whenWithdrawalEnabled() {
        require(withdrawalEnabled);
        _;
    }

    modifier whenWithdrawalDisabled() {
        require(!withdrawalEnabled);
        _;
    }

    /**
    * @dev called by the owner to stop, triggers stopped state
    */
    function stop() public onlyOwner whenNotStopped {
        stopped = true;
        emit Stopped(owner);
    }

    /**
    * @dev called by the owner to restart, triggers restarted state
    */
    function restart() public onlyOwner whenStopped {
        stopped = false;
        withdrawalEnabled = false;
        emit Restarted(owner);
    }

    /** 
    * @dev enables withdrawals, only callable by the owner when the withdrawals are disabled
    * @notice enables withdrawals, only callable by the owner when the withdrawals are disabled
    */
    function enableWithdrawal() public onlyOwner whenStopped whenWithdrawalDisabled {
        withdrawalEnabled = true;
        emit WithdrawalEnabled(owner);
    }

    /** 
    * @dev disables withdrawals, only callable by the owner when the withdrawals are enabled
    * @notice disables withdrawals, only callable by the owner when the withdrawals are enabled
    */
    function disableWithdrawal() public onlyOwner whenWithdrawalEnabled {
        withdrawalEnabled = false;
        emit WithdrawalDisabled(owner);
    }

    /** 
    * Event for logging contract stopping
    * @param owner who owns the contract
    */
    event Stopped(address owner);
    
    /** 
    * Event for logging contract restarting
    * @param owner who owns the contract
    */
    event Restarted(address owner);

    /** 
    * Event for logging enabling withdrawals
    * @param owner who owns the contract
    */
    event WithdrawalEnabled(address owner);
    
    /** 
    * Event for logging disabling withdrawals
    * @param owner who owns the contract
    */
    event WithdrawalDisabled(address owner);
}

contract Whitelist {

    // who can whitelist
    address public whitelister;

    // Whitelist mapping
    mapping (address => bool) whitelist;

    /**
      * @dev The Whitelist constructor sets the original `whitelister` of the contract to the sender
      * account.
      */
    constructor() public {
        whitelister = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the whitelister.
      */
    modifier onlyWhitelister() {
        require(msg.sender == whitelister);
        _;
    }

    /** 
    * @dev Only callable by the whitelister. Whitelists the specified address.
    * @notice Only callable by the whitelister. Whitelists the specified address.
    * @param _address Address to be whitelisted. 
    */
    function addToWhitelist(address _address) public onlyWhitelister {
        require(_address != address(0));
        emit WhitelistAdd(whitelister, _address);
        whitelist[_address] = true;
    }
    
    /** 
    * @dev Only callable by the whitelister. Removes the specified address from whitelist.
    * @notice Only callable by the whitelister. Removes the specified address from whitelist.
    * @param _address Address to be removed from whitelist. 
    */
    function removeFromWhitelist(address _address) public onlyWhitelister {
        require(_address != address(0));
        emit WhitelistRemove(whitelister, _address);
        whitelist[_address] = false;
    }

    /**
    * @dev Checks if the specified address is whitelisted.
    * @notice Checks if the specified address is whitelisted. 
    * @param _address Address to be whitelisted.
    */
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    /**
      * @dev Changes the current whitelister. Callable only by the whitelister.
      * @notice Changes the current whitelister. Callable only by the whitelister.
      * @param _newWhitelister Address of new whitelister.
      */
    function changeWhitelister(address _newWhitelister) public onlyWhitelister {
        require(_newWhitelister != address(0));
        emit WhitelisterChanged(whitelister, _newWhitelister);
        whitelister = _newWhitelister;
    }

    /** 
    * Event for logging the whitelister change. 
    * @param previousWhitelister Old whitelister.
    * @param newWhitelister New whitelister.
    */
    event WhitelisterChanged(address indexed previousWhitelister, address indexed newWhitelister);
    
    /** 
    * Event for logging when the user is whitelisted.
    * @param whitelister Current whitelister.
    * @param whitelistedAddress User added to whitelist.
    */
    event WhitelistAdd(address indexed whitelister, address indexed whitelistedAddress);
    /** 
    * Event for logging when the user is removed from the whitelist.
    * @param whitelister Current whitelister.
    * @param whitelistedAddress User removed from whitelist.
    */
    event WhitelistRemove(address indexed whitelister, address indexed whitelistedAddress); 
}

contract ElpisCrowdsale is Stoppable, Whitelist {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Wallet for contributions
    address public wallet;

    // Cumulative wei contributions per address
    mapping (address => uint256) public ethBalances;

    // Cumulative ELP allocations per address
    mapping (address => uint256) public elpBalances;

    // USD/ETH rate
    uint256 public rate;

    // Maximum wei contribution for non-whitelisted addresses
    uint256 public threshold;

    // Amount of wei raised
    uint256 public weiRaised;

    // Amount of USD raised
    uint256 public usdRaised;

    // Amount of tokens sold so far
    uint256 public tokensSold;

    // Maximum amount of ELP tokens to be sold
    uint256 public cap;

    // Block on which crowdsale is deployed
    uint256 public deploymentBlock;

    // Amount of ELP tokens sold per phase
    uint256 public constant AMOUNT_PER_PHASE = 14500000 ether;

    /**
    * @param _rate USD/ETH rate
    * @param _threshold Maximum wei contribution for non-whitelisted addresses
    * @param _token Address of the token being sold
    * @param _wallet Address of the wallet for contributions
    */
    constructor(uint256 _rate, uint256 _threshold, uint256 _cap, ERC20 _token, address _wallet) public {
        require(_rate > 0);
        require(_threshold > 0);
        require(_cap > 0);
        require(_token != address(0));
        require(_wallet != address(0));

        rate = _rate;
        threshold = _threshold;
        cap = _cap;
        token = _token;
        wallet = _wallet;
        deploymentBlock = block.number;
    }

    /**
    * @dev Sets the USD/ETH rate
    * @param _rate USD/ETH rate
    */
    function setRate(uint256 _rate) public onlyOwner {
        emit RateChanged(owner, rate, _rate);
        rate = _rate;
    }

    /**
    * @dev Sets the threshold
    * @param _threshold Maximum wei contribution for non-whitelisted addresses
    */
    function setThreshold(uint256 _threshold) public onlyOwner {
        emit ThresholdChanged(owner, threshold, _threshold);
        threshold = _threshold;
    }

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable whenNotStopped {
        uint256 weiAmount = msg.value;
        require(_beneficiary != address(0));
        require(weiAmount != 0);
        weiRaised = weiRaised.add(weiAmount);
        require(weiRaised <= cap);

        uint256 dollars = _getUsdAmount(weiAmount);
        uint256 tokens = _getTokenAmount(dollars);

        // update state & statistics
        uint256 previousEthBalance = ethBalances[_beneficiary];
        ethBalances[_beneficiary] = ethBalances[_beneficiary].add(weiAmount);
        elpBalances[_beneficiary] = elpBalances[_beneficiary].add(tokens);
        tokensSold = tokensSold.add(tokens);
        usdRaised = usdRaised.add(dollars);

        if (ethBalances[_beneficiary] > threshold) {
            whitelist[_beneficiary] = false;
            // Transfer difference (up to threshold) to wallet
            // if previous balance is lower than threshold
            if (previousEthBalance < threshold)
                wallet.transfer(threshold - previousEthBalance);
            emit NeedKyc(_beneficiary, weiAmount, ethBalances[_beneficiary]);
        } else {
            whitelist[_beneficiary] = true;
            // When cumulative contributions for address are lower
            // than threshold, transfer whole contribution to wallet
            wallet.transfer(weiAmount);
            emit Contribution(_beneficiary, weiAmount, ethBalances[_beneficiary]);
        }

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

    /**
    * @notice Withdraws the tokens. For whitelisted contributors it withdraws ELP tokens.
    * For non-whitelisted contributors it withdraws the threshold amount of ELP tokens,
    * everything above the threshold amount is transfered back to contributor as ETH.
    */
    function withdraw() external whenWithdrawalEnabled {
        uint256 ethBalance = ethBalances[msg.sender];
        require(ethBalance > 0);
        uint256 elpBalance = elpBalances[msg.sender];

        // reentrancy protection
        elpBalances[msg.sender] = 0;
        ethBalances[msg.sender] = 0;

        if (isWhitelisted(msg.sender)) {
            // Transfer all ELP tokens to contributor
            token.transfer(msg.sender, elpBalance);
        } else {
            // Transfer threshold equivalent ELP amount based on average price
            token.transfer(msg.sender, elpBalance.mul(threshold).div(ethBalance));

            if (ethBalance > threshold) {
                // Excess amount (over threshold) of contributed ETH is
                // transferred back to non-whitelisted contributor
                msg.sender.transfer(ethBalance - threshold);
            }
        }
        emit Withdrawal(msg.sender, ethBalance, elpBalance);
    }

    /**
    * @dev This method can be used by the owner to extract mistakenly sent tokens
    * or Ether sent to this contract.
    * @param _token address The address of the token contract that you want to
    * recover set to 0 in case you want to extract ether. It can&#39;t be ElpisToken.
    */
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(token));
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 tokenReference = ERC20(_token);
        uint balance = tokenReference.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

    /**
    * @dev Checks how much of ELP tokens one can get for the specified USD amount.
    * @param _usdAmount Specified USD amount.
    * @return Returns how much ELP tokens you can currently get for the specified USD amount.
    */
    function _getTokenAmount(uint256 _usdAmount) internal view returns (uint256) {
        uint256 phase = getPhase();
        uint256 initialPriceNumerator = 110;
        uint256 initialPriceDenominator = 1000;

        uint256 scaleNumerator = 104 ** phase;
        uint256 scaleDenominator = 100 ** phase;

        return _usdAmount.mul(initialPriceNumerator).mul(scaleNumerator).div(initialPriceDenominator).div(scaleDenominator);
    }

    /**
    * @dev Gets the USD amount for specified wei amount
    * @param _weiAmount Specified wei amount
    * @return Returns USD amount based on wei amount
    */
    function _getUsdAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

    /**
    * @notice Gets the current phase of crowdsale.
    * Tokens have different price during each phase.
    * @return Returns the current crowdsale phase.
    */
    function getPhase() public view returns (uint256) {
        return tokensSold / AMOUNT_PER_PHASE;
    }

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * Event for rate change logging
    * @param owner who owns the contract
    * @param oldValue old USD/ETH rate
    * @param newValue new USD/ETH rate
    */
    event RateChanged(address indexed owner, uint256 oldValue, uint256 newValue);

    /**
    * Event for rate change logging
    * @param owner who owns the contract
    * @param oldValue old maximum wei contribution for non-whitelisted addresses value
    * @param newValue new maximum wei contribution for non-whitelisted addresses value
    */
    event ThresholdChanged(address indexed owner, uint256 oldValue, uint256 newValue);

    /**
    * @param beneficiary who is the recipient of tokens from the contribution
    * @param contributionAmount Amount of ETH contributor has contributed
    * @param totalAmount Total amount of ETH contributor has contributed
    */
    event Contribution(address indexed beneficiary, uint256 contributionAmount, uint256 totalAmount);

    /**
    * @param beneficiary who is the recipient of tokens from the contribution
    * @param contributionAmount Amount of ETH contributor has contributed
    * @param totalAmount Total amount of ETH contributor has contributed
    */
    event NeedKyc(address indexed beneficiary, uint256 contributionAmount, uint256 totalAmount);

    /**
    * @param beneficiary who is the recipient of tokens from the contribution
    * @param ethBalance ETH balance of the recipient of tokens from the contribution
    * @param elpBalance ELP balance of the recipient of tokens from the contribution
    */
    event Withdrawal(address indexed beneficiary, uint256 ethBalance, uint256 elpBalance);

    /**
    * @param token claimed token
    * @param owner who owns the contract
    * @param amount amount of the claimed token
    */
    event ClaimedTokens(address indexed token, address indexed owner, uint256 amount);
}