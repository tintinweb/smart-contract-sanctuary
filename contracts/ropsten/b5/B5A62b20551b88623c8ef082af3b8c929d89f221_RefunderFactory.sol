//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IRegistry.sol";
import "./Refunder.sol";

/**
 *  @title RefunderFactory - factory contract for deploying refunder contracts
 */
contract RefunderFactory {
    /// @notice Address of the refunder registry
    address public registry;

    /// @notice The version of the refunder
    uint8 public constant REFUNDER_VERSION = 1;

    /// @notice Event emitted once new refunder is deployed
    event RefunderCreated(
        address indexed owner,
        address indexed refunderAddress
    );

    constructor(address registry_) {
        registry = registry_;
    }

    /**
     * @notice Creates new instance of a refunder contract
     */
    function createRefunder() external returns (address) {
        Refunder refunder = new Refunder(registry);
        refunder.transferOwnership(msg.sender);

        IRegistry(registry).register(address(refunder), REFUNDER_VERSION);

        emit RefunderCreated(msg.sender, address(refunder));
        return address(refunder);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IRegistry {
    function register(address refunder, uint8 version) external;

    function updateRefundable(
        address targetAddress,
        bytes4 identifier,
        bool supported
    ) external;

    function getRefundersCount() external view returns (uint256);

    function getRefunder(uint256 index) external returns (address);

    function getRefunderCountFor(address targetAddress, bytes4 identifier)
        external
        view
        returns (uint256);

    function getRefunderForAtIndex(
        address targetAddress,
        bytes4 identifier,
        uint256 index
    ) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IRefunder.sol";
import "./IRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 *  @title Refunder - core contract for refunding arbitrary contract+indentifier calls
 *  between 96%-99% of the gas costs of the transaction
 */
contract Refunder is ReentrancyGuard, Ownable, Pausable, IRefunder {
    using Address for address;

    /// @notice Address of the refunder registry
    address public registry;

    /// @notice The maximum allowed gas price that the refunder is willing to refund
    uint256 public maxGasPrice = 0;

    /**
     *  @notice The base gas cost of the `relayAndRefun` transaction up until the point where the first `gasLeft` is executed
     *  Important: Gas costs for the transaction arguments are not included!
     *  Calculation: base 21_000 + 128 (8 non_zero_identifier_bytes) + 96 (24 zero_identifier_bytes) + 762 (gas costs until gasProvided variable)
     */
    uint256 public constant BASE_TX_COST = 21986;

    /// @notice The gas cost for executing refund internal function + emitting RelayAndRefund event
    uint256 public constant REFUND_OP_COST = 6440;

    /**
     * @notice Struct storing the refundable data for a given target
     * isSupported marks whether the refundable is supported or not
     * validatingContract contract address to call for business logic validation on every refund
     * validatingIdentifier identifier to call for business logic validation on every refund
     */
    struct Refundable {
        bool isSupported;
        address validatingContract;
        bytes4 validatingIdentifier;
    }

    /// @notice refundables mapping storing all of the supported `target` + `identifier` refundables
    mapping(address => mapping(bytes4 => Refundable)) public refundables;

    /// @notice Deposit event emitted once someone deposits ETH to the contract
    event Deposit(address indexed depositor, uint256 amount);

    /// @notice Withdraw event emitted once the owner withdraws ETH from the contract
    event Withdraw(address indexed recipient, uint256 amount);

    /// @notice GasPriceChange event emitted once the Max Gas Price is updated
    event GasPriceChange(uint256 newGasPrice);

    /// @notice RefundableUpdate event emitted once the owner updates the refundables
    event RefundableUpdate(
        address indexed targetContract,
        bytes4 indexed identifier,
        bool isRefundable,
        address validatingContract,
        bytes4 validatingIdentifier
    );

    /// @notice RelayAndRefund event emitted once someone executes transaction for which the contract will refund him of up to 99% of the cost
    event RelayAndRefund(
        address indexed caller,
        address indexed target,
        bytes4 indexed identifier,
        uint256 refundAmount
    );

    /**
     * @notice Constructor
     * @param _registry The address of the registry
     */
    constructor(address _registry) {
        registry = _registry;
    }

    /**
     * @notice Validates that the provided target+identifier is marked as refundable and that the gas price is
     * lower than the maximum allowed one
     * @param targetContract the contract that will be called
     * @param identifier the function to be called
     */
    modifier onlySupportedParams(address targetContract, bytes4 identifier) {
        require(tx.gasprice <= maxGasPrice, "Refunder: Invalid gas price");
        require(
            refundables[targetContract][identifier].isSupported,
            "Refunder: Non-refundable call"
        );

        _;
    }

    /**
     * @notice calculates the net gas cost for refunding and refunds the msg.sender afterwards
     */
    modifier netGasCost(address target, bytes4 identifier) {
        uint256 gasProvided = gasleft();

        _;

        uint256 gasUsedSoFar = gasProvided - gasleft();
        uint256 gas = gasUsedSoFar + BASE_TX_COST + REFUND_OP_COST;
        uint256 refundAmount = gas * tx.gasprice;

        Address.sendValue(msg.sender, refundAmount);
        emit RelayAndRefund(msg.sender, target, identifier, refundAmount);
    }

    /// @notice receive function for depositing ETH into the contract
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraws ETH from the contract
     * @param amount amount of ETH to withdraw
     */
    function withdraw(uint256 amount) external override onlyOwner nonReentrant {
        require(
            address(this).balance >= amount,
            "Refunder: Insufficient balance"
        );

        Address.sendValue(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Updates the maximum gas price of transactions that the refunder will refund
     * @param gasPrice the maximum gas price to refund
     */
    function setMaxGasPrice(uint256 gasPrice) external override onlyOwner {
        maxGasPrice = gasPrice;
        emit GasPriceChange(gasPrice);
    }

    /**
     * @notice Updates the map of the refundables. Refundable can be added / removed depending on the isRefundable param
     * @param targetContract the contract for which we are updating the refundables
     * @param identifier the function for which we are updating the refundables
     * @param isRefundable_ whether the contract will refund the combination of `target` + `iterfaceId` or not
     */
    function updateRefundable(
        address targetContract,
        bytes4 identifier,
        bool isRefundable_,
        address validatingContract,
        bytes4 validatingIdentifier
    ) external override onlyOwner {
        refundables[targetContract][identifier] = Refundable(
            isRefundable_,
            validatingContract,
            validatingIdentifier
        );
        IRegistry(registry).updateRefundable(
            targetContract,
            identifier,
            isRefundable_
        );

        emit RefundableUpdate(
            targetContract,
            identifier,
            isRefundable_,
            validatingContract,
            validatingIdentifier
        );
    }

    /**
     * @notice Benchmarks the gas costs and executes `target` + `identifier` with the provided `arguments`
     * Once executed, the msg.sender gets refunded up to 99% of the gas cost
     * @param target the contract to call
     * @param identifier the function to call
     * @param arguments the bytes of data to pass as arguments
     */
    function relayAndRefund(
        address target,
        bytes4 identifier,
        bytes memory arguments
    )
        external
        override
        netGasCost(target, identifier)
        nonReentrant
        onlySupportedParams(target, identifier)
        whenNotPaused
        returns (bytes memory)
    {
        Refundable memory _refundableData = refundables[target][identifier];
        if (_refundableData.validatingContract != address(0)) {
            bytes memory validationArgs =
                abi.encodeWithSelector(
                    _refundableData.validatingIdentifier,
                    msg.sender,
                    target,
                    identifier,
                    arguments
                );
            (bool success, bytes memory returnData) =
                _refundableData.validatingContract.call(validationArgs);
            require(success, "Refunder: Validating contract reverted");

            bool isAllowed = abi.decode(returnData, (bool));
            require(
                isAllowed,
                "Refunder: Validating contract rejected the refund"
            );
        }

        bytes memory data = abi.encodeWithSelector(identifier, arguments);
        (bool success, bytes memory returnData) = target.call(data);

        require(success, "Refunder: Function call not successful");
        return returnData;
    }

    /// @notice Pauses refund operations of the contract
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Unpauses the refund operations of the contract
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice Returns true/false whether the
    function getRefundable(address target, bytes4 identifier)
        external
        view
        returns (Refundable memory)
    {
        return refundables[target][identifier];
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IRefunder {
    function updateRefundable(
        address targetContract,
        bytes4 identifier,
        bool isRefundable_,
        address validationContract,
        bytes4 validationFunc
    ) external;

    function withdraw(uint256 amount) external;

    function relayAndRefund(
        address target,
        bytes4 identifier,
        bytes memory arguments
    ) external returns (bytes memory);

    function setMaxGasPrice(uint256 gasPrice) external;

    function pause() external;

    function unpause() external;
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

