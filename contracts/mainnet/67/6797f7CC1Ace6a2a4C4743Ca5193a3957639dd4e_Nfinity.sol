/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
}

contract Administrative is Ownable {
  using Counters for Counters.Counter;

  address private _withdrawer;

  string public uriBase      = "https://i.nfinity.space/";
  string public uriPathQuilt = "quilts/";
  string public uriPathPatch = "patches/";

  Counters.Counter public version;

  uint256 public staticPatchMintPrice  = .025 ether;
  uint256 public dynamicPatchMintPrice = .001 ether;

  uint256 public staticPatchDrawPrice = .001 ether;

  bool public patchMintingEnabled = true;
  bool public patchDrawingEnabled = true;

  // The first quilt raffle happens at the 16th Patch (aka Patch #15),
  uint256 public quiltGiftIndex = 16;

  bool public secureRandom = false;
  bool public ignoreLinkBalance = false;

  bytes32 internal _vrfKeyHash = 0;
  uint256 internal _vrfFee = 0;

  constructor(bytes32 newVrfKeyHash, uint256 newVrfFee) {
    _vrfKeyHash = newVrfKeyHash;
    _vrfFee = newVrfFee;
    _withdrawer = _msgSender();
  }

  /*
   * Admin functions
   */

  function adminUpdateDynamicPatchMintPrice(uint256 price) external onlyOwner {
    dynamicPatchMintPrice = price;
  }

  function adminUpdateStaticPatchMintPrice(uint256 price) external onlyOwner {
    staticPatchMintPrice = price;
  }

  function adminUpdateStaticPatchDrawPrice(uint256 price) external onlyOwner {
    staticPatchDrawPrice = price;
  }

  function adminTogglePatchMinting(bool enabled) external onlyOwner {
    patchMintingEnabled = enabled;
  }

  function adminTogglePatchDrawing(bool enabled) external onlyOwner {
    patchDrawingEnabled = enabled;
  }

  function adminUpdateUris(string memory base, string memory pathQuilt, string memory pathPatch)
  external onlyOwner {
    uriBase         = base;
    uriPathQuilt    = pathQuilt;
    uriPathPatch    = pathPatch;
  }

  function adminUpdateSecureRandom(bool enabled) external onlyOwner {
    secureRandom = enabled;
  }

  function adminUpdateIgnoreLinkBalance(bool ignore) external onlyOwner {
    ignoreLinkBalance = ignore;
  }

  function adminUpdateQuiltGiftIndex(uint256 index) external onlyOwner {
    quiltGiftIndex = index;
  }

  function adminUpdateVrfFee(uint256 fee) external onlyOwner {
    _vrfFee = fee;
  }

  function adminUpdateVrfKeyHash(bytes32 keyHash) external onlyOwner {
    _vrfKeyHash = keyHash;
  }

  function adminUpdateWithdrawer(address withdrawer) external onlyOwner {
    _withdrawer = withdrawer;
  }

  /*
   * Funds
   */

  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function withdraw() external {
    require(_withdrawer == msg.sender, "not_withdrawer");
    payable(msg.sender).transfer(getBalance());
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable { }
  fallback() external payable { }
}


library Data {
  enum TokenType {
    NULL, QUILT, PATCH
  }

  struct DefinedIndex {
    uint256 index;
    bool defined;
  }

  function index(uint256 value) internal pure returns(DefinedIndex memory) {
    return DefinedIndex(value, true);
  }
}



library Cursors {
  struct Cursor {
    uint256 segMax;
    uint256 segCur;
    int256  dirX;
    int256  dirY;
    int256  headX;
    int256  headY;
  }

  function initialCursor() internal pure returns(Cursor memory) {
    return Cursor({
      segMax: 1,
      segCur: 0,
      dirX:   1,
      dirY:   0,
      headX:  0,
      headY:  0
    });
  }

  /// Move the Cursor head outward in a spiral matrix pattern
  function moveHead(Cursor storage cursor) internal {
    cursor.headX += cursor.dirX;
    cursor.headY += cursor.dirY;

    cursor.segCur++;

    if (cursor.segCur == cursor.segMax) {
      cursor.segCur = 0;

      int256 buffer = cursor.dirX;
      cursor.dirX = cursor.dirY;
      cursor.dirY = -buffer;

      if (cursor.dirY == 0) {
        cursor.segMax++;
      }
    }
  }
}



library Helpers {
  function tokenURI(Nfinity instance, uint256 tokenId, uint256 version) internal view returns (string memory) {
    require(instance.tokenExists(tokenId), "token_not_found");

    uint256 index = 0;
    Data.TokenType tokenType = instance.tokenIdToType(tokenId);
    string memory path;

    if (tokenType == Data.TokenType.QUILT) {
      (index, ) = instance.tokenIdToQuiltIndex(tokenId);
      path = instance.uriPathQuilt();
    } else if (tokenType == Data.TokenType.PATCH) {
      (index,) = instance.tokenIdToPatchIndex(tokenId);
      path = instance.uriPathPatch();
    } else {
      revert("token_type_not_found");
    }

    return string(abi.encodePacked(instance.uriBase(), path, Strings.toString(index), "/meta.json?version=", Strings.toString(version)));
  }
}



library Quilts {
  using Patches for Patches.Patch;

  struct Quilt {
    uint256 id;
    uint256 index;
    uint256 createdAt;
    address winner;
    uint256 blockNum;
  }

  /* static */

  function getQuiltIdsByOwner(Nfinity instance, address owner) internal view returns(uint256[] memory quiltIds) {
    uint quiltCount = instance.getQuiltCount();
    uint ownedCount = 0;

    for (uint i = 0; i < quiltCount; i++) {
      if (instance.ownerOf(instance.getQuiltIdByIndex(i)) == owner) {
        ownedCount++;
      }
    }

    quiltIds = new uint[](ownedCount);

    uint counter = 0;
    for (uint i = 0; i < quiltCount; i++) {
      uint id = instance.getQuiltIdByIndex(i);
      if (instance.ownerOf(id) == owner) {
        quiltIds[counter] = id;
        counter++;
      }
    }

    return quiltIds;
  }

  function create(address owner, uint256 id, Quilt[] storage allQuilts, mapping (uint256 => Data.DefinedIndex) storage idToIndexMap) internal returns(Quilt memory quilt) {
    uint index = allQuilts.length;

    quilt = Quilt({
      id:        id,
      index:     index,
      createdAt: block.timestamp, // solhint-disable-line not-rely-on-time
      winner:    owner,
      blockNum:  0
    });

    allQuilts.push(quilt);

    idToIndexMap[id] = Data.index(index);

    return quilt;
  }

  function freeze(uint256 id, uint256 blockNum, mapping (uint256 => Data.DefinedIndex) storage map, Quilt[] storage quilts) internal {
    Data.DefinedIndex memory index = map[id];
    require(index.defined, "quilt_not_found");

    Quilts.Quilt storage quilt = quilts[index.index];
    quilt.blockNum = blockNum;
  }
}



library Patches {
  using Cursors for Cursors.Cursor;
  using Raffles for Raffles.Pool;

  uint public constant PATCH_PIXEL_COUNT = 32 * 32;

  // uint24[256] internal _emptyPatchImage; // = [ 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 ];

  struct Patch {
    uint256 id;
    uint256 index;
    int256 x;
    int256 y;
    uint256 createdAt;
    address creator;
    uint256 adminFlags;
    uint256 userFlags;
    uint256 lastBlockDrawn;
  }

  event PatchDrawn(address indexed owner, uint256 indexed patchId, Patches.Patch patch, uint24[PATCH_PIXEL_COUNT] pixels);

  /* static */

  function create(address owner, uint256 id, Cursors.Cursor storage cursor, Patch[] storage allPatches, mapping (uint256 => Data.DefinedIndex) storage idToIndexMap) internal returns(Patch memory patch) {
    uint index = allPatches.length;

    patch = Patch({
      id:             id,
      index:          index,
      x:              cursor.headX,
      y:              cursor.headY,
      createdAt:      block.timestamp, // solhint-disable-line not-rely-on-time
      creator:        owner,
      adminFlags:     0,
      userFlags:      0,
      lastBlockDrawn: 0
    });

    allPatches.push(patch);

    cursor.moveHead();

    idToIndexMap[id] = Data.index(index);

    return patch;
  }

  function getPatchIdsByOwner(Nfinity instance, address owner) internal view returns(uint256[] memory patchIds) {
    uint patchCount = instance.getPatchCount();
    uint ownedCount = 0;

    for (uint i = 0; i < patchCount; i++) {
      if (instance.ownerOf(instance.getPatchIdByIndex(i)) == owner) {
        ownedCount++;
      }
    }

    patchIds = new uint[](ownedCount);

    uint counter = 0;
    for (uint i = 0; i < patchCount; i++) {
      uint id = instance.getPatchIdByIndex(i);
      if (instance.ownerOf(id) == owner) {
        patchIds[counter] = id;
        counter++;
      }
    }

    return patchIds;
  }

  function draw(uint256 patchId, uint24[PATCH_PIXEL_COUNT] memory pixels, uint256 price,
                mapping (uint256 => Data.DefinedIndex) storage map, Patch[] storage patches,
                Raffles.Pool storage rafflePool,
                address ignoreAddress) internal
  {
    require(msg.value >= price, "patch_draw_fee_not_met");

    Data.DefinedIndex memory index = map[patchId];
    require(index.defined, "patch_not_found");

    Patch storage patch = patches[index.index];
    patch.lastBlockDrawn = block.number;

    // Contract owner can't participate in raffles. Neither can the withdrawer.
    if (msg.sender != ignoreAddress) {
      rafflePool.add(patch.id);
    }

    emit PatchDrawn(msg.sender, patchId, patch, pixels);
  }

  function setUserFlags(uint256 patchId, uint256 newUserFlags, mapping (uint256 => Data.DefinedIndex) storage map,
                        Patch[] storage patches)  internal
  {
    Data.DefinedIndex memory index = map[patchId];
    require(index.defined, "patch_not_found");

    Patch storage patch = patches[index.index];
    patch.userFlags = newUserFlags;
  }

  function setAdminFlags(uint256 patchId, uint256 newAdminFlags, mapping (uint256 => Data.DefinedIndex) storage map,
                         Patch[] storage patches) internal
  {
    Data.DefinedIndex memory index = map[patchId];
    require(index.defined, "patch_not_found");

    Patch storage patch = patches[index.index];
    patch.adminFlags = newAdminFlags;
  }
}



abstract contract Rng is VRFConsumerBase, Administrative {
  mapping(bytes32 => address) public rngRequestIdToSender;

  function rngReceive(address sender, uint256 randomNumber) internal virtual;

  function hasEnoughLink() public view returns(bool) {
    if (ignoreLinkBalance) {
      return true;
    }

    return LINK.balanceOf(address(this)) > _vrfFee;
  }

  function rngGenerate() internal {
    if (secureRandom && hasEnoughLink()) {
      bytes32 requestId = requestRandomness(_vrfKeyHash, _vrfFee);
      rngRequestIdToSender[requestId] = msg.sender;
    } else {
      requestRandomnessInsecure();
    }
  }

  function requestRandomnessInsecure() private {
    uint256 randomNumber = uint256(
      keccak256(
        abi.encode(
          blockhash(block.number - 1),
          block.number,
          block.difficulty,
          msg.sender
        )
      )
    );

    rngReceive(msg.sender, randomNumber);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
    address sender = rngRequestIdToSender[requestId];
    if (sender == address(0)) return;

    rngReceive(sender, randomNumber);
  }
}


library Raffles {
  struct Pool {
    bool ignore;
    mapping(uint256 => bool) _map;
    uint256[] _list;
  }

  function add(Pool storage pool, uint256 value) internal {
    if (pool._map[value] == false) {
      pool._map[value] = true;
      pool._list.push(value);
    }
  }

  function getWinner(Pool storage pool, uint256 randomNumber) internal view returns(bool found, uint256 winner) {
    // Choose from a list of drawn patches, plus 1 for the minter. They get entered
    // into the raffle too since they haven't had an opportunity to Draw yet.
    uint256 winnerPatchIndex = randomNumber % (pool._list.length + 1);

    if (winnerPatchIndex == pool._list.length) {
      return (false, 0);
    } else {
      return (true, pool._list[winnerPatchIndex]);
    }
  }
}



contract Nfinity is Administrative, Rng, ERC721 {
  using Counters for Counters.Counter;
  using Cursors for Cursors.Cursor;
  using Patches for Patches.Patch;
  using Quilts for Quilts.Quilt;
  using Raffles for Raffles.Pool;

  uint public constant PATCH_PIXEL_COUNT = 32 * 32;
  string public constant TOKEN_NAME   = "Nfinity";
  string public constant TOKEN_SYMBOL = "NFI";

  Counters.Counter public tokenIds;
  Raffles.Pool public rafflePool;
  Cursors.Cursor public cursor = Cursors.initialCursor();

  Patches.Patch[] public patches;
  Quilts.Quilt[] public quilts;

  mapping (uint256 => Data.TokenType) public tokenIdToType;

  mapping (uint256 => Data.DefinedIndex) public tokenIdToPatchIndex;
  mapping (uint256 => Data.DefinedIndex) public tokenIdToQuiltIndex;

  event NewQuiltMinted(address indexed owner, uint256 indexed quiltId, Quilts.Quilt quilt);
  event NewPatchMinted(address indexed owner, uint256 indexed patchId, Patches.Patch patch);
  event PatchDrawn(address indexed owner, uint256 indexed patchId, Patches.Patch patch, uint24[PATCH_PIXEL_COUNT] pixels);

  constructor(address vrfCoordinator, address vrfLink, bytes32 vrfKeyHash, uint256 vrfFee)
    ERC721(TOKEN_NAME, TOKEN_SYMBOL)
    VRFConsumerBase(vrfCoordinator, vrfLink)
    Administrative(vrfKeyHash, vrfFee)
  {
    // Secure the first 3 Quilt NFTs for Jimmie
    // This is done manually so that the genesis Quilt's tokenId is 0
    for (uint i = 0; i < 3; i++) {
      _createQuilt(msg.sender);
    }

    // Secure the first 12 Patch NFTs for Jimmie
    for (uint i = 0; i < 12; i++) {
      _createPatchNoRaffle(msg.sender);
    }
  }

  function _createToken(Data.TokenType tokenType, address recipient) private returns(uint256 tokenId) {
    tokenId = tokenIds.current();
    _mint(recipient, tokenId);
    tokenIds.increment();
    version.increment();

    tokenIdToType[tokenId] = tokenType;

    return tokenId;
  }

  function tokenExists(uint256 tokenId) public view returns(bool) {
    return _exists(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns(string memory) {
    return Helpers.tokenURI(this, tokenId, version.current());
  }

  /*
   * Quilts
   */

  function _createQuilt(address owner) private returns(Quilts.Quilt memory quilt) {
    uint256 quiltId = _createToken(Data.TokenType.QUILT, owner);
    quilt = Quilts.create(owner, quiltId, quilts, tokenIdToQuiltIndex);
    emit NewQuiltMinted(owner, quiltId, quilt);
    return quilt;
  }

  function getQuiltCount() public view returns(uint) {
    return quilts.length;
  }

  function getQuiltById(uint256 quiltId) public view returns(Quilts.Quilt memory) {
    Data.DefinedIndex memory quiltIndex = tokenIdToQuiltIndex[quiltId];
    require(quiltIndex.defined, "quilt_not_found");

    return quilts[quiltIndex.index];
  }

  function getQuiltIdByIndex(uint256 index) public view returns(uint256) {
    return quilts[index].id;
  }

  function getQuiltIdsByOwner(address owner) external view returns(uint256[] memory quiltIds) {
    return Quilts.getQuiltIdsByOwner(this, owner);
  }

  function freezeQuilt(uint256 id, uint256 blockNum) external {
    require(ownerOf(id) == msg.sender, "quilt_incorrect_owner");
    Quilts.freeze(id, blockNum, tokenIdToQuiltIndex, quilts);
  }

  /*
   * Patches
   */

  function _createPatchNoRaffle(address owner) private returns(Patches.Patch memory patch) {
    uint256 patchId = _createToken(Data.TokenType.PATCH, owner);
    patch = Patches.create(owner, patchId, cursor, patches, tokenIdToPatchIndex);
    emit NewPatchMinted(owner, patchId, patch);

    return patch;
  }

  function _createPatch(address owner) private returns(Patches.Patch memory patch) {
    patch = _createPatchNoRaffle(owner);
    _startRaffleIfNeeded();
    return patch;
  }

  function getPatchById(uint256 id) public view returns(Patches.Patch memory) {
    Data.DefinedIndex memory patchIndex = tokenIdToPatchIndex[id];
    require(patchIndex.defined, "patch_not_found");

    return patches[patchIndex.index];
  }

  function getPatchIdByIndex(uint256 index) public view returns(uint256) {
    return patches[index].id;
  }

  function getPatchCount() public view returns(uint) {
    return patches.length;
  }

  function getMintPatchPrice() public view returns(uint) {
    return staticPatchMintPrice + dynamicPatchMintPrice * cursor.segMax;
  }

  function mintPatch() external payable returns(Patches.Patch memory) {
    require(patchMintingEnabled, "patch_minting_disabled");
    require(msg.value >= getMintPatchPrice(), "patch_mint_fee_not_met");
    return _createPatch(msg.sender);
  }

  function draw(uint256 patchId, uint24[PATCH_PIXEL_COUNT] memory pixels) external payable {
    require(patchDrawingEnabled, "patch_drawing_disabled");
    require(ownerOf(patchId) == msg.sender, "patch_incorrect_owner");
    address owner = owner();

    Patches.draw({
      patchId:        patchId,
      pixels:         pixels,
      price:          staticPatchDrawPrice,
      map:            tokenIdToPatchIndex,
      patches:        patches,
      rafflePool:     rafflePool,
      ignoreAddress:  owner
    });

    version.increment();
  }

  function getPatchIdsByOwner(address owner) external view returns(uint256[] memory patchIds) {
    return Patches.getPatchIdsByOwner(this, owner);
  }

  function setPatchUserFlags(uint256 patchId, uint256 newUserFlags) external payable {
    require(ownerOf(patchId) == msg.sender, "patch_incorrect_owner");
    Patches.setUserFlags(patchId, newUserFlags, tokenIdToPatchIndex, patches);
  }

  function adminSetPatchAdminFlags(uint256 patchId, uint256 newAdminFlags) external onlyOwner {
    Patches.setAdminFlags(patchId, newAdminFlags, tokenIdToPatchIndex, patches);
  }

  /*
   * Raffle
   */

  function _startRaffleIfNeeded() private {
    if (patches.length == quiltGiftIndex) {
      rngGenerate();
      quiltGiftIndex *= 2;
    }
  }

  function rngReceive(address sender, uint256 randomNumber) internal virtual override {
    (bool found, uint256 winningPatchId) = rafflePool.getWinner(randomNumber);
    address winner = found ? ownerOf(winningPatchId) : sender;

    _createQuilt(winner);

  }

  function getRaffleParticipants() external view returns(uint256[] memory) {
    return rafflePool._list;
  }
}