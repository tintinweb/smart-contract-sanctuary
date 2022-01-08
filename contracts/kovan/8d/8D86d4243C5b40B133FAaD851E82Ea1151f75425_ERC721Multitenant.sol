/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @liveart/contracts/Royalties.sol


pragma solidity ^0.8.0;

library Royalties {
    struct RoyaltyReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
        uint256 resalePercentage;
        uint256 CAPPS;
        uint256 fixedCut;
    }

    struct BuyOutReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
    }
}

// File: @liveart/contracts/ODRL.sol


pragma solidity ^0.8.0;

library ODRL {
    struct Party {
        string role;
        address wallet;
    }
    struct Policy {
        string action;
        uint256 target;
        Party permission;
    }

    string constant ACTION_BUY_OUT = "Buy out the NFT";
}

// File: @liveart/contracts/Mintable.sol


pragma solidity ^0.8.0;



library Mintable {
    struct TokenData {
        string tokenMetadataURI;
        uint256 editionOf;
        uint256 maxTokenSupply;
        address to;
    }
    struct TokenDataWithRoyalties {
        string tokenMetadataURI;
        uint256 editionOf;
        uint256 maxTokenSupply;
        address to;
        Royalties.RoyaltyReceiver[] royaltyReceivers;
        ODRL.Policy[] sellableRights;
        ODRL.Policy[] otherRights;
    }
    struct TokenDataWithBuyOut {
        string tokenMetadataURI;
        uint256 editionOf;
        uint256 maxTokenSupply;
        address to;
        Royalties.RoyaltyReceiver[] royaltyReceivers;
        ODRL.Policy[] sellableRights;
        ODRL.Policy[] otherRights;
        uint256 buyOutPrice;
        Royalties.BuyOutReceiver[] buyOutReceivers;
    }
}

// File: @liveart/contracts/ERC721/IERC721MultitenantStorage.sol


pragma solidity ^0.8.0;


interface IERC721MultitenantStorage {
    function registerApp(
        string calldata app,
        address[] memory minters,
        address[] memory pausers,
        address admin
    ) external;

    function balanceOf(
        string calldata app,
        address owner
    ) external view returns (uint256);

    function ownerOf(
        string calldata app,
        uint256 tokenId
    ) external view returns (address);

    function tokenURI(
        string calldata app,
        uint256 tokenId
    ) external view returns (string memory);

    function paused(
        string calldata app
    ) external view returns (bool);

    function approve(
        string calldata app,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(
        string calldata app,
        uint256 tokenId
    ) external view returns (address);

    function isApprovedForAll(
        string calldata app,
        address owner,
        address operator
    ) external view  returns (bool);

    function setApprovalForAll(
        string calldata app,
        address owner,
        address operator,
        bool approved
    ) external;

    function transferFrom(
        string calldata app,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        string calldata app,
        Mintable.TokenData memory tokenData
    ) external returns (uint256);

    function nextTokenId(
        string calldata app
    ) external view returns(uint256);

    function burn(
        string calldata app,
        uint256 tokenId
    ) external;

    function pause(
        string calldata app
    ) external;

    function unpause(
        string calldata app
    ) external;

    function totalSupply(
        string calldata app
    ) external view returns (uint256);

    function tokenOfOwnerByIndex(
        string calldata app,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    function tokenByIndex(
        string calldata app,
        uint256 index
    ) external view returns (uint256);

    function tokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);

    function maxTokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);

    function grantRoleForApp(
        string memory app,
        bytes32 role,
        address account
    ) external;

    function hasAppRole(
        string memory app,
        bytes32 role,
        address account
    ) external view returns (bool);

    function revokeRoleFromApp(
        string memory app,
        bytes32 role,
        address account
    ) external;

    function getAppRoleMemberCount(
        string memory app,
        bytes32 role
    ) external view  returns (uint256);

    function getAppRoleMember(
        string memory app,
        bytes32 role,
        uint256 index
    ) external view  returns (address);

    function grantRole(
        string memory role,
        address account
    ) external;

    function annulRole(
        string memory role,
        address account
    ) external;

    function possessRole(
        string memory role,
        address account
    ) external view returns (bool);

    function setTokenCertificate(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI
    ) external;

    function getTokenCertificate(
        string calldata app,
        uint256 tokenId
    ) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @liveart/contracts/Roles.sol


pragma solidity ^0.8.0;

library Roles {
    bytes32 constant ROLE_OWNER = keccak256(bytes("ROLE_OWNER"));
    bytes32 constant ROLE_CREATOR = keccak256(bytes("ROLE_CREATOR"));

    bytes32 constant ROLE_MINTER = keccak256(bytes("ROLE_MINTER"));
    bytes32 constant ROLE_PAUSER = keccak256(bytes("ROLE_PAUSER"));
    bytes32 constant ROLE_ADMIN = keccak256(bytes(ROLE_ADMIN_STR));

    string constant ROLE_ADMIN_STR = "ROLE_ADMIN";
}

// File: @liveart/contracts/IAccessControlEnumerableMultitenant.sol


pragma solidity ^0.8.0;

interface IAccessControlEnumerableMultitenant {
    /**
         * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        string memory app,
        string memory role,
        address account
    ) external view returns (bool);

    function grantRole(
        string memory app,
        string memory role,
        address account
    ) external;

    function revokeRole(
        string memory app,
        string memory role,
        address account
    ) external;

    function getRoleMember(
        string memory app,
        string memory role,
        uint256 index
    ) external view returns (address);

    function getRoleMemberCount(
        string memory app,
        string memory role
    ) external view returns (uint256);
}

// File: @liveart/contracts/AccessControlEnumerableMultitenant.sol


pragma solidity ^0.8.0;





abstract contract AccessControlEnumerableMultitenant is
    ContextUpgradeable, IAccessControlEnumerableMultitenant {

    mapping(
        bytes32 => string
    ) private _roles;

    function __AccessControlEnumerableMultitenant_init() internal {
        _roles[Roles.ROLE_MINTER] = "ROLE_MINTER";
        _roles[Roles.ROLE_PAUSER] = "ROLE_PAUSER";
        _roles[Roles.ROLE_ADMIN] = "ROLE_ADMIN";
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(
        string memory app,
        bytes32 role
    ) {
        _checkRole(app, role, _msgSender());
        _;
    }

    function _normaliseRole(
        string memory role
    ) internal pure returns (bytes32) {
        return keccak256(bytes(role));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        string memory app,
        string memory role,
        address account
    ) external view override returns (bool) {
        return _hasRole(app, _normaliseRole(role), account);
    }

    function grantRole(
        string memory app,
        string memory role,
        address account
    ) external override onlyRole(app, Roles.ROLE_ADMIN) {
        _setupRole(app, role, account);
    }

    function _setupRole(
        string memory app,
        string memory role,
        address account
    ) internal {
        bytes32 normalizedRole = _normaliseRole(role);
        _roles[normalizedRole] = role;

        _grantRole(app, normalizedRole, account);
    }

    function revokeRole(
        string memory app,
        string memory role,
        address account
    ) external override onlyRole(app, Roles.ROLE_ADMIN) {
        _revokeRole(app, _normaliseRole(role), account);
    }

    function _grantRole(
        string memory app,
        bytes32 role,
        address account
    ) internal virtual;

    function _revokeRole(
        string memory app,
        bytes32 role,
        address account
    ) internal virtual;

    function _checkRole(
        string memory app,
        bytes32 role,
        address account
    ) internal view {
        require(
            _hasRole(app, role, account),
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        _roles[role]
                    )
                )
        );
    }

    function _hasRole(
        string memory app,
        bytes32 role,
        address account
    ) internal virtual view returns (bool);
}

// File: @liveart/contracts/ERC721/IERC721MultitenantCore.sol


pragma solidity ^0.8.0;

/**
 * @dev Multi tenant version of IERC721 interface.
 */
interface IERC721MultitenantCore  {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(
        string calldata app,
        address owner
    ) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(
        string calldata app,
        uint256 tokenId
    ) external view returns (address owner);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        string calldata app,
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        string calldata app,
        address owner,
        address operator
    ) external view returns (bool);
}

// File: @liveart/contracts/ERC721/IERC721MultitenantEnumerable.sol


pragma solidity ^0.8.0;

/**
 * @dev Multi tenant version of IERC721Enumerable interface.
 */
interface IERC721MultitenantEnumerable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply(
        string calldata app
    ) external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(
        string calldata app,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(
        string calldata app,
        uint256 index
    ) external view returns (uint256);

    /**
    * @dev Returns the total amount of token editions including parent token
    */
    function tokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);
}

// File: @liveart/contracts/ERC721/IERC721MultitenantMetadata.sol


pragma solidity ^0.8.0;

/**
 * @dev Multi tenant version of IERC721Metadata interface.
 */
interface IERC721MultitenantMetadata {
    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        string calldata app,
        uint256 tokenId
    ) external view returns (string memory);
}

// File: @liveart/contracts/ERC721/IERC721MultitenantPausable.sol


pragma solidity ^0.8.0;

interface IERC721MultitenantPausable {
    function paused(
        string calldata app
    ) external view returns (bool);
}

// File: @liveart/contracts/ERC721/IERC721MultitenantMintable.sol


pragma solidity ^0.8.0;


interface IERC721MultitenantMintable {
    event TokenCreated(
        string app,
        uint256 indexed tokenId,
        Mintable.TokenData tokenData
    );
}

// File: @liveart/contracts/ERC721/IERC721MultitenantFull.sol


pragma solidity ^0.8.0;






interface IERC721MultitenantFull is
    IERC721MultitenantCore,
    IERC721MultitenantEnumerable,
    IERC721MultitenantMetadata,
    IERC721MultitenantPausable,
    IERC721MultitenantMintable {

    function registerApp(
        string calldata app,
        address[] memory minters,
        address[] memory pausers,
        address admin
    ) external;

    function getTokenCertificate(
        string calldata app,
        uint256 tokenId
    ) external view returns (string memory);
}

// File: @liveart/contracts/ERC721/IERC721MultitenantExtension.sol


pragma solidity ^0.8.0;



interface IERC721MultitenantExtension is
    IERC721MultitenantFull, IAccessControlEnumerableMultitenant {

    function getStorageAddress() external view returns (address);

    function approveFromExtension(
        string calldata app,
        address to,
        uint256 tokenId,
        address msgSender
    ) external;

    function setApprovalForAllFromExtension(
        string calldata app,
        address operator,
        bool approved,
        address msgSender
    ) external;

    function transferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) external payable;
    function safeTransferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) external payable;
    function safeTransferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender,
        bytes memory _data
    ) external payable;

    function mintFromExtension(
        string calldata app,
        Mintable.TokenData memory tokenData,
        address msgSender
    ) external returns(uint256);

    function burnFromExtension(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) external;

    function pauseFromExtension(
        string calldata app,
        address msgSender
    ) external;

    function unpauseFromExtension(
        string calldata app,
        address msgSender
    ) external;

    function grantRoleFromExtension(
        string memory app,
        string memory role,
        address account,
        address msgSender
    ) external;

    function revokeRoleFromExtension(
        string memory app,
        string memory role,
        address account,
        address msgSender
    ) external;

    function setTokenCertificateFromExtension(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI,
        address msgSender
    ) external;
}

// File: LiveArt/Middleware/ERC721Multitenant.sol


pragma solidity ^0.8.0;



// import "./IERC721MultitenantStorage.sol";
// import "../AccessControlEnumerableMultitenant.sol";
// import "./IERC721MultitenantExtension.sol";
// import "../Mintable.sol";





contract ERC721Multitenant is
    OwnableUpgradeable, IERC721MultitenantExtension,
    AccessControlEnumerableMultitenant {

    using AddressUpgradeable for address;

    IERC721MultitenantStorage internal _erc721MultitenantStorage;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(
        string calldata app
    ) {
        require(
            !_erc721MultitenantStorage.paused(app),
            "Pausable: paused"
        );
        _;
    }

    modifier onlyAdmin() {
        _requireAdminRole(_msgSender());
        _;
    }
    function _requireAdminRole(
        address msgSender
    ) internal view {
        require(
            _erc721MultitenantStorage.possessRole(
                Roles.ROLE_ADMIN_STR,
                _msgSender()
            ),
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(msgSender), 20),
                    " is missing role ",
                    Roles.ROLE_ADMIN_STR
                )
            )
        );
    }

    function _hasRole(
        string memory app,
        bytes32 role,
        address account
    ) internal view override returns (bool) {
        return _erc721MultitenantStorage.hasAppRole(
            app,
            role,
            account
        );
    }

    function _revokeRole(
        string memory app,
        bytes32 role,
        address account
    ) internal override {
        _erc721MultitenantStorage.revokeRoleFromApp(
            app,
            role,
            account
        );
    }

    function _grantRole(
        string memory app,
        bytes32 role,
        address account
    ) internal override {
        _erc721MultitenantStorage.grantRoleForApp(
            app,
            role,
            account
        );
    }

    function grantRoleFromExtension(
        string memory app,
        string memory role,
        address account,
        address msgSender
    ) external override onlyAdmin {
        _checkRole(app, Roles.ROLE_ADMIN, msgSender);
        _setupRole(app, role, account);
    }

    function revokeRoleFromExtension(
        string memory app,
        string memory role,
        address account,
        address msgSender
    ) external override onlyAdmin {
        _checkRole(app, Roles.ROLE_ADMIN, msgSender);
        _revokeRole(app, _normaliseRole(role), account);
    }

    function getRoleMemberCount(
        string memory app,
        string memory role
    ) external view override returns (uint256) {
        return _erc721MultitenantStorage.getAppRoleMemberCount(
            app,
            _normaliseRole(role)
        );
    }

    function getRoleMember(
        string memory app,
        string memory role,
        uint256 index
    ) external view override returns (address) {
        bytes32 normalisedRole = _normaliseRole(role);

        require(
            index < _erc721MultitenantStorage.getAppRoleMemberCount(
                app,
                normalisedRole
            ),
            "index out of bounds"
        );
        return _erc721MultitenantStorage.getAppRoleMember(
            app,
            normalisedRole,
            index
        );
    }

    function initialize(
        IERC721MultitenantStorage erc721MultitenantStorage
    ) external initializer {
        __Ownable_init();
        __AccessControlEnumerableMultitenant_init();

        updateExtendingAddress(erc721MultitenantStorage);
    }

    function updateExtendingAddress(
        IERC721MultitenantStorage erc721MultitenantStorage
    ) public onlyOwner {
        _erc721MultitenantStorage = erc721MultitenantStorage;
    }

    function getStorageAddress(

    ) external view override onlyAdmin returns (address) {
        return address(_erc721MultitenantStorage);
    }

    function registerApp(
        string calldata app,
        address[] memory minters,
        address[] memory pausers,
        address admin
    ) external override onlyAdmin {
        require(
            _erc721MultitenantStorage.getAppRoleMemberCount(
                app,
                Roles.ROLE_ADMIN
            ) == 0,
            "app is already registered"
        );

        _erc721MultitenantStorage.grantRoleForApp(
            app,
            Roles.ROLE_ADMIN,
            owner()
        );
        _erc721MultitenantStorage.grantRoleForApp(
            app,
            Roles.ROLE_MINTER,
            owner()
        );
        _erc721MultitenantStorage.grantRoleForApp(
            app,
            Roles.ROLE_PAUSER,
            owner()
        );
        _erc721MultitenantStorage.registerApp(
            app,
            minters,
            pausers,
            admin
        );
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        string calldata app,
        address owner
    ) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _erc721MultitenantStorage.balanceOf(
            app,
            owner
        );
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        string calldata app,
        uint256 tokenId
    ) public view override returns (address) {
        address owner = _erc721MultitenantStorage.ownerOf(
            app,
            tokenId
        );
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See { IERC721Metadata-tokenURI }.
     */
    function tokenURI(
        string calldata app,
        uint256 tokenId
    ) external view override returns (string memory) {
        require(
            _exists(app,tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _erc721MultitenantStorage.tokenURI(
            app,
            tokenId
        );
    }

    function approveFromExtension(
        string calldata app,
        address to,
        uint256 tokenId,
        address msgSender
    ) external override onlyAdmin {
        _approve(app, to, tokenId, msgSender);
    }

    function _approve(
        string calldata app,
        address to,
        uint256 tokenId,
        address msgSender
    ) internal {
        address owner = _erc721MultitenantStorage.ownerOf(app, tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msgSender == owner || _erc721MultitenantStorage.isApprovedForAll(
            app,
            owner,
            msgSender
        ),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _erc721MultitenantStorage.approve(
            app,
            to,
            tokenId
        );
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        string calldata app,
        uint256 tokenId
    ) external view override returns (address) {
        require(
            _exists(app, tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _erc721MultitenantStorage.getApproved(
            app,
            tokenId
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(
        string calldata app,
        uint256 tokenId
    ) internal view returns (bool) {
        return _erc721MultitenantStorage.ownerOf(
            app,
            tokenId
        ) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        string calldata app,
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        require(
            _exists(
                app,
                tokenId
            ),
            "ERC721: operator query for nonexistent token"
        );
        address owner = _erc721MultitenantStorage.ownerOf(
            app,
            tokenId
        );
        return (
            spender == owner ||
            _erc721MultitenantStorage.getApproved(
                app,
                tokenId
            ) == spender ||
            _erc721MultitenantStorage.isApprovedForAll(
                app,
                owner,
                spender
            )
        );
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        string calldata app,
        address owner,
        address operator
    ) external view override returns (bool) {
        return _erc721MultitenantStorage.isApprovedForAll(
            app,
            owner,
            operator
        );
    }

    function setApprovalForAllFromExtension(
        string calldata app,
        address operator,
        bool approved,
        address msgSender
    ) external override onlyAdmin {
        _setApprovalForAll(app, operator, approved, msgSender);
    }

    function _setApprovalForAll(
        string calldata app,
        address operator,
        bool approved,
        address msgSender
    ) internal {
        require(operator != msgSender, "ERC721: approve to caller");

        _erc721MultitenantStorage.setApprovalForAll(
            app,
            msgSender,
            operator,
            approved
        );
    }

    function transferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) external payable override onlyAdmin {
        _transfer(
            app,
            from,
            to,
            tokenId,
            msgSender
        );
    }
    function safeTransferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) external payable override onlyAdmin {
        _safeTransfer(
            app,
            from,
            to,
            tokenId,
            msgSender,
            ""
        );
    }
    function safeTransferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender,
        bytes memory _data
    ) external payable override onlyAdmin {
        _safeTransfer(
            app,
            from,
            to,
            tokenId,
            msgSender,
            _data
        );
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender,
        bytes memory _data
    ) internal {
        _transfer(app, from, to, tokenId, msgSender);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) internal whenNotPaused(app) {
        require(
            _exists(app, tokenId),
            "token does not exist"
        );
        require(
            from == _erc721MultitenantStorage.ownerOf(app, tokenId),
            "ERC721: from is not current owner"
        );
        require(
            _isApprovedOrOwner(app, msgSender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(
            to != address(0),
            "ERC721: transfer to the zero address"
        );

        _erc721MultitenantStorage.transferFrom(
            app,
            from,
            to,
            tokenId
        );
    }

    function mintFromExtension(
        string calldata app,
        Mintable.TokenData memory tokenData,
        address msgSender
    ) external override onlyAdmin returns (uint256) {
        _checkRole(
            app,
            Roles.ROLE_MINTER,
            msgSender
        );

        return _mint(app, tokenData);
    }

    function _mint(
        string calldata app,
        Mintable.TokenData memory tokenData
    ) internal returns (uint256) {
        require(tokenData.to != address(0), "ERC721: mint to the zero address");

        require(
            tokenData.maxTokenSupply > 0,
            "max token supply should be >= 1"
        );
        if (tokenData.editionOf > 0) {
            require(
                tokenData.maxTokenSupply == 1,
                "invalid token supply for edition"
            );
            require(
                _exists(app, tokenData.editionOf),
                "original token does not exist"
            );
            require(
                _erc721MultitenantStorage.tokenSupply(
                    app,
                    tokenData.editionOf
                ) < _erc721MultitenantStorage.maxTokenSupply(
                app,
                tokenData.editionOf
            ),
                "editions limit reached"
            );
        }

        uint256 tokenId = _erc721MultitenantStorage.mint(
            app,
            tokenData
        );

        require(
            _checkOnERC721Received(address(0), tokenData.to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        emit TokenCreated(
            app,
            tokenId,
            tokenData
        );

        return tokenId;
    }

    function burnFromExtension(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) external override onlyAdmin {
        _burn(app, tokenId, msgSender);
    }

    function _burn(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) internal {
        require(
            _isApprovedOrOwner(
                app,
                msgSender,
                tokenId
            ),
            "ERC721Burnable: caller is not owner nor approved"
        );

        _erc721MultitenantStorage.burn(
            app,
            tokenId
        );
    }

    function pauseFromExtension(
        string calldata app,
        address msgSender
    ) external override onlyAdmin {
        _checkRole(app, Roles.ROLE_PAUSER, msgSender);
        _pause(app);
    }

    function _pause(
        string calldata app
    ) internal {
        _erc721MultitenantStorage.pause(
            app
        );
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(
        string calldata app
    ) external view override returns (bool) {
        return _erc721MultitenantStorage.paused(app);
    }

    function unpauseFromExtension(
        string calldata app,
        address msgSender
    ) external override onlyAdmin {
        _checkRole(app, Roles.ROLE_PAUSER, msgSender);

        _unpause(app);
    }

    function _unpause(
        string calldata app
    ) internal {
        _erc721MultitenantStorage.unpause(
            app
        );
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply(
        string calldata app
    ) external view override returns (uint256) {
        return _erc721MultitenantStorage.totalSupply(
            app
        );
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(
        string calldata app,
        address owner,
        uint256 index
    ) external view override returns (uint256 tokenId) {
        require(
            owner != address(0),
            "ERC721Enumerable: token query for the zero address"
        );
        require(
            index < _erc721MultitenantStorage.balanceOf(
                app,
                owner
            ),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _erc721MultitenantStorage.tokenOfOwnerByIndex(
            app,
            owner,
            index
        );
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(
        string calldata app,
        uint256 index
    ) external view override returns (uint256) {
        require(
            index < _erc721MultitenantStorage.totalSupply(app),
            "ERC721Enumerable: global index out of bounds"
        );

        return _erc721MultitenantStorage.tokenByIndex(
            app,
            index
        );
    }

    /**
    * @dev Returns the total amount of token editions including parent token
    */
    function tokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view override returns (uint256) {
        require(
            _exists(app, tokenId),
            "token does not exist"
        );

        return _erc721MultitenantStorage.tokenSupply(
            app,
            tokenId
        );
    }

    function setTokenCertificateFromExtension(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI,
        address msgSender
    ) external override onlyAdmin {
        _checkRole(
            app,
            Roles.ROLE_MINTER,
            msgSender
        );

        _setTokenCertificate(app, tokenId, certificateURI);
    }
    function _setTokenCertificate(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI
    ) internal {
        require(
            _exists(app, tokenId),
            "token does not exist"
        );
        require(
            bytes(
                _erc721MultitenantStorage.getTokenCertificate(
                    app,
                    tokenId
                )
            ).length == 0,
            "can't change token certificate"
        );

        _erc721MultitenantStorage.setTokenCertificate(
            app,
            tokenId,
            certificateURI
        );
    }

    function getTokenCertificate(
        string calldata app,
        uint256 tokenId
    ) external override view returns (string memory) {
        return _erc721MultitenantStorage.getTokenCertificate(
            app,
            tokenId
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}