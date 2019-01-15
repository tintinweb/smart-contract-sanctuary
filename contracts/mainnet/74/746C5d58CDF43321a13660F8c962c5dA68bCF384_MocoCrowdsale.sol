pragma solidity ^0.5.0;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Whitelisted.sol

contract Whitelisted is Ownable {

    mapping (address => uint16) public whitelist;
    mapping (address => bool) public provider;

    // Only whitelisted
    modifier onlyWhitelisted {
      require(isWhitelisted(msg.sender));
      _;
    }

      modifier onlyProvider {
        require(isProvider(msg.sender));
        _;
      }

      // Check if address is KYC provider
      function isProvider(address _provider) public view returns (bool){
        if (owner() == _provider){
          return true;
        }
        return provider[_provider] == true ? true : false;
      }
      // Set new provider
      function setProvider(address _provider) public onlyOwner {
         provider[_provider] = true;
      }
      // Deactive current provider
      function deactivateProvider(address _provider) public onlyOwner {
         require(provider[_provider] == true);
         provider[_provider] = false;
      }
      // Set purchaser to whitelist with zone code
      function setWhitelisted(address _purchaser, uint16 _zone) public onlyProvider {
         whitelist[_purchaser] = _zone;
      }
      // Delete purchaser from whitelist
      function deleteFromWhitelist(address _purchaser) public onlyProvider {
         whitelist[_purchaser] = 0;
      }
      // Get purchaser zone code
      function getWhitelistedZone(address _purchaser) public view returns(uint16) {
        return whitelist[_purchaser] > 0 ? whitelist[_purchaser] : 0;
      }
      // Check if purchaser is whitelisted : return true or false
      function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
      }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5e2c3b333d311e6c">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b9d8d5dcc1dcc0f9d4d0c1dbc0cddcca97d0d6">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer fund with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn&#39;t be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn&#39;t necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime Crowdsale opening time
     * @param closingTime Crowdsale closing time
     */
    constructor (uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime >= block.timestamp);
        require(closingTime > openingTime);

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}

// File: openzeppelin-solidity/contracts/crowdsale/distribution/PostDeliveryCrowdsale.sol

/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostDeliveryCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address beneficiary) public {
        require(hasClosed());
        uint256 amount = _balances[beneficiary];
        require(amount > 0);
        _balances[beneficiary] = 0;
        _deliverTokens(beneficiary, amount);
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Overrides parent by storing balances instead of issuing tokens right away.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    }

}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: openzeppelin-solidity/contracts/crowdsale/emission/AllowanceCrowdsale.sol

/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _tokenWallet;

    /**
     * @dev Constructor, takes token wallet address.
     * @param tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
     */
    constructor (address tokenWallet) public {
        require(tokenWallet != address(0));
        _tokenWallet = tokenWallet;
    }

    /**
     * @return the address of the wallet that will hold the tokens.
     */
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    /**
     * @dev Checks the amount of tokens left in the allowance.
     * @return Amount of tokens left in the allowance
     */
    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

    /**
     * @dev Overrides parent behavior by transferring tokens from wallet.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }
}

// File: contracts/MocoCrowdsale.sol

contract MocoCrowdsale is TimedCrowdsale, AllowanceCrowdsale, Whitelisted {
  // Amount of wei raised

  uint256 public bonusPeriod;

  uint256 public bonusAmount;
  // Unlock period 1 - 6 month
  uint256 private _unlock1;

  // Unlock period 2 - 12 month
  uint256 private _unlock2;

  // Specify locked zone for 2nd period
  uint8 private _lockedZone;

  // Total tokens distributed
  uint256 private _totalTokensDistributed;


  // Total tokens locked
  uint256 private _totalTokensLocked;


  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    address asset,
    uint256 value,
    uint256 amount
  );

  struct Asset {
    uint256 weiRaised;
    uint256 minAmount;
    uint256 rate;
    bool active;
  }

  mapping (address => Asset) private asset;
  mapping (address => uint256) private _balances;


  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _unlockPeriod1,
    uint256 _unlockPeriod2,
    uint256 _bonusPeriodEnd,
    uint256 _bonusAmount,
    uint256 _rate,
    address payable _wallet,
    IERC20 _token,
    address _tokenWallet
  ) public
  TimedCrowdsale(_openingTime, _closingTime)
  Crowdsale(_rate, _wallet, _token)
  AllowanceCrowdsale(_tokenWallet){
       _unlock1 = _unlockPeriod1;
       _unlock2 = _unlockPeriod2;
       bonusPeriod = _bonusPeriodEnd;
      bonusAmount  = _bonusAmount;
      asset[address(0)].rate  = _rate;
  }
  function getAssetRaised(address _assetAddress) public view returns(uint256) {
      return asset[_assetAddress].weiRaised;
  }
  function getAssetMinAmount(address _assetAddress) public view returns(uint256) {
      return asset[_assetAddress].minAmount;
  }
  function getAssetRate(address _assetAddress) public view returns(uint256) {
      return asset[_assetAddress].rate;
  }
  function isAssetActive(address _assetAddress) public view returns(bool) {
      return asset[_assetAddress].active == true ? true : false;
  }
  // Add asset
  function setAsset(address _assetAddress, uint256 _weiRaised, uint256 _minAmount, uint256 _rate) public onlyOwner {
      asset[_assetAddress].weiRaised = _weiRaised;
      asset[_assetAddress].minAmount = _minAmount;
      asset[_assetAddress].rate = _rate;
      asset[_assetAddress].active = true;
  }

  //

  function weiRaised(address _asset) public view returns (uint256) {
    return asset[_asset].weiRaised;
  }
  function _getTokenAmount(uint256 weiAmount, address asst)
    internal view returns (uint256)
  {
    return weiAmount.mul(asset[asst].rate);
  }

  function minAmount(address _asset) public view returns (uint256) {
    return asset[_asset].minAmount;
  }

  // Buy Tokens
  function buyTokens(address beneficiary) public onlyWhitelisted payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount, address(0));

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount, address(0));

    // update state
    asset[address(0)].weiRaised = asset[address(0)].weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);

    emit TokensPurchased(
      msg.sender,
      beneficiary,
      address(0),
      weiAmount,
      tokens
    );

    // super._updatePurchasingState(beneficiary, weiAmount);

    super._forwardFunds();
    // super._postValidatePurchase(beneficiary, weiAmount);
  }
  // Buy tokens for assets
  function buyTokensAsset(address beneficiary, address asst, uint256 amount) public onlyWhitelisted {
     require(isAssetActive(asst));
    _preValidatePurchase(beneficiary, amount, asst);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(amount, asst);

    // update state
    asset[asst].weiRaised = asset[asst].weiRaised.add(amount);

    _processPurchase(beneficiary, tokens);

    emit TokensPurchased(
      msg.sender,
      beneficiary,
      asst,
      amount,
      tokens
    );

     address _wallet  = wallet();
     IERC20(asst).safeTransferFrom(beneficiary, _wallet, amount);

    // super._postValidatePurchase(beneficiary, weiAmount);
  }

  // Check if locked is end
  function lockedHasEnd() public view returns (bool) {
    return block.timestamp > _unlock1 ? true : false;
  }
  // Check if locked is end
  function lockedTwoHasEnd() public view returns (bool) {
    return block.timestamp > _unlock2 ? true : false;
  }
// Withdraw tokens after locked period is finished
  function withdrawTokens(address beneficiary) public {
    require(lockedHasEnd());
    uint256 amount = _balances[beneficiary];
    require(amount > 0);
    uint256 zone = super.getWhitelistedZone(beneficiary);
    if (zone == 840){
      // require(lockedTwoHasEnd());
      if(lockedTwoHasEnd()){
        _balances[beneficiary] = 0;
        _deliverTokens(beneficiary, amount);
      }
    } else {
    _balances[beneficiary] = 0;
    _deliverTokens(beneficiary, amount);
    }
  }

  // Locked tokens balance
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }
  // Pre validation token buy
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount,
    address asst
  )
    internal
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
    require(weiAmount >= minAmount(asst));
}
  function getBonusAmount(uint256 _tokenAmount) public view returns(uint256) {
    return block.timestamp < bonusPeriod ? _tokenAmount.div(bonusAmount) : 0;
  }

  function calculateTokens(uint256 _weiAmount) public view returns(uint256) {
    uint256 tokens  = _getTokenAmount(_weiAmount);
    return  tokens + getBonusAmount(tokens);
  }
  function lockedTokens(address beneficiary, uint256 tokenAmount) public onlyOwner returns(bool) {
    _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    return true;
  }
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    uint256 zone = super.getWhitelistedZone(beneficiary);
   uint256 bonusTokens = getBonusAmount(tokenAmount);
    if (zone == 840){
      uint256 totalTokens = bonusTokens.add(tokenAmount);
      _balances[beneficiary] = _balances[beneficiary].add(totalTokens);
    }
    else {
      super._deliverTokens(beneficiary, tokenAmount);
      _balances[beneficiary] = _balances[beneficiary].add(bonusTokens);
    }

  }

}