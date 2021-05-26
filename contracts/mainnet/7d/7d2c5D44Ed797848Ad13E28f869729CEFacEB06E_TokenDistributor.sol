//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {IERC20} from './IERC20.sol';
import {EthAddressLib} from './EthAddressLib.sol';
import {SafeMath} from './SafeMath.sol';
import {SafeERC20} from './SafeERC20.sol';
import {Ownable} from './Ownable.sol';

/// @title TokenDistributor
/// @author Aito
/// @dev Receives tokens and manages the distribution amongst receivers
contract TokenDistributor is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Distribution {
    address[] receivers;
    uint256[] percentages;
  }

  event DistributionUpdated(address[] receivers, uint256[] percentages);
  event Distributed(address receiver, uint256 percentage, uint256 amount);

  /// @dev Defines how tokens and ETH are distributed on each call to .distribute()
  Distribution private distribution;

  /// @dev Instead of using 100 for percentages, higher base to have more precision in the distribution
  uint256 public constant DISTRIBUTION_BASE = 10000;

  constructor(address[] memory _receivers, uint256[] memory _percentages) {
    _setTokenDistribution(_receivers, _percentages);
  }

  /// @dev Allows the owner to change the receivers and their percentages
  /// @param _receivers Array of addresses receiving a percentage of the distribution, both user addresses
  ///   or contracts
  /// @param _percentages Array of percentages each _receivers member will get
  function setTokenDistribution(address[] memory _receivers, uint256[] memory _percentages)
    external
    onlyOwner
  {
    _setTokenDistribution(_receivers, _percentages);
  }

  /// @dev Distributes the whole balance of a list of _tokens balances in this contract
  /// @param _tokens list of ERC20 tokens to distribute
  function distribute(IERC20[] memory _tokens) external {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _balanceToDistribute =
        (address(_tokens[i]) != EthAddressLib.ethAddress())
          ? _tokens[i].balanceOf(address(this))
          : address(this).balance;
      if (_balanceToDistribute <= 0) {
        continue;
      }

      _distributeTokenWithAmount(_tokens[i], _balanceToDistribute);
    }
  }

  /// @dev Distributes specific amounts of a list of _tokens
  /// @param _tokens list of ERC20 tokens to distribute
  /// @param _amounts list of amounts to distribute per token
  function distributeWithAmounts(IERC20[] memory _tokens, uint256[] memory _amounts) public {
    for (uint256 i = 0; i < _tokens.length; i++) {
      _distributeTokenWithAmount(_tokens[i], _amounts[i]);
    }
  }

  /// @dev Distributes specific total balance's percentages of a list of _tokens
  /// @param _tokens list of ERC20 tokens to distribute
  /// @param _percentages list of percentages to distribute per token
  function distributeWithPercentages(IERC20[] memory _tokens, uint256[] memory _percentages)
    external
  {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _amountToDistribute =
        (address(_tokens[i]) != EthAddressLib.ethAddress())
          ? _tokens[i].balanceOf(address(this)).mul(_percentages[i]).div(100)
          : address(this).balance.mul(_percentages[i]).div(100);
      if (_amountToDistribute <= 0) {
        continue;
      }

      _distributeTokenWithAmount(_tokens[i], _amountToDistribute);
    }
  }

  /// @dev Returns the receivers and percentages of the contract Distribution
  /// @return receivers array of addresses and percentages array on uints
  function getDistribution() external view returns (Distribution memory) {
    return distribution;
  }

  receive() external payable {}

  function _setTokenDistribution(address[] memory _receivers, uint256[] memory _percentages)
    internal
  {
    require(_receivers.length == _percentages.length, 'Array lengths should be equal');

    uint256 sumPercentages;
    for (uint256 i = 0; i < _percentages.length; i++) {
      sumPercentages += _percentages[i];
    }
    require(sumPercentages == DISTRIBUTION_BASE, 'INVALID_%_SUM');

    distribution = Distribution({receivers: _receivers, percentages: _percentages});
    emit DistributionUpdated(_receivers, _percentages);
  }

  function _distributeTokenWithAmount(IERC20 _token, uint256 _amountToDistribute) internal {
    address _tokenAddress = address(_token);
    Distribution memory _distribution = distribution;
    for (uint256 j = 0; j < _distribution.receivers.length; j++) {
      uint256 _amount =
        _amountToDistribute.mul(_distribution.percentages[j]).div(DISTRIBUTION_BASE);

      //avoid transfers/burns of 0 tokens
      if (_amount == 0) {
        continue;
      }

      if (_tokenAddress != EthAddressLib.ethAddress()) {
        _token.safeTransfer(_distribution.receivers[j], _amount);
      } else {
        //solium-disable-next-line
        (bool _success, ) = _distribution.receivers[j].call{value: _amount}('');
        require(_success, 'Reverted ETH transfer');
      }
      emit Distributed(_distribution.receivers[j], _distribution.percentages[j], _amount);
    }
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
   * Emits a `Transfer` event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through `transferFrom`. This is
   * zero by default.
   *
   * This value changes when `approve` or `transferFrom` are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * > Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an `Approval` event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a `Transfer` event.
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
   * a call to `approve`. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

library EthAddressLib {
  /**
   * @dev Returns the address used within the protocol to identify ETH
   * @return The address assigned to ETH
   */
  function ethAddress() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts

pragma solidity ^0.7.0;

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
    require(b <= a, 'SafeMath: subtraction overflow');
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, 'SafeMath: division by zero');
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
    require(b != 0, 'SafeMath: modulo by zero');
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts

pragma solidity ^0.7.0;

import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.

    // A Solidity high level call has three parts:
    //  1. The target address is checked to verify it contains contract code
    //  2. The call itself is made, and success asserted
    //  3. The return value is decoded, which in turn checks the size of the returned data.
    // solhint-disable-next-line max-line-length
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts

pragma solidity ^0.7.0;

import './Context.sol';

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
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * This test is non-exhaustive, and there may be false-negatives: during the
   * execution of a contract's constructor, its address will be reported as
   * not containing a contract.
   *
   * > It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

// SPDX-License-Identifier: MIT
// From https://github.com/OpenZeppelin/openzeppelin-contracts

pragma solidity ^0.7.0;

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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}