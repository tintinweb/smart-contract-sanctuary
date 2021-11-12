/**
 *Submitted for verification at Etherscan.io on 2021-11-12
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




interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}




interface IPreSaleRound {
  /** Provides capacity of presale round
   * @return Capacity of given presale round in TKNbits
   */
  function capacity() external view returns (uint256);

  /** Provides pressale round parameters
   * @return price - token price in USDc
   * @return minPurchase - minimum presale purchase in TKNbits
   * @return maxPurchase - maximum presale stage purchase in TKNbits
   */
  function saleParams() external view returns (
    uint256 price,
    uint256 minPurchase,
    uint256 maxPurchase);

  /** Provides presale round release parameters
   * @return initialRelease - inital release rate expressed in PPM
   * @return cliffPeriod - cliff (freeze) perriod (seconds)
   * @return distributionPeriod - distribution perriod (seconds)
   */
  function releaseParams() external view returns (
    uint256 initialRelease,
    uint256  cliffPeriod,
    uint256 distributionPeriod);

  /** Provides number of tokens bought by given address
   * @param beneficiary_ Address of wallet that bought some tokens
   * @return Number of TKNbits allocated to beneficiary address accross all presale stages
   */
  function boughtBy(address beneficiary_) external view returns (uint256);

  /** Provides total number of tokens sold during the presale round
   * @return Number of TKNbits sold both internally and externally during the presale round
   */
  function sold() external view returns (uint256);

  /** Provides number of tokens needed for release allowance
   * @return Number of TKNbits sold externally during the presale round
   */
  function allowance() external view returns (uint256);

  ///  Informs if Presale Round has already completed.
  function closed() external view returns (bool);
}











/// @title Base PreSale contract for MrToken projects
/// @dev Explanation of some abbrev used in the comments:
/// TKNbits - Tokens amount in base units (with decimals)
/// USDc - USD amount in base units (cents)
abstract contract PreSaleRoundSimple is Ownable {

  using SafeMath for uint256;

  // TKNbits sold to external addresses
  uint256 soldExt;
  // TKNbits sold internally on platform
  uint256 soldInt;

  // ETH - USD price feed
  AggregatorV3Interface immutable priceFeed;
  // True if round was started
  bool _started;
  // True if round was closed
  bool _closed;
  // Latest synchronized rate
  uint256 _rate;

  // Published events
  event SaleStarted();
  event SaleFinished(uint256 tknbits);
  event PurchaseAccepted(address beneficiary, uint256 tknbits);

  /** Constructor of new presale contract
   * @param ethPriceFeed_ Address of price feed oracle
   */
  constructor(AggregatorV3Interface ethPriceFeed_) {
    require(address(ethPriceFeed_) != address(0));

    priceFeed = ethPriceFeed_;
  }

  function capacity() public view virtual returns (uint256);

  function saleParams() public view virtual returns (
    uint256 price,
    uint256 minPurchase,
    uint256 maxPurchase);

  function releaseParams() public view virtual returns (
    uint256 initialRelease,
    uint256 cliffPeriod,
    uint256 distributionPeriod);

  receive() external payable {
    revert("Direct payments are not possible in our presale");
  }

  /** Provides current price in ETH for given number of tokens
   * @param tknbits_ Number of tknbits to be bougth
   * @return Value in native chain currency corresponding to given number tokens
   */
  function latestPrice(uint256 tknbits_) public view returns (uint256) {
    (uint256 price,,) = saleParams();
    // tknbits [TKN * 1e18] * price [USDc/TKN] * 1e6 / rate [USD * 1e8 /ETH] -> ETH * 1e18
    return tknbits_ * price * 1e6 / _rate;
  }

  /// @notice True if presale is ready to accept purchases.
  function active() public view returns (bool) {
    return _started && !_closed;
  }

  function closed() public view returns (bool) {
    return _closed;
  }

  /// @notice Main PreSale entry point for purchasing tokens
  function buy() public payable whenActive {
    (uint256 price, uint256 minPurchase, uint256 maxPurchase) = saleParams();

    // value [ETH * 1e18] * rate [USD * 1e8 /ETH] / (price [USD * 1e2 /TKN] * 1e6)-> TKN * 1e18
    // oracle price has 8 decimals, token price has 2
    uint256 tknbits =  msg.value * _rate / (price * 1e6);
    // Allow 10% variation due to possible rate changes
    uint256 delta = tknbits / 10;
    require(tknbits + delta >= minPurchase, "Value lower than minimum stage purchase");
    require(tknbits - delta <= maxPurchase, "Value higher than maximum stage purchase");

    soldExt += tknbits;
    emit PurchaseAccepted(msg.sender, tknbits);
    _postBuy();
  }

  /** Register sale performed internally on MrToken platform
   * @param tknbits_ Number of TKNbits purchased on the platform
   */
  function internalBuy(uint256 tknbits_) external onlyOwner whenActive {
    soldInt += tknbits_;
    _postBuy();
  }

  function getLatestRate() public view returns (uint256) {
    (, int256 answer, , ,) = priceFeed.latestRoundData();
    return uint256(answer);
  }

  /// @dev Update ETH/USD exchange rate
  function updateRate(uint256 rate) external onlyOwner whenActive {
    _rate = rate;
  }

  /// @dev Updates count of sold tokens and finished sale if capacity is reached.
  function _postBuy() internal {
    uint256 sold_ = soldExt + soldInt;
    if (sold_ >= capacity()) {
      _closed = true;
      emit SaleFinished(sold_);
    }
  }

  /// @dev Starts sale on next available stage
  function startSale() external onlyOwner whenNotStarted {
    _rate = getLatestRate();
    _started = true;
    emit SaleStarted();
  }

  /// @dev Closes current stage of presale
  function closeSale() external onlyOwner whenActive {
    _closed = true;
    emit SaleFinished(soldExt + soldInt);
  }

  function sold() public view returns (uint256) {
    return soldInt + soldExt;
  }

  function status() public view returns (
    bool isActive,
    uint256 soldTknbits,
    uint256 rate,
    uint256 latestRate) {
    return ( active(), sold(), _rate, getLatestRate() );
  }

  /** @dev Allows to withdraw collected ETH from the contract
   * @param amount_ Amount to be transfered to PreSale collector address. If 0 provided, whole
   *                contract balance will be transfered out.
   */
  function withdraw(address wallet_, uint256 amount_) external onlyOwner whenClosed {
    require(wallet_ != address(0));
    require(address(this).balance >= amount_, "Requested withdraw amount is too high");
    if (amount_ == 0) {
      amount_ = address(this).balance;
    }
    payable(wallet_).transfer(amount_);
  }

  modifier whenNotStarted() {
    require(!_started, "Sale was already started");
    _;
  }

  modifier whenClosed() {
    require(_closed, "Sale is not closed");
    _;
  }

  modifier whenActive() {
    require(active(), "Sale is not active");
    _;
  }
}






uint256 constant USD_TO_TKNBITS = 1e20; // 1e2 (USD -> USDc) * 1e18 (USDc -> TKNbits)
uint256 constant PCNT_TO_PPM = 1e4; // 1% -> 1e4 ppm

contract MuziblePreSaleRoundTest1 is PreSaleRoundSimple {

  // Tokenomy
  uint256 constant STAGE_CAPACITY     = 10000 ether;
  uint256 constant STAGE_PRICE        =    30; // USDc
  uint256 constant STAGE_MIN_PURCHASE =     2; // USD
  uint256 constant STAGE_MAX_PURCHASE =   200; // USD
  uint256 constant STAGE_INIT_RELEASE =    15; // %
  uint256 constant STAGE_CLIFF_PERIOD =    2 * 30 days; // seconds
  uint256 constant STAGE_DIST_PERIOD  =    6 * 30 days; // seconds

  constructor(AggregatorV3Interface ethPriceFeed_)
    PreSaleRoundSimple(ethPriceFeed_) { }

  function capacity() public pure override returns (uint256) {
    return STAGE_CAPACITY;
  }

  function saleParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_PRICE,
      STAGE_MIN_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE,
      STAGE_MAX_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE
    );
  }

  function releaseParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_INIT_RELEASE * PCNT_TO_PPM,
      STAGE_CLIFF_PERIOD,
      STAGE_DIST_PERIOD
    );
  }
}

contract MuziblePreSaleRoundTest2 is PreSaleRoundSimple {

  // Tokenomy
  uint256 constant STAGE_CAPACITY     = 10000 ether;
  uint256 constant STAGE_PRICE        =    50; // USDc
  uint256 constant STAGE_MIN_PURCHASE =     2; // USD
  uint256 constant STAGE_MAX_PURCHASE =   500; // USD
  uint256 constant STAGE_INIT_RELEASE =    20; // %
  uint256 constant STAGE_CLIFF_PERIOD =    2 * 30 days; // seconds
  uint256 constant STAGE_DIST_PERIOD  =    5 * 30 days; // seconds

  constructor(AggregatorV3Interface ethPriceFeed_)
    PreSaleRoundSimple(ethPriceFeed_) { }

  function capacity() public pure override returns (uint256) {
    return STAGE_CAPACITY;
  }

  function saleParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_PRICE,
      STAGE_MIN_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE,
      STAGE_MAX_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE
    );
  }

  function releaseParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_INIT_RELEASE * PCNT_TO_PPM,
      STAGE_CLIFF_PERIOD,
      STAGE_DIST_PERIOD
    );
  }
}

contract MuziblePreSaleRoundTest3 is PreSaleRoundSimple {

  // Tokenomy
  uint256 constant STAGE_CAPACITY     = 10000 ether;
  uint256 constant STAGE_PRICE        =    75; // USDc
  uint256 constant STAGE_MIN_PURCHASE =     2; // USD
  uint256 constant STAGE_MAX_PURCHASE =   500; // USD
  uint256 constant STAGE_INIT_RELEASE =    25; // %
  uint256 constant STAGE_CLIFF_PERIOD =    2 * 30 days; // seconds
  uint256 constant STAGE_DIST_PERIOD  =    4 * 30 days; // seconds

  constructor(AggregatorV3Interface ethPriceFeed_)
    PreSaleRoundSimple(ethPriceFeed_) { }

  function capacity() public pure override returns (uint256) {
    return STAGE_CAPACITY;
  }

  function saleParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_PRICE,
      STAGE_MIN_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE,
      STAGE_MAX_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE
    );
  }

  function releaseParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_INIT_RELEASE * PCNT_TO_PPM,
      STAGE_CLIFF_PERIOD,
      STAGE_DIST_PERIOD
    );
  }
}

contract MuziblePreSaleRoundTest4 is PreSaleRoundSimple {

  // Tokenomy
  uint256 constant STAGE_CAPACITY     = 10000 ether;
  uint256 constant STAGE_PRICE        =   100; // USDc
  uint256 constant STAGE_MIN_PURCHASE =     2; // USD
  uint256 constant STAGE_MAX_PURCHASE =   500; // USD
  uint256 constant STAGE_INIT_RELEASE =    50; // %
  uint256 constant STAGE_CLIFF_PERIOD =    2 * 30 days; // seconds
  uint256 constant STAGE_DIST_PERIOD  =    3 * 30 days; // seconds

  constructor(AggregatorV3Interface ethPriceFeed_)
    PreSaleRoundSimple(ethPriceFeed_) { }

  function capacity() public pure override returns (uint256) {
    return STAGE_CAPACITY;
  }

  function saleParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_PRICE,
      STAGE_MIN_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE,
      STAGE_MAX_PURCHASE * USD_TO_TKNBITS / STAGE_PRICE
    );
  }

  function releaseParams() public pure override returns (uint256, uint256, uint256) {
    return (
      STAGE_INIT_RELEASE * PCNT_TO_PPM,
      STAGE_CLIFF_PERIOD,
      STAGE_DIST_PERIOD
    );
  }
}