pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IAlphaReceiver.sol";
import "../interfaces/IAlphaReleaseRule.sol";
import "../interfaces/IAlphaReleaseRuleSelector.sol";

/**
 * @title Alpha rule selector
 * @notice Implements the selector of Alpha rule.
 * @author Alpha
 **/

contract AlphaReleaseRuleSelector is Ownable, IAlphaReleaseRuleSelector {
  using SafeMath for uint256;

  /**
   * @dev the struct for storing the receiver's rule
   */
  struct ReceiverRule {
    // Alpha receiver
    IAlphaReceiver receiver;
    // release rule
    IAlphaReleaseRule rule;
  }

  /**
   * @dev the list of receivers with rule
   */
  ReceiverRule[] public receiverRuleList;

  /**
   * @dev emitted on update Alpha release rule 
   * @param index the index to update
   * @param receiver the address of Alpha receiver
   * @param rule the release rule of Alpha receiver
   */
  event AlphaReleaseRuleUpdated(
    uint256 indexed index,
    address indexed receiver,
    address indexed rule
  );

  /**
   * @dev emitted on remove Alpha release rule
   * @param index the index to remove
   * @param receiver the address of receiver
   * @param rule the release rule of Alpha receiver 
   */
  event AlphaReleaseRuleRemoved(
    uint256 indexed index,
    address indexed receiver,
    address indexed rule
  );

  /**
   * @dev set the Alpha release rule to the Alpha token reward receiver
   * @param _receiver the receiver to set the Alpha release rule
   * @param _rule the Alpha release rule of the receiver
   * set Alpha release rule to the receiver and add the receivver to the linked list of receiver
   */
  function setAlphaReleaseRule(IAlphaReceiver _receiver, IAlphaReleaseRule _rule)
    external
    onlyOwner
  {
    ReceiverRule memory receiverRule = ReceiverRule(
      _receiver,
      _rule
    );
    receiverRuleList.push(receiverRule);
    uint256 index = receiverRuleList.length.sub(1);
    emit AlphaReleaseRuleUpdated(index, address(_receiver), address(_rule));
  }

  function removeAlphaReleaseRule(uint256 _index)
    external
    onlyOwner
  { 
    require(_index < receiverRuleList.length, "Index out of range");
    ReceiverRule storage removedReceiverRule = receiverRuleList[_index];
    emit AlphaReleaseRuleRemoved(_index, address(removedReceiverRule.receiver), address(removedReceiverRule.rule));
    if (_index != receiverRuleList.length.sub(1)) {
      receiverRuleList[_index] = receiverRuleList[receiverRuleList.length.sub(1)];
    } 
    receiverRuleList.pop();
  }

  /**
   * @dev get receiverRuleList length
   * @return get receiverRuleList length
   */
  function getreceiverRuleListLength() external view returns (uint256) {
    return receiverRuleList.length;
  }

  /**
   * @dev returns the list of receiver and the list of amount that Alpha token will
   * release to each receiver from _fromBlock to _toBlock
   * @param _fromBlock the start block to release the Alpha token
   * @param _toBlock the end block to release the Alpha token
   * @return the list of Alpha token receiver and the list of amount that will release to each receiver
   */
  function getAlphaReleaseRules(uint256 _fromBlock, uint256 _toBlock)
    external
    override
    view
    returns (IAlphaReceiver[] memory, uint256[] memory)
  {
    IAlphaReceiver[] memory receivers = new IAlphaReceiver[](receiverRuleList.length);
    uint256[] memory amounts = new uint256[](receiverRuleList.length);
    for (uint256 i = 0; i < receiverRuleList.length; i++) {
      ReceiverRule storage receiverRule = receiverRuleList[i];
      receivers[i] = IAlphaReceiver(receiverRule.receiver);
      amounts[i] = receiverRule.rule.getReleaseAmount(_fromBlock, _toBlock);
    }
    return (receivers, amounts);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity 0.6.11;

import {IAlphaReceiver} from "./IAlphaReceiver.sol";

/**
 * @title Alpha release rule selector contract
 * @notice Implements Alpha release rule selector contract.
 * @author Alpha
 **/

interface IAlphaReleaseRuleSelector {
  /**
   * @notice get the Alpha token release rules from _fromBlock to _toBlock
   * @param _fromBlock the start block to release Alpha token
   * @param _toBlock the end block to release Alpha token
   * @return receivers - the list of Alpha token receiver, amounts - the list of 
   * amount that each receiver will receive the Alpha token
   */
  function getAlphaReleaseRules(uint256 _fromBlock, uint256 _toBlock)
    external
    view
    returns (IAlphaReceiver[] memory receivers, uint256[] memory amounts);
}

pragma solidity 0.6.11;

/**
 * @title Alpha release rule
 * @notice The interface of Alpha release rule
 * @author Alpha
 **/

interface IAlphaReleaseRule {
  /**
   * @notice get the Alpha token release amount from _fromBlock to _toBlock
   * @param _fromBlock the start block to release Alpha token
   * @param _toBlock the end block to release Alpha token
   * @return the amount od Alpha token to release
   */
  function getReleaseAmount(uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);
}

pragma solidity 0.6.11;

/**
 * @title Alpha receiver interface
 * @notice The interface of Alpha token reward receiver
 * @author Alpha
 **/

interface IAlphaReceiver {
  /**
   * @notice receive Alpha token from the distributor
   * @param _amount the amount of Alpha token to receive
   */
  function receiveAlpha(uint256 _amount) external;
}