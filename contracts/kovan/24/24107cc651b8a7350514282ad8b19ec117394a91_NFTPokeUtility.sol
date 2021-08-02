/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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


// File contracts/INFTPoke.sol


pragma solidity ^0.8.5;

interface INFTPoke is IERC721 {
    function getTokensOf(address owner)
        external
        view
        returns (uint256[] memory);

    function getCurrentNumberOfNFTs() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override;
}


// File contracts/ICommon.sol


pragma solidity ^0.8.5;

interface ICommon {
    struct NFTDetails {
        uint256 stakePosition;
        uint256 stakeTime;
        uint256 tokenId;
    }
}


// File contracts/INFTPokeStakeController.sol


pragma solidity ^0.8.5;

interface INFTPokeStakeController is ICommon {}


// File contracts/INFTPokeStakeControllerProxy.sol


pragma solidity ^0.8.5;

interface INFTPokeStakeControllerProxy is ICommon {
    function mintNewToken(address owner, NFTDetails memory token) external;

    function mintNewTokens(address owner, NFTDetails[] memory tokens) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


pragma solidity ^0.8.0;







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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/access/[email protected]


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}


// File contracts/MerkleProof.sol


pragma solidity ^0.8.5;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
contract MerkleProof {
    bytes32 public root;

    constructor(bytes32 _root) {
        root = _root;
    }

    function verifyURI(string memory tokenURI, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(tokenURI));
        return verify(leaf, proof);
    }

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32 leaf, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


// File contracts/NFTPoke.sol


pragma solidity ^0.8.5;






contract NFTPoke is
    Ownable,
    ERC721URIStorage,
    MerkleProof,
    ERC721Pausable,
    INFTPoke
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI = "https://ipfs.io/ipfs/";

    //  marks the token as being minted
    mapping(bytes32 => bool) public mintedTokens;
    //  find tokenId by tokenURI
    mapping(bytes32 => uint256) public uriToTokenId;
    //  find all tokens of an address
    mapping(address => uint256[]) public tokensByAddress;

    //  the starting price to mint an NFT
    uint256 public currentPrice;
    //  the price increase after each NFT is minted
    uint256 public priceIncrease;
    //  the number of tokens that will not get price increases
    uint256 public numberOfTokensAtSamePrice = 200;
    //  maximum number of hard minted tokens
    uint256 public maxHardMinted = 242;
    //  the current number of hard minted tokens
    uint256 public hardMinted;
    //  maximum number of tokens that can be minted
    uint256 public maxMinted = 13000 + maxHardMinted;

    event SetBaseUri(
        address indexed _owner,
        string initialBaseURI,
        string finalBaseURI
    );
    event MintedOwner(string tokenURI, uint256 tokenId);
    event Minted(
        address indexed _owner,
        uint256 price,
        string tokenURI,
        uint256 tokenId
    );
    event MintedMultiple(
        address indexed _owner,
        uint256 price,
        uint256 tokenLength
    );
    event TransferToken(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );

    constructor(
        string memory nftName,
        string memory nftSymbol,
        bytes32 root,
        uint256 _currentPrice,
        uint256 _priceIncrease
    ) ERC721(nftName, nftSymbol) MerkleProof(root) {
        currentPrice = _currentPrice;
        priceIncrease = _priceIncrease;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
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
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @param from address from which to transfer the token
     * @param to address to which to transfer the token
     * @param tokenId to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(INFTPoke, ERC721) {
        changeTokenOwners(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
        emit TransferToken(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @param from address from which to transfer the token
     * @param to address to which to transfer the token
     * @param tokenId to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(INFTPoke, ERC721) {
        changeTokenOwners(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
        emit TransferToken(from, to, tokenId);
    }

    function changeTokenOwners(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint256 length = tokensByAddress[from].length;
        for (uint256 i = 0; i < length; i++) {
            if (tokensByAddress[from][i] == tokenId) {
                tokensByAddress[from][i] = tokensByAddress[from][length - 1];
                tokensByAddress[from].pop();
                tokensByAddress[to].push(tokenId);
                return;
            }
        }
        revert("There was not found any token");
    }

    /**
     * @dev Return the list of tokenIds assigned for a specific address
     * @param owner address for which we return the token list
     * @return list value of 'number'
     */
    function getTokensOf(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        return tokensByAddress[owner];
    }

    /**
     * @dev Return if a specific token URI was already minted
     * @param tokenURIValue string to be verified
     * @return bool value
     */
    function isMinted(string memory tokenURIValue) public view returns (bool) {
        return mintedTokens[hashed(tokenURIValue)];
    }

    /**
     * @dev Return the hash of the given tokenURI
     * @param tokenURIValue string for which to calculate the hash
     * @return bytes32 hash value
     */
    function hashed(string memory tokenURIValue)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenURIValue));
    }

    /**
     * @dev Mint by owner a given list of hashes
     * @param hashes string list to mint
     */
    function mintByOwner(string[] memory hashes) public onlyOwner {
        require(
            hardMinted + hashes.length <= maxHardMinted,
            "There are too many hard minted tokens"
        );
        for (uint256 i = 0; i < hashes.length; i++) {
            mintItemWithoutProof(hashes[i]);
            hardMinted++;
        }
    }

    /**
     * @dev Set the baseURI to a given tokenURI
     * @param uri string to save
     */
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
        emit SetBaseUri(msg.sender, baseURI, uri);
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overwritten
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Get the current number of minted NFTs
     * @return uint256 value
     */
    function getCurrentNumberOfNFTs() public view override returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Return a tokenId given a string tokenURI
     * @param tokenURIValue string to be verified
     * @return uint256 value
     */
    function getTokenIdByTokenURI(string memory tokenURIValue)
        public
        view
        returns (uint256)
    {
        return uriToTokenId[hashed(tokenURIValue)];
    }

    /**
     * @dev Verify that the current tokenURI is part of the root merkleTree
     * @param tokenURIValue string to be verified
     */
    modifier validURI(string memory tokenURIValue, bytes32[] memory proof) {
        require(verifyURI(tokenURIValue, proof), "Not valid tokenURI");
        _;
    }

    /**
     * @dev Mint a list of NFTs as owner
     * @param tokenURIValue string
     */
    function mintItemWithoutProof(string memory tokenURIValue) internal {
        bytes32 uriHash = hashed(tokenURIValue);

        //  increment the number of tokens minted
        _tokenIds.increment();
        //  get a new token id
        uint256 id = _tokenIds.current();
        //  mint the new id to the sender
        _mint(msg.sender, id);
        //  set the tokenURI for the minted token
        _setTokenURI(id, tokenURIValue);
        //  link the tokenURI with the token id
        uriToTokenId[uriHash] = id;
        //  mark the tokenURI token as minted
        mintedTokens[uriHash] = true;

        tokensByAddress[msg.sender].push(id);

        emit MintedOwner(tokenURIValue, id);
    }

    /**
     * @dev It is possible that funds were sent to this address before the contract was deployed.
     * We can flush those funds to the destination address.
     */
    function flush() public onlyOwner {
        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(address(this).balance);
    }

    /**
     * @dev Mint a list of tokenURIs
     * @param tokenURIs string list of
     * @param proofs bytes32 list
     */
    function mintItems(string[] memory tokenURIs, bytes32[][] memory proofs)
        public
        payable
        returns (uint256[] memory)
    {
        require(
            tokenURIs.length == proofs.length,
            "The input number of token URIs length is not the same as the number of proofs"
        );
        require(
            msg.value >= currentPrice * tokenURIs.length,
            "value is smaller than current price"
        );
        require(
            _tokenIds.current() < maxMinted,
            "No more tokens can be minted"
        );
        require(
            _tokenIds.current() + tokenURIs.length <= maxMinted,
            "The number of tokens to mint is greater than maximum allowed"
        );

        uint256[] memory rez = new uint256[](tokenURIs.length);

        uint256 oldId = _tokenIds.current();

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            require(verifyURI(tokenURIs[i], proofs[i]), "Not valid tokenURI");

            bytes32 uriHash = hashed(tokenURIs[i]);
            //make sure they are only minting something that is not already minted
            require(!mintedTokens[uriHash], "Token already minted");

            //  get a new token id
            uint256 id = _tokenIds.current() + 1;
            //  mint the new id to the sender
            _mint(msg.sender, id);
            //  set the tokenURI for the minted token
            _setTokenURI(id, tokenURIs[i]);
            //  link the tokenURI with the token id
            uriToTokenId[uriHash] = id;
            //  mark the tokenURI token as minted
            mintedTokens[uriHash] = true;
            //  increment the number of tokens minted
            _tokenIds.increment();

            tokensByAddress[msg.sender].push(id);

            rez[i] = id;
        }

        uint256 maxStableId = numberOfTokensAtSamePrice + hardMinted;

        if (_tokenIds.current() >= maxStableId) {
            if (oldId < maxStableId) {
                uint256 mintedTokensWithPriceIncrease = tokenURIs.length -
                    (maxStableId - oldId);
                //  increase price of the next token to be minted
                currentPrice =
                    currentPrice +
                    priceIncrease *
                    mintedTokensWithPriceIncrease;
            } else {
                //  increase price of the next token to be minted
                currentPrice = currentPrice + priceIncrease * tokenURIs.length;
            }
        }

        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(msg.value);

        emit MintedMultiple(msg.sender, currentPrice, tokenURIs.length);

        return rez;
    }

    /**
     * @dev Mint a NFT based on the tokenURIValue
     * @param tokenURIValue string
     * @param proof bytes32 list
     */
    function mintItem(string memory tokenURIValue, bytes32[] memory proof)
        public
        payable
        validURI(tokenURIValue, proof)
        returns (uint256)
    {
        require(
            msg.value >= currentPrice,
            "value is smaller than current price"
        );
        require(
            _tokenIds.current() < maxMinted,
            "No more tokens can be minted"
        );

        bytes32 uriHash = hashed(tokenURIValue);

        //make sure they are only minting something that is not already minted
        require(!mintedTokens[uriHash], "Token already minted");

        //  get a new token id
        uint256 id = _tokenIds.current() + 1;
        //  mint the new id to the sender
        _mint(msg.sender, id);
        //  set the tokenURI for the minted token
        _setTokenURI(id, tokenURIValue);
        //  link the tokenURI with the token id
        uriToTokenId[uriHash] = id;
        //  mark the tokenURI token as minted
        mintedTokens[uriHash] = true;
        //  increment the number of tokens minted
        _tokenIds.increment();

        tokensByAddress[msg.sender].push(id);

        if (id >= numberOfTokensAtSamePrice + hardMinted) {
            //  increase price of the next token to be minted
            currentPrice = currentPrice + priceIncrease;
        }

        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(msg.value);

        emit Minted(msg.sender, currentPrice, tokenURIValue, id);

        //  returns the current minted token id
        return id;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}


// File contracts/Utility.sol

pragma solidity 0.8.5;

contract Utility is Ownable {
    event FallbackCalled(bool called);
    event ReceiveCalled(bool called);

    fallback() external payable {
        emit FallbackCalled(true);
    }

    receive() external payable {
        emit ReceiveCalled(true);
    }

    function flush(bool canBeReverted) external {
        uint256 balance = address(this).balance;

        if (canBeReverted) {
            require(balance > 0, "Contract has no balance");
        } else if (balance == 0) {
            return;
        }

        address payable to = payable(owner());
        to.transfer(balance);
    }
}


// File contracts/NFTPokeGovernance.sol

pragma solidity 0.8.5;








contract NFTPokeGovernance is
    Utility,
    ERC20Burnable,
    ERC20Capped,
    ERC165Storage,
    ERC20Snapshot,
    INFTPokeStakeControllerProxy
{
    using ERC165Checker for address;

    event TokenMinterAdded(address tokenMinter);
    event TokenMinted(address owner, uint256 mintedTokens);
    event TokenBurned(address owner, uint256 burnedTokens);
    event TokenBurnedFrom(address owner, address account, uint256 burnedTokens);

    address public stakeMinter;

    uint256 public rewardStakeMax = 81791963015494100000000000;
    uint256 public rewardPerSecond = 300000000000000;
    uint256 public rewardTokenPerSecond = 300000000000000;
    uint256 public rewardStakePositionPerSecond = 100000000000000;

    uint256 private constantValue = 1324200000;
    uint256 private constantValue2 = 113242;

    /**
     * @dev NFTPokeGovernance constructor
     * Supports the IERC20 and IStakeProxy interfaces
     * @param name_ of the token
     * @param symbol_ of the token
     * @param cap_ is the total supply
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_
    ) ERC20(name_, symbol_) ERC20Capped(cap_) {
        _registerInterface(type(IERC20).interfaceId);
        _registerInterface(ERC20.name.selector);
        _registerInterface(ERC20.symbol.selector);
        _registerInterface(ERC20.decimals.selector);
        _registerInterface(type(INFTPokeStakeControllerProxy).interfaceId);
    }

    /**
     * @dev See {ERC20-_mint and ERC20Capped-_mint}.
     * @param account for who to mint new tokens
     * @param amount amount to mint
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
        emit TokenMinted(account, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer and ERC20Snapshot-_beforeTokenTransfer }.
     * @param from who to send the tokens
     * @param to who to send the tokens
     * @param amount to be transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See {ERC20Snapshot-takeSnapshot}.
     */
    function takeSnapshot() external onlyOwner returns (uint256) {
        return super._snapshot();
    }

    /**
     * @dev Add a new contract that can mint tokens for users
     * @param minter that has access to mint new tokens for a specific user
     */
    function addTokenMinter(address minter) external onlyOwner {
        require(stakeMinter == address(0), "Can't assign a new token minter");
        require(
            minter.supportsInterface(type(INFTPokeStakeController).interfaceId),
            "Token doesn't implement INFTPokeStakeController"
        );
        stakeMinter = minter;
        emit TokenMinterAdded(minter);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokenBurned(msg.sender, amount);
    }

    /**
     * See {ERC20-_burn} and {ERC20-allowance}.
     */
    function burnFrom(address account, uint256 amount) public override {
        super.burnFrom(account, amount);
        emit TokenBurnedFrom(msg.sender, account, amount);
    }

    /**
     * @dev Modifier that checks to see if address who wants to mint has access
     */
    modifier verifyStakeMinter() {
        require(
            msg.sender == stakeMinter,
            "The minter is not the stake contract"
        );
        _;
    }

    /**
     * @dev Mint new tokens for a single NFT token
     * @param owner that will receive new minted tokens
     * @param token details for the NFT token
     */
    function mintNewToken(address owner, NFTDetails memory token)
        external
        override
        verifyStakeMinter
    {
        uint256 stakedTime = block.timestamp - token.stakeTime;

        uint256 reward = rewardPerSecond * stakedTime;
        uint256 rewardToken = rewardTokenPerSecond * stakedTime;
        uint256 rewardPosition = rewardStakePositionPerSecond * stakedTime;

        uint256 rewardTokenId = (rewardToken *
            (constantValue - token.tokenId * constantValue2)) / constantValue;
        uint256 rewardStakePosition = (rewardPosition *
            (constantValue - (token.stakePosition + 1) * constantValue2)) /
            constantValue;

        reward += rewardTokenId + rewardStakePosition;

        if (totalSupply() + reward > rewardStakeMax) {
            reward = rewardStakeMax - totalSupply();
        }
        require(reward > 0, "No rewards to mint");
        _mint(owner, reward);
    }

    /**
     * @dev Mint new tokens for multiple NFT tokens
     * @param owner that will receive new minted tokens
     * @param tokens details for the NFT tokens
     */
    function mintNewTokens(address owner, NFTDetails[] memory tokens)
        external
        override
        verifyStakeMinter
    {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            NFTDetails memory token = tokens[i];

            uint256 stakedTime = block.timestamp - token.stakeTime;

            uint256 reward = rewardPerSecond * stakedTime;
            uint256 rewardToken = rewardTokenPerSecond * stakedTime;
            uint256 rewardPosition = rewardStakePositionPerSecond * stakedTime;

            uint256 rewardTokenId = (rewardToken *
                (constantValue - token.tokenId * constantValue2)) /
                constantValue;
            uint256 rewardStakePosition = (rewardPosition *
                (constantValue - (token.stakePosition + 1) * constantValue2)) /
                constantValue;

            totalReward += reward + rewardTokenId + rewardStakePosition;
        }
        if (totalSupply() + totalReward > rewardStakeMax) {
            totalReward = rewardStakeMax - totalSupply();
        }
        require(totalReward > 0, "No rewards to mint");
        _mint(owner, totalReward);
    }
}


// File contracts/NFTPokeStakeController.sol


pragma solidity ^0.8.5;










contract NFTPokeStakeController is
    Ownable,
    ERC165Storage,
    IERC721Receiver,
    INFTPokeStakeController
{
    using ERC165Checker for address;

    address public contractAddress;
    INFTPoke public nft;
    INFTPokeStakeControllerProxy[] public tokens;

    event RewardTokenAdded(address rewardToken);
    event RewardTokenRemoved(address rewardToken);
    event ReceivedToken(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );
    event StakeToken(
        address owner,
        uint256 tokenId,
        uint256 stakeIndex,
        uint256 timestamp
    );
    event UnstakeToken(address owner, uint256 tokenId, uint256 timestamp);

    constructor(address nftAddress) {
        require(
            nftAddress.supportsInterface(type(IERC721).interfaceId),
            "Token doesn't implement IERC721"
        );
        _registerInterface(type(INFTPokeStakeController).interfaceId);
        nft = INFTPoke(nftAddress);
        contractAddress = address(this);
    }

    function getRewardTokenAddresses() public view returns (address[] memory) {
        address[] memory tokenAddresses = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenAddresses[i] = address(tokens[i]);
        }
        return tokenAddresses;
    }

    function getCurrentNumberOfNFTs() external view returns (uint256) {
        return nft.getCurrentNumberOfNFTs();
    }

    function tokensByAddress() public view returns (uint256[] memory) {
        return nft.getTokensOf(msg.sender);
    }

    function addRewardToken(address newRewardToken) external onlyOwner {
        require(
            newRewardToken.supportsInterface(
                type(INFTPokeStakeControllerProxy).interfaceId
            ),
            "Token doesn't implement INFTPokeStakeControllerProxy"
        );
        bool exists = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (address(tokens[i]) == newRewardToken) {
                exists = true;
                break;
            }
        }
        require(!exists, "The reward token already exists");
        tokens.push(INFTPokeStakeControllerProxy(newRewardToken));
        emit RewardTokenAdded(newRewardToken);
    }

    function removeRewardToken(address rewardToken) external onlyOwner {
        require(
            rewardToken.supportsInterface(
                type(INFTPokeStakeControllerProxy).interfaceId
            ),
            "Token doesn't implement INFTPokeStakeControllerProxy"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            if (address(tokens[i]) == rewardToken) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                emit RewardTokenRemoved(rewardToken);
                return;
            }
        }
        revert("The rewardToken doesn't exists");
    }

    function transferTokenBack(address to, uint256 tokenId) public onlyOwner {
        require(
            nft.ownerOf(tokenId) == contractAddress,
            "The contract is not owner of this token"
        );
        require(!_allTokensStakeFlag[tokenId], "Token is already stacked");
        nft.safeTransferFrom(contractAddress, to, tokenId);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     * this can be used just when the user is sending directly to the contract
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        emit ReceivedToken(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    /**
     * @dev stake a single token by transferring from the owner to the stake contract and start earning rewards
     */
    function stake(uint256 tokenId) external {
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "The sender is not the owner of this token"
        );
        nft.safeTransferFrom(msg.sender, contractAddress, tokenId);
        require(
            nft.ownerOf(tokenId) == contractAddress,
            "The owner of this token is not the contract"
        );
        stakeProcess(tokenId);
    }

    /**
     * @dev stake a single token by transferring from the owner to the stake contract and start earning rewards
     */
    function stakeAll() external {
        uint256[] memory userTokens = tokensByAddress();
        require(userTokens.length > 0, "There are tokens to staked for sender");

        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            nft.safeTransferFrom(msg.sender, contractAddress, tokenId);
            require(
                nft.ownerOf(tokenId) == contractAddress,
                "The owner of this token is not the contract"
            );
        }
        stakeAllInit(userTokens);
    }

    /**
     * @dev stake a single token by transferring from the owner to the stake contract and start earning rewards
     */
    function unstake(uint256 tokenId) external {
        require(
            nft.ownerOf(tokenId) == contractAddress,
            "The owner of this token is not the contract"
        );
        require(
            isStakedByOwner(msg.sender, tokenId),
            "The sender is not owner of tokenId to unstake"
        );
        NFTDetails memory tokenDetails = unstakeProcess(tokenId);
        nft.safeTransferFrom(contractAddress, msg.sender, tokenId);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "The sender is not the owner of this token"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            INFTPokeStakeControllerProxy token = tokens[i];
            token.mintNewToken(msg.sender, tokenDetails);
        }
    }

    /**
     * @dev stake a single token by transferring from the owner to the stake contract and start earning rewards
     */
    function unstakeAll() external {
        uint256[] memory userTokens = getStackedTokens();
        require(userTokens.length > 0, "There are no staked tokens for sender");
        NFTDetails[] memory stakedTokenDetails = unstakeAllInit(userTokens);

        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            nft.safeTransferFrom(contractAddress, msg.sender, tokenId);
            require(
                nft.ownerOf(tokenId) == msg.sender,
                "The sender is not the owner of this token"
            );
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            INFTPokeStakeControllerProxy token = tokens[i];
            token.mintNewTokens(msg.sender, stakedTokenDetails);
        }
    }

    struct NFTStakeDetails {
        uint256 index;
        uint256 stakePosition;
        uint256 stakeTime;
    }
    // Array with all token ids that are stacked
    uint256[] public allTokensStaked;
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) public _allTokensIndex; // todo add private
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => bool) public _allTokensStakeFlag; // todo add private

    // mapping from owner to list of staked token ids
    mapping(address => uint256[]) public _ownerTokenList; // todo add private
    // Mapping from token ID to token details of the owner tokens list
    mapping(uint256 => NFTStakeDetails) public _ownedTokensDetails;

    function getStackedTokens() public view returns (uint256[] memory) {
        return _ownerTokenList[msg.sender];
    }

    function getStackedTokensOf(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return _ownerTokenList[owner];
    }

    function getTokenDetails() public view returns (NFTDetails[] memory) {
        return getTokenDetailsOf(msg.sender);
    }

    function getTokenDetailsOf(address owner)
        public
        view
        returns (NFTDetails[] memory)
    {
        uint256[] memory tokenIds = getStackedTokensOf(owner);

        NFTDetails[] memory tokenDetails = new NFTDetails[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            NFTStakeDetails memory tokenDetail = _ownedTokensDetails[tokenId];
            tokenDetails[i] = NFTDetails(
                tokenDetail.stakePosition,
                tokenDetail.stakeTime,
                tokenId
            );
        }

        return tokenDetails;
    }

    function isStakedByOwner(address owner, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        NFTStakeDetails memory details = _ownedTokensDetails[tokenId];
        return
            details.stakeTime > 0 &&
            _ownerTokenList[owner].length > details.index;
    }

    function stakeAllInit(uint256[] memory tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakeProcess(tokenIds[i]);
        }
    }

    function stakeProcess(uint256 tokenId) internal {
        require(!_allTokensStakeFlag[tokenId], "Token is already stacked");

        uint256 insertIndex = allTokensStaked.length;
        _allTokensStakeFlag[tokenId] = true;
        _allTokensIndex[tokenId] = insertIndex;
        allTokensStaked.push(tokenId);

        uint256 currentOwnerIndex = _ownerTokenList[msg.sender].length;
        _ownerTokenList[msg.sender].push(tokenId);
        _ownedTokensDetails[tokenId] = NFTStakeDetails(
            currentOwnerIndex,
            insertIndex,
            block.timestamp
        );
        emit StakeToken(msg.sender, tokenId, insertIndex, block.timestamp);
    }

    function unstakeProcess(uint256 tokenId)
        internal
        returns (NFTDetails memory)
    {
        require(_allTokensStakeFlag[tokenId], "Token is not staked");

        _allTokensStakeFlag[tokenId] = false;
        uint256 index = _allTokensIndex[tokenId];
        _allTokensIndex[tokenId] = 0;
        allTokensStaked[index] = allTokensStaked[allTokensStaked.length - 1];
        allTokensStaked.pop();

        NFTStakeDetails memory tokenDetails = _ownedTokensDetails[tokenId];
        uint256[] storage tokenOwnedList = _ownerTokenList[msg.sender];
        uint256 lastTokenId = tokenOwnedList[tokenOwnedList.length - 1];
        tokenOwnedList[tokenDetails.index] = lastTokenId;
        tokenOwnedList.pop();
        _ownedTokensDetails[lastTokenId].index = tokenDetails.index;
        delete _ownedTokensDetails[tokenId];

        emit UnstakeToken(msg.sender, tokenId, block.timestamp);
        return
            NFTDetails(
                tokenDetails.stakePosition,
                tokenDetails.stakeTime,
                tokenId
            );
    }

    function unstakeAllInit(uint256[] memory tokenIds)
        internal
        returns (NFTDetails[] memory)
    {
        NFTDetails[] memory tokenDetails = getTokenDetailsOf(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_allTokensStakeFlag[tokenId], "Token is not staked");

            _allTokensStakeFlag[tokenId] = false;
            uint256 index = _allTokensIndex[tokenId];
            _allTokensIndex[tokenId] = 0;
            uint256 lastToken = allTokensStaked[allTokensStaked.length - 1];
            allTokensStaked[index] = lastToken;
            _allTokensIndex[lastToken] = index;
            allTokensStaked.pop();
            delete _ownedTokensDetails[tokenId];
            emit UnstakeToken(msg.sender, tokenId, block.timestamp);
        }
        delete _ownerTokenList[msg.sender];
        return tokenDetails;
    }
}


// File contracts/NFTPokeUtility.sol

pragma solidity 0.8.5;








contract NFTPokeUtility is
    Utility,
    ERC20Burnable,
    ERC20Capped,
    ERC165Storage,
    ERC20Snapshot,
    INFTPokeStakeControllerProxy
{
    using ERC165Checker for address;

    event TokenMinterAdded(address tokenMinter);
    event TokenMinted(address owner, uint256 mintedTokens);
    event TokenBurned(address owner, uint256 burnedTokens);
    event TokenBurnedFrom(address owner, address account, uint256 burnedTokens);

    address public stakeMinter;

    uint256 public liquidityPoolTokens = 70107396870423500000000000;
    uint256 public publicSellTokens = 46738264580282300000000000;
    uint256 public privateSellTokens = 23369132290141200000000000;
    uint256 public inGameRewardTokens = 11684566145070600000000000;

    uint256 public rewardStakeMax = 81791963015494100000000000;
    uint256 public rewardPerSecond = 300000000000000;
    uint256 public rewardTokenPerSecond = 300000000000000;
    uint256 public rewardStakePositionPerSecond = 100000000000000;

    uint256 private constantValue = 1324200000;
    uint256 private constantValue2 = 113242;

    /**
     * @dev NFTPokeUtility constructor
     * Supports the IERC20 and IStakeProxy interfaces
     * @param name_ of the token
     * @param symbol_ of the token
     * @param cap_ is the total supply
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_
    ) ERC20(name_, symbol_) ERC20Capped(cap_) {
        _registerInterface(type(IERC20).interfaceId);
        _registerInterface(ERC20.name.selector);
        _registerInterface(ERC20.symbol.selector);
        _registerInterface(ERC20.decimals.selector);
        _registerInterface(type(INFTPokeStakeControllerProxy).interfaceId);
    }

    /**
     * @dev See {ERC20-_mint and ERC20Capped-_mint}.
     * @param account for who to mint new tokens
     * @param amount amount to mint
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
        emit TokenMinted(account, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer and ERC20Snapshot-_beforeTokenTransfer }.
     * @param from who to send the tokens
     * @param to who to send the tokens
     * @param amount to be transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See {ERC20Snapshot-takeSnapshot}.
     */
    function takeSnapshot() external onlyOwner returns (uint256) {
        return super._snapshot();
    }

    /**
     * @dev Add a new contract that can mint tokens for users
     * @param minter that has access to mint new tokens for a specific user
     */
    function addTokenMinter(address minter) external onlyOwner {
        require(stakeMinter == address(0), "Can't assign a new token minter");
        require(
            minter.supportsInterface(type(INFTPokeStakeController).interfaceId),
            "Token doesn't implement INFTPokeStakeController"
        );
        stakeMinter = minter;
        emit TokenMinterAdded(minter);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokenBurned(msg.sender, amount);
    }

    /**
     * See {ERC20-_burn} and {ERC20-allowance}.
     */
    function burnFrom(address account, uint256 amount) public override {
        super.burnFrom(account, amount);
        emit TokenBurnedFrom(msg.sender, account, amount);
    }

    bool public privateSellTokensMinted = false;
    bool public publicSellTokensMinted = false;
    bool public liquidityPoolTokensMinted = false;
    bool public inGameRewardTokensMinted = false;

    function mintForPrivateSell() external onlyOwner {
        require(!privateSellTokensMinted, "Private sell tokens already minted");
        privateSellTokensMinted = true;
        _mint(msg.sender, privateSellTokens);
    }

    function mintForPublicSell() external onlyOwner {
        require(!publicSellTokensMinted, "Public sell tokens already minted");
        publicSellTokensMinted = true;
        _mint(msg.sender, publicSellTokens);
    }

    function mintForLiquidityPoll() external onlyOwner {
        require(
            !liquidityPoolTokensMinted,
            "Liquidity pool tokens already minted"
        );
        liquidityPoolTokensMinted = true;
        _mint(msg.sender, liquidityPoolTokens);
    }

    function mintForInGameRewards() external onlyOwner {
        require(
            !inGameRewardTokensMinted,
            "In game reward tokens already minted"
        );
        inGameRewardTokensMinted = true;
        _mint(msg.sender, inGameRewardTokens);
    }

    /**
     * @dev Modifier that checks to see if address who wants to mint has access
     */
    modifier verifyStakeMinter() {
        require(
            msg.sender == stakeMinter,
            "The minter is not the stake contract"
        );
        _;
    }

    /**
     * @dev Mint new tokens for a single NFT token
     * @param owner that will receive new minted tokens
     * @param token details for the NFT token
     */
    function mintNewToken(address owner, NFTDetails memory token)
        external
        override
        verifyStakeMinter
    {
        uint256 stakedTime = block.timestamp - token.stakeTime;

        uint256 reward = rewardPerSecond * stakedTime;
        uint256 rewardToken = rewardTokenPerSecond * stakedTime;
        uint256 rewardPosition = rewardStakePositionPerSecond * stakedTime;

        uint256 rewardTokenId = (rewardToken *
            (constantValue - token.tokenId * constantValue2)) / constantValue;
        uint256 rewardStakePosition = (rewardPosition *
            (constantValue - (token.stakePosition + 1) * constantValue2)) /
            constantValue;

        reward += rewardTokenId + rewardStakePosition;

        if (totalSupply() + reward > rewardStakeMax) {
            reward = rewardStakeMax - totalSupply();
        }
        require(reward > 0, "No rewards to mint");
        _mint(owner, reward);
    }

    /**
     * @dev Mint new tokens for multiple NFT tokens
     * @param owner that will receive new minted tokens
     * @param tokens details for the NFT tokens
     */
    function mintNewTokens(address owner, NFTDetails[] memory tokens)
        external
        override
        verifyStakeMinter
    {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            NFTDetails memory token = tokens[i];

            uint256 stakedTime = block.timestamp - token.stakeTime;

            uint256 reward = rewardPerSecond * stakedTime;
            uint256 rewardToken = rewardTokenPerSecond * stakedTime;
            uint256 rewardPosition = rewardStakePositionPerSecond * stakedTime;

            uint256 rewardTokenId = (rewardToken *
                (constantValue - token.tokenId * constantValue2)) /
                constantValue;
            uint256 rewardStakePosition = (rewardPosition *
                (constantValue - (token.stakePosition + 1) * constantValue2)) /
                constantValue;

            totalReward += reward + rewardTokenId + rewardStakePosition;
        }
        if (totalSupply() + totalReward > rewardStakeMax) {
            totalReward = rewardStakeMax - totalSupply();
        }
        require(totalReward > 0, "No rewards to mint");
        _mint(owner, totalReward);
    }
}