/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File contracts/core/NFTeacket.sol
pragma solidity ^0.8.4;

contract NFTeacket is ERC721 {
    enum TicketType {
        Maker,
        Taker
    }

    enum OptionType {
        CallBuy,
        CallSale,
        PutBuy,
        PutSale
    }

    struct OptionDataMaker {
        uint256 price; // The price of the option
        uint256 strike; // The strike price of the option
        uint256 settlementTimestamp; // The maturity timestamp of the option
        uint256 takerTicketId; // The taker ticket ID of this order
        uint256 nftId; // The nft token ID of the option
        address nftContract; // The smart contract address of the nft
        OptionType optionType; // Type of the option
    }

    struct OptionDataTaker {
        uint256 makerTicketId;
    }

    /// @dev The NFTea contract
    address public nftea;

    /// @dev Token ids to ticket type
    mapping(uint256 => TicketType) _ticketIdToType;

    /// @dev Token ids to OptionDataMaker
    mapping(uint256 => OptionDataMaker) private _ticketIdToOptionDataMaker;

    /// @dev Token ids to OptionDataTaker
    mapping(uint256 => OptionDataTaker) private _ticketIdToOptionDataTaker;

    /// @dev The current nft counter to get next available id
    uint256 private _counter;

    modifier onylyFromNFTea() {
        require(msg.sender == nftea, "NFTeacket: not called from nftea");
        _;
    }

    constructor(address _nftea) ERC721("NFTeacket", "NBOT") {
        nftea = _nftea;
    }

    /// @notice Mint a maker ticket NFT associated with the given option offer
    /// @param to adress to mint a ticket to
    /// @param data option data to store in the ticket
    function mintMakerTicket(address to, OptionDataMaker memory data)
        external
        onylyFromNFTea
        returns (uint256 ticketId)
    {
        ticketId = _counter++;
        _safeMint(to, ticketId);
        _ticketIdToOptionDataMaker[ticketId] = data;
        _ticketIdToType[ticketId] = TicketType.Maker;
    }

    /// @notice Mint a taker ticket NFT associated with the given option offer
    /// @param to adress to mint a ticket to
    /// @param data option data to store in the ticket
    /// @dev No need to check that the maker icket referenced in the data params
    /// actually exists since it's already ensure in the NFTea caller contract
    function mintTakerTicket(address to, OptionDataTaker memory data)
        public
        onylyFromNFTea
        returns (uint256 ticketId)
    {
        ticketId = _counter++;
        _safeMint(to, ticketId);
        _ticketIdToOptionDataTaker[ticketId] = data;
        _ticketIdToType[ticketId] = TicketType.Taker;
    }

    /// @notice Return if the ticker is a Maker or a Taker
    /// @param ticketId the ticket id
    function ticketIdToType(uint256 ticketId) public view returns (TicketType) {
        require(_exists(ticketId), "NFTeacket: ticket does not exist");
        return _ticketIdToType[ticketId];
    }

    /// @notice return the maker option data associated with the ticket
    /// @param ticketId the ticket id
    function ticketIdToOptionDataMaker(uint256 ticketId)
        external
        view
        returns (OptionDataMaker memory)
    {
        require(
            ticketIdToType(ticketId) == TicketType.Maker,
            "NFTeacket: Not a maker ticket"
        );
        return _ticketIdToOptionDataMaker[ticketId];
    }

    /// @notice return the taker option data associated with the ticket
    /// @param ticketId the ticket id
    function ticketIdToOptionDataTaker(uint256 ticketId)
        external
        view
        returns (OptionDataTaker memory)
    {
        require(
            ticketIdToType(ticketId) == TicketType.Taker,
            "NFTeacket: Not a taker ticket"
        );
        return _ticketIdToOptionDataTaker[ticketId];
    }

    /// @notice Link the maker ticket with the tacker ticket
    /// @param makerTicketId the maker ticket id
    /// @param takerTicketId the taker ticket id
    /// @dev No need to check that the maker and taker tickets exists since it's already ensure
    /// on the NFTea caller contract
    function linkMakerToTakerTicket(
        uint256 makerTicketId,
        uint256 takerTicketId
    ) external onylyFromNFTea {
        _ticketIdToOptionDataMaker[makerTicketId].takerTicketId = takerTicketId;
    }

    /// @notice Burn the ticket
    /// @param ticketId the ticket id
    function burnTicket(uint256 ticketId) external onylyFromNFTea {
        this.ticketIdToType(ticketId) == TicketType.Maker
            ? delete _ticketIdToOptionDataMaker[ticketId]
            : delete _ticketIdToOptionDataTaker[ticketId];

        delete _ticketIdToType[ticketId];

        _burn(ticketId);
    }
}

// File contracts/core/NFTea.sol
pragma solidity ^0.8.4;

contract NFTea {
    event OrderCreated(uint256 makerTicketId, NFTeacket.OptionDataMaker data);
    event OrderCancelled(uint256 makerTicketId);
    event OrderFilled(uint256 takerTicketId, NFTeacket.OptionDataTaker data);
    event OptionUsed(uint256 makerTicketId, bool value);

    address public admin;
    address public nfteacket;

    uint256 public maxDelayToClaim;
    uint256 public optionFees;
    uint256 public saleFees;

    modifier onlyAdmin() {
        require(msg.sender == admin, "NFTea: not admin");
        _;
    }

    modifier onlyWhenNFTeacketSet() {
        require(nfteacket != address(0), "NFTea: nfteacket not set");
        _;
    }

    constructor() {
        admin = msg.sender;
        optionFees = 3;
        saleFees = 1;
        maxDelayToClaim = 1 days;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setMaxDelayToClaim(uint256 delay) external onlyAdmin {
        maxDelayToClaim = delay;
    }

    function setOptionFees(uint256 fee) external onlyAdmin {
        require(fee < 100, "NFTea: incorret fee value");
        optionFees = fee;
    }

    function setSaleFees(uint256 fee) external onlyAdmin {
        require(fee < 100, "NFTea: incorret fee value");
        saleFees = fee;
    }

    function collectFees() external onlyAdmin {
        _transferEth(msg.sender, address(this).balance);
    }

    function setNFTeacket(address _nfteacket) external onlyAdmin {
        nfteacket = _nfteacket;
    }

    /// @notice Create an option order for a given NFT
    /// @param optionPrice the price of the option
    /// @param strikePrice the strike price of the option
    /// @param settlementTimestamp the option maturity timestamp
    /// @param nftId the token ID of the NFT relevant of this order
    /// @param nftContract the address of the NFT contract
    /// @param optionType the type of the option (CallBuy, CallSale, PutBuy or PutSale)
    function makeOrder(
        uint256 optionPrice,
        uint256 strikePrice,
        uint256 settlementTimestamp,
        uint256 nftId,
        address nftContract,
        NFTeacket.OptionType optionType
    ) external payable onlyWhenNFTeacketSet {
        require(
            settlementTimestamp > block.timestamp,
            "NFTea: Incorrect timestamp"
        );

        if (optionType == NFTeacket.OptionType.CallBuy) {
            _requireEthSent(optionPrice);
        } else if (optionType == NFTeacket.OptionType.CallSale) {
            _requireEthSent(0);
            _lockNft(nftId, nftContract);
        } else if (optionType == NFTeacket.OptionType.PutBuy) {
            _requireEthSent(optionPrice);
        } else {
            // OptionType.Putsale
            _requireEthSent(strikePrice);
        }

        NFTeacket.OptionDataMaker memory data = NFTeacket.OptionDataMaker({
            price: optionPrice,
            strike: strikePrice,
            settlementTimestamp: settlementTimestamp,
            nftId: nftId,
            nftContract: nftContract,
            takerTicketId: 0,
            optionType: optionType
        });

        uint256 makerTicketId = NFTeacket(nfteacket).mintMakerTicket(
            msg.sender,
            data
        );

        emit OrderCreated(makerTicketId, data);
    }

    /// @notice Cancel a non filled order
    /// @param makerTicketId the ticket ID associated with the order
    function cancelOrder(uint256 makerTicketId) external onlyWhenNFTeacketSet {
        NFTeacket _nfteacket = NFTeacket(nfteacket);

        // Check the seender is the maker
        _requireTicketOwner(msg.sender, makerTicketId);

        NFTeacket.OptionDataMaker memory optionData = _nfteacket
            .ticketIdToOptionDataMaker(makerTicketId);

        require(optionData.takerTicketId == 0, "NFTea: Order already filled");

        if (optionData.optionType == NFTeacket.OptionType.CallBuy) {
            _transferEth(msg.sender, optionData.price);
        } else if (optionData.optionType == NFTeacket.OptionType.CallSale) {
            _transferNft(
                address(this),
                msg.sender,
                optionData.nftId,
                optionData.nftContract
            );
        } else if (optionData.optionType == NFTeacket.OptionType.PutBuy) {
            _transferEth(msg.sender, optionData.price);
        } else {
            // OptionType.Putsale
            _transferEth(msg.sender, optionData.strike);
        }

        _nfteacket.burnTicket(makerTicketId);

        emit OrderCancelled(makerTicketId);
    }

    /// @notice Fill a given option order
    /// @param makerTicketId the corresponding order identified by its ticket ID
    function fillOrder(uint256 makerTicketId)
        external
        payable
        onlyWhenNFTeacketSet
    {
        NFTeacket _nfteacket = NFTeacket(nfteacket);

        NFTeacket.OptionDataMaker memory optionData = _nfteacket
            .ticketIdToOptionDataMaker(makerTicketId);

        uint256 optionPriceSubFees = (optionData.price * (100 - optionFees)) /
            100;

        require(
            block.timestamp < optionData.settlementTimestamp,
            "NFTea: Obsolete order"
        );

        require(optionData.takerTicketId == 0, "NFTea: Order already filled");

        if (optionData.optionType == NFTeacket.OptionType.CallBuy) {
            _requireEthSent(0);
            _lockNft(optionData.nftId, optionData.nftContract);

            // Pay the taker for selling the call to the maker
            _transferEth(msg.sender, optionPriceSubFees);
        } else if (optionData.optionType == NFTeacket.OptionType.CallSale) {
            _requireEthSent(optionData.price);

            // Pay the maker for selling the call to the taker
            address maker = _nfteacket.ownerOf(makerTicketId);
            _transferEth(maker, optionPriceSubFees);
        } else if (optionData.optionType == NFTeacket.OptionType.PutBuy) {
            _requireEthSent(optionData.strike);

            // Pay the taker for selling the put to the maker
            _transferEth(msg.sender, optionPriceSubFees);
        } else {
            // OptionType.Putsale
            _requireEthSent(optionData.price);

            // Pay the maker for selling the put to the taker
            address maker = _nfteacket.ownerOf(makerTicketId);
            _transferEth(maker, optionPriceSubFees);
        }

        NFTeacket.OptionDataTaker memory data = NFTeacket.OptionDataTaker({
            makerTicketId: makerTicketId
        });

        uint256 takerTicketId = _nfteacket.mintTakerTicket(msg.sender, data);

        _nfteacket.linkMakerToTakerTicket(makerTicketId, takerTicketId);

        emit OrderFilled(takerTicketId, data);
    }

    /// @notice Allow a buyer to use his right to either buy or sale at the registered strike price
    /// @param ticketId The buyer ticket
    function useBuyerRightAtMaturity(uint256 ticketId)
        external
        payable
        onlyWhenNFTeacketSet
    {
        NFTeacket _nfteacket = NFTeacket(nfteacket);

        _requireTicketOwner(msg.sender, ticketId);

        NFTeacket.OptionDataMaker memory makerOptionData;
        uint256 makerTicketId;
        address ethReceiver;
        address nftReceiver;
        address nftSender;

        // Get the ticket type
        NFTeacket.TicketType ticketType = _nfteacket.ticketIdToType(ticketId);

        // If buyer is the maker
        if (ticketType == NFTeacket.TicketType.Maker) {
            makerOptionData = _nfteacket.ticketIdToOptionDataMaker(ticketId);

            makerTicketId = ticketId;

            address taker = _nfteacket.ownerOf(makerOptionData.takerTicketId);

            if (makerOptionData.optionType == NFTeacket.OptionType.CallBuy) {
                // When using call buy right, msg.value must be the strike price
                _requireEthSent(makerOptionData.strike);

                ethReceiver = taker;
                nftSender = address(this);
                nftReceiver = msg.sender;
            } else if (
                makerOptionData.optionType == NFTeacket.OptionType.PutBuy
            ) {
                // When using put buy right, msg.value must be 0
                _requireEthSent(0);

                ethReceiver = msg.sender;
                nftSender = msg.sender;
                nftReceiver = taker;
            } else {
                revert("NFTea: Not a buyer");
            }
        } else {
            // If buyer is the taker
            NFTeacket.OptionDataTaker memory takerOptionData = _nfteacket
                .ticketIdToOptionDataTaker(ticketId);

            makerOptionData = _nfteacket.ticketIdToOptionDataMaker(
                takerOptionData.makerTicketId
            );

            makerTicketId = takerOptionData.makerTicketId;

            address maker = _nfteacket.ownerOf(takerOptionData.makerTicketId);

            if (makerOptionData.optionType == NFTeacket.OptionType.CallSale) {
                // When using call buy right, msg.value must be the strike price
                _requireEthSent(makerOptionData.strike);

                ethReceiver = maker;
                nftSender = address(this);
                nftReceiver = msg.sender;
            } else if (
                makerOptionData.optionType == NFTeacket.OptionType.PutSale
            ) {
                // When using put buy right, msg.value must be 0
                _requireEthSent(0);

                ethReceiver = msg.sender;
                nftSender = msg.sender;
                nftReceiver = maker;
            } else {
                revert("NFTea: Not a buyer");
            }
        }

        // Ensure we are at timestamp such that settlement <= timestamp < settlement + maxDelayToClaim
        require(
            block.timestamp >= makerOptionData.settlementTimestamp &&
                block.timestamp <
                makerOptionData.settlementTimestamp + maxDelayToClaim,
            "NFTea: Can't use buyer right"
        );

        uint256 strikePriceSubFees = (makerOptionData.strike *
            (100 - saleFees)) / 100;

        // Swap NFT with ETH
        _transferEth(ethReceiver, strikePriceSubFees);
        _transferNft(
            nftSender,
            nftReceiver,
            makerOptionData.nftId,
            makerOptionData.nftContract
        );

        // Burn maker and taker tickets
        _nfteacket.burnTicket(makerTicketId);
        _nfteacket.burnTicket(makerOptionData.takerTicketId);

        emit OptionUsed(makerTicketId, true);
    }

    /// @notice Allow a seller to withdraw his locked collateral at maturity
    /// @param ticketId The seller ticket
    function withdrawLockedCollateralAtMaturity(uint256 ticketId)
        external
        onlyWhenNFTeacketSet
    {
        NFTeacket _nfteacket = NFTeacket(nfteacket);

        _requireTicketOwner(msg.sender, ticketId);

        NFTeacket.TicketType ticketType = _nfteacket.ticketIdToType(ticketId);

        NFTeacket.OptionDataMaker memory makerOptionData;
        uint256 makerTicketId;
        bool withdrawSucceed;

        // If seller is the maker
        if (ticketType == NFTeacket.TicketType.Maker) {
            makerOptionData = _nfteacket.ticketIdToOptionDataMaker(ticketId);
            makerTicketId = ticketId;

            // Ensure we are at timestamp >= settlement + maxDelayToClaim
            require(
                block.timestamp >=
                    makerOptionData.settlementTimestamp + maxDelayToClaim,
                "NFTea: Can't withdraw collateral now"
            );

            if (makerOptionData.optionType == NFTeacket.OptionType.CallSale) {
                _transferNft(
                    address(this),
                    msg.sender,
                    makerOptionData.nftId,
                    makerOptionData.nftContract
                );
                withdrawSucceed = true;
            } else if (
                makerOptionData.optionType == NFTeacket.OptionType.PutSale
            ) {
                _transferEth(msg.sender, makerOptionData.strike);
                withdrawSucceed = true;
            } else {
                withdrawSucceed = false;
            }
        } else {
            // If seller is the taker
            NFTeacket.OptionDataTaker memory takerOptionData = _nfteacket
                .ticketIdToOptionDataTaker(ticketId);

            makerOptionData = _nfteacket.ticketIdToOptionDataMaker(
                takerOptionData.makerTicketId
            );

            makerTicketId = takerOptionData.makerTicketId;

            // Ensure we are at timestamp >= settlement + maxDelayToClaim
            require(
                block.timestamp >=
                    makerOptionData.settlementTimestamp + maxDelayToClaim,
                "NFTea: Can't withdraw collateral now"
            );

            if (makerOptionData.optionType == NFTeacket.OptionType.CallBuy) {
                _transferNft(
                    address(this),
                    msg.sender,
                    makerOptionData.nftId,
                    makerOptionData.nftContract
                );
                withdrawSucceed = true;
            } else if (
                makerOptionData.optionType == NFTeacket.OptionType.PutBuy
            ) {
                _transferEth(msg.sender, makerOptionData.strike);
                withdrawSucceed = true;
            } else {
                withdrawSucceed = false;
            }
        }

        if (withdrawSucceed) {
            // Burn maker and taker tickets
            _nfteacket.burnTicket(makerTicketId);
            _nfteacket.burnTicket(makerOptionData.takerTicketId);

            emit OptionUsed(makerTicketId, false);
        } else {
            revert("NFTea: Not a seller");
        }
    }

    /// @param spender the address that claims to be the ticket owner
    /// @param ticketId the option ticket id
    function _requireTicketOwner(address spender, uint256 ticketId)
        private
        view
    {
        address owner = NFTeacket(nfteacket).ownerOf(ticketId);
        require(owner == spender, "NFTea: Not ticket owner");
    }

    /// @dev ETH needs to be sent if the maker is
    ///  - buying a call : he needs to send the option price
    ///  - buying a put : he needs to send the option price
    ///  - selling a call : he needs to send the strike price
    /// @param amount the amount required to be sent by the trader
    function _requireEthSent(uint256 amount) private view {
        require(msg.value == amount, "NFTea: Incorrect sent ETH amount");
    }

    /// @dev When a trader wants to sell a call, he has to lock his NFT
    /// until maturity
    /// @param nftId the token ID of the NFT to lock
    /// @param nftContractAddress address of the NFT contract
    function _lockNft(uint256 nftId, address nftContractAddress) private {
        IERC721 nftContract = IERC721(nftContractAddress);
        address owner = nftContract.ownerOf(nftId);

        require(owner == msg.sender, "NFTea : Not nft owner");

        require(
            address(this) == owner ||
                nftContract.getApproved(nftId) == address(this) ||
                nftContract.isApprovedForAll(owner, address(this)),
            "NFTea : Contract not approved, can't lock nft"
        );

        // Lock the nft by transfering it to the contract
        nftContract.transferFrom(msg.sender, address(this), nftId);
    }

    function _transferNft(
        address from,
        address to,
        uint256 nftId,
        address nft
    ) private {
        IERC721 nftContract = IERC721(nft);
        nftContract.transferFrom(from, to, nftId);
    }

    /// @dev    Safely transfer amount ethereum to the target
    /// @param to the target wallet to send eth to
    /// @param amount the amount of eth to send
    function _transferEth(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        require(success, "NFTea: Eth transfer failed");
    }
}

// File contracts/test/CustomErc721.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract CustomERC721 is ERC721 {
    uint256 private _counter;

    constructor() ERC721("CustomERC721", "NFK") {}

    function mint(address to) public {
        uint256 tokenId = _counter++;
        _safeMint(to, tokenId);
    }
}