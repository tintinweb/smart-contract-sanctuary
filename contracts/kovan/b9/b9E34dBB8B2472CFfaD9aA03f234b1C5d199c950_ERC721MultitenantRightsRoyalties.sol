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

// File: @liveart/contracts/ERC721/IERC721MultitenantWithTokenRightsAndRoyalties.sol


pragma solidity ^0.8.0;




interface IERC721MultitenantWithTokenRightsAndRoyalties is
    IERC721MultitenantExtension {

    event TokenWithRoyaltiesCreated(
        string app,
        uint256 indexed tokenId,
        Mintable.TokenDataWithRoyalties tokenData
    );

    function mintWithRightsAndRoyaltiesFromExtension(
        string calldata app,
        Mintable.TokenDataWithRoyalties memory tokenData,
        address msgSender
    ) external returns (uint256);
    function mintWithBuyoutFromExtension(
        string calldata app,
        Mintable.TokenDataWithBuyOut memory tokenData,
        address msgSender
    ) external returns (uint256);

    function getBuyOutPrice(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);
    function tokenLocked(
        string calldata app,
        uint256 tokenId
    ) external view returns (bool);
    function buyOutTokenFromExtension(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) external payable;

    /**
    * @dev Returns list of token assigned rights
    */
    function getTokenRights(
        string calldata app,
        uint256 tokenId
    ) external view returns (ODRL.Policy[] memory);

    function transferTokenRightsFromExtension(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights,
        address from,
        address to,
        address msgSender
    ) external payable;

    /**
    * @dev get token royalties config
    */
    function getTokenRoyalties(
        string calldata app,
        uint256 tokenId
    ) external view returns (Royalties.RoyaltyReceiver[] memory);

    // Royalty support for various existing standards
    function getFeeRecipients(
        string calldata app,
        uint256 tokenId
    ) external view returns (address payable[] memory);
    function getFeeBps(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint[] memory);
    function getFees(
        string calldata app,
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(
        string calldata app,
        uint256 tokenId,
        uint256 value
    ) external view returns (address, uint256);
    function getRoyalties(
        string calldata app,
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
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

// File: @liveart/contracts/ERC721/ERC721MultitenantExtensionProxy.sol


pragma solidity ^0.8.0;






abstract contract ERC721MultitenantExtensionProxy is
    IERC721MultitenantExtension, OwnableUpgradeable {

    IERC721MultitenantExtension internal _erc721MultitenantExtension;

    modifier onlyAdmin() {
        _requireAdminRole();
        _;
    }

    function _requireAdminRole() internal view {
        require(
            IERC721MultitenantStorage(
                _erc721MultitenantExtension.getStorageAddress()
            ).possessRole(
                Roles.ROLE_ADMIN_STR,
                _msgSender()
            ),
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(_msgSender()), 20),
                    " is missing role ",
                    Roles.ROLE_ADMIN_STR
                )
            )
        );
    }

    function getStorageAddress(

    ) external view override onlyAdmin returns (address) {
        return _erc721MultitenantExtension.getStorageAddress();
    }

    function __ERC721MultitenantExtensionProxy_init(
        IERC721MultitenantExtension erc721MultitenantExtension
    ) internal initializer {
        __Ownable_init();

        updateExtendingAddress(
            erc721MultitenantExtension
        );
    }

    function updateExtendingAddress(
        IERC721MultitenantExtension erc721MultitenantExtension
    ) public onlyOwner {
        _erc721MultitenantExtension = erc721MultitenantExtension;
    }

    function registerApp(
        string calldata app,
        address[] memory minters,
        address[] memory pausers,
        address admin
    ) external override {
        _erc721MultitenantExtension.registerApp(
            app,
            minters,
            pausers,
            admin
        );
    }

    function balanceOf(
        string calldata app,
        address owner
    ) public view override returns (uint256) {
        return _erc721MultitenantExtension.balanceOf(app, owner);
    }

    function ownerOf(
        string calldata app,
        uint256 tokenId
    ) public view override returns (address) {
        return _erc721MultitenantExtension.ownerOf(app, tokenId);
    }

    function tokenURI(
        string calldata app,
        uint256 tokenId
    ) external view override returns (string memory) {
        return _erc721MultitenantExtension.tokenURI(app, tokenId);
    }

    function approveFromExtension(
        string calldata app,
        address to,
        uint256 tokenId,
        address msgSender
    ) external override onlyAdmin {
        return _erc721MultitenantExtension.approveFromExtension(
            app,
            to,
            tokenId,
            msgSender
        );
    }

    function getApproved(
        string calldata app,
        uint256 tokenId
    ) external view override returns (address) {
        return _erc721MultitenantExtension.getApproved(app, tokenId);
    }

    function isApprovedForAll(
        string calldata app,
        address owner,
        address operator
    ) external view override returns (bool) {
        return _erc721MultitenantExtension.isApprovedForAll(
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
        _erc721MultitenantExtension.setApprovalForAllFromExtension(
            app,
            operator,
            approved,
            msgSender
        );
    }

    function transferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) public payable virtual override onlyAdmin {
        _erc721MultitenantExtension.transferFromExtension(
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
    ) public payable virtual override onlyAdmin {
        _erc721MultitenantExtension.safeTransferFromExtension(
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
        address msgSender,
        bytes memory _data
    ) public payable virtual override onlyAdmin {
        _erc721MultitenantExtension.safeTransferFromExtension(
            app,
            from,
            to,
            tokenId,
            msgSender,
            _data
        );
    }

    function mintFromExtension(
        string calldata app,
        Mintable.TokenData memory tokenData,
        address msgSender
    ) public override onlyAdmin returns (uint256) {
        return _erc721MultitenantExtension.mintFromExtension(
            app,
            tokenData,
            msgSender
        );
    }

    function burnFromExtension(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) external override onlyAdmin {
        _erc721MultitenantExtension.burnFromExtension(
            app,
            tokenId,
            msgSender
        );
    }

    function pauseFromExtension(
        string calldata app,
        address msgSender
    ) external override onlyAdmin {
        _erc721MultitenantExtension.pauseFromExtension(
            app,
            msgSender
        );
    }

    function paused(
        string calldata app
    ) external view override returns (bool) {
        return _erc721MultitenantExtension.paused(app);
    }

    function unpauseFromExtension(
        string calldata app,
        address msgSender
    ) external override onlyAdmin {
        _erc721MultitenantExtension.unpauseFromExtension(
            app,
            msgSender
        );
    }

    function totalSupply(
        string calldata app
    ) external view override returns (uint256) {
        return _erc721MultitenantExtension.totalSupply(app);
    }

    function tokenOfOwnerByIndex(
        string calldata app,
        address owner,
        uint256 index
    ) external view override returns (uint256 tokenId) {
        return _erc721MultitenantExtension.tokenOfOwnerByIndex(app, owner, index);
    }

    function tokenByIndex(
        string calldata app,
        uint256 index
    ) external view override returns (uint256) {
        return _erc721MultitenantExtension.tokenByIndex(app, index);
    }

    function tokenSupply(
        string calldata app,
        uint256 tokenId
    ) external view override returns (uint256) {
        return _erc721MultitenantExtension.tokenSupply(app, tokenId);
    }

    function _exists(
        string calldata app,
        uint256 tokenId
    ) internal view returns (bool) {
        return IERC721MultitenantStorage(
            _erc721MultitenantExtension.getStorageAddress()
        ).ownerOf(
            app,
            tokenId
        ) != address(0);
    }

    function hasRole(
        string memory app,
        string memory role,
        address account
    ) external view override returns (bool) {
        return _erc721MultitenantExtension.hasRole(
            app,
            role,
            account
        );
    }

    function grantRole(
        string memory app,
        string memory role,
        address account
    ) external override {
        _erc721MultitenantExtension.grantRoleFromExtension(
            app,
            role,
            account,
            _msgSender()
        );
    }

    function grantRoleFromExtension(
        string memory app,
        string memory role,
        address account,
        address msgSender
    ) external override onlyAdmin {
        _erc721MultitenantExtension.grantRoleFromExtension(
            app,
            role,
            account,
            msgSender
        );
    }

    function revokeRole(
        string memory app,
        string memory role,
        address account
    ) external override {
        _erc721MultitenantExtension.revokeRoleFromExtension(
            app,
            role,
            account,
            _msgSender()
        );
    }

    function revokeRoleFromExtension(
        string memory app,
        string memory role,
        address account,
        address msgSender
    ) external override onlyAdmin {
        _erc721MultitenantExtension.revokeRoleFromExtension(
            app,
            role,
            account,
            msgSender
        );
    }

    function getRoleMember(
        string memory app,
        string memory role,
        uint256 index
    ) external view override returns (address) {
        return _erc721MultitenantExtension.getRoleMember(
            app,
            role,
            index
        );
    }

    function getRoleMemberCount(
        string memory app,
        string memory role
    ) external view override returns (uint256) {
        return _erc721MultitenantExtension.getRoleMemberCount(app, role);
    }

    function setTokenCertificateFromExtension(
        string calldata app,
        uint256 tokenId,
        string memory certificateURI,
        address msgSender
    ) external override onlyAdmin {
        _erc721MultitenantExtension.setTokenCertificateFromExtension(
            app,
            tokenId,
            certificateURI,
            msgSender
        );
    }

    function getTokenCertificate(
        string calldata app,
        uint256 tokenId
    ) external override view returns (string memory) {
        return _erc721MultitenantExtension.getTokenCertificate(
            app,
            tokenId
        );
    }
}

// File: @liveart/contracts/ERC721/IMultitenantRoyaltiesExtension.sol


pragma solidity ^0.8.0;


interface IMultitenantRoyaltiesExtension {
    function registerToken(
        string calldata app,
        uint256 tokenId,
        Royalties.RoyaltyReceiver[] memory royaltyReceivers
    ) external;
    function registerToken(
        string calldata app,
        uint256 tokenId,
        Royalties.RoyaltyReceiver[] memory royaltyReceivers,
        uint256 buyOutPrice,
        Royalties.BuyOutReceiver[] memory buyOutReceivers
    ) external;

    function afterTokenTransfer(
        string calldata app,
        uint256 tokenId
    ) external;

    function buyOutToken(
        string calldata app,
        uint256 tokenId
    ) external payable;
    function getBuyOutPrice(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint256);

    function payForRightsTransfer(
        string calldata app,
        uint256 tokenId,
        address payable from
    ) external payable;

    function getTokenRoyalties(
        string calldata app,
        uint256 tokenId
    ) external view returns (Royalties.RoyaltyReceiver[] memory);

    function getRoyalties(
        string calldata app,
        uint256 tokenId
    ) external view returns (
        address payable[] memory,
        uint256[] memory
    );

    function royaltyInfo(
        string calldata app,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function getFees(
        string calldata app,
        uint256 tokenId
    ) external view returns (
        address payable[] memory,
        uint256[] memory
    );

    function getFeeBps(
        string calldata app,
        uint256 tokenId
    ) external view returns (uint[] memory);

    function getFeeRecipients(
        string calldata app,
        uint256 tokenId
    ) external view returns (address payable[] memory);
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

// File: LiveArt/Middleware/ERC721MultitenantRightsRoyalties.sol


pragma solidity ^0.8.0;






contract ERC721MultitenantRightsRoyalties is
    IERC721MultitenantWithTokenRightsAndRoyalties,
    ERC721MultitenantExtensionProxy {

    IMultitenantRoyaltiesExtension private
        _multitenantRoyaltiesExtension;
    IMultitenantODRLExtension private
        _multitenantODRLExtension;

    mapping(
        string => mapping(uint256 => bool)
    ) private _locked;

    function initialize(
        IERC721MultitenantExtension erc721MultitenantExtension,
        IMultitenantRoyaltiesExtension erc721MultitenantPaymentSplitter,
        IMultitenantODRLExtension multitenantODRLExtension
    ) external initializer {
        __ERC721MultitenantExtensionProxy_init(erc721MultitenantExtension);
        updateRoyaltiesExtension(erc721MultitenantPaymentSplitter);
        updateODRLExtension(multitenantODRLExtension);
    }
    function updateRoyaltiesExtension(
        IMultitenantRoyaltiesExtension erc721MultitenantPaymentSplitter
    ) public onlyOwner {
        _multitenantRoyaltiesExtension = erc721MultitenantPaymentSplitter;
    }
    function updateODRLExtension(
        IMultitenantODRLExtension multitenantODRLExtension
    ) public onlyOwner {
        _multitenantODRLExtension = multitenantODRLExtension;
    }

    function mintWithRightsAndRoyaltiesFromExtension(
        string calldata app,
        Mintable.TokenDataWithRoyalties memory tokenData,
        address msgSender
    ) external override onlyAdmin returns (uint256) {
        uint256 tokenId = super.mintFromExtension(
            app,
            Mintable.TokenData(
                tokenData.tokenMetadataURI,
                tokenData.editionOf,
                tokenData.maxTokenSupply,
                tokenData.to
            ),
            msgSender
        );

        _multitenantRoyaltiesExtension.registerToken(
            app,
            tokenId,
            tokenData.royaltyReceivers
        );
        _afterTokenMinted(
            app,
            tokenId,
            tokenData
        );

        return tokenId;
    }

    function mintWithBuyoutFromExtension(
        string calldata app,
        Mintable.TokenDataWithBuyOut memory tokenData,
        address msgSender
    ) external override onlyAdmin returns (uint256) {
        uint256 tokenId = super.mintFromExtension(
            app,
            Mintable.TokenData(
                tokenData.tokenMetadataURI,
                tokenData.editionOf,
                tokenData.maxTokenSupply,
                tokenData.to
            ),
            msgSender
        );

        _multitenantRoyaltiesExtension.registerToken(
            app,
            tokenId,
            tokenData.royaltyReceivers,
            tokenData.buyOutPrice,
            tokenData.buyOutReceivers
        );
        _lockToken(
            app,
            tokenId
        );
        _afterTokenMinted(
            app,
            tokenId,
            Mintable.TokenDataWithRoyalties(
                tokenData.tokenMetadataURI,
                tokenData.editionOf,
                tokenData.maxTokenSupply,
                tokenData.to,
                tokenData.royaltyReceivers,
                tokenData.sellableRights,
                tokenData.otherRights
            )
        );

        return tokenId;
    }

    function getBuyOutPrice(
        string calldata app,
        uint256 tokenId
    ) external override view returns (uint256) {
        return _multitenantRoyaltiesExtension.getBuyOutPrice(
            app,
            tokenId
        );
    }
    function buyOutTokenFromExtension(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) external payable override onlyAdmin {
        _buyOutToken(app, tokenId, msgSender);
    }
    function _buyOutToken(
        string calldata app,
        uint256 tokenId,
        address msgSender
    ) internal {
        require(_exists(app, tokenId), "non existent token");
        require(
            _multitenantODRLExtension.hasTokenRight(
                app,
                tokenId,
                msgSender,
                ODRL.ACTION_BUY_OUT
            ),
            "buy out token right is required"
        );

        _multitenantRoyaltiesExtension.buyOutToken{
        value: msg.value
        } (
            app,
            tokenId
        );

        _unlockToken(
            app,
            tokenId
        );
    }

    function _lockToken(
        string calldata app,
        uint256 tokenId
    ) internal {
        _locked[app][tokenId] = true;
    }
    function _unlockToken(
        string calldata app,
        uint256 tokenId
    ) internal {
        _locked[app][tokenId] = false;
    }
    function _tokenLocked(
        string calldata app,
        uint256 tokenId
    ) internal view returns (bool) {
        return _locked[app][tokenId] == true;
    }

    function tokenLocked(
        string calldata app,
        uint256 tokenId
    ) external override onlyAdmin view returns (bool) {
        return _tokenLocked(app, tokenId);
    }

    function _afterTokenMinted(
        string calldata app,
        uint256 tokenId,
        Mintable.TokenDataWithRoyalties memory tokenData
    ) internal {
        _multitenantODRLExtension.registerToken(
            app,
            tokenId,
            tokenData.sellableRights,
            tokenData.otherRights
        );

        for (uint256 i = 0; i < tokenData.sellableRights.length; i++) {
            tokenData.sellableRights[i].target = tokenId;
        }
        for (uint256 i = 0; i < tokenData.otherRights.length; i++) {
            tokenData.otherRights[i].target = tokenId;
        }
        emit TokenWithRoyaltiesCreated(
            app,
            tokenId,
            tokenData
        );
    }

    function transferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) public virtual override(
        ERC721MultitenantExtensionProxy, IERC721MultitenantExtension
    ) payable {
        _requireTokenPayment(app, tokenId);
        _payForRightsTransfer(app, tokenId, from);

        super.transferFromExtension(
            app,
            from,
            to,
            tokenId,
            msgSender
        );

        _multitenantODRLExtension.onERC721TokenTransfer(
            app,
            tokenId,
            from,
            to
        );

        _multitenantRoyaltiesExtension.afterTokenTransfer(app, tokenId);
    }
    function safeTransferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender
    ) public virtual override(
        ERC721MultitenantExtensionProxy, IERC721MultitenantExtension
    ) payable {
        _requireTokenPayment(app, tokenId);
        _payForRightsTransfer(app, tokenId, from);

        super.safeTransferFromExtension(
            app,
            from,
            to,
            tokenId,
            msgSender
        );

        _multitenantODRLExtension.onERC721TokenTransfer(
            app,
            tokenId,
            from,
            to
        );

        _multitenantRoyaltiesExtension.afterTokenTransfer(app, tokenId);
    }
    function safeTransferFromExtension(
        string calldata app,
        address from,
        address to,
        uint256 tokenId,
        address msgSender,
        bytes memory _data
    ) public virtual override(
        ERC721MultitenantExtensionProxy, IERC721MultitenantExtension
    ) payable {
        _requireTokenPayment(app, tokenId);
        _payForRightsTransfer(app, tokenId, from);

        super.safeTransferFromExtension(
            app,
            from,
            to,
            tokenId,
            msgSender,
            _data
        );

        _multitenantODRLExtension.onERC721TokenTransfer(
            app,
            tokenId,
            from,
            to
        );

        _multitenantRoyaltiesExtension.afterTokenTransfer(app, tokenId);
    }

    function transferTokenRightsFromExtension(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights,
        address from,
        address to,
        address msgSender
    ) external onlyAdmin override payable {
        if (
            _multitenantODRLExtension.hasSellableRights(
                app,
                tokenId,
                transferRights
            )
        ) {
            _requireTokenPayment(app, tokenId);
        }
        _payForRightsTransfer(app, tokenId, from);

        _transferTokenRights(
            app,
            tokenId,
            transferRights,
            from,
            to,
            msgSender
        );
    }

    function _requireTokenPayment(
        string calldata app,
        uint256 tokenId
    ) internal {
        if (_tokenLocked(app, tokenId)) {
            require(
                msg.value > 0,
                "transfer should be paid"
            );
        }
    }
    function _payForRightsTransfer(
        string calldata app,
        uint256 tokenId,
        address from
    ) internal {
        if (msg.value > 0) {
            _multitenantRoyaltiesExtension.payForRightsTransfer{
                value: msg.value
            } (
                app,
                tokenId,
                payable(from)
            );
        }
    }

    function getTokenRights(
        string calldata app,
        uint256 tokenId
    ) external view override returns (ODRL.Policy[] memory) {
        require(_exists(app, tokenId), "Nonexistent token");

        return _multitenantODRLExtension.getTokenRights(app, tokenId);
    }

    function _transferTokenRights(
        string calldata app,
        uint256 tokenId,
        ODRL.Policy[] memory transferRights,
        address from,
        address to,
        address msgSender
    ) internal {
        require(_exists(app, tokenId), "Nonexistent token");

        require(
            msgSender == from ||
            _erc721MultitenantExtension.isApprovedForAll(
                app,
                from,
                msgSender
            ) ||
            _erc721MultitenantExtension.getApproved(
                app,
                tokenId
            ) == msgSender,
            "only owner or operator can transfer rights"
        );
        require(
            from != to,
            "can't transfer to self"
        );

        _multitenantODRLExtension.transferTokenRights(
            app,
            tokenId,
            transferRights,
            from,
            to
        );

        if (
            _multitenantODRLExtension.hasSellableRights(
                app,
                tokenId,
                transferRights
            )
        ) {
            _multitenantRoyaltiesExtension.afterTokenTransfer(app, tokenId);
        }
    }

    function getTokenRoyalties(
        string calldata app,
        uint256 tokenId
    ) external view override returns (Royalties.RoyaltyReceiver[] memory) {
        require(_exists(app, tokenId), "Nonexistent token");

        return _multitenantRoyaltiesExtension.getTokenRoyalties(
            app,
            tokenId
        );
    }

    function getRoyalties(
        string calldata app,
        uint256 tokenId
    ) public view override returns (
        address payable[] memory,
        uint256[] memory
    ) {
        require(_exists(app, tokenId), "Nonexistent token");

        return _multitenantRoyaltiesExtension.getRoyalties(
            app,
            tokenId
        );
    }

    function royaltyInfo(
        string calldata app,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        require(_exists(app, tokenId), "Nonexistent token");

        (address _receiver, uint256 _royaltyAmount) =
            _multitenantRoyaltiesExtension.royaltyInfo(
                app,
                tokenId,
                salePrice
            );

        if (_royaltyAmount == 0) {
            return (address(this), _royaltyAmount);
        }
        return (_receiver, _royaltyAmount);
    }

    function getFees(
        string calldata app,
        uint256 tokenId
    ) external view override returns (
        address payable[] memory,
        uint256[] memory
    ) {
        require(_exists(app, tokenId), "Nonexistent token");

        return _multitenantRoyaltiesExtension.getFees(
            app,
            tokenId
        );
    }

    function getFeeBps(
        string calldata app,
        uint256 tokenId
    ) external view override returns (uint[] memory) {
        require(_exists(app, tokenId), "Nonexistent token");

        return _multitenantRoyaltiesExtension.getFeeBps(
            app,
            tokenId
        );
    }

    function getFeeRecipients(
        string calldata app,
        uint256 tokenId
    ) external view override returns (address payable[] memory) {
        require(_exists(app, tokenId), "Nonexistent token");

        return _multitenantRoyaltiesExtension.getFeeRecipients(
            app,
            tokenId
        );
    }
}