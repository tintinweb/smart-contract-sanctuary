pragma solidity ^0.4.21;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
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

// File: contracts/HoldToken.sol

contract HoldToken is MintableToken {
    using SafeMath for uint256;

    string public name = &#39;HOLD&#39;;
    string public symbol = &#39;HOLD&#39;;
    uint8 public decimals = 18;

    event Burn(address indexed burner, uint256 value);
    event BurnTransferred(address indexed previousBurner, address indexed newBurner);

    address burnerRole;

    modifier onlyBurner() {
        require(msg.sender == burnerRole);
        _;
    }

    function HoldToken(address _burner) public {
        burnerRole = _burner;
    }

    function transferBurnRole(address newBurner) public onlyBurner {
        require(newBurner != address(0));
        BurnTransferred(burnerRole, newBurner);
        burnerRole = newBurner;
    }

    function burn(uint256 _value) public onlyBurner {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0), _value);
    }
}

// File: contracts/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    HoldToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    uint256 public rate;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     * @param transactionId identifier which corresponds to transaction under which the tokens were purchased
     */
    event TokenPurchase(address indexed beneficiary, uint256 indexed value, uint256 indexed amount, uint256 transactionId);


    function Crowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        uint256 _initialWeiRaised
    ) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != address(0));
        require(_rate > 0);

        token = new HoldToken(_wallet);
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        weiRaised = _initialWeiRaised;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
}

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: contracts/CappedCrowdsale.sol

contract CappedCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    uint256 public hardCap;
    uint256 public tokensToLock;
    uint256 public releaseTime;
    bool public isFinalized = false;
    TokenTimelock public timeLock;

    event Finalized();
    event FinishMinting();
    event TokensMinted(
        address indexed beneficiary,
        uint256 indexed amount
    );

    function CappedCrowdsale(uint256 _hardCap, uint256 _tokensToLock, uint256 _releaseTime) public {
        require(_hardCap > 0);
        require(_tokensToLock > 0);
        require(_releaseTime > endTime);
        hardCap = _hardCap;
        releaseTime = _releaseTime;
        tokensToLock = _tokensToLock;

        timeLock = new TokenTimelock(token, wallet, releaseTime);
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);

        token.mint(address(timeLock), tokensToLock);

        Finalized();
        isFinalized = true;
    }

    function finishMinting() onlyOwner public {
        require(token.mintingFinished() == false);
        require(isFinalized);
        token.finishMinting();

        FinishMinting();
    }

    function mint(address beneficiary, uint256 amount) onlyOwner public {
        require(!token.mintingFinished());
        require(isFinalized);
        require(amount > 0);
        require(beneficiary != address(0));
        token.mint(beneficiary, amount);

        TokensMinted(beneficiary, amount);
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= hardCap;
        return super.hasEnded() || capReached || isFinalized;
    }

}

// File: contracts/OnlyWhiteListedAddresses.sol

contract OnlyWhiteListedAddresses is Ownable {
    using SafeMath for uint256;
    address utilityAccount;
    mapping (address => bool) whitelist;
    mapping (address => address) public referrals;

    modifier onlyOwnerOrUtility() {
        require(msg.sender == owner || msg.sender == utilityAccount);
        _;
    }

    event WhitelistedAddresses(
        address[] users
    );

    event ReferralsAdded(
        address[] user,
        address[] referral
    );

    function OnlyWhiteListedAddresses(address _utilityAccount) public {
        utilityAccount = _utilityAccount;
    }

    function whitelistAddress (address[] users) public onlyOwnerOrUtility {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
        WhitelistedAddresses(users);
    }

    function addAddressReferrals (address[] users, address[] _referrals) public onlyOwnerOrUtility {
        require(users.length == _referrals.length);
        for (uint i = 0; i < users.length; i++) {
            require(isWhiteListedAddress(users[i]));

            referrals[users[i]] = _referrals[i];
        }
        ReferralsAdded(users, _referrals);
    }

    function isWhiteListedAddress (address addr) public view returns (bool) {
        return whitelist[addr];
    }
}

// File: contracts/HoldCrowdsale.sol

contract HoldCrowdsale is CappedCrowdsale, OnlyWhiteListedAddresses {
    using SafeMath for uint256;

    struct TokenPurchaseRecord {
        uint256 timestamp;
        uint256 weiAmount;
        address beneficiary;
    }

    uint256 transactionId = 1;

    mapping (uint256 => TokenPurchaseRecord) pendingTransactions;
    mapping (uint256 => bool) completedTransactions;

    uint256 public referralPercentage;
    uint256 public individualCap;

    /**
     * event for token purchase logging
     * @param transactionId transaction identifier
     * @param beneficiary who will get the tokens
     * @param timestamp when the token purchase request was made
     * @param weiAmount wei invested
     */
    event TokenPurchaseRequest(
        uint256 indexed transactionId,
        address beneficiary,
        uint256 indexed timestamp,
        uint256 indexed weiAmount,
        uint256 tokensAmount
    );

    event ReferralTokensSent(
        address indexed beneficiary,
        uint256 indexed tokensAmount,
        uint256 indexed transactionId
    );

    event BonusTokensSent(
        address indexed beneficiary,
        uint256 indexed tokensAmount,
        uint256 indexed transactionId
    );

    function HoldCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _icoHardCapWei,
        uint256 _referralPercentage,
        uint256 _rate,
        address _wallet,
        uint256 _tokensToLock,
        uint256 _releaseTime,
        uint256 _privateWeiRaised,
        uint256 _individualCap,
        address _utilityAccount
    ) public
    OnlyWhiteListedAddresses(_utilityAccount)
    CappedCrowdsale(_icoHardCapWei, _tokensToLock, _releaseTime)
    Crowdsale(_startTime, _endTime, _rate, _wallet, _privateWeiRaised)
    {
        referralPercentage = _referralPercentage;
        individualCap = _individualCap;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(!isFinalized);
        require(beneficiary == msg.sender);
        require(msg.value != 0);
        require(msg.value >= individualCap);

        uint256 weiAmount = msg.value;
        require(isWhiteListedAddress(beneficiary));
        require(validPurchase(weiAmount));

        // update state
        weiRaised = weiRaised.add(weiAmount);

        uint256 _transactionId = transactionId;
        uint256 tokensAmount = weiAmount.mul(rate);

        pendingTransactions[_transactionId] = TokenPurchaseRecord(now, weiAmount, beneficiary);
        transactionId += 1;


        TokenPurchaseRequest(_transactionId, beneficiary, now, weiAmount, tokensAmount);
        forwardFunds();
    }

    function issueTokensMultiple(uint256[] _transactionIds, uint256[] bonusTokensAmounts) public onlyOwner {
        require(isFinalized);
        require(_transactionIds.length == bonusTokensAmounts.length);
        for (uint i = 0; i < _transactionIds.length; i++) {
            issueTokens(_transactionIds[i], bonusTokensAmounts[i]);
        }
    }

    function issueTokens(uint256 _transactionId, uint256 bonusTokensAmount) internal {
        require(completedTransactions[_transactionId] != true);
        require(pendingTransactions[_transactionId].timestamp != 0);

        TokenPurchaseRecord memory record = pendingTransactions[_transactionId];
        uint256 tokens = record.weiAmount.mul(rate);
        address referralAddress = referrals[record.beneficiary];

        token.mint(record.beneficiary, tokens);
        TokenPurchase(record.beneficiary, record.weiAmount, tokens, _transactionId);

        completedTransactions[_transactionId] = true;

        if (bonusTokensAmount != 0) {
            require(bonusTokensAmount != 0);
            token.mint(record.beneficiary, bonusTokensAmount);
            BonusTokensSent(record.beneficiary, bonusTokensAmount, _transactionId);
        }

        if (referralAddress != address(0)) {
            uint256 referralAmount = tokens.mul(referralPercentage).div(uint256(100));
            token.mint(referralAddress, referralAmount);
            ReferralTokensSent(referralAddress, referralAmount, _transactionId);
        }
    }

    function validPurchase(uint256 weiAmount) internal view returns (bool) {
        bool withinCap = weiRaised.add(weiAmount) <= hardCap;
        bool withinCrowdsaleInterval = now >= startTime && now <= endTime;
        return withinCrowdsaleInterval && withinCap;
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

// File: contracts/Migrations.sol

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}