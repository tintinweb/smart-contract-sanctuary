//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./AuthorizationStorage.sol";

import "../interfaces/IAuthorization.sol";
import "../interfaces/IEurPriceFeed.sol";
import "../interfaces/IOperationsRegistry.sol";
import "../interfaces/IBFactory.sol";
import "../interfaces/IXTokenWrapper.sol";

/**
 * @title Authorization
 * @author Protofire
 * @dev Contract module which contains the authorization logic.
 *
 * This contract should be called by an Authorizable contract through its `onlyAuthorized` modifier.
 */
contract Authorization is IAuthorization, Initializable, OwnableUpgradeable, AuthorizationStorage {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    /**
     * @dev Emitted when `permissions` address is set.
     */
    event PermissionsSet(address indexed newPermissions);

    /**
     * @dev Emitted when `operationsRegistry` address is set.
     */
    event OperationsRegistrySet(address indexed newOperationsRegistry);

    /**
     * @dev Emitted when `tradingLimit` value is set.
     */
    event TradingLimitSet(uint256 newLimit);

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event EurPriceFeedSet(address indexed newEurPriceFeed);

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event PoolFactorySet(address indexed poolFactory);

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event XTokenWrapperSet(address indexed xTokenWrapper);

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Initalize the contract.
     *
     * Sets ownership to the account that deploys the contract.
     *
     * @param _permissions Permissions module address
     * @param _eurPriceFeed EurPriceFeed module address
     * @param _operationsRegistry OperationsRegistry address
     * @param _poolFactory Balancer BFactory address
     * @param _xTokenWrapper XTokenWrapper address
     * @param _tradingLimit Traiding limit value
     * @param _paused Pause protocol
     */
    function initialize(
        address _permissions,
        address _eurPriceFeed,
        address _operationsRegistry,
        address _poolFactory,
        address _xTokenWrapper,
        uint256 _tradingLimit,
        bool _paused
    ) public initializer {
        _setPermissions(_permissions);
        _setEurPriceFeed(_eurPriceFeed);
        _setOperationsRegistry(_operationsRegistry);
        _setPoolFactory(_poolFactory);
        _setXTokenWrapper(_xTokenWrapper);
        _setTradingLimit(_tradingLimit);
        paused = _paused;

        __Ownable_init();

        emit PermissionsSet(permissions);
        emit EurPriceFeedSet(_eurPriceFeed);
        emit OperationsRegistrySet(_operationsRegistry);
        emit TradingLimitSet(_tradingLimit);
    }

    /**
     * @dev Sets `_permissions` as the new Permissions module.
     *
     * Requirements:
     *
     * - the caller must have be the owner.
     * - `_permissions` should not be the zero address.
     *
     * @param _permissions The address of the new Pemissions module.
     */
    function setPermissions(address _permissions) external override onlyOwner {
        _setPermissions(_permissions);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * Requirements:
     *
     * - the caller must have be the owner.
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external override onlyOwner {
        _setEurPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_tradingLimit` as the new traiding limit for T1 users.
     *
     * Requirements:
     *
     * - the caller must have be the owner.
     * - `_tradingLimit` should not be 0.
     *
     * @param _tradingLimit The value of the new traiding limit for T1 users.
     */
    function setTradingLimit(uint256 _tradingLimit) external override onlyOwner {
        _setTradingLimit(_tradingLimit);
    }

    /**
     * @dev Sets `_operationsRegistry` as the new OperationsRegistry module.
     *
     * Requirements:
     *
     * - the caller must have be the owner.
     * - `_operationsRegistry` should not be the zero address.
     *
     * @param _operationsRegistry The address of the new OperationsRegistry module.
     */
    function setOperationsRegistry(address _operationsRegistry) external override onlyOwner {
        _setOperationsRegistry(_operationsRegistry);
    }

    /**
     * @dev Sets `_poolFactory` as the new BFactory module.
     *
     * Requirements:
     *
     * - the caller must have be the owner.
     * - `_poolFactory` should not be the zero address.
     *
     * @param _poolFactory The address of the new Balance BFactory module.
     */
    function setPoolFactory(address _poolFactory) external override onlyOwner {
        _setPoolFactory(_poolFactory);
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new XTokenWrapper module.
     *
     * Requirements:
     *
     * - the caller must have be the owner.
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the new XTokenWrapper module.
     */
    function setXTokenWrapper(address _xTokenWrapper) external override onlyOwner {
        _setXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_permissions` as the new Permissions module.
     *
     * Requirements:
     *
     * - `_permissions` should not be the zero address.
     *
     * @param _permissions The address of the new Pemissions module.
     */
    function _setPermissions(address _permissions) internal {
        require(_permissions != address(0), "permissions is the zero address");
        emit PermissionsSet(_permissions);
        permissions = _permissions;
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * Requirements:
     *
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function _setEurPriceFeed(address _eurPriceFeed) internal {
        require(_eurPriceFeed != address(0), "eur price feed is the zero address");
        emit EurPriceFeedSet(_eurPriceFeed);
        eurPriceFeed = _eurPriceFeed;
    }

    /**
     * @dev Sets `_tradingLimit` as the new traiding limit for T1 users.
     *
     * Requirements:
     *
     * - `_tradingLimit` should not be 0.
     *
     * @param _tradingLimit The value of the new traiding limit for T1 users.
     */
    function _setTradingLimit(uint256 _tradingLimit) internal {
        require(_tradingLimit != 0, "trading limit is 0");
        emit TradingLimitSet(_tradingLimit);
        tradingLimit = _tradingLimit;
    }

    /**
     * @dev Sets `_operationsRegistry` as the new OperationsRegistry module.
     *
     * Requirements:
     *
     * - `_operationsRegistry` should not be the zero address.
     *
     * @param _operationsRegistry The address of the new OperationsRegistry module.
     */
    function _setOperationsRegistry(address _operationsRegistry) internal {
        require(_operationsRegistry != address(0), "operation registry is the zero address");
        emit OperationsRegistrySet(_operationsRegistry);
        operationsRegistry = _operationsRegistry;
    }

    /**
     * @dev Sets `_poolFactory` as the new BFactory module.
     *
     * Requirements:
     *
     * - `_poolFactory` should not be the zero address.
     *
     * @param _poolFactory The address of the new Balance BFactory module.
     */
    function _setPoolFactory(address _poolFactory) internal {
        require(_poolFactory != address(0), "Pool Factory is the zero address");
        emit PoolFactorySet(_poolFactory);
        poolFactory = _poolFactory;
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new XTokenWrapper module.
     *
     * Requirements:
     *
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the new XTokenWrapper module.
     */
    function _setXTokenWrapper(address _xTokenWrapper) internal {
        require(_xTokenWrapper != address(0), "XTokenWrapper is the zero address");
        emit XTokenWrapperSet(_xTokenWrapper);
        xTokenWrapper = _xTokenWrapper;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        require(!paused, "paused");
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        require(paused, "not paused");
        paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Determins if a user is allowed to perform an operation.
     *
     * @param _user msg.sender from function using Authorizable `onlyAuthorized` modifier.
     * @param _asset address of the contract using Authorizable `onlyAuthorized` modifier.
     * @param _operation msg.sig from function using Authorizable `onlyAuthorized` modifier.
     * @param _data msg.data from function using Authorizable `onlyAuthorized` modifier.
     * @return a boolean signaling the authorization.
     */
    function isAuthorized(
        address _user,
        address _asset,
        bytes4 _operation,
        bytes calldata _data
    ) external view override returns (bool) {
        // The protocol is paused
        if (paused) {
            return false;
        }

        // Only allowed operations
        if (isERC20Operation(_operation)) {
            // Get user and amount based on the operation
            address operationSender = _user;
            address user = _user;
            bytes4 operation = _operation;
            uint256 operationAmount;

            // ERC20_TRANSFER uses _user, which is the sender, for authorizing

            if (_operation == ERC20_TRANSFER) {
                ( , uint256 amount) = abi.decode(_data[4:], (address, uint256));
                operationAmount = amount;
            }

            if (_operation == ERC20_MINT || _operation == ERC20_BURN_FROM) {
                (address account, uint256 amount) = abi.decode(_data[4:], (address, uint256));
                user = account;
                operationAmount = amount;
            }

            if (_operation == ERC20_TRANSFER_FROM) {
                (address sender, , uint256 amount) = abi.decode(_data[4:], (address, address, uint256));
                user = sender;
                operationAmount = amount;
                operation = ERC20_TRANSFER;
            }

            // No need to check for Zero amount operations, also Balancer requires allowed zero amount transfers
            if (operationAmount == 0) {
                return true;
            }

            return checkERC20Permissions(operationSender, user, _asset, operation, operationAmount);
        }

        if (isBFactoryOperation(_operation)) {
            return checkBFactoryPermissions(_user);
        }

        return false;
    }

    /**
     * @dev Checks user permissions logic for ERC20 operations.
     *
     * @param _sender address executing the operation.
     * @param _user user's address.
     * @param _asset address of the contract where `_operation` comes from.
     * @param _operation operation to authorized.
     * @param _amount operation amount.
     */
    function checkERC20Permissions(
        address _sender,
        address _user,
        address _asset,
        bytes4 _operation,
        uint256 _amount
    ) internal view returns (bool) {
        // Get user permissions
        address[] memory accounts = new address[](6);
        accounts[0] = _user;
        accounts[1] = _user;
        accounts[2] = _user;
        accounts[3] = _user;
        accounts[4] = _user;
        accounts[5] = _sender;

        uint256[] memory ids = new uint256[](6);
        ids[0] = TIER_1_ID;
        ids[1] = TIER_2_ID;
        ids[2] = SUSPENDED_ID;
        ids[3] = REJECTED_ID;
        ids[4] = PROTOCOL_CONTRACT;
        ids[5] = PROTOCOL_CONTRACT;

        uint256[] memory permissionsBlance = IERC1155(permissions).balanceOfBatch(accounts, ids);

        address token = IXTokenWrapper(xTokenWrapper).xTokenToToken(_asset);

        // Only PROTOCOL_CONTRACT can mint/burn/transfer/transferFrom xLPT
        if (IBFactory(poolFactory).isBPool(token)) {
            return checkProtocolContract(_operation, permissionsBlance[4], permissionsBlance[5]);
        }

        // User is paused
        if (permissionsBlance[2] > 0) {
            return false;
        }

        // User is Rejected
        if (permissionsBlance[3] > 0) {
            return checkRejected(_operation);
        }

        return checkByTier(_user, _asset, _operation, _amount, permissionsBlance);
    }

    /**
     * @dev Checks user permissions logic for BFactory operations.
     *
     * @param _user user's address.
     */
    function checkBFactoryPermissions(address _user) internal view returns (bool) {
        uint256 permissionBlance = IERC1155(permissions).balanceOf(_user, POOL_CREATOR);

        return permissionBlance > 0;
    }

    /**
     * @dev Checks user permissions by Tier logic.
     *
     * @param _user user's address.
     * @param _asset address of the contract where `_operation` comes from.
     * @param _operation operation to authorized.
     * @param _amount operation amount.
     * @param _permissionsBlance user's permissions.
     */
    function checkByTier(
        address _user,
        address _asset,
        bytes4 _operation,
        uint256 _amount,
        uint256[] memory _permissionsBlance
    ) internal view returns (bool) {
        // If User is in TIER 2 it is allowed to do everything
        if (_permissionsBlance[1] > 0) {
            return true;
        }

        // If not Tier 2 but Tier 1, we need to check limits and actions
        uint256 currentTradigBalace =
            IOperationsRegistry(operationsRegistry).tradingBalanceByOperation(_user, _operation);
        uint256 eurAmount = IEurPriceFeed(eurPriceFeed).calculateAmount(_asset, _amount);

        // Something wrong with price feed
        if (eurAmount == 0) {
            return false;
        }

        if (_permissionsBlance[0] > 0 && currentTradigBalace.add(eurAmount) <= tradingLimit) {
            return true;
        }

        // Neither Tier 2 or Tier 1
        return false;
    }

    /**
     * @dev Checks user permissions when rejected.
     *
     * @param _operation operation to authorized.
     */
    function checkRejected(bytes4 _operation) internal pure returns (bool) {
        // Only allowed to unwind position (burn)
        return _operation == ERC20_BURN_FROM;
    }

    /**
     * @dev Checks protocol contract type permissions .
     *
     * @param _operation operation to authorized.
     * @param _permissionUser user's protocol contract permission.
     * @param _permissionSender sender's protocol contract permission.
     */
    function checkProtocolContract(
        bytes4 _operation,
        uint256 _permissionUser,
        uint256 _permissionSender
    ) internal pure returns (bool) {
        if (_operation == ERC20_TRANSFER || _operation == ERC20_TRANSFER_FROM) {
            // the sender should be PROTOCOL_CONTRACT
            return _permissionSender > 0;
        }

        if (_operation == ERC20_MINT || _operation == ERC20_BURN_FROM) {
            // minting to or berning from should be PROTOCOL_CONTRACT
            return _permissionUser > 0;
        }

        return false;
    }

    /**
     * @dev Returns `true` if `_operation` is an ERC20 method.
     *
     * @param _operation Method sig.
     */
    function isERC20Operation(bytes4 _operation) internal pure returns (bool) {
        return
            _operation == ERC20_TRANSFER ||
            _operation == ERC20_TRANSFER_FROM ||
            _operation == ERC20_MINT ||
            _operation == ERC20_BURN_FROM;
    }

    /**
     * @dev Returns `true` if `_operation` is a BFatory method.
     *
     * @param _operation Method sig.
     */
    function isBFactoryOperation(bytes4 _operation) internal pure returns (bool) {
        return _operation == BFACTORY_NEW_POOL;
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
library SafeMathUpgradeable {
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

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title AuthorizationStorage
 * @author Protofire
 * @dev Storage structure used by Authorization contract.
 *
 * All storage must be declared here
 * New storage must be appended to the end
 * Never remove items from this list
 */
abstract contract AuthorizationStorage {
    /// @dev Permissions module address
    address public permissions;
    /// @dev EurPriceFeed module address
    address public eurPriceFeed;
    /// @dev OperationsRegistry address
    address public operationsRegistry;
    /// @dev Balancer BFactory address
    address public poolFactory;
    /// @dev XTokenWrapper address
    address public xTokenWrapper;
    /// @dev Traiding limit value (in WEI) for some type of users
    uint256 public tradingLimit;

    /// @dev Indicates if protocol is paused
    bool public paused;

    bytes4 public constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 public constant ERC20_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 public constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 public constant ERC20_MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 public constant ERC20_BURN_FROM = bytes4(keccak256("burnFrom(address,uint256)"));
    bytes4 public constant BFACTORY_NEW_POOL = bytes4(keccak256("newBPool()"));

    // Constants for Permissions ID
    uint256 public constant SUSPENDED_ID = 0;
    uint256 public constant TIER_1_ID = 1;
    uint256 public constant TIER_2_ID = 2;
    uint256 public constant REJECTED_ID = 3;
    uint256 public constant PROTOCOL_CONTRACT = 4;
    uint256 public constant POOL_CREATOR = 5;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IAuthorization
 * @author Protofire
 * @dev Interface to be implemented by any Authorization logic contract.
 *
 */
interface IAuthorization {
    /**
     * @dev Sets `_permissions` as the new Permissions module.
     *
     * @param _permissions The address of the new Pemissions module.
     */
    function setPermissions(address _permissions) external;

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external;

    /**
     * @dev Sets `_operationsRegistry` as the new OperationsRegistry module.
     *
     * @param _operationsRegistry The address of the new OperationsRegistry module.
     */
    function setOperationsRegistry(address _operationsRegistry) external;

    /**
     * @dev Sets `_tradingLimit` as the new traiding limit.
     *
     * @param _tradingLimit The value of the new traiding limit.
     */
    function setTradingLimit(uint256 _tradingLimit) external;

    /**
     * @dev Sets `_poolFactory` as the new BFactory module.
     *
     * @param _poolFactory The address of the new Balance BFactory module.
     */
    function setPoolFactory(address _poolFactory) external;

    /**
     * @dev Sets `_xTokenWrapper` as the new XTokenWrapper module.
     *
     * @param _xTokenWrapper The address of the new XTokenWrapper module.
     */
    function setXTokenWrapper(address _xTokenWrapper) external;

    /**
     * @dev Determins if a user is allowed to perform an operation.
     *
     * @param _user msg.sender from function using Authorizable `onlyAuthorized` modifier.
     * @param _asset address of the contract using Authorizable `onlyAuthorized` modifier.
     * @param _operation msg.sig from function using Authorizable `onlyAuthorized` modifier.
     * @param _data msg.data from function using Authorizable `onlyAuthorized` modifier.
     * @return a boolean signaling the authorization.
     */
    function isAuthorized(
        address _user,
        address _asset,
        bytes4 _operation,
        bytes calldata _data
    ) external returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any EurPriceFeed logic contract used in the protocol.
 *
 */
interface IEurPriceFeed {
    /**
     * @dev Gets the price a `_asset` in EUR.
     *
     * @param _asset address of asset to get the price.
     */
    function getPrice(address _asset) external returns (uint256);

    /**
     * @dev Gets how many EUR represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the price.
     * @param _amount amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _amount) external view returns (uint256);

    /**
     * @dev Sets feed addresses for a given group of assets.
     *
     * @param _assets Array of assets addresses.
     * @param _feeds Array of asset/ETH price feeds.
     */
    function setAssetsFeeds(address[] memory _assets, address[] memory _feeds) external;

    /**
     * @dev Sets feed addresse for a given asset.
     *
     * @param _asset Assets address.
     * @param _feed Asset/ETH price feed.
     */
    function setAssetFeed(address _asset, address _feed) external;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any OperationRegistry logic contract use in the protocol.
 *
 */
interface IOperationsRegistry {
    /**
     * @dev Gets the balance traded by `_user` for an `_operation`.
     *
     * @param _user user's address
     * @param _operation msg.sig of the function considered an operation.
     */
    function tradingBalanceByOperation(address _user, bytes4 _operation) external view returns (uint256);

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external;

    /**
     * @dev Sets `_asset` as allowed for calling `addTrade`.
     *
     * @param _asset asset's address.
     */
    function allowAsset(address _asset) external;

    /**
     * @dev Sets `_asset` as disallowed for calling `addTrade`.
     *
     * @param _asset asset's address.
     */
    function disallowAsset(address _asset) external;

    /**
     * @dev Adds `_amount` converted to ERU to the balance traded by `_user` for an `_operation`.
     *
     * @param _user user's address
     * @param _operation msg.sig of the function considered an operation.
     * @param _amount msg.sig of the function considered an operation.
     */
    function addTrade(
        address _user,
        bytes4 _operation,
        uint256 _amount
    ) external;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./IBPool.sol";

interface IBFactory {
    event LOG_NEW_POOL(address indexed caller, address indexed pool);

    function isBPool(address b) external view returns (bool);

    function newBPool() external returns (IBPool);

    function setExchProxy(address exchProxy) external;

    function setOperationsRegistry(address operationsRegistry) external;

    function setPermissionManager(address permissionManager) external;

    function setAuthorization(address _authorization) external;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title IXTokenWrapper
 * @author Protofire
 * @dev XTokenWrapper Interface.
 *
 */
interface IXTokenWrapper is IERC1155Receiver {
    /**
     * @dev Token to xToken registry.
     */
    function tokenToXToken(address _token) external view returns (address);

    /**
     * @dev xToken to Token registry.
     */
    function xTokenToToken(address _xToken) external view returns (address);

    /**
     * @dev Wraps `_token` into its associated xToken.
     *
     */
    function wrap(address _token, uint256 _amount) external payable returns (bool);

    /**
     * @dev Unwraps `_xToken`.
     *
     */
    function unwrap(address _xToken, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool {
    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
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