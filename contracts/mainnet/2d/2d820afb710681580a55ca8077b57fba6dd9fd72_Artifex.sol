/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT

/**
 * @title Artifex Smart Contract
 * @author GigLabs, Brian Burns <[email protected]>
 */

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
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
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
    mapping(address => uint8) private _otherOperators;

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
     * @dev Returns the operator state for an address. State
     * of 1 means active operator of the contract. State of 0 means
     * not an operator of the contract.
     */
    function otherOperator(address operatorAddress)
        public
        view
        virtual
        returns (uint8)
    {
        return _otherOperators[operatorAddress];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than an operator.
     */
    modifier anyOperator() {
        require(
            owner() == _msgSender() || _otherOperators[msg.sender] == 1,
            "Ownable: caller is not an operator"
        );
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

    /**
     * @dev Sets the state of other operators for performaing certain
     * contract functions. Can only be called by the current owner.
     */
    function setOtherOperator(address _newOperator, uint8 _state)
        public
        virtual
        onlyOwner
    {
        require(_newOperator != address(0));
        _otherOperators[_newOperator] = _state;
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

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is
    Context,
    ERC165,
    ERC721,
    IERC721Enumerable
{
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
        override(IERC165, ERC165, ERC721)
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

/**
 * @dev The Artifex main contract.
 *
 * Each Artifex token implements full on-chain metadata
 * in standard JSON format for anyone to retreive using the
 * getMetadata() function in this contract. A mirrored copy of the
 * metadata JSON is also stored on IPFS.
 *
 * Each NFT 2D image is stored on both IPFS and Arweave
 * Each NFT 3D model is stored on both IPFS and Arweave
 *
 * The metadata on-chain in this contract (and mirrored on IPFS)
 * return the hashes / locations of all NFT images and 3D model files
 * stored on IPFS and Arweave.
 *
 * The metadata on-chain in this contract (and mirrored on IPFS)
 * also return SHA256 hashes of the NFT images and 3D model files
 * for verifying authenticity of the NFTs.
 *
 * Metadata is retreivable using the tokenURI() call as specified
 * in the ERC721-Metadata standard. tokenURI can't point to on-chain
 * locations directly - it points to an off-chain URI for
 * returning metadata.
 */
contract Artifex is Ownable, ERC721Enumerable {
    // NOTE: `SafeMath` is no longer needed starting with Solidity 0.8.
    // The compiler now has built in overflow checking.
    //
    // using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    // Core series metadata
    struct ArtistNFTSeriesInfo {
        uint256 totalEditions;
        string creatorName;
        string artistName;
        string artTitle;
        string description;
        string sha256ImageHash;
        string ipfsImageHash;
        string arweaveImageHash;
        string imageFileType;
    }

    // Extended series metadata
    struct ArtistNFTSeries3DModelInfo {
        string sha256ModelHash;
        string ipfs3DModelHash;
        string arweave3DModelHash;
        string modelFileType;
    }

    // Series ID => Core series metadata for NFT Type 1 (2D art piece)
    mapping(uint256 => ArtistNFTSeriesInfo) private artist2DSeriesInfo;

    // Series ID => Core series metadata for NFT Type 2 (3D art piece,
    // in 2D format)
    mapping(uint256 => ArtistNFTSeriesInfo) private artist3DSeriesInfo;

    // Series ID => Extended series metadata for NFT Type 2 (3D model
    // files for 3D art piece)
    mapping(uint256 => ArtistNFTSeries3DModelInfo)
        private artistSeries3DModelInfo;

    // Series ID => series locked state
    mapping(uint256 => bool) private artistSeriesLocked;

    // Token ID => token's IPFS Metadata hash
    mapping(uint256 => string) private tokenIdToIPFSMetadataHash;

    // Base token URI used as a prefix for all tokens to build
    // a full token URI string
    string private _baseTokenURI;

    // Base external token URI used as a prefix for all tokens
    // to build a full external token URI string
    string private _externalBaseTokenURI;

    // Multipliers for token Id calculations
    uint256 constant SERIES_MULTIPLIER = 100000000;
    uint256 constant NFT_TYPE_MULTIPLIER = 10000;

    /**
     * @notice Event emitted when the takenBaseUri is set after
     * contract deployment
     * @param tokenBaseUri the base URI for tokenURI calls
     */
    event TokenBaseUriSet(string tokenBaseUri);

    /**
     * @notice Event emitted when the externalBaseUri is set after
     * contract deployment.
     * @param externalBaseUri the new external base URI
     */
    event ExternalBaseUriSet(string externalBaseUri);

    /**
     * @notice Event emitted when a series is locked/sealed
     * @param seriesId the ID of the newly locked/sealed series
     */
    event SeriesLocked(uint256 seriesId);

    /**
     * @dev Constructor
     * @param name the token name
     * @param symbol the token symbol
     * @param base_uri the base URI for location of off-chain metadata
     * @param external_base_uri the base URI for viewing token on website
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory base_uri,
        string memory external_base_uri
    ) ERC721(name, symbol) {
        _baseTokenURI = base_uri;
        _externalBaseTokenURI = external_base_uri;
    }

    /**
     * @notice Add core metadata for the 2D piece in an artist series.
     * NOTE: For Artifex, there will only be 100 artist series IDs (1-100).
     * Each series will have a 1 of 1 2D art piece (nftType 1) and a run
     * of 100 3D art pieces (nftType 2). Series ID 0 will be a gift
     * series and is not included in the 1-100 artist series IDs.
     * @param seriesId the ID of the series (0-100)
     * @param seriesInfo structure with series metadata
     */
    function addArtistSeries2dNftType(
        uint256 seriesId,
        ArtistNFTSeriesInfo calldata seriesInfo
    ) external anyOperator {
        // Series ID must be 0-100
        require(seriesId <= 100);

        // Once a series metadata is locked, it cannot be updated. The
        // information will live as permanent metadata in the contract.
        require(artistSeriesLocked[seriesId] == false, "Series is locked");

        artist2DSeriesInfo[seriesId] = seriesInfo;
    }

    /**
     * @notice Add core metadata for the 3D pieces in an artist series.
     * NOTE: For Artifex, there will only be 100 artist series IDs (1-100).
     * Each series will have a 1 of 1 2D art piece (nftType 1) and a run
     * of 100 3D art pieces (nftType 2). Series ID 0 will be a gift
     * series and is not included in the 1-100 artist series IDs.
     * @param seriesId the ID of the series (0-100)
     * @param seriesInfo structure with series metadata
     * @param series3DModelInfo structure with series 3D model metadata
     */
    function addArtistSeries3dNftType(
        uint256 seriesId,
        ArtistNFTSeriesInfo calldata seriesInfo,
        ArtistNFTSeries3DModelInfo calldata series3DModelInfo
    ) external anyOperator {
        // Series ID must be 0-100
        require(seriesId <= 100);

        // Once a series metadata is locked, it cannot be updated. The
        // information will live as permanent metadata in the contract and
        // on IFPS
        require(artistSeriesLocked[seriesId] == false, "Series is locked");

        artist3DSeriesInfo[seriesId] = seriesInfo;
        artistSeries3DModelInfo[seriesId] = series3DModelInfo;
    }

    /**
     * @dev Update the IPFS hash for a given token.
     * Series metadata must NOT be locked yet (must still be within
     * the series metadata update window)
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param ipfsHash string IPFS link to assign
     */
    function updateTokenIPFSMetadataHash(
        uint256 tokenId,
        string calldata ipfsHash
    ) external anyOperator {
        require(
            artistSeriesLocked[getSeriesId(tokenId)] == false,
            "Series is locked"
        );
        _setTokenIPFSMetadataHash(tokenId, ipfsHash);
    }

    /**
     * @notice This function permanently locks metadata updates for all NFTs
     * in a Series. For practical reasons, a short period of time is given
     * for updates following a series mint. For example, maybe an artist
     * notices incorrect info in the description of their art after it is
     * minted. In most projects, metadata updates would be possible by changning
     * the metadata on the web server hosting the metadata. However, for
     * Artifex once metadata is locked, no updates to the metadata will be
     * possible - the information is permanent and immutable.
     *
     * The metadata will be permanent on-chain here in the contract, retrievable
     * as a JSON string via the getMetadata() call. A mirror of the metadata will
     * also live permanently on IPFS at the location stored in the
     * tokenIdToIPFSMetadataHash mapping in this contract.
     *
     * @param seriesId the ID of the series (0-100)
     */
    function lockSeries(uint256 seriesId) external anyOperator {
        // Series ID must be 0-100
        require(seriesId <= 100);

        // Series must not have been previously locked
        require(artistSeriesLocked[seriesId] == false, "Series is locked");

        // Lock the series. Once a series information is set, it can no
        // longer be updated. The information will live as permanent
        // metadata in the contract.
        artistSeriesLocked[seriesId] = true;

        // Emit the event
        emit SeriesLocked(seriesId);
    }

    /**
     * @notice Sets a new base token URI for accessing off-chain metadata
     * location. If this is changed, an event gets emitted.
     * @param newBaseTokenURI the new base token URI
     */
    function setBaseURI(string calldata newBaseTokenURI) external anyOperator {
        _baseTokenURI = newBaseTokenURI;

        // Emit the event
        emit TokenBaseUriSet(newBaseTokenURI);
    }

    /**
     * @notice Sets a new base external URI for accessing the nft on a web site.
     * If this is changed, an event gets emitted
     * @param newExternalBaseTokenURI the new base external token URI
     */
    function setExternalBaseURI(string calldata newExternalBaseTokenURI)
        external
        anyOperator
    {
        _externalBaseTokenURI = newExternalBaseTokenURI;

        // Emit the event
        emit ExternalBaseUriSet(newExternalBaseTokenURI);
    }

    /**
     * @dev Batch transfer of Artifex NFTs from one address to another
     * @param _to The address of the recipient
     * @param _tokenIds List of token IDs to transfer
     */
    function batchTransfer(address _to, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(msg.sender, _to, _tokenIds[i], "");
        }
    }

    /**
     * @notice Given a series ID, return the locked state
     * @param seriesId the series ID
     * @return true if series is locked, otherwise returns false
     */
    function isSeriesLocked(uint256 seriesId) external view returns (bool) {
        return artistSeriesLocked[seriesId];
    }

    /**
     * @notice return the base URI used for accessing off-chain metadata
     * @return base URI for location of the off-chain metadata
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice return the base external URI used for accessing nft on a web site.
     * @return base external URI
     */
    function externalBaseURI() external view returns (string memory) {
        return _externalBaseTokenURI;
    }

    /**
     * @notice Given a token ID, return whether or not it exists
     * @param tokenId the token ID
     * @return a bool which is true of the token exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Given a token ID, return all on-chain metadata for the
     * token as JSON string
     *
     * For each NFT, the following on-chain metadata is returned:
     *    - Name: The title of the art piece (includes creator of the art piece)
     *    - Descriptiom: Details about the art piece (includes the artist represented)
     *    - Image URI: The off-chain URI location of the image
     *    - External URI: Website to view the NFT
     *    - SHA256 Image Hash: The actual image hash stored on-chain for anyone
     *      to validate authenticity of their art piece
     *    - IPFS Image Hash: IFPS storage hash of the image
     *    - Arweave Image Hash: Arweave storage hash of the image
     *    - Image File Type: File extension of the image, since file stores such
     *      as IPFS may not return the image file type
     *
     *    IF 3D MODEL INFO AVAILABLE, THEN INCLUDE THIS IN METADATA
     *    - SHA256 3D Model Hash: The actual 3D Model hash stored
     *      on-chain for anyone to validate authenticity of their
     *       3D model asset
     *    - IPFS 3D Model Hash: IFPS storage hash of the 3D model
     *    - Arweave Image Hash: Arweave storage hash of the 3D model
     *    - 3D Model File Type: File extension of the 3D model
     *
     *    ATTRIBUTES INCLUDED:
     *    - Creator name: The creator of the art piece
     *    - Artist name: The artist represented / honored by the creator
     *    - Edition Number: The edition number of the NFT
     *    - Total Editions: Total editions that can ever exist in the series
     *
     * @param tokenId the token ID
     * @return metadata a JSON string of the metadata
     */
    function getMetadata(uint256 tokenId)
        external
        view
        returns (string memory metadata)
    {
        require(_exists(tokenId), "Token does not exist");

        uint256 seriesId = getSeriesId(tokenId);
        uint256 nftType = getNftType(tokenId);
        uint256 editionNum = getNftNum(tokenId);

        string memory creatorName;
        ArtistNFTSeriesInfo memory seriesInfo;
        ArtistNFTSeries3DModelInfo memory series3DModelInfo;
        if (nftType == 1) {
            seriesInfo = artist2DSeriesInfo[seriesId];
            creatorName = seriesInfo.artistName;
        } else if (nftType == 2) {
            seriesInfo = artist3DSeriesInfo[seriesId];
            creatorName = seriesInfo.creatorName;
            series3DModelInfo = artistSeries3DModelInfo[seriesId];
        }

        // Name
        metadata = string(
            abi.encodePacked('{\n  "name": "', seriesInfo.artistName)
        );
        metadata = string(abi.encodePacked(metadata, " Artifex #"));
        metadata = string(abi.encodePacked(metadata, editionNum.toString()));
        metadata = string(abi.encodePacked(metadata, " of "));
        metadata = string(
            abi.encodePacked(metadata, seriesInfo.totalEditions.toString())
        );
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // Description: Generation
        metadata = string(abi.encodePacked(metadata, '  "description": "'));
        metadata = string(abi.encodePacked(metadata, seriesInfo.description));
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // Image URI
        metadata = string(abi.encodePacked(metadata, '  "image": "'));
        metadata = string(abi.encodePacked(metadata, _baseTokenURI));
        metadata = string(abi.encodePacked(metadata, seriesInfo.ipfsImageHash));
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // External URI
        metadata = string(abi.encodePacked(metadata, '  "external_url": "'));
        metadata = string(abi.encodePacked(metadata, externalURI(tokenId)));
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // SHA256 Image Hash
        metadata = string(
            abi.encodePacked(metadata, '  "sha256_image_hash": "')
        );
        metadata = string(
            abi.encodePacked(metadata, seriesInfo.sha256ImageHash)
        );
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // IPFS Image Hash
        metadata = string(abi.encodePacked(metadata, '  "ipfs_image_hash": "'));
        metadata = string(abi.encodePacked(metadata, seriesInfo.ipfsImageHash));
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // Arweave Image Hash
        metadata = string(
            abi.encodePacked(metadata, '  "arweave_image_hash": "')
        );
        metadata = string(
            abi.encodePacked(metadata, seriesInfo.arweaveImageHash)
        );
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // Image file type
        metadata = string(abi.encodePacked(metadata, '  "image_file_type": "'));
        metadata = string(abi.encodePacked(metadata, seriesInfo.imageFileType));
        metadata = string(abi.encodePacked(metadata, '",\n'));

        // Optional 3D Model metadata
        if (nftType == 2) {
            // SHA256 3D Model Hash
            metadata = string(
                abi.encodePacked(metadata, '  "sha256_3d_model_hash": "')
            );
            metadata = string(
                abi.encodePacked(metadata, series3DModelInfo.sha256ModelHash)
            );
            metadata = string(abi.encodePacked(metadata, '",\n'));

            // IPFS 3D Model Hash
            metadata = string(
                abi.encodePacked(metadata, '  "ipfs_3d_model_hash": "')
            );
            metadata = string(
                abi.encodePacked(metadata, series3DModelInfo.ipfs3DModelHash)
            );
            metadata = string(abi.encodePacked(metadata, '",\n'));

            // Arweave 3D Model Hash
            metadata = string(
                abi.encodePacked(metadata, '  "arweave_3d_model_hash": "')
            );
            metadata = string(
                abi.encodePacked(metadata, series3DModelInfo.arweave3DModelHash)
            );
            metadata = string(abi.encodePacked(metadata, '",\n'));

            // 3D model file type
            metadata = string(
                abi.encodePacked(metadata, '  "model_file_type": "')
            );
            metadata = string(
                abi.encodePacked(metadata, series3DModelInfo.modelFileType)
            );
            metadata = string(abi.encodePacked(metadata, '",\n'));
        }

        // Atributes section

        // Artist Name
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "attributes": [\n     {"trait_type": "Artist", "value": "'
            )
        );
        metadata = string(abi.encodePacked(metadata, seriesInfo.artistName));
        metadata = string(abi.encodePacked(metadata, '"},\n'));

        // Creator Name
        metadata = string(
            abi.encodePacked(
                metadata,
                '     {"trait_type": "Creator", "value": "'
            )
        );
        metadata = string(abi.encodePacked(metadata, creatorName));
        metadata = string(abi.encodePacked(metadata, '"},\n'));

        // Edition Number
        metadata = string(
            abi.encodePacked(
                metadata,
                '     {"trait_type": "Edition", "value": '
            )
        );
        metadata = string(abi.encodePacked(metadata, editionNum.toString()));
        metadata = string(abi.encodePacked(metadata, ","));

        // Total Editions
        metadata = string(abi.encodePacked(metadata, ' "max_value": '));
        metadata = string(
            abi.encodePacked(metadata, seriesInfo.totalEditions.toString())
        );
        metadata = string(abi.encodePacked(metadata, ","));
        metadata = string(
            abi.encodePacked(metadata, ' "display_type": "number"}\n ]')
        );

        // Finish JSON object
        metadata = string(abi.encodePacked(metadata, "\n}"));
    }

    /**
     * @notice Mints an Artifex NFT
     * @param to address of the recipient
     * @param seriesId series to mint
     * @param nftType the type of nft - 1 for 2D piece, 2 for 3D piece
     * @param nftNum the edition number of the nft
     * @param ipfsHash the ipfsHash of a copy of the token's Metadata on ipfs
     */
    function mintArtifexNft(
        address to,
        uint256 seriesId,
        uint256 nftType,
        uint256 nftNum,
        string memory ipfsHash
    ) public anyOperator {
        // Ensure the series is not locked yet. No more minting can
        // happen once the series is locked
        require(artistSeriesLocked[seriesId] == false, "Series is locked");
        // Series 0 is a gift series. Only enforce edition limits
        // for artist Series > 0.
        if (seriesId > 0) {
            if (nftType == 1) {
                require(nftNum == 1, "Edition must be 1");
            } else if (nftType == 2) {
                require(nftNum <= 100, "Edition must be <= 100");
            }
        }
        uint256 tokenId = encodeTokenId(seriesId, nftType, nftNum);
        _safeMint(to, tokenId);
        _setTokenIPFSMetadataHash(tokenId, ipfsHash);
    }

    /**
     * @notice Mints multiple Artifex NFTs for same series and nftType
     * @param to address of the recipient
     * @param seriesId series to mint
     * @param nftType the type of nft - 1 for 2D piece, 2 for 3D piece
     * @param nftStartingNum the starting edition number of the nft
     * @param numTokens the number of tokens to mint in the edition,
     * starting from nftStartingNum edition number
     * @param ipfsHashes an array of ipfsHashes of each token's Metadata on ipfs
     */
    function batchMintArtifexNft(
        address to,
        uint256 seriesId,
        uint256 nftType,
        uint256 nftStartingNum,
        uint256 numTokens,
        string[] memory ipfsHashes
    ) public anyOperator {
        require(
            numTokens == ipfsHashes.length,
            "numTokens and num ipfsHashes must match"
        );
        for (uint256 i = 0; i < numTokens; i++) {
            mintArtifexNft(
                to,
                seriesId,
                nftType,
                nftStartingNum + i,
                ipfsHashes[i]
            );
        }
    }

    /**
     * @notice Given a token ID, return the series ID of the token
     * @param tokenId the token ID
     * @return the series ID of the token
     */
    function getSeriesId(uint256 tokenId) public pure returns (uint256) {
        return (uint256(tokenId / SERIES_MULTIPLIER));
    }

    /**
     * @notice Given a token ID, return the nft type of the token
     * @param tokenId the token ID
     * @return the nft type of the token
     */
    function getNftType(uint256 tokenId) public pure returns (uint256) {
        uint256 seriesId = getSeriesId(tokenId);
        return
            uint256(
                (tokenId - (SERIES_MULTIPLIER * seriesId)) / NFT_TYPE_MULTIPLIER
            );
    }

    /**
     * @notice Given a token ID, return the nft edition number of the token
     * @param tokenId the token ID
     * @return the nft edition number of the token
     */
    function getNftNum(uint256 tokenId) public pure returns (uint256) {
        uint256 seriesId = getSeriesId(tokenId);
        uint256 nftType = getNftType(tokenId);
        return
            uint256(
                tokenId -
                    (SERIES_MULTIPLIER * seriesId) -
                    (nftType * NFT_TYPE_MULTIPLIER)
            );
    }

    /**
     * @notice Generate a tokenId given the series ID, nft type,
     * and nft edition number
     * @param seriesId series to mint
     * @param nftType the type of nft - 1 for 2D piece, 2 for 3D piece
     * @param nftNum the edition number of the nft
     * @return the token ID
     */
    function encodeTokenId(
        uint256 seriesId,
        uint256 nftType,
        uint256 nftNum
    ) public pure returns (uint256) {
        return ((seriesId * SERIES_MULTIPLIER) +
            (nftType * NFT_TYPE_MULTIPLIER) +
            nftNum);
    }

    /**
     * @notice Given a token ID, return the name of the artist name
     * for the token
     * @param tokenId the token ID
     * @return artistName the name of the artist
     */
    function getArtistNameByTokenId(uint256 tokenId)
        public
        view
        returns (string memory artistName)
    {
        require(_exists(tokenId), "Token does not exist");
        if (getNftType(tokenId) == 1) {
            artistName = artist2DSeriesInfo[getSeriesId(tokenId)].artistName;
        } else if (getNftType(tokenId) == 2) {
            artistName = artist3DSeriesInfo[getSeriesId(tokenId)].artistName;
        }
    }

    /**
     * @notice Given a series ID and nft type, return information about the series
     * @param seriesId series to mint
     * @param nftType the type of nft - 1 for 2D piece, 2 for 3D piece
     * @return seriesInfo structure with series information
     */
    function getSeriesInfo(uint256 seriesId, uint256 nftType)
        public
        view
        returns (
            ArtistNFTSeriesInfo memory seriesInfo,
            ArtistNFTSeries3DModelInfo memory series3dModelInfo
        )
    {
        if (nftType == 1) {
            seriesInfo = artist2DSeriesInfo[seriesId];
        } else if (nftType == 2) {
            seriesInfo = artist3DSeriesInfo[seriesId];
            series3dModelInfo = artistSeries3DModelInfo[seriesId];
        }
    }

    /**
     * @notice Given a token ID, return information about the series
     * @param tokenId the token ID
     * @return seriesInfo structure with series information
     */
    function getSeriesInfoByTokenId(uint256 tokenId)
        public
        view
        returns (
            ArtistNFTSeriesInfo memory seriesInfo,
            ArtistNFTSeries3DModelInfo memory series3dModelInfo
        )
    {
        require(_exists(tokenId), "Token does not exist");
        (seriesInfo, series3dModelInfo) = getSeriesInfo(
            getSeriesId(tokenId),
            getNftType(tokenId)
        );
    }

    /**
     * @dev Returns an URI for a given token ID.
     * See {IERC721Metadata-tokenURI}.
     * @param tokenId uint256 ID of the token to query
     * @return URI for location of the off-chain metadata
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

        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        tokenIdToIPFSMetadataHash[tokenId]
                    )
                )
                : "";
    }

    /**
     * @dev Returns the actual CID hash pointing to the token's metadata on IPFS.
     * @param tokenId token ID of the token to query
     * @return the ipfs hash of the metadata
     */
    function tokenIPFSMetadataHash(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenIdToIPFSMetadataHash[tokenId];
    }

    /**
     * @notice Given a token ID, return the external URI for viewing the nft on a
     * web site.
     * @param tokenId the token ID
     * @return external URI
     */
    function externalURI(uint256 tokenId) public view returns (string memory) {
        return
            string(abi.encodePacked(_externalBaseTokenURI, tokenId.toString()));
    }

    /**
     * @notice return the base URI used for accessing off-chain metadata
     * @return base URI for location of the off-chain metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Private function to set the token IPFS hash for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param ipfs_hash string IPFS link to assign
     */
    function _setTokenIPFSMetadataHash(uint256 tokenId, string memory ipfs_hash)
        private
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        tokenIdToIPFSMetadataHash[tokenId] = ipfs_hash;
    }
}