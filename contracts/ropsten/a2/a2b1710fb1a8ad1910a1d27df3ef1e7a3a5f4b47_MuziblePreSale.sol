/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}







/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * @dev Standard math utilities missing in the Solidity language.
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
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}





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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );

  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}











/// @title Base PreSale contract for MrToken projects
/// @dev Explanation of some abbrev used in the comments:
/// TKNbits - Tokens amount in base units (with decimals)
/// USDc - USD amount in base units (cents)
/// PPM - parts per milion 1e-6
/// PPB - parts per bilion 1e-9
/// CRY - native cryptocurency of given chain (ETH, MATIC, etc...)
abstract contract PreSale is Ownable {

  using SafeMath for uint256;

  uint constant PPM = 1e6;

  struct Stage {
    // Assigned TKNbits per wallet address
    mapping(address => uint256) balances;
    // TKNbits sold to external addresses
    uint256 soldExt;
    // TKNbits sold internally on platform
    uint256 soldInt;
  }

  // ERC20 token being sold
  IERC20 immutable token;
  // CRY - USD price feed
  AggregatorInterface immutable priceFeed;
  // Address where funds are collected
  address immutable public wallet;
  // Total number of configured stages
  uint256 immutable public stageCount;
  // ID of current PreSale stage
  uint256 public currentStage;

  // Presale stages
  mapping(uint256 => Stage) stages;
  // Already claimed TKNbits per wallet address
  mapping(address => uint256) claimed;
  // Sale active flag
  bool public active;
  // Date of tokens release
  uint256 releaseDate;


  // Published events
  event SaleStarted(uint256 stageId);
  event SaleFinished(uint256 stageId, uint256 tknbits);
  event PurchaseAccepted(address beneficiary, uint256 tknbits);
  event TokensReleased();

  /** Constructor of new presale contract
   * @param wallet_ Address of the wallet receiving collected CRY
   * @param stageCount_ Number of stages
   * @param token_ Contract of ERC20 token being soled under this presale
   * @param ethPriceFeed_ Address of price feed oracle
   */
  constructor(address wallet_, uint256 stageCount_, IERC20 token_, AggregatorInterface ethPriceFeed_) {
    require(wallet_ != address(0));
    require(stageCount_ > 0);
    require(address(token_) != address(0));
    require(address(ethPriceFeed_) != address(0));

    wallet = wallet_;
    stageCount = stageCount_;
    token = token_;
    priceFeed = ethPriceFeed_;
  }

  receive() external payable {
    revert("Direct payments are not possible in our presale");
  }

  /** Virtual method providing stage capacity to be implemented by specific presale contract
   * @param stageId_ Id of presale stage
   * @return Capacity of given stage in TKNbits
   */
  function capacity(uint256 stageId_) public view virtual returns (uint256);

  /** Virtual method providing stage sale parameters to be implemented by specific presale contract
   * @param stageId_ Id of presale stage
   * @return price - token price in USDc
   * @return minPurchase - minimum presale purchase in TKNbits
   * @return maxPurchase - maximum presale stage purchase in TKNbits
   */
  function saleParams(uint256 stageId_) public view virtual returns (uint256 price, uint256 minPurchase, uint256 maxPurchase);

  /** Virtual method providing stage release parameters to be implemented by specific presale contract
   * @param stageId_ Id of presale stage
   * @return initialRelease - inital release rate expressed in PPM
   * @return releaseRate - release rate expressed in PPM / releasePeriod
   */
  function releaseParams(uint256 stageId_) public view virtual returns (uint256 initialRelease, uint256 releaseRate);

  /// @return Release period, determining rate at which tokens are being released.
  function releasePeriod() public pure virtual returns (uint256) {
    return 1 weeks;
  }

  /** Provides current price in CRY for given number of tokens
   * @param tknbits_ Number of tknbits to be bougth
   * @return Value in native chain currency corresponding to given number tokens
   */
  function latestPrice(uint256 tknbits_) public view returns (uint256) {
    (uint256 price,,) = saleParams(currentStage);
    uint256 rate = uint256(priceFeed.latestAnswer());
    // tknbits [TKN * 1e18] * price [USDc/TKN] * 1e6 / rate [USD * 1e8 /CRY] -> CRY * 1e18
    return tknbits_ * price * 1e6 / rate;
  }

  /// @notice Main PreSale entry point for purchasing tokens
  function buy() public payable whenActive {
    (uint256 price, uint256 minPurchase, uint256 maxPurchase) = saleParams(currentStage);
    Stage storage stage = stages[currentStage];
    uint256 rate = uint256(priceFeed.latestAnswer());
    // value [CRY * 1e18] * rate [USD * 1e8 /CRY] / (price [USD * 1e2 /TKN] * 1e6)-> TKN * 1e18
    // oracle price has 8 decimals, token price has 2
    uint256 tknbits =  msg.value * rate / (price * 1e6);
    // Allow 5% variation due to possible rate changes
    uint256 delta = tknbits * 5 / 100;
    uint256 balance = stage.balances[msg.sender];
    require(balance + tknbits + delta >= minPurchase, "Value lower than minimum stage purchase");
    require(balance + tknbits - delta <= maxPurchase, "Value higher than maximum stage purchase");

    // Set new balance clamped within min / max purchase limits
    stage.balances[msg.sender] = Math.max(Math.min(balance.add(tknbits), maxPurchase), minPurchase);
    uint256 soldTknbits = stage.balances[msg.sender] - balance;
    stage.soldExt += soldTknbits;
    emit PurchaseAccepted(msg.sender, soldTknbits);
    _postBuy(stage);
  }

  /** Register sale performed internally on MrToken platform
   * @param tknbits_ Number of TKNbits purchased on the platform
   */
  function internalBuy(uint256 tknbits_) external onlyOwner whenActive {
    Stage storage stage = stages[currentStage];
    stage.soldInt += tknbits_;
    _postBuy(stage);
  }

  /// @dev Updates count of sold tokens and finished sale if capacity is reached.
  function _postBuy(Stage storage stage_) internal {
    uint256 sold_ = stage_.soldExt + stage_.soldInt;
    if (sold_ >= capacity(currentStage)) {
      active = false;
      emit SaleFinished(currentStage, sold_);
    }
  }

  /// @dev Starts sale on next available stage
  function startSale() external onlyOwner whenNotActive {
    require(currentStage < stageCount, "All stages completed");
    active = true;
    emit SaleStarted(++currentStage);
  }

  /// @dev Closes current stage of presale
  function closeSale() external onlyOwner whenActive {
    active = false;
    Stage storage stage = stages[currentStage];
    emit SaleFinished(currentStage, stage.soldExt + stage.soldInt);
  }

  /// @dev Total allowance needed for presale contract claims
  function getAllowance() external view onlyOwner returns (uint256) {
    uint256 tknbits = 0;
    for(uint i = 1; i <= stageCount; i++) {
      tknbits += stages[i].soldExt;
    }
    return tknbits;
  }

  /// @dev Releases tokens to beneficaries
  function release() external onlyOwner whenNotActive whenNotReleased {
    require(currentStage == stageCount, "Not all stages completed");
    releaseDate = block.timestamp;
    emit TokensReleased();
  }

  function sold() public view returns (uint256) {
    return stages[currentStage].soldExt + stages[currentStage].soldInt;
  }

  /** @notice View on number of tokens bought by given address
   * @param beneficiary_ Address of wallet that bought some tokens
   * @return Number of TKNbits allocated to beneficiary address accross all presale stages
   */
  function boughtBy(address beneficiary_) public view returns (uint256) {
    uint256 tknbits = 0;
    for(uint i = 1; i <= stageCount; i++) {
      tknbits += stages[i].balances[beneficiary_];
    }
    return tknbits;
  }

  /** @notice View number of tokens allowed to be bought by given address in current stage
   * @param beneficiary_ Address of wallet that bought some tokens
   * @return Number of tokens still allowed for purchase in current presale stage
   */
  function allowedFor(address beneficiary_) public view returns (uint256) {
    (,, uint256 maxPurchase) = saleParams(currentStage);
    (, uint256 result) = maxPurchase.trySub(stages[currentStage].balances[beneficiary_]);
    return result;
  }

  /** @notice View on remaining token balance by given address
   * @param beneficiary_ Address of wallet that bought some tokens
   * @return Number of TKNbits still available to beneficiary address accross all presale stages
   */
  function balanceOf(address beneficiary_) public view returns (uint256) {
    return boughtBy(beneficiary_) - claimed[beneficiary_];
  }

  /** @notice View on number of tokens already released for given address
   * @param beneficiary_ Address of wallet that bought some tokens
   * @return Number of TKNbits released to beneficiary address accross all presale stages
   */
  function releasedFor(address beneficiary_) public view returns (uint256) {
    if(releaseDate == 0) {
      return 0;
    }
    uint256 elapsed = block.timestamp - releaseDate;
    uint256 tknbits = 0;
    for(uint i = 1; i <= stageCount; i++) {
      uint256 balance = stages[i].balances[beneficiary_];
      if(balance == 0) {
        continue;
      }
      (uint256 initialRelease, uint256 releaseRate) = releaseParams(i);
      tknbits += balance * Math.min(PPM, initialRelease + elapsed * releaseRate / releasePeriod());
    }
    return tknbits / PPM;
  }

  /** @notice View on number of tokens that given address can claim
   * @param beneficiary_ Address of wallet that bought some tokens
   * @return Number of TKNbits that can be claimed by a givne address
   */
  function claimableBy(address beneficiary_) public view returns (uint256) {
    return releasedFor(beneficiary_) - claimed[beneficiary_];
  }

  /** @notice Allows caller to claim previously bought tokens
   * @param tknbits_ Number of TKNbits that caller would like to claim. If 0 provided, all
   *                 claimable tokens will be transfered to the caller address.
   */
  function claim(uint256 tknbits_) external whenReleased {
    uint256 claimable = claimableBy(msg.sender);
    require(tknbits_ <= claimable, "Requested claim amount is too high");
    if(tknbits_ == 0) {
      tknbits_ = claimable;
    }
    claimed[msg.sender] += tknbits_;
    token.transferFrom(owner(), msg.sender, tknbits_);
  }

  /** @dev Allows to withdraw collected CRY from the contract
   * @param amount_ Amount to be transfered to PreSale collector address. If 0 provided, whole
   *                contract balance will be transfered out.
   */
  function withdraw(uint256 amount_) external onlyOwner whenNotActive {
    require(address(this).balance >= amount_, "Requested withdraw amount is too high");
    if (amount_ == 0) {
      amount_ = address(this).balance;
    }
    payable(wallet).transfer(amount_);
  }

  modifier whenActive() {
    require(active, "Sale is not active");
    _;
  }

  modifier whenNotActive() {
    require(!active, "Sale is active");
    _;
  }

  modifier whenReleased() {
    require(releaseDate != 0, "Tokens not yet released");
    _;
  }

  modifier whenNotReleased() {
    require(releaseDate == 0, "Tokens already released");
    _;
  }
}






contract MuziblePreSale is PreSale {

  uint256 constant USD_TO_TKNBITS = 1e20; // 1e2 (USD -> USDc) * 1e18 (USDc -> TKNbits)
  uint256 constant PCNT_TO_PPM = 1e4; // 1% -> 1e4 ppm

  // Tokenomy
  uint256 constant STAGE_COUNT = 4;
  uint256 constant STAGES_CAPACITY = 2e6 ether;

  uint256 constant STAGE1_PRICE        =    30; // USDc
  uint256 constant STAGE1_MIN_PURCHASE =   200; // USD
  uint256 constant STAGE1_MAX_PURCHASE =  2000; // USD
  uint256 constant STAGE1_INIT_RELEASE =    50; // %
  uint256 constant STAGE1_RELEASE_RATE =     2; // %

  uint256 constant STAGE2_PRICE        =    50; // USDc
  uint256 constant STAGE2_MIN_PURCHASE =   200; // USD
  uint256 constant STAGE2_MAX_PURCHASE =  5000; // USD
  uint256 constant STAGE2_INIT_RELEASE =    25; // %
  uint256 constant STAGE2_RELEASE_RATE =     2; // %

  uint256 constant STAGE3_PRICE        =    75; // USDc
  uint256 constant STAGE3_MIN_PURCHASE =   200; // USD
  uint256 constant STAGE3_MAX_PURCHASE = 13000; // USD
  uint256 constant STAGE3_INIT_RELEASE =    20; // %
  uint256 constant STAGE3_RELEASE_RATE =     2; // %

  uint256 constant STAGE4_PRICE        =   100; // USDc
  uint256 constant STAGE4_MIN_PURCHASE =   200; // USD
  uint256 constant STAGE4_MAX_PURCHASE = 13000; // USD
  uint256 constant STAGE4_INIT_RELEASE =    50; // %
  uint256 constant STAGE4_RELEASE_RATE =     2; // %

  constructor(address wallet_, IERC20 token_, AggregatorInterface ethPriceFeed_)
    PreSale(wallet_, STAGE_COUNT, token_, ethPriceFeed_) { }

  function capacity(uint256) public pure override returns (uint256) {
    return STAGES_CAPACITY;
  }

  function saleParams(uint256 stageId_) public pure override returns (uint256, uint256, uint256) {
    if(stageId_ == 1) {
      return (
        STAGE1_PRICE,
        STAGE1_MIN_PURCHASE * USD_TO_TKNBITS / STAGE1_PRICE,
        STAGE1_MAX_PURCHASE * USD_TO_TKNBITS / STAGE1_PRICE
      );
    } else if (stageId_ == 2) {
      return (
        STAGE2_PRICE,
        STAGE2_MIN_PURCHASE * USD_TO_TKNBITS / STAGE2_PRICE,
        STAGE2_MAX_PURCHASE * USD_TO_TKNBITS / STAGE2_PRICE
      );
    } else if (stageId_ == 3) {
      return (
        STAGE3_PRICE,
        STAGE3_MIN_PURCHASE * USD_TO_TKNBITS / STAGE3_PRICE,
        STAGE3_MAX_PURCHASE * USD_TO_TKNBITS / STAGE3_PRICE
      );
    } else {
      return (
        STAGE4_PRICE,
        STAGE4_MIN_PURCHASE * USD_TO_TKNBITS / STAGE4_PRICE,
        STAGE4_MAX_PURCHASE * USD_TO_TKNBITS / STAGE4_PRICE
      );
    }
  }

  function releaseParams(uint256 stageId_) public pure override returns (uint256, uint256) {
    if(stageId_ == 1) {
      return (
        STAGE1_INIT_RELEASE * PCNT_TO_PPM,
        STAGE1_RELEASE_RATE * PCNT_TO_PPM
      );
    } else if (stageId_ == 2) {
      return (
        STAGE2_INIT_RELEASE * PCNT_TO_PPM,
        STAGE2_RELEASE_RATE * PCNT_TO_PPM
      );
    } else if (stageId_ == 3) {
      return (
        STAGE3_INIT_RELEASE * PCNT_TO_PPM,
        STAGE3_RELEASE_RATE * PCNT_TO_PPM
      );
    } else {
      return (
        STAGE4_INIT_RELEASE * PCNT_TO_PPM,
        STAGE4_RELEASE_RATE * PCNT_TO_PPM
      );
    }
  }
}