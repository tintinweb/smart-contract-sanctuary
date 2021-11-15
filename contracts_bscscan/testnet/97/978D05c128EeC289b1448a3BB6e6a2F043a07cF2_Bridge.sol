//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Bridge is Ownable {
  using SafeMath for uint256;

  uint public nonce;
  mapping(uint => bool) private _processedNonces;
  IERC20 private _token;
  bool private _paused = false;
  address payable private _unlocker_bot;
  address private _pauser_bot;
  uint256 private maxAmountLock = 15000000000000000000000;
  uint256 public tokenFeePercent = 0;
  uint256 public fee = 0.001 ether;
  uint256 public _totalFee = 0;
  uint256 private _maxPercentageFee = 20;
  uint256 private _feeAmountToSend = 0.05 ether;
  uint256 private _dailyTransferTotal = 0;
  uint256 private _dailyTransferIntervalOneDay = 86400;
  uint256 private _dailyTransferNextTimestamp = block.timestamp.add(_dailyTransferIntervalOneDay);
  uint256 private _dailyTransferLimit = maxAmountLock.mul(50);

  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce
  );

  event UnexpectedRequest(
    address indexed from,
    address indexed to,
    uint amount,
    uint date
  );

  constructor(address token, address unlockerBot, address pauserBot) {
    _unlocker_bot = payable(unlockerBot);
    _pauser_bot = pauserBot;
    _token = IERC20(token);
  }

  modifier Pausable() {
      require(_paused == false, "Bridge: Paused.");
      _;
  }

  modifier OnlyUnlocker() {
      require(msg.sender == _unlocker_bot, "Bridge: You can't call this function.");
      _;
  }

  modifier OnlyPauserAndOwner() {
      require((msg.sender == _pauser_bot || msg.sender == owner()), "Bridge: You can't call this function.");
      _;
  }

  function lock(uint256 amount) external payable Pausable {
    address sender = msg.sender;
    require(_token.balanceOf(sender) >= amount, "Bridge: Account has no balance.");
    require(maxAmountLock >= amount, "Bridge: Please reduce the amount of tokens.");

    if(fee > 0) {
      require(msg.value >= fee, "Bridge: Insufficient fee.");
    }

    if(tokenFeePercent > 0) {
      uint256 amountFee = amount.div(100).mul(tokenFeePercent);
      _totalFee = _totalFee.add(amountFee);
      amount = amount.sub(amountFee);
    }

    require(_token.balanceOf(sender) >= amount, "Bridge: Account has no balance.");
    require(_token.transferFrom(sender, address(this), amount), "Bridge: Transfer failed.");

    emit Transfer(
      sender,
      address(this),
      amount,
      block.timestamp,
      nonce
    );
    nonce++;

    if(address(this).balance >= _feeAmountToSend) {
        _unlocker_bot.transfer(address(this).balance);
    }
  }

  function unlock(address to, uint256 amount, uint otherChainNonce) external OnlyUnlocker Pausable returns (bool){
    require(_processedNonces[otherChainNonce] == false, "Bridge: Transaction processed.");
    require(_token.balanceOf(address(this)) >= amount, "Bridge: Out of tokens.");

    if(amount > maxAmountLock) {
      pauseBridge(msg.sender, to, amount);
      return false;
    }

    if(block.timestamp >= _dailyTransferNextTimestamp){
      resetTransferCounter();
    }

    _dailyTransferTotal = _dailyTransferTotal.add(amount);

    if(_dailyTransferTotal >= _dailyTransferLimit) {
      resetTransferCounter();
      pauseBridge(msg.sender, to, amount);
      return false;
    }

    _processedNonces[otherChainNonce] = true;
    require(_token.approve(address(this), amount), "Bridge: Approval failed");
    require(_token.transferFrom(address(this), to, amount), "Bridge: Transfer failed");

    return true;
  }

  function setBridgePausedState(bool state) public OnlyPauserAndOwner {
      _paused = state;
  }

  function setMaxLock(uint256 _maxAmountLock) public onlyOwner {
      maxAmountLock = _maxAmountLock;
  }

  function setFee(uint256 fValue) public onlyOwner {
      fee = fValue;
  }

  function setFeeNumToSend(uint256 fAmount) public onlyOwner {
      _feeAmountToSend = fAmount;
  }

  function setTokenMaxPercentageFee(uint256 fPercent) public onlyOwner {
      _maxPercentageFee = fPercent;
  }

  function setTokenPercentageFee(uint256 fAmount) public onlyOwner {
      require(_maxPercentageFee >= fAmount, "Bridge: Max fee is 20%");
      tokenFeePercent = fAmount;
  }

  function setDailyTransferLImitFactor(uint256 factor) public onlyOwner {
      _dailyTransferLimit = maxAmountLock.mul(factor);
  }

  function resetTransferCounter() internal {
    _dailyTransferNextTimestamp = block.timestamp.add(_dailyTransferIntervalOneDay);
    _dailyTransferTotal = 0;
  }

  function pauseBridge(address from, address to, uint256 amount) internal {
      _paused = true;

      emit UnexpectedRequest(
        from,
        to,
        amount,
        block.timestamp
      );
  }

  /**
  * change from msg.sender to contractor address
  */
  function withdrawErc20(uint256 amount) public onlyOwner {
    require(_token.balanceOf(address(this)) >= amount, "Bridge: Out of tokens.");
    _token.transfer(msg.sender, amount);
  }

  function withdrawErc20Fee() public onlyOwner {
    require(_token.balanceOf(address(this)) >= _totalFee, "Bridge: Out of tokens.");
    require(_token.transfer(msg.sender, _totalFee), "Bridge: Transfer failed.");
    _totalFee = 0;
  }

  function burn(uint256 amount) public onlyOwner {
    require(_token.balanceOf(address(this)) >= amount, "Bridge: Out of tokens.");
    _token.transfer(0x000000000000000000000000000000000000dEaD, amount);
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

