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

// File: @liveart/contracts/ERC721/IMultitenantODRLExtension.sol


pragma solidity ^0.8.0;


interface IMultitenantODRLExtension {
    function registerToken(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory sellableRights,
        ODRL.Policy[] memory otherRights
    ) external;

    function getTokenRights(
        string calldata app,
        uint256 tokenId
    ) external view returns (ODRL.Policy[] memory);

    function onERC721TokenTransfer(
        string calldata app,
        uint256 tokenId,
        address from,
        address to
    ) external;

    function transferTokenRights(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights,
        address from,
        address to
    ) external;

    function hasSellableRights(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights
    ) external view returns (bool);

    function hasTokenRight(
        string calldata app,
        uint256 tokenId,
        address owner,
        string memory action
    ) external view returns (bool);
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

// File: LiveArt/Extension/MultitenantODRLExtension.sol


pragma solidity ^0.8.0;






contract MultitenantODRLExtension is
    IMultitenantODRLExtension, OwnableUpgradeable {

    IERC721MultitenantStorage _erc721MultitenantStorage;

    mapping(
        string => mapping(uint256 => string[])
    ) private _sellableRights;
    mapping(
        string => mapping(uint256 => string[])
    ) private _otherRights;
    mapping(
        string => mapping(
            uint256 => mapping(
                address => mapping(
                    string => ODRL.Policy
                )
            )
        )
    ) private _tokenRightsByOwner;
    mapping(
        string => mapping(
            uint256 => ODRL.Policy[]
        )
    ) private _tokenRights;

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

    function initialize(
        IERC721MultitenantStorage erc721MultitenantStorage
    ) external initializer {
        __Ownable_init();
        setStorageAddress(erc721MultitenantStorage);
    }
    function setStorageAddress(
        IERC721MultitenantStorage erc721MultitenantStorage
    ) public onlyOwner {
        _erc721MultitenantStorage = erc721MultitenantStorage;
    }

    function registerToken(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory sellableRights,
        ODRL.Policy[] memory otherRights
    ) external override onlyAdmin {
        _saveTokenRights(
            app,
            tokenId,
            sellableRights,
            otherRights
        );
    }

    function _saveTokenRights(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory sellableRights,
        ODRL.Policy[] memory otherRights
    ) internal {
        mapping(
            address => mapping(
                string => ODRL.Policy
            )
        ) storage tokenRightsByOwner =
            _tokenRightsByOwner[app][tokenId];
        ODRL.Policy[] storage tokenRights =
            _tokenRights[app][tokenId];

        string memory action;
        for (uint256 i = 0; i < sellableRights.length; i++) {
            sellableRights[i].target = tokenId;

            action = sellableRights[i].action;
            _sellableRights[app][tokenId].push(action);
            tokenRightsByOwner[
                sellableRights[i].permission.wallet
            ][action] = sellableRights[i];
            tokenRights.push(sellableRights[i]);
        }
        for (uint256 i = 0; i < otherRights.length; i++) {
            otherRights[i].target = tokenId;

            action = otherRights[i].action;
            _otherRights[app][tokenId].push(action);
            tokenRightsByOwner[
                otherRights[i].permission.wallet
            ][action] = otherRights[i];
            tokenRights.push(otherRights[i]);
        }
    }

    function getTokenRights(
        string calldata app,
        uint256 tokenId
    ) external override view onlyAdmin returns (
        ODRL.Policy[] memory
    ) {
        ODRL.Policy[] memory tokenRights =
            _tokenRights[app][tokenId];

        return tokenRights;
    }

    function onERC721TokenTransfer(
        string calldata app,
        uint256 tokenId,
        address from,
        address to
    ) external override onlyAdmin {
        string[] memory sellableRights = _sellableRights[app][tokenId];
        mapping(
            address => mapping(
                string => ODRL.Policy
            )
        ) storage tokenRightsByOwner =
            _tokenRightsByOwner[app][tokenId];

        string memory action;
        for (uint256 i = 0; i < sellableRights.length; i++) {
            action = sellableRights[i];
            if (
                tokenRightsByOwner[from][action].target == tokenId
            ) {
                _transferTokenRight(
                    app,
                    tokenId,
                    from,
                    to,
                    action,
                    "ROLE_OWNER"
                );
            }
        }
    }

    function transferTokenRights(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights,
        address from,
        address to
    ) external override onlyAdmin {
        mapping(
            address => mapping(
                string => ODRL.Policy
            )
        ) storage tokenRightsByOwner =
            _tokenRightsByOwner[app][tokenId];

        address wallet;
        string memory action;
        for (uint256 i = 0; i < transferRights.length; i++) {
            wallet = transferRights[i].permission.wallet;
            action = transferRights[i].action;

            require(
                wallet == from,
                "can't transfer not owned right"
            );
            require(
                tokenRightsByOwner[wallet][action].target ==
                    tokenId,
                "right does not exist"
            );

            _transferTokenRight(
                app,
                tokenId,
                from,
                to,
                action,
                transferRights[i].permission.role
            );
        }
    }

    function hasSellableRights(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights
    ) external override view onlyAdmin returns (bool) {
        string[] memory sellableRights =
            _sellableRights[app][tokenId];

        for (uint32 i = 0; i < transferRights.length; i++) {
            for (uint32 j = 0; j < sellableRights.length; j++) {
                if (
                    _compareStrings(
                        sellableRights[j],
                        transferRights[i].action
                    )
                ) {
                    return true;
                }
            }
        }

        return false;
    }

    function hasTokenRight(
        string calldata app,
        uint256 tokenId,
        address owner,
        string memory action
    ) external override view onlyAdmin returns (bool) {
        return _tokenRightsByOwner[app][tokenId][owner][action]
            .target == tokenId;
    }

    function _transferTokenRight(
        string calldata app,
        uint256 tokenId,
        address from,
        address to,
        string memory action,
        string memory role
    ) internal {
        mapping(
            address => mapping(
                string => ODRL.Policy
            )
        ) storage tokenRightsByOwner =
            _tokenRightsByOwner[app][tokenId];
        ODRL.Policy[] storage tokenRights =
            _tokenRights[app][tokenId];

        tokenRightsByOwner[to][action] = tokenRightsByOwner[from][action];
        tokenRightsByOwner[to][action].permission.wallet = to;
        tokenRightsByOwner[to][action].permission.role = role;
        delete tokenRightsByOwner[from][action];

        for (uint256 i = 0; i < tokenRights.length; i++) {
            if (_compareStrings(tokenRights[i].action, action)) {
                if (tokenRights[i].permission.wallet == from) {
                    tokenRights[i] = tokenRightsByOwner[to][action];
                }
            }
        }
    }

    function _compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}