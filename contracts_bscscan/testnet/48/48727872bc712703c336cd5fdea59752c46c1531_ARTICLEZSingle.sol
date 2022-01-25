/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({BEP165Checker}).
 *
 * For an implementation, see {BEP165}.
 */
interface IBEP165 {
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

// File: @openzeppelin/contracts/token/BEP721/IBEP721.sol

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Required interface of an BEP721 compliant contract.
 */
interface IBEP721 is IBEP165 {
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
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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

// File: @openzeppelin/contracts/token/BEP721/IBEP721Receiver.sol

pragma solidity ^0.8.0;

/**
 * @title BEP721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from BEP721 asset contracts.
 */
interface IBEP721Receiver {
    /**
     * @dev Whenever an {IBEP721} `tokenId` token is transferred to this contract via {IBEP721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IBEP721.onBEP721Received.selector`.
     */
    function onBEP721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/BEP721/extensions/IBEP721Metadata.sol

pragma solidity ^0.8.0;

/**
 * @title BEP-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IBEP721Metadata is IBEP721 {
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/introspection/BEP165.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IBEP165} interface.
 *
 * Contracts that want to implement BEP165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {BEP165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract BEP165 is IBEP165 {
    /**
     * @dev See {IBEP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IBEP165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/BEP721/BEP721.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[BEP721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {BEP721Enumerable}.
 */
contract BEP721 is Context, BEP165, IBEP721, IBEP721Metadata {
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

    mapping(uint256 => mapping(address => uint256)) public balances;
    

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    mapping(uint256 => mapping(address => bool)) public checker;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IBEP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BEP165, IBEP165)
        returns (bool)
    {
        return
            interfaceId == type(IBEP721).interfaceId ||
            interfaceId == type(IBEP721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBEP721-balanceOf}.
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
            "BEP721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IBEP721-ownerOf}.
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
            "BEP721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IBEP721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IBEP721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IBEP721Metadata-tokenURI}.
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
            "BEP721Metadata: URI query for nonexistent token"
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
     * @dev See {IBEP721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = BEP721.ownerOf(tokenId);
        require(to != owner, "BEP721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "BEP721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IBEP721-getApproved}.
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
            "BEP721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IBEP721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "BEP721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IBEP721-isApprovedForAll}.
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
     * @dev See {IBEP721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "BEP721: transfer caller is not owner nor approved"
        );
        balances[tokenId][to] +=1;
        balances[tokenId][from] -=1;
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IBEP721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        balances[tokenId][to] +=1;
        balances[tokenId][from] -=1;
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IBEP721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(msg.sender == from || checker[tokenId][from] == true, "Not a Owner");
        _safeTransfer(from, to, tokenId, _data);
        if(msg.sender != from){
            checker[tokenId][from] = false;
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
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
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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
            _checkOnBEP721Received(from, to, tokenId, _data),
            "BEP721: transfer to non BEP721Receiver implementer"
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
            "BEP721: operator query for nonexistent token"
        );
        address owner = BEP721.ownerOf(tokenId);
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
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-BEP721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IBEP721Receiver-onBEP721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnBEP721Received(address(0), to, tokenId, _data),
            "BEP721: transfer to non BEP721Receiver implementer"
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
        require(to != address(0), "BEP721: mint to the zero address");
        require(!_exists(tokenId), "BEP721: token already minted");

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
        address owner = BEP721.ownerOf(tokenId);

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
            BEP721.ownerOf(tokenId) == from,
            "BEP721: transfer of token that is not own"
        );
        require(to != address(0), "BEP721: transfer to the zero address");

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
        emit Approval(BEP721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IBEP721Receiver-onBEP721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnBEP721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IBEP721Receiver(to).onBEP721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IBEP721Receiver(to).onBEP721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "BEP721: transfer to non BEP721Receiver implementer"
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

// File: @openzeppelin/contracts/token/BEP721/extensions/IBEP721Enumerable.sol

pragma solidity ^0.8.0;

/**
 * @title BEP-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IBEP721Enumerable is IBEP721 {
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

// File: @openzeppelin/contracts/token/BEP721/extensions/BEP721Enumerable.sol

pragma solidity ^0.8.0;

/**
 * @dev This implements an optional extension of {BEP721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract BEP721Enumerable is BEP721, IBEP721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IBEP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IBEP165, BEP721)
        returns (bool)
    {
        return
            interfaceId == type(IBEP721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBEP721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < BEP721.balanceOf(owner),
            "BEP721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IBEP721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IBEP721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < BEP721Enumerable.totalSupply(),
            "BEP721Enumerable: global index out of bounds"
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
        uint256 length = BEP721.balanceOf(to);
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

        uint256 lastTokenIndex = BEP721.balanceOf(from) - 1;
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

// File: @openzeppelin/contracts/token/BEP721/extensions/BEP721URIStorage.sol

pragma solidity ^0.8.0;

/**
 * @dev BEP721 token with storage based token URI management.
 */
abstract contract BEP721URIStorage is BEP721 {
    using Strings for uint256;
      struct Metadata {
        string name;
        string ipfsimage;
        string ipfsmetadata;
    }

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
        mapping(uint256 => Metadata) token_id;

    
    
   
    

    /**
     * @dev See {IBEP721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory ipfsmetadata)
    {
        require(
            _exists(tokenId),
            "BEP721URIStorage: URI query for nonexistent token"
        );

        // string memory _tokenURI = _tokenURIs[tokenId];

        // string memory base = _baseURI();
        require(_exists(tokenId), "token not minted");
        Metadata memory date = token_id[tokenId];
        ipfsmetadata= date.ipfsmetadata;
        // string memory ipfsmetadata = getmetadata(tokenId);

        return ipfsmetadata;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "BEP721URIStorage: URI set of nonexistent token"
        );
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

// File: @openzeppelin/contracts/token/BEP721/extensions/BEP721Burnable.sol

pragma solidity ^0.8.0;

/**
 * @title BEP721 Burnable Token
 * @dev BEP721 Token that can be irreversibly burned (destroyed).
 */
abstract contract BEP721Burnable is Context, BEP721, Ownable {
    using SafeMath for uint;
    /**
     * @dev Burns `tokenId`. See {BEP721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        if( msg.sender == owner()){
            address owner = BEP721.ownerOf(tokenId);
            balances[tokenId][owner].sub(1);
            _burn(tokenId);
        }
        else{
            require(balances[tokenId][msg.sender] == 1,"Not a Owner");
            balances[tokenId][msg.sender].sub(1);
            _burn(tokenId);
        }
        
    }
}

interface  BEP20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/newaidi.sol

pragma solidity ^0.8.0;

contract ARTICLEZSingle is
    BEP721,
    BEP721Enumerable,
    BEP721URIStorage,
    BEP721Burnable    
{
    event Approve(
        address indexed owner,
        uint256 indexed token_id,
        bool approved
    );
    event Promoevent(
        address indexed owner,
        uint256 indexed promo_id,
        uint256 indexed clickCount,
        bool approved
    );
    event OrderPlace(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event CancelOrder(address indexed from, uint256 indexed tokenId);
    event ChangePrice(address indexed from, uint256 indexed tokenId, uint256 indexed value);
    event AmtChecking(uint256 indexed approvevalue, uint256 indexed fee, uint256 netamount, uint256 roy);
    event TestChecking(string target, uint256 amt);
    event Checking(address indexed myaddr);

    using SafeMath for uint256;

    struct Order {
        uint256 tokenId;
        uint256 price;
    }
    struct RegUsers {
        address usraddr;
        uint256 rfee;
    }
    struct Token_Types {
        address addr;
        bool sale;
        bool mint;
        bool stake;
        bool bid;
        bool register;
        bool promotion;
        bool boost;
    }
    struct StakeTokens {
        bool claim;
        uint256 tokenId;
        address tokenOwner;
        uint256 datetime;
        uint256 datetimeClaimed;
    }

    struct BidTokens {
        uint256 tokenId;
        address addr;
        uint256 price;
        string tokenName;
        uint256 datetime;
        uint256 datetimeUpdated;
        bool completed;
    }

    mapping(address => mapping(uint256 => Order)) public order_place;
    mapping(address => RegUsers) public Reg_Users;
    mapping(string => Token_Types) public TokenTypes;

    // mapping(address => mapping(uint256 => StakeTokens)) public Stake_Tokens;
    mapping(uint256 => StakeTokens) public Stake_Tokens;
    // mapping(uint256 => BidTokens) public Bid_Tokens;
    mapping(uint256 => mapping(address => BidTokens)) public Bid_Tokens;

    mapping(uint256 => mapping(address => bool)) public checkOrder;
    mapping(uint256 => uint256) public totalQuantity;
    mapping(uint256 => bool) public _operatorApprovals;
    mapping(uint256 => address) public _creator;
    mapping(uint256 => uint256) public _royal;
    // mapping(string => address) private tokentype;

    uint256 public _tid;
    uint256 public _pid;
    uint256 public _boostId;
    uint256 private serviceValue;
    uint256 private authorRegFee;
    uint256 private authorRoyalty;
    uint256 private mint_fee;
    uint256 private claimaward;
    uint256 private promoTokenVal;
    uint256 private boostTokenVal;

    string private _currentBaseURI;

    constructor(
        uint256 id,
        uint256 pid,
        uint256 boostId,
        uint256 _serviceValue,
        uint256 _authorRegFee,
        uint256 _authorRoyalty,
        uint256 _mint_fee,
        uint256 _claimaward
    ) BEP721("ARTICLEZ", "ARTICLEZ") {
        _tid = id;
        _pid = pid;
        _boostId = boostId;
        serviceValue = _serviceValue;
        authorRegFee = _authorRegFee;
        authorRoyalty = _authorRoyalty;
        mint_fee = _mint_fee;
        claimaward = _claimaward;
    }

    function getServiceFee() public view returns(uint256){
        return serviceValue;
    }
    function setServiceFee(uint256 _serviceValue) public onlyOwner{
        serviceValue = _serviceValue;
    }
    function getRegFee() public view returns(uint256){
        return authorRegFee;
    }
    function SetRegFee(uint256 regfee) public onlyOwner{
        authorRegFee = regfee;
    }
    function getMintFee() public view returns(uint256){
        return mint_fee;
    }
    function SetMintFee(uint256 mintfee) public onlyOwner{
        mint_fee = mintfee;
    }
    function getAuthorRoyalty() public view returns(uint256){
        return authorRoyalty;
    }
    function SetAuthorRoyalty(uint256 authorRoy) public onlyOwner{
        authorRoyalty = authorRoy;
    }
    function getClaimAward() public view returns(uint256){
        return claimaward;
    }
    function SetClaimAward(uint256 claimAward) public onlyOwner{
        claimaward = claimAward;
    }

    function SetPromoTokenVal(uint256 PromoTokenVal) public onlyOwner{
        promoTokenVal = PromoTokenVal;
    }
    function SetBoostTokenVal(uint256 BoostTokenVal) public onlyOwner{
        boostTokenVal = BoostTokenVal;
    }

    function addID(uint256 value) public returns (uint256) {
        _tid = _tid + value;
        return _tid;
    }

    function addTokenType(
        string memory _type,
        address tokenAddress,
        bool _sale,
        bool _mint,
        bool _stake,
        bool _bid,
        bool _register,
        bool _promotion,
        bool _boost
    ) public onlyOwner{
        _addTokenType(_type, tokenAddress, _sale, _mint, _stake, _bid, _register, _promotion, _boost);
    }
    function _addTokenType(
        string memory _type,
        address tokenAddress,
        bool _sale,
        bool _mint,
        bool _stake,
        bool _bid,
        bool _register,
        bool _promotion,
        bool _boost
    ) internal onlyOwner{
        TokenTypes[_type].addr = tokenAddress;
        TokenTypes[_type].sale = _sale;
        TokenTypes[_type].mint = _mint;
        TokenTypes[_type].stake = _stake;
        TokenTypes[_type].bid = _bid;
        TokenTypes[_type].register = _register;
        TokenTypes[_type].promotion = _promotion;
        TokenTypes[_type].boost = _boost;
    }
    function getTokenAddress(string memory _type) public view returns(address){
        return TokenTypes[_type].addr;
    }

    function AuthorRegister(string memory tokenName) public {
        require( msg.sender != Reg_Users[msg.sender].usraddr, "User not Authorised");
        require( TokenTypes[tokenName].register, "Register not allowed with this token");
        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        uint256 approveValue = t.allowance(msg.sender, address(this));
        require( approveValue >= authorRegFee, "Allowance Invalid for Register");
        t.transferFrom(msg.sender,owner(),authorRegFee);

        Reg_Users[msg.sender].usraddr = msg.sender;
        Reg_Users[msg.sender].rfee = authorRegFee;
    }
    // function setApproval(address operator, bool approved)
    //     public
    //     returns (uint256)
    // {
    //     setApprovalForAll(operator, approved);
    //     uint256 id_ = addID(1).add(block.timestamp);
    //     emit Approve(msg.sender, id_, approved);
    //     return id_;
    // }
    function AuthorMint(
        address operator,
        string memory name,
        string memory ipfsimage,
        string memory ipfsmetadata,
        uint256 value,
        string memory tokenName
    )
    public
    returns (uint256)
    {
        require(msg.sender == Reg_Users[msg.sender].usraddr, "User not Authorised");
        require(TokenTypes[tokenName].mint, "Mint not allowed with this token");

        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        uint256 approveValue = t.allowance(msg.sender, address(this));
        require( approveValue >= mint_fee, "Fee Allowance Invalid for User");
        t.transferFrom(msg.sender, owner(), mint_fee);

        setApprovalForAll(operator, true);
        uint256 tokenId = addID(1).add(block.timestamp);
        emit Approve(msg.sender, tokenId, true);

        token_id[tokenId] = Metadata(name, ipfsimage,ipfsmetadata);
        _creator[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
        _royal[tokenId] = authorRoyalty;
        balances[tokenId][msg.sender] = 1;
        if (value != 0) {
            _orderPlace(msg.sender, tokenId, value);
        }
        totalQuantity[tokenId] = 1;
        return tokenId;
    }
    function mint(
        address operator,
        string memory name,
        string memory ipfsimage,
        string memory ipfsmetadata,
        uint256 value,
        uint256 royal
    )
    public onlyOwner
    returns (uint256)
    {
        setApprovalForAll(operator, true);
        uint256 tokenId = addID(1).add(block.timestamp);
        emit Approve(msg.sender, tokenId, true);

        token_id[tokenId] = Metadata(name, ipfsimage,ipfsmetadata);
        _creator[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
        _royal[tokenId] = royal.mul(1e18);
        balances[tokenId][msg.sender] = 1;
        if (value != 0) {
            _orderPlace(msg.sender, tokenId, value);
        }
        totalQuantity[tokenId] = 1;
        return tokenId;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(BEP721, BEP721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(BEP721, BEP721URIStorage)
    {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(BEP721, BEP721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BEP721, BEP721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function get(uint256 tokenId)
        external
        view
        returns (string memory name, string memory ipfsimage)
    {
        require(_exists(tokenId), "token not minted");
        Metadata memory date = token_id[tokenId];
        ipfsimage = date.ipfsimage;
        name = date.name;
    }
    function calc(
        uint256 amount,
        uint256 royal,
        uint256 _serviceValue
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = percent(amount, _serviceValue);
        uint256 roy = percent(amount, royal);
        uint256 netamount = amount.sub(fee.add(roy));
        fee = fee.add(fee);
        return (fee, roy, netamount);
    }
    function percent(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value1.mul(value2).div(1e20);
        return (result);
    }

    // function saleToken(
    //     address payable from,
    //     uint256 tokenId,
    //     uint256 amount
    // ) public payable {
    //     checker[tokenId][from] = true;
    //     _saleToken(from, tokenId, amount);
    //     saleTokenTransfer(from, tokenId);   
    // }

    // function _saleToken(
    //     address payable from,
    //     uint256 tokenId,
    //     uint256 amount
    // ) internal {
    //     uint256 val = percent(amount, serviceValue).add(amount);
    //     require(msg.value == val, "Insufficient Balance");
    //     require(amount == order_place[from][tokenId].price, "Insufficent found");
    //     address payable admin = payable(owner());
    //     address payable create = payable(_creator[tokenId]);
    //     (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(
    //         amount,
    //         _royal[tokenId],
    //         serviceValue
    //     );
    //     require( msg.value == _adminfee.add(roy.add(netamount)), "Insufficient Balance");
    //     admin.transfer(_adminfee);
    //     create.transfer(roy);
    //     from.transfer(netamount);
    // }

    // function saleTokenTransfer(address payable from, uint256 tokenId) internal {
    //     if (checkOrder[tokenId][from] == true) {
    //         delete order_place[from][tokenId];
    //         checkOrder[tokenId][from] = false;
    //     }
    //     tokenTrans(tokenId, from, msg.sender);
    // }

    function tokenTrans(
        uint256 tokenId,
        address from,
        address to
    ) internal {
        _approve(msg.sender,tokenId);
        safeTransferFrom(from, to, tokenId);
        // balances[tokenId][to] +=1;
        // balances[tokenId][from] -=1;
    }

    function orderPlace(uint256 tokenId, uint256 _price) public{
        _orderPlace(msg.sender, tokenId, _price);
    }
    function _orderPlace(
        address from,
        uint256 tokenId,
        uint256 _price
    ) internal {
        require(balances[tokenId][from] > 0, "Is Not a Owner");
        Order memory order;
        order.tokenId = tokenId;
        order.price = _price;
        order_place[from][tokenId] = order;
        checkOrder[tokenId][from] = true;
        emit OrderPlace(from, tokenId, _price);
    }
    function cancelOrder(uint256 tokenId) public{
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        delete order_place[msg.sender][tokenId];
        checkOrder[tokenId][msg.sender] = false;
        emit CancelOrder(msg.sender, tokenId);
    }
    // function changePrice(uint256 value, uint256 tokenId) public{
    //     require( balances[tokenId][msg.sender] > 0, "Is Not a Owner");
    //     require( value < order_place[msg.sender][tokenId].price);
    //     order_place[msg.sender][tokenId].price = value;
    //     emit ChangePrice(msg.sender, tokenId, value);
    // }
    function burnToken(uint256 tokenId) public {
        require(balances[tokenId][msg.sender] > 0, "Your Not a Token Owner or insufficient Token Balance");
        burn(tokenId);
        if(balances[tokenId][msg.sender] == 1){
            if(checkOrder[tokenId][msg.sender]==true){
                delete order_place[msg.sender][tokenId];
                checkOrder[tokenId][msg.sender] = false;
            }
        }
        //balances[tokenId][msg.sender] -=1;
    }
    function burnTokenByAdmin(uint256 tokenId, address from) public onlyOwner {
        require(balances[tokenId][from] == 1, "Your Not a Token Owner or insufficient Token Balance");
        burn(tokenId);
        if(balances[tokenId][from] == 1){
            if(checkOrder[tokenId][from]==true){
                delete order_place[from][tokenId];
                checkOrder[tokenId][from] = false;
            }
        }
        //balances[tokenId][msg.sender] -=1;
    }

    function stakeToken(uint256 tokenId) public {
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        require(Stake_Tokens[tokenId].claim == false, "Token already staked");
        Stake_Tokens[tokenId].tokenId = tokenId;
        Stake_Tokens[tokenId].tokenOwner = msg.sender;
        Stake_Tokens[tokenId].claim = true;
        Stake_Tokens[tokenId].datetime = block.timestamp;
        Stake_Tokens[tokenId].datetimeClaimed = block.timestamp;
        tokenTrans(tokenId, msg.sender, owner());
        address admin = owner();
        checker[tokenId][admin] == true;
    }

    function claimStakeToken(uint256 tokenId, string memory tokenName) public {
        require(TokenTypes[tokenName].stake, "Stake not allowed with this token");
        require(Stake_Tokens[tokenId].tokenOwner == msg.sender, "Is Not a Stake Owner");
        require(Stake_Tokens[tokenId].claim, "Token not staked");
        uint256 seccountnew = (block.timestamp.sub(Stake_Tokens[tokenId].datetimeClaimed)).div(86400);
        emit TestChecking('claimStakeToken', seccountnew.mul(1e18));
        // require(seccountnew >= 1, "Currently claim not available");
        if(seccountnew >= 1) {
            uint256 netamount = seccountnew.mul(claimaward).mul(1e18);
            address payable admin = payable(owner());
            address addr = TokenTypes[tokenName].addr;
            BEP20 t = BEP20(addr);
            uint256 approveValue = t.allowance(admin, address(this));
            require(approveValue >= netamount, "Insufficient Balance");
            t.transferFrom(admin, msg.sender, netamount);
            Stake_Tokens[tokenId].datetimeClaimed = block.timestamp;
        }
    }

    function closeStakeToken(uint256 tokenId, string memory tokenName) public {
        require(TokenTypes[tokenName].stake, "Stake not allowed with this token");
        require(Stake_Tokens[tokenId].tokenOwner == msg.sender, "Is Not a Stake Owner");
        require(Stake_Tokens[tokenId].claim, "Token not staked");
        claimStakeToken(tokenId, tokenName);
        Stake_Tokens[tokenId].claim = false;
        address payable admin = payable(owner());
        checker[tokenId][admin] == true;
        tokenTrans(tokenId, admin, msg.sender);
    }

    function placeABId(string memory tokenName, address bidaddr, uint256 amount, uint256 tokenId) public {
        require(TokenTypes[tokenName].bid, "Bid not allowed with this token");
        require(balances[tokenId][msg.sender] == 0, "Bid not allowed to you");
        require(amount > 0, 'Amount must be greater than zero');
        allowAmtchk(tokenId, msg.sender, amount, tokenName);
        Bid_Tokens[tokenId][bidaddr].tokenId = tokenId;
        Bid_Tokens[tokenId][bidaddr].addr = bidaddr;
        Bid_Tokens[tokenId][bidaddr].price = amount;
        Bid_Tokens[tokenId][bidaddr].tokenName = tokenName;
        Bid_Tokens[tokenId][bidaddr].datetime = block.timestamp;
        Bid_Tokens[tokenId][bidaddr].datetimeUpdated = block.timestamp;
        Bid_Tokens[tokenId][bidaddr].completed = false;
    }
    function acceptBId(string memory tokenName,address bidaddr, uint256 amount, uint256 tokenId) public {
        require(Bid_Tokens[tokenId][bidaddr].price > 0, "Bid not valid");
        require(Bid_Tokens[tokenId][bidaddr].price == amount, "Bid Price not valid");
        require(Bid_Tokens[tokenId][bidaddr].completed == false, "Bid already placed");
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        allowAmtchk(tokenId, bidaddr, amount, tokenName);
        ercTokenTrans(tokenName, bidaddr, msg.sender, owner(), amount, tokenId);
        if(checkOrder[tokenId][msg.sender]==true) {
            delete order_place[msg.sender][tokenId];
            checkOrder[tokenId][msg.sender] = false;
        }
        tokenTrans(tokenId,msg.sender, bidaddr);
        Bid_Tokens[tokenId][bidaddr].completed = true;
    }
    function salewithToken(string memory tokenName, address ownerAddr, uint256 tokenId, uint256 amount) public{
        require(TokenTypes[tokenName].sale, "Sale not allowed with this token");
        require(amount > 0, 'Amount must be greater than zero');
        require(amount == order_place[ownerAddr][tokenId].price, "Insufficent found");
        checker[tokenId][ownerAddr] = true;
        require(balances[tokenId][ownerAddr] > 0, "Is Not a Owner");
        allowAmtchk(tokenId, msg.sender, amount, tokenName);
        ercTokenTrans(tokenName, msg.sender, ownerAddr, owner(), amount, tokenId);
        if(checkOrder[tokenId][ownerAddr]==true){
            delete order_place[ownerAddr][tokenId];
            checkOrder[tokenId][ownerAddr] = false;
        }
        tokenTrans(tokenId, ownerAddr, msg.sender);
    }
    function allowAmtchk (uint tokenId, address from, uint amount, string memory tokenName) internal{
        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(amount, _royal[tokenId], serviceValue);
        uint256 totVal = _adminfee.add(roy.add(netamount));
        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        uint256 approveValue = t.allowance(from, address(this));
        emit AmtChecking(approveValue, _adminfee, netamount, roy);
        require(approveValue >= amount, "Insufficient Balance");
        require(approveValue >= totVal, "Insufficient Fee Balance");
    }
    function ercTokenTrans(string memory tokenName, address from, address to, address admin, uint256 amount, uint256 tokenId) internal{
        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(amount, _royal[tokenId], serviceValue);
        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        t.transferFrom(from, admin, _adminfee);
        t.transferFrom(from, _creator[tokenId], roy);
        t.transferFrom(from, to, netamount);
    }

    function emitChecking() public{
        emit Checking(msg.sender);
    }

    function payPromotion(string memory tokenName, uint256 amount) public {
        require(TokenTypes[tokenName].promotion, "Promotion not allowed with this token");
        address from = msg.sender;
        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        uint256 approveValue = t.allowance(from, address(this));
        require(approveValue >= amount, "Insufficient Balance");
        _pid = _pid + 1;
        uint256 pid = _pid.add(block.timestamp);

        uint256 clickCount = amount.div(promoTokenVal);
        emit Promoevent(msg.sender, pid, clickCount, true);

        t.transferFrom(from, owner(), amount);
    }

    function buyBoost(string memory tokenName, uint256 amount) public {
        require(TokenTypes[tokenName].boost, "Boost not allowed with this token");
        address from = msg.sender;
        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        uint256 approveValue = t.allowance(from, address(this));
        require(approveValue >= amount, "Insufficient Balance");
        _boostId = _boostId + 1;
        uint256 boostId = _boostId.add(block.timestamp);

        uint256 boostCount = amount.div(boostTokenVal);
        emit Promoevent(msg.sender, boostId, boostCount, true);

        t.transferFrom(from, owner(), amount);
    }

    function adminWithdraw(string memory tokenName, uint256 amount) public onlyOwner {
        address addr = TokenTypes[tokenName].addr;
        BEP20 t = BEP20(addr);
        t.transfer(owner(), amount);
    }

}