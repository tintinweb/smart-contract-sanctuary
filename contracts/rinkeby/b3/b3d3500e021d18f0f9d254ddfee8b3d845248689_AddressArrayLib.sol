/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// File: contracts/raqam/AddressArrayLib.sol


pragma solidity ^0.8.0;

// library for address array 
library AddressArrayLib {
    using AddressArrayLib for addresses;

    struct addresses {
        address[] array;
    }

    function add(addresses storage self, address _address)
        external
    {
        if(! exists(self, _address)){
            self.array.push(_address);
        }
    }

    function getIndexByAddress(
        addresses storage self,
        address _address
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists_;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _address) {
                index = i;
                exists_ = true;
                break;
            }
        }
        return (index, exists_);
    }

    function remove(
        addresses storage self,
        address _address
    ) internal {
       for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                delete self.array[i];
            }
        }
    }


    function exists(
        addresses storage self,
        address _address
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                return true;
            }
        }
        return false;
    }
}

// File: contracts/raqam/RolesManager.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

abstract contract RolesManager {
    // Default Roles
    uint256 public constant ADMIN_ROLE = 1;
    uint256 public constant WITHDRAWER_ROLE = 2;
    uint256 public constant PAUSER_ROLE = 3;
    uint256 public constant AIRDROPPER_ROLE = 4;
    uint256 public constant COLLECTION_CREATER_ROLE = 5;

    // Mapping to store all manager for each role
    mapping(uint256 => address[]) roleManagers;

    // Mapping to store all roles for each manager
    mapping(address => uint256[]) managerRoles;

    // Function to check if user have specified Role
    function hasRole(uint256 _role, address _manager)
        public
        view
        returns (bool)
    {
        for (
            uint256 index = 0;
            index < managerRoles[_manager].length;
            index++
        ) {
            if (_role == managerRoles[_manager][index]) {
                return true;
            }
        }
        return false;
    }

    // Modifire to check if user have required privileges.
    modifier roleRequired(uint256 _role) {
        require(
            hasRole(_role, msg.sender),
            "RoleManager: User don't have required privileges for this action"
        );
        _;
    }

    // Function to set role to mananger
    function setRole(uint256 _role, address _manager)
        public
        roleRequired(ADMIN_ROLE)
    {
        require(
            !hasRole(_role, _manager),
            "RolesManager: Manager already have this Role"
        );
        require(
            _role == WITHDRAWER_ROLE ||
                _role == ADMIN_ROLE ||
                _role == COLLECTION_CREATER_ROLE ||
                _role == PAUSER_ROLE ||
                _role == AIRDROPPER_ROLE,
            "RolesManager: Unidentified Role"
        );

        roleManagers[_role].push(_manager);
        managerRoles[_manager].push(_role);
    }

    // Function to remove specified role except adminRole.
    function _removeRole(uint256 _role, address _manager) private {
        require(
            hasRole(_role, _manager),
            "RolesManager: Manager doesn't have this Role"
        );

        // Remove manager from role mapping
        for (uint256 index = 0; index < roleManagers[_role].length; index++) {
            if (roleManagers[_role][index] == _manager) {
                roleManagers[_role][index] = roleManagers[_role][
                    roleManagers[_role].length - 1
                ];
                roleManagers[_role].pop();
                break;
            }
        }

        // Remove role from manager's mapping
        for (
            uint256 index = 0;
            index < managerRoles[_manager].length;
            index++
        ) {
            if (managerRoles[_manager][index] == _role) {
                managerRoles[_manager][index] = managerRoles[_manager][
                    managerRoles[_manager].length - 1
                ];
                managerRoles[_manager].pop();
                break;
            }
        }
    }

    // Function to remove specified role except adminRole.
    function removeRole(uint256 _role, address _manager)
        public
        roleRequired(ADMIN_ROLE)
    {
        require(
            _role == WITHDRAWER_ROLE ||
                _role == COLLECTION_CREATER_ROLE ||
                _role == PAUSER_ROLE ||
                _role == AIRDROPPER_ROLE,
            "RolesManager: Unidentified Role"
        );

        _removeRole(_role, _manager);
    }

    // Private function to give all control of contract to this admin.
    function _createAdmin(address _newAdmin) internal {
        uint256[5] memory _roles = [
            WITHDRAWER_ROLE,
            ADMIN_ROLE,
            COLLECTION_CREATER_ROLE,
            PAUSER_ROLE,
            AIRDROPPER_ROLE
        ];

        for (uint256 index = 0; index < _roles.length; index++) {
            if (!hasRole(_roles[index], _newAdmin)) {
                roleManagers[_roles[index]].push(_newAdmin);
                managerRoles[_newAdmin].push(_roles[index]);
            }
        }
    }

    // Function to give all control of contract to this admin.
    function createAdmin(address _newAdmin) public roleRequired(ADMIN_ROLE) {
        _createAdmin(_newAdmin);
    }

    // Function to remove all control of contract to this admin.
    function removeAdmin(address _admin) public roleRequired(ADMIN_ROLE) {
        // Check if the _admin is only admin.
        require(
            roleManagers[ADMIN_ROLE].length > 1,
            "RolesManager: The Only admin, Can't be removed."
        );

        uint256[5] memory _roles = [
            WITHDRAWER_ROLE,
            ADMIN_ROLE,
            COLLECTION_CREATER_ROLE,
            PAUSER_ROLE,
            AIRDROPPER_ROLE
        ];

        for (uint256 index = 0; index < _roles.length; index++) {
            if (hasRole(_roles[index], _admin)) {
                _removeRole(_roles[index], _admin);
            }
        }
    }

    // Function to transfer the control from current account to new account.
    function changeAdmin(address _newAdmin) public roleRequired(ADMIN_ROLE) {
        createAdmin(_newAdmin);
        removeAdmin(msg.sender);
    }

    // Function to get all managers of role
    function getAllManagers(uint256 _role)
        public
        view
        returns (address[] memory)
    {
        return roleManagers[_role];
    }

    // Function to get all roles of manager
    function getAllRoles(address _manager)
        public
        view
        returns (uint256[] memory)
    {
        return managerRoles[_manager];
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Burnable_init_unchained();
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
    uint256[50] private __gap;
}

// File: contracts/raqam/ERC1155Collection.sol


pragma solidity ^0.8.0;





contract ERC1155Collection is
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    RolesManager
{
    function initialize() public initializer {
        __ERC1155_init("");
        tokenIdIndex = 1;
        _createAdmin(msg.sender);
    }
    // constructor(){
    // tokenIdIndex = 1;
    //  _createAdmin(msg.sender);
    // }

    struct collectionTimeings {
        
        uint256 VIPStartTiming;
        uint256 VIPEndingTiming;
        uint256 whitelistedStartTiming;
        uint256 whitelistedEndingTiming;
        uint256 normalStartingTime;
        uint256 normalEndingTime;
    }

  

    // Strcture to store the collection
    struct collection {
        string uri;
        uint256 price;
        uint256 priceForVIP;
        uint256 priceForWhitelisted;
        uint256 maxSupply;
        uint256 totalSupply;
        bool paused;
        collectionTimeings timings;
        //  uint256 normalStartingTime;
        // uint256 normalEndingTime;
        // uint256 VIPStartTiming;
        // uint256 VIPEndingTiming;
        // uint256 whitelistedStartTiming;
        // uint256 whitelistedEndingTiming;
    }

    // Storing all collections
    collection[] public collections;

    // Mapping to store contract's APIs
    mapping(uint256 => string) private tokenURIs;

    // Auto-Number generation.
    uint256 private tokenIdIndex;

    // Mapping to store all collections.
    mapping(uint256 => uint256[]) public collectionTokens;

    // Storing whitelisted and VIP users.
    using AddressArrayLib for AddressArrayLib.addresses;
    AddressArrayLib.addresses whitelistedUsers;
    AddressArrayLib.addresses VIPUsers;

    // Method to add whitelisted users.
    function addWhitelistedUsers(address[] memory users)
        public
        roleRequired(ADMIN_ROLE)
    {
        // Loop through users:
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers.add(users[index]);
        }
    }

    // Method to remove all whitelisted users.
    function removeWhitelistedUsers(address[] memory users)
        public
        roleRequired(ADMIN_ROLE)
    {
        // Loop through users:
        for (uint256 index = 0; index < users.length; index++) {
            whitelistedUsers.remove(users[index]);
        }
    }

    // Method to check if user is whitelisted user
    function isUserWhitelisted(address user) public view returns (bool) {
        return whitelistedUsers.exists(user);
    }

    // Method to get all whitelisted users
    function getWhitelistedUsers() public view returns (address[] memory) {
        return whitelistedUsers.array;
    }

    // Method to add VIP users.
    function addVIPUsers(address[] memory users)
        public
        roleRequired(ADMIN_ROLE)
    {
        // Loop through users:
        for (uint256 index = 0; index < users.length; index++) {
            VIPUsers.add(users[index]);
        }
    }

    // Method to remove all VIP users.
    function removeVIPUsers(address[] memory users)
        public
        roleRequired(ADMIN_ROLE)
    {
        // Loop through users:
        for (uint256 index = 0; index < users.length; index++) {
            VIPUsers.remove(users[index]);
        }
    }

    // Method to check if user is VIP user
    function isUserVIP(address user) public view returns (bool) {
        return VIPUsers.exists(user);
    }

    // Method to get all VIP users
    function getVIPUsers() public view returns (address[] memory) {
        return VIPUsers.array;
    }

    // Method to Return the minted token belong to particular collection or not
    function collectionHasTokenId(uint256 tokenId, uint256 collectionIndex)
        public
        view
        returns (bool)
    {
        for (
            uint256 index = 0;
            index < collectionTokens[collectionIndex].length;
            index++
        ) {
            if (collectionTokens[collectionIndex][index] == tokenId) {
                return true;
            }
        }
        return false;
    }

    // Method to create collection
    function createCollection(
       collection memory _collection
    ) public roleRequired(COLLECTION_CREATER_ROLE) {
        // Validate the VIP timeings.
        require(
            _collection.timings.VIPStartTiming < _collection.timings.VIPEndingTiming && _collection.timings.VIPEndingTiming > block.timestamp,
            "ERC1155: VIP start time must be less than VIP end time, VIP end time must be greater than current time "
        );
        require(
             _collection.timings.VIPStartTiming >= block.timestamp,
            "ERC1155: VIP start time must be greater than or equal to current time"
        );

        // Validate the Whitelisted timeings.
        require(
             _collection.timings.whitelistedStartTiming <  _collection.timings.whitelistedEndingTiming &&
                _collection.timings.whitelistedEndingTiming > block.timestamp,
            "ERC1155: Whitelisted start time must be less than whitelisted end time , whitelisted end time greater than current time "
        );
        require(
            _collection.timings.whitelistedStartTiming >=  _collection.timings.VIPEndingTiming,
            "ERC1155: whitelisted start time must be greater than or equal to VIP end time"
        );

        // collectionTimeings memory _Timings = collectionTimeings(
        //   _normalStartTime,
        //     _normalEndTime,
        //     _VIPStartTime,
        //     _VIPEndTime,
        //     _whitelistedStartTime,
        //     _whitelistedEndTime
        // );

        // collection memory _collection = collection(
        //     _uri,
        //     price,
        //     priceForVIP,
        //     priceForWhitelisted,
        //     maxSupply,
        //     0,
        //     false,
        //    _Timings
        // );
        collections.push(_collection);
        
        
    }

    // Method to update start and end time of collection
    function updateCollectionTimePrice(
        uint256 _VIPStartTime,
        uint256 _VIPEndTime,
        uint256 _whitelistedStartTime,
        uint256 _whitelistedEndTime,
        uint256 collectionIndex,
        uint256 _priceForVIP,
        uint256 _priceForWhitelisted
    ) public roleRequired(PAUSER_ROLE) {
        // Validate the VIP timeings.
        require(
            _VIPStartTime < _VIPEndTime && _VIPEndTime > block.timestamp,
            "ERC1155: VIP start time must be less than VIP end time, VIP end time must be greater than current time "
        );
        require(
            _VIPStartTime >= block.timestamp,
            "ERC1155: VIP start time must be greater than or equal to current time"
        );

        // Validate the Whitelisted timeings.
        require(
            _whitelistedStartTime < _whitelistedEndTime &&
                _whitelistedEndTime > block.timestamp,
            "ERC1155: Whitelisted start time must be less than whitelisted end time , whitelisted end time greater than current time "
        );
        require(
            _whitelistedStartTime >= _VIPEndTime,
            "ERC1155: whitelisted start time must be greater than or equal to VIP end time"
        );

        collection storage _collection = collections[collectionIndex];
        _collection.timings.VIPStartTiming = _VIPStartTime;
        _collection.timings.VIPEndingTiming = _VIPEndTime;
        _collection.timings.whitelistedStartTiming = _whitelistedStartTime;
        _collection.timings.whitelistedEndingTiming = _whitelistedEndTime;

        if (_priceForVIP > 0 && _priceForWhitelisted > 0) {
            _collection.priceForVIP = _priceForVIP;
            _collection.priceForWhitelisted = _priceForWhitelisted;
        }
    }

    // Method to get collection length
    function getCollectionLength() public view returns (uint256) {
        return collections.length;
    }

    // Method to mint NFT to some user after paying the price.
    function mint(
        address to,
        uint256 collectionIndex,
        uint256 edition,
        string memory _tokenURI
    ) public payable {
        require(
            collectionIndex < collections.length,
            "ERC1155: Collection doesn't exist."
        );
        collection storage _collection = collections[collectionIndex];

        // Check if collection is in VIP minting phase:
        if (
            _collection.timings.VIPStartTiming <= block.timestamp &&
            _collection.timings.VIPEndingTiming >= block.timestamp
        ) {
            require(isUserVIP(msg.sender), "ERC1155: VIP user minting only");
            require(
                msg.value >= _collection.priceForVIP,
                "ERC1155: Insufficient amount transferred."
            );
        }

        // Check if collection is in whitelisted minting phase:
       else if (
            _collection.timings.whitelistedStartTiming <= block.timestamp &&
            _collection.timings.whitelistedEndingTiming >= block.timestamp
        ) {
            require(
                isUserWhitelisted(msg.sender),
                "ERC1155: Whitelisted user minting only"
            );
            require(
                msg.value >= _collection.priceForWhitelisted,
                "ERC1155: Insufficient amount transferred."
            );
        }

        else{
            require(
                msg.value >= _collection.price,
                "ERC1155: Insufficient amount transferred."
            );

            require(_collection.timings.normalStartingTime <= block.timestamp && 
            _collection.timings.normalEndingTime >= block.timestamp
            ,"ERC1155: Minting time not started or  expired .");
        }
        
        require(
            edition == _collection.totalSupply + 1,
            "ERC1155: Edition not allowed to create."
        );
        require(
            _collection.totalSupply < _collection.maxSupply,
            "ERC1155: Max supply reached."
        );
        require(
            !_collection.paused,
            "ERC1155: Minting paused for this collection"
        );
        _mint(to, tokenIdIndex, 1, "");
        collectionTokens[collectionIndex].push(tokenIdIndex);
        _collection.totalSupply++;
        tokenURIs[tokenIdIndex] = _tokenURI;
        tokenIdIndex++;
    }

    // Method to get tokenURI
    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId];
    }

    // Method to withdraw fund from contract
    function withdraw(uint256 amount) public roleRequired(WITHDRAWER_ROLE) {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    // Method to pause specific collection
    function pauseCollection(uint256 collectionIndex)
        public
        roleRequired(PAUSER_ROLE)
    {
        require(
            collectionIndex < collections.length,
            "ERC1155: Collection doesn't exist."
        );
        require(
            !collections[collectionIndex].paused,
            "ERC1155: Collection already paused."
        );
        collections[collectionIndex].paused = true;
    }

    // Method to unpause specific collection
    function unpauseCollection(uint256 collectionIndex)
        public
        roleRequired(PAUSER_ROLE)
    {
        require(
            collectionIndex < collections.length,
            "ERC1155: Collection doesn't exist."
        );
        require(
            collections[collectionIndex].paused,
            "ERC1155: Collection not paused."
        );
        collections[collectionIndex].paused = false;
    }

    // Method to pause all collections
    function pauseMintingForAll() public roleRequired(PAUSER_ROLE) {
        for (uint256 index = 0; index < collections.length; index++) {
            if (!collections[index].paused) {
                collections[index].paused = true;
            }
        }
    }

    // Method to pause all collections
    function unpauseMintingForAll() public roleRequired(PAUSER_ROLE) {
        for (uint256 index = 0; index < collections.length; index++) {
            if (collections[index].paused) {
                collections[index].paused = false;
            }
        }
    }

    // Method to Mint NFT to toAddress without the payment.
    function airDrop(
        address[] memory toAddresses,
        uint256[] memory collectionIndices,
        uint256[] memory editions,
        string[] memory _tokenURIs
    ) public roleRequired(AIRDROPPER_ROLE) {
        require(
            toAddresses.length == collectionIndices.length &&
                collectionIndices.length == editions.length &&
                editions.length == _tokenURIs.length,
            "Length should be same between 'toAddresses', 'collectionIndices', 'editions' and '_tokenURIs'"
        );

        for (uint256 index = 0; index < toAddresses.length; index++) {
            require(
                collectionIndices[index] < collections.length,
                "ERC1155: Collection doesn't exist."
            );
            collection storage _collection = collections[
                collectionIndices[index]
            ];
            require(
                editions[index] == _collection.totalSupply + 1,
                "ERC1155: Edition not allowed to create."
            );
            require(
                _collection.totalSupply < _collection.maxSupply,
                "ERC1155: Max supply reached."
            );
            require(
                !_collection.paused,
                "ERC1155: Minting paused for this collection"
            );
            _mint(toAddresses[index], tokenIdIndex, 1, "");
            collectionTokens[collectionIndices[index]].push(tokenIdIndex);
            _collection.totalSupply++;
            tokenURIs[tokenIdIndex] = _tokenURIs[index];
            tokenIdIndex++;
        }
    }

    // Override ERC1155 method
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}