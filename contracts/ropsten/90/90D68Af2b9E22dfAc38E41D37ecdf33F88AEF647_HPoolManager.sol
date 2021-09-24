/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

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


// File @openzeppelin/contracts-upgradeable/introspection/[email protected]


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(address(0)).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(address(0)).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}


// File contracts/interfaces/AggregatorV3Interface.sol

pragma solidity 0.6.12;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}


// File @openzeppelin/contracts/introspection/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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


// File contracts/interfaces/IHordTicketFactory.sol

pragma solidity ^0.6.12;

/**
 * IHordTicketFactory contract.
 * @author Nikola Madjarevic
 * Date created: 11.5.21.
 * Github: madjarevicn
 */
interface IHordTicketFactory is IERC1155 {
    function getTokenSupply(uint tokenId) external view returns (uint256);
    function lastMintedTokenId() external view returns (uint256);
}


// File contracts/interfaces/IHordTreasury.sol

pragma solidity 0.6.12;

/**
 * IHordTreasury contract.
 * @author Nikola Madjarevic
 * Date created: 14.7.21.
 * Github: madjarevicn
 */
interface IHordTreasury {
    function depositToken(address token, uint256 amount) external;
}


// File contracts/interfaces/IHPoolFactory.sol

pragma solidity 0.6.12;

/**
 * IHPoolFactory contract.
 * @author Nikola Madjarevic
 * Date created: 29.7.21.
 * Github: madjarevicn
 */
interface IHPoolFactory {
    function deployHPool(uint256 hPoolId) external returns (address);
}


// File contracts/interfaces/IHordConfiguration.sol

pragma solidity 0.6.12;

/**
 * IHordConfiguration contract.
 * @author Nikola Madjarevic
 * Date created: 4.8.21.
 * Github: madjarevicn
 */
interface IHordConfiguration {
    function minChampStake() external view returns(uint256);
    function maxWarmupPeriod() external view returns(uint256);
    function maxFollowerOnboardPeriod() external view returns(uint256);
    function minFollowerUSDStake() external view returns(uint256);
    function maxFollowerUSDStake() external view returns(uint256);
    function minStakePerPoolTicket() external view returns(uint256);
    function assetUtilizationRatio() external view returns(uint256);
    function gasUtilizationRatio() external view returns(uint256);
    function platformStakeRatio() external view returns(uint256);
    function percentPrecision() external view returns(uint256);
    function maxSupplyHPoolToken() external view returns(uint256);
    function maxUSDAllocationPerTicket() external view returns (uint256);
    function totalSupplyHPoolTokens() external view returns (uint256);
    function endTimeTicketSale() external view returns (uint256);
    function endTimePrivateSubscription() external view returns (uint256);
    function endTimePublicSubscription() external view returns (uint256);
}


// File contracts/interfaces/IHPool.sol

pragma solidity 0.6.12;

/**
 * IHPool contract.
 * @author Nikola Madjarevic
 * Date created: 29.7.21.
 * Github: madjarevicn
 */
interface IHPool {
    function depositBudgetFollowers() external payable;
    function depositBudgetChampion() external payable;
    function mintHPoolToken(string memory name, string memory symbol, uint256 _totalSupply) external;
}


// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity ^0.6.12;

/**
 * IMaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/HordUpgradable.sol

pragma solidity ^0.6.12;

/**
 * HordUpgradables contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "HordUpgradable: Restricted only to Maintainer");
        _;
    }

    // Only chainport congress modifier
    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "HordUpgradable: Restricted only to HordCongress");
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    function setMaintainersRegistry(
        address _maintainersRegistry
    )
    public
    onlyHordCongress
    {
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }
}


// File contracts/libraries/SafeMath.sol


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


// File contracts/hPools/HPoolManager.sol

pragma solidity 0.6.12;








/**
 * HPoolManager contract.
 * @author Nikola Madjarevic
 * Date created: 7.7.21.
 * Github: madjarevicn
 */
contract HPoolManager is ERC1155HolderUpgradeable, HordUpgradable {
    using SafeMath for *;

    // States of the pool contract
    enum PoolState {
        PENDING_INIT,
        TICKET_SALE,
        PRIVATE_SUBSCRIPTION,
        PUBLIC_SUBSCRIPTION,
        SUBSCRIPTION_FAILED,
        ASSET_STATE_TRANSITION_IN_PROGRESS,
        ACTIVE,
        FINISHING,
        ENDED
    }

    enum SubscriptionRound {
        PRIVATE,
        PUBLIC
    }

    // Address for HORD token
    address public hordToken;
    // Constant, representing 1ETH in WEI units.
    uint256 public constant one = 10e18;

    // Subscription struct, represents subscription of user
    struct Subscription {
        address user;
        uint256 amountEth;
        uint256 numberOfTickets;
        SubscriptionRound sr;
        bool isSubscriptionWithdrawnPoolTerminated;
    }

    // HPool struct
    struct hPool {
        PoolState poolState;
        uint256 championEthDeposit;
        address championAddress;
        uint256 createdAt;
        uint256 endTicketSalePhase;
        uint256 endPrivateSubscriptionPhase;
        uint256 endPublicSubscriptionSalePhase;
        uint256 nftTicketId;
        uint256 numberOfTicketsUsed;
        bool isValidated;
        uint256 followersEthDeposit;
        address hPoolContractAddress;
        uint256 treasuryFeePaid;
    }

    // Instance of Hord Configuration contract
    IHordConfiguration internal hordConfiguration;
    // Instance of oracle
    AggregatorV3Interface internal linkOracle;
    // Instance of hord ticket factory
    IHordTicketFactory internal hordTicketFactory;
    // Instance of Hord treasury contract
    IHordTreasury internal hordTreasury;
    // Instance of HPool Factory contract
    IHPoolFactory internal hPoolFactory;

    // All hPools
    hPool[] public hPools;
    // Map pool Id to all subscriptions
    mapping(uint256 => Subscription[]) internal poolIdToSubscriptions;
    // Map user address to pool id to his subscription for that pool
    mapping(address => mapping(uint256 => Subscription))
        internal userToPoolIdToSubscription;
    // Mapping user to ids of all pools he has subscribed for
    mapping(address => uint256[]) internal userToPoolIdsSubscribedFor;
    // Support listing pools per champion
    mapping(address => uint256[]) internal championAddressToHPoolIds;

    /**
     * Events
     */
    event PoolInitRequested(
        uint256 poolId,
        address champion,
        uint256 championEthDeposit,
        uint256 timestamp,
        uint256 bePoolId
    );
    event TicketIdSetForPool(uint256 poolId, uint256 nftTicketId);
    event HPoolStateChanged(uint256 poolId, PoolState newState);
    event Subscribed(
        uint256 poolId,
        address user,
        uint256 amountETH,
        uint256 numberOfTickets,
        SubscriptionRound sr
    );
    event TicketsWithdrawn(
        uint256 poolId,
        address user,
        uint256 numberOfTickets
    );
    event SubscriptionWithdrawn(
        uint256 poolId,
        address user,
        uint256 amountEth,
        uint256 numberOfTickets
    );
    event ServiceFeePaid(uint256 poolId, uint256 amount);
    event HPoolLaunchFailed(uint256 poolId);

    /**
     * @notice          Initializer function, can be called only once, replacing constructor
     * @param           _hordCongress is the address of HordCongress contract
     * @param           _maintainersRegistry is the address of the MaintainersRegistry contract
     */
    function initialize(
        address _hordCongress,
        address _maintainersRegistry,
        address _hordTicketFactory,
        address _hordTreasury,
        address _hordToken,
        address _hPoolFactory,
        address _chainlinkOracle,
        address _hordConfiguration
    ) external initializer {
        require(_hordCongress != address(0));
        require(_maintainersRegistry != address(0));
        require(_hordTicketFactory != address(0));
        require(_hordConfiguration != address(0));

        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
        hordTicketFactory = IHordTicketFactory(_hordTicketFactory);
        hordTreasury = IHordTreasury(_hordTreasury);
        hPoolFactory = IHPoolFactory(_hPoolFactory);
        hordToken = _hordToken;

        linkOracle = AggregatorV3Interface(_chainlinkOracle);
        hordConfiguration = IHordConfiguration(_hordConfiguration);
    }

    /**
     * @notice          Internal function to handle safe transferring of ETH.
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    /**
     * @notice          Internal function to pay service to hord treasury contract
     */
    function payServiceFeeToTreasury(uint256 poolId, uint256 amount) internal {
        safeTransferETH(address(hordTreasury), amount);
        emit ServiceFeePaid(poolId, amount);
    }

    /**
     * @notice          Function where champion can create his pool.
     *                  In case champion is not approved, maintainer can cancel his pool creation,
     *                  and return him back the funds.
     */
    function createHPool(uint256 bePoolId) external payable {
        require(
            msg.value >= getMinimalETHToInitPool(),
            "ETH amount is less than minimal deposit."
        );

        // Create hPool structure
        hPool memory hp;

        hp.poolState = PoolState.PENDING_INIT;
        hp.championEthDeposit = msg.value;
        hp.championAddress = msg.sender;
        hp.createdAt = block.timestamp;

        // Compute ID to match position in array
        uint256 poolId = hPools.length;
        // Push hPool structure
        hPools.push(hp);

        // Add Id to list of ids for champion
        championAddressToHPoolIds[msg.sender].push(poolId);

        // Trigger events
        emit PoolInitRequested(
            poolId,
            msg.sender,
            msg.value,
            block.timestamp,
            bePoolId
        );
        emit HPoolStateChanged(poolId, hp.poolState);
    }

    /**
     * @notice          Function to set NFT for pool, which will at the same time validate the pool itself.
     * @param           poolId is the ID of the pool contract.
     */
    function setNftForPool(uint256 poolId, uint256 _nftTicketId)
        external
        onlyMaintainer
    {
        require(poolId < hPools.length, "hPool with poolId does not exist.");
        require(_nftTicketId > 0, "NFT id can not be 0.");
        require(_nftTicketId <= hordTicketFactory.lastMintedTokenId(), "NFT does not exist");

        hPool storage hp = hPools[poolId];

        require(!hp.isValidated, "hPool already validated.");
        require(
            hp.poolState == PoolState.PENDING_INIT,
            "Bad state transition."
        );

        hp.isValidated = true;
        hp.nftTicketId = _nftTicketId;
        hp.poolState = PoolState.TICKET_SALE;
        hp.endTicketSalePhase = block.timestamp + hordConfiguration.endTimeTicketSale();

        emit TicketIdSetForPool(poolId, hp.nftTicketId);
        emit HPoolStateChanged(poolId, hp.poolState);
    }

    /**
     * @notice          Function to start private subscription phase. Can be started only if previous
     *                  state of the hPool was TICKET_SALE.
     * @param           poolId is the ID of the pool contract.
     */
    function startPrivateSubscriptionPhase(uint256 poolId)
        external
        onlyMaintainer
    {
        require(poolId < hPools.length, "hPool with poolId does not exist.");

        hPool storage hp = hPools[poolId];

        require(hp.poolState == PoolState.TICKET_SALE);
        hp.poolState = PoolState.PRIVATE_SUBSCRIPTION;
        hp.endPrivateSubscriptionPhase = block.timestamp + hordConfiguration.endTimePrivateSubscription();

        emit HPoolStateChanged(poolId, hp.poolState);
    }

    /**
     * @notice          Function for users to subscribe for the hPool.
     */
    function privateSubscribeForHPool(uint256 poolId) external payable {
        hPool storage hp = hPools[poolId];
        require(
            hp.poolState == PoolState.PRIVATE_SUBSCRIPTION,
            "hPool is not in PRIVATE_SUBSCRIPTION state."
        );

        Subscription memory s = userToPoolIdToSubscription[msg.sender][poolId];
        require(s.amountEth == 0, "User can not subscribe more than once.");

        uint256 numberOfTicketsToUse = getRequiredNumberOfTicketsToUse(
            msg.value
        );
        require(numberOfTicketsToUse > 0);

        hordTicketFactory.safeTransferFrom(
            msg.sender,
            address(this),
            hp.nftTicketId,
            numberOfTicketsToUse,
            "0x0"
        );

        s.amountEth = msg.value;
        s.numberOfTickets = numberOfTicketsToUse;
        s.user = msg.sender;
        s.sr = SubscriptionRound.PRIVATE;

        // Store subscription
        poolIdToSubscriptions[poolId].push(s);
        userToPoolIdToSubscription[msg.sender][poolId] = s;
        userToPoolIdsSubscribedFor[msg.sender].push(poolId);
        hp.numberOfTicketsUsed = hp.numberOfTicketsUsed.add(numberOfTicketsToUse);

        hp.followersEthDeposit = hp.followersEthDeposit.add(msg.value);

        emit Subscribed(
            poolId,
            msg.sender,
            msg.value,
            numberOfTicketsToUse,
            s.sr
        );
    }

    function startPublicSubscriptionPhase(uint256 poolId)
        external
        onlyMaintainer
    {
        require(poolId < hPools.length, "hPool with poolId does not exist.");

        hPool storage hp = hPools[poolId];

        uint256 maxTicketsToUse = getRequiredNumberOfTicketsToUse(hordConfiguration.maxFollowerUSDStake());

        require(block.timestamp >= hp.endPrivateSubscriptionPhase || hp.numberOfTicketsUsed < maxTicketsToUse);
        require(hp.poolState == PoolState.PRIVATE_SUBSCRIPTION);
        hp.poolState = PoolState.PUBLIC_SUBSCRIPTION;
        hp.endPublicSubscriptionSalePhase = block.timestamp + hordConfiguration.endTimePublicSubscription();

        emit HPoolStateChanged(poolId, hp.poolState);
    }

    /**
     * @notice          Function for users to subscribe for the hPool.
     */
    function publicSubscribeForHPool(uint256 poolId) external payable {
        hPool storage hp = hPools[poolId];
        require(
            hp.poolState == PoolState.PUBLIC_SUBSCRIPTION,
            "hPool is not in PUBLIC_SUBSCRIPTION state."
        );

        Subscription memory s = userToPoolIdToSubscription[msg.sender][poolId];
        require(s.amountEth == 0, "User can not subscribe more than once.");

        s.amountEth = msg.value;
        s.numberOfTickets = 0;
        s.user = msg.sender;
        s.sr = SubscriptionRound.PUBLIC;

        hp.followersEthDeposit = hp.followersEthDeposit.add(msg.value);

        // Store subscription
        poolIdToSubscriptions[poolId].push(s);
        userToPoolIdToSubscription[msg.sender][poolId] = s;
        userToPoolIdsSubscribedFor[msg.sender].push(poolId);

        emit Subscribed(poolId, msg.sender, msg.value, 0, s.sr);
    }

    /**
     * @notice          Maintainer should end subscription phase in case all the criteria is reached
     */
    function endSubscriptionPhaseAndInitHPool(uint256 poolId, string memory name, string memory symbol)
        external
        onlyMaintainer
    {
        hPool storage hp = hPools[poolId];
        require(
            hp.poolState == PoolState.PUBLIC_SUBSCRIPTION,
            "hPool is not in subscription state."
        );
        require(
            hp.followersEthDeposit >= getMinSubscriptionToLaunchInETH(),
            "hPool subscription amount is below threshold."
        );

        hp.poolState = PoolState.ASSET_STATE_TRANSITION_IN_PROGRESS;

        // Deploy the HPool contract
        IHPool hpContract = IHPool(hPoolFactory.deployHPool(poolId));

        //Mint HPoolToken for certain HPool
        hpContract.mintHPoolToken(name, symbol, hordConfiguration.totalSupplyHPoolTokens());

        // Set the deployed address of hPool
        hp.hPoolContractAddress = address(hpContract);

        uint256 treasuryFeeETH = hp
            .followersEthDeposit
            .mul(hordConfiguration.gasUtilizationRatio())
            .div(hordConfiguration.percentPrecision());

        payServiceFeeToTreasury(poolId, treasuryFeeETH);

        hpContract.depositBudgetFollowers{
            value: hp.followersEthDeposit.sub(treasuryFeeETH)
        }();
        hpContract.depositBudgetChampion{value: hp.championEthDeposit}();

        hp.treasuryFeePaid = treasuryFeeETH;

        // Trigger event that pool state is changed
        emit HPoolStateChanged(poolId, hp.poolState);
    }

    function endSubscriptionPhaseAndTerminatePool(uint256 poolId)
        external
        onlyMaintainer
    {
        hPool storage hp = hPools[poolId];

        require(
            hp.poolState == PoolState.PUBLIC_SUBSCRIPTION,
            "hPool is not in subscription state."
        );
        require(
            hp.followersEthDeposit < getMinSubscriptionToLaunchInETH(),
            "hPool subscription amount is above threshold."
        );

        // Set new pool state
        hp.poolState = PoolState.SUBSCRIPTION_FAILED;

        // Trigger event
        emit HPoolStateChanged(poolId, hp.poolState);
        emit HPoolLaunchFailed(poolId);
    }

    function withdrawDeposit(uint256 poolId) public {
        hPool storage hp = hPools[poolId];
        Subscription storage s = userToPoolIdToSubscription[msg.sender][poolId];

        require(
            hp.poolState == PoolState.SUBSCRIPTION_FAILED,
            "Pool is not in valid state."
        );
        require(
            !s.isSubscriptionWithdrawnPoolTerminated,
            "Subscription already withdrawn"
        );

        if (s.numberOfTickets > 0) {
            hordTicketFactory.safeTransferFrom(
                address(this),
                msg.sender,
                hp.nftTicketId,
                s.numberOfTickets,
                "0x0"
            );
        }

        // Transfer subscription back to user
        safeTransferETH(msg.sender, s.amountEth);
        // Mark that user withdrawn his subscription.
        s.isSubscriptionWithdrawnPoolTerminated = true;
        // Fire SubscriptionWithdrawn event
        emit SubscriptionWithdrawn(
            poolId,
            msg.sender,
            s.amountEth,
            s.numberOfTickets
        );
        // Mark that user taken all tickets
        s.numberOfTickets = 0;
    }

    /**
     * @notice          Function to withdraw tickets. It can be called whenever after subscription phase.
     * @param           poolId is the ID of the pool for which user is withdrawing.
     */
    function withdrawTickets(uint256 poolId) public {
        hPool storage hp = hPools[poolId];
        Subscription storage s = userToPoolIdToSubscription[msg.sender][poolId];

        require(s.amountEth > 0, "User did not participate in this hPool.");
        require(
            s.numberOfTickets > 0,
            "User have already withdrawn his tickets."
        );
        require(
            uint256(hp.poolState) > 3,
            "Only after Subscription phase user can withdraw tickets."
        );

        hordTicketFactory.safeTransferFrom(
            address(this),
            msg.sender,
            hp.nftTicketId,
            s.numberOfTickets,
            "0x0"
        );

        // Trigger event that user have withdrawn tickets
        emit TicketsWithdrawn(poolId, msg.sender, s.numberOfTickets);

        // Remove users tickets.
        s.numberOfTickets = 0;
    }

    /**
     * @notice          Function to get minimal amount of ETH champion needs to
     *                  put in, in order to create hPool.
     * @return         Amount of ETH (in WEI units)
     */
    function getMinimalETHToInitPool() public view returns (uint256) {
        uint256 latestPrice = uint256(getLatestPrice());
        uint256 usdEThRate = one.mul(one).div(latestPrice);
        return usdEThRate.mul(hordConfiguration.minChampStake()).div(one);
    }

    /**
     * @notice          Function to get maximal amount of ETH user can subscribe with
     *                  per 1 access ticket
     * @return         Amount of ETH (in WEI units)
     */
    function getMaxSubscriptionInETHPerTicket() public view returns (uint256) {
        uint256 latestPrice = uint256(getLatestPrice());
        uint256 usdEThRate = one.mul(one).div(latestPrice);
        return
            usdEThRate.mul(hordConfiguration.maxUSDAllocationPerTicket()).div(
                one
            );
    }

    /**
     * @notice          Function to get minimal subscription in ETH so pool can launch
     */
    function getMinSubscriptionToLaunchInETH() public view returns (uint256) {
        uint256 latestPrice = uint256(getLatestPrice());
        uint256 usdEThRate = one.mul(one).div(latestPrice);
        return usdEThRate.mul(hordConfiguration.minFollowerUSDStake()).div(one);
    }

    /**
     * @notice          Function to fetch the latest price of the stored oracle.
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = linkOracle.latestRoundData();
        return price;
    }

    /**
     * @notice          Function to fetch on how many decimals is the response
     */
    function getDecimalsReturnPrecision() public view returns (uint8) {
        return linkOracle.decimals();
    }

    /**
     * @notice          Function to get IDs of all pools for the champion.
     */
    function getChampionPoolIds(address champion)
        external
        view
        returns (uint256[] memory)
    {
        return championAddressToHPoolIds[champion];
    }

    /**
     * @notice          Function to get IDs of pools for which user subscribed
     */
    function getPoolsUserSubscribedFor(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userToPoolIdsSubscribedFor[user];
    }

    /**
     * @notice          Function to compute how much user can currently subscribe in ETH for the hPool.
     */
    function getMaxUserSubscriptionInETH(address user, uint256 poolId)
        external
        view
        returns (uint256)
    {
        hPool memory hp = hPools[poolId];

        Subscription memory s = userToPoolIdToSubscription[user][poolId];

        if (s.amountEth > 0) {
            // User already subscribed, can subscribe only once.
            return 0;
        }

        uint256 numberOfTickets = hordTicketFactory.balanceOf(
            user,
            hp.nftTicketId
        );
        uint256 maxUserSubscriptionPerTicket = getMaxSubscriptionInETHPerTicket();

        return numberOfTickets.mul(maxUserSubscriptionPerTicket);
    }

    /**
     * @notice          Function to return required number of tickets for user to use in order to subscribe
     *                  with selected amount
     * @param           subscriptionAmount is the amount of ETH user wants to subscribe with.
     */
    function getRequiredNumberOfTicketsToUse(uint256 subscriptionAmount)
        public
        view
        returns (uint256)
    {
        uint256 maxParticipationPerTicket = getMaxSubscriptionInETHPerTicket();
        uint256 amountOfTicketsToUse = (subscriptionAmount).div(
            maxParticipationPerTicket
        );

        if (
            subscriptionAmount.mul(maxParticipationPerTicket) <
            amountOfTicketsToUse
        ) {
            amountOfTicketsToUse++;
        }

        return amountOfTicketsToUse;
    }

    /**
     * @notice          Function to get all subscribed addresses on one hPool
     */
    function getSubscribedAddresses(uint256 poolId, uint256 startIndex, uint256 endIndex)
    external
    view
    returns (address[] memory)
    {
        address[] memory subscribedAddresses = new address[](endIndex - startIndex);
        uint256 counter;

        for (uint256 i = startIndex; i < endIndex; i++) {
            subscribedAddresses[counter] = poolIdToSubscriptions[poolId][i].user;
            counter++;
        }

        return subscribedAddresses;
    }

    function getNumberOfTicketsUsed(uint256 poolId)
    external
    view
    returns (uint256)
    {
        return hPools[poolId].numberOfTicketsUsed;
    }

    /**
     * @notice          Function to get user subscription for the pool.
     * @param           poolId is the ID of the pool
     * @param           user is the address of user
     * @return          amount of ETH user deposited and number of tickets taken from user.
     */
    function getUserSubscriptionForPool(uint256 poolId, address user)
        external
        view
        returns (uint256, uint256)
    {
        Subscription memory subscription = userToPoolIdToSubscription[user][
            poolId
        ];

        return (subscription.amountEth, subscription.numberOfTickets);
    }

    /**
     * @notice          Function to get information for specific pool
     * @param           poolId is the ID of the pool
     */
    function getPoolInfo(uint256 poolId)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            bool,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Load pool into memory
        hPool memory hp = hPools[poolId];

        return (
            uint256(hp.poolState),
            hp.championEthDeposit,
            hp.championAddress,
            hp.createdAt,
            hp.nftTicketId,
            hp.isValidated,
            hp.followersEthDeposit,
            hp.hPoolContractAddress,
            hp.treasuryFeePaid,
            hp.endTicketSalePhase,
            hp.endPrivateSubscriptionPhase,
            hp.endPublicSubscriptionSalePhase
        );
    }
}