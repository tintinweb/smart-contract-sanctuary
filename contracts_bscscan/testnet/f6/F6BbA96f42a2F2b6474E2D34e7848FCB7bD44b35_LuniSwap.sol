// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from '../dependencies/open-zeppelin/SafeMath.sol';
import {VersionedInitializable} from '../utils/VersionedInitializable.sol';


contract LuniSwap is VersionedInitializable{
  using SafeMath for uint256;

  struct UserData {
    string employType;
    uint256 amountSwap;
    uint swapTimestamp;
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event SwapLuniProcess(address indexed swap, uint256 luniAmount, uint256 usdtAmount, uint256 rate);
  event addEmploy(address indexed employAddress, string employType);
  event removeEmployEvent(address employAddress);
  event addConfig(string indexed employType, uint256 maxOut);
  event SwapUSDT(address indexed swap, uint256 luniAmount, uint256 usdtAmount, uint256 rate);

  uint256 public constant REVISION = 2;

  address public LUNI_TOKEN;
  address public USDT_TOKEN;

  uint constant SECONDS_PER_DAY = 24 * 60 * 60;
  int constant OFFSET19700101 = 2440588;

  address private swapAdmin;
  uint256 public usdtRate;
  uint256 public swapFee;
  uint256 public newLimit;

  mapping(string => uint256) public employTypeConfig;
  mapping(address => UserData) public employ;

  modifier onlyOwner() {
    require(msg.sender == swapAdmin, 'INVALID Swap ADMIN');
    _;
  }

  constructor() public{
  }

  /**
   * @dev Called by the proxy contract
   **/
  function initialize(
  ) external initializer {
    //  newLimit = 3000 ether;
    //  employTypeConfig["new"] = newLimit;
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

  function setNewLimit(uint256 _newLimit) public onlyOwner {
      newLimit = _newLimit;
  }

  function setAddressToken(address baseToken, address pairToken) public onlyOwner {
      LUNI_TOKEN = baseToken;
      USDT_TOKEN = pairToken;
  }

  function setSwapFee(uint256 fee) public onlyOwner {
      swapFee = fee;
  }

  function removeEmploy(address _employ) public onlyOwner {
      delete employ[_employ];
      emit removeEmployEvent(_employ);
  }

 function addNewEmploy(address[] calldata employList, string memory _employType) public onlyOwner {
    for (uint256 i = 0; i < employList.length; i++) {
      employ[employList[i]] = UserData(_employType, 0, 0);
      emit addEmploy(employList[i], _employType);
    }
  }

  function addEmployConfig(string memory typeConfig, uint256 maxOut) public onlyOwner {
      employTypeConfig[typeConfig] = maxOut;
      emit addConfig(typeConfig, maxOut);
  }


  function swapLuni(uint256 amountLuni) public {
    (uint256 swapAmountValid, bool isReset) = _getValidSwap(msg.sender);
    if (swapAmountValid == 0) {
      revert();
    }
    uint256 realLuniSwap = amountLuni > swapAmountValid ? swapAmountValid : amountLuni;
    uint256 fee = realLuniSwap.mul(swapFee).div(100);

    IERC20(LUNI_TOKEN).transferFrom(msg.sender, address(this), realLuniSwap);
    uint256 usdtAmount = realLuniSwap.sub(fee).mul(usdtRate).div(1e18);
    IERC20(USDT_TOKEN).transfer(msg.sender, usdtAmount);
    if (isReset) {
       if (bytes(employ[msg.sender].employType).length == 0) {
           employ[msg.sender].employType = "new";
        }
      employ[msg.sender].amountSwap = realLuniSwap;
    } else {
      employ[msg.sender].amountSwap = employ[msg.sender].amountSwap.add(realLuniSwap);
    }
    employ[msg.sender].swapTimestamp = block.timestamp;

    emit SwapLuniProcess(msg.sender, realLuniSwap, usdtAmount, usdtRate);
  }

  function swapUSDT(uint256 amountUSDT) public {

    uint256 fee = amountUSDT.mul(swapFee).div(100);

    IERC20(USDT_TOKEN).transferFrom(msg.sender, address(this), amountUSDT);

    uint amountLuni = amountUSDT.sub(fee).mul(1e18).div(usdtRate);
    IERC20(LUNI_TOKEN).transfer(msg.sender, amountLuni);

    emit SwapUSDT(msg.sender, amountLuni, amountUSDT, usdtRate);
  }

  function getLuniAvailableToSwap(address employAdd) public view returns (uint256) {
    if (bytes(employ[employAdd].employType).length == 0) {
      return (newLimit);
    }
    (uint256 swapUSDTAmountValid, bool isReset) = _getValidSwap(employAdd);
    return(swapUSDTAmountValid);
  }

  function _getValidSwap(address _employ) internal view returns (uint256, bool) {
     if (bytes(employ[_employ].employType).length == 0) {
      return (newLimit, true);
    }
    uint256 swapAmountMax = employTypeConfig[employ[_employ].employType];
    uint lastSwapTimeStamp = employ[_employ].swapTimestamp;
    if (lastSwapTimeStamp == 0) {
      return(swapAmountMax, false);
    } else {
        uint currentMonth = getMonth(uint(block.timestamp));
        uint lastMonthSwap = getMonth(uint(lastSwapTimeStamp));
        if (currentMonth == lastMonthSwap) {
          return(swapAmountMax.sub(employ[_employ].amountSwap), false);
        } else {
          return(swapAmountMax, true);
        }
    }
  }

  function getMonth(uint timestamp) internal view returns (uint) {
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

  /**
   * @dev returns the revision of the implementation contract
   * @return The revision
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Bitcoinnami, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 internal lastInitializedRevision = 0;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(revision > lastInitializedRevision, 'Contract instance has already been initialized');

    lastInitializedRevision = revision;

    _;
  }

  /// @dev returns the revision number of the contract.
  /// Needs to be defined in the inherited class as a constant.
  function getRevision() internal pure virtual returns (uint256);

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

