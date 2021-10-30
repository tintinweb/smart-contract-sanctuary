/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: MIT


/* 

contract created by
                          __                                                    __ 
                         |  \                                                  |  \
 ______ ____    ______  _| $$_     ______    _______   ______    ______    ____| $$
|      \    \  /      \|   $$ \   |      \  /       \ /      \  /      \  /      $$
| $$$$$$\$$$$\|  $$$$$$\\$$$$$$    \$$$$$$\|  $$$$$$$|  $$$$$$\|  $$$$$$\|  $$$$$$$
| $$ | $$ | $$| $$    $$ | $$ __  /      $$ \$$    \ | $$    $$| $$    $$| $$  | $$
| $$ | $$ | $$| $$$$$$$$ | $$|  \|  $$$$$$$ _\$$$$$$\| $$$$$$$$| $$$$$$$$| $$__| $$
| $$ | $$ | $$ \$$     \  \$$  $$ \$$    $$|       $$ \$$     \ \$$     \ \$$    $$
 \$$  \$$  \$$  \$$$$$$$   \$$$$   \$$$$$$$ \$$$$$$$   \$$$$$$$  \$$$$$$$  \$$$$$$$
                                                                                  
                     __  __                        __      __                      
                    |  \|  \                      |  \    |  \                     
  _______   ______  | $$| $$  ______    _______  _| $$_    \$$ __     __   ______  
 /       \ /      \ | $$| $$ /      \  /       \|   $$ \  |  \|  \   /  \ /      \ 
|  $$$$$$$|  $$$$$$\| $$| $$|  $$$$$$\|  $$$$$$$ \$$$$$$  | $$ \$$\ /  $$|  $$$$$$\
| $$      | $$  | $$| $$| $$| $$    $$| $$        | $$ __ | $$  \$$\  $$ | $$    $$
| $$_____ | $$__/ $$| $$| $$| $$$$$$$$| $$_____   | $$|  \| $$   \$$ $$  | $$$$$$$$
 \$$     \ \$$    $$| $$| $$ \$$     \ \$$     \   \$$  $$| $$    \$$$    \$$     \
  \$$$$$$$  \$$$$$$  \$$ \$$  \$$$$$$$  \$$$$$$$    \$$$$  \$$     \$      \$$$$$$$


NFT Collective for Artists, Builders & Collectors
https://metaseed.art
 
*/                                                              

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721Receiver.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\extensions\IERC721Metadata.sol

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

// File: node_modules\openzeppelin-solidity\contracts\utils\Address.sol

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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

        // solhint-disable-next-line avoid-low-level-calls
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

        // solhint-disable-next-line avoid-low-level-calls
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

        // solhint-disable-next-line avoid-low-level-calls
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

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: node_modules\openzeppelin-solidity\contracts\utils\Strings.sol

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: node_modules\openzeppelin-solidity\contracts\utils\introspection\ERC165.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\ERC721.sol

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
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\extensions\IERC721Enumerable.sol

pragma solidity ^0.8.0;

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

// File: openzeppelin-solidity\contracts\token\ERC721\extensions\ERC721Enumerable.sol

pragma solidity ^0.8.0;

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
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
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
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// File: contracts\lib\Counters.sol

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
        {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        {
            counter._value = value - 1;
        }
    }
}

// File: openzeppelin-solidity\contracts\access\Ownable.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.8.0;

contract LETTERS is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant LETTERS_PUBLIC = 1000;
    uint256 public constant LETTERS_MAX = LETTERS_PUBLIC;
    uint256 public constant PURCHASE_LIMIT = 1;
    uint256 public allowListMaxMint = 1;
    uint256 public constant PRICE = 100_000_000_000_000_000; // 0.1 ETH
    string private _contractURI = "";
    string private _tokenBaseURI = "";
    bool private _isActive = false;
    bool public isAllowListActive = false;
    
    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;
    
    Counters.Counter private _publicLETTERS;

    constructor() ERC721("Letters", "LETTERS") {
        _allowList[0x7BF0688Fc3ab0CFdD00E48673b3A0D6128DF33Dc]=true;
        _allowList[0xc28FA41bcc3964Fa784e2793e3915FE4d4dF8d3E]=true;
        _allowList[0x13Fd300cd3E3DB045Fd420dDB3030eE55108Db4E]=true;
        _allowList[0x83002509A1836cE8030041FeB36C9D15511423F1]=true;
        _allowList[0x36Fa11f6715A5E440871F531030Ee4E94d7B9309]=true;
        _allowList[0x69a2D7D53e07E31b184196C895b02620d0Ab0104]=true;
        _allowList[0xC8932B5B7a6994A7f82087c4D6E8c8D67E6feE5C]=true;
        _allowList[0xCEB992E5e82C718491f776299d4fe775D9214147]=true;
        _allowList[0xFc1dF48328D4BAe087899072f0f5f8031BC38fff]=true;
        _allowList[0x8b01553BcE7f63864058Dc632A25F2b0F56810c2]=true;
        _allowList[0x5C41BE79c5af91cC019d94E6cF0C999f746136Db]=true;
        _allowList[0xfc981edae4d567e530f827ec7fED3307C484C5B6]=true;
        _allowList[0xab7b9801568A05A44E6E3Bb626B27030C763479a]=true;
        _allowList[0xB5A2370E6e741c6A12c40E6FF8FC6852D38e88cE]=true;
        _allowList[0x61fAE2d53Ce42D87a089753c55C2d26309F0A89f]=true;
        _allowList[0x370F2b7Cb212617ef1353BB20E8E66dc5950374f]=true;
        _allowList[0xA764E937556B742a88723Bb6c8B269B26dAe742A]=true;
        _allowList[0x6A69Efe85FE9AEdfaE63d67C8Cc354349B7ef89C]=true;
        _allowList[0xeb2B62Ca1d4A59d601fc46c652D56ADFb065Ce4F]=true;
        _allowList[0xc49a570a3A3ce48085E869F53f6511babD9c2CcD]=true;
        _allowList[0xFbb63846776982dAcD4BA710501F93c3073040fC]=true;
        _allowList[0xAA65f742193953DAf7703a5EEAf7406c0F6b9137]=true;
        _allowList[0x466AbBfb9AAb4C6dF6d3Cc03D6C63C43C5162048]=true;
        _allowList[0x803028dD9D3B5FC1b12e48B4f3F4218cc6470146]=true;
        _allowList[0xbf99402420AD0cB4091ffE8AB37314785EffE64F]=true;
        _allowList[0xA227B5ef06410639D4985d6be693352B71b8A165]=true;
        _allowList[0x1721E4489fE2b2A9a8c95256028e7f3025c50569]=true;
        _allowList[0x56543717d994D09D5862AB9c6f99bCe964AE664a]=true;
        _allowList[0x23CcD60bcC6457c634C977534948928983ebc2DB]=true;
        _allowList[0xE6ceF3226E19A5bBf2b4310A242AB1b9692E4A15]=true;
        _allowList[0x65EA52776ab213971ACD173013Ca5EEb8F7202bc]=true;
        _allowList[0x4660fBB1E7C72AbDdCf4d90B244887e3521AD3b2]=true;
        _allowList[0x51bB62F1753C741D717D74E1BC435903E42e42EC]=true;
        _allowList[0x3F4373aFdde3D7dE3AC433AcC7De685338c3980e]=true;
        _allowList[0xbAabA45DcabD9DDC8C81ad246aA7aE92964F0C81]=true;
        _allowList[0x023d8c2F6374F61B943F1dEf2A910197bb653858]=true;
        _allowList[0xFDb4cCdfDcD5aE3E45e85945E2e19ABD3F422D9e]=true;
        _allowList[0xEbA1184a59cA067286ab492165E0AaC51A6ff3C9]=true;
        _allowList[0xaF2E919B59734B8d99F6Bc1f62Dc63d6519d14BC]=true;
        _allowList[0xB709Dd16453CcD67fA15F9BDDa00a02751dfac9b]=true;
        _allowList[0x7255FE6f25ecaED72E85338c131D0daA60724Ecc]=true;
        _allowList[0x5219DA43dad677892a4c009c0B610FB189d06963]=true;
        _allowList[0x23da856b31F486A6c39DA1E12c3CB49dC33231B7]=true;
        _allowList[0xa25DAcCF7bacd8c229B3f8C59a314496Ae642F5C]=true;
        _allowList[0x31Aabd64819175430a21B23FA8e57d4cE00BD6e1]=true;
        _allowList[0x881a5E8Ace5Cb2cd72b135bEC25d9A94Df3d5413]=true;
        _allowList[0x628eA111406A68f4EC00cA3587843Ef0058BA6f3]=true;
        _allowList[0x18A4EBeEA97AAF45d7dE8c248b09AB9c25BC1906]=true;
        _allowList[0x67066F901022fDFC4b11b3bee59e9A0fdAdE7Efb]=true;
        _allowList[0x41AF923750584fE213955b2FC707717fB4Adb256]=true;
        _allowList[0xAa847D567d6968E59D1CAb8b1feA6897A21fAAee]=true;
        _allowList[0xd461c0E84C98650B7d573Cb7cDd3d7E0bA402E6b]=true;
        _allowList[0x22d0794A82EEBdd10245C2d162951eB1CA6FA58b]=true;
        _allowList[0xb2e0e159aE208aE1a16247321949CdA20da75e62]=true;
        _allowList[0x646020747321527ff22Ad17CA6A6aA139cd0BA54]=true;
        _allowList[0x39b15858d4585D24Fc37beE690d6A102F9a1FF90]=true;
        _allowList[0xead6365C2926006faCfE0411db42702888722453]=true;
        _allowList[0x774eEd784BD501BaCD7cC9FF9De185D96c04Bd51]=true;
        _allowList[0x99F607CffdA434Eed851EE5f25Bf34F463A78657]=true;
        _allowList[0x18Fc8940309C4F58806A67C101aFe0d3bD16E424]=true;
        _allowList[0x5011f2a7E9e6A41b7c8d68d2AFF6529E6e167d7d]=true;
        _allowList[0xFc84F9cE5A0BA010344D690f849988FA033031a5]=true;
        _allowList[0x049E4649Ac8b41c5E5b4c26212476f9E5490A034]=true;
        _allowList[0x1E8C0cCf25c2AF914FCCB659808ae196eCB93b6A]=true;
        _allowList[0xC93C4593A7D55b08f48b8b416fBf9f631912e2C9]=true;
        _allowList[0x7D75881e214Ba08b7595BEcc4F62168F71e49d64]=true;
        _allowList[0x2a3B3AB29E88310F48739E77D008DbB0940c01A0]=true;
        _allowList[0xD05d113669355CBe5AC7c4e466eAa9E3e87e8054]=true;
        _allowList[0xb767D67b5b5AF28BEB0b760cA38169ac508B8D6e]=true;
        _allowList[0xf19F1C9b5985A3e1B999E95Ba3CC4f591a2dC019]=true;
        _allowList[0x3406dC6A8e01Eefd44C8623AaB704Bb60e074743]=true;
        _allowList[0xcFeee429a333Afcf89E6Ae5BCCaf9aDb01AbA6EB]=true;
        _allowList[0xEDcF12b46f57207Ec537Eb73C4E2C103A32B233A]=true;
        _allowList[0x66C22847026859dA04EF475113a58576d1347845]=true;
        _allowList[0xF1d2706250B4A5C0c42bdce5025ef5a1E2F90293]=true;
        _allowList[0xdd8406BF72fe27bfff96530aF5348F20bAB300B5]=true;
        _allowList[0x0775a23372a9A1572B2138f0eb5069A60f6b8b05]=true;
        _allowList[0x3dA954C2e7a494e25102Fd11910223849FeA9B77]=true;
        _allowList[0xCc6D4546F57Ae7d37A2acb17D07228e0d8439e6c]=true;
        _allowList[0xDff71A881a17737b6942FE1542F4b88128eA57D8]=true;
        _allowList[0xd116a6edAaA77Bb0B9d758C8E8d705b3908D9353]=true;
        _allowList[0x190F49C0F92a2C10aca57108B8ccD49416c22d25]=true;
        _allowList[0x1a98347250498531758446aC22E605dceb46005c]=true;
        _allowList[0x5fe91B15F8b9a2B305628Cd49a686d6A0ca81e81]=true;
        _allowList[0x85951C90CabFd076db3095B705A7B1A5DFDb31e4]=true;
        _allowList[0xb988c18408Ea94139BE704fEc1CF9350d2A0B1e1]=true;
        _allowList[0x6f96A08D5CCFE4c9712670dC17a0118441CC621d]=true;
        _allowList[0x3D7f2165d3d54eAF9F6af52fd8D91669D4E02ebC]=true;
        _allowList[0xebFbb1233FdE916F2744cD3784a5D1581f2661B3]=true;
        _allowList[0x21bd72a7e219B836680201c25B61a4AA407F7bfD]=true;
        _allowList[0xeaF7814CDf7236Bc5992D19CC455F9C92B00AA9e]=true;
        _allowList[0x30c381EeB974C11B639e5e932b58044F08BAf737]=true;
        _allowList[0xd79586309A9790A0546989624a96439c4Be9abd5]=true;
        _allowList[0xEbf5feF7946d95880f4d1B298F70F7F1bF552a9E]=true;
        _allowList[0x5022cF478c7124d508Ab4A304946Cb4Fa3d9C39e]=true;
        _allowList[0x167B563eDAA56407CA8602562C7e2e38a87e674F]=true;
        _allowList[0xe7703b16eF7cd803FF46703172Ef402f07A0ebb2]=true;
        _allowList[0x20905a56858AF03DdB80B32c9FE26E96093edcB5]=true;
        _allowList[0xeed1F8E56932beA3e77e996710e1524fc642FCFa]=true;
        _allowList[0x9644A0B2A8e1f56C82b20E6ef3f71aec1EC2aB6B]=true;
        _allowList[0xEd74e8cE17F2dFf13d801583c70f5e9a1aCE5d6d]=true;
        _allowList[0x7313a2E1460e41D6A1eF20CFd5c6F702a8651551]=true;
        _allowList[0x07b2cFB7674876fb34EeeD3248E99Bc63d238F91]=true;
        _allowList[0x586D9F26695465e57f34930E2fE9AE1CF07367Ab]=true;
        _allowList[0x9BE947791880718A2A0D5baf6EA8b883948eEbe4]=true;
        _allowList[0x56f210974e0Ac548cF75c6034f1C0aa515c818df]=true;
        _allowList[0xBe9Dff4A9E1b1BE116172854F3b5680b4d225E35]=true;
        _allowList[0x7DD3666633b25d8CC5C68cbfdF3907F443DAe5c7]=true;
        _allowList[0x2B4b676397A75746b77b2F5999f106929174fC01]=true;
        _allowList[0xFE15f7adBc591fe2Af5736231e791D469F64Ae26]=true;
        _allowList[0x439016804a0F0A9B5cBaf82461573Ca0A5e38e88]=true;
        _allowList[0xd5e5d602aDb31A00D90FEa6d6CcA4d085C9252dc]=true;
        _allowList[0xdc1036CB9B138A0206aa567BDE08D50b81Ee4091]=true;
        _allowList[0x3326AA7595DFeb4aa163391Ef49fd8e7DAD771dd]=true;
        _allowList[0x3A0A8ECD310C23E909f7ca96E0b7Ec42d2C4a957]=true;
        _allowList[0x9c19f0Bd6218f223320F5B51fA4F4F74A0f25b51]=true;
        _allowList[0x6d15c238676BBbFd913822713d971cDFC170E2DF]=true;
        _allowList[0xA021Da3af846EAdF9539Bba8D0d5Ac59C87B3ed7]=true;
        _allowList[0xd27db4bAdaA0347cC50c2Bf2ce91e6CA7ab6158E]=true;
        _allowList[0x769380D02Ec0f022B610a907abdd090DB23c46F3]=true;
        _allowList[0xEefc64D684A2dE1566b9A3368150cC882aA0B683]=true;
        _allowList[0x0d9bc5D496C805bC6B49126111fcb538a4eC360D]=true;
        _allowList[0x5e19Ed4A406eDdFCE924B4949aAfEe5df15C2bE8]=true;
        _allowList[0x093e94741A8F96Bf44Ec92d5F0E464B109242138]=true;
        _allowList[0x01e8fB920df7775ACEab82F07c283539473e8f2a]=true;
        _allowList[0x81044165Bde432fbc131AE3E83e2CEED68C424F1]=true;
        _allowList[0x50c077578696A1e35Bd690247fCc285A44A29710]=true;
        _allowList[0xf14c2b72c7c8821A579a578B098542eBA13D8a12]=true;
        _allowList[0x3661ec1ee571efe8179b09436F3308DF6A7C089C]=true;
        _allowList[0x7dAAC88c492c641A0aC8D08420B6a7D78764615D]=true;
        _allowList[0xF94BA062308EA92f7AB3CF55c4B410339717C74d]=true;
        _allowList[0x8D0569C7B80098aa64e64e9F6b7a6A3A1EeFBb8f]=true;
        _allowList[0xe7ffF33d78FD81FA0Bfdca008695e125c3710EF8]=true;
        _allowList[0x44C06482aa80D4611A16E6F4116137cb44E6aE2C]=true;
        _allowList[0xE5Cd0545BE357D206187052B5018B342C26b819A ]=true;
        _allowList[0xc7BA81D2a48f0C5dc285835456A7135713aD994B]=true;
        _allowList[0x6130B7313833f99956A364156b3329e50695BD65]=true;
        _allowList[0x549cEa1ff6e0210Efb79f2fE58D7b0674701A6b4]=true;
        _allowList[0x89E61810011d8f032F92fF1F3F9680e2D2feE83F]=true;
        _allowList[0x26f921d0358EA791e4071ceC84a5040f5fF73440]=true;
        _allowList[0x3d46386BECc128F900e707b04dc1BA3C4144B43B]=true;
        _allowList[0xbBac69f7Bf99a0dD28a9e1ed4AdE8c508AE90c2D]=true;
        _allowList[0x4802dF37A6b97565c760caAA2E49AF0Cf204726E]=true;
        _allowList[0xdcd1E41eDbfCaCFdeA40aebba38BC28416FfB743]=true;
        _allowList[0xA5f11cD33A4F756C2633Cee4fa466c8A4bB6518a]=true;
        _allowList[0x93675bE4842871BA13a92d555C1Ee99D15691E92]=true;
        _allowList[0xF95b3cccB536bCb9F1F6eb4f3D703e65fC41689E]=true;
        _allowList[0x05CcF21A74324542F5c68bC8F216E173382C0254]=true;
        _allowList[0xBf071f633150f47B31C45Ff7D04f94F06F39974A]=true;
        _allowList[0x16a6E1Cce134fD6440Dd610a8Db2CE91542a6DE3]=true;
        _allowList[0x614ef48f3Db5544A33c148921352Ccb32ff480dF]=true;
        _allowList[0xB7edcF5Cd7C1d9a1eB175e54b62FE913ab87f327]=true;
        _allowList[0xE33e0BD203B8A7de9ED6A2928a1A1623851e5257]=true;
        _allowList[0x81450f038842311cd7BF878a14bcAAD9529e5170]=true;
        _allowList[0xc6A9b7b05f9dA87bfFb345094b238Db6B18b9143]=true;
        _allowList[0xFb8C0777051218D3EcB6ADe85783B64Ce54ad409]=true;
        _allowList[0x54fA1B6f88B289e58D32e1f0A03570d08F26B31a]=true;
        _allowList[0x27Eb78C1Eade6fc040d25b94E7acf6BBe0689F0A]=true;
        _allowList[0x7D87E23d7777D4829845F03f31721E10775799fd]=true;
        _allowList[0xA68595d2B71B3f7bd943FA02E51bae01ae18b8ec]=true;
        _allowList[0x1E77175dc45e51c37f982f451c0E5131D9b688E1]=true;
        _allowList[0x5a9CE28f388784Fbb515d68802Ab0f1a0C4b7490]=true;
        _allowList[0xE6CEB755e9c5706F001eAdebE5E47eaF3bEC0e11]=true;
        _allowList[0x938a0aF4B86057489bC651Dd02C080890d8ed5e5]=true;
        _allowList[0x5A077f81e4df021431F25b12541Ba233084380C2]=true;
        _allowList[0x8A9cd4ADf3C065aF17b2be9Ef347c4EDC5C73D05]=true;
        _allowList[0x280E7D851B8d6bD46B7ed4f98670a08f08ad1A5D]=true;
        _allowList[0x7c7869c553e180A8A90231E4F016fa382dfFc029]=true;
        _allowList[0x06762dF3dd1473306Be29072588b75B6Aa443Df6]=true;
        _allowList[0xF930b0A0500D8F53b2E7EFa4F7bCB5cc0c71067E]=true;
        _allowList[0x72d5704bA3850E131B9047D5F26876929FD2A2b4]=true;
        _allowList[0xe713794D7e3083687B93B64d5e5B15C84Dc6DBd5]=true;
        _allowList[0x9985273fa044a6164f9599Ec3E26d6B1bCbcC756]=true;
        _allowList[0xDc9DfBbd17Ef58aB8979D813f5aD0E0E4d9319bf]=true;
        _allowList[0x616ed054e0e0fdbfCAd3fA2F42daeD3d7d4eE448]=true;
        _allowList[0xA9B8A2Fb3802EB0c509831e6Ad232c0AC684A5a2]=true;
        _allowList[0x9fd2912eb0D8af91aA065A0002eDE74F9016514d]=true;
        _allowList[0x4394b956F78AD75d7a0Cf434fE5eff0A4e1D52df]=true;
        _allowList[0x436667b3F2715938791a3A1f1c040D274eEe2141]=true;
        _allowList[0x4993B35f56799fE504392d0bb1D57dfc3D73DA70]=true;
        _allowList[0xA0DB7A17B3B912c5b3bCcBAD5E9f7be910a05888]=true;
        _allowList[0xBDae25428c19d25659ca1da2DE626346e939EF4b]=true;
        _allowList[0x4e0DBF4d4835C8bE33C9f43584bdF385Dc66d61b]=true;
        _allowList[0xd4aa18a5E9C1bdEcb4F97cf31928De7936b1654C]=true;
        _allowList[0x17E80B4E239298C4c23F5445b5017D7d91D22FE5]=true;
        _allowList[0x8175BE7836445E2C4bC33216E2a9e84Db732F170]=true;
        _allowList[0x4fB23d2A4c1F9b16a0A237Cbe1A07396000C5719]=true;
        _allowList[0x2B6F5ee4d2275DcC1CF08EC01baa5B4D5b967d0E]=true;
        _allowList[0x20Aa44524D165043833e2526A754F46A77514232]=true;
        _allowList[0x9eF4ca1A90361Aee93c4638D142Ba04A5a8fB08B]=true;
        _allowList[0xdf09092bAe5C265e404e0a8Ce01eBF341481F531]=true;
        _allowList[0x3018B55796b0B9F6B4fe6853561FD33B9261ff30]=true;
        _allowList[0xf712929c4D3a341104ADbA9aAf1eaAD73e37b5b2]=true;
        _allowList[0xc30452caeB2fD97222455Caa3ae3105a96ec522E]=true;
        _allowList[0x21818f7Fc4712e6b3BCE71a7EEA40414f1FeAD3f]=true;
        _allowList[0xb6af0e59E41F75552af00138a9F62ACAef2B6254]=true;
        _allowList[0x8c74C3153e829a9c7d60bD057b27D2eb3222DDdf]=true;
        _allowList[0x0DB1f2147619d12f5281B2a3cAe9B34736F4532D]=true;
        _allowList[0x1d7b8E4A86Ae6abe09FE4f0A5bcF2495b17fF199]=true;
        _allowList[0x0bB1066194cbb52B10183d7D79b1180cf2B5eD48]=true;
        _allowList[0x8cc3A2f4DCdaaa250037Fb913c2629A010f1f8eD]=true;
        _allowList[0x4115551A8341d24c5E8747abD0D0f85B8D0352Dc]=true;
        _allowList[0x70FC1502f222E721A86731661DB5F3AbE21A8C6F]=true;
        _allowList[0x8E55c9518416D12dB2763EE17A2D60f2d6244D93]=true;
        _allowList[0x1b8f04d48567ab20F7dbE3A191CD0d3C2826BF7b]=true;
        _allowList[0x8756Da913378b865Cc6e5bbD8d403995A0b37567]=true;
        _allowList[0x7215b80FbA9c774d629Aa930baEf35E562e0Cd57]=true;
        _allowList[0x6292afeBa1382b2F22Caa3214F42073655092EC8]=true;
        _allowList[0x71A39b27A6F3B384180945870b72767c043e638a]=true;
        _allowList[0x4a75C0aaefbE2703C3b3a8dFF1e6e5bF9E4078dB]=true;
        _allowList[0x88F964C4CCe207eaa77Cf9eC77e0A2e716B6F1f8]=true;
        _allowList[0x9630D91664f9014874308a019F060BE838Cf63Dc]=true;
        _allowList[0x1B52175fCb2a892b53330810F29735Ae23dBCCDe]=true;
        _allowList[0x3754469Fb055400C816e4F8Ec0223912cD9FBC7B]=true;
        _allowList[0xFeA363925253d83F43c2AA5Deb578C6298E511E1]=true;
        _allowList[0xcc6292BC2d67a3BDd84DDd6166112Aee8Ec0c986]=true;
        _allowList[0xc75fe38dCE675cA98B3F3fb6e9402eCf5E120D5C]=true;
        _allowList[0xb770C98FB918c323d5b55be1520050782E5ec297]=true;
        _allowList[0x3F42b979cd581e3484469825c712f03f0Efb8C94]=true;
        _allowList[0x53eF350f3d8c7fCDF04661Ff6672A8fe406E7605]=true;
        _allowList[0xd3d2F1373d73A31AaD6DfE226935585A9608F4a8]=true;
        _allowList[0xBd98fa50265ff40568Cf7728E02Adfb7a30FF608]=true;
        _allowList[0xd5FFE973DfE90dA96CC1af4fD8f9E67093E51E84]=true;
        _allowList[0xd7EF4213AC470D243a61aACaC2C1DE08dD4c9903]=true;
        _allowList[0x1148b66f5BDc99a2AD9F659D42Bf115aF0755266]=true;
        _allowList[0x58d8CC6f87f0C3c69B5998dBE62DFde9DcAD2FB9]=true;
        _allowList[0xe94AE36efC66aD2cc3a891893217CFAD33Fee418]=true;
        _allowList[0x5fE8a15dbE1863B37F7e15B1B180af7627548738]=true;
        _allowList[0x5CADCcfd488E2B919596e2430a7ec3a6cc1CF2Ea]=true;
        _allowList[0x068565c1F5bDe10D4230A8157Da12a4C0A825613]=true;
        _allowList[0x10a04e477016290fC974b1CD88cAc7720E418FE8]=true;
        _allowList[0x2fbB04CA08Be1094F6131e2c8B33368b8eef5F9f]=true;
        _allowList[0x4f41FA9664EAfe2a9b8b6663D81473B942345dF6]=true;
        _allowList[0xDaBc0fC8FF02c784871e1122784DD9aF15AAF0d7]=true;
        _allowList[0x8F3c36B25D077B9301Ee6b9B69D02b18B1E390F5]=true;
        _allowList[0x11D6622d7112eF328b2a050693F871A7716283e7]=true;
        _allowList[0xFD0D1A8AD4F8DfC3e91d4843559316DDbd675542]=true;
        _allowList[0x0e815ca87DbE52A4C4322c29c768255A44320005]=true;
        _allowList[0x711E207B2fa8daceBb4D7cb9E4b0f77D98FAfA22]=true;
        _allowList[0xd11071FD3dfd4FbDF3EE8Fbe88D97894cf777375]=true;
        _allowList[0x505aA4bA3ebc89fAB940836a157c3e38f2844491]=true;
        _allowList[0x141c663fD81914A3AD328bce16a1b817A7bD82F2]=true;
        _allowList[0x95dF515077b7BFE200DC3f9C541F9563E19Aa3Af]=true;
        _allowList[0x6518Dae4d5847e1195A080611b96AED3714A8C41]=true;
        _allowList[0x833bc15c3aAF8BeCb9c82dfD8fd9474E31C9C583]=true;
        _allowList[0xF8e0cBfA60D142d4D5ef28491A6737EDF5f6659F]=true;
        _allowList[0x91E371C3CD3Aa81aF27b1602D4d8cf9D81ec5a90]=true;
        _allowList[0x76e469dB0E97638a92532DcD132b348F5CF48037]=true;
        _allowList[0xAA4e17A7a9f3E46339715F214D261D139805E4a4]=true;
        _allowList[0x356663f9D20D7126f0eF4226377bBa7F20708C21]=true;
        _allowList[0x56Ba5B0Aad0298b4aEceC0f307CCd0d7d6163915]=true;
        _allowList[0xF1a9F5AEb0F975489aC2628A22040Cf42E9fE8DD]=true;
        _allowList[0xb8dB0BFD726D774C7A0c659503376d3225cF9B7E]=true;
        _allowList[0x5Bca4075dFC8065235cF75C6b15B410e62845Fec]=true;
        _allowList[0xDE8cc955b627620A82eC95D5DBF8f6fCedEEDDED]=true;
        _allowList[0x7BaB574D52834E25aF94F265Bac34A971d299139]=true;
        _allowList[0x2a00F63Af45627fF351549106eA735Bd973Aa86E]=true;
        _allowList[0xc1849D147Dc883E5B5d4923aE49234A4FE8ea1ef]=true;
        _allowList[0xB8a7d78021A83fb29263D0c121C839C96CF07Fc6]=true;
        _allowList[0x948Cc15dABF83047219695645f8f9416b7aAa11e]=true;
        _allowList[0x39432039ddBd6fC67668386C897e54c1c5554CE4]=true;
        _allowList[0xf8439818Be6b8bD15aC7b2096E4a4325389A1f91]=true;
        _allowList[0x764aBE778aa96Cd04972444a8E1DB83dF13f7E66]=true;
        _allowList[0xBa595D92A314d7da8D31971BB227c0C002a04041]=true;
        _allowList[0x007DbeD1B4a125c45DF88F3FFa350ff70c94DD9f]=true;
        _allowList[0xbC6e70CB9b89851E6Cff7cE198a774549f4c0F0C]=true;
        _allowList[0x5043C8e2F1573E7A1A009Be23f2C31266f1948f1]=true;
        _allowList[0x9Ce6840743F3d01550AABAC539056ee7258C13cA]=true;
        _allowList[0x1Df722258cD703Cdde8bac7C079e222c4b145BBd]=true;
        _allowList[0xB830B2FD1518B04310D264704A4e46f9E083B41e]=true;
        _allowList[0xC7bE5A69F0Da5672E3ECfaaf5529b5FE81D803A1]=true;
        _allowList[0x6f5DE938cC4204245D62051c13c391f149c6e092]=true;
        _allowList[0x362bD4F29D03d68bF5b1b6bc118739f0e7527f15]=true;
        _allowList[0x3632C0ecCB5760Db0b049e3dF9fb1dfeD62a6237]=true;
        _allowList[0x6c90a82B53356CDBa4a1D0aB49D9BA11dE2a722F]=true;
        _allowList[0x0aF0CC88182856aFD7f0d5D953c76673395fe85D]=true;
        _allowList[0x86aD40B7B57551402E191eB2E51dDe23DEBd9E13]=true;
        _allowList[0xDa8bFCdC68A8174B4BB5cD53cf5BE825FbF20dd2]=true;
        _allowList[0x6B605318017255D7fA0840Ae62Ec4ec1950Ee9E7]=true;
        _allowList[0x84179C31f79683C7aAe040D7c9c05789BaCE912a]=true;
        _allowList[0xacf9E2d1fEDEDe1893F6f667af8110B5500Ff43e]=true;
        _allowList[0x69B9D379774926cE40bc9493C8BB8497d1888A80]=true;
        _allowList[0xBF64136ccEB3158E8d959C2619326f6877B7f239]=true;
        _allowList[0x76d06E8E4cc5b949F2e668E98Df62A00B663C6e8]=true;
        _allowList[0xc44e64a59510b626AD49F205b2FA5ee1B2781398]=true;
        _allowList[0x6Ff412F54E10588A2CF0442cCfB228f866ff1684]=true;
        _allowList[0x36c5c9ec647c0C6DdB283465dCbbA175C34D7125]=true;
        _allowList[0x1bb6Ad7CD3cb7C86e1a50A5a5E956567D47EeFd0]=true;
        _allowList[0xdC84BFCF2DCb37f7F30F8fB64F823794C84c6358]=true;
        _allowList[0x2a0e4ef6C7693Ad911Ee2d3A289f2707296F633b]=true;
        _allowList[0x647FCF04eb545EB7eCd2C0987f0D6e742A1331ce]=true;
        _allowList[0xf74404BCC86b9408373E8D081575bFfB9FDD6C98]=true;
        _allowList[0x99B937DB7E11f1Abe6ee1795317912BE46E20140]=true;
        _allowList[0x3Ff74F5524259b4b5e3b9163D8a14B42deFb9a71]=true;
        _allowList[0x5d676c01A602E478d7a345454bA1495794cc91b9]=true;
        _allowList[0xFcA5ea7c64133F2fca39aD099234b07aAab2df61]=true;
        _allowList[0x338Ac132E077a14A657B5515EAB9E337Dfa023Ba]=true;
        _allowList[0xe8616eaB82Aa739E532ab72F75bebb8e3238c583]=true;
        _allowList[0x748b19a319E4b11341Fb967F92489377816C2159]=true;
        _allowList[0x9fb622b200D7403Be7c596164018fC7F39aB1536]=true;
        _allowList[0x41477FA04d85cBB4f030eD577f5950C039EAEDBd]=true;
        _allowList[0x14669Df8BFcF56cA60dBC3397B8e8f0c0aD23062]=true;
        _allowList[0xC1d65A0196d6adB817368324E1859C1c8C060068]=true;
        _allowList[0xDB93342558502d4F522E774Eac55D71BFF8e6130]=true;
        _allowList[0x874A26517f82F96114F8d4A741424D88C8aE4a03]=true;
        _allowList[0xa0FAf6a7f900d5a10E7a51592b39858Fc0968866]=true;
        _allowList[0xbCa5a56465c9A3f3A19C0617ac9AB5f56877D69E]=true;
        _allowList[0x2D09b091922809a2b0Ead12866211fB4389A256C]=true;
        _allowList[0x7AbCA3CBC8Aa182D10f742F72E2E8BC68c4a8839]=true;
        _allowList[0x9CED3bDC0e6ff65C3f072b0b5527184843Ed4eaf]=true;
        _allowList[0xCA1059d0b589180FDF870D12F6B254F235Ca7255]=true;
        _allowList[0xaf15947D32b82BC053E46Ca380664C8EF46E70b1]=true;
        _allowList[0x8C5fC43ad00Cc53e11F61bEce329DDc5E3ea0929]=true;
        _allowList[0xdD5BA3024D0CEa35007e07C2D795BD9e93a4c127]=true;
        _allowList[0x03f4Cb9e297ea659F30E09341eE7155a7d136398]=true;
        _allowList[0xbdce0d84ABb90AaBcC1a530475A6b0E0E4e39aB1]=true;
        _allowList[0xfD72ab50c5e80a07a19ae8Cfd6b23C4116FeCF62]=true;
        _allowList[0xDb54C320A0B1e994D2bF7dd2eC939F6c25918011]=true;
        _allowList[0x327535dF246Ddbacb25D86CF25276ba626d9e29d]=true;
        _allowList[0x3f623a639DCfeBDc6F96d8A1e445fbC3403662B7]=true;
        _allowList[0x4460a4bD792585b7b1290A1e5C10A92D71d2d8f2]=true;
        _allowList[0x8BE62F79Ea0Dc4bf199Dd65363683Bd892E17f66]=true;
        _allowList[0xbBa1D8028cC2a942ea678e6fCBc17946784b1030]=true;
        _allowList[0x677620f63dad02D3d8Ebb04e4eB941799aC811Ee]=true;
        _allowList[0x7112FDF95e273b82e54A66E555611578A31B2E41]=true;
        _allowList[0x2363bEf09Bd8C872228F8A8D42B7b205E8AD4AC6]=true;
        _allowList[0x1533eF8a7BC85532a8515DF6fDFb15d165D0d03c]=true;
        _allowList[0xf9A95f15d178e0afFf60c543A9D7117235e54204]=true;
        _allowList[0x4cB298bB77b98A0F68B47cEf292206d3855f7059]=true;
        _allowList[0x5Ec0D096f8ef2Ac2dBd3536e3dFE2db1361BA6a7]=true;
        _allowList[0xb708E5Fc7E0916AaC3e2B0a30721F72B9AEC02bE]=true;
        _allowList[0x84dDddBe34C36c894347fA3649B0E25550dEb4d6]=true;
        _allowList[0x720Bf57F67b6B00B97cBD9d967a0Af2427352435]=true;
        _allowList[0x8E4E5Ab35103ea35a5FDc77313c50Af9Ff060608]=true;
        _allowList[0x19e6700Dfa0dC3F288c3cC21c86016546d51B3cA]=true;
        _allowList[0xAd16A82eC6d12367491e39EAEf6C6a626F2f7748]=true;
        _allowList[0xe28CC8f24edA328eB311C4bf03BBa2D4bF15500F]=true;
        _allowList[0x490262214be7B9486dbFaa547a947ac913889DEC]=true;
        _allowList[0xD7bad5Eff26389B4eE7822690207b13106E03D43]=true;
        _allowList[0x86cfe5B9D71a61EB489fB323D8B839D89983fb37]=true;
        _allowList[0xf04C8f815878Eb09B8E4602Ffe780aAC818AE6b9]=true;
        _allowList[0x654fd4b0c2e82cD869a76889CCC14F52Ae282f37]=true;
        _allowList[0xD8c88B8681B3F699d8DAe59ec239fB0925acC660]=true;
        _allowList[0xB3B3eEB4D999AfC09049F8Df15A6e286c0f212f1]=true;
        _allowList[0x76Bc581fE5Ab1235631a18C39100065a770482C8]=true;
        _allowList[0x04F581FF13481Df7E55fD6d4A102277aa3eD3ef0]=true;
        _allowList[0xA0223601E0AaC07346B0EC4bCa352Bc74f22b099]=true;
        _allowList[0x77E1b087378d0A12Ba3769D46A983A8AE2E61e69]=true;
        _allowList[0xe4f0b2b776E779dE24B6B62D98E58c1fBC786f35]=true;
        _allowList[0xbb44530e21b3A5Aaf0c86BA10D605e1396bADD88]=true;
        _allowList[0xD982987638b66E72a1241A81a965050687d09B24]=true;
        _allowList[0x868a8b040653FB80eDd83A211f8Cf21f8653F970]=true;
        _allowList[0xf6B6Fd916852CF7339B0b5d136fCE5ae29a80780]=true;
        _allowList[0x4c9A65Dc425f512e4b4B57e47fd760a0A5123bD4]=true;
        _allowList[0x117D4EA1f4498Fe2189BAf08f2DC02dCDD7507A8]=true;
        _allowList[0x5B37B7777F13a8659a10EE84e9102b049272EdA5]=true;
        _allowList[0xc3f71D25b5b15A6BC0d1b233C23e2Ae31334fA6F]=true;
        _allowList[0x06Ac3826c858C64b5755E292d17477090d3d2149]=true;
        _allowList[0x222b17dE9d7D549f6212E674964e7Df37fEF25D5]=true;
        _allowList[0xc5699f5a395234956FD8B1Ef764eF74A4B895631]=true;
        _allowList[0x831Ee284B5068A607bd84F16975Db3A867aAf50D]=true;
        _allowList[0x028368E212809C44Cb9E2D7738481f7fACc5590C]=true;
        _allowList[0x2E83B8B7205Cbbb2dF2b1160099Aa2c727351959]=true;
        _allowList[0xc68E624a02d76FEa3bC3Ca3D8434167ee943D403]=true;
        _allowList[0x01b44B1018C0629eAd48fc88C59d56F3894b1535]=true;
        _allowList[0x4E60c3a0A1a8ba1987f03f971fd2a63c80C718c0]=true;
        _allowList[0xb85633D34203B20F57b684F292fe3F281e7b8713]=true;
        _allowList[0x741F14A7Ee342bf0A97615843bd5DB57CBc7Cf5e]=true;
        _allowList[0x3727234959241f514CBcA2b2C44D18Ea50BFc6B1]=true;
        _allowList[0x0BF815975c7b1ab2c5Ff2E30fd8e3bC4a4A67123]=true;
        _allowList[0x5f38c1E1E0D31DbE6CEFf00F7dA7E1cC200A43b7]=true;
        _allowList[0x81FC4AE2e1795Af7f142e31Bf9Ec5C15363c0eB5]=true;
        _allowList[0x57bBa57417e320671F1bA999e7e686923299EaCf]=true;
        _allowList[0x7565DEdDCB83a14B185eb9520914bB918cDfE983]=true;
        _allowList[0xD4dD6702b064bC2EcCF58ECFe1a364B35a6511b3]=true;
        _allowList[0xE188b0Ba723260B14D5C61DcF8e7a69Ab4B9cF41]=true;
        _allowList[0xa2eB54B2CE875A19E82088B88ABF2a1758836760]=true;
        _allowList[0x323D153a48b42B3c530bf860b1A647262642B171]=true;
        _allowList[0x0f1154dF03359ad8653c694019BE41A8C39F413b]=true;
        _allowList[0xA21A6f85e9E782427491C20361a84Ac6B816fa38]=true;
        _allowList[0xe6d029fD16f6fb0E7EaE3553FAd5De209Bc03d6C]=true;
        _allowList[0x8c08BA3c775C125Bb2afa46e0e43698F216B6789]=true;
        _allowList[0x990FFe2980D29eAA271A9710F1b8e38a1193Ef57]=true;
        _allowList[0x1d7F4bA2997D644d21195aaDA3F2f85F24330e6d]=true;
        _allowList[0xc9241fA1cba2b3755b154F3670E2754fd86f9a4B]=true;
        _allowList[0xCab38F1c738042E1e1208DA1d4C6e53Dd83C80dF]=true;
        _allowList[0x871ABEA67Bd376A8484E8dE649c73965a0d3e794]=true;
        _allowList[0x6A45B137c9681cf3CF531Eb61E68545779FACC36]=true;
        _allowList[0x7c54B32219fa879Bff62e55D00A81C9B59c1fc99]=true;
        _allowList[0x78D4e8fDC6E5d03e208Ca4E0FcB7D9CE633378b3]=true;
        _allowList[0x62B5bD7F04Fe783796810b2526470dfdE73dAA49]=true;
        _allowList[0x32debd59217e4adf5e8A942166D4765C46d82B82]=true;
        _allowList[0xE136C0D0039aFAe187F022a5e2F37B8Bf5d176a9]=true;
        _allowList[0x9De33BeE1353E65fE86Cc274F86Ade0439021576]=true;
        _allowList[0xF2c519b1633241cDdfE21CeCaE1A5B0FA4C776b3]=true;
        _allowList[0x8E63E4376dDE62cb82f5a91C4bCE4156457dEdB1]=true;
        _allowList[0x36356e0284Dc9aDccC72649833d453Fcf229b630]=true;
        _allowList[0x16951212197B6E995aB4ceCC5cF6dbeA976782dd]=true;
        _allowList[0x61e722c09Ad1F625dE6f2A1543577a67FAf31119]=true;
        _allowList[0x560772126fBc21bF188AABF05E714299edC7bbFC]=true;
        _allowList[0xBcE3C9499752dEB24d02AC2daAA96739F5aeC4Fd]=true;
        _allowList[0x8121b28051B4B1D2840A5b0E00A4A59b72C3d169]=true;
        _allowList[0x64932F86d69F2717307F41b4c6b8198000583c63]=true;
        _allowList[0xB3Fd0c9647ED347AaeE9c2DD8dbe909BB26272c6]=true;
        _allowList[0x7695Ea5De20f829Eb3161B6D5299D94Cb68F0E11]=true;
        _allowList[0x2B935746fDd506C4887a2ff87E4559FAbe2aCa13]=true;
        _allowList[0x3f9505a255174D66c533cc91099c126D71E79406]=true;
        _allowList[0x7dA940212642d20862ED2f479A56Cc3eb1Ea3c8c]=true;
        _allowList[0xB4725430bce5f9CEaA3682933fa04b741a44cd30]=true;
        _allowList[0xB87991FeC50Aa91F5dEe55Efa70817e750029789]=true;
        _allowList[0xE14dc6FD0A163Ce3Fba49f4B2B73941E3Fb7c0AE]=true;
        _allowList[0xBf44C636A4A4Bbe257a87067B25c4C875170e04D]=true;
        _allowList[0x396155c7F15ae8Aa634FD1Ed15fBa3Ee7397AF36]=true;
        _allowList[0x22F95C8bd456b565BdB1917aba5B0611C105Ad5A]=true;
        _allowList[0x996e778ff6e7Fca4b8FCf8a9ec2E85C878241bC4]=true;
        _allowList[0x62FA9f3548611888BC96F5aE5A2eCA1EF91d4b0e]=true;
        _allowList[0x361e8ff276689F476B9B942a67fD2ca69649389E]=true;
        _allowList[0x61B857bCcBca5fFA1412836e1b78F238D1085AEf]=true;
        _allowList[0x37Fa3D9B5a7522153259EdcAA22DE5ED9B3a0150]=true;
        _allowList[0x410e867347634a2283031D327461078a72c38a0d]=true;
        _allowList[0x41d4e731f6a555BD3a533fd2B963185793e56f31]=true;
        _allowList[0x1cCf769B05f509c9FB51ef4911d3941d06821901]=true;
        _allowList[0xb3DC6Ff7C5BB3f1Fe7b79DEF802048EaD10F8690]=true;
        _allowList[0x012E168ACb9fdc90a4ED9fd6cA2834D9bF5b579e]=true;
        _allowList[0x063a48F3b73957b6d0640352525Eae313D4426c3]=true;
        _allowList[0xc309efF4fC1A0d694D76d982188b18a6da7bb756]=true;
        _allowList[0x44331702C2f80dfFa21e3e4934D601648ba5cC56]=true;
        _allowList[0xCDf641863B76E5Ef6A2D766B86bedacBD16CeADe]=true;
        _allowList[0x9f1E19C805Bc2DF9D0c00d6622E6Ed386A0CA30D]=true;
        _allowList[0x30954DcDfBc971901E9Cf6B9EfBE4F1eEE10d6aE]=true;
        _allowList[0x311b0200653e986CFFa77Eb56bFA6cB191b5D190]=true;
        _allowList[0x8976bbbcb15e79181725FBdfe2959f89bE041a92]=true;
        _allowList[0x26c9Fc612b005781127246BBc5dC39f823E3106E]=true;
        _allowList[0xC34493729B06A62efb5bc10F7d361FAdDD546562]=true;
        _allowList[0x2A80e679389a3de24dF93a8F511D04130F24f591]=true;
        _allowList[0x42BBf5f71C234284265D61BC77f564209B1140dB]=true;
        _allowList[0xFB8625CeA73cdd67b737b94b10CBe6554aF279d4]=true;
        _allowList[0x5ce7df30118dBB34D29c2a2E7bAd3B5b98E9c926]=true;
        _allowList[0xF98dD7e0d41586ab71F843df3F29723ADa890727]=true;
        _allowList[0xf8b9c607675C554be8898e874338355B0e63A7F6]=true;
        _allowList[0xba69593F1F51D4b2ff0a73298c8bE0C8586be931]=true;
        _allowList[0xB7972C694cB76d4756346A9a7235d90064D8bd8B]=true;
        _allowList[0xc8ba12882C3547B5fB3bd215f474Af365A55157a]=true;
        _allowList[0xEfa131b185De4F8965b9c1A6f02E6264CAC36a28]=true;
        _allowList[0xe028498570b2727d620FB288BF1fe37B45bef041]=true;
        _allowList[0x497713ee53C228Eb4B04ae8bc7a2E5b5898CDFAb]=true;
        _allowList[0x8753982d800bbBF1fAf478eF84C3e96F2775d3B9]=true;
        _allowList[0x3B334052bc8d623d7733c5318893ae4f33776959]=true;
        _allowList[0xbb0a7d261F4b6102e5A9592507a39f19758e8fE4]=true;
        _allowList[0xcc0cc3eEc0A10374819D363DF84148a6ad2399D2]=true;
        _allowList[0xa9A0Ac2b50cE6F166d169c3D3178F94251ec23C4]=true;
        _allowList[0x3A78a990DcfE1fa140701CB4A02c7B9D8c3f3E9e]=true;
        _allowList[0xd2F17ed427f0fE28b243854a6d615D3259D69243]=true;
        _allowList[0xaffC8B03f84E1BCdB759378da1667301a5ac51F2]=true;
        _allowList[0x3a0491E718988C77394C12eF639C9bC424C536dA]=true;
        _allowList[0x09f95bd58F8714D231809440a459e2675510fd4C]=true;
        _allowList[0x3fd26eDA04344456a3768Bb8504D24DE81Ee7B6b]=true;
        _allowList[0xAfA4CB60EC55adD92de2aD5318562c175f95eF23]=true;
        _allowList[0x12B668eB9Ca7354B2f05361E3AE12b27547A4986]=true;
        _allowList[0x86E45049d74550f86D05916663be90b7A3881440]=true;
        _allowList[0x8a1b6a1134628E1F3827fcDbbbDaCf6A2C54C5Ea]=true;
        _allowList[0xB56332AfF8018B5780305CBbb4b577b6FB8c80D2]=true;
        _allowList[0xE9Cc4F546CBab8A1BDF7e6E3e37851C6250d28F2]=true;
        _allowList[0x880a42D5aEcdFA4226Eb2F99a04a75baFC336780]=true;
        _allowList[0xEcE44413e685659eE964757364d70B062505fEef]=true;
        _allowList[0xD4F17B038B10CC720778DFf27Df3E47D637d6cD9]=true;
        _allowList[0xe6660Fd8d59F97443ab21905D8CD8E8C5A12Ad21]=true;
        _allowList[0x49b8E54031482d1A516bE9197D6f1B71239E00E8]=true;
        _allowList[0xCE4569F6639a3EE7217aE24b32bE28d4c3f6D19a]=true;
        _allowList[0xD502d966f2B50e4C1768efFe99D4C7C90C3a7625]=true;
        _allowList[0x21Be698347e62235309A0FBeb98D0F60989d68f4]=true;
        _allowList[0xDe609b02125b7574C5126b3c73Ee65332c012642]=true;
        _allowList[0x057D1e845402b371EB793135F877966B47577e28]=true;
        _allowList[0x2986a4ccF8EaB3a44DF43A655dC9ad1777Feb00C]=true;
        _allowList[0x2308E386896F78ad4c9675EC22401B287C72eB78]=true;
        _allowList[0x81a1B8ED2D0449a50168C6B410a4De24CebB9f70]=true;
        _allowList[0xF93962fE1C9C5085D429BEb407a654EdaC210e56]=true;
        _allowList[0xD34e3c34Ae9828dffEDB9a2f236aF47119A113Bd]=true;
        _allowList[0x685408262D49784be403455aE749ab0b81D5E110]=true;
        _allowList[0x92A021C3B21dffF0192175831791fA261bdf7018]=true;
        _allowList[0xEAD3B6578c71117526A9C972c0932C446320CFb0]=true;
        _allowList[0x7b6555058649A1a63a6EA4fC1EAfd28e78949a0b]=true;
        _allowList[0x264b57Bb121589Cb210932a81Ba482f0a9873eeF]=true;
        _allowList[0x507568aCd9F5C2982c97b3370912Fd5b401D98bd]=true;
        _allowList[0x263aE5D5c93573CAC6392Bf65815acf6570f8637]=true;
        _allowList[0xE6316b387E4D8951De278297e3801C02395F8803]=true;
        _allowList[0xbBBAA9b374136A2FDEF831758Fd6D00f0aA116F5]=true;
        _allowList[0xA2dEbAcbF2b543b6E4CB5D4A4F26220aFCA4e9cB]=true;
        _allowList[0x905362Ec4410D0E9295d16acC584d488ED2819A9]=true;
        _allowList[0x54505b8c1447678E744150d4BCd9261D589dcD66]=true;
        _allowList[0xf92aA16174c441766e07a59600eDf291B4e01a43]=true;
        _allowList[0xA44804c4d3d6D9Fa37102fD0aaE39d23de7a3839]=true;
        _allowList[0x14AB9F431B7D25FcAd366EC9511DcE38E229745C]=true;
        _allowList[0xeEBb3e1d120aFEE9004d4B62E1A6eb2Cb0FdD3F8]=true;
        _allowList[0x1597b351f2390a8bFBdbFcF88179f3bDc5D2Ec82]=true;
        _allowList[0x0A3A0cF2B9f37e15d3d559B85b8A26a3099b0894]=true;
        _allowList[0x49594Fb73a7912Bc6dA5D33a1060Aca029907086]=true;
        _allowList[0x445537dBfC407673d66E2c8A86216257aDDd91C0]=true;
        _allowList[0x71eFEa85A59b461853dFB6aeDf1F06B6d6E89E92]=true;
        _allowList[0x759EA6dB5bf409fc91551a726092726Bf58Fff29]=true;
        _allowList[0x26ADcf5EB1FB4f87202Ac772c009f02D51c89e1b]=true;
        _allowList[0xb8d24EAc7840Fdabe2A96ee88169c8D7a205a4D4]=true;
        _allowList[0x6258D54320e3281B3e0fceE33363425A60845581]=true;
        _allowList[0x274316a1359b0df41e88e06cE2d33Dab6B5cA772]=true;
        _allowList[0x0c3699715DE1739eF5a8a0F3a667a7092EE7e0B4]=true;
        _allowList[0x4251EF8361a471E51188fD3dfCBaD4d5f977D9f0]=true;
        _allowList[0x01d08a68a55b010ab4B87b17064125Daeb523A3C]=true;
        _allowList[0x23be5cC51661d247e7969E26420274cAdD9347Dc]=true;
        _allowList[0x9581F459897A5b490332173B90Cfde37229A4Dd1]=true;
        _allowList[0xC2bD7faca51549dbB8E701f48baAF5C135374613]=true;
        _allowList[0x78FA3A61C93666882b56ef62646b8E9F39150A50]=true;
        _allowList[0x523D68f55b6b4d4ff76b2a3e073BF334233Ac86f]=true;
        _allowList[0x8C04D9E45c8aF805a5877B7f6611e7bD2Bddac38]=true;
        _allowList[0x97E62921B46E0f9048CF505A13C04e11D033E6D4]=true;
        _allowList[0x4fB0b6d348bEBa85D4ee4B45d00FBd1824fBe2eA]=true;
        _allowList[0x872eab8A707Cf6ba69B4c2FB0F2C274998fEDe47]=true;
        _allowList[0xe91F0085F5c3e67C8Ebd5c8f6E7f4d884452DBAa]=true;
        _allowList[0x9e7f531BF5676aeE365375f362C4F9c7110f9d6E]=true;
        _allowList[0x09DC47C3C21a11f41e25a058C1DfC07951661C22]=true;
        _allowList[0xcB1fAe08008B69e023Cd16BA9024650AFfc7d0c3]=true;
        _allowList[0x78Ee5e45B0A5b85CB282C7a9009fF9A40C0481AB]=true;
        _allowList[0xfeA31016bd0C4B9CdFB8b683e39901Cc99B1ED93]=true;
        _allowList[0xfc9B347bBbD747595EaB7D8bdad60585ddFE5784]=true;
        _allowList[0x668F386b1780A757fde264eaEfD7877c263cAE2c]=true;
        _allowList[0xC0Bd088d18791Cb74e9d75AE9fA9B40B736CdAA9]=true;
        _allowList[0x384eeC1dAA1a3Bd58430bd5117B5D8658b121983]=true;
        _allowList[0x286A6f617cFe518f2F5bb67686a460141A7B89f7]=true;
        _allowList[0xFABCC55906b142dE23EFebb97A107e943Fe5BE98]=true;
        _allowList[0x6c2f39dF4e989172647E033bB1ECB79eE91e67D7]=true;
        _allowList[0xf19B975AB5B1ab459eE989f1875C80FD24359b4E]=true;
        _allowList[0xDfB67117B3C36d6c0584e8b268F6a6a3Ba4E41dc]=true;
        _allowList[0x9aa5075ff25c6798355f2BD49bA2f15EdD795180]=true;
        _allowList[0x3C34634763424d775111d0685E2d7D11Ec8C41A0]=true;
        _allowList[0x2E6d1Af99C10cac1Ec4389e86a90c710D7c10b8e]=true;
        _allowList[0x3bA8C4067C4F245d8FFFB911969fbb0AB492cba3]=true;
        _allowList[0xF83787D15cadd1cAD2158646E7cab858157c8D7C]=true;
        _allowList[0x44de03c876d575344417FF01e8A943D561e8df5a]=true;
        _allowList[0x51380EB9DC67A2Cc7A2fE29eb3174CABa90C817E]=true;
        _allowList[0xFCb49314d478fb81caCe751A73272F1bA1a15b01]=true;
        _allowList[0x2380CA49Ed8e933c97905977763693E5CF8770f4]=true;
        _allowList[0x265BCCe851F84601D05E122C40187475C98BCa10]=true;
        _allowList[0xa1a134BDA79F8CB9c3C5E419E88A85a2a97b0917]=true;
        _allowList[0x734ebeCE6D698a50CF90aC9bF15e3F16dC34a204]=true;
        _allowList[0xBc2c226364fBdeD527BA8d13FF5af7fB359A0E43]=true;
        _allowList[0x61B4e7cB4003a55dEbF52dFc5ee3Ee1151287d1B]=true;
        _allowList[0x3c3fD843d1b075af719d086DBFE5aB33E47F6aE8]=true;
        _allowList[0x30f0d26D5b01Bca26b50415DE8F9AcB88C2aC744]=true;
        _allowList[0xE1c5FD5cBE3Ba9fB3E418B1B2C7241F05E794b8e]=true;
        _allowList[0x99526b337AEA2eF72F454dE80722C98Bf216E6F9]=true;
        _allowList[0x5A0eA806A8F713249ba650eC859EDc9Ab9e78f08]=true;
        _allowList[0xA43711F5DCc3559a1E07eC124fd167e26c9BaD43]=true;
        _allowList[0xCE1989e08253d27F7Be389692B59A60353424420]=true;
        _allowList[0x348B1D9e9e7E837228AB17e42602160a654fa781]=true;
        _allowList[0x6d02482eACF2E9F5D97160231291C26EBCA8De19]=true;
        _allowList[0x68Abb61E97fFD7C59D6112c01C622E76187C26Ff]=true;
        _allowList[0x54EcaD032486a010E5378bfB0aA2E6a752f335c4]=true;
        _allowList[0x5C1107B352514d158d80429b1B5cf50968F7fa9A]=true;
        _allowList[0x8745125effd4A86f69aeE71bFcEa9768AA519E0E]=true;
        _allowList[0x2b212c0c6f4eFcEEf25Fb5B00F7130b325f96284]=true;
        _allowList[0xA32729ea990d4005329212e8867FE3eCDa8EaBdf]=true;
        _allowList[0xAF42E51B8d38876d6b3aF4caE83AA513C35570c3]=true;
        _allowList[0xDb8286D6563c680c22b91E715d628C2bF232FDa3]=true;
        _allowList[0x91832bcd20d938Af88462F2D1B41abE2397fbA00]=true;
        _allowList[0xa843F841928094844A73A4c6284718DA88f5713f]=true;
        _allowList[0x679641F9450609D2Ca03B2C468AC8631f87d8Ee6]=true;
        _allowList[0x9bcfAC3a3f7a58Ca04ccDA110d87CA40D862c970]=true;
        _allowList[0xBB6B8faA2651A6c7Fe8fF56A7c4F96d9325C7B93]=true;
        _allowList[0x787e06FAE1C2139Bf8cFa2d5C5784728A6E5fc9F]=true;
        _allowList[0x7443E57a7d4df44FE6819dd76474BA9C3BE3c81D]=true;
        _allowList[0x8F383669200040179D7F9f0d58B17B975662CC96]=true;
        _allowList[0xe48EDd2cD4d82b6E703A9c3c45775d072d753591]=true;
        _allowList[0xCC3e7494Ab2c5615587d635C221b80E9eD5AF292]=true;
        _allowList[0x59994F5952d65761CF81bB00320BE7989C5DDD4f]=true;
        _allowList[0xc8cf25c6FD75c97E94d0A4edA01ffe47703bEDF6]=true;
        _allowList[0xE1f8b6d331b8c93f8f7C47b86B52cafe69f25fC1]=true;
        _allowList[0x1250DBB785833a0BBEA689298EAEEA88B6F23317]=true;
        _allowList[0xdB869ec912BBd37d322f05D3EBd845AbE19ef42F]=true;
        _allowList[0x3c6Deaf5C95717eD5442C9836dfC62C1e5E83164]=true;
        _allowList[0xdC47B7380bcbBa367671C8caF9F96F6494214183]=true;
        _allowList[0x2c79aC9f76c3310B59D4C5E3FD214a73AEC68553]=true;
        _allowList[0xdE5fB7260d57BA0E4F7F1BEAB6217f5A6cEDfE85]=true;
        _allowList[0xe68c0650A819d1c4c9f541a0dADBB457CC793419]=true;
        _allowList[0x36C5EbCfb53dBd2B304fb75C208f022430607058]=true;
        _allowList[0xEEDfb23b3CDaa722e88B082ceC11EBc6838665d4]=true;
        _allowList[0x933707B556a6d32177dB68600cD6f0e704B53FC1]=true;
        _allowList[0x96025F21F49d7f63F38e43cfC8498EF1cc396497]=true;
        _allowList[0x36f77c3cb4E777F04e12F083A255955601Fb91d8]=true;
        _allowList[0x2225723952dc1DB233A4ACD6b752729e6c9DC376]=true;
        _allowList[0xB3D2ecEf92Dd0130DdD8EaC286528b7E70df4Ee4]=true;
        _allowList[0xed11924CE2f6d832b8fb7993268f1A23770dba88]=true;
        _allowList[0x6860C9323d4976615ae515Ab4b0039d7399E7CC8]=true;
        _allowList[0x72256967d7933d87840a76b4546EA9c6f5659ed5]=true;
        _allowList[0x199C4f59804eA806309616733d9ab02F88bC8524]=true;
        _allowList[0x9DebCB17f2AfAe04bC7a0c7b66A8f4f904313aDf]=true;
        _allowList[0x877a0762FAc76005816618CaFC62223a9689a6Ca]=true;
        _allowList[0x8c80E286678eE035c29392eD3b3B5e043fD55dEF]=true;
        _allowList[0xADAae0CF49B422fB24cB988d669e77F4E015608c]=true;
        _allowList[0x9D80c6F372b13a6e58fb08df11272b8dBFAA3779]=true;
        _allowList[0xE18e6002c7Ce832b2a6A23c6C00c04CFf461A56D]=true;
        _allowList[0x736e0a7Be8c4b8E96e9E300974F68D5ff5C86911]=true;
        _allowList[0x882FF1134F17017fE2c1F4B464EEe7d4f0B0d476]=true;
        _allowList[0xF0bF1C59ee9b78A2Ce5763165e1B6B24Cb35fD8A]=true;
        _allowList[0x0c7cf2EB315eAE5473a58D5bc096aD6645bd8d86]=true;
        _allowList[0xCFf01b81fbBc4C534619918599fC4625d977F1F1]=true;
        _allowList[0x476dd09cCF3e8F1aF9f25719F76EDA376D09F4A6]=true;
        _allowList[0x9e2328ebaaCeB57FD83e5bF109e0809Bba210D76]=true;
        _allowList[0xf83a126b9371655F02F8D9486d9cCEe606DdCEED]=true;
        _allowList[0xc501B327a682c268400639f8eC3B8039695a07ef]=true;
        _allowList[0xBCb8951810Ed55010FE0F43e5B4130Ed0c55333e]=true;
        _allowList[0xDC85Fe5DE6fdB27ea980d1027FFA1833aCf12a05]=true;
        _allowList[0x57D0A76320Bb11a06f0A193b22a60441a06aae8F]=true;
        _allowList[0x7fA77093e83C9292C2357ea799AC2C57EC138203]=true;
        _allowList[0xdEf6abb057A37aeCc03E47552011b668ab5F6F55]=true;
        _allowList[0x3D7cfA343B7b87559C61D58462DdFe6D5EE30658]=true;
        _allowList[0xBD66d837A0f034e88EdeA79F7b9d61ccdd6fB0CC]=true;
        _allowList[0x4E7932e035489ac4c9E5d4c849C4C93C623ccCb3]=true;
        _allowList[0x2B4f7FEC7D0C9D94993EBB3FeDC0F87f0cEB7e5c]=true;
        _allowList[0x3a66F923e59E969609CD24Be579084e363cab0Df]=true;
        _allowList[0xeb90D706F04fBaD5feFe8891045eecBB2dD783C6]=true;
        _allowList[0xe4f04b5c35b9bC0A3704a77Abb2c990298E5605A]=true;
        _allowList[0x47493C98c663De61092a61365CEc07569703e761]=true;
        _allowList[0xbe69A9Fb57aBC64AA6758f97c6a36Cd97Da8B3bC]=true;
        _allowList[0x1afd5184AD81D4D27afE507141Bf8013E3C7d5FC]=true;
        _allowList[0x9A0078620b68CAEA268FdC85395B4b2fbE435EDf]=true;
        _allowList[0x9E3D6025e4A8AdA9F437E5b17aC3f549200DaC2A]=true;
        _allowList[0x22Cf007B5C2245211fB05B9F0fD96d3B791c5f81]=true;
        _allowList[0xc906B0c46fc44a44D9d55bc09A8841AA13B76104]=true;
        _allowList[0x1569e9232773cb532c027Ebe262E699153A71D70]=true;
        _allowList[0x61Ccc816EeEA3D14A00604EB0e85eD2962315032]=true;
        _allowList[0x9004Dd38aB40d488151059599a7275eF0915D5F7]=true;
        _allowList[0x660a60B72FA92132E5e2f03ca6977544a000893F]=true;
        _allowList[0x4233C93649444871FdB2a5bB63ab548F41E9a71f]=true;
        _allowList[0x27eCe61C5bC34809DcC368De12C4f39614f77376]=true;
        _allowList[0xC6239cd97a08025C57a0880619Aa17BAbB165d36]=true;
        _allowList[0x41d9D2eF3A1af44613777418Cf6452170d78d844]=true;
        _allowList[0xA2dD3dD77e83fc9B7423d1b089D178a06acaa8B1]=true;
        _allowList[0x2251676d1Ff6FA9A10878205E5107a399BDa4F16]=true;
        _allowList[0x34Ab707d42717043a72Afc54DFF1DDDB1833cb0B]=true;
        _allowList[0x01d8978564fDe99FC4609892ac7b605f85600803]=true;
        _allowList[0xA21b8C1253e0d9287bbda6ee42cB583A338d5600]=true;
        _allowList[0x43d3086F1f329227dae2341A0dAF19132578C867]=true;
        _allowList[0xb8A79871C8e2CADeA84cC90310eF233Bc764D5eB]=true;
        _allowList[0x5375B3ECC262d21e8Bd00F2681aCedc53765F4eb]=true;
        _allowList[0x218d5638Bf697e22EbB3CD4B6fbf73DCD1A8F035]=true;
        _allowList[0xd7c82352118A8b68a3043266aebc66e148Ed3755]=true;
        _allowList[0xB14Da89AeAA3fC9eefD73E0D93A7952ee3D51E66]=true;
        _allowList[0x0604E3F8dA1771e17b9672aA18A705001ce30Be2]=true;
        _allowList[0x2535314106f7A3E8390B847a918Cc5D38d046f97]=true;
        _allowList[0x1CccFDBaD92675f7212cb264e4FdCbd8699a81dE]=true;
        _allowList[0x7e01EbF8Ba839E71dCC663cB2E7eCA0eA90CaD6F]=true;
        _allowList[0xaa114724F2bCBD859d01585435E3076671314D2E]=true;
        _allowList[0x52F87DEaD80104256A9A35295bd4155C75082E7c]=true;
        _allowList[0x9c0089dfF60cF55854Db24b1f560619988AdA7F3]=true;
        _allowList[0x0F3E5F4D5033C8EEAe3b5feac3C6c51A23c7A852]=true;
        _allowList[0xDDC628Ca39016AF4283B83EdF2d426A2EcBB732c]=true;
        _allowList[0x8A87164E62c031fc6eA951dCF827134015FEFa61]=true;
        _allowList[0xdbEFee517025559E7898d3a48f18221C32D3Fcf5]=true;
        _allowList[0x5b20b4bFe7A3F32969f53Ae43c9BC8696553C5aa]=true;
        _allowList[0x7E719b6c7f81a4C3b572cB1b0F102f9921306787]=true;
        _allowList[0x14eF92bC08611eEBaC0cED6373A0c08034848948]=true;
        _allowList[0xC091C86f56Ac120815A528d3F68D9Ab1a3BE7BA8]=true;
        _allowList[0x3FfbFd5d177b5D306A2bEfCB0d3F9613d6F32eD2]=true;
        _allowList[0xF7b617acA6075909A78cc4921C909b90010E55fd]=true;
        _allowList[0xd4faB4f5F5DDb5f459b85C48aDA8FBaC238f0Ab6]=true;
        _allowList[0xcd8Cf64b220E3d10fBB175a22BE7c42E8AcA0014]=true;
        _allowList[0xa0558eD99BFA1260421Ae7a0d2069899EDa68021]=true;
        _allowList[0x2D5CdDa4643beB674182b9D75C144AF39cC7196e]=true;
        _allowList[0xF98f6d9B5B1d4f226cA7E4fdC20b75d44fb12B58]=true;
        _allowList[0xB5BC2701c6f5373ECE42F7DF157dBDee8798af67]=true;
        _allowList[0x9D1766d3EB95D68A4c5B82F904A93424DBa230e9]=true;
        _allowList[0xa925E1fDeEE5E2BF60cd257d1FFCFf6f4d8775D1]=true;
        _allowList[0x5370Bb6ADc4818B1641D1105bfe0984B684E3661]=true;
        _allowList[0xE996929df7b68e2eC2F57432e9BB4Fb879aEDA77]=true;
        _allowList[0xFaf6bb8F1a300130fB9dc582DC8363a50841882D]=true;
        _allowList[0xa61696402876aEb0d23E343DA8e48A5C05eCa45F]=true;
        _allowList[0x4ea54430e7D588Ef5d009C1b9d7E4d06a35565b5]=true;
        _allowList[0xa97c7af7532e661DB802069571920A718338618d]=true;
        _allowList[0x2c7F66A4F33ec1BfB6CAe0326da665133Bf6d830]=true;
        _allowList[0xf8091A1A3055C9a8a7492E7Dcc31162D000747C7]=true;
        _allowList[0x13a1DB3301fE0dd554aA4Cd4fDA4e27fa1f63Bba]=true;
        _allowList[0x7b17dF087859f731a2097fe040a1af3B70DF3c95]=true;
        _allowList[0x54E26f921313E98CB9e263e64DDff83239Aa3837]=true;
        _allowList[0xf706C06CfcDa4C03420a532361b51cE30885A187]=true;
        _allowList[0x920450c569E148404BfAD97B81728262230F980D]=true;
        _allowList[0x152C3d6ADe7424e43763ec2A582Dd411459b229c]=true;
        _allowList[0x42bBEce6eEa8F3E90466E798849838Aca9e7181D]=true;
        _allowList[0x156306d98B426521573e4789F3de09850b03D309]=true;
        _allowList[0x4e93aE6aD41f4E32A210b0067cd35dD1CcDdb8C4]=true;
        _allowList[0xF0e2ac11c872E5B993dCA0CAb8c41773F529f0d5]=true;
        _allowList[0x6e19cE8aF8c4Eb668840680a38C12FD7390Cdc42]=true;
        _allowList[0x694C80A5c910586b894bDf51e711d9127783a76f]=true;
        _allowList[0x49f1509a1042BED9ABD5721b29780B45EdEC435A]=true;
        _allowList[0x0b50844B7b1E4885c3498f047Cc6dcc36103313E]=true;
        _allowList[0xaC9f48825c51f16125d03583376Fb170E94e0A79]=true;
        _allowList[0x0817E382a40d484A8b90C792b399667174E50aB8]=true;
        _allowList[0x17B9fCf6fea88b21075b4dECce026a24f3C53C9b]=true;
        _allowList[0xa628D3a520c20C55d200Aa1Bd4ce7CAC0386d2aE]=true;
        _allowList[0xDD2C0120e177457BDcbF3b94Af30fD118d6b09cB]=true;
        _allowList[0x6946ae4360d19f4821e1009C51bF5Da1E50736db]=true;
        _allowList[0xbEeBE2cd0AEF888230945EA40767B62C9570299C]=true;
        _allowList[0xf45D07e683caE570D56300A108A6D6B1E7F1Dc79]=true;
        _allowList[0xA334e6E97260B22728521171ab12017Da3c36609]=true;
        _allowList[0xFbEeBEFA8DB8B3df57e89E739bbD461bCe7E9109]=true;
        _allowList[0x8752CaF9F5dB7E5D1375866525b7c8fE12826dBF]=true;
        _allowList[0xd879B9a1112759d5f1e64553f20B66B5Ede13F2f]=true;
        _allowList[0x2e307Ceab1b4c5F4cAc508E3B13C3dBfe86a3c81]=true;
        _allowList[0x894085BBFdDBd1e5257ed33886BF1B3bA3cfb492]=true;
        _allowList[0x911bD2dd808882AA4B347745a9A688D616110A1c]=true;
        _allowList[0xC820417B367FFa330d1Fd1ea829d82F32c108601]=true;
        _allowList[0x71281411a338C9Fb813cA350510F805A6AA54990]=true;
        _allowList[0xd7062b24e96e82e7506E90730A39175C5e9e68E7]=true;
        _allowList[0x1Da98aa4FaEFB6eC93cC1bA6AdcFB59c8aF51152]=true;
        _allowList[0xe0bFf868219253510a275fdddd14B4Bdf859Ee83]=true;
        _allowList[0x44340F7dc53bF90363E503350bbEDf69e2D7870c]=true;
        _allowList[0x8ab83D869f2Bc250b781D26F6584fd5c562FdD9D]=true;
        _allowList[0x9C26583abDAD7A5551fC1E85097A161B76e16450]=true;
        _allowList[0x95dD010D54Efb6B4fcD040dBBd93eeE8f2acc7a2]=true;
        _allowList[0xAdE29cAeCbAb402527e757dd078a150D295379b7]=true;
        _allowList[0x81BeBeF0Ff62A9D1d80353B3FA2124b7c8f820Af]=true;
        _allowList[0x082ed91C65EcbA6Ac147B115f661B1c7b584D23C]=true;
        _allowList[0x4ECF5BC9A031bF984D2a00D3f9eEf0BA6c7f692c]=true;
        _allowList[0xf08C831bE98B0e4482Bc9411B435664Ea3f84cE0]=true;
        _allowList[0xb50A1Cb62eaB623c785aBa912F59B69F69fcC0cf]=true;
        _allowList[0xe71D0fB50Ab4e57e69B814c63aBF1A91a830F447]=true;
        _allowList[0xE688f6c910ee98f2cf5d12192C7280a81205B3AF]=true;
        _allowList[0xE918973ae1e3bD95D0D9D30059404fe0C7Ff0eAA]=true;
        _allowList[0xF8d7daF9DaA9c1F8beFBc87A958f778Ca5A7cc3B]=true;
        _allowList[0x7B93A0205e9F4F389A1BCbb266f9DD23D1Ad6f4b]=true;
        _allowList[0x51aba10f51cde855B48df6fD8B01d70AFcea2C71]=true;
        _allowList[0xE4559A7ee19F6a66D7b1DB3Dce507D30C481aE35]=true;
        _allowList[0x83742fAdDdE0b5b2b307Ac46F24a1C118d332549]=true;
        _allowList[0x792b4Ed2b3DDBCEf0A3ae09810f3925105A3d6c1]=true;
        _allowList[0x8DAff7be83F1066DE2873449ada2b7A33E3F6A22]=true;
        _allowList[0xa0aE9FD0168214A67389090aaee1b534Dbe72d4b]=true;
        _allowList[0x0e1072D89569FFAc2B68fD6bf2e433F071806B6c]=true;
        _allowList[0x165c55362690c34EDE6aBd699bc0E76818DBe870]=true;
        _allowList[0x6Db5E720a947c7Cc2f3FcaD4Cf5058402FC456c6]=true;
        _allowList[0x503105C030eaF77C4411a28BCd479D47D3f1AB64]=true;
        _allowList[0xD2dF3edA1c5146C4D94ef020D539DFd60005bDEd]=true;
        _allowList[0x70b26A35F8f308eF8286798c33b4f7a1811c7630]=true;
        _allowList[0x9Dcf33d6BE32ecF8846f05c4407781bCE8e59A89]=true;
        _allowList[0x817e1d0D580C4BD21dB8BdA15d326c3d76B6ccC5]=true;
        _allowList[0xDE26b5A134c7e6F6f9a041B71C701430e9FA9630]=true;
        _allowList[0x4C61496e282BA45975B6863f14aEEd35D686aBfE]=true;
        _allowList[0xAd49b3d265008a437d828C0c7C5096958cde5f62]=true;
        _allowList[0x7A1853B856964898E45d4443065C3bA720958C00]=true;
        _allowList[0xde67c92c7281dE52097880412Ea2dc2f85E578A6]=true;
        _allowList[0xdEa68e767890f4711ADa53c3aed81a26FeC5cEa8]=true;
        _allowList[0xCafde7463D1a7bAd5E635602CF57029B6aD8795F]=true;
        _allowList[0xE27f91dD0aC362EbA67b7Fc7f88187df25509d6d]=true;
        _allowList[0x2fb230336C189914aC28b256c544674e47Bc9925]=true;
        _allowList[0x54E9aD1D7c15a581575C727c68888D19d71496b1]=true;
        _allowList[0x63B2D34cd3a3a224389Af8f410D9E528c30f2EbD]=true;
        _allowList[0x90d9172c62a0206848B1eC83A35065bd61bA0f08]=true;
        _allowList[0xb30C65a6544967CB79fd13a610374d4B1451eDd9]=true;
        _allowList[0x2AcEa0FAAaFFDe5Add96541Ce8079F2A0cC8CF4A]=true;
        _allowList[0xDB79b9D1FFB602Aa4E62241A83B7c70FB6e6D5C4]=true;
        _allowList[0xB874c334B78abD95402F18CE02b99EA145Bd8709]=true;
        _allowList[0x0C8EcC562C855A20841499813F1cFE1abE23c2B1]=true;
        _allowList[0xa66F733bd30A6CF895f78d3BF1B116060bb77F6C]=true;
        _allowList[0xbC8cA0906e478fffbf4F3DAe3Da456814fb14416]=true;
        _allowList[0xe86EFc1C9E7f23700508942A36bA3efF6553F20d]=true;
        _allowList[0x576B08bcbCe27180be35EFAF2F67d66b8e9bEbC2]=true;
        _allowList[0x14C4Fa9c3dF3C225eA8aAc7Ea40692c0Df1e1Ed7]=true;
        _allowList[0x0BaBb77C909Ae6Df906dc47B40AA9d63A164Eb01]=true;
        _allowList[0x3A51E8cb35cC1d458E995b66A6b88569494429e2]=true;
        _allowList[0x5257aD2570eB10249EC03Aa023e14e2c4De6EE86]=true;
        _allowList[0xBe02f3095985feF7Ba4cce00B43d043B2974A009]=true;
        _allowList[0x297Eb64Bc880a7a39B3D326aA8f9B4c1597B50Dc]=true;
        _allowList[0x4F65758795E0C8b1d3a3B6F841C301782e4b2f94]=true;
        _allowList[0x924e4fA75d441eED0b007d724E2FeE7ceBDDA7Fb]=true;
        _allowList[0x1cED02157579a61eFD97973CB198f63f635729C3]=true;
        _allowList[0xD06150ffFb00169c3cCE35C2b9fF27adAf6dfD52]=true;
        _allowList[0xC38233e8666b888EF17AFA814a855F888c32dA9c]=true;
        _allowList[0x5F2f0Ea12798ef824B26711d763DB33648eB77e8]=true;
        _allowList[0x28A0E828Fc3108011bA7b6aE45020C3310F8C386]=true;
        _allowList[0x00669F9D9ff7F72E83d49F3D955fFb3e87C77971]=true;
        _allowList[0x74da634DEA0B9CdF3A80e36943928D614f4Ccd20]=true;
        _allowList[0x58270BF3101D2153e19732D8A67c6F6E3b9f0F95]=true;
        _allowList[0x4dC12B0a36ab76542f7B74b58997A15Bf42af3e4]=true;
        _allowList[0x7f64d79293b8eaB2ad215AA17EEc4733abAA9e62]=true;
        _allowList[0xe0cfC96D177F1d0C222FA651518ab7cF08AEECeb]=true;
        _allowList[0x94707969050620655495750cf55DD3BF20E640Bf]=true;
        _allowList[0x14Cd8F10C282Dac0FC3d7D558FDdBE476feFbf76]=true;
        _allowList[0x15b68E412aD935bedAAaDb59133E4675BDC0988d]=true;
        _allowList[0x9752Ff185Fc7CeFa514398068731a60BAe3ec224]=true;
        _allowList[0x6F04833195De49aB7021c76F6C756ffa41CaD262]=true;
        _allowList[0xa6a15056f8DA65E91776bfcDb831eCA37E067133]=true;
        _allowList[0x4c6AB491dE3cdE727D931C079348E700EA675472]=true;
        _allowList[0x6B40459C0974F63987e628E68a6eAdE6a4dEE2c0]=true;
        _allowList[0x3d21175Ad1A18A262072e825CA9aC9cB962C8E0D]=true;
        _allowList[0xb83078cA87F43bB9fD7a4A93C0A716Eccb098559]=true;
        _allowList[0xAf6A78083708cAe7AEAd9C96A1475eB25C671Fbd]=true;
        _allowList[0xcb7e797c81E402448939d8A0b1427D394cbfE18a]=true;
        _allowList[0xfEA9B1760505fe0ac6ac48c30Bc81c9D7431f554]=true;
        _allowList[0xdae2d80e803e7e7bc279309EDE4E039788B4936D]=true;
        _allowList[0x24FF079523D017AD15636420F37e9013a3E47a08]=true;
        _allowList[0x6E24AC7A957bA929e48E298c75F6b76D0cDFa901]=true;
        _allowList[0x09379A0248Fe1EEeC49fBF01Dd4586fAfceB349e]=true;
        _allowList[0x72a2E41994A242a1d0a536Ce5823142f123204cE]=true;
        _allowList[0xFd3AA49af3BE98b8d9ac6e676891867bf34137fA]=true;
        _allowList[0xCE4A546B623c15E92889DF8E77F6601a0Af55008]=true;
        _allowList[0xf0245B2ef5befe163d77E4cEe8D0242f422209eb]=true;
        _allowList[0x887F4ae78D3F2219998b75Bc8fC2C9d9673a942a]=true;
        _allowList[0x73BcBAE654B6239132718e5a3c4B3ceecdED4b4e]=true;
        _allowList[0x992984C607644B42d4A491f51A0191b0B59F4569]=true;
        _allowList[0xE9f76e57388Cf5AB613A1671027109188Cf7789C]=true;
        _allowList[0x54BF374c1a0eb4C52017Cc52Cf1633327EE3E985]=true;
        _allowList[0x99b14277fd7b21107184f4eDED83254bA573E689]=true;
        _allowList[0xF140fEf0d5843DC9C7c30aC1Aa46750aaeD5a24F]=true;
        _allowList[0x1F441c82F5a5dba80CE2D56C993D1f0539ff19B7]=true;
        _allowList[0x07ea2201512f174b8e020efC8021a163F4143Ee8]=true;
        _allowList[0xC1CBFD0f49450878C074e3935554002201Db3235]=true;
        _allowList[0x707a7096D339975De22D1fEf8ff827790C3A1cd1]=true;
        _allowList[0x94DfE15282C232EF941D53AAEecAD2b7369b46FE]=true;
        _allowList[0x5f0D42172D2f1dF71224eFFe0161Fa59Dc25F625]=true;
        _allowList[0x9F286319BE34810f17FdaD364D9CCaefac31407D]=true;
        _allowList[0xb5dD21026a88770986C3FC676aE0DB6092f63Dde]=true;
        _allowList[0x3426A6a37cb469273B4e3fA3DaD53BC3A45a8ec3]=true;
        _allowList[0x70d9f98EA60658fD81Cc54086006E949AEE207F3]=true;
        _allowList[0xcE3595bcFdf3A901335364f628F58Ccebdd53c4E]=true;
        _allowList[0x41CFcC63981CD09201A37dF7f515307FBaDf51F8]=true;
        _allowList[0x64a2aB112Ab608a185A7358e7c3D3ce69D824Ec0]=true;
        _allowList[0xD5F7818b117193509382E734c9C4EBB517461B9a]=true;
        _allowList[0x32c6d855ee1ABbcb96Ff7635Fb14F4329C9e45F4]=true;
        _allowList[0x4D69C8Dc5AF12b9CAE0c4dC0A6440C4C0170aa63]=true;
        _allowList[0x504f0BAf0810a9A3265BEBe18ee25474800ffc45]=true;
        _allowList[0xa2F0448f346cE50B9029506c88Dfa58d07bAF880]=true;
        _allowList[0x2283e3E2820F6DB70eB6FA94Bf2C189652290D25]=true;
        _allowList[0x836B8145afcB81b995ACaDcFEFeFb2dCd399ae4a]=true;
        _allowList[0xd2cE4bDDd7CeDAa8B04d5F13b1Ece8f0D09740e9]=true;
        _allowList[0x75C6F6D54440441cAbcf53ff2Ebe63cD3218099E]=true;
        _allowList[0x5f08F3e687D907b976e1E24435b093d577982c74]=true;
        _allowList[0x0ebaB817a620E826732A5E94E1AF8dF100f04dB8]=true;
        _allowList[0xb7b008b162096fC66dae91fA63f9baf0C8150db8]=true;
        _allowList[0xD1DC0BCf70362A13F0a5f657f1Ad41A9E203E62c]=true;
        _allowList[0x049894C74ed994d904Ce34E56c4E45Ce150aF15C]=true;
        _allowList[0x34db35639EAfe2712aE1F69dfa298b06a5c25053]=true;
        _allowList[0xC93730E3b7bF06E392CDDe0dD0455A79A8C3Fe55]=true;
        _allowList[0xFc0048E8FCB0Bc74bEa2DbA777a6c556C1E34a83]=true;
        _allowList[0xC311d98916960F6DB4D514a47019F9dcb43eba57]=true;
        _allowList[0x660849eC825B8FE543F79A84A17B58a99C2Bb7fF]=true;
        _allowList[0x731Ed355833856dC1a004354EF06E6157B657264]=true;
        _allowList[0x4b47B59c5B8119bB7AfB41361303EF0f1C1D662A]=true;
        _allowList[0x7b7f11Fd3ef5615F607FF33EA4dFF30774B7b30c]=true;
        _allowList[0x0ff4A39c460Cd75767C60776d254F7Bf822caa01]=true;
        _allowList[0xF3b3AB6c4BA3Ec7434e0461Dd801e258A6b93004]=true;
        _allowList[0xB99ad00Ae0b27d980a4C236C41ED685D2bfe159a]=true;
        _allowList[0x03756d5B8f9Fb42abb735AeD6126dFb344eBbA43]=true;
        _allowList[0xf483e340848695aa9A2c78D7AB5758a9faE97d61]=true;
        _allowList[0x3Ab3F43A2Af6B00c639A4eD5143caf788da68377]=true;
        _allowList[0xFC0ce11136adc4fdA3c5DCD66f3b4C472aA5FFE4]=true;
        _allowList[0xC0509a3ce4225410C94029C3834e493B9d7E89F2]=true;
        _allowList[0x8aEF89129806B23C7930DFdf2B46E22ae1849c49]=true;
        _allowList[0x7fE1533C2e9AaB11d0e5074274EdC53Eeff8d840]=true;
        _allowList[0x5299582ba59EA5609BB9950E969f5041d1e01C23]=true;
        _allowList[0x3330777CC5270dB65E7dF1D738E989DC16Dd49f2]=true;
        _allowList[0x54BF664369c38785827DBA60Cf5a05d1bc68a0f0]=true;
        _allowList[0x4939C898da18b0c1E71DC2A42aa545AD228711B5]=true;
        _allowList[0xB1892b7a383697D10A9419eB132598F3F4bC8dD1]=true;
        _allowList[0x0e121D0C8c695A18d504714B1f4608b6EDa944a7]=true;
        _allowList[0xC9b378a35C6C2e9971F74b0A75662Aa664B3F391]=true;
        _allowList[0xbDf7EcD3938bC86373D15709fE09DcF9Bb677ca7]=true;
        _allowList[0x145Ca5302130bEcfcAEbA9AD93DE2f4dB4d3A72e]=true;
        _allowList[0x86ce39cB7f3F68D848F2a867c73Aa080AeAece97]=true;
        _allowList[0x6885dB8e9e82682e9219F1A3cB46D2B92C68fbD0]=true;
        _allowList[0x21c62b005e6e8123C33f0008DeBca41ba785F304]=true;
        _allowList[0x7ECF5D15862074d311c282E2b47aEeEdcFd20376]=true;
        _allowList[0xD58082F2dFB159670D85634a9a9de505c46a8E2e]=true;
        _allowList[0xD15d558cb022566CE7C291d1f229420BcA842349]=true;
        _allowList[0x915fB20645A6EC5285Ef298a93D25Ee787f1a1b2]=true;
        _allowList[0xCB17C8e39Ec71Ec7d9D0738275Eb0963A9aBC680]=true;
        _allowList[0x566ED43d3a275C0a6C394933c1a378050623876c]=true;
        _allowList[0x5C3C8d61AA8555dddCf85F10A792056Bd1bbdfc9]=true;
        _allowList[0x9f882cB17b6A3F53fE0B65A9B3f73BAc68a22468]=true;
        _allowList[0x413e81d8F46CD69733F7714cE6F5D6C8f47c5843]=true;
        _allowList[0x2855E8D5d8DF7009ccC204eAf328ce1a8DaC5441]=true;
        _allowList[0xCf25264f6d7D2305990872BE968125ed757Deba0]=true;
        _allowList[0x0D6DE7038B400f610d94E2d04edE9BAeF9d2376E]=true;
        _allowList[0xa257413252A3A1C367AE443a60d9d5Ea1921dF17]=true;
        _allowList[0xb261F055621fb3D19b86CD87d499b5aD9a561115]=true;
        _allowList[0x85eb62F5748E50AaD4584B2bc9e0176fBe247b49]=true;
        _allowList[0xa163C4210Dc1Cb11ff85EF292eb02345858b88f9]=true;
        _allowList[0xa45A3692e37089cE1AFEc88921650Cd1f1C2c6bD]=true;
        _allowList[0x98BB3A3921200017ebd0aF803aeDDD464e70E791]=true;
        _allowList[0x3e25dac1092031116E2A7d59953dCEC2824A6C6A]=true;
        _allowList[0xE61350D0b293b0516a83B610EA835C50D83Dca23]=true;
        _allowList[0x707d27D62411baEcd11f78482A8b3ACF03936f5d]=true;
        _allowList[0xDD60fC8E5c7bF835AB60437387344a0686924868]=true;
        _allowList[0xA5D5Daf174E495D1EAfcC18968FdA7c2927AB94C]=true;
        _allowList[0xDd5B66E6905f83442Bc4eF691aE2fd4f731c1c8C]=true;
        _allowList[0x19e39B0c71A4D6D2b615Bc4B6F6dc36eE7aeb5d3]=true;
        _allowList[0xD789b9Ed2092917472fb13bb746858B2F65f1aDA]=true;
        _allowList[0xc4996857d25e902eBEa251621b758F86D3761C0f]=true;
        _allowList[0xEb546f8DECE2463b7EE9c5A09BF2F741ec705daA]=true;
        _allowList[0xdF7bf4Ecd80d836646125794933b0Ae128F724Dd]=true;
        _allowList[0xe45432CcDC6b2B2674bB1657f9f566c9b400e7ac]=true;
        _allowList[0xa7bce13c268c132eAfA61633827B872a248Cb352]=true;
        _allowList[0x3a017854138C5f9b85b0457b832151B28213b6E6]=true;
        _allowList[0xDdE7b1103d7Bb19982ef9c6d9a348a0C0ea7e132]=true;
        _allowList[0x7c17D8dfCfC5672df200acfFe41FcD5c81252566]=true;
        _allowList[0x802720F980e5f9bD7358Ad0bd9caA272d0173E00]=true;
        _allowList[0xd02840d5853fCddD802cc957D00b7Df04a63ee5e]=true;
        _allowList[0xA3264a6B18b0e43DA9C7C235B5434294C2f9B10D]=true;
        _allowList[0xb822714d379aA6C0FDb7aefDEdCeB7616f83680b]=true;
        _allowList[0x973a2acE28745ce4715659C60Ef70B9E4c044086]=true;
        _allowList[0x4e9CFd9dc692565e61E157e1F61339D869381B50]=true;
        _allowList[0x67BF9615891Ea8879903858D8AFe56c980CE0962]=true;
        _allowList[0x791BdbC87f3eaFD6341bBFa54173ab8d81C6aA58]=true;
        _allowList[0x30E9Bd42A34059E59613d80E35FC8FE45861Be33]=true;
        _allowList[0x2e8D1eAd7Ba51e04c2A8ec40a8A3eD49CC4E1ceF]=true;
        _allowList[0x5Add76ACC48e1BB1a434da15d32d4a6734869430]=true;
        _allowList[0x4a5c27fc6d10e8A0feC4F2D504eD5bd05b4A4c4F]=true;
        _allowList[0x0E68ec6237f1294335647012B678E385f9dF3C22]=true;
        _allowList[0xE5AE91c6267f22D1F5AA50aC953025a7A36ed36B]=true;
        _allowList[0x040b104d7Cb4557EBaEf0122a4b8cbC073f1a021]=true;
        _allowList[0xBBE30cDe30a4b7f56602D72a2EDd9b6E61c424d3]=true;
        _allowList[0xda1B25a4bD1ae5380FdAEf207dc3a5999C5D8B80]=true;
        _allowList[0x2ec970270130EdbA7D9B1f0f7cE7DFb3d1f6Cf6a]=true;
        _allowList[0x91Bb0008b406ddfd9c5F66655d2AF77FbE7C99B7]=true;
        _allowList[0x4aEb7ea57E3f83d620FefCe39F27D79668e40aA2]=true;
        _allowList[0x5c5F1Fc018D9989D1F617f1cCEc6c2Da0e6ca06A]=true;
        _allowList[0xED9f922304a7bc4CD1f1C3611060D8486Fbd7c4b]=true;
        _allowList[0x413eE671f3351f54CDeC60BFabfFca7E7E5A32f7]=true;
        _allowList[0xC938100605505290fe55fEf5901626f12Ed45700]=true;
        _allowList[0xe60253102546CE672E550F0b537e3FEe3fE3B6c5]=true;
        _allowList[0x029Cb4D9566ef3B9E277C2E5887cE2C891D04EeD]=true;
        _allowList[0xf8817128624eA0Ca15400dEE922D81121c9B9839]=true;
        _allowList[0xe5f2f34BF34A74384EA09005818A74B953B15359]=true;
        _allowList[0x443bd36Fa4BbeD299173911b6E51c4f08Eb99C8F]=true;
        _allowList[0x0B4AE84E396aEe628C562449Bc6d49968c1E1AEf]=true;
        _allowList[0x059360DbE7aC512675CDdD37414C8083A6E2eD0F]=true;
        _allowList[0x397725CD38e28C497bB4A6862cbEBe69e7A922cD]=true;
        _allowList[0xf70EB1ab344d8066c4f74b125B7ab1e2404914E1]=true;
        _allowList[0xE6dc0034eDD9126dA7e0c5a398D8E7dC71171Fea]=true;
        _allowList[0x13AbB285529729ED8ACeCFf3Da52351e991F650e]=true;
        _allowList[0x8D35625c3D457bC03fF8AE2EC48FB023ffb05b3A]=true;
        _allowList[0xF75a7D7cC5991630FB44EAA74D938bd28e35E87E]=true;
        _allowList[0x93D020b0C5158939274235EE9E670eDb9612726e]=true;
        _allowList[0x44532990EaFfD73dbB2086b2a4124455bD7F1bC7]=true;
        _allowList[0x13aeA819C2b5f3bd409A6A7612A0C7A414Fc02F5]=true;
        _allowList[0x626CE14BD71d7f3B9AC33966AAa7611A4f5cBd2a]=true;
        _allowList[0x2829d75963e0f9475c31E8Dd014152b3AD2efC6b]=true;
        _allowList[0xEA6F17757172B189342852744D17577408d0f6af]=true;
        _allowList[0xf181C6E3EFD05F7C90453C090d4700e26b5371C1]=true;
        _allowList[0xB237b9bde8BF11F30dE1cC2d83599A584D86d05c]=true;
        _allowList[0x08c3d4a4fE4e28F4ea0402fcCF35D5B81E8f1EC8]=true;
        _allowList[0xEa302cF778a1186843Ae10689695349f5388E0D9]=true;
        _allowList[0x0F8176c597aA2136b54bCA3F10e098c668fA2CcB]=true;
        _allowList[0x99B937DB7E11f1Abe6ee1795317912BE46E20140]=true;
        _allowList[0x45da9dD8b42145F8B02F928365970bDE51Df17Eb]=true;
        _allowList[0x544b7df6e96b6c5b3C78efe0bD05Fba68a878828]=true;
        _allowList[0xbEBbBf96F42a744d11A0Ed3F6b6372a900DbB793]=true;
    }

    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
       
    }

    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string memory URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // minting
    function minting(address to, uint256 numberOfTokens)
        external
        payable
        onlyOwner 
        {
            require(
                _publicLETTERS.current() < 1000,
                "Purchase would exceed LETTERS_PUBLIC"
            );
            
            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 tokenId = _publicLETTERS.current();
    
                if (_publicLETTERS.current() < LETTERS_PUBLIC) {
                    _publicLETTERS.increment();
                    _safeMint(to, tokenId);
                }
            }
    }
    
      function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
      }
    
      function setAllowListMaxMint(uint256 maxMint) external onlyOwner {
        allowListMaxMint = maxMint;
      }
      
      function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
            
          
          _allowList[addresses[i]] = true;
          
          /**
          * @dev We don't want to reset _allowListClaimed count
          * if we try to add someone more than once.
          */
          _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
      }
     
      
      function allowListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');
    
        return _allowListClaimed[owner];
      }
    
      function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
      }
    
      function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
    
          /// @dev We don't want to reset possible _allowListClaimed numbers.
          _allowList[addresses[i]] = false;
        }
      }
    
    function purchaseAllowList(uint256 numberOfTokens) external payable {
        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Can only mint up to 1 token"
        );
        require(
            balanceOf(msg.sender) < 1, 
            'Each address may only have 1 Letter'
        );
        require(isAllowListActive, 'Allow List is not active');
        require(_allowList[msg.sender], 'You are not on the Allow List');
        require(
            _publicLETTERS.current() < LETTERS_PUBLIC,
            "Purchase would exceed max"
        );
        require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');
        require(
            _publicLETTERS.current() < LETTERS_PUBLIC,
            "Purchase would exceed LETTERS_PUBLIC"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _publicLETTERS.current();

            if (_publicLETTERS.current() < LETTERS_PUBLIC) {
                _publicLETTERS.increment();
                _safeMint(msg.sender, tokenId);
            }
        }
      }

    function purchase(uint256 numberOfTokens) external payable {
        
        require(_isActive, "Contract is not active");
        
        require(
            balanceOf(msg.sender) < 1, 
            'Each address may only have 1 Letter'
        );
        
        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Can only mint up to 1 token"
        );
        require(
            _publicLETTERS.current() < LETTERS_PUBLIC,
            "Purchase would exceed LETTERS_PUBLIC"
        );
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _publicLETTERS.current();

            if (_publicLETTERS.current() < LETTERS_PUBLIC) {
                _publicLETTERS.increment();
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}