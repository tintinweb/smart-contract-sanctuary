/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
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

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
}

// File: @openzeppelin/contracts/utils/Address.sol

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

    function toString(address account) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(account)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

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

// File: @openzeppelin/contracts/utils/Context.sol
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol
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

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

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
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// File: @openzeppelin/contracts/access/Ownable.sol
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

    function set(Counter storage counter, uint256 value) internal {
        counter._value = value;
    }
}

pragma solidity ^0.8.0;

interface IWhitelisted {
    function whitelistedMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable;
    function whitelistedMint(address _to, bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable;
    function isWhitelisted(bytes32[] calldata _merkleProof) external view returns (bool);
    function isWhitelisted(address _user, bytes32[] calldata _merkleProof) external view returns (bool);
    function setWhitelistedCost(uint256 _newWhitelistedCost) external;
    function setWhitelistedRoot(bytes32 _newWhitelistedRoot) external;
}

interface IGiveaway {
    function giveawayMint(uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) external;
    function giveawayMint(address _to, uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) external;
    function giveawaysOf(address _to, uint256 _total, bytes32[] calldata _merkleProof) external view returns (uint256);
    function setGiveawayRoot(bytes32 _newGiveawayRoot) external;
}

interface IGames {
    function gameMint(address _to, uint256 _mintAmount) external;
    function gamesOf(address _to) external view returns (uint256);
    function addGames(address _to, uint256 _newGames) external;
    function removeGames(address _to, uint256 _newGames) external;
}

interface ILocking {
    function unlock(address _user, uint256 tokenId, uint256 code) external;
    function lock(address _user, uint256 tokenId, uint256 code) external;
    function isLocked(uint256 tokenId) external view returns (bool);
    function isLocked(address _user, uint256 tokenId) external view returns (bool);
    function lockedAt(uint256 tokenId) external view returns (uint256);
    function lockedAt(address _user, uint256 tokenId) external view returns (uint256);
    function lockedList() external view returns (uint256[] memory);
    function lockedList(address _user) external view returns (uint256[] memory);
    function setDisableLocks(bool _state) external;
    function locked(address _user, uint256 tokenId, uint256 code, bool _state) external;
}

interface IBanning {
    function isBanned(address _user) external view returns (bool);
    function banned(address _user, bool _state) external;
    function transferFromBanned(address _to, uint256 tokenId) external;
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HollywoodApesV2 is ERC721, Ownable, IWhitelisted, IGiveaway, IGames, ILocking, IBanning {
    using Address for address;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _totalSupply;

    string public baseURI;
    string public notRevealedUri;
    uint256 public cost = 0.08 ether;
    uint256 public whitelistedCost = 0.05 ether;
    uint256 public maxSupply = 9000;
    uint256 public revealed;
    bool public whitelistPaused = true;
    bool public giveawayPaused;
    bool public gamesPaused;
    bool public mintPaused = true;
    bool public exchangeOpen;
    bool public disableLocks;
    bytes32 public whitelistedRoot = 0xa6e4dad26037d78e4f5abac1b4b3cd9f941d30623c13526d8e8b1b2ba1341b57;
    bytes32 public giveawayRoot = 0x2d0c2d3aacc0f90995ef3aabbb7477db920b67ec8ce0b82ef0b49ec6e5f53db1;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    mapping(address => bool) private _banned;
    mapping(address => bool) private _diamonds;
    mapping(address => uint256) private _giveaways;
    mapping(address => uint256) private _games;
    mapping(address => mapping(uint256 => uint256)) private _lockedTime;
    mapping(address => mapping(uint256 => uint256)) private _lockedCode;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // private
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (msg.sender != owner()) {
            require(!isLocked(ownerOf(tokenId), tokenId), "token is locked");
            require(!isLocked(from, tokenId), "token is locked");
            require(!isBanned(from), "address is banned");
            require(!isBanned(to), "address is banned");
            require(!isBanned(ownerOf(tokenId)), "address is banned");

            if (!isDiamond(msg.sender)) {
                require(exchangeOpen, "transfers not allowed");
            }
        }

        super._transfer(from, to, tokenId);
    }

    function _fastMint(address _to, uint256 _mintAmount) private {
        uint256 current = _totalSupply.current();

        if (_mintAmount == 1) {
            _safeMint(_to, current + 1);
        } else if (_to.isContract()) {
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, current + i);
            }
        } else {
            for (uint256 i = 1; i <= _mintAmount; i++) {
                uint256 tokenId = current + i;

                _owners[tokenId] = _to;

                emit Transfer(address(0), _to, tokenId);
            }
            _balances[_to] += _mintAmount;
        }

        _totalSupply.set(current + _mintAmount);
    }

    function _setLocked(address _user, uint256 tokenId, uint256 code, bool _state) private {
        require(tokenId > 0, "invalid tokenId");
        require(
            ownerOf(tokenId) == _user,
            "lock of token that is not own"
        );

        if (_state && _lockedTime[_user][tokenId] == 0) {
            _lockedCode[_user][tokenId] = code;
            _lockedTime[_user][tokenId] = block.timestamp;
            _lockedTime[_user][0] += 1;
        } else if (!_state && _lockedTime[_user][tokenId] > 0) {
            require(_lockedCode[_user][tokenId] == code, "invalid code");

            _lockedTime[_user][tokenId] = 0;
            _lockedTime[_user][0] -= 1;
        }
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public payable
    function mint(uint256 _mintAmount) public payable {
        mint(msg.sender, _mintAmount);
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        require(!mintPaused, "the contract mint is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_totalSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner() && cost > 0) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        _fastMint(_to, _mintAmount);
    }

    function whitelistedMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public virtual override payable {
        whitelistedMint(msg.sender, _merkleProof, _mintAmount);
    }

    function whitelistedMint(address _to, bytes32[] calldata _merkleProof, uint256 _mintAmount) public virtual override payable {
        require(!whitelistPaused, "the contract whitelist mint is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_totalSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(isWhitelisted(_to, _merkleProof), "user is not whitelisted");

        if (whitelistedCost > 0) {
            require(msg.value >= whitelistedCost * _mintAmount, "insufficient funds");
        }

        _fastMint(_to, _mintAmount);
    }

    // public write
    function unlock(address _user, uint256 tokenId, uint256 code) public virtual override {
        _setLocked(_user, tokenId, code, false);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        if (msg.sender != owner()) {
            if (!isDiamond(msg.sender)) {
                require(exchangeOpen, "transfers not allowed");
            }
            require(!isLocked(ownerOf(tokenId), tokenId), "token is locked");
            require(!isLocked(msg.sender, tokenId), "token is locked");
            require(!isLocked(to, tokenId), "token is locked");
            require(!isBanned(msg.sender), "address is banned");
            require(!isBanned(ownerOf(tokenId)), "address is banned");
            require(!isBanned(to), "address is banned");
        }

        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (msg.sender != owner()) {
            if (!isDiamond(msg.sender)) {
                require(exchangeOpen, "transfers not allowed");
            }
            require(!isBanned(msg.sender), "address is banned");
            require(!isBanned(operator), "address is banned");
        }
        super.setApprovalForAll(operator, approved);
    }

    function giveawayMint(uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) public virtual override {
        giveawayMint(msg.sender, _total, _merkleProof, _mintAmount);
    }

    function giveawayMint(address _to, uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) public virtual override {
        require(!giveawayPaused, "the contract giveaway mint is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_totalSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(giveawaysOf(_to, _total, _merkleProof) >= _mintAmount, "insufficient giveaways");

        _giveaways[_to] += _mintAmount;

        _fastMint(_to, _mintAmount);
    }

    function gameMint(address _to, uint256 _mintAmount) public virtual override {
        require(!gamesPaused, "the contract games mint is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_totalSupply.current() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(_games[msg.sender] >= _mintAmount, "insufficient games");

        _games[msg.sender] -= _mintAmount;

        _fastMint(_to, _mintAmount);
    }

    function lock(address _user, uint256 tokenId, uint256 code) public virtual override {
        _setLocked(_user, tokenId, code, true);
    }

    // public view
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (msg.sender != owner()) {
            if (!isDiamond(msg.sender)) {
                require(exchangeOpen, "transfers not allowed");
            }
            require(!isLocked(ownerOf(tokenId), tokenId), "token is locked");
            require(!isLocked(msg.sender, tokenId), "token is locked");
            require(!isBanned(msg.sender), "address is banned");
            require(!isBanned(ownerOf(tokenId)), "address is banned");
        }

        return super.getApproved(tokenId);
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        if (msg.sender != owner() && _owner != owner()) {
            if (!isDiamond(msg.sender) && !isDiamond(_owner)) {
                require(exchangeOpen, "transfers not allowed");
            }

            if (isBanned(msg.sender) ||
                isBanned(_owner) ||
                isBanned(_operator)) {
                return false;
            }
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry) != address(0) && address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return isLocked(msg.sender, tokenId);
    }

    function isLocked(address _user, uint256 tokenId) public view virtual override returns (bool) {
        return !disableLocks && (_lockedTime[_user][tokenId] > 0);
    }

    function lockedAt(uint256 tokenId) public view virtual override returns (uint256) {
        return lockedAt(msg.sender, tokenId);
    }

    function lockedAt(address _user, uint256 tokenId) public view virtual override returns (uint256) {
        return _lockedTime[_user][tokenId];
    }

    function lockedList() public view virtual override returns (uint256[] memory) {
        return lockedList(msg.sender);
    }

    function lockedList(address _user) public view virtual override returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_lockedTime[_user][0]);
        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= 1000; tokenId++) {
            if (_lockedTime[_user][tokenId] > 0) {
                tokenIds[index] = tokenId;
                index++;
            }
        }
        return tokenIds;
    }

    function isBanned(address _user) public view virtual override returns (bool) {
        return _banned[_user];
    }

    function isDiamond(address _user) public view returns (bool) {
        return _diamonds[_user];
    }

    function isWhitelisted(bytes32[] calldata _merkleProof) public view virtual override returns (bool) {
        return isWhitelisted(msg.sender, _merkleProof);
    }

    function isWhitelisted(address _user, bytes32[] calldata _merkleProof) public view virtual override returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));

        return MerkleProof.verify(_merkleProof, whitelistedRoot, leaf);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed < tokenId) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        string memory baseExtension = ".json";
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function giveawaysOf(address _to, uint256 _total, bytes32[] calldata _merkleProof) public view virtual override returns (uint256) {
        require(
            _to != address(0),
            "giveaways query for the zero address"
        );

        bytes32 leaf = keccak256(abi.encodePacked(_to, _total));
        require(MerkleProof.verify(_merkleProof, giveawayRoot, leaf), "invalid proof");

        uint256 taken = _giveaways[_to];
        if (taken >= _total) {
            return 0;
        }

        return _total - taken;
    }

    function gamesOf(address _to) public view virtual override returns (uint256) {
        require(
            _to != address(0),
            "games query for the zero address"
        );
        return _games[_to];
    }

    // only owner
    function setRevealed(uint256 _newRevealed) public onlyOwner {
        revealed = _newRevealed;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setProxyRegistryAddress(address _newProxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _newProxyRegistryAddress;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistedCost(uint256 _newWhitelistedCost) public virtual override onlyOwner {
        whitelistedCost = _newWhitelistedCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setWhitelistPaused(bool _state) public onlyOwner {
        whitelistPaused = _state;
    }

    function setGiveawayPaused(bool _state) public onlyOwner {
        giveawayPaused = _state;
    }

    function setGamesPaused(bool _state) public onlyOwner {
        gamesPaused = _state;
    }

    function setMintPaused(bool _state) public onlyOwner {
        mintPaused = _state;
    }

    function setExchangeOpen(bool _state) public onlyOwner {
        exchangeOpen = _state;
    }

    function setDisableLocks(bool _state) public virtual override onlyOwner {
        disableLocks = _state;
    }

    function setWhitelistedRoot(bytes32 _newWhitelistedRoot) public virtual override onlyOwner {
        whitelistedRoot = _newWhitelistedRoot;
    }

    function setGiveawayRoot(bytes32 _newGiveawayRoot) public virtual override onlyOwner {
        giveawayRoot = _newGiveawayRoot;
    }

    function locked(address _user, uint256 tokenId, uint256 code, bool _state) public virtual override onlyOwner {
        _setLocked(_user, tokenId, _state ? code : _lockedCode[_user][tokenId], _state);
    }

    function banned(address _user, bool _state) public virtual override onlyOwner {
        _banned[_user] = _state;
    }

    function diamonds(address _user, bool _state) public onlyOwner {
        _diamonds[_user] = _state;
    }

    function diamonds(address[] memory _users, bool _state) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            _diamonds[_users[i]] = _state;
        }
    }

    function transferFromBanned(address _to, uint256 tokenId) public virtual override onlyOwner {
        address from = ownerOf(tokenId);
        require(isBanned(from), "address is not banned");

        super._transfer(from, _to, tokenId);
    }

    function transferFromSelf(address to, uint256 tokenId) public onlyOwner {
        super._safeTransfer(msg.sender, to, tokenId, "");
    }

    function addGames(address _to, uint256 _newGames) public virtual override onlyOwner {
        require(
            _to != address(0),
            "add games for the zero address"
        );
        _games[_to] += _newGames;
    }

    function removeGames(address _to, uint256 _newGames) public virtual override onlyOwner {
        require(
            _to != address(0),
            "remove games for the zero address"
        );
        _games[_to] -= _newGames;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}