/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0

/*
                                                        ,----,
                            ,--,     ,----..          ,/   .`|           ____
                          ,--.'|    /   /   \       ,`   .'  :         ,'  , `.
                       ,--,  | :   /   .     :    ;    ;     /      ,-+-,.' _ |
                    ,---.'|  : '  .   /   ;.  \ .'___,/    ,'    ,-+-. ;   , ||
                    |   | : _' | .   ;   /  ` ; |    :     |    ,--.'|'   |  ;|
                    :   : |.'  | ;   |  ; \ ; | ;    |.';  ;   |   |  ,', |  ':t
                    |   ' '  ; : |   :  | ; | ' `----'  |  |   |   | /  | |  ||
                    '   |  .'. | .   |  ' ' ' :     '   :  ;   '   | :  | :  |,
                    |   | :  | ' '   ;  \; /  |     |   |  '   ;   . |  ; |--'
                    '   : |  : ;  \   \  ',  /      '   :  |   |   : |  | ,
                    |   | '  ,/    ;   :    /       ;   |.'    |   : '  |/
                    ;   : ;--'      \   \ .'        '---'      ;   | |`-'
                    |   ,/           `---`                     |   ;/
                    '---'                                      '---'
*/

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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

pragma solidity ^0.8.10;

abstract contract ERC721P is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    string private _name;
    string private _symbol;
    address[] internal _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint count = 0;
        uint length = _owners.length;
        for( uint i = 0; i < length; ++i ){
            if( owner == _owners[i] ){
                ++count;
            }
        }
        delete length;
        return count;
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721P.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721P.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721P.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721P.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721P.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.10;

abstract contract ERC721Enum is ERC721P, IERC721Enumerable {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721P) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        require(index < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
        uint count;
        for( uint i; i < _owners.length; ++i ){
            if( owner == _owners[i] ){
                if( count == index )
                    return i;
                else
                    ++count;
            }
        }
        require(false, "ERC721Enum: owner ioob");
    }
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        require(0 < ERC721P.balanceOf(owner), "ERC721Enum: owner ioob");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enum.totalSupply(), "ERC721Enum: global ioob");
        return index;
    }
}

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity ^0.8.10;

interface IBoostWatcher {
    function watchBooster(address _collection, uint256[] calldata _tokenIds, uint256[] calldata _startDates) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(address add, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HumansOfTheMetaverseRealEstate is ERC721Enum, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;

    uint8 bonusPercentage = 20;

    // business logic constants
    uint16 private constant LAND = 1;
    uint16 private constant OFFICE = 2;
    uint256 private constant ETHER = 1e18;

    string private baseURI;
    address public tokenAddress;

    struct Coordinate {
        int32 layer;
        int256 x;
        int256 y;
    }

    struct LayerConfiguration {
        bool lock;
        int32 layer;
        uint256 length;
        mapping(uint16 => uint32) typesPricing; // real estate prices will be dependent on the layer they are in
        mapping(uint256 => uint256) rangePricing;
    }

    EnumerableSet.AddressSet collections;
    EnumerableSet.AddressSet allowedRealEstateModifiers;

    mapping(int32 => LayerConfiguration) layerConfigurationMap;

    mapping(bytes32 => uint8) buildingEnrolmentSlotsMapping; // layer + buildingType => Enrolment

    mapping(bytes32 => bool) realEstateOccupancyMapping; // layer + x + y => bool

    mapping(bytes32 => bool) humanEnrolmentMapping; // address + tokenId => layer + x + y

    mapping(uint256 => EnumerableSet.UintSet) tokenEnrolmentEmployeesMapping;
    mapping(uint256 => uint64) tokensTypeMapping;
    mapping(uint256 => Coordinate) tokensCoordinates;

    // events
    event RealEstateMinted(uint256[] tokenIds, Coordinate[] coordinates, address caller);
    event RealEstateChanges(uint256[] tokenIds, uint16[] realEstateTypes, address caller);
    event RealEstateEnrolment(uint256[] tokenIds, uint256 office, uint256 timestamp, address caller, address collection);
    event RealEstateEnrolmentRetrieval(uint256[] tokenIds, uint256 office, uint256 timestamp, address caller, address collection);


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address[] memory _collectionAddresses,
        address _tokenAddress
    ) ERC721P(_name, _symbol) {
        _pause();
        setBaseURI(_initBaseURI);

        for (uint8 i = 0; i < _collectionAddresses.length; ++i) {
            collections.add(_collectionAddresses[i]);
        }

        tokenAddress = _tokenAddress;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTokenAddress(address _address) external onlyOwner {
        tokenAddress = _address;
    }

    function addAllowedModifiers(address[] calldata _modifierAddresses) external onlyOwner {
        for (uint8 i = 0; i < _modifierAddresses.length; ++i) {
            allowedRealEstateModifiers.add(_modifierAddresses[i]);
        }
    }

    function removeAllowedModifiers(address[] calldata _modifierAddresses) external onlyOwner {
        for (uint8 i = 0; i < _modifierAddresses.length; ++i) {
            allowedRealEstateModifiers.remove(_modifierAddresses[i]);
        }
    }

    function addCollection(address _collection) external onlyOwner {
        collections.add(_collection);
    }

    function removeCollection(address _collection) external onlyOwner {
        require(collections.contains(_collection), "Specified address not found");
        collections.remove(_collection);
    }

    function setOfficeBoost(uint8 _boost) external onlyOwner {
        bonusPercentage = _boost;
    }

    function withdrawTokens() external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }


    function setLayerConfiguration(
        int32 _layer,
        uint256 _length,
        uint16[] calldata _realEstateTypes,
        uint32[] calldata _realEstatePrices,
        uint8[] calldata _slots,
        uint256[] calldata _landPrices
    ) external onlyOwner {
        require(
            _realEstateTypes.length == _realEstatePrices.length
            && _realEstatePrices.length == _slots.length
            && _landPrices.length == _length / 2,
            "Incorrect input"
        );

        LayerConfiguration storage layerConfiguration = layerConfigurationMap[_layer];
        layerConfiguration.layer = _layer;
        layerConfiguration.length = _length;

        for (uint8 i = 0; i < _realEstateTypes.length; ++i) {
            layerConfiguration.typesPricing[_realEstateTypes[i]] = _realEstatePrices[i];
            buildingEnrolmentSlotsMapping[
                keccak256(abi.encode(_layer, _realEstateTypes[i]))
            ] = _slots[i];
        }

        for(uint256 i = 0; i < _length / 2; ++i) {
            layerConfiguration.rangePricing[i * 2] = _landPrices[i];
        }
    }

    function setLayerLock(int32 _layer, bool _lock) external onlyOwner {
        LayerConfiguration storage layerConfiguration = _getLayerConfiguration(_layer);
        layerConfiguration.lock = _lock;
    }

    function setLayerLength(int32 _layer, uint256 _length, uint256[] calldata _additionalPrices) external onlyOwner {
        LayerConfiguration storage layerConfiguration = _getLayerConfiguration(_layer);

        require(_additionalPrices.length == _length / 2 - layerConfiguration.length / 2, "Incorrect input");

        for(uint256 i = layerConfiguration.length / 2; i < _length / 2; ++i) {
            layerConfiguration.rangePricing[i * 2] = _additionalPrices[i];
        }

        layerConfiguration.length = _length;

    }

    function setLayerLandPricing(int32 _layer, uint256[] calldata prices) external onlyOwner {
        LayerConfiguration storage layerConfiguration = _getLayerConfiguration(_layer);

        require(prices.length == layerConfiguration.length / 2, "Incorrect input");

        for (uint256 i = 0; i < layerConfiguration.length / 2; ++i) {
            layerConfiguration.rangePricing[i * 2] = prices[i];
        }

    }

    function setLayerTypesPricing(
        int32 _layer,
        uint16[] calldata realEstateTypes,
        uint32[] calldata realEstatePrices
    ) external onlyOwner {
        require(realEstateTypes.length == realEstatePrices.length, "Incorrect input");
        LayerConfiguration storage layerConfiguration = _getLayerConfiguration(_layer);

        for (uint16 i = 0; i < realEstateTypes.length; ++i) {
            layerConfiguration.typesPricing[realEstateTypes[i]] = realEstatePrices[i];
        }
    }

    function removeLayerTypesPricing(int32 _layer, uint16[] calldata realEstateTypes) external onlyOwner {
        LayerConfiguration storage layerConfiguration = _getLayerConfiguration(_layer);
        for (uint256 i = 0; i < realEstateTypes.length; ++i) {
            delete layerConfiguration.typesPricing[realEstateTypes[i]];
            delete buildingEnrolmentSlotsMapping[keccak256(abi.encode(_layer, realEstateTypes[i]))];
        }
    }

    function setLayerRealEstateTypeEnrolmentConfig(int32 _layer, uint16[] calldata _realEstateTypes, uint8[] calldata _slots) external onlyOwner {
        require(_realEstateTypes.length == _slots.length, "Incorrect input");
        for (uint64 i = 0; i < _realEstateTypes.length; ++i) {
            buildingEnrolmentSlotsMapping[keccak256(abi.encode(_layer, _realEstateTypes[i]))] = _slots[i];
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function _getLayerConfiguration(int32 _layer) internal view returns (LayerConfiguration storage) {
        LayerConfiguration storage layerConfiguration = layerConfigurationMap[_layer];
        require(layerConfiguration.length != uint256(0), "There is no configuration for provided layer");

        return layerConfiguration;
    }

    function _abs(int256 x) internal pure returns(uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    function buyLand(Coordinate[] memory _coordinates) external whenNotPaused payable {
        uint256 price = calculateLandPrice(_coordinates);

        uint256[] memory tokenIds = occupyLand(_coordinates);

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), price *  ETHER);

        emit RealEstateMinted(tokenIds, _coordinates, msg.sender);

        delete price;
        delete tokenIds;
    }

    function changeRealEstate(uint256[] calldata _tokenIds, uint16[] calldata _realEstateNewTypes) external whenNotPaused payable {
        // ownership si interactions trebuie remove si update in tokenAddress
        require(_tokenIds.length == _realEstateNewTypes.length, "Incorrect input dat");

        validateTokensToBeChanged(_tokenIds, _realEstateNewTypes);

        uint256 price = calculateRealEstatePrice(_tokenIds, _realEstateNewTypes);

        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            tokensTypeMapping[_tokenIds[i]] = _realEstateNewTypes[i];
        }

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), price * ETHER);

        emit RealEstateChanges(_tokenIds, _realEstateNewTypes, msg.sender);

        delete price;
    }

    function externalChangeRealEstate(uint256[] calldata _tokenIds, uint16[] calldata _realEstateNewTypes, address owner, uint256 amount) external whenNotPaused {
        // ownership si interactions trebuie remove si update in tokenAddress
        require(allowedRealEstateModifiers.contains(msg.sender), "Not an allowed real estate changer");
        require(_tokenIds.length == _realEstateNewTypes.length, "Incorrect input data");

        validateTokensToBeChanged(_tokenIds, _realEstateNewTypes);

        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            tokensTypeMapping[_tokenIds[i]] = _realEstateNewTypes[i];
        }

        IERC20(tokenAddress).transferFrom(owner, address(this),  amount * ETHER);

        emit RealEstateChanges(_tokenIds, _realEstateNewTypes, owner);
    }

    function validateTokensToBeChanged(uint256[] calldata _tokenIds, uint16[] calldata _realEstateNewTypes) internal view {

        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            if (tokensTypeMapping[_tokenIds[i]] == LAND && _realEstateNewTypes[i] == LAND) {
                revert("Land should be changed into a building");
            }

            require(msg.sender == ownerOf(_tokenIds[i]), "Not the owner of the real estate piece");
        }
    }

    function calculateLandPrice(Coordinate[] memory _coordinates) public view returns(uint256) {
        validateCoordinates(_coordinates);
        uint256 price = 0;

        for(uint128 i = 0; i < _coordinates.length; ++i) {
            Coordinate memory coordinate = _coordinates[i];
            LayerConfiguration storage layerConfiguration = _getLayerConfiguration(coordinate.layer);

            uint256 landPriceIndex = uint256(_abs(coordinate.x) + _abs(coordinate.y));

            landPriceIndex = landPriceIndex % 2 == 1 ? landPriceIndex - 1 : landPriceIndex;

            price += layerConfiguration.rangePricing[landPriceIndex];
        }

        return price;
    }

    function calculateRealEstatePrice(uint256[] calldata _tokenIds, uint16[] calldata _realEstateTypes) public view returns(uint256) {
        uint256 price = 0;

        for(uint128 i = 0; i < _tokenIds.length; ++i) {

            LayerConfiguration storage layerConfiguration = _getLayerConfiguration(tokensCoordinates[_tokenIds[i]].layer);

            if (layerConfiguration.typesPricing[_realEstateTypes[i]] == uint64(0)) {
                revert("Unsupported real estate type for provided layer");
            }
            uint256 realEstatePrice = layerConfiguration.typesPricing[_realEstateTypes[i]];

            require(realEstatePrice != uint32(0), "Unsupported building type");

            price += realEstatePrice;

        }

        return price;
    }

    function validateCoordinates(Coordinate[] memory _coordinates) public view {
        for (uint256 i = 0; i < _coordinates.length; ++i) {
            Coordinate memory coordinate = _coordinates[i];
            LayerConfiguration storage layerConfiguration = _getLayerConfiguration(coordinate.layer);

            require(
                _abs(coordinate.x) < layerConfiguration.length / 2
                && _abs(coordinate.y) < layerConfiguration.length / 2
                && !realEstateOccupancyMapping[keccak256(abi.encode(coordinate.x, coordinate.y, coordinate.layer))],
                "Coordinates invalid"
            );
        }
    }

    function enrollInOffice(uint256[] calldata _workers, uint256 _office, address _collection) external whenNotPaused {

        require(collections.contains(_collection), "Not amongst enrollable collections");
        require(ownerOf(_office) == msg.sender, "Not the owner of the office");

        if (
            buildingEnrolmentSlotsMapping[keccak256(abi.encode(tokensCoordinates[_office].layer, tokensTypeMapping[_office]))]
            - tokenEnrolmentEmployeesMapping[_office].length()
            < _workers.length
        ) {
            revert("The office does not have enough slots available");
        }

        for (uint8 i = 0; i < _workers.length; ++i) {
            require(IERC721(_collection).ownerOf(_workers[i]) == msg.sender, "Not the owner of the humans");
            require(!humanEnrolmentMapping[keccak256(abi.encode(_collection, _workers[i]))], "Human already enrolled");
            tokenEnrolmentEmployeesMapping[_office].add(_workers[i]);
            humanEnrolmentMapping[keccak256(abi.encode(_collection, _workers[i]))] = true;
        }

        uint256 value = block.timestamp;

        notifyYielder(value, _collection, _workers);

        emit RealEstateEnrolment(_workers, _office, value, msg.sender, _collection);

        delete value;

    }

    function retrieveHuman(uint256[] calldata _workers, uint256 _office, address _collection) external whenNotPaused {
        require(collections.contains(_collection));
        require(ownerOf(_office) == msg.sender);

        for (uint8 i = 0; i < _workers.length; ++i) {
            require(IERC721(_collection).ownerOf(_workers[i]) == msg.sender);
            require(humanEnrolmentMapping[keccak256(abi.encode(_collection, _workers[i]))], "Human not enrolled");
            require(tokenEnrolmentEmployeesMapping[_office].contains(_workers[i]), "Human not enrolled in specified office");
            tokenEnrolmentEmployeesMapping[_office].remove(_workers[i]);
            humanEnrolmentMapping[keccak256(abi.encode(_collection, _workers[i]))] = false;
        }

        notifyYielder(0, _collection, _workers);

        emit RealEstateEnrolmentRetrieval(_workers, _office, 0, msg.sender, _collection);
    }

    function notifyYielder(uint256 value, address _collection, uint256[] calldata tokens) internal {
        uint256[] memory startDates = new uint256[](tokens.length);
        for (uint8 i = 0; i < startDates.length; ++i) {
            startDates[i] = value;
        }

        IBoostWatcher(tokenAddress).watchBooster(_collection, tokens, startDates);

        delete startDates;
    }

    function lockCoordinates(Coordinate[] memory _coordinates) external onlyOwner {
        validateCoordinates(_coordinates);

        for (uint64 i = 0; i < _coordinates.length; ++i) {
            if (!realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))]) {
                realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))] = true;
            }
        }

    }

    function unlockCoordinates(Coordinate[] memory _coordinates) external onlyOwner {
        for (uint64 i = 0; i < _coordinates.length; ++i) {
            if (realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))]) {
                realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))] = false;
            }
        }

    }

    function reserveCoordinates(Coordinate[] memory _coordinates) external onlyOwner {
        validateCoordinates(_coordinates);

        uint256[] memory tokenIds = occupyLand(_coordinates);

        for (uint64 i = 0; i < _coordinates.length; ++i) {
            if (!realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))]) {
                realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))] = true;
            }
        }

        emit RealEstateMinted(tokenIds, _coordinates, msg.sender);
    }

    function occupyLand(Coordinate[] memory _coordinates) internal returns(uint256[] memory ){
        uint256[] memory tokenIds = new uint256[](_coordinates.length);
        uint256 totalSupply = totalSupply();

        for (uint256 i = 0; i < _coordinates.length; ++i) {
            tokenIds[i] = totalSupply + i;
            tokensTypeMapping[totalSupply + i] = LAND;
            tokensCoordinates[totalSupply + i] = _coordinates[i];
            realEstateOccupancyMapping[keccak256(abi.encode(_coordinates[i].x, _coordinates[i].y, _coordinates[i].layer))] = true;
            _safeMint(msg.sender, totalSupply + i);
        }

        return tokenIds;
    }

    // backend

    function getTokensType(uint256[] calldata _tokenIds) public view returns(uint256[] memory) {
        uint256[] memory types = new uint256[](_tokenIds.length);
        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            types[i] = tokensTypeMapping[_tokenIds[i]];
        }

        delete types;

        return types;
    }

    function getTokensCoordinates(uint256[] calldata _tokenIds) public view returns(Coordinate[] memory) {
        Coordinate[] memory coordinates = new Coordinate[](_tokenIds.length);
        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            coordinates[i] = tokensCoordinates[_tokenIds[i]];
        }

        delete coordinates;

        return coordinates;
    }

    function getTokensEnrolments(uint256[] calldata _tokenIds) public view returns(uint256[][] memory) {
        uint256[][] memory enrolments = new uint256[][](_tokenIds.length);
        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            enrolments[_tokenIds[i]] = new uint256[](tokenEnrolmentEmployeesMapping[_tokenIds[i]].length());

            for (uint8 j = 0; j < tokenEnrolmentEmployeesMapping[_tokenIds[i]].length(); ++i) {
                enrolments[_tokenIds[i]][j] = tokenEnrolmentEmployeesMapping[_tokenIds[i]].at(j);
            }
        }

        for (uint64 i = 0; i < _tokenIds.length; ++i) {
            delete enrolments[_tokenIds[i]];
        }

        delete enrolments;

        return enrolments;
    }

    function getTokensOwners(uint256[] calldata _tokenIds) external view returns(address[] memory) {
        address[] memory addresses = new address[](_tokenIds.length);

        for(uint64 i = 0; i < _tokenIds.length; ++i) {
            addresses[i] = ownerOf(_tokenIds[i]);
        }

        delete addresses;

        return addresses;
    }

    // overrides

    function tokenURI(uint256 _tokenId) external view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : "";
    }

    // boosting

    function computeAmount(uint256 amount) external view returns(uint256) {
        return amount + amount * bonusPercentage / 100;
    }

}