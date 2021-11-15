// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import {IFactory} from "./Factory.sol";
import {StdQueue} from "./utils/Queue.sol";
import {IOperation} from "./operations/Operation.sol";
import {IOperationStore} from "./operations/OperationStore.sol";

contract Router is Ownable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // operation
    address public optStore;
    uint256 public optStdId;
    address public factory;

    // constant
    address public wUST;
    address public aUST;

    // acl
    address public bot;

    function initialize(
        address _optStore,
        uint256 _optStdId,
        address _wUST,
        address _aUST,
        address _factory
    ) public initializer {
        optStore = _optStore;
        optStdId = _optStdId;
        factory = _factory;
        wUST = _wUST;
        aUST = _aUST;
        bot = msg.sender;
    }

    function setOperationId(uint256 _optStdId) public onlyOwner {
        optStdId = _optStdId;
    }

    function setBotAddress(address _bot) public onlyOwner {
        bot = _bot;
    }

    function _init(
        IOperation.Type _typ,
        uint256 _amount,
        bool _autoFinish
    ) internal {
        IOperationStore store = IOperationStore(optStore);
        if (store.isIdleQueueEmpty()) {
            // deploy new one
            address instance = IFactory(factory).build(optStdId, address(this));
            store.allocate(
                IOperationStore.Info({
                    etherAddr: instance,
                    terraAddr: IOperation(instance).terraAddress()
                })
            );
            IERC20(wUST).safeApprove(instance, type(uint256).max);
            IERC20(aUST).safeApprove(instance, type(uint256).max);
        }
        IOperation operation = IOperation(store.init(_autoFinish));

        if (_typ == IOperation.Type.DEPOSIT) {
            IERC20(wUST).safeTransferFrom(msg.sender, address(this), _amount);
            operation.initDepositStable(msg.sender, _amount, _autoFinish);
            return;
        }

        if (_typ == IOperation.Type.REDEEM) {
            IERC20(aUST).safeTransferFrom(msg.sender, address(this), _amount);
            operation.initRedeemStable(msg.sender, _amount, _autoFinish);
            return;
        }

        revert("Router: invalid operation type");
    }

    function _finish(address _opt) internal {
        IOperationStore.Status status =
            IOperationStore(optStore).getStatusOf(_opt);

        if (status == IOperationStore.Status.RUNNING_MANUAL) {
            // check msg.sender
            require(
                IOperation(_opt).getCurrentStatus().operator == msg.sender,
                "Router: invalid sender"
            );
        } else if (status == IOperationStore.Status.RUNNING_AUTO) {
            // check msg.sender || bot
            require(
                IOperation(_opt).getCurrentStatus().operator == msg.sender ||
                    bot == msg.sender,
                "Router: invalid sender"
            );
        } else {
            revert("Router: invalid status for finish");
        }

        IOperation(_opt).finish();
        IOperationStore(optStore).finish(_opt);
    }

    function depositStable(uint256 _amount) public {
        _init(IOperation.Type.DEPOSIT, _amount, true);
    }

    function initDepositStable(uint256 _amount) public {
        _init(IOperation.Type.DEPOSIT, _amount, false);
    }

    function finishDepositStable(address _operation) public {
        _finish(_operation);
    }

    function redeemStable(uint256 _amount) public {
        _init(IOperation.Type.REDEEM, _amount, true);
    }

    function initRedeemStable(uint256 _amount) public {
        _init(IOperation.Type.REDEEM, _amount, false);
    }

    function finishRedeemStable(address _operation) public {
        _finish(_operation);
    }

    function fail(address _opt) public {
        require(
            msg.sender == owner() || msg.sender == bot,
            "Router: access denied"
        );

        IOperation(_opt).fail();
        IOperationStore(optStore).fail(_opt);
    }

    function recover(address _opt) public {
        require(
            msg.sender == owner() || msg.sender == bot,
            "Router: access denied"
        );

        IOperation(_opt).recover();
        IOperationStore(optStore).recover(_opt);
    }

    function emergencyWithdraw(address _opt, address _token) public onlyOwner {
        IOperation(_opt).emergencyWithdraw(_token, msg.sender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {Operator} from "./utils/Operator.sol";

interface OperationStandard {
    function initialize(bytes memory) external;

    function initPayload(address, bytes32) external view returns (bytes memory);
}

interface IFactory {
    event ContractDeployed(
        address indexed deployer,
        address indexed instance,
        bytes32 indexed terraAddress
    );

    function build(uint256 _optId, address _controller)
        external
        returns (address);
}

contract Factory is IFactory, Operator {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // permission
    mapping(address => bool) public permission;

    function allow(address _target) public onlyOwner {
        permission[_target] = true;
    }

    function deny(address _target) public onlyOwner {
        permission[_target] = false;
    }

    function isPermissioned(address _target) public view returns (bool) {
        return permission[_target];
    }

    // standard operations
    mapping(uint256 => address) internal standards;

    function setStandardOperation(uint256 _optId, address _operation)
        public
        onlyOwner
    {
        standards[_optId] = _operation;
    }

    // terra address buffer
    EnumerableSet.Bytes32Set private terraAddresses;

    function pushTerraAddresses(bytes32[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            terraAddresses.add(_addrs[i]);
        }
    }

    function fetchNextTerraAddress() public view returns (bytes32) {
        return terraAddresses.at(0);
    }

    function fetchTerraAddress() private returns (bytes32) {
        bytes32 addr = terraAddresses.at(0);
        terraAddresses.remove(addr);
        return addr;
    }

    function build(uint256 _optId, address _controller)
        public
        override
        onlyGranted
        returns (address)
    {
        require(isPermissioned(msg.sender), "Factory: not allowed");

        bytes32 terraAddr = fetchTerraAddress();
        address instance = Clones.clone(standards[_optId]);
        bytes memory payload =
            OperationStandard(standards[_optId]).initPayload(
                _controller,
                terraAddr
            ); // TODO: make terraAddress buffer
        OperationStandard(instance).initialize(payload);

        emit ContractDeployed(msg.sender, instance, terraAddr);

        return instance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library StdQueue {
    struct Queue {
        uint256 index;
        uint256 size;
        mapping(uint256 => bytes) store;
    }

    function isEmpty(Queue storage q) internal view returns (bool) {
        return q.size == 0;
    }

    function getItemAt(Queue storage q, uint256 index)
        internal
        view
        returns (bytes memory)
    {
        return q.store[q.index + index];
    }

    function produce(Queue storage q, bytes memory data) internal {
        q.store[q.index + q.size] = data;
        q.size += 1;
    }

    function consume(Queue storage q) internal returns (bytes memory) {
        require(!isEmpty(q), "StdQueue: empty queue");
        bytes memory data = getItemAt(q, 0);
        q.index += 1;
        q.size -= 1;
        return data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import {WrappedAsset} from "../assets/WrappedAsset.sol";

interface IOperation {
    // Events
    event AutoFinishEnabled(address indexed operation);
    event InitDeposit(address indexed operator, uint256 amount, bytes32 to);
    event FinishDeposit(address indexed operator, uint256 amount);
    event InitRedemption(address indexed operator, uint256 amount, bytes32 to);
    event FinishRedemption(address indexed operator, uint256 amount);
    event EmergencyWithdrawActivated(address token, uint256 amount);

    // Data Structure
    enum Status {IDLE, RUNNING, STOPPED}
    enum Type {NEUTRAL, DEPOSIT, REDEEM}

    struct Info {
        Status status;
        Type typ;
        address operator;
        uint256 amount;
        address input;
        address output;
    }

    // Interfaces
    function controller() external view returns (address);

    function terraAddress() external view returns (bytes32);

    function getCurrentStatus() external view returns (Info memory);

    function initDepositStable(
        address _operator,
        uint256 _amount,
        bool _autoFinish
    ) external;

    function initRedeemStable(
        address _operator,
        uint256 _amount,
        bool _autoFinish
    ) external;

    function finish() external;

    function finishDepositStable() external;

    function finishRedeemStable() external;

    function fail() external;

    function recover() external;

    function emergencyWithdraw(address _token, address _to) external;
}

// Operation.sol: subcontract generated per wallet, defining all relevant wrapping functions
contract Operation is Ownable, IOperation, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for WrappedAsset;

    Info public DEFAULT_STATUS =
        Info({
            status: Status.IDLE,
            typ: Type.NEUTRAL,
            operator: address(0x0),
            amount: 0,
            input: address(0x0),
            output: address(0x0)
        });
    Info public currentStatus;

    WrappedAsset public wUST;
    WrappedAsset public aUST;

    address public override controller;
    bytes32 public override terraAddress;

    function initialize(bytes memory args) public initializer {
        (
            address _controller,
            bytes32 _terraAddress,
            address _wUST,
            address _aUST
        ) = abi.decode(args, (address, bytes32, address, address));

        currentStatus = DEFAULT_STATUS;
        controller = _controller;
        terraAddress = _terraAddress;
        wUST = WrappedAsset(_wUST);
        aUST = WrappedAsset(_aUST);
    }

    function initPayload(address, bytes32 _terraAddress)
        public
        view
        returns (bytes memory)
    {
        return abi.encode(controller, _terraAddress, wUST, aUST);
    }

    modifier onlyController {
        require(controller == msg.sender, "Operation: not allowed");

        _;
    }

    modifier checkStopped {
        require(currentStatus.status != Status.STOPPED, "Operation: stopped");

        _;
    }

    function getCurrentStatus() public view override returns (Info memory) {
        return currentStatus;
    }

    function _init(
        Type _typ,
        address _operator,
        uint256 _amount,
        bool _autoFinish
    ) private {
        require(currentStatus.status == Status.IDLE, "Operation: running");
        require(_amount >= 10 ether, "Operation: amount must be more than 10");

        currentStatus = Info({
            status: Status.RUNNING,
            typ: _typ,
            operator: _operator,
            amount: _amount,
            input: address(0x0),
            output: address(0x0)
        });

        if (_typ == Type.DEPOSIT) {
            currentStatus.input = address(wUST);
            currentStatus.output = address(aUST);

            wUST.safeTransferFrom(msg.sender, address(this), _amount);
            wUST.burn(_amount, terraAddress);

            emit InitDeposit(_operator, _amount, terraAddress);
        } else if (_typ == Type.REDEEM) {
            currentStatus.input = address(aUST);
            currentStatus.output = address(wUST);

            aUST.safeTransferFrom(msg.sender, address(this), _amount);
            aUST.burn(_amount, terraAddress);

            emit InitRedemption(_operator, _amount, terraAddress);
        } else {
            revert("Operation: invalid operation type");
        }

        if (_autoFinish) {
            emit AutoFinishEnabled(address(this));
        }
    }

    function initDepositStable(
        address _operator,
        uint256 _amount,
        bool _autoFinish
    ) public override onlyController {
        _init(Type.DEPOSIT, _operator, _amount, _autoFinish);
    }

    function initRedeemStable(
        address _operator,
        uint256 _amount,
        bool _autoFinish
    ) public override onlyController {
        _init(Type.REDEEM, _operator, _amount, _autoFinish);
    }

    function _finish() private returns (address, uint256) {
        // check status
        require(currentStatus.status == Status.RUNNING, "Operation: idle");

        WrappedAsset output = WrappedAsset(currentStatus.output);
        uint256 amount = output.balanceOf(address(this));
        address operator = currentStatus.operator;

        require(amount > 0, "Operation: not enough token");
        output.safeTransfer(operator, amount);

        // prevent multiple reference
        Type typ = currentStatus.typ;

        if (typ == Type.DEPOSIT) {
            emit FinishDeposit(operator, amount);
        } else if (typ == Type.REDEEM) {
            emit FinishRedemption(operator, amount);
        }

        // reset
        currentStatus = DEFAULT_STATUS;

        return (address(output), amount);
    }

    function finish() public override onlyController {
        _finish();
    }

    function finishDepositStable() public override onlyController {
        _finish();
    }

    function finishRedeemStable() public override onlyController {
        _finish();
    }

    function fail() public override onlyController {
        currentStatus.status = Status.STOPPED;
    }

    function recover() public override onlyController {
        currentStatus.status = Status.RUNNING;
        _finish();
    }

    function emergencyWithdraw(address _token, address _to)
        public
        override
        onlyController
    {
        require(
            currentStatus.status == Status.STOPPED,
            "Operation: not an emergency"
        );

        IERC20(_token).safeTransfer(
            _to,
            IERC20(_token).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {StdQueue} from "../utils/Queue.sol";
import {Operator} from "../utils/Operator.sol";
import {IOperation} from "./Operation.sol";

interface IOperationStore {
    // Events
    event OperationAllocated(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr
    );
    event OperationInitialized(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr,
        bool autoFinish
    );
    event OperationFinished(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr
    );
    event OperationFailed(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr
    );
    event OperationRecovered(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr
    );
    event OperationDeallocated(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr
    );
    event OperationFlushed(
        address indexed controller,
        address indexed operation,
        bytes32 indexed terraAddr,
        Queue from,
        Queue to
    );

    // Data Structure
    enum Status {
        IDLE,
        RUNNING_AUTO,
        RUNNING_MANUAL,
        FINISHED,
        FAILED,
        RECOVERED,
        DEALLOCATED
    }

    enum Queue {IDLE, RUNNING, FAILED, BLACKHOLE}

    struct Info {
        address etherAddr;
        bytes32 terraAddr;
    }

    // getter
    function isIdleQueueEmpty() external view returns (bool);

    function getIdleOperationAt(uint256 _index)
        external
        view
        returns (Info memory);

    function isFailedQueueEmpty() external view returns (bool);

    function getFailedOperationAt(uint256 _index)
        external
        view
        returns (Info memory);

    function isRunningQueueEmpty() external view returns (bool);

    function getRunningOperationAt(uint256 _index)
        external
        view
        returns (Info memory);

    function getStatusOf(address _opt) external view returns (Status);

    // logics
    function allocate(Info memory info) external;

    function init(bool _autoFinish) external returns (address);

    function finish(address _opt) external;

    function fail(address _opt) external;

    function recover(address _opt) external;

    function deallocate(address _opt) external;

    function flush(Queue queue, uint256 _amount) external;

    function flushAll(uint256 _amount) external;
}

contract OperationStore is IOperationStore, Operator {
    using StdQueue for StdQueue.Queue;

    function encodeOperation(Info memory info)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(info.etherAddr, info.terraAddr);
    }

    function decodeOperation(bytes memory rawInfo)
        internal
        pure
        returns (Info memory)
    {
        (address etherAddr, bytes32 terraAddr) =
            abi.decode(rawInfo, (address, bytes32));
        return Info({etherAddr: etherAddr, terraAddr: terraAddr});
    }

    // queues
    mapping(address => Status) public optStat;

    StdQueue.Queue public optIdle;
    StdQueue.Queue public optFailed;
    StdQueue.Queue public optRunning;

    function isIdleQueueEmpty() public view override returns (bool) {
        return optIdle.isEmpty();
    }

    function getIdleOperationAt(uint256 _index)
        public
        view
        override
        returns (Info memory)
    {
        return decodeOperation(optIdle.getItemAt(_index));
    }

    function isFailedQueueEmpty() public view override returns (bool) {
        return optFailed.isEmpty();
    }

    function getFailedOperationAt(uint256 _index)
        public
        view
        override
        returns (Info memory)
    {
        return decodeOperation(optFailed.getItemAt(_index));
    }

    function isRunningQueueEmpty() public view override returns (bool) {
        return optRunning.isEmpty();
    }

    function getRunningOperationAt(uint256 _index)
        public
        view
        override
        returns (Info memory)
    {
        return decodeOperation(optRunning.getItemAt(_index));
    }

    function getStatusOf(address _opt) public view override returns (Status) {
        return optStat[_opt];
    }

    // lifecycle

    // x -> init
    function allocate(Info memory info) public override onlyGranted {
        optIdle.produce(encodeOperation(info));
        optStat[info.etherAddr] = Status.IDLE;
        emit OperationAllocated(msg.sender, info.etherAddr, info.terraAddr);
    }

    // init -> finish -> idle
    //      -> fail -> ~
    //      -> x (if autoFinish disabled)
    function init(bool _autoFinish)
        public
        override
        onlyGranted
        returns (address)
    {
        bytes memory rawInfo = optIdle.consume();
        Info memory info = decodeOperation(rawInfo);
        if (_autoFinish) {
            optRunning.produce(rawInfo); // idle -> running
            optStat[info.etherAddr] = Status.RUNNING_AUTO;
        } else {
            optStat[info.etherAddr] = Status.RUNNING_MANUAL;
        }
        emit OperationInitialized(
            msg.sender,
            info.etherAddr,
            info.terraAddr,
            _autoFinish
        );
        return info.etherAddr;
    }

    function finish(address _opt) public override onlyGranted {
        Status status = optStat[_opt];

        if (status == Status.RUNNING_MANUAL) {
            allocate(
                Info({
                    etherAddr: _opt,
                    terraAddr: IOperation(_opt).terraAddress()
                })
            );
            optStat[_opt] = Status.IDLE;
        } else if (status == Status.RUNNING_AUTO) {
            // wait for flush
            optStat[_opt] = Status.FINISHED;
        } else {
            revert("Router: invalid condition for finish operation");
        }

        emit OperationFinished(
            msg.sender,
            _opt,
            IOperation(_opt).terraAddress()
        );
    }

    // fail -> recover -> idle
    //      -> truncate -> x
    function fail(address _opt) public override onlyGranted {
        optStat[_opt] = Status.FAILED;
        emit OperationFailed(msg.sender, _opt, IOperation(_opt).terraAddress());
    }

    function flushRunningQueue(StdQueue.Queue storage _queue) internal {
        if (_queue.isEmpty()) {
            return;
        }

        Info memory info = decodeOperation(_queue.getItemAt(0));
        Status stat = optStat[info.etherAddr];
        if (stat == Status.FINISHED) {
            optIdle.produce(_queue.consume());
            emit OperationFlushed(
                msg.sender,
                info.etherAddr,
                info.terraAddr,
                Queue.RUNNING,
                Queue.IDLE
            );
        } else if (stat == Status.FAILED) {
            optFailed.produce(_queue.consume());
            emit OperationFlushed(
                msg.sender,
                info.etherAddr,
                info.terraAddr,
                Queue.RUNNING,
                Queue.FAILED
            );
        } else {
            return;
        }
    }

    function recover(address _opt) public override onlyGranted {
        optStat[_opt] = Status.RECOVERED;
        emit OperationRecovered(
            msg.sender,
            _opt,
            IOperation(_opt).terraAddress()
        );
    }

    function deallocate(address _opt) public override onlyOwner {
        optStat[_opt] = Status.DEALLOCATED;
        emit OperationDeallocated(
            msg.sender,
            _opt,
            IOperation(_opt).terraAddress()
        );
    }

    function flushFailedQueue(StdQueue.Queue storage _queue) internal {
        if (_queue.isEmpty()) {
            return;
        }

        Info memory info = decodeOperation(_queue.getItemAt(0));
        Status stat = optStat[info.etherAddr];
        if (stat == Status.RECOVERED) {
            optIdle.produce(_queue.consume());
            emit OperationFlushed(
                msg.sender,
                info.etherAddr,
                info.terraAddr,
                Queue.FAILED,
                Queue.IDLE
            );
        } else if (stat == Status.DEALLOCATED) {
            _queue.consume();
            emit OperationFlushed(
                msg.sender,
                info.etherAddr,
                info.terraAddr,
                Queue.FAILED,
                Queue.BLACKHOLE
            );
        } else {
            return;
        }
    }

    function _flush(
        StdQueue.Queue storage _queue,
        uint256 _amount,
        function(StdQueue.Queue storage) _handler
    ) internal {
        for (uint256 i = 0; i < _amount; i++) {
            _handler(_queue);
        }
    }

    function flush(Queue _queue, uint256 _amount) public override onlyGranted {
        if (_queue == Queue.RUNNING) {
            _flush(optRunning, _amount, flushRunningQueue);
        } else if (_queue == Queue.FAILED) {
            _flush(optRunning, _amount, flushFailedQueue);
        } else {
            revert("OperationStore: invalid queue type");
        }
    }

    function flushAll(uint256 _amount) public override onlyGranted {
        flush(Queue.RUNNING, _amount);
        flush(Queue.FAILED, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Operator {
    address public owner;
    address public operator;

    constructor() {
        owner = msg.sender;
        operator = msg.sender;
    }

    modifier onlyOwner {
        require(checkOwner(), "Operator: owner access denied");

        _;
    }

    function checkOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    modifier onlyOperator {
        require(checkOperator(), "Operator: operator access denied");

        _;
    }

    function checkOperator() public view returns (bool) {
        return msg.sender == operator;
    }

    modifier onlyGranted {
        require(checkGranted(), "Operator: access denied");

        _;
    }

    function checkGranted() public view returns (bool) {
        return checkOwner() || checkOperator();
    }

    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }

    function transferOperator(address _operator) public onlyOwner {
        operator = _operator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WrappedAsset is IERC20 {
    event Burn(address indexed _sender, bytes32 indexed _to, uint256 amount);

    function burn(uint256 amount, bytes32 to) external;
}

