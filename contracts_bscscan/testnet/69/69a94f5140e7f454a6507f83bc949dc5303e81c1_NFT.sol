/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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


abstract contract Ownable is Context {

	mapping(address => bool) public manager;

    event OwnershipTransferred(address indexed newOwner, bool isManager);


    constructor() {
        _setOwner(_msgSender(), true);
    }

    modifier onlyOwner() {
        require(manager[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    function setOwner(address newOwner,bool isManager) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner,isManager);
    }

    function _setOwner(address newOwner, bool isManager) private {
        manager[newOwner] = isManager;
        emit OwnershipTransferred(newOwner, isManager);
    }
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _baseURI;


    string private _name;
    string private _symbol;


    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    constructor(string memory name_, string memory symbol_ ,string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _setBaseURI(baseURI_);
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
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


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";
    }


    function baseURI() internal view virtual returns (string memory) {
        return _baseURI;
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        return _owners[tokenId] != address(0);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }


    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }


    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
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

contract NFT is ERC721Enumerable , ReentrancyGuard , Ownable{
    using SafeMath for uint256; 
    using Strings for uint256;
	string private _imgURI;

    struct NftInfo{
        uint256 level;
        string name;
        uint256 role;
        uint256 force;
        uint256 agile;
        uint256 physique;
        uint256 intellect;
        uint256 willpower;
        uint256 spirit;
    }

    mapping(uint256 => NftInfo) public nftMap;

    // level  
    mapping(uint256 => uint256) public levelMultiple;

    struct UpgradeInfo{
        bool isUpgrade;
        address goldToken;
        uint256 goldAmount;
        address bnxToken;
        uint256 bnxAmount;
        uint256 multiple;
    }
    // nextId 
    mapping(uint256 => UpgradeInfo) upgradeMap;

    struct RoleAttProb{
    //string name;
        uint256 minForce;
        uint256 maxForce;
        uint256 minAgile;
        uint256 maxAgile;
        uint256 minPhysique;
        uint256 maxPhysique;
        uint256 minIntellect;
        uint256 maxIntellect;
        uint256 minWillpower;
        uint256 maxWillpower;
        uint256 minSpirit;
        uint256 maxSpirit;
    }

    mapping(uint256 => string) public roleName;
    mapping(uint256 => RoleAttProb) public roleAttMap;
    mapping(uint256 => mapping(uint256 => uint256)) public current;
	
	struct BlindBoxInfo{
		bool status;
		uint256 totalProb;
		uint256[] nftkeys;
		uint256[] probability;
		address token;
		uint256 amount;
        uint256 brokeRate;
	}
	mapping(uint256 => BlindBoxInfo) public blindBoxMap;
	mapping(address => mapping(uint256 => uint256)) private numForDay;
    uint256 public timeCorrection;
    uint256 public maxNumOfDay;
	mapping(address => bool) public whitelist;
    uint256 public additional;
    address public wallet;


	
	address public gheAddress = 0x9AD44e8Bf6C485dB08b041185a05c0d16D16069c;
	address public ghcAddress = 0x683fae4411249Ca05243dfb919c20920f3f5bfE0;
	
	uint256[] private boxNftKeys = [1,2,3,4,5,6,7,8,9,10];
	uint256[] private boxNftProb = [10,10,10,10,10,10,10,10,10,10];
	
	uint256[] private roleMinA = [61,25,25,1,30,31];
	uint256[] private roleMaxA = [38,15,54,29,50,9];
	uint256[] private roleMinB = [11,11,1,61,30,25];
	uint256[] private roleMaxB = [19,19,29,38,50,54];
	uint256[] private roleMinC = [35,61,25,25,30,11];
	uint256[] private roleMaxC = [25,38,15,54,50,19];
	uint256[] private roleMinD = [61,25,25,1,30,31];
	uint256[] private roleMaxD = [38,15,54,29,50,9];
	uint256[] private roleMinE = [25,35,61,25,30,35];
	uint256[] private roleMaxE = [54,25,38,15,50,25];
	uint256[] private roleMinF = [11,11,1,61,30,25];
	uint256[] private roleMaxF = [19,19,29,38,50,54];
	uint256[] private roleMinG = [35,61,25,25,30,11];
	uint256[] private roleMaxG = [25,38,15,54,50,19];
	uint256[] private roleMinH = [25,35,61,25,30,35];
	uint256[] private roleMaxH = [54,25,38,15,50,25];
	uint256[] private roleMinI = [31,25,25,1,30,61];
	uint256[] private roleMaxI = [9,54,15,29,50,38];
	uint256[] private roleMinJ = [31,25,25,1,30,61];
	uint256[] private roleMaxJ = [9,54,15,29,50,38];
    
    uint256 public nonce;

    struct relationInfo{
        address leader;
        address[] underling;
        uint256 brokerage;
    }
    mapping(uint256 => mapping(address => relationInfo)) relationMap;
	
	event UpgradeNft(address indexed user, uint256 nftId, bool status);
    event Withdraw(address indexed user, uint256 boxId, uint256 amount);

    receive() external payable {
    }
    
    constructor() ERC721("Galaxy Heroes", "Galaxy Heroes" ,"https://game.galaxyheroesx.com/api/index/index/id/") Ownable() {
		
		_imgURI = "https://game.galaxyheroesx.com/api/index/nftimg/id/";
        _setCurrent(1,1,10101000000001);
        _setCurrent(1,2,10201000000001);
        _setCurrent(1,3,10301000000001);
        _setCurrent(1,4,10401000000001);
        _setCurrent(1,5,10501000000001);
        _setCurrent(1,6,10601000000001);
        _setCurrent(1,7,10701000000001);
        _setCurrent(1,8,10801000000001);
        _setCurrent(1,9,10901000000001);
        _setCurrent(1,10,11001000000001);
		_setCurrent(2,1,20101000000001);
		
		
		_setUpgradeMap(2, true, gheAddress, 5000 * 10**8 * 10**18, ghcAddress, 0,30);
		_setUpgradeMap(3, true, gheAddress, 12500 * 10**8 * 10**18, ghcAddress, 0,30);
		_setUpgradeMap(4, true, gheAddress, 37500 * 10**8 * 10**18, ghcAddress, 0,35);
		_setUpgradeMap(5, true, gheAddress, 112500 * 10**8 * 10**18, ghcAddress, 500 * 10 ** 8 * 10**9, 35);
		_setUpgradeMap(6, true, gheAddress, 247500 * 10**8 * 10**18, ghcAddress, 1000 * 10 ** 8 * 10**9, 40);
		_setUpgradeMap(7, true, gheAddress, 495000 * 10**8 * 10**18, ghcAddress, 2500 * 10 ** 8 * 10**9, 40);
		_setUpgradeMap(8, true, gheAddress, 1237500 * 10**8 * 10**18, ghcAddress, 5000 * 10 ** 8 * 10**9, 45);
		_setUpgradeMap(9, true, gheAddress, 2475 * 10**11 * 10**18, ghcAddress, 10000 * 10 ** 8 * 10**9, 45);
		_setUpgradeMap(10, true, gheAddress, 495 * 10**12 * 10**18, ghcAddress, 20000 * 10 ** 8 * 10**9, 50);
		_setUpgradeMap(11, true, gheAddress, 12375 * 10**11 * 10**18, ghcAddress, 40000 * 10 ** 8 * 10**9, 55);
		_setUpgradeMap(12, true, gheAddress, 2475 * 10**12 * 10**18, ghcAddress, 80000 * 10 ** 8 * 10**9, 55);
		
		_setBlindBoxMap(0,true,ghcAddress, 10 * 10**8 * 10**9, 10, boxNftKeys, boxNftProb);
		
		
		_setRoleAttMap(1,roleMinA,roleMaxA);
		_setRoleAttMap(2,roleMinB,roleMaxB);
		_setRoleAttMap(3,roleMinC,roleMaxC);
		_setRoleAttMap(4,roleMinD,roleMaxD);
		_setRoleAttMap(5,roleMinE,roleMaxE);
		_setRoleAttMap(6,roleMinF,roleMaxF);
		_setRoleAttMap(7,roleMinG,roleMaxG);
		_setRoleAttMap(8,roleMinH,roleMaxH);
		_setRoleAttMap(9,roleMinI,roleMaxI);
		_setRoleAttMap(10,roleMinJ,roleMaxJ);
		
		
        _setlevelMultiple(1,1);
        _setlevelMultiple(2,3);
		_setlevelMultiple(3,6);
        _setlevelMultiple(4,10);
        _setlevelMultiple(5,20);
        _setlevelMultiple(6,30);
        _setlevelMultiple(7,60);
        _setlevelMultiple(8,90);
        _setlevelMultiple(9,120);
        _setlevelMultiple(10,220);
        _setlevelMultiple(11,420);
        _setlevelMultiple(12,700);	

        _setRoleName(1,"Gene warrior");
		_setRoleName(2,"Element mage");
		_setRoleName(3,"Mechanical madman");
		_setRoleName(4,"Storm Warrior");
		_setRoleName(5,"Knights");
		_setRoleName(6,"Stranger");
		_setRoleName(7,"Spirit Ranger");
		_setRoleName(8,"Knight of the blue");
		_setRoleName(9,"Apostle of death");
		_setRoleName(10,"Ghost");
		
        maxNumOfDay = 5;
		wallet = 0x73BE097576A2C72354E480599Ce447D580e3ff00;
			
        
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
	function setImgURI(string memory imgURI_) public onlyOwner {
        _imgURI = imgURI_;
    }
    function _setCurrent(uint256 _type, uint256 _nftId, uint256 _initialId) internal{
        current[_type][_nftId] = _initialId;
    }
	
	function imgURI(uint256 tokenId) public view  returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_imgURI).length > 0 ? string(abi.encodePacked(_imgURI, tokenId.toString())) : "";
    }	
	
    function numToDayTimes(address _user) public view returns(uint256){
        uint256 todaytimes = (block.timestamp.add(timeCorrection)).div(86400);
        return numForDay[_user][todaytimes];
    }
    function setTimeCorrection(uint256 _timeCorrection) public onlyOwner{
        timeCorrection = _timeCorrection;
    }

    function setMaxNumOfDay(uint256 _maxNumOfDay) public onlyOwner{
        maxNumOfDay = _maxNumOfDay;
    }
    function setAdditional(uint256 _additional) public onlyOwner{
        additional = _additional;
    }
	function setWallet(address _wallet)public onlyOwner{
		wallet = _wallet;
	}
    function setWhitelist(address _user, bool _status) public onlyOwner{
        whitelist[_user] = _status;
    }

    function buyBlindBox(uint256 _boxId , address _leader) public {
		require(blindBoxMap[_boxId].status == true,"unavailable");
        uint256 todaytimes = (block.timestamp.add(timeCorrection)).div(86400);
        bool isWhite = whitelist[msg.sender];
        if(!isWhite){
            require(numForDay[msg.sender][todaytimes] < maxNumOfDay,"unavailable");
        }
		IERC20(blindBoxMap[_boxId].token).transferFrom(msg.sender,address(this),blindBoxMap[_boxId].amount);
		
        uint256 randId = randomNum(1,blindBoxMap[_boxId].totalProb);
        uint256 roleId = 0;
		for(uint256 i = 0;i < blindBoxMap[_boxId].nftkeys.length; i++){
			if( randId <= blindBoxMap[_boxId].probability[i]){
				roleId = blindBoxMap[_boxId].nftkeys[i];
				break;
			}
		}
		
        uint256 newId = current[1][roleId]++;
        _setAttProb(roleId,newId,isWhite);
		nftMap[newId].level = 1;
        _safeMint(msg.sender, newId);
        numForDay[msg.sender][todaytimes] = numForDay[msg.sender][todaytimes].add(1);
        _handling(_boxId,msg.sender,_leader);
    }

    function _handling(uint256 _boxId, address _from, address _leader) internal {
        if(relationMap[_boxId][_from].leader == address(0) && _leader != address(0) && _leader != _from){
            relationMap[_boxId][_from].leader = _leader;
        }
        uint256 brokerage = 0;
        if(relationMap[_boxId][_from].leader != address(0)){

        (bool isIn,) = firstIndexOf(relationMap[_boxId][relationMap[_boxId][_from].leader].underling,_from);
		if(!isIn){
			relationMap[_boxId][relationMap[_boxId][_from].leader].underling.push(_from);
		}
        brokerage = blindBoxMap[_boxId].amount.mul( blindBoxMap[_boxId].brokeRate).div(100);
        relationMap[_boxId][relationMap[_boxId][_from].leader].brokerage = relationMap[_boxId][relationMap[_boxId][_from].leader].brokerage.add(brokerage);
        }
		
        IERC20(blindBoxMap[_boxId].token).transfer(wallet, blindBoxMap[_boxId].amount.sub(brokerage));
    }

    function firstIndexOf(address[] memory array, address key) internal pure returns (bool, uint256) {

    	if(array.length == 0){
    		return (false, 0);
    	}

    	for(uint256 i = 0; i < array.length; i++){
    		if(array[i] == key){
    			return (true, i);
    		}
    	}
    	return (false, 0);
    }

    function randomNum(uint256 _min, uint256 _max)internal returns(uint256) {
        uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % _max;   
        nonce++;
        return index.add(_min);
    }

    function _setAttProb(uint256 _roleId, uint256 _NftId, bool _isWhite)internal{
        nftMap[_NftId].name = roleName[_roleId];
        nftMap[_NftId].role = _roleId;
        if(_isWhite){
            nftMap[_NftId].force = randomNum(roleAttMap[_roleId].minForce.add(additional),roleAttMap[_roleId].maxForce);
            nftMap[_NftId].agile = randomNum(roleAttMap[_roleId].minAgile.add(additional),roleAttMap[_roleId].maxAgile);
            nftMap[_NftId].physique = randomNum(roleAttMap[_roleId].minPhysique.add(additional),roleAttMap[_roleId].maxPhysique);
            nftMap[_NftId].intellect = randomNum(roleAttMap[_roleId].minIntellect.add(additional),roleAttMap[_roleId].maxIntellect);
            nftMap[_NftId].willpower = randomNum(roleAttMap[_roleId].minWillpower.add(additional),roleAttMap[_roleId].maxWillpower);
            nftMap[_NftId].spirit = randomNum(roleAttMap[_roleId].minSpirit.add(additional),roleAttMap[_roleId].maxSpirit);
        }else{
            nftMap[_NftId].force = randomNum(roleAttMap[_roleId].minForce,roleAttMap[_roleId].maxForce);
            nftMap[_NftId].agile = randomNum(roleAttMap[_roleId].minAgile,roleAttMap[_roleId].maxAgile);
            nftMap[_NftId].physique = randomNum(roleAttMap[_roleId].minPhysique,roleAttMap[_roleId].maxPhysique);
            nftMap[_NftId].intellect = randomNum(roleAttMap[_roleId].minIntellect,roleAttMap[_roleId].maxIntellect);
            nftMap[_NftId].willpower = randomNum(roleAttMap[_roleId].minWillpower,roleAttMap[_roleId].maxWillpower);
            nftMap[_NftId].spirit = randomNum(roleAttMap[_roleId].minSpirit,roleAttMap[_roleId].maxSpirit);
        }
    }

    function withdraw(uint256 _boxId)public{
        uint256 brokerage = relationMap[_boxId][msg.sender].brokerage;
        relationMap[_boxId][msg.sender].brokerage = 0;
        IERC20(blindBoxMap[_boxId].token).transfer(msg.sender, brokerage);
        emit Withdraw(msg.sender,_boxId,brokerage);

    }

    function relation(address _user, uint256 _boxId) public view returns(relationInfo memory){
        return relationMap[_boxId][_user];
    }

	function upgradeNft(uint256 _nftId) public{
		require(_isApprovedOrOwner(_msgSender(), _nftId), "ERC721: transfer caller is not owner nor approved");
		uint256 nextlevelId = nftMap[_nftId].level.add(1);
		uint256 succProb = randomNum(1,100);
		if(upgradeMap[nextlevelId].goldAmount > 0){
			IERC20(upgradeMap[nextlevelId].goldToken).transferFrom(msg.sender,address(this),upgradeMap[nextlevelId].goldAmount);
		}
		if(upgradeMap[nextlevelId].bnxAmount > 0){
			IERC20(upgradeMap[nextlevelId].bnxToken).transferFrom(msg.sender,address(this),upgradeMap[nextlevelId].bnxAmount);
		}
		
		if( succProb >= upgradeMap[nextlevelId].multiple){
			nftMap[_nftId].level = nextlevelId;
			emit UpgradeNft(msg.sender,_nftId,true);
		}else{
			_burn(_nftId);
			emit UpgradeNft(msg.sender,_nftId,false);
		}		
	}


    function setRoleName(uint256 _roleId, string memory _name) external onlyOwner{
		_setRoleName(_roleId,_name);
    }
	
	function _setRoleName(uint256 _roleId, string memory _name)internal{
		roleName[_roleId] = _name;
    }


    function setRoleAttMap(uint256 _roleId, uint256[] memory min, uint256[] memory max) external onlyOwner{
		_setRoleAttMap(_roleId,min,max);
    }
	
	function _setRoleAttMap(uint256 _roleId, uint256[] memory min, uint256[] memory max)internal{
        require(min.length == max.length && min.length == 6,"Invalid length");
        //roleAttMap[_roleId].name = _name;

        roleAttMap[_roleId].minForce = min[0];
        roleAttMap[_roleId].minAgile = min[1];
        roleAttMap[_roleId].minPhysique = min[2];
        roleAttMap[_roleId].minIntellect = min[3];
        roleAttMap[_roleId].minWillpower = min[4];
        roleAttMap[_roleId].minSpirit = min[5];

        roleAttMap[_roleId].maxForce = max[0];
        roleAttMap[_roleId].maxAgile = max[1];
        roleAttMap[_roleId].maxPhysique = max[2];
        roleAttMap[_roleId].maxIntellect = max[3];
        roleAttMap[_roleId].maxWillpower = max[4];
        roleAttMap[_roleId].maxSpirit = max[5];
    }


	
	function setUpgradeMap(uint256 _levelId, bool _isUpgrade, address _goldToken, uint256 _goldAmount, address _bnxToken, uint256 _bnxAmount, uint256 _multiple) external onlyOwner{
		_setUpgradeMap(_levelId, _isUpgrade, _goldToken, _goldAmount, _bnxToken, _bnxAmount, _multiple);
		
	}
	
	function _setUpgradeMap(uint256 _levelId, bool _isUpgrade, address _goldToken, uint256 _goldAmount, address _bnxToken, uint256 _bnxAmount, uint256 _multiple) internal{
		upgradeMap[_levelId].isUpgrade = _isUpgrade;
		upgradeMap[_levelId].goldToken = _goldToken;
		upgradeMap[_levelId].goldAmount = _goldAmount;
		upgradeMap[_levelId].bnxToken = _bnxToken;
		upgradeMap[_levelId].bnxAmount = _bnxAmount;
		upgradeMap[_levelId].multiple = _multiple;
		
	}
	
	function setBlindBoxMap(uint256 _boxId, bool _status, address _token, uint256 _amount, uint256 _brokeRate ,uint256[] memory _nftkeys, uint256[] memory _probability)external onlyOwner{
		_setBlindBoxMap(_boxId,_status,_token,_amount,_brokeRate, _nftkeys,_probability);
	}

    function _setBlindBoxMap(uint256 _boxId, bool _status, address _token, uint256 _amount, uint256 _brokeRate , uint256[] memory _nftkeys, uint256[] memory _probability)internal{
		require(_nftkeys.length == _probability.length, "Invalid length");
		blindBoxMap[_boxId].status = _status;
		blindBoxMap[_boxId].token = _token;
		blindBoxMap[_boxId].amount = _amount;
        blindBoxMap[_boxId].brokeRate = _brokeRate;
		blindBoxMap[_boxId].nftkeys = _nftkeys;
		
		blindBoxMap[_boxId].totalProb = 0;
		for(uint256 i = 0; i < _probability.length; i++){
			blindBoxMap[_boxId].totalProb = blindBoxMap[_boxId].totalProb.add(_probability[i]);
            blindBoxMap[_boxId].probability.push(blindBoxMap[_boxId].totalProb);
		}
	}
	
	function setlevelMultiple(uint256 _levelId, uint256 _multiple)external onlyOwner{
		_setlevelMultiple(_levelId,_multiple);
	}	
	
	function _setlevelMultiple(uint256 _levelId, uint256 _multiple) internal{
		levelMultiple[_levelId] = _multiple;
	}
	
    function mintNft(address _user, uint256 _typeId, uint256 _roleId)external onlyOwner{
		_mintNft(_user,_typeId,_roleId);
	}

	function _mintNft(address _user, uint256 _typeId, uint256 _roleId)internal{
		uint256 newId = current[_typeId][_roleId]++;
        _safeMint(_user, newId);
	}


	function setNftInfo(uint256 _nftId, string memory _name, uint256 _level, uint256 _force, uint256 _agile, uint256 _physique, uint256 _intellect, uint256 _willpower, uint256 _spirit)external onlyOwner{
        _setNftInfo(_nftId,_name,_level,_force,_agile,_physique,_intellect,_willpower,_spirit);
	}	

    function _setNftInfo(uint256 _nftId, string memory _name, uint256 _level, uint256 _force, uint256 _agile, uint256 _physique, uint256 _intellect, uint256 _willpower, uint256 _spirit) internal{
	    nftMap[_nftId].name = _name;
        nftMap[_nftId].level = _level;
		nftMap[_nftId].force = _force;
        nftMap[_nftId].agile = _agile;
        nftMap[_nftId].physique = _physique;
        nftMap[_nftId].intellect = _intellect;
        nftMap[_nftId].willpower = _willpower;
        nftMap[_nftId].spirit = _spirit;
	}	

	function CrossTransfer(IERC20 token, address beneficiary) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "no tokens to release");
        token.transfer(beneficiary, amount);
	}
  
	function PayTransfer(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
	}

	function batchBalance(address _user) public view returns(uint256, uint256[] memory, string[] memory, string[] memory, NftInfo[] memory ){
     
		uint256 amount = balanceOf(_user);
		uint256[] memory nftIds = new uint256[](amount);
		string[] memory tokenUris = new string[](amount);
		string[] memory imgUris = new string[](amount);
		NftInfo[] memory nftInfos = new NftInfo[](amount);
		for(uint256 i = 0; i< amount; i++){          
			nftIds[i] = tokenOfOwnerByIndex(_user,i);          
			tokenUris[i] = tokenURI(nftIds[i]);
			imgUris[i] = imgURI(nftIds[i]);
			nftInfos[i] = nftMap[nftIds[i]];
		}
		return (amount,nftIds,tokenUris,imgUris,nftInfos);
	}

    function setConfig(address _wallet, uint256 _maxNumOfDay, uint256 _timeCorrection, uint256 _additional)external onlyOwner{
		wallet = _wallet;
		maxNumOfDay = _maxNumOfDay;
		timeCorrection = _timeCorrection;
		additional = _additional;

    }

}