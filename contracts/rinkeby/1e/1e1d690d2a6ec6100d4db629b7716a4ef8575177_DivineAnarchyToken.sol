/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IDivineAnarchyToken is IERC721, IERC721Metadata {

    // Interface getters.
    function getTokenClass(uint256 _id) external view returns(uint256);

    function getTokenClassSupplyCap(uint256 _classId) external view returns(uint256);

    function getTokenClassCurrentSupply(uint256 _classId) external view returns(uint256);

    function getTokenClassVotingPower(uint256 _classId) external view returns(uint256);

    function getTokensMintedAtPresale(address account) external view returns(uint256);

    function isTokenClass(uint256 _id) external pure returns(bool);

    function isTokenClassMintable(uint256 _id) external pure returns(bool);

    function isAscensionApple(uint256 _id) external pure returns(bool);

    function isBadApple(uint256 _id) external pure returns(bool);

    function consumedAscensionApples(address account) external view returns(uint256);

    function airdropApples(uint256 amount, uint256 appleClass, address[] memory accounts) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    constructor() {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
    constructor() {
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
}

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

interface IOracle {

    function getRandomNumbers(uint256 _number) external returns(uint256[][] memory);

    function wait() external pure returns(bool);
}

interface IAdminWallets {

    function getOwnerWallet() external pure returns(address);

    function getDiversityWallet() external pure returns(address);

    function getAssetBenderWallet() external pure returns(address);

    function getMarketingWallet() external pure returns(address);

    function getDivineTreasuryWallet() external pure returns(address);

    function isInEmperorList(address account) external view returns(bool);

    function isPresaleActive() external view returns(bool);

    function getCurrentPresaleRound() external view returns(uint256);

    function isAllowedAtPresale(uint256 round, address account) external view returns(bool);
}
contract DivineAnarchyToken is IDivineAnarchyToken, ERC165, Ownable, Pausable, ReentrancyGuard {

    using Address for address;
    using Strings for string;

    // Contract variables.
    IAdminWallets public adminWallets;
    IOracle public oracle;

    string private _baseURI;
    string private _name;
    string private _symbol;

    uint256 public constant THE_UNKNOWN = 0;
    uint256 public constant KING = 1;
    uint256 public constant ADAM_EVE = 2;
    uint256 public constant HUMAN_HERO = 3;
    uint256 public constant HUMAN_NEMESIS = 4; 
    uint256 public constant ASCENSION_APPLE = 5;
    uint256 public constant BAD_APPLE = 6;

    mapping(uint256 => uint256) private _tokenClass;
    mapping(uint256 => uint256) private _tokenClassSupplyCap;
    mapping(uint256 => uint256) private _tokenClassSupplyCurrent;
    mapping(uint256 => uint256) private _tokenClassVotingPower;

    uint256 private _mintedToTreasury;
    uint256 private constant MAX_MINTED_TO_TREASURY = 10; // TODO to replace by 244
    bool private _mintedToTreasuryHasFinished = false;

    uint256 private constant MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE = 3;
    mapping(address => uint256) private _tokensMintedByAddressAtPresale;

    uint256 private constant MAX_TOKENS_MINTED_BY_ADDRESS = 4;
    mapping(address => uint256) private _tokensMintedByAddress;

    uint256 private _initAscensionApple = 16011;
    uint256 private _initBadApple = 19011;
    mapping(address => uint256) private _consumedAscensionApples;

    uint256 private constant TOKEN_UNIT_PRICE = 0.09 ether;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;
    
    
    // Contract constructor
    constructor (string memory name_, string memory symbol_, string memory baseURI_, address _adminwallets, address _oracle) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;

        adminWallets = IAdminWallets(_adminwallets);
        oracle = IOracle(_oracle);

        _tokenClassSupplyCap[THE_UNKNOWN] = 1;
        _tokenClassSupplyCap[KING] = 8;
        _tokenClassSupplyCap[ADAM_EVE] = 2;
        _tokenClassSupplyCap[HUMAN_HERO] = 5000;
        _tokenClassSupplyCap[HUMAN_NEMESIS] = 5000; 
        _tokenClassSupplyCap[ASCENSION_APPLE] = 3000;
        _tokenClassSupplyCap[BAD_APPLE] = 1500;

        _tokenClassVotingPower[KING] = 2000;
        _tokenClassVotingPower[ADAM_EVE] = 1000;
        _tokenClassVotingPower[HUMAN_HERO] = 1;
        _tokenClassVotingPower[HUMAN_NEMESIS] = 1;

        // Minting the Unknown for Treasury wallet.
        //address divineTreasuryWallet = adminWallets.getDivineTreasuryWallet();
        
        _beforeTokenTransfer(address(0), adminWallets.getDivineTreasuryWallet(), 0);
        _balances[adminWallets.getDivineTreasuryWallet()] += 1;
        _owners[0] = adminWallets.getDivineTreasuryWallet();
        _tokenClass[0] = THE_UNKNOWN;
        _tokenClassSupplyCurrent[THE_UNKNOWN] = 1;
        
        _beforeTokenTransfer(address(0), adminWallets.getDiversityWallet(), 1);
        _beforeTokenTransfer(address(0), adminWallets.getAssetBenderWallet(), 2);
        _beforeTokenTransfer(address(0), adminWallets.getMarketingWallet(), 3);

        // Minting three kings for Diversity, AssetBender and Marketing.
        _balances[adminWallets.getDiversityWallet()] += 1;
        _balances[adminWallets.getAssetBenderWallet()] += 1;
        _balances[adminWallets.getMarketingWallet()] += 1;

        _owners[1] = adminWallets.getDiversityWallet();
        _owners[2] = adminWallets.getAssetBenderWallet();
        _owners[3] = adminWallets.getMarketingWallet();
        _owners[4] = adminWallets.getMarketingWallet();

        for(uint256 i = 1; i <= 5; i++) {
            _tokenClass[i] = KING;
        }
 
        _tokenClassSupplyCurrent[KING] = 3;
    }


    // Contract functions.
    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function getAdminWalletsAddress() public view returns(address) {
        return address(adminWallets);
    }

    function getOracleAddress() public view returns(address) {
        return address(oracle);
    }

    function getTokenClass(uint256 _id) external view override returns(uint256) {
        return _tokenClass[_id];
    }

    function setTokenClass(uint _id) external pure returns(uint256) {
        // This can be erased if not necessary.
        if (_id == 0) {
            return THE_UNKNOWN;
        } else if (_id >= 1 && _id <= 8) {
            return KING;
        } else if (_id == 9 && _id == 10) {
            return ADAM_EVE;
        } else if (_id >= 11 && _id <= 8010) {
            return HUMAN_HERO;
        } else if (_id >= 8011 && _id <= 16010) {
            return HUMAN_NEMESIS;
        } else if (_id >= 16011 && _id <= 19010) {
            return ASCENSION_APPLE;
        } else if (_id >= 19011 && _id <= 20510) {
            return BAD_APPLE;
        } else {
            revert('This ID does not belong to a valid token class');
        }
    }

    function getTokenClassSupplyCap(uint256 _classId) external view override returns(uint256) {
        return _tokenClassSupplyCap[_classId];
    }

    function getTokenClassCurrentSupply(uint256 _classId) external view override returns(uint256) {
        return _tokenClassSupplyCurrent[_classId];
    }

    function getTokenClassVotingPower(uint256 _classId) external view override returns(uint256) {
        return _tokenClassVotingPower[_classId];
    }

    function getTokensMintedAtPresale(address account) external view override returns(uint256) {
        return _tokensMintedByAddressAtPresale[account];
    }

    function isTokenClass(uint256 _id) public pure override returns(bool) {
        return (_id >= 0 && _id <= 20510);
    }

    function isTokenClassMintable(uint256 _id) public pure override returns(bool) {
        return (_id >= 0 && _id <= 16010);
    }

    function isAscensionApple(uint256 _id) public pure override returns(bool) {
        return (_id >= 16011 && _id <= 19010);
    }

    function isBadApple(uint256 _id) public pure override returns(bool) {
        return (_id >= 19011 && _id <= 20510);
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }

    function ownerOf(uint256 _id) public view override returns(address) {
        return _owners[_id];
    }

    function consumedAscensionApples(address account) public view override returns(uint256) {
        return _consumedAscensionApples[account];
    }

    // Functions to comply with ERC721.
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address operator) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(_msgSender() != operator, "Error: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function getMintedToTreasuryFinished() public view returns(bool) {
        return _mintedToTreasuryHasFinished;
    }

    // Minting & airdropping.
    function airdropToTreasury(uint256[][] memory treasuryRandom) external onlyOwner {
        address divineTreasuryWallet = adminWallets.getDivineTreasuryWallet();
        require(!paused(), "Error: token transfer while paused");
        // Minting 244 NFTs to Divine Treasury Wallet.
        uint256[] memory tokenIds = treasuryRandom[0];
        uint256[] memory classIds = treasuryRandom[1];

        require(classIds.length == tokenIds.length);

        uint256 amount = tokenIds.length;
        require(_mintedToTreasury + amount <= MAX_MINTED_TO_TREASURY, 'Error: you are exceeding the max airdrop amount to Treasury');
        
       

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _beforeTokenTransfer(address(0), divineTreasuryWallet, tokenIds[i]);
            _balances[divineTreasuryWallet] += 1;
            _owners[tokenIds[i]] = divineTreasuryWallet;
            _tokenClass[tokenIds[i]] = classIds[i];
            _tokenClassSupplyCurrent[classIds[i]] += 1;

            emit Transfer(address(0), divineTreasuryWallet, tokenIds[i]);
            
        }

        _mintedToTreasury += amount;

        if(_mintedToTreasury == MAX_MINTED_TO_TREASURY) {
            _mintedToTreasuryHasFinished = true;
        }
    }    

    function mint(address account, uint256 amount) external nonReentrant payable {
        // Pre minting checks.
        address operator = _msgSender();

        require(msg.value >= TOKEN_UNIT_PRICE * amount, 'Make sure you can afford 0.09 eth per token');
        require(account != address(0), "Error: mint to the zero address");
        require(!paused(), "Error: token transfer while paused");
        require(_mintedToTreasuryHasFinished == true, 'Error: Wait until airdropping to Treasury has finished');

        bool presaleStatus = adminWallets.isPresaleActive();

        if (presaleStatus == true) {
            uint256 presaleRound = adminWallets.getCurrentPresaleRound();
            require(adminWallets.isAllowedAtPresale(presaleRound, operator) == true, 'Error: you cannot mint at this stage');
            require(_tokensMintedByAddressAtPresale[operator] + amount <= MAX_TOKENS_MINTED_BY_ADDRESS_PRESALE, 'Error: you cannot mint more tokens at presale');
        } else {
            require(_tokensMintedByAddress[operator] + amount <= MAX_TOKENS_MINTED_BY_ADDRESS, 'Error: you cannot mint more tokens');
        }

        // Mint process.
        /*
         * We have to provide a way to send some of the ether minted to the wallet owner of the oracle.
         * But we have to calculate the amount so that the oracle is assigned a proper amount of ether.
         */
        uint256[][] memory randomList = oracle.getRandomNumbers(amount);
        uint256[] memory tokensIds = randomList[0];
        uint256[] memory classIds = randomList[1];

        for (uint256 i = 0; i < amount; i++) {
            _beforeTokenTransfer(address(0), account, tokensIds[i]);

            _owners[tokensIds[i]] = account;
            _balances[account] += 1;
            _tokenClass[tokensIds[i]] = classIds[i];
            _tokenClassSupplyCurrent[classIds[i]] += 1;

            emit Transfer(address(0), account, tokensIds[i]);
        }

        // Post minting.
        if (adminWallets.isPresaleActive() == true) {
            _tokensMintedByAddressAtPresale[operator] += amount;
        } else {
            _tokensMintedByAddress[operator] += amount;
        }
    }

    function transferFrom(address from, address to, uint256 id) public override {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        _transfer(from, to, operator, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public override {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        _transfer(from, to, operator, id);
        // Post transfer: check IERC721Receiver.
        require(_checkOnERC721Received(from, to, id, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public override {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        _transfer(from, to, operator, id);

        // Post transfer: check IERC721Receiver with data input.
        require(_checkOnERC721Received(from, to, id, data), "ERC721: transfer to non ERC721Receiver implementer");

    }

    function _transfer(address from, address to, address operator, uint256 id) internal virtual {
        require(_owners[id] == from);
        require(from == operator || getApproved(id) == operator || isApprovedForAll(from, operator), "Error: caller is neither owner nor approved");
        _beforeTokenTransfer(from, to, id);

        // Transfer.
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[id] = to;

        emit Transfer(from, to, id);
        _tokenApprovals[id] = address(0);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids) public {
        // Pre transfer checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        if (from != operator && isApprovedForAll(from, operator) == false) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(getApproved(ids[i]) == operator, 'Error: caller is neither owner nor approved');
            }
        }

        // Transfer.
        for (uint256 i = 0; i < ids.length; i++) {
            require(_owners[ids[i]] == from);
            _beforeTokenTransfer(from, to, ids[i]);
            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[ids[i]] = to;

            emit Transfer(from, to, ids[i]);
            _tokenApprovals[ids[i]] = address(0);

            require(_checkOnERC721Received(from, to, ids[i], ""), "ERC721: transfer to non ERC721Receiver implementer");
        }
    }
    
    function burn(address account, uint256 id) public {
        // Pre burning checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        require(account == operator || getApproved(id) == operator || isApprovedForAll(account, operator), "Error: caller is neither owner nor approved");
        require(account != address(0), "Error: burn from the zero address");
        require(_owners[id] == account, 'Error: account is not owner of token id');
         _beforeTokenTransfer(account, address(0), id);

        // Burn process.
        _owners[id] = address(0);
        _balances[account] -= 1;

        emit Transfer(account, address(0), id);

        // Post burning.
        _tokenApprovals[id] = address(0);
    }

    function burnBatch(address account, uint256[] memory ids) public {
        // Pre burning checks.
        address operator = _msgSender();
        require(!paused(), "Error: token transfer while paused");

        if (account != operator && isApprovedForAll(account, operator) == false) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(getApproved(ids[i]) == operator, 'Error: caller is neither owner nor approved');
            }
        } 

        for (uint256 i = 0; i < ids.length; i++) {
            require(_owners[ids[i]] == account, 'Error: account is not owner of token id');
        }

        // Burn process.
        for (uint256 i = 0; i < ids.length; i++) {
            _beforeTokenTransfer(account, address(0), ids[i]);
            _owners[ids[i]] = address(0);
            _balances[account] -= 1;
            emit Transfer(account, address(0), ids[i]);
        }

        // Post burning.
        for (uint256 i=0; i < ids.length; i++) {
            _tokenApprovals[ids[i]] = address(0);
        }
    }

    function airdropApples(uint256 amount, uint256 appleClass, address[] memory accounts) external override onlyOwner {        
        require(accounts.length == amount);
        require(appleClass == ASCENSION_APPLE || appleClass == BAD_APPLE, 'Error: The token class is not an apple');
        require(_tokenClassSupplyCurrent[appleClass] + amount <= _tokenClassSupplyCap[appleClass], 'Error: You exceed the supply cap for this apple class');

        uint256 appleIdSetter;

        if (appleClass == ASCENSION_APPLE) {
            appleIdSetter = _initAscensionApple + _tokenClassSupplyCurrent[ASCENSION_APPLE];
        } else {
            appleIdSetter = _initBadApple + _tokenClassSupplyCurrent[BAD_APPLE];
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 appleId = appleIdSetter + i;
            _beforeTokenTransfer(address(0), accounts[i], appleId);
            _owners[appleId] = accounts[i];
            _balances[accounts[i]] += 1;
            _tokenClass[appleId] = appleClass;
        } 

        _tokenClassSupplyCurrent[appleClass] += amount;
    }

    function ascensionAppleConsume(address account, uint256 appleId) external {
        address operator = _msgSender();

        require(isAscensionApple(appleId), 'Error: token provided is not ascension apple');
        require(_owners[appleId] == operator || getApproved(appleId) == operator || isApprovedForAll(account, operator), "Error: caller is neither owner nor approved");

        burn(account, appleId);

        _consumedAscensionApples[account] += 1;
    }

    function badAppleConsume(address account, uint256 appleId, uint256 tokenId) external {
        address operator = _msgSender();

        require(isBadApple(appleId), 'Error: token provided is not bad apple');
        require(_owners[appleId] == operator || getApproved(appleId) == operator || isApprovedForAll(account, operator), "Error: caller is neither owner nor approved");

        burn(account, appleId);
        burn(account, tokenId);

        // Rewarding with 1 ascension apple.
        require(_tokenClassSupplyCurrent[ASCENSION_APPLE] + 1 <= _tokenClassSupplyCap[ASCENSION_APPLE], 'Error: You exceed the supply cap for this apple class');

        uint256 ascensionAppleId = _initAscensionApple + _tokenClassSupplyCurrent[ASCENSION_APPLE];
            
        _beforeTokenTransfer(address(0), account, ascensionAppleId);
        _owners[ascensionAppleId] = account;
        _balances[account] += 1;
        _tokenClassSupplyCurrent[ASCENSION_APPLE] += 1;
    }

    // Auxiliary functions.
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
      
    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual  returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual  returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual  returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    
       function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal   {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        for(uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }
    
    function getData(address _account)external view returns(uint256[][] memory){
        uint256[][] memory data = new uint256[][](2);
        uint256[] memory arrayOfTokens = walletOfOwner(_account);
        uint256[] memory othersData = new uint256[](1);
        othersData[0] = totalSupply();
        data[0] = arrayOfTokens;
        data[1] = othersData;
        return data;
    }
    
    function withdrawAll() external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is 0.");
        (bool success,) = payable(msg.sender).call{value: balance}(new bytes(0));
        if(!success)revert("withdrawAll: transfer error");
    }

    function withdraw(uint256 _amount) external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is 0.");
        require(balance > _amount, "balance must be superior to amount");
        (bool success,) = payable(msg.sender).call{value: _amount}(new bytes(0));
        if(!success)revert("withdraw: transfer error");
    }
    

}