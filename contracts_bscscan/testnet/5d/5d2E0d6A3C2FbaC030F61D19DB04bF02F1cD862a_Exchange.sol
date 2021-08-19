/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

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

interface IMozikERC721Token is IERC721Enumerable {
   

    function getBaseTokenURI() external view returns (string memory); 

    function setBaseTokenURI(string memory url) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function isMozikNftToken(address tokenAddress) external view returns(bool);

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

}


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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
     /*
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title Authentication 授权合约
 * Authentication - 用于控制市场/交易所的商品操作权限
 * @dev https://www.mozik.cc
 * @author duncanwang
 */
contract Authentication is Ownable {
    address private _owner;//合约拥有者
    mapping(address=>bool) _managers;//管理员

    /**
    * @dev constructor ： 构建函数
    */
    constructor() {    
        _owner = msg.sender;
    }

    /**
     * @dev onlyAuthorized 是否已授权？
       权限控制：修饰符
    * @param target 期望判断的目标地址;         
     */
    modifier onlyAuthorized(address target) {
        require(isOwner()||isManager(target),"Only for manager or owner!");
        _;
    }    

    /**
    * @dev addManager -增加管理员。不做判断，允许重复设置；
      权限控制：只有owner可以增加管理员；
    * @param manager 期望设置的地址;    
    */
    function addManager(address manager) public onlyOwner{    
        _managers[manager] = true;
    }    

    /**
    * @dev removeManager -删除管理员。不做判断，允许重复设置；
      权限控制：只有owner可以剔除管理员；
    * @param manager 期望设置的地址;        
    */
    function removeManager(address manager) public onlyOwner{    
        _managers[manager] = false;
    }  

    /**
    * @dev isManager - 判断是否是管理员；
      权限控制：任何人都可以访问； 
    */
    function isManager(address manager) public view returns (bool) {    
        return(_managers[manager]);
    }             

}    

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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


enum TokenType {ETH, ERC20}

/**
 * @title Good 平台合约
 * Goods - contract which treat NFT for sale.
 * @dev https://www.mozik.cc
 * @author duncanwang
 */
contract Goods is Ownable {
    using Strings for string;
    using Address for address;    
    using SafeMath for *;
   
    string constant public _name = "GOODS contract as ERC721 NFT for sale with version 1.0";

    /* 商品属性 */
    address private _nftContractAddress;
    uint256 public _tokenID;
    TokenType public _expectedTokenType;
    address payable public _sellerAddress;
    address private _expectedTokenAddress;
    uint256 public _expectedValue;
    uint private _startTime;
    bool private _isForSale = false;

    /* 处理函数 */
    /**
    * @dev constructor ： 构建函数
    * @param ContractAddress TOKEN address treated as goods.
    */
    constructor(address ContractAddress) {
        //require an contract address
        require(true == Address.isContract(ContractAddress), "ContractAddress is not a contract address!");

        //set _nftContractAddress if the address is a ERC721 token address.
        if(IERC721(ContractAddress).supportsInterface(0x80ac58cd))
        {
            _nftContractAddress = ContractAddress;
        }
        else
        {
            revert();
        }
        
    }  

/**
    * @dev getGoodsInfo : 获取商品信息
    * @return _nftContractAddress 对应的NFT的合约地址
    * @return _tokenID  对应的NFT的TOKENID
    * @return _expectedTokenType 对应售出获得的TOKEN是ETH还是其他类型的TOKEN： ERC20或者ERC721；
    * @return _sellerAddress 商品销售者地址
    * @return _expectedTokenAddress 期待售出获得的TOKEN合约地址
    * @return _expectedValue 期待售出获得的TOKEN数量
    * @return _startTime 开始销售的时间；
    * @return _isForSale 当前商品是否是待售状态；
    */
    function getGoodsInfo() external view returns (address, uint256, TokenType,address,address,uint256,uint,bool) {  
        //返回商品所有信息        
        return (_nftContractAddress,_tokenID,_expectedTokenType,_sellerAddress,_expectedTokenAddress,_expectedValue,_startTime,_isForSale);
    }  

/**
    * @dev onSale : 设置商品销售属性 
    * 权限控制：goods合约的创建者才能设置商品属性；
    * @param saleTokenID 对应的销售NFT的token ID;
    * @param sellerAddress 销售者账号；
    * @param expectedTokenType 期望获得的TOKEN是ETH还是ERC20 ,ERC721TOKEN；
    * @param tokenAddress 如果期望获得的TOKEN不是ETH，则此处为期望的TOKEN合约地址
    * @param value 期待售出获得的TOKEN数量
    * @param startTime 开始销售的时间；
    * @return bool 设置商品状态为成功还是失败；
    */
    function onSale(uint256 saleTokenID,address payable sellerAddress,TokenType expectedTokenType, address tokenAddress, uint256 value, uint256 startTime) external onlyOwner returns (bool) {  
        /*1. 该商品处于销售状态，或者销售账户地址为0，则不能设置销售参数 */
        //上架了_isForSale必定为true，这样控制无法修改上架的商品属性
        /*
        if(_isForSale|| sellerAddress == address(0) )
        {
            return false;
        }
        改为：
        */
        if(sellerAddress == address(0))
        {
            return false;
        }
        /*2.销售者不是该NFT商品的拥有者，授权者，超级授权者，则返回失败*/
        if(!isApprovedOrOwner(sellerAddress,saleTokenID )) 
        {
            return false;
        }   

        /*3.当销售类型不为ETH时，tokenAddress必须是一个合约地址;
            此时adress(0)也是非法的，不是合约地址，不做单独判断；*/
        if((expectedTokenType != TokenType.ETH) && (!Address.isContract(tokenAddress)) )
        {
             return false;
        }

        //4.检查startTime值小于当前区块的时间，则返回失败；
        /*2021.8.18 这个限制去掉。
        if(startTime < block.timestamp)
        {
             return false;
        }
        */
        //5.商品赋值
        _tokenID = saleTokenID;
        _expectedTokenType = expectedTokenType;
        _sellerAddress = sellerAddress;
        _expectedTokenAddress = tokenAddress;
        _expectedValue = value;
        _startTime = startTime;
        _isForSale = true;        

        //6.返回成功
        return true;
    }  

/**
    * @dev offSale : 商品下架，设置该商品的属性为无效值
    * 权限控制：goods合约的创建者才能设置下架；
    */
    function offSale() external onlyOwner{ 
        _tokenID = 0;
        _expectedTokenType = TokenType.ETH;
        _sellerAddress = payable(address(0));
        _expectedTokenAddress = address(0);
        _expectedValue = 0;
        _startTime = 0;        
        _isForSale = false;
    }  

    /**
     * @dev _isApprovedOrOwner ：判断该地址是否是该NFT商品的拥有者，授权者，超级授权者
     *
     * @param seller 销售者地址
     * @param tokenId 销售者想出售的tokenId       
     * Requirements:
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address seller, uint256 tokenId) public view returns (bool) {
        //如果tokenId不存在，则异常返回，赋值不会成功；
        address owner = IERC721(_nftContractAddress).ownerOf(tokenId);

       /*如果销售者是该tokenID的拥有者，授权者或者超级授权者(不同于单个授权)
            为了兼容所有的ERC721 TOKEN，只能使用IERC721的接口函数来判断。*/   
        return (seller == owner || IERC721(_nftContractAddress).getApproved(tokenId) == seller || IERC721(_nftContractAddress).isApprovedForAll(owner, seller));
    }

    /**
     * @dev isOnSale: 从时间，状态等判断该商品是否处于销售状态
       权限：公开，任意人都可以访问
     * @return bool true or false;
     */
    function isOnSale() public view returns(bool) {
        return(_isForSale && (block.timestamp >= _startTime));
    }
}


/**
 * @title Exchange 交易合约
 * Exchange - 该合约用于处理mozik nft的交易，换取目标为MOZIK ERC20和ETH
 * @dev https://www.mozik.cc
 * @author duncanwang
 */
contract Exchange is Authentication {
    using Strings for string;
    using Address for address;    
    using SafeMath for *;

    string constant public _name = "Exchange contract as ERC721 NFT exchange with ETH or mozik ERC20 version 1.1";    
    
    struct NftPair {
        address nftContractaddr;
        uint256 tokenID;
        bool isUsed;
    }
    mapping(bytes32 => NftPair) private _saleGoodsSource;
    mapping(bytes32 => address) private _saleGoodsAddr;//nft pair对应的商品合约地址
    //mapping(uint256 => address) private _saleGoodsAddr;//token ID对应的商品合约地址
    address private _mozikNftAddress;//MOZIK NFT智能合约
    address private _mozikErc20Address;//MOZIK ERC20智能合约

    /* 处理函数 */
    /**
    * @dev constructor ： 构建函数
      权限：管理账户创建者
    * @param mozikNftAddress mozik ERC721 NFT token.
    * @param mozikErc20Address mozik ERC20 FT token.
    */
    constructor(address mozikNftAddress, address mozikErc20Address) {
        //这2个地址必须是合约地址
        require(Address.isContract(mozikNftAddress), "the first parameter should be MozikERC721Token address!" );     
        require(Address.isContract(mozikErc20Address), "the second parameter should be mozik ERC20 address!" );     

        //判断该合约地址是否是mozik ERC721 NFT token地址
        require(IMozikERC721Token(mozikNftAddress).isMozikNftToken(mozikNftAddress), "the first parameter should be MozikERC721Token address!");

        //记录合约地址
        _mozikNftAddress = mozikNftAddress;
        
        //固定交换合约对应的ERC20的地址，防止被人使用无价值token套利.
        _mozikErc20Address = mozikErc20Address;
        
    }  

    function keyByNFTPair(address nftContractaddr,uint256 tokenID) internal pure
             returns (bytes32 result) 
     {  
        result =  keccak256(abi.encodePacked(nftContractaddr, tokenID));
     }  

    function _existGoods(address nftContractaddr,uint256 tokenID) internal view
            returns(bool) {
        bytes32 key = keyByNFTPair(nftContractaddr,tokenID);
        return _saleGoodsSource[key].isUsed;
    }
    
    /**
     * @dev isOnSale: 判断某个tokenId是否作为商品在销售
       权限：公开，任意人都可以访问
     * @param tokenID 需要查询的token id, 其对应的goods中的_tokenID在exchange市场具有唯一性。
     */
    function isOnSale(address nftContractaddr,uint256 tokenID) public view returns(bool) {
        bytes32 key = keyByNFTPair(nftContractaddr,tokenID);
        address goodsAddress = _saleGoodsAddr[key];

        //包括该商品的isForSale是true,当前时间大于销售开始时间
        if( address(0) != goodsAddress && Goods(goodsAddress).isOnSale() )
        {
            return true;
        }

        //其他情况下均返回false
        return false;

    }   

    /**
     * @dev getSaleGoodsInfo: 返回销售列表中的某一个商品信息；
       权限：公开，任意人都可以访问
     * @param tokenID 要查询的tokenID
     */
    function getSaleGoodsInfo(address nftContractaddr,uint256 tokenID) external view 
    returns (address nftContractAddress, uint256 tokenid, TokenType expectedTokenType,address sellerAddress,address expectedTokenAddress,uint256 expectedValue,uint startTime,bool isForSale) {
        bytes32 key = keyByNFTPair(nftContractaddr,tokenID);
        address goodsAddress = _saleGoodsAddr[key];

        //商品地址不可能是0地址；
        require(address(0) != goodsAddress, "It's not an invalid goods.");

        return( Goods(goodsAddress).getGoodsInfo() );


    }    

   /**
     * @dev hasRightToSale: 判断账户是否有销售该token id的权限；
       权限：公开，任意人都可以访问
     * @param targetAddr : address,需要判断的账号地址；
     * @param tokenId : uint256, NFT tokenId；该token Id必须存在，否则失败回滚；
     * @return bool: 返回结果 true/false;
     */
    function hasRightToSale(address nftContractaddr,address targetAddr, uint256 tokenId) public view returns(bool) {
  
        //该函数不会返回异常回退
       /*判断如果销售者是该tokenID的拥有者，授权者或者超级授权者(不同于单个授权)
            为了兼容所有的ERC721 TOKEN，只能使用IERC721的接口函数来判断。*/   
        return (IMozikERC721Token(nftContractaddr).isApprovedOrOwner(targetAddr, tokenId));
    }

/**
     * @dev IsTokenOwner: 判断账户是否是该token id的拥有者；
       权限：公开，任意人都可以访问
     * @param targetAddr : address,需要判断的账号地址；
     * @param tokenId : uint256, NFT tokenId；该token Id必须存在，否则失败回滚；
     * @return bool: 返回结果 true/false;
     */
    function IsTokenOwner(address nftContractaddr,address targetAddr, uint256 tokenId) public view returns(bool) {
        //如果tokenId不存在则返回失败
        if(!IMozikERC721Token(nftContractaddr).exists(tokenId))
        {
            return false;
        }
        
        /* 确认目标地址是不是该token的owner*/   
        return (targetAddr == IMozikERC721Token(nftContractaddr).ownerOf(tokenId) );
    }

   /**
     * @dev hasEnoughTokenToBuy: 判断账户是否有足够的token来购买NFT；
       权限：公开，任意人都可以访问
     * @param buyer : address, 购买账户,不可以是0x0的地址；
     * @param tokenId : uint256, NFT tokenId；该token Id必须存在，否则失败回滚；
     * @return bool: 返回结果 true/false;
     */
    function hasEnoughTokenToBuy(address nftContractaddr,address buyer, uint256 tokenId) public view returns(bool) {
        
        /* 地址为0，或者token id不存在则直接返回false */
        if( (address(0) == buyer) || (!IMozikERC721Token(nftContractaddr).exists(tokenId)) )
        {
            return false;
        }

        /* 该tokenid属于销售商品；不判断是否处于销售中，这个由外部函数判断 */
        bytes32 key = keyByNFTPair(nftContractaddr,tokenId);
        address goodsAddress = _saleGoodsAddr[key];
        /* 如果商品地址为0，那也是异常的*/
        if(address(0) == goodsAddress)
        {
            return false;
        }
        
        /* 卖家期望收获的是ETH */
        if(TokenType.ETH ==  Goods(goodsAddress)._expectedTokenType() )
        {
            buyer.balance >= Goods(goodsAddress)._expectedValue();
            return true;
        }
        /* 卖家期望收获的是ERC20的TOKEN */
        else if(TokenType.ERC20 ==  Goods(goodsAddress)._expectedTokenType() )
        {
                IERC20(_mozikErc20Address).balanceOf(buyer) >= Goods(goodsAddress)._expectedValue();
                return true;
        }
        else
        {
            //其他都返回失败
            return false;
        }           
  
    }

    /**
    * @dev sellNFT: NFT拥有者发起销售设置；
       权限：TOKEN 拥有者才能发起销售
       前置条件：该NFT TOKEN拥有者需要把该TOKEN ID授权给EXCHANGE地址
    * @param saleTokenID 对应的销售NFT的token ID;
    * @param expectedTokenType 期望获得的TOKEN是ETH还是ERC20 ,ERC721TOKEN；
    * @param tokenAddress 如果期望获得的TOKEN不是ETH，则此处为期望的TOKEN合约地址
    * @param value 期待售出获得的TOKEN数量
    * @param startTime 开始销售的时间；
     */
    function sellNFT(address nftContractAddr,uint256 saleTokenID, TokenType expectedTokenType, address tokenAddress, uint256 value, uint256 startTime) external {
        Goods goods;
        bool result;


        /* 发送者必须是一个外部账户，不是合约地址；本版本先做限定，防止攻击 */
        require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");

        /* 目前限定销售者必须是token id的owner，同时表明该saleTokenID存在*/
        require(IsTokenOwner(nftContractAddr,msg.sender, saleTokenID),"the sender isn't the owner of the token id nft!");

        /* expectedTokenType为有效值 */
        require((expectedTokenType == TokenType.ETH) || (expectedTokenType == TokenType.ERC20),
                "expectedTokenType must be ETH or ERC20 in this version!");

        /* tokenAddress为mozik ERC20的地址 */
        if(expectedTokenType == TokenType.ERC20)
        {
            require((tokenAddress == _mozikErc20Address), "the expected token must be mozik ERC20 token.");
        }
        
        /* startTime是否大于等于区块时间 */
        /*2021.8.18 如果提交上架时间早于块当前时间，以块上时间作为上架时间。
        require((startTime >= block.timestamp), "startTime for sale must be bigger than now.");
        */
        if(startTime < block.timestamp)
        {
            startTime = block.timestamp;
        }
        /*要不要考虑当前是否在销售状态？？？ */
        
        /*在上架前先显式的做一下授权操作 */
        IERC721(nftContractAddr).approve(address(this), saleTokenID);
        /*该NFT TOKEN拥有者需要提前把该TOKEN ID授权给EXCHANGE地址，否者购买者会购买不成功的。
          为了备忘，提前确认当前合约是该NFT的授权者*/
        require(hasRightToSale(nftContractAddr,address(this), saleTokenID),"the exchange contracct is not the approved of the TOKEN.");

        bytes32 key = keyByNFTPair(nftContractAddr,saleTokenID);
        /* 判断token id是更新参数还是新建商品，然后调用GOODS销售设定 */
        /* 更新已有商品：对应的address值有效 */
        if( address(0) != _saleGoodsAddr[key] )
        {
            //确认下，这儿是引用还是COPY呢？引用
            goods = Goods(_saleGoodsAddr[key] );
            result = goods.onSale(saleTokenID,payable(msg.sender),expectedTokenType, tokenAddress, value, startTime);
            require(result, "reset goods on sale is failed.");
        }
        else
        {
            /* 创建商品并设置商品属性 */
            goods = new Goods(nftContractAddr);
            result = goods.onSale(saleTokenID, payable(msg.sender), expectedTokenType, tokenAddress, value, startTime);
            require(result, "set goods on sale is failed.");

            //更新商品地址            
            _saleGoodsAddr[key] = address(goods);
            _saleGoodsSource[key] = NftPair(nftContractAddr,saleTokenID,true);
            /* 设置当前合约Exchange为授权者,便于在购买时可以发起转移 */
            //IMozikERC721Token(_mozikNftAddress).approve(address(this),saleTokenID);
        }
    }    

    /**
    * @dev cancelSell: 取消销售货品
       权限：管理员和合约的owner才有此权限；
            销售者可以跟管理方协商后处理，无法擅自取消销售。
            这里是不是要改成销售者有权做下架呢？？？
    * @param tokenID uint256;
    */
    /*
    function cancelSell(address nftContractAddr,uint256 tokenID) external onlyAuthorized(msg.sender){
        //不管销售状态，只要销售列表中有就删除掉。
        bytes32 key = keyByNFTPair(nftContractAddr,tokenID);
        _saleGoodsAddr[key] = address(0);
        _saleGoodsSource[key].isUsed = false;
        //不触发Goods智能合约销毁接口了，要费GAS，没有什么价值；
        //ERC721没有取消授权的接口，也不取消授权了。
    }    
    */
    function cancelSell(address nftContractAddr,uint256 tokenID) external {
        /* 发送者必须是一个外部账户，不是合约地址；本版本先做限定，防止攻击 */
        require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");

        /* 目前限定销售者必须是token id的owner，同时表明该saleTokenID存在*/
        require(IsTokenOwner(nftContractAddr,msg.sender, tokenID),"the sender isn't the owner of the token id nft!");

        //不管销售状态，只要销售列表中有就删除掉。
        bytes32 key = keyByNFTPair(nftContractAddr,tokenID);
        _saleGoodsAddr[key] = address(0);
        _saleGoodsSource[key].isUsed = false;
        //不触发Goods智能合约销毁接口了，要费GAS，没有什么价值；
        //ERC721没有取消授权的接口，也不取消授权了。
    } 
    /**
    * @dev buyNFT: 购买处于销售状态的NFT TOKEN
       权限：
       前置条件：如果是使用ERC20 MOZIK购买，需要把等额的TOKEN授权给exchange合约
    * @param tokenID 想购买的tokenID;
    */
    function buyNFT(address nftContractAddr,uint256 tokenID) payable external {
        //判断该tokenId是否处于销售中，包含该token id是否存在  
        require(isOnSale(nftContractAddr,tokenID),"The nft token(tokenID) is not on sale.");

        //当前合约是该NFT的授权者
        require(hasRightToSale(nftContractAddr,address(this), tokenID),"the exchange contracct is not the approved of the TOKEN.");

        //当前发起者是否有足够的余额购买
        require(hasEnoughTokenToBuy(nftContractAddr,msg.sender, tokenID), "No enough token to buy the NFT(tokenID)");
        
        //tokenid必须处于销售列表中,index必须是有效值
        bytes32 key = keyByNFTPair(nftContractAddr,tokenID);
        address goodsAddress = _saleGoodsAddr[key];
        //商品地址不可能是0地址；
        require(address(0) != goodsAddress, "The token ID isn't on sale status!");

        //不要出现同账号买卖现象，链上交易都费钱。想测试还请换个不同账号吧。
        require(msg.sender != Goods(goodsAddress)._sellerAddress(), "the buyer can't be same to the seller.");

        //转移ERC721给购买者
        IMozikERC721Token(nftContractAddr).safeTransferFrom(Goods(goodsAddress)._sellerAddress(), msg.sender, tokenID);

        //根据期望的token类型做转账处理
        uint256 amount = Goods(goodsAddress)._expectedValue();

        /* 卖家期望收获的是ETH */
        if(TokenType.ETH ==  Goods(goodsAddress)._expectedTokenType() )
        {
            //转期望目标值的ETH
            Goods(goodsAddress)._sellerAddress().transfer(amount);
        }
        /* 卖家期望收获的是ERC20的TOKEN */
        else if(TokenType.ERC20 ==  Goods(goodsAddress)._expectedTokenType() )
        {
            //如果是使用ERC20 MOZIK购买，需要在调用该函数之前把等额的TOKEN授权给exchange合约
            require(IERC20(_mozikErc20Address).allowance(msg.sender, address(this)) >= amount, 
                    "the approved MOZ ERC20 tokens to the contract address should greater than the _expectedValue." );
                                
            IERC20(_mozikErc20Address).transferFrom(msg.sender, Goods(goodsAddress)._sellerAddress(), amount);
        }

        //移除商品.需要再次销售的话，拥有者要重新sellNFTkey
        _saleGoodsAddr[key] = address(0x0);
    }   

    /**
    * @dev getTokenAddress: 查看配置的2个合约地址
        权限：任何人都可查看
    * @return mozikNftAddress mozik ERC721 NFT token.
    * @return mozikErc20Address mozik ERC20 FT token.
    */
    function getTokenAddress() external view returns (address, address){
        //return(_mozikNftAddress, _mozikErc20Address);
        return(_mozikNftAddress, _mozikErc20Address);
    }    

    /**
    * @dev destroyContract: 销毁合约。通过该函数可以把该合约的ETH返回给owner
        权限：任何人都可查看
    */
    function destroyContract() external onlyOwner {
        //该合约如果持有的MOZIK ERC20全部转给owner;
        uint256 amount = IERC20(_mozikErc20Address).balanceOf(address(this));
        IERC20(_mozikErc20Address).transfer(owner(), amount);

        //该合约如果持有的MOZIK ERC721全部转给owner
        //一般不会发送。如果要实现该功能，需要改造MoizikERC721Token多，暂不动。
            
        //该合约如果持有的ETH全部转给owner
        selfdestruct(payable(owner()));
    } 
}