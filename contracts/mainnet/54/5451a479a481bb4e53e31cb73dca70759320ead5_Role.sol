/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-02
 */

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
 */

// SPDX-License-Identifier: MIT

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``"s account.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI"s implementation - MIT licence
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

/*
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
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
    // slot"s contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler"s defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction"s gas, it is best to keep them low in cases like this one, to
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity"s `transfer`: sends `amount` wei to
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
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
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``"s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``"s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
     * Use along with {balanceOf} to enumerate all of ``owner``"s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``"s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``"s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
     * @dev Private function to add a token to this extension"s ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension"s token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension"s ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from"s tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token"s index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension"s token tracking data structures.
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
        // an "if" statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token"s index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

contract Role is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public seed;
    bool public saleIsActive = false;
    uint public next_token;

    mapping(uint => uint) public xp;
    mapping(uint => uint) public level;
    event leveled(address indexed owner, uint level, uint role);

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "RPK/not-authorized");
        _;
    }

    string[] private genus = [
        "Fox",
        "Piggy",
        "Doge",
        "Wolf",
        "Steed",
        "Alpaca",
        "Cat",
        "Chook",
        "Octopus",
        "Whale",
        "Owl",
        "Dragon"
    ];

    string[] private gender = ["Male", "Female", "Gynander"];

    // The initial age, No more than 30 (range: 0 - 30)
    uint256 private age = 31;

    string[] private career = [
        "Banker",
        "Game Player",
        "Strategist",
        "Negotiator",
        "Fortune Builder",
        "Theologian",
        "Appeaser",
        "Tactician",
        "Architect",
        "Warrior",
        "Physician",
        "Soldier",
        "Gastronome",
        "Cleric",
        "Outdoorsman",
        "Scholar",
        "Reader",
        "Writer",
        "Artist",
        "Pyromaniac",
        "Scientist",
        "Actor",
        "Nurse",
        "Security",
        "Trader",
        "Doctor",
        "Merchant",
        "Musician",
        "Engineer",
        "Hacker",
        "Student",
        "Broker",
        "Bartender",
        "Athlete",
        "Police",
        "Thief",
        "Farmer",
        "Teacher",
        "Professor",
        "Sailor",
        "Investor",
        "Degen",
        "Diplomat",
        "Politician"
    ];

    string[] private regional = [
        "Wind Land",
        "Cloud Land",
        "Rain Land",
        "Light Land",
        "Dark Land"
    ];

    string[] private marriage = ["Married", "Unmarried"];

    string[] private skin = [
        "#BACBFB",
        "#AA0000",
        "#4668FF",
        "#008C0E",
        "#CAB8FB",
        "#BF0049",
        "#9950FD",
        "#ED401D",
        "#58D1B3",
        "#00A763",
        "#FFDEC5",
        "#F29710",
        "#EDC3DB",
        "#D9D9D9",
        "#32EDA6"
    ];

    string[] private character = [
        "Arbitrary",
        "Ascetic",
        "Babbling Buffoon",
        "Bloodlust",
        "Body Modder",
        "Giant",
        "Gregarious",
        "Hedonist",
        "Iron Gut",
        "Lefthanded",
        "Light Eater",
        "Out Of Shape",
        "Playful",
        "Robust",
        "Secretive",
        "Shy",
        "Sturdy",
        "Tortured",
        "Short Sighted",
        "Severely Injured",
        "Smoker",
        "Weak Stomach",
        "Bastard",
        "Dwarf",
        "Feeble",
        "Fever",
        "Harelip",
        "Measles",
        "Tuberculosis",
        "Indolent",
        "Indulgent",
        "Infection",
        "Infirm",
        "Lisp",
        "Obese",
        "One Eyed",
        "One Handed",
        "One Legged",
        "Stout",
        "Syphilitic",
        "Aggressive",
        "Alert",
        "Ambitious",
        "Attractive",
        "Candid",
        "Careful",
        "Devoted",
        "Dutiful",
        "Easy-Going",
        "Forceful",
        "Forgetful",
        "Frank",
        "Genteel",
        "Frugal",
        "Gullible",
        "Happy",
        "Hard-Working",
        "Initiative",
        "Inventive",
        "Lazy",
        "Liberal",
        "Modest",
        "Obedient",
        "Selfless",
        "Sensible",
        "Sensitive",
        "Sincere",
        "Skeptical",
        "Smart",
        "Sociable",
        "Sporting",
        "Steady",
        "Straightforward",
        "Strict",
        "Strong-Willed",
        "Sympathetic",
        "Talented",
        "Trustful",
        "Understanding",
        "Unselfish",
        "Active",
        "Adroit",
        "Analytical",
        "Apprehensive",
        "Argumentative",
        "Bad-Tempered",
        "Bossy",
        "Brave",
        "Brilliant",
        "Caring",
        "Charitable",
        "Cheerful",
        "Childish",
        "Comical",
        "Conceited",
        "Confident",
        "Conscientious",
        "Dashing",
        "Dedicated",
        "Demanding",
        "Dependable",
        "Depressing",
        "Determined",
        "Diplomatic",
        "Disciplined",
        "Disorganized",
        "Energetic",
        "Enthusiastic",
        "Faithful",
        "Friendly",
        "Funny",
        "Generous",
        "Hearty",
        "Helpful",
        "Helpless",
        "Bloodthirsty",
        "Charismatic",
        "Mastermind",
        "Naive",
        "Skilled",
        "Visionary",
        "Misguided",
        "Tough",
        "Martial",
        "Weird",
        "Amiable",
        "Rude",
        "Crazy",
        "Mediocre",
        "Naughty",
        "Benevolent",
        "Graceful",
        "Nudist"
    ];

    // No more than 100 (range: 0 - 100)
    uint256 private lucky = 101;

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getGenus(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GENUS", genus);
    }

    function getGender(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GENDER", gender);
    }

    function getAge(uint256 tokenId) public view returns (string memory) {
        uint256 growthAge = (block.timestamp - seed) / 31536000;
        uint256 newAge = pluck(tokenId, "AGE", age) + growthAge;
        return toString(newAge);
    }

    function getCareer(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CAREER", career);
    }

    function getRegional(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "REGIONAL", regional);
    }

    function getMarriage(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MARRIAGE", marriage);
    }

    function getSkin(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SKIN", skin);
    }

    function getCharacter(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CHARACTER", character);
    }

    function getXp(uint256 tokenId) public view returns (string memory) {
        return toString(xp[tokenId]);
    }

    function getLevel(uint256 tokenId) public view returns (string memory) {
        return toString(level[tokenId]);
    }

    function getLucky(uint256 tokenId) public view returns (string memory) {
        return toString(pluck(tokenId, "LUCKY", lucky));
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(seed, keyPrefix, toString(tokenId)))
        );
        return sourceArray[rand % sourceArray.length];
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 randomRange
    ) internal view returns (uint256) {
        uint256 rand = random(
            string(abi.encodePacked(seed, keyPrefix, toString(tokenId)))
        );
        return rand % randomRange;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[26] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">';

        parts[1] = "<style>.base{font-family:serif;font-size:14px;fill:";

        parts[2] = getSkin(tokenId);

        parts[3] = ';}</style><rect width="100%" height="100%" fill="#281A33" />';

        parts[4] = '<path class="base" d="M50.7,59c0.7,0,1.3-0.1,2-0.2s1.3-0.3,1.8-0.6c0.5-0.3,0.7-0.7,0.7-1.3c0-0.4-0.2-0.6-0.7-0.6c-1.1,0-2.2-0.1-3.1-0.3c-1-0.2-1.9-0.7-2.8-1.5c-1.3-1.2-2.5-2.5-3.6-3.7s-2-2.5-2.9-3.8c-0.9-1.3-1.9-2.7-2.8-4.2c-0.1-0.1-0.1-0.3-0.2-0.4c0-0.1,0-0.2,0.2-0.2c0.9-0.4,1.8-0.9,2.7-1.6c0.9-0.7,1.6-1.5,2.2-2.5c0.6-1,0.9-2.3,0.9-3.7c0-2.6-1-4.6-2.9-5.9c-1.9-1.3-4.7-1.9-8.2-1.9c-1,0-1.8,0-2.5,0.1c-0.6,0-1.2,0.1-1.7,0.2c-0.5,0.1-1.1,0.1-1.7,0.1c-0.7,0-1.3,0-1.7,0s-0.9-0.1-1.5-0.1s-1.2,0-2.1,0c-0.4,0-0.7,0-0.9,0.1c-0.2,0.1-0.3,0.2-0.3,0.5c0,0.2,0.1,0.4,0.3,0.6c0.2,0.2,0.6,0.3,1.1,0.4c0.9,0.1,1.5,0.3,1.9,0.5c0.4,0.3,0.7,0.7,0.8,1.2s0.2,1.4,0.2,2.4l0,0v20.8c0,1.1-0.3,1.9-0.8,2.4s-1.4,0.8-2.6,1.1c-0.9,0.2-1.4,0.5-1.4,0.9c0,0.2,0.1,0.3,0.4,0.4c0.2,0.1,0.5,0.1,0.9,0.1c0.8,0,1.6,0,2.3-0.1c0.7-0.1,1.4-0.1,2.1-0.2c0.7,0,1.4-0.1,2.2-0.1c0.6,0,1.2,0,1.8,0.1c0.6,0,1.1,0.1,1.8,0.1c0.6,0.1,1.3,0.1,2.2,0.1c0.4,0,0.7,0,0.9-0.1c0.2-0.1,0.3-0.2,0.3-0.4c0-0.3-0.1-0.4-0.3-0.6c-0.2-0.1-0.6-0.2-1-0.3c-1.2-0.2-2.1-0.7-2.6-1.3c-0.5-0.6-0.8-1.5-0.8-2.5l0,0v-8.7c0-0.3,0.1-0.5,0.2-0.7c0.1-0.2,0.3-0.3,0.5-0.2c0.4,0,0.8,0.1,1.4,0.2c0.5,0.1,1.1,0.3,1.7,0.6c0.8,0.4,1.4,1,1.8,1.7c1,1.7,1.8,3,2.6,4.2c0.7,1.1,1.4,2.1,2.1,3c0.7,0.9,1.4,1.8,2.1,2.8c0.6,0.7,1.2,1.3,2,1.8c0.7,0.5,1.5,0.8,2.4,1.1C48.5,58.9,49.6,59,50.7,59z M33.2,42c-0.7,0-1.3-0.1-1.7-0.3c-0.4-0.2-0.6-0.7-0.6-1.4c0-1.8,0-3.3,0-4.6c0-1.3,0-2.3,0.1-3.1c0-1.7,0.2-2.9,0.5-3.5c0.3-0.6,0.9-0.9,1.8-0.9c1.7,0,3.1,0.3,4,0.9s1.6,1.4,1.9,2.5s0.5,2.3,0.5,3.6c0,1.2-0.3,2.3-0.8,3.4c-0.5,1-1.3,1.9-2.3,2.5C35.8,41.7,34.6,42,33.2,42z M68.6,36.1c0.3,0,0.4-0.2,0.4-0.5c0-0.1,0-0.2,0-0.4c0-0.2-0.1-0.3-0.1-0.5c-0.2-0.6-0.6-1.4-1-2.3c-0.5-0.9-0.9-1.8-1.4-2.7c-0.5-0.9-0.8-1.6-1.1-2c-0.2-0.3-0.4-0.6-0.7-0.7s-0.6-0.2-0.9-0.2c-0.7,0-1.3,0.1-1.8,0.2c-0.5,0.2-0.8,0.4-0.8,0.8c0,0.2,0,0.4,0.1,0.5c0.1,0.1,0.2,0.3,0.4,0.6c0.5,0.6,1,1.3,1.7,2.1c0.7,0.8,1.3,1.6,2,2.4c0.7,0.8,1.3,1.4,1.8,1.9C67.8,35.8,68.3,36.1,68.6,36.1z M66.3,58.7c2.5,0,4.5-0.5,6.2-1.6c1.6-1,2.9-2.4,3.7-4.1s1.2-3.5,1.2-5.4c0-1.8-0.4-3.4-1.3-4.8c-0.9-1.5-2.1-2.7-3.6-3.6c-1.5-0.9-3.2-1.4-5.1-1.4c-1.5,0-2.9,0.3-4.2,0.9s-2.5,1.5-3.5,2.5c-1,1.1-1.8,2.2-2.3,3.6c-0.5,1.3-0.8,2.7-0.8,4.1c0,1.9,0.4,3.6,1.3,5c0.9,1.5,2,2.6,3.5,3.5C62.8,58.2,64.5,58.7,66.3,58.7z M67.3,57c-1.2,0-2.2-0.4-3-1.3c-0.9-0.9-1.6-2-2.1-3.5c-0.5-1.4-0.8-2.9-0.8-4.4c0-1.4,0.1-2.6,0.3-3.8c0.2-1.2,0.6-2.1,1.2-2.9c0.5-0.6,1-1,1.6-1.2c0.6-0.2,1.3-0.4,2-0.4c1.2,0,2.3,0.4,3.2,1.3c0.9,0.9,1.6,2,2.1,3.4c0.5,1.4,0.8,2.9,0.8,4.5c0,1.1-0.1,2.2-0.2,3.3c-0.1,1.1-0.4,2-0.8,2.7c-0.4,0.8-1,1.3-1.7,1.7S68.2,57,67.3,57z M80.7,58.1c0.6,0,1.2,0,1.6-0.1s0.8-0.1,1.3-0.1c0.4,0,0.9,0,1.4,0c0.6,0,1.1,0,1.5,0c0.4,0,0.8,0.1,1.3,0.1c0.4,0,1,0.1,1.6,0.1c0.2,0,0.4,0,0.6-0.1c0.2-0.1,0.3-0.2,0.3-0.4c0-0.3-0.1-0.4-0.3-0.6c-0.2-0.1-0.5-0.2-0.8-0.3c-0.5-0.2-0.9-0.3-1.4-0.5s-0.6-0.6-0.6-1.3l0,0V30c0-1.7,0.1-2.9,0.2-3.7s0.1-1.4,0.1-1.6c0-0.1,0-0.2-0.1-0.3s-0.1-0.1-0.2-0.1c-0.1,0-0.2,0-0.4,0.1c-0.5,0.2-1.1,0.4-1.7,0.7c-0.6,0.3-1.3,0.5-2.1,0.8c-0.7,0.2-1.5,0.5-2.3,0.6c-0.3,0.1-0.4,0.3-0.4,0.6c0,0.4,0.1,0.6,0.4,0.7c0.8,0.2,1.3,0.6,1.6,1.2s0.4,1.4,0.4,2.3l0,0v23.8c0,0.7-0.2,1.1-0.6,1.3c-0.4,0.2-0.9,0.4-1.3,0.5c-0.3,0.1-0.5,0.2-0.8,0.3s-0.3,0.3-0.3,0.6c0,0.2,0.1,0.3,0.3,0.4C80.3,58.1,80.5,58.1,80.7,58.1z M101.4,58.7c1.1,0,2-0.2,3-0.5c0.9-0.3,1.7-0.8,2.4-1.3c0.7-0.6,1.3-1.2,1.7-1.9c0.5-0.7,0.7-1.3,0.7-1.8c0-0.3-0.1-0.5-0.4-0.5c-0.1,0-0.2,0-0.3,0.1c-0.1,0.1-0.2,0.2-0.3,0.3c-0.7,0.7-1.4,1.2-2.2,1.6c-0.8,0.4-1.7,0.5-2.6,0.5c-1.3,0-2.5-0.3-3.5-1c-1.1-0.7-1.9-1.6-2.5-2.8c-0.6-1.2-0.9-2.5-0.9-3.9c0-0.7,0.1-1.1,0.3-1.4c0.2-0.2,0.5-0.4,0.9-0.4l0,0h9.9c1,0,1.5-0.5,1.5-1.6c0-1.2-0.3-2.3-0.9-3.2c-0.6-0.9-1.4-1.7-2.4-2.2c-1-0.5-2.2-0.8-3.5-0.8c-1.8,0-3.4,0.5-4.8,1.4c-1.5,0.9-2.6,2.2-3.5,3.8c-0.9,1.6-1.3,3.3-1.3,5.2c0,2.1,0.4,3.9,1.1,5.5s1.8,2.8,3.1,3.7C98.1,58.3,99.6,58.7,101.4,58.7z M101.5,44h-3.8c-0.4,0-0.6-0.2-0.6-0.5c0-0.6,0.2-1.3,0.7-1.9c0.4-0.6,1-1.1,1.7-1.6c0.7-0.4,1.4-0.6,2.1-0.6c1,0,1.9,0.3,2.7,0.9s1.1,1.4,1.1,2.3c0,0.3,0,0.6-0.1,0.8c-0.1,0.2-0.2,0.3-0.3,0.4c-0.4,0.1-0.9,0.2-1.4,0.2C103,44,102.4,44,101.5,44L101.5,44z"/>';
        
        parts[5] = '<text x="20" y="100" class="base">';

        parts[6] = getGenus(tokenId);

        parts[7] = '</text><text x="20" y="120" class="base">';

        parts[8] = getGender(tokenId);

        parts[9] = '</text><text x="20" y="140" class="base">';

        parts[10] = getAge(tokenId);

        parts[11] = '</text><text x="20" y="160" class="base">';

        parts[12] = getMarriage(tokenId);

        parts[13] = '</text><text x="20" y="180" class="base">';

        parts[14] = getRegional(tokenId);

        parts[15] = '</text><text x="20" y="200" class="base">';

        parts[16] = getCareer(tokenId);

        parts[17] = '</text><text x="20" y="220" class="base">';

        parts[18] = getCharacter(tokenId);
        
        parts[19] = '</text><text x="20" y="240" class="base">Lv ';

        parts[20] = getLevel(tokenId);

        parts[21] = '</text><text x="20" y="260" class="base">XP ';

        parts[22] = getXp(tokenId);

        parts[23] = '</text><text x="20" y="280" class="base">LUK+';

        parts[24] = getLucky(tokenId);

        parts[25] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[7],
                parts[8],
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[14],
                parts[15],
                parts[16],
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[22],
                parts[23],
                parts[24],
                parts[25]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Role(for 0xAdventure) #',
                        toString(tokenId),
                        '", "description": "0xAdventure is a guild of Dimensional Breakers. We are willing to give precious life to become a beacon for all Dimensional Breakers.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function claim() public nonReentrant {
        require(saleIsActive, "Sale must be active to mint Role");
        uint _next_role = next_token;
        level[_next_role] = 1;
        _safeMint(_msgSender(), _next_role);
        next_token++;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI"s implementation - MIT license
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

    // level
    function addXp(uint _tokenId, uint _xp) external auth {
        require(_tokenId < totalSupply(), "operator query for nonexistent token");
        xp[_tokenId] += _xp;
    }

    function addListXp(uint[] memory _tokenIds, uint[] memory _xps) external auth {
        require(_tokenIds.length == _xps.length, "tokenIds are inconsistent with xps length");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] < totalSupply(), "operator query for nonexistent token");
            uint _tokenId = _tokenIds[i];
            uint _xp = _xps[i];
            xp[_tokenId] += _xp;
        }
    }
    
    function levelUp(uint _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        uint _level = level[_tokenId];
        uint _xp_required = xp_required(_level);
        require(xp[_tokenId] >= _xp_required, "xp is not enough");
        xp[_tokenId] -= _xp_required;
        level[_tokenId] = _level + 1;
        emit leveled(msg.sender, _level, _tokenId);
    }
    
    function xp_required(uint curent_level) public pure returns (uint xp_to_next_level) {
        xp_to_next_level = curent_level * 1000;
        for (uint i = 1; i < curent_level; i++) {
            xp_to_next_level += i * 1000;
        }
    }

    constructor()
        ERC721("Role(for 0xAdventure)", "ROLE")
        Ownable()
    {
        seed = block.timestamp;
        wards[msg.sender] = 1;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

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
     * @dev Moves `amount` tokens from the caller"s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller"s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender"s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller"s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}