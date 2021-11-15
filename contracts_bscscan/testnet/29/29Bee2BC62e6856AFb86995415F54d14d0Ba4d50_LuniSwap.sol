// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from '../dependencies/open-zeppelin/SafeMath.sol';


contract LuniSwap {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

// BTCC
  address public LUNI_TOKEN = 0xdFA8eeB1f602f1996EC2dA3C1e20C1e95c3A81b0;
  // UD2
  address public USDT_TOKEN = 0xeac6F5bEB61ad7f4278cD4506D3fAD1C5E8eA1F6;

  // address public immutable LUNI_TOKEN = 0xddb3a2a5b469e8df878aa110f1a10dcef2fe3052;
  // address public immutable USDT_TOKEN = 0x55d398326f99059ff775485246999027b3197955;
  uint constant SECONDS_PER_DAY = 24 * 60 * 60;
  int constant OFFSET19700101 = 2440588;

  address private swapAdmin;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event SwapLuniProcess(address indexed swap, uint256 luniAmount, uint256 usdtAmount, uint256 rate);

  uint256 public usdtRate;
  uint256 public swapFee;

  mapping(string => uint256) public employTypeConfig;

  struct UserData {
    string employType;
    uint256 amountSwap;
    uint swapTimestamp;
  }

  mapping(address => UserData) public employ;

  modifier onlyOwner() {
    require(msg.sender == swapAdmin, 'INVALID Swap ADMIN');
    _;
  }

  constructor() public{
    swapAdmin = msg.sender;
    usdtRate = 1e18;
    swapFee = 10;
  }

  /**
   * @dev Withdraw IDO Token to an address, revert if it fails.
   * @param recipient recipient of the transfer
   */
  function withdrawToken(address recipient, address token) public onlyOwner {
    IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(swapAdmin, newOwner);
    swapAdmin = newOwner;
  }

  function setUsdtRate(uint256 rate) public onlyOwner {
      usdtRate = rate;
  }


  function setSwapFee(uint256 fee) public onlyOwner {
      swapFee = fee;
  }

  function removeEmploy(address _employ) public onlyOwner {
      delete employ[_employ];
  }

 function addNewEmploy(address newEmploy, string memory employType) public onlyOwner {
      employ[newEmploy] = UserData(employType, 0, 0);
  }

  function addEmployConfig(string memory typeConfig, uint256 maxOut) public onlyOwner {
      employTypeConfig[typeConfig] = maxOut;
  }


  function swapLuni(uint256 amountLuni) public {
    require(bytes(employ[msg.sender].employType).length != 0, "Address is not valid");

    uint256 swapUSDTAmountValid = _getValidSwap();
    uint256 swapUSDTAmount = amountLuni.div(usdtRate).mul(1e18);
    uint256 realUSDTSwap = swapUSDTAmount > swapUSDTAmountValid ? swapUSDTAmountValid : swapUSDTAmount;
    uint256 fee = realUSDTSwap.mul(swapFee).div(100);

    IERC20(LUNI_TOKEN).transferFrom(msg.sender, address(this), realUSDTSwap.mul(usdtRate).div(1e18));
    IERC20(USDT_TOKEN).transfer(msg.sender, realUSDTSwap.sub(fee));
    employ[msg.sender].amountSwap = employ[msg.sender].amountSwap.add(realUSDTSwap);
    employ[msg.sender].swapTimestamp = block.timestamp;

    emit SwapLuniProcess(msg.sender, realUSDTSwap.mul(usdtRate), realUSDTSwap, usdtRate);
  }

  function _getValidSwap() private returns (uint256) {
    uint256 vaildAmount = 0;
    uint256 swapAmountMax = employTypeConfig[employ[msg.sender].employType];
    uint lastSwapTimeStamp = employ[msg.sender].swapTimestamp;
    if (lastSwapTimeStamp == 0) {
      vaildAmount = swapAmountMax;
    } else {
        uint currentMonth = getMonth(uint(block.timestamp));
        uint lastMonthSwap = getMonth(uint(lastSwapTimeStamp));
        if (currentMonth == lastMonthSwap) {
          vaildAmount = swapAmountMax.sub(employ[msg.sender].amountSwap);
        } else {
          employ[msg.sender].amountSwap = 0;
          vaildAmount = swapAmountMax;
        }
    }
    return(vaildAmount);
  }

  function getMonth(uint timestamp) public pure returns (uint) {
        uint _days = timestamp / SECONDS_PER_DAY;
        int __days = int(_days);
        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
      return(uint(_month));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
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
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
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
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

