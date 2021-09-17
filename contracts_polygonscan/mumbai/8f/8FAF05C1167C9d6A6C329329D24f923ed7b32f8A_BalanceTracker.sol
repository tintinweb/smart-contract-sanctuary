// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IBalanceTracker.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/EventWrapper.sol";
import "../interfaces/events/EventReceiver.sol";

contract BalanceTracker is EventReceiver, IBalanceTracker, Ownable {
    using SafeMath for uint256;

    bytes32 public constant EVENT_TYPE_DEPOSIT = bytes32("Deposit");
    bytes32 public constant EVENT_TYPE_TRANSFER = bytes32("Transfer");
    bytes32 public constant EVENT_TYPE_SLASH = bytes32("Slash");
    bytes32 public constant EVENT_TYPE_WITHDRAW = bytes32("Withdraw");

    // user account address -> token address -> balance
    mapping(address => mapping(address => TokenBalance)) public accountTokenBalances;
    // token address -> total tracked balance
    mapping(address => uint256) public totalTokenBalances;

    //solhint-disable-next-line no-empty-blocks, func-visibility
    constructor(address eventProxy) EventReceiver(eventProxy) { }

    function getBalance(address account, address[] calldata tokens)
        external
        view
        override
        returns (TokenBalance[] memory userBalances)
    {
        userBalances = new TokenBalance[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
           userBalances[i] = accountTokenBalances[account][tokens[i]];
        }

        return userBalances;
    }

    function setBalance(SetTokenBalance[] calldata balances) external override onlyOwner {
        for (uint256 i = 0; i < balances.length; i++) {
            SetTokenBalance calldata balance = balances[i];
            updateBalance({
                account: balance.account,
                token: balance.token,
                amount: balance.amount,
                stateSync: false
            });
        }
    }

    function updateBalance(address account, address token, uint256 amount, bool stateSync) private {
        require(token != address(0), "INVALID_TOKEN_ADDRESS");
        require(account != address(0), "INVALID_ACCOUNT_ADDRESS");

        TokenBalance storage currentUserBalance = accountTokenBalances[account][token];
        uint256 currentTotalBalance = totalTokenBalances[token];

        // stateSync updates balances on an ongoing basis, whereas setBalance is only
        // allowed to update balances that have not been set before
        if (stateSync || currentUserBalance.token == address(0)) {
            uint256 updatedTotalBalance = currentTotalBalance.sub(currentUserBalance.amount).add(amount);
            accountTokenBalances[account][token] = TokenBalance({token: token, amount: amount});
            totalTokenBalances[token] = updatedTotalBalance;
            emit BalanceUpdate(account, token, amount, stateSync, true);
        } else {
            // setBalance may trigger this event if it tries to update the balance
            // of an already set user-token key
            emit BalanceUpdate(account, token, amount, false, false);
        }
    }

    function _onEventReceive(address, bytes32 eventType, bytes calldata data) internal override virtual  {
        require(eventType == EVENT_TYPE_DEPOSIT || eventType == EVENT_TYPE_TRANSFER || eventType == EVENT_TYPE_WITHDRAW || eventType == EVENT_TYPE_SLASH, "INVALID_EVENT_TYPE");

        (BalanceUpdateEvent memory balanceUpdate) = abi.decode(data, (BalanceUpdateEvent));

        updateBalance({
            account: balanceUpdate.account,
            token: balanceUpdate.token,
            amount: balanceUpdate.amount,
            stateSync: true
        });
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

pragma solidity 0.7.6;
pragma abicoder v2;

import "./events/IEventReceiver.sol";

interface IBalanceTracker is IEventReceiver {

    struct TokenBalance {
        address token;
        uint256 amount;
    }

    struct SetTokenBalance {
        address account;
        address token;
        uint256 amount;
    }

    /// @param account User address
    /// @param token Token address
    /// @param amount User balance set for the user-token key
    /// @param stateSynced True if the event is from the L1 to L2 state sync. False if backfill
    /// @param applied False if the update was not actually recorded. Only applies to backfill updates that are skipped
    event BalanceUpdate(address account, address token, uint256 amount, bool stateSynced, bool applied);

    /// @notice Retrieve the current balances for the supplied account and tokens
    function getBalance(address account, address[] calldata tokens) external view returns (TokenBalance[] memory userBalances);

    /// @notice Allows backfilling of current balance
    /// @dev onlyOwner. Only allows unset balances to be updated
    function setBalance(SetTokenBalance[] calldata balances) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

struct EventWrapper {
    bytes32 eventType;
    bytes data;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IEventReceiver.sol";

abstract contract EventReceiver is IEventReceiver {
    
    address public eventProxy;

    event ProxyAddressSet(address proxyAddress);

    constructor(address eventProxyAddress) {
        require(eventProxyAddress != address(0), "INVALID_ROOT_PROXY");   

        _setEventProxyAddress(eventProxyAddress);
    }

    function onEventReceive(address sender, bytes32 eventType, bytes calldata data) external override {
        require(msg.sender == eventProxy, "EVENT_PROXY_ONLY");

        _onEventReceive(sender, eventType, data);
    }

    //solhint-disable-next-line no-unused-vars
    function _onEventReceive(address sender, bytes32 eventType, bytes calldata data) internal virtual;
    
    function _setEventProxyAddress(address eventProxyAddress) private {
        eventProxy = eventProxyAddress;

        emit ProxyAddressSet(eventProxy);
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

pragma solidity 0.7.6;
pragma abicoder v2;

interface IEventReceiver {

    function onEventReceive(address sender, bytes32 eventType, bytes calldata data) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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