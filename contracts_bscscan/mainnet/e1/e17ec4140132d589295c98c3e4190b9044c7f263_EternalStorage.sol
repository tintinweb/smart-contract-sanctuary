/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
  function decimals() external view returns (uint8);
}



/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IERC20Extended.sol";

interface IERC20WETH is IERC20Extended {
  function deposit() external payable;
}



/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IERC20WETH.sol";

interface IBasicDefinitions {
  /** START: Basic Config Getters **/

  function one() external view returns (uint256);

  function yearInSeconds() external view returns (uint256);

  function weth() external view returns (IERC20WETH);

  function acceptableDustPercentage() external view returns (uint256);

  function maxCollectorFeePercentage() external view returns (uint256);

  function whitelist(address _address) external view returns (bool);

  function investorsWhitelist(address _address) external view returns (bool);

  function maxSlippage() external view returns (uint256);

  function minSlippage() external view returns (uint256);

  function maxStreamingFee() external view returns (uint256);

  function maxEntryFee() external view returns (uint256);

  function feeCollectorPercentage() external view returns (uint256);

  function investorIsWhitelisted(address _address) external view returns (bool);

  function userCanDeposit(address _address) external view returns (bool);

  function depositsEnabled() external view returns (bool);

  function feeCollector() external view returns (address);

  function checkSlippage(
    uint256 n1,
    uint256 n2,
    uint256 slippage
  ) external pure returns (bool);

  function normalizeDecimals(uint256 decimals) external pure returns (uint256);

  function weightedAverage(
    uint256 value1,
    uint256 value2,
    uint256 weight1,
    uint256 weight2
  ) external pure returns (uint256);
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IERC20WETH.sol";

interface IEternalStorage {
  /** START: Basic Config Getters **/
  function getStrategist(address _contract) external view returns (address);

  function getClaimable(address _contract) external view returns (uint256);

  function subFromClaimable(uint256 _addAmount) external;

  function retainStreamingFee(uint256 burnAmount, address _user)
    external
    returns (uint256);

  function getWithdrawalAmount(
    uint256 withdrawalAmount,
    uint256 toClaimable,
    uint256 _realTotalSupply
  ) external view returns (uint256);

  function getCurrentlyPositionedToken(address _contract)
    external
    view
    returns (IERC20Extended);

  function setCurrentlyPositionedToken(IERC20Extended _currentlyPositionedToken)
    external;

  function getEntryTimestamp(address _contract, address user)
    external
    view
    returns (uint256);

  function setEntryTimestamp(address account, uint256 timestamp) external;

  function setStrategist(address _strategist) external;

  function validateSwap(
    uint256 price, // baseado no sellAmount
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    uint256 buyTokenBalanceBeforeSwap,
    uint256 sellTokenBalanceBeforeSwap
  ) external view returns (uint256);

  function checkContractToken(
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    bool isTrade
  ) external returns (bool);

  function setupStrategy(
    uint256 _entryFee,
    uint256 _streamingFee,
    uint256 _acceptableSlippage,
    IERC20Extended _protectionToken,
    IERC20Extended _exposureToken,
    address strategyAddress
  ) external;

  function getCollectorFees() external view returns (uint256);

  function getMintAmount(
    uint256 boughtAmount,
    IERC20Extended buyToken,
    uint256 realTotalSupply
  ) external view returns (uint256);

  function retainEntryFee(uint256 mintAmount) external returns (uint256);
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/EternalStorage.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "./IEternalStorage.sol";
////import "./IERC20WETH.sol";
////import "./IBasicDefinitions.sol";

contract EternalStorage is IEternalStorage {
  using SafeMath for uint256;

  // CONSTS
  mapping(address => StrategyConfig) internal _strategiesConfig;

  IBasicDefinitions private _basicDefinitions;

  address private _owner;

  struct StrategyConfig {
    address strategist;
    uint256 streamingFee;
    uint256 entryFee;
    uint256 acceptableSlippage;
    IERC20Extended protectionToken;
    IERC20Extended exposureToken;
    IERC20Extended currentlyPositionedToken;
    mapping(address => uint256) entryTimestamp;
    uint256 claimable;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "ES:ONLY_OWNER");
    _;
  }

  modifier onlyStrategist(address contractAddress) {
    require(
      msg.sender == _strategiesConfig[contractAddress].strategist,
      "ES:ONLY_STRATEGIST"
    );
    _;
  }

  constructor(IBasicDefinitions basicDefinitions_) {
    _basicDefinitions = basicDefinitions_;
    _owner = msg.sender;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function basicDefinitions() public view returns (IBasicDefinitions) {
    return _basicDefinitions;
  }

  function changeOwner(address newOwner) public onlyOwner {
    _owner = newOwner;
  }

  function changeBasicDefinitions(IBasicDefinitions newBasicDefinitions)
    public
    onlyOwner
  {
    _basicDefinitions = newBasicDefinitions;
  }

  /** START: StrategyConfig Getters **/

  function getStrategist(address _contract)
    public
    view
    override
    returns (address)
  {
    return _strategiesConfig[_contract].strategist;
  }

  function getStreamingFee(address _contract) public view returns (uint256) {
    return _strategiesConfig[_contract].streamingFee;
  }

  function getEntryFee(address _contract) public view returns (uint256) {
    return _strategiesConfig[_contract].entryFee;
  }

  function getAcceptableSlippage(address _contract)
    public
    view
    returns (uint256)
  {
    return _strategiesConfig[_contract].acceptableSlippage;
  }

  function getProtectionToken(address _contract)
    public
    view
    returns (IERC20Extended)
  {
    return _strategiesConfig[_contract].protectionToken;
  }

  function getExposureToken(address _contract)
    public
    view
    returns (IERC20Extended)
  {
    return _strategiesConfig[_contract].exposureToken;
  }

  function getCurrentlyPositionedToken(address _contract)
    public
    view
    override
    returns (IERC20Extended)
  {
    return _strategiesConfig[_contract].currentlyPositionedToken;
  }

  function getEntryTimestamp(address _contract, address user)
    public
    view
    override
    returns (uint256)
  {
    return _strategiesConfig[_contract].entryTimestamp[user];
  }

  function getClaimable(address _contract)
    public
    view
    override
    returns (uint256)
  {
    return _strategiesConfig[_contract].claimable;
  }

  /** END: StrategyConfig Getters **/

  /** START: StrategyConfig Setters **/
  function changeStrategist(address contractAddress, address newStrategist)
    public
    onlyStrategist(contractAddress)
  {
    _strategiesConfig[contractAddress].strategist = newStrategist;
  }

  function changeStreamingFee(address contractAddress, uint256 _streamingFee)
    public
    onlyStrategist(contractAddress)
  {
    require(
      _streamingFee <= _basicDefinitions.maxStreamingFee(),
      "ES:STREAMING_FEE_TOO_HIGH"
    );

    require(
      _streamingFee < getStreamingFee(contractAddress),
      "ES:STREAMING_FEE_CANNOT_BE_HIGHER"
    );

    _strategiesConfig[contractAddress].streamingFee = _streamingFee;
  }

  function changeEntryFee(address contractAddress, uint256 _entryFee)
    public
    onlyStrategist(contractAddress)
  {
    require(
      _entryFee <= _basicDefinitions.maxEntryFee(),
      "ES:ENTRY_FEE_TOO_HIGH"
    );

    _strategiesConfig[contractAddress].entryFee = _entryFee;
  }

  function changeAcceptableSlippage(
    address contractAddress,
    uint256 _acceptableSlippage
  ) public onlyStrategist(contractAddress) {
    require(
      _acceptableSlippage <= _basicDefinitions.maxSlippage(),
      "ES:SLIPPAGE_TOO_HIGH"
    );

    require(
      _acceptableSlippage >= _basicDefinitions.minSlippage(),
      "ES:SLIPPAGE_TOO_LOW"
    );

    _strategiesConfig[contractAddress].acceptableSlippage = _acceptableSlippage;
  }

  /** START: Called by Straategy Contract */

  function setEntryTimestamp(address account, uint256 timestamp)
    public
    override
  {
    _strategiesConfig[msg.sender].entryTimestamp[account] = timestamp;
  }

  function setCurrentlyPositionedToken(IERC20Extended _currentlyPositionedToken)
    public
    override
  {
    require(
      _currentlyPositionedToken ==
        _strategiesConfig[msg.sender].protectionToken ||
        _currentlyPositionedToken ==
        _strategiesConfig[msg.sender].exposureToken,
      "ES:TOKEN_NOT_FROM_STRATEGY"
    );

    _strategiesConfig[msg.sender]
      .currentlyPositionedToken = _currentlyPositionedToken;
  }

  function addToClaimable(uint256 _addAmount) public {
    _strategiesConfig[msg.sender].claimable = getClaimable(msg.sender).add(
      _addAmount
    );
  }

  function subFromClaimable(uint256 _subAmount) public override {
    _strategiesConfig[msg.sender].claimable = getClaimable(msg.sender).sub(
      _subAmount
    );
  }

  function setStrategist(address _strategist) public override {
    _strategiesConfig[msg.sender].strategist = _strategist;
  }

  mapping(address => bool) private _strategySet;

  function strategySet(address _addr) public view returns (bool) {
    return _strategySet[_addr];
  }

  modifier requireWhitelist(address _addr) {
    require(_basicDefinitions.whitelist(_addr), "ES:TOKEN_NOT_WHITELISTED");
    _;
  }

  function setupStrategy(
    uint256 _entryFee,
    uint256 _streamingFee,
    uint256 _acceptableSlippage,
    IERC20Extended _protectionToken,
    IERC20Extended _exposureToken,
    address strategyAddress
  )
    public
    override
    requireWhitelist(address(_protectionToken))
    requireWhitelist(address(_exposureToken))
  {
    require(_strategySet[strategyAddress] == false, "ES:STRATEGY_ALREADY_SET");
    require(_protectionToken != _exposureToken, "ES:TOKENS_MUST_BE_DIFFERENT");

    require(
      _entryFee <= _basicDefinitions.maxEntryFee(),
      "ES:ENTRY_FEE_TOO_HIGH"
    );

    require(
      _streamingFee <= _basicDefinitions.maxStreamingFee(),
      "ES:STREAMING_FEE_TOO_HIGH"
    );
    require(
      _acceptableSlippage <= _basicDefinitions.maxSlippage(),
      "ES:SLIPPAGE_TOO_HIGH"
    );
    require(
      _acceptableSlippage >= _basicDefinitions.minSlippage(),
      "ES:SLIPPAGE_TOO_LOW"
    );

    _strategiesConfig[strategyAddress].streamingFee = _streamingFee;
    _strategiesConfig[strategyAddress].acceptableSlippage = _acceptableSlippage;
    _strategiesConfig[strategyAddress].entryFee = _entryFee;

    _strategiesConfig[strategyAddress].protectionToken = _protectionToken;
    _strategiesConfig[strategyAddress].exposureToken = _exposureToken;
    _strategiesConfig[strategyAddress]
      .currentlyPositionedToken = _protectionToken;

    _strategiesConfig[strategyAddress].claimable = 0;
    _strategySet[strategyAddress] = true;
  }

  /** END: StrategyConfig Setters */

  /** START: Strategy Validations */

  /**
    @notice Where the Slippage checking and dust checking (check if there is any dust left after swap)
            validations are made. Since the swaps rely a lot on 0x and,
            these are basic validations that should be made after a swap is executed. If any of them fail,
            the transaction is reverted
    @param sellToken the selling token address
    @param buyToken the buy token address
    @param buyTokenBalanceBeforeSwap the buy token balance balance befere the swap (stored in the _fillQuote function)
    @param sellTokenBalanceBeforeSwap the sell Token Balance before the swap (stored in the _fillQuote function)
  */
  function validateSwap(
    uint256 price, // based on 0x API "sellAmount" key
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    uint256 buyTokenBalanceBeforeSwap,
    uint256 sellTokenBalanceBeforeSwap
  ) public view override returns (uint256) {
    uint256 buyTokenBalanceAfterSwap = buyToken.balanceOf(msg.sender);

    require(
      buyTokenBalanceAfterSwap > buyTokenBalanceBeforeSwap,
      "ES:TOKEN_NOT_BOUGHT"
    );

    uint256 sellTokenBalanceAfterSwap = sellToken.balanceOf(msg.sender);

    require(
      sellTokenBalanceAfterSwap < sellTokenBalanceBeforeSwap,
      "ES:TOKEN_NOT_SOLD"
    );

    uint256 normalizedBuyTokenDelta =
      (buyTokenBalanceAfterSwap - buyTokenBalanceBeforeSwap).mul(
        _basicDefinitions.normalizeDecimals(buyToken.decimals()) // 8
      );

    uint256 validationPrice =
      normalizedBuyTokenDelta.mul(_basicDefinitions.one()).div(
        // sellTokenDelta:
        (sellTokenBalanceBeforeSwap - sellTokenBalanceAfterSwap).mul(
          _basicDefinitions.normalizeDecimals(sellToken.decimals())
        )
      );

    require(
      _basicDefinitions.checkSlippage(
        price,
        validationPrice,
        getAcceptableSlippage(msg.sender)
      ),
      "ES:INTERVAL_OUT_OF_RANGE"
    );

    uint256 acceptableDust =
      _basicDefinitions.acceptableDustPercentage().mul(validationPrice);

    require(
      sellTokenBalanceAfterSwap <= acceptableDust,
      "ES:DUST_HIGHER_THAN_EXPECTED"
    );

    return normalizedBuyTokenDelta;
  }

  function checkContractToken(
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    bool isTrade
  )
    public
    view
    override
    requireWhitelist(address(sellToken))
    requireWhitelist(address(buyToken))
    returns (bool _check)
  {
    if (
      getCurrentlyPositionedToken(msg.sender) == buyToken &&
      _basicDefinitions.weth() == sellToken &&
      isTrade == false
    ) {
      return true;
    }
    if (
      getCurrentlyPositionedToken(msg.sender) == getProtectionToken(msg.sender)
    ) {
      return
        isTrade
          ? (sellToken == getProtectionToken(msg.sender) &&
            buyToken == getExposureToken(msg.sender))
          : (sellToken == getExposureToken(msg.sender) &&
            buyToken == getProtectionToken(msg.sender));
    } else {
      return
        isTrade
          ? (sellToken == getExposureToken(msg.sender) &&
            buyToken == getProtectionToken(msg.sender))
          : (sellToken == getProtectionToken(msg.sender) &&
            buyToken == getExposureToken(msg.sender));
    }
  }

  /**
    @notice a function to check the slippage between 2 numbers
  */

  /** END: Strategy Validations */

  /** START: Fee gathering */
  /**
    @notice called upon withdrawal request
   */
  function retainStreamingFee(uint256 burnAmount, address _user)
    external
    override
    returns (uint256)
  {
    if (_user != getStrategist(msg.sender)) {
      require(
        block.timestamp > getEntryTimestamp(msg.sender, _user),
        "ES:WRONG_TIMESTAMP"
      );

      uint256 diffInSeconds =
        block.timestamp.sub(getEntryTimestamp(msg.sender, _user));

      uint256 fee =
        diffInSeconds >= _basicDefinitions.yearInSeconds()
          ? getStreamingFee(msg.sender)
          : getStreamingFee(msg.sender)
            .mul(diffInSeconds)
            .mul(_basicDefinitions.one())
            .div(_basicDefinitions.yearInSeconds());

      uint256 toClaimable = burnAmount.mul(fee).div(_basicDefinitions.one());

      require(
        toClaimable <=
          burnAmount.mul(getStreamingFee(msg.sender)).div(
            _basicDefinitions.one()
          ),
        "ES:CLAIMABLE_TOO_HIGH"
      );

      require(
        burnAmount.sub(toClaimable) <= burnAmount,
        "ES:STREAMING_FEE_CALC_ERROR"
      );

      addToClaimable(toClaimable);

      return toClaimable;
    }
    return 0;
  }

  /**
    @notice Auxiliary function to calculate the amount of the currently positioned token the user
            wishes to withdraw, in proportion to the amount of strategy token he sends on withdrawal request
    @param withdrawalAmount The amount of strategy tokens the user sends to receive the 
                            equivalent currently positioned tokens.
    @param toClaimable Amount that has been retrieved to the user based on streaming fees.
    @dev All token balances must be normalized in 18 decimals in order to make the proportion calculus work.
         This is caused because of the ERC20 decimals difference. WBTC has 8 decimals white WETH has 18 and USDC has 6.
  */
  function getWithdrawalAmount(
    uint256 withdrawalAmount,
    uint256 toClaimable,
    uint256 _realTotalSupply
  ) external view override returns (uint256) {
    uint256 userStrategyTokenSlicePercentage =
      withdrawalAmount.mul(_basicDefinitions.one()).div(
        _realTotalSupply - toClaimable
      );

    uint256 withdrawTokenAmount =
      getCurrentlyPositionedToken(msg.sender)
        .balanceOf(msg.sender)
        .mul(userStrategyTokenSlicePercentage)
        .div(_basicDefinitions.one());

    delete userStrategyTokenSlicePercentage;

    return withdrawTokenAmount;
  }

  function getMintAmount(
    uint256 boughtAmount,
    IERC20Extended buyToken,
    uint256 realTotalSupply
  ) public view override returns (uint256) {
    // percentual do usuário total de tokens que está atualmente posicionado
    // Na hipótese que não é possível manipular a proporção 0/100% dos tokens. Garantido pelo validateSwap
    uint256 percentual =
      boughtAmount.mul(_basicDefinitions.one()).div(
        buyToken.balanceOf(msg.sender).mul(
          _basicDefinitions.normalizeDecimals(buyToken.decimals())
        )
      );

    uint256 mintAmount =
      realTotalSupply
        .mul(_basicDefinitions.one())
        .div(uint256(_basicDefinitions.one()).sub(percentual))
        .sub(realTotalSupply);

    return mintAmount;
  }

  /**
    @notice called upon deposit.
            Strategist must also have his entry fee retained
  **/
  function retainEntryFee(uint256 mintAmount)
    external
    override
    returns (uint256)
  {
    uint256 toClaimable =
      mintAmount.mul(getEntryFee(msg.sender)).div(_basicDefinitions.one());

    addToClaimable(toClaimable);

    return mintAmount.sub(toClaimable);
  }

  function getCollectorFees() public view override returns (uint256) {
    return
      getClaimable(msg.sender)
        .mul(_basicDefinitions.feeCollectorPercentage())
        .div(_basicDefinitions.one());
  }
}