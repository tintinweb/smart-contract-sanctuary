/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// CAESIUMLAB smart Contract 

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;



interface IERC721Receiver {
   
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


library Address {
   
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

  
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
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

        // if (value == 0) {
        //     return "0";
        // }
        // uint256 temp = value;
        // uint256 digits;
        // while (temp != 0) {
        //     digits++;
        //     temp /= 10;
        // }
        // bytes memory buffer = new bytes(digits);
        // while (value != 0) {
        //     digits -= 1;
        //     buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        //     value /= 10;
        // }
        // return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        // if (value == 0) {
        //     return "0x00";
        // }
        // uint256 temp = value;
        // uint256 length = 0;
        // while (temp != 0) {
        //     length++;
        //     temp >>= 8;
        // }
        // return toHexString(value, length);
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
interface IERC721Metadata {

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
    mapping (uint256 => address) public _tokenApprovals;

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


interface IERC721Enumerable {

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


abstract contract ERC721Full is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
        require(index < ERC721Full.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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

    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

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



contract ImageContract is IERC721Metadata, ERC721Full{

address admin;  
uint TokenID = 0;
address  contract_owner = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
uint service;
uint total_p;
struct metadata {
string Artwork_name;
string Artwork_type;
address Author;//changed

string Artwork_description;
string Artwork_url_image;
uint Artwork_price;
uint Auction_Length;
uint Royalty;


}

 struct Vendor{
    uint nftCount; 
    uint withdrawnBalance;
    uint userWeiBalance;
 
    }
 mapping (address => Vendor) Vendors;   
 enum TokenState {Sold, Available}
 struct NFT {
        uint256 price;
        uint256 _tokenId;
        string  tokenURL;
        TokenState tokenState;
        uint bidcount;
         bool doesExist;
        
    }
    
string[] public images;
mapping(uint => metadata) public imageData;
mapping(string => bool) _imageExists;

mapping(uint => bool) _listedForAuction;
mapping(uint => bool) _listedForSale;
mapping(uint => address) _tokenToOwner;
mapping (uint => NFT) NFTs;
struct auctionData {
uint Artwork_price;
uint time;
}

mapping(uint => auctionData) tokenAuction;

event BoughtNFT(uint256 _tokenId, address _buyer, uint256 _price);


 NFT[] allNFT;
     
constructor() ERC721("CAESIUMLAB", "CSM") { admin = payable( msg.sender);}

 
function MintFixedNFT(string memory _Artwork_name, string memory _Artwork_description, string memory _Artwork_url_image, uint _Artwork_price,uint _Royalty) public payable returns (uint){
require(!_imageExists[_Artwork_url_image]);
metadata memory md;
md.Artwork_name = _Artwork_name;

md.Artwork_description = _Artwork_description;
md.Artwork_url_image = _Artwork_url_image;
md.Artwork_price = _Artwork_price;
//md.Auction_Length = _Auction_Length;
md.Royalty= _Royalty;
images.push(_Artwork_url_image);
TokenID =  TokenID  +1;
md.Author = msg.sender;

imageData[ TokenID ] = md;
_mint(msg.sender,TokenID);
_tokenToOwner[TokenID] = msg.sender;
_imageExists[_Artwork_url_image] = true;
payable(contract_owner).transfer(msg.value); 
NFTs[TokenID] = NFT(_Artwork_price, TokenID,_Artwork_url_image, TokenState.Available,0,true);
return  TokenID;
}

function mintAuctionLength(string memory _Artwork_name, string memory _Artwork_description, string memory _Artwork_url_image, uint _Artwork_price, uint _Auction_Length,uint _Royalty) public payable returns (string memory,uint,uint){
require(!_imageExists[_Artwork_url_image]);
metadata memory md;
md.Artwork_name = _Artwork_name;
md.Artwork_description = _Artwork_description;
md.Artwork_url_image = _Artwork_url_image;
md.Artwork_price = _Artwork_price;
md.Auction_Length = _Auction_Length;
md.Royalty= _Royalty;
images.push(_Artwork_url_image);
 TokenID  =  TokenID +1;
md.Author = msg.sender;

imageData[ TokenID ] = md;
_mint(msg.sender,TokenID);
_tokenToOwner[TokenID] = msg.sender;
_imageExists[_Artwork_url_image] = true;

uint VendorNumberofNFT =  Vendors[msg.sender].nftCount++; 
      NFT memory allNFTs = NFT(_Artwork_price,TokenID,_Artwork_url_image, TokenState.Available, 0,true);
      NFTs[TokenID] = NFT(_Artwork_price, TokenID,_Artwork_url_image, TokenState.Available,0,true);
      allNFT.push(allNFTs);
      payable(contract_owner).transfer(msg.value); 

      return (' Auction NFT MINT sucessfully',TokenID, VendorNumberofNFT);

}


 
function nftSold(uint _tokenId) public {
    _listedForSale[_tokenId] = false;
    _listedForAuction[_tokenId] = false;
  }
  
function approvethis(address add,uint256 _tokenId) public {
      _tokenApprovals[_tokenId] = add;
  }

  function BuyNFT(address _owner, uint256 _tokenId, uint256 _price) public payable returns(string memory,uint256) {
        require(msg.sender != admin,'Token owner cannot buy');
        _price = imageData[_tokenId].Artwork_price;
        uint256 royalty;
        if(_owner==imageData[_tokenId].Author){
            royalty = 0;
            // require(msg.value==_price, "You need to send the correct amount.");
            // approvethis(msg.sender,_tokenId);
            // transferFrom(_owner, msg.sender, _tokenId);
            // nftSold(_tokenId);
            // emit BoughtNFT(_tokenId, msg.sender, _price);
            // payable(_owner).transfer(msg.value); 
            // _tokenToOwner[_tokenId] = msg.sender;
            // return('You have sucessfully Buy this NFT',_tokenId);
        }
        else{
            royalty = _price*imageData[_tokenId].Royalty/100;
                         
        }
        service = msg.value -(_price+royalty);
        total_p = msg.value - service;
        require(total_p==_price+royalty, "You need to send the correct amount.");
        approvethis(msg.sender,_tokenId);
        transferFrom(_owner, msg.sender, _tokenId);
        nftSold(_tokenId);
        emit BoughtNFT(_tokenId, msg.sender, _price);
        payable(_owner).transfer(_price); 
        if(royalty>0){
        payable(imageData[_tokenId].Author).transfer(royalty); 
        }
        _tokenToOwner[_tokenId] = msg.sender;
        payable(contract_owner).transfer(service); 
        return('You have sucessfully Buy this NFT',_tokenId);
        
    }

}

contract NFtMarket  is ImageContract {
    
   // address payable admin;
   //  enum TokenState {Sold, Available}
     
   
  //    mapping (uint => NFT) NFTs;
      mapping(address => mapping(uint => bool)) hasBibedFor;
      mapping (address => uint) bidPrice;
      mapping (uint => mapping (address => bider)) biderToId;
      mapping (uint => uint) BidAmountToTokenId;
 //     mapping (address => Vendor) Vendors;
      
       
       
    
  /*  constructor () ERC721('OlaNFT', 'OLANFT')  {
        admin = payable( msg.sender); 
    }
    */
   // uint TokenID = 0;
    uint bidcount = 0;
    uint BidAmount = 0;
    
    uint HighestBiderPrice = 0;
    address public HighestBiderAddress ;
    
   
  /*   
    struct Vendor{
    uint nftCount; 
    uint withdrawnBalance;
    uint userWeiBalance;
 
    }
    
    struct NFT {
        uint256 price;
        uint256 _tokenId;
        string  tokenURL;
        TokenState tokenState;
        uint bidcount;
         bool doesExist;
        
    }
    
    */
    
    struct bider {
        address biderAdress;
        uint bidPrice;
        bool canPay;
    }
    

     
//  NFT[] allNFT;
 
    function bid (uint _tokenId, uint _bidAmount) public payable returns (string memory, uint, uint) {
       require(msg.sender != admin,'Token Owner cannot bid');
       require(NFTs[_tokenId].doesExist == true, 'Token id does not exist'); 
       require (hasBibedFor[msg.sender][_tokenId] == false, 'you cannot bid for an Nft twice');
       require (BidAmountToTokenId[_tokenId] < _bidAmount, 'this Nft already has an higher or equal bider');
       require (NFTs[_tokenId].price <= _bidAmount, 'You cannot bid below the startingPrice');
       uint TotalBid = NFTs[_tokenId].bidcount++;
      
        bidPrice[msg.sender] = _bidAmount;
        uint bidAmount = bidPrice[msg.sender];
         hasBibedFor[msg.sender][_tokenId]= true;
        biderToId[_tokenId][msg.sender]= bider(msg.sender,_bidAmount, true);
        if (BidAmountToTokenId[_tokenId] < _bidAmount ){
            BidAmountToTokenId[_tokenId] = _bidAmount;
        }
        payable(contract_owner).transfer(msg.value); 
        return('You have sucessfully bided for this NFT', bidAmount, TotalBid);
        
    }
    
    function CheckhighestBidDEtails (uint _id) public  returns(uint, address) {
    require(NFTs[_id].doesExist == true, 'Token id does not exist');
        HighestBiderPrice = BidAmountToTokenId[_id];
        if ( biderToId[_id][msg.sender].bidPrice == HighestBiderPrice){
            HighestBiderAddress = biderToId[_id][msg.sender].biderAdress;
        }  
        else{
        
         return(HighestBiderPrice,HighestBiderAddress);

        }
        
        
      return(HighestBiderPrice,HighestBiderAddress);
       
    }
    
    
    function BuyBidNFT (uint _tokenId) public payable returns(string memory)  {
       require(NFTs[_tokenId].doesExist == true, 'Token id does not exist');
      // require(msg.value == _amount, "DepositEther:Amount sent does not equal amount entered");
       require (msg.sender == HighestBiderAddress, 'only highest bidder can pay' );
      // require (msg.value == HighestBiderPrice, 'amount is less than higest bid price');
     //   Vendors[msg.sender].userWeiBalance += _amount;
     uint256 royalty;
     if(ownerOf(_tokenId)==imageData[_tokenId].Author){
         royalty = 0;

         
        // address nftOwner = ownerOf(_tokenId);
        // console.log("nftOwner",nftOwner);
        // address buyer = msg.sender; 
        //  console.log("buyer",buyer);
        // transferFrom(nftOwner, buyer, _tokenId);
        // nftSold(_tokenId);
        // emit BoughtNFT(_tokenId, buyer, HighestBiderPrice);

        // require(msg.value==HighestBiderPrice, "You need to send the correct amount.");

        // payable(nftOwner).transfer(msg.value); 
        //  _tokenToOwner[_tokenId] = msg.sender;

        // return('Bid NFT Buy sucessfully ');
        //safeTransferFrom(nftOwner, buyer, _tokenId);
        // payable(address(this)).transfer(msg.value); 
      //    uint VendorNumberofNFT =  Vendors[msg.sender].nftCount--; 
     //   return(VendorNumberofNFT);
     }
     else{royalty = HighestBiderPrice*imageData[_tokenId].Royalty/100;}
        address nftOwner = ownerOf(_tokenId);
        address buyer = msg.sender; 
        approvethis(msg.sender,_tokenId);

        transferFrom(nftOwner, buyer, _tokenId);
        nftSold(_tokenId);
        emit BoughtNFT(_tokenId, buyer, HighestBiderPrice);
        require(msg.value==HighestBiderPrice+royalty, "You need to send the correct amount.");

        payable(nftOwner).transfer(HighestBiderPrice); 
        if(royalty>0){payable(imageData[_tokenId].Author).transfer(royalty);}
        _tokenToOwner[_tokenId] = msg.sender;
        HighestBiderPrice = 0;
        BidAmountToTokenId[_tokenId] = 0;
        return('Bid NFT Buy sucessfully ');
       
     
    }
    
    //   function contractEtherBalance() public view returns(uint256){
    //     return address(this).balance;
    // }

     
//  function getBalance() public view returns(uint){
//      return address(this).balance;
//  }
 
    function resellNFT(uint256 _token, uint256 _newPrice, string memory _newName,string memory _Artwork_type)public payable returns(string memory,uint) {//changed
        address _owner = _tokenToOwner[_token];
        require(msg.sender==_owner, "You are not the owner so you cannot resell this.");
        // NFTs[_token]=NFT(_newPrice, nft._tokenId,nft.tokenURL, nft.tokenState, nft.bidcount,  nft.doesExist );
        _listedForSale[_token] = true;
        NFTs[_token].price = _newPrice;
        imageData[_token].Artwork_price=_newPrice;
        imageData[_token].Artwork_name = _newName;
        imageData[_token].Artwork_type = _Artwork_type;
        payable(contract_owner).transfer(msg.value); //for Service Fees Trasnsfer to Contract Owner 
        return('Resell Fixed Price NFT  sucessfully ',_token);
    }


function resellAuctionNFT(uint256 _token, string memory _newName,uint256 _newPrice, uint _Auction_Length)public payable returns(string memory,uint) {//changed
        address _owner = _tokenToOwner[_token];
        require(msg.sender==_owner, "You are not the owner so you cannot resell this.");
        // NFTs[_token]=NFT(_newPrice, nft._tokenId,nft.tokenURL, nft.tokenState, nft.bidcount,  nft.doesExist );
        _listedForSale[_token] = true;
        NFTs[_token].price = _newPrice;
        imageData[_token].Artwork_price=_newPrice;
        imageData[_token].Artwork_name = _newName;
        imageData[_token].Auction_Length = _Auction_Length;
        payable(contract_owner).transfer(msg.value); 

 
        return('Resell Auction Length Price NFT  sucessfully ',_token);
    }


// function getFixedRoyalty(uint256 _token) view public returns(uint256) {
//         return (imageData[_token].Artwork_price*imageData[_token].Royalty)/100;
//     }
//     function getAuctionRoyalty(uint256 _token, uint256 _highestBidPrice) view public returns(uint256) {
//         return (_highestBidPrice*imageData[_token].Royalty)/100;
//     }
    
}