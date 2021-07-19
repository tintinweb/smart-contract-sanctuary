//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: ITRC20.sol

pragma solidity 0.6.0;

interface ITRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

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

//SourceUnit: InvestBox.sol

pragma solidity 0.6.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./Ownable.sol";
import "./TokenInfo.sol";

contract InvestBox is Ownable, TokenInfo {

  using SafeMath for uint;

  ITRC20 _IN1;
  ITRC20 _IN2;
  ITRC20 _OUT;

  string public identifier;

  uint _packageCount;
  uint _price1;
  uint _price2;
  uint _payout;
  uint _timespan;

  struct Payout {
    uint32 startTime;
    uint32 endTime;
    uint192 amount;
  }

  struct Stats {
    uint128 completed;
    uint128 total;
  }

  mapping(address => mapping(uint => Payout)) _payouts;
  mapping(address => Stats) _stats;

  event Taken(address user, uint amount);

  function takeProfit() external {
    Stats storage stats = _stats[msg.sender];
    require(stats.completed < stats.total, 'You have no stakes');
    uint profit = 0;
    for (uint256 i = stats.completed + 1; i <= stats.total; i++) {
      profit = profit.add( _take(msg.sender, i) );
    }
    require(profit > 0, 'Nothing to take');
    _OUT.transfer(msg.sender, profit);
    emit Taken(msg.sender, profit);
  }

  event Paid(address user, uint number, uint amount);

  function _take(address user, uint key) private returns (uint amount) {
    Payout storage payout = _payouts[user][key];
    uint256 start = payout.startTime;
    uint256 end = payout.endTime;
    amount = payout.amount;
    if(block.timestamp > start) {
      if(block.timestamp < end) {
        amount = amount.mul(block.timestamp - start).div(end - start);
        payout.amount = uint192( uint256(payout.amount).sub(amount) );
        payout.startTime = uint32(block.timestamp);
      } else {
        delete _payouts[user][key];
        _stats[user].completed++;
      }
      emit Paid(user, key, amount);
    } else
      amount = 0;
  }


  function availableFor(address user) public view returns (uint available) {
    Stats storage stats = _stats[user];
    available = 0;
    for (uint256 i = stats.completed + 1; i <= stats.total; i++) {
      available = available.add(
        _availableInPayout(_payouts[user][i])
      );
    }
  }

  function _availableInPayout(Payout storage payout) private view returns (uint amount) {
    uint256 start = payout.startTime;
    uint256 end = payout.endTime;
    amount = payout.amount;
    if(block.timestamp > start) {
      if(block.timestamp < end) {
        amount = amount.mul(block.timestamp - start).div(end - start);
      }
    } else {
      amount = 0;
    }
  }

  event Purchased(address user, uint number, uint start, uint end, uint price1, uint price2, uint payout);

  function buy() external {
    require(_packageCount > 0, "No available packages");
    _IN1.transferFrom(msg.sender, address(this), _price1);
    _IN2.transferFrom(msg.sender, address(this), _price2);

    Stats storage stats = _stats[msg.sender];
    _payouts[msg.sender][++stats.total] = Payout(
      uint32(block.timestamp),
      uint32(block.timestamp + _timespan),
      uint192(_payout)
    );

    _packageCount--;

    emit Purchased(msg.sender, stats.total, block.timestamp, block.timestamp + _timespan, _price1, _price2, _payout);

  }

   constructor(
    string memory id,
    address token_IN1,
    address token_IN2,
    address token_OUT,
    uint packageCount,
    uint price1,
    uint price2,
    uint payout,
    uint timespan
  ) public {
    require(token_IN1 != address(0));
    require(token_IN2 != address(0));
    require(token_OUT != address(0));
    identifier = id;
    _IN1 = ITRC20(token_IN1);
    _IN2 = ITRC20(token_IN2);
    _OUT = ITRC20(token_OUT);
    _packageCount = packageCount;
    _price1 = price1;
    _price2 = price2;
    _payout = payout;
    _timespan = timespan;
  }

  event NewParameters(uint packageCount, uint price1, uint price2, uint payout, uint timespan);

  function setParameters (
    uint packageCount,
    uint price1,
    uint price2,
    uint payout,
    uint timespan
  ) external onlyOwner {
    if(_packageCount != packageCount) _packageCount = packageCount;
    if(_price1 != price1) _price1 = price1;
    if(_price2 != price2) _price2 = price2;
    if(_payout != payout) _payout = payout;
    if(_timespan != timespan) _timespan = timespan;
    emit NewParameters(packageCount, price1, price2, payout, timespan);
  }

  function getParameters() public view returns (
    uint packageCount,
    uint price1,
    uint price2,
    uint payout,
    uint timespan
  ) {
    packageCount = _packageCount;
    price1 = _price1;
    price2 = _price2;
    payout = _payout;
    timespan = _timespan;
  }

  function IN1_tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(_IN1); }
  function IN2_tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(_IN2); }
  function OUT_tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(_OUT); }

}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
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
contract Ownable is Context {
    address private _owner;
    uint96 private _;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TokenInfo.sol

pragma solidity 0.6.0;

import "./ITRC20.sol";

contract TokenInfo {
  function _tokenInfo(ITRC20 token) internal view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) {
    name = token.name();
    symbol = token.symbol();
    decimals = token.decimals();
    tokenAddress = address(token);
  }
}