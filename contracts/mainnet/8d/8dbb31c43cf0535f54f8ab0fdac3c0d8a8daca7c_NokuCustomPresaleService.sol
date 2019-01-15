pragma solidity ^0.4.23;

// File: contracts/WhitelistableConstraints.sol

/**
 * @title WhitelistableConstraints
 * @dev Contract encapsulating the constraints applicable to a Whitelistable contract.
 */
contract WhitelistableConstraints {

    /**
     * @dev Check if whitelist with specified parameters is allowed.
     * @param _maxWhitelistLength The maximum length of whitelist. Zero means no whitelist.
     * @param _weiWhitelistThresholdBalance The threshold balance triggering whitelist check.
     * @return true if whitelist with specified parameters is allowed, false otherwise
     */
    function isAllowedWhitelist(uint256 _maxWhitelistLength, uint256 _weiWhitelistThresholdBalance)
        public pure returns(bool isReallyAllowedWhitelist) {
        return _maxWhitelistLength > 0 || _weiWhitelistThresholdBalance > 0;
    }
}

// File: contracts/Whitelistable.sol

/**
 * @title Whitelistable
 * @dev Base contract implementing a whitelist to keep track of investors.
 * The construction parameters allow for both whitelisted and non-whitelisted contracts:
 * 1) maxWhitelistLength = 0 and whitelistThresholdBalance > 0: whitelist disabled
 * 2) maxWhitelistLength > 0 and whitelistThresholdBalance = 0: whitelist enabled, full whitelisting
 * 3) maxWhitelistLength > 0 and whitelistThresholdBalance > 0: whitelist enabled, partial whitelisting
 */
contract Whitelistable is WhitelistableConstraints {

    event LogMaxWhitelistLengthChanged(address indexed caller, uint256 indexed maxWhitelistLength);
    event LogWhitelistThresholdBalanceChanged(address indexed caller, uint256 indexed whitelistThresholdBalance);
    event LogWhitelistAddressAdded(address indexed caller, address indexed subscriber);
    event LogWhitelistAddressRemoved(address indexed caller, address indexed subscriber);

    mapping (address => bool) public whitelist;

    uint256 public whitelistLength;

    uint256 public maxWhitelistLength;

    uint256 public whitelistThresholdBalance;

    constructor(uint256 _maxWhitelistLength, uint256 _whitelistThresholdBalance) internal {
        require(isAllowedWhitelist(_maxWhitelistLength, _whitelistThresholdBalance), "parameters not allowed");

        maxWhitelistLength = _maxWhitelistLength;
        whitelistThresholdBalance = _whitelistThresholdBalance;
    }

    /**
     * @return true if whitelist is currently enabled, false otherwise
     */
    function isWhitelistEnabled() public view returns(bool isReallyWhitelistEnabled) {
        return maxWhitelistLength > 0;
    }

    /**
     * @return true if subscriber is whitelisted, false otherwise
     */
    function isWhitelisted(address _subscriber) public view returns(bool isReallyWhitelisted) {
        return whitelist[_subscriber];
    }

    function setMaxWhitelistLengthInternal(uint256 _maxWhitelistLength) internal {
        require(isAllowedWhitelist(_maxWhitelistLength, whitelistThresholdBalance),
            "_maxWhitelistLength not allowed");
        require(_maxWhitelistLength != maxWhitelistLength, "_maxWhitelistLength equal to current one");

        maxWhitelistLength = _maxWhitelistLength;

        emit LogMaxWhitelistLengthChanged(msg.sender, maxWhitelistLength);
    }

    function setWhitelistThresholdBalanceInternal(uint256 _whitelistThresholdBalance) internal {
        require(isAllowedWhitelist(maxWhitelistLength, _whitelistThresholdBalance),
            "_whitelistThresholdBalance not allowed");
        require(whitelistLength == 0 || _whitelistThresholdBalance > whitelistThresholdBalance,
            "_whitelistThresholdBalance not greater than current one");

        whitelistThresholdBalance = _whitelistThresholdBalance;

        emit LogWhitelistThresholdBalanceChanged(msg.sender, _whitelistThresholdBalance);
    }

    function addToWhitelistInternal(address _subscriber) internal {
        require(_subscriber != address(0), "_subscriber is zero");
        require(!whitelist[_subscriber], "already whitelisted");
        require(whitelistLength < maxWhitelistLength, "max whitelist length reached");

        whitelistLength++;

        whitelist[_subscriber] = true;

        emit LogWhitelistAddressAdded(msg.sender, _subscriber);
    }

    function removeFromWhitelistInternal(address _subscriber, uint256 _balance) internal {
        require(_subscriber != address(0), "_subscriber is zero");
        require(whitelist[_subscriber], "not whitelisted");
        require(_balance <= whitelistThresholdBalance, "_balance greater than whitelist threshold");

        assert(whitelistLength > 0);

        whitelistLength--;

        whitelist[_subscriber] = false;

        emit LogWhitelistAddressRemoved(msg.sender, _subscriber);
    }

    /**
     * @param _subscriber The subscriber for which the balance check is required.
     * @param _balance The balance value to check for allowance.
     * @return true if the balance is allowed for the subscriber, false otherwise
     */
    function isAllowedBalance(address _subscriber, uint256 _balance) public view returns(bool isReallyAllowed) {
        return !isWhitelistEnabled() || _balance <= whitelistThresholdBalance || whitelist[_subscriber];
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts/Presale.sol

/**
 * @title Presale
 * @dev A simple Presale Contract (PsC) for deposit collection during pre-sale events.
 */
contract Presale is Whitelistable, Pausable {
    using AddressUtils for address;
    using SafeMath for uint256;

    event LogCreated(
        address caller,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        uint256 minDeposit,
        address wallet,
        address indexed providerWallet,
        uint256 maxWhitelistLength,
        uint256 whitelistThreshold
    );
    event LogMinDepositChanged(address indexed caller, uint256 indexed minDeposit);
    event LogInvestmentReceived(
        address indexed caller,
        address indexed beneficiary,
        uint256 indexed amount,
        uint256 netAmount
    );
    event LogPresaleTokenChanged(
        address indexed caller,
        address indexed presaleToken,
        uint256 indexed rate
    );

    // The start and end block where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;

    // Address where funds are collected
    address public wallet;

    // Presale minimum deposit in wei
    uint256 public minDeposit;

    // Presale balances (expressed in wei) deposited by each subscriber
    mapping (address => uint256) public balanceOf;
    
    // Amount of raised money in wei
    uint256 public raisedFunds;

    // Amount of service provider fees in wei
    uint256 public providerFees;

    // Address where service provider fees are collected
    address public providerWallet;

    // Two fee thresholds separating the raised money into three partitions
    uint256 public feeThreshold1;
    uint256 public feeThreshold2;

    // Three percentage levels for fee calculation in each partition
    uint256 public lowFeePercentage;
    uint256 public mediumFeePercentage;
    uint256 public highFeePercentage;

    // Optional ERC20 presale token (0 means no presale token)
    MintableToken public presaleToken;

    // How many ERC20 presale token units a buyer gets per wei (0 means no presale token)
    uint256 public rate;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage
    )
    Whitelistable(_maxWhitelistLength, _whitelistThreshold)
    public
    {
        require(_startBlock >= block.number, "_startBlock is lower than current block number");
        require(_endBlock >= _startBlock, "_endBlock is lower than _startBlock");
        require(_minDeposit > 0, "_minDeposit is zero");
        require(_wallet != address(0) && !_wallet.isContract(), "_wallet is zero or contract");
        require(!_providerWallet.isContract(), "_providerWallet is contract");
        require(_feeThreshold2 >= _feeThreshold1, "_feeThreshold2 is lower than _feeThreshold1");
        require(0 <= _lowFeePercentage && _lowFeePercentage <= 100, "_lowFeePercentage not in range [0, 100]");
        require(0 <= _mediumFeePercentage && _mediumFeePercentage <= 100, "_mediumFeePercentage not in range [0, 100]");
        require(0 <= _highFeePercentage && _highFeePercentage <= 100, "_highFeePercentage not in range [0, 100]");

        startBlock = _startBlock;
        endBlock = _endBlock;
        minDeposit = _minDeposit;
        wallet = _wallet;
        providerWallet = _providerWallet;
        feeThreshold1 = _feeThreshold1;
        feeThreshold2 = _feeThreshold2;
        lowFeePercentage = _lowFeePercentage;
        mediumFeePercentage = _mediumFeePercentage;
        highFeePercentage = _highFeePercentage;

        emit LogCreated(
            msg.sender,
            _startBlock,
            _endBlock,
            _minDeposit,
            _wallet,
            _providerWallet,
            _maxWhitelistLength,
            _whitelistThreshold
        );
    }

    function hasStarted() public view returns (bool ended) {
        return block.number >= startBlock;
    }

    // @return true if presale event has ended
    function hasEnded() public view returns (bool ended) {
        return block.number > endBlock;
    }

    // @return The current fee percentage based on raised funds
    function currentFeePercentage() public view returns (uint256 feePercentage) {
        return raisedFunds < feeThreshold1 ? lowFeePercentage :
            raisedFunds < feeThreshold2 ? mediumFeePercentage : highFeePercentage;
    }

    /**
     * Change the minimum deposit for each subscriber. New value shall be lower than previous.
     * @param _minDeposit The minimum deposit for each subscriber, expressed in wei
     */
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        require(0 < _minDeposit && _minDeposit < minDeposit, "_minDeposit not in range [0, minDeposit]");
        require(!hasEnded(), "presale has ended");

        minDeposit = _minDeposit;

        emit LogMinDepositChanged(msg.sender, _minDeposit);
    }

    /**
     * Change the maximum whitelist length. New value shall satisfy the #isAllowedWhitelist conditions.
     * @param _maxWhitelistLength The maximum whitelist length
     */
    function setMaxWhitelistLength(uint256 _maxWhitelistLength) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        setMaxWhitelistLengthInternal(_maxWhitelistLength);
    }

    /**
     * Change the whitelist threshold balance. New value shall satisfy the #isAllowedWhitelist conditions.
     * @param _whitelistThreshold The threshold balance (in wei) above which whitelisting is required to invest
     */
    function setWhitelistThresholdBalance(uint256 _whitelistThreshold) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        setWhitelistThresholdBalanceInternal(_whitelistThreshold);
    }

    /**
     * Add the subscriber to the whitelist.
     * @param _subscriber The subscriber to add to the whitelist.
     */
    function addToWhitelist(address _subscriber) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        addToWhitelistInternal(_subscriber);
    }

    /**
     * Removed the subscriber from the whitelist.
     * @param _subscriber The subscriber to remove from the whitelist.
     */
    function removeFromWhitelist(address _subscriber) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        removeFromWhitelistInternal(_subscriber, balanceOf[_subscriber]);
    }

    /**
     * Set the ERC20 presale token address and conversion rate.
     * @param _presaleToken The ERC20 presale token.
     * @param _rate How many ERC20 presale token units a buyer gets per wei.
     */
    function setPresaleToken(MintableToken _presaleToken, uint256 _rate) external onlyOwner {
        require(_presaleToken != presaleToken || _rate != rate, "both _presaleToken and _rate equal to current ones");
        require(!hasEnded(), "presale has ended");

        presaleToken = _presaleToken;
        rate = _rate;

        emit LogPresaleTokenChanged(msg.sender, _presaleToken, _rate);
    }

    function isAllowedBalance(address _beneficiary, uint256 _balance) public view returns (bool isReallyAllowed) {
        bool hasMinimumBalance = _balance >= minDeposit;
        return hasMinimumBalance && super.isAllowedBalance(_beneficiary, _balance);
    }

    function isValidInvestment(address _beneficiary, uint256 _amount) public view returns (bool isValid) {
        bool withinPeriod = startBlock <= block.number && block.number <= endBlock;
        bool nonZeroPurchase = _amount != 0;
        bool isAllowedAmount = isAllowedBalance(_beneficiary, balanceOf[_beneficiary].add(_amount));

        return withinPeriod && nonZeroPurchase && isAllowedAmount;
    }

    function invest(address _beneficiary) public payable whenNotPaused {
        require(_beneficiary != address(0), "_beneficiary is zero");
        require(_beneficiary != wallet, "_beneficiary is equal to wallet");
        require(_beneficiary != providerWallet, "_beneficiary is equal to providerWallet");
        require(isValidInvestment(_beneficiary, msg.value), "forbidden investment for _beneficiary");

        balanceOf[_beneficiary] = balanceOf[_beneficiary].add(msg.value);
        raisedFunds = raisedFunds.add(msg.value);

        // Optionally distribute presale token to buyer, if configured
        if (presaleToken != address(0) && rate != 0) {
            uint256 tokenAmount = msg.value.mul(rate);
            presaleToken.mint(_beneficiary, tokenAmount);
        }

        if (providerWallet == 0) {
            wallet.transfer(msg.value);

            emit LogInvestmentReceived(msg.sender, _beneficiary, msg.value, msg.value);
        }
        else {
            uint256 feePercentage = currentFeePercentage();
            uint256 fees = msg.value.mul(feePercentage).div(100);
            uint256 netAmount = msg.value.sub(fees);

            providerFees = providerFees.add(fees);

            providerWallet.transfer(fees);
            wallet.transfer(netAmount);

            emit LogInvestmentReceived(msg.sender, _beneficiary, msg.value, netAmount);
        }
    }

    function () external payable whenNotPaused {
        invest(msg.sender);
    }
}

// File: contracts/CappedPresale.sol

/**
 * @title CappedPresale
 * @dev Extension of Presale with a max amount of funds raised
 */
contract CappedPresale is Presale {
    using SafeMath for uint256;

    event LogMaxCapChanged(address indexed caller, uint256 indexed maxCap);

    // Maximum cap in wei
    uint256 public maxCap;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        uint256 _maxCap
    )
    Presale(
        _startBlock,
        _endBlock,
        _minDeposit,
        _wallet,
        _providerWallet,
        _maxWhitelistLength,
        _whitelistThreshold,
        _feeThreshold1,
        _feeThreshold2,
        _lowFeePercentage,
        _mediumFeePercentage,
        _highFeePercentage
    )
    public
    {
        require(_maxCap > 0, "_maxCap is zero");
        require(_maxCap >= _feeThreshold2, "_maxCap is lower than _feeThreshold2");
        
        maxCap = _maxCap;
    }

    /**
     * Change the maximum cap of the presale. New value shall be greater than previous one.
     * @param _maxCap The maximum cap of the presale, expressed in wei
     */
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        require(_maxCap > maxCap, "_maxCap is not greater than current maxCap");
        require(!hasEnded(), "presale has ended");
        
        maxCap = _maxCap;

        emit LogMaxCapChanged(msg.sender, _maxCap);
    }

    // overriding Presale#hasEnded to add cap logic
    // @return true if presale event has ended
    function hasEnded() public view returns (bool ended) {
        bool capReached = raisedFunds >= maxCap;
        
        return super.hasEnded() || capReached;
    }

    // overriding Presale#isValidInvestment to add extra cap logic
    // @return true if beneficiary can buy at the moment
    function isValidInvestment(address _beneficiary, uint256 _amount) public view returns (bool isValid) {
        bool withinCap = raisedFunds.add(_amount) <= maxCap;

        return super.isValidInvestment(_beneficiary, _amount) && withinCap;
    }
}

// File: contracts/NokuCustomPresale.sol

/**
 * @title NokuCustomPresale
 * @dev Extension of CappedPresale.
 */
contract NokuCustomPresale is CappedPresale {
    event LogNokuCustomPresaleCreated(
        address caller,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        uint256 minDeposit,
        address wallet,
        address indexed providerWallet,
        uint256 maxWhitelistLength,
        uint256 whitelistThreshold
    );

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        uint256 _maxCap
    )
    CappedPresale(
        _startBlock,
        _endBlock,
        _minDeposit,
        _wallet,
        _providerWallet,
        _maxWhitelistLength,
        _whitelistThreshold,
        _feeThreshold1,
        _feeThreshold2,
        _lowFeePercentage,
        _mediumFeePercentage,
        _highFeePercentage,
        _maxCap
    )
    public {
        emit LogNokuCustomPresaleCreated(
            msg.sender,
            _startBlock,
            _endBlock,
            _minDeposit,
            _wallet,
            _providerWallet,
            _maxWhitelistLength,
            _whitelistThreshold
        );
    }
}

// File: contracts/NokuPricingPlan.sol

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
contract NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

// File: contracts/NokuCustomService.sol

contract NokuCustomService is Pausable {
    using AddressUtils for address;

    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers
    NokuPricingPlan public pricingPlan;

    constructor(address _pricingPlan) internal {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");

        pricingPlan = NokuPricingPlan(_pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");
        require(NokuPricingPlan(_pricingPlan) != pricingPlan, "_pricingPlan equal to current");
        
        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: contracts/NokuCustomPresaleService.sol

/**
 * @title NokuCustomPresaleService
 * @dev Extension of NokuCustomService adding the fee payment in NOKU tokens.
 */
contract NokuCustomPresaleService is NokuCustomService {
    event LogNokuCustomPresaleServiceCreated(address indexed caller);

    bytes32 public constant SERVICE_NAME = "NokuCustomERC20.presale";
    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomPresaleServiceCreated(msg.sender);
    }

    function createCustomPresale(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        uint256 _maxCap
    )
    public returns(NokuCustomPresale customPresale)
    {
        customPresale = new NokuCustomPresale(
            _startBlock,
            _endBlock,
            _minDeposit,
            _wallet,
            _providerWallet,
            _maxWhitelistLength,
            _whitelistThreshold,
            _feeThreshold1,
            _feeThreshold2,
            _lowFeePercentage,
            _mediumFeePercentage,
            _highFeePercentage,
            _maxCap
        );

        // Transfer NokuCustomPresale ownership to the client
        customPresale.transferOwnership(msg.sender);

        require(pricingPlan.payFee(SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}