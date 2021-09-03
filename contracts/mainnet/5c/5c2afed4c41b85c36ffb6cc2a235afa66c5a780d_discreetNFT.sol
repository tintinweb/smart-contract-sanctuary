/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


/**
 * @dev Interface for discreet.eth in addition to the standard ERC721 interface.
 */
interface discreetNFTInterface {
    /**
     * @dev Mint token with the supplied tokenId if it is currently available.
     */
    function mint(uint256 tokenId) external;

    /**
     * @dev Mint token with the supplied tokenId if it is currently available to
     * another address.
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * @dev Burn token with the supplied tokenId if it is owned, approved or
     * reclaimable. Tokens become reclaimable after ~4 million blocks without a
     * mint or transfer.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Check the current block number at which a given token will become
     * reclaimable.
     */
    function reclaimableThreshold(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Check whether a given token is currently reclaimable.
     */
    function isReclaimable(uint256 tokenId) external view returns (bool);

    /**
     * @dev Retrieve just the image URI for a given token.
     */
    function tokenImageURI(uint256 tokenId) external view returns (string memory);
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IENSReverseRegistrar {
    function claim(address owner) external returns (bytes32 node);
    function setName(string calldata name) external returns (bytes32 node);
}


/**
 * @dev Implementation of the {IERC165} interface.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    // Token name
    bytes8 private immutable _name;

    // Token symbol
    bytes8 private immutable _symbol;

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
    constructor(bytes8 name_, bytes8 symbol_) {
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
    function name() external view virtual override returns (string memory) {
        return string(abi.encodePacked(_name));
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return string(abi.encodePacked(_symbol));
    }

    /**
     * @dev NOTE: standard functionality overridden.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {}

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
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
    function setApprovalForAll(address operator, bool approved) external virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
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
    ) external virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
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
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
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
        uint256 size;
        assembly { size := extcodesize(to) }
        if (size > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual override returns (uint256) {
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
    function tokenByIndex(uint256 index) external view virtual override returns (uint256) {
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


/**
 * @dev discreet (full set — replaces the 576 orignal and 288 extra NFTs and
 * adds an additional 432 for 1296 in total)
 * @author 0age
 */
contract discreetNFT is discreetNFTInterface, ERC721, ERC721Enumerable, IERC721Receiver {
    // Map tokenIds to block numbers past which they are burnable by any caller.
    mapping(uint256 => uint256) private _reclaimableThreshold;

    // Map transaction submitters to the block number of their last token mint.
    mapping(address => uint256) private _lastTokenMinted;

    discreetNFTInterface public constant originalSet = discreetNFTInterface(
        0x3c77065B584D4Af705B3E38CC35D336b081E4948
    );

    discreetNFTInterface public constant extraSet = discreetNFTInterface(
        0x04C0567cdBB51c3a9B1C907a56A5edA0EdeeBf71
    );

    uint256 public immutable migrationEnds;

    // Fixed base64-encoded SVG fragments used across all images.
    bytes32 private constant h0 = 'data:image/svg+xml;base64,PD94bW';
    bytes32 private constant h1 = 'wgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz';
    bytes32 private constant h2 = '0iVVRGLTgiPz48c3ZnIHZpZXdCb3g9Ij';
    bytes32 private constant h3 = 'AgMCA1MDAgNTAwIiB4bWxucz0iaHR0cD';
    bytes32 private constant h4 = 'ovL3d3dy53My5vcmcvMjAwMC9zdmciIH';
    bytes32 private constant h5 = 'N0eWxlPSJiYWNrZ3JvdW5kLWNvbG9yOi';
    bytes4 private constant m0 = 'iPjx';
    bytes10 private constant m1 = 'BmaWxsPSIj';
    bytes16 private constant f0 = 'IiAvPjwvc3ZnPg==';

    /**
     * @dev Deploy discreet as an ERC721 NFT.
     */
    constructor() ERC721("discreet", "DISCREET") {
        // Set up ENS reverse registrar.
        IENSReverseRegistrar _ensReverseRegistrar = IENSReverseRegistrar(
            0x084b1c3C81545d370f3634392De611CaaBFf8148
        );

        _ensReverseRegistrar.claim(msg.sender);
        _ensReverseRegistrar.setName("discreet.eth");

        migrationEnds = block.number + 21600; // ~3 days
    }

    /**
     * @dev Throttle minting to once a block and reset the reclamation threshold
     * whenever a new token is minted or transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // If minting: ensure it's the only one from this tx origin in the block.
        if (from == address(0)) {
            require(
                block.number > _lastTokenMinted[tx.origin],
                "discreet: cannot mint multiple tokens per block from a single origin"
            );

            _lastTokenMinted[tx.origin] = block.number;
        }

        // If not burning: reset tokenId's reclaimable threshold block number.
        if (to != address(0)) {
            _reclaimableThreshold[tokenId] = block.number + 0x400000;
        }
    }

    /**
     * @dev Wrap an original or extra discreet NFT when transferred to this
     * contract via `safeTransferFrom` during the migration period.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            block.number < migrationEnds,
            "discreet: token migration is complete."
        );

        require(
            msg.sender == address(originalSet) || msg.sender == address(extraSet),
            "discreet: only accepts original or extra set discreet tokens."
        );

        if (msg.sender == address(originalSet)) {
            require(
                tokenId < 0x240,
                "discreet: only accepts original set discreet tokens with metadata"
            );
            _safeMint(from, tokenId);
        } else {
            require(
                tokenId < 0x120,
                "discreet: only accepts extra set discreet tokens with metadata"
            );
            _safeMint(from, tokenId + 0x240);
        }

        return this.onERC721Received.selector;
    }

    /**
     * @dev Mint a given discreet NFT if it is currently available.
     */
    function mint(uint256 tokenId) external override {
        require(
            tokenId < 0x510,
            "discreet: cannot mint out-of-range token"
        );

        if (tokenId < 0x360) {
            require(
                block.number >= migrationEnds,
                "discreet: cannot mint tokens from original or extra set until migration is complete."
            );
        }

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev Mint a given NFT if it is currently available to a given address.
     */
    function mint(address to, uint256 tokenId) external override {
        require(
            tokenId < 0x510,
            "discreet: cannot mint out-of-range token"
        );

        if (tokenId < 0x360) {
            require(
                block.number >= migrationEnds,
                "discreet: cannot mint tokens from original or extra set until migration is complete."
            );
        }

        _safeMint(to, tokenId);
    }

    /**
     * @dev Burn a given discreet NFT if it is owned, approved or reclaimable.
     * Tokens become reclaimable after ~4 million blocks without a transfer.
     */
    function burn(uint256 tokenId) external override {
        require(
            tokenId < 0x510,
            "discreet: cannot burn out-of-range token"
        );

        // Only enforce check if tokenId has not reached reclaimable threshold.
        if (!isReclaimable(tokenId)) {
            require(
                _isApprovedOrOwner(msg.sender, tokenId),
                "discreet: caller is not owner nor approved"
            );
        }

        _burn(tokenId);
    }

    /**
     * @dev Check the current block number at which the given token will become
     * reclaimable.
     */
    function reclaimableThreshold(uint256 tokenId) public view override returns (uint256) {
        require(tokenId < 0x510, "discreet: out-of-range token");

        return _reclaimableThreshold[tokenId];
    }

    /**
     * @dev Check whether a given token is currently reclaimable.
     */
    function isReclaimable(uint256 tokenId) public view override returns (bool) {
        return reclaimableThreshold(tokenId) < block.number;
    }

    /**
     * @dev Derive and return a discreet tokenURI image formatted as a data URI.
     */
    function tokenImageURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < 0x510, "discreet: URI image query for out-of-range token");

        // Nine base64-encoded SVG fragments for background colors.
        bytes9[9] memory c0 = [
            bytes9('MwMDAwMDA'),
            'M2OWZmMzc',
            'NmZjM3Njk',
            'MzNzY5ZmY',
            'NmZmZmOTA',
            'M5MGZmZmY',
            'NmZjkwZmY',
            'NmZmZmZmY',
            'M4MDgwODA'
        ];

        // Eighteen base64-encoded SVG fragments for primary shapes.
        string[18] memory s0 = [
            'yZWN0IHg9IjE1NSIgeT0iNTUiIHdpZHRoPSIxOTAiIGhlaWdodD0iMzkwIi',
            'yZWN0IHg9IjU1IiB5PSIxNTUiIHdpZHRoPSIzOTAiIGhlaWdodD0iMTkwIi',
            'yZWN0IHg9IjExNSIgeT0iMTE1IiB3aWR0aD0iMjcwIiBoZWlnaHQ9IjI3MCIgIC',
            'jaXJjbGUgY3g9IjI1MCIgY3k9IjI1MCIgcj0iMTY1Ii',
            'lbGxpcHNlIGN4PSIyNTAiIGN5PSIyNTAiIHJ4PSIxMjUiIHJ5PSIxOTUiIC',
            'lbGxpcHNlIGN4PSIyNTAiIGN5PSIyNTAiIHJ4PSIxOTUiIHJ5PSIxMjUiIC',
            'wb2x5Z29uIHBvaW50cz0iMTAwLDEzNSAyNTAsNDAwIDQwMCwxMzUiIC',
            'wb2x5Z29uIHBvaW50cz0iNDAwLDM2NSAyNTAsMTAwIDEwMCwzNjUiIC',
            'wb2x5Z29uIHBvaW50cz0iNDAwLDEwMCA0MDAsNDAwIDEwMCw0MDAiIC',
            'wb2x5Z29uIHBvaW50cz0iMTAwLDQwMCA0MDAsNDAwIDEwMCwxMDAiIC',
            'wb2x5Z29uIHBvaW50cz0iMTAwLDQwMCA0MDAsMTAwIDEwMCwxMDAiIC',
            'wb2x5Z29uIHBvaW50cz0iNDAwLDQwMCA0MDAsMTAwIDEwMCwxMDAiIC',
            'wb2x5Z29uIHBvaW50cz0iMjMwLDQwMCAyNzAsNDAwIDI3MCwyNzAgNDAwLDI3MCA0MDAsMjMwIDI3MCwyMzAgMjcwLDEwMCAyMzAsMTAwIDIzMCwyMzAgMTAwLDIzMCAxMDAsMjcwIDIzMCwyNzAiIC',
            'wb2x5Z29uIHBvaW50cz0iMjMwLDQwMCAyNzAsNDAwIDI3MCwyNzAgNDAwLDI3MCA0MDAsMjMwIDI3MCwyMzAgMjcwLDEwMCAyMzAsMTAwIDIzMCwyMzAgMTAwLDIzMCAxMDAsMjcwIDIzMCwyNzAiIHRyYW5zZm9ybT0icm90YXRlKDQ1LDI1MCwyNTApIi',
            'wb2x5Z29uIHBvaW50cz0iMjUwLDQwMCAzNTAsMjUwIDI1MCwxMDAgMTUwLDI1MCIgIC',
            'wb2x5Z29uIHBvaW50cz0iMjUwLDEwMCAzMzgsMzcxIDEwNywyMDQgMzkzLDIwNCAxNjIsMzcxIi',
            'wb2x5Z29uIHBvaW50cz0iMzgwLDE3NSAzODAsMzI1IDI1MCw0MDAgMTIwLDMyNSAxMjAsMTc1IDI1MCwxMDAiIC',
            'wYXRoIGQ9Ik0wIDIwMCB2LTIwMCBoMjAwIGExMywxMSAwIDAsMSAwLDIwMCBhMTEsMTMgMCAwLDEgLTIwMCwwIiB0cmFuc2Zvcm09InJvdGF0ZSgyMjUsMjA4LDE0OCkgc2NhbGUoMC45MikiIC'
        ];

        // Nine base64-encoded SVG fragments for primary colors.
        bytes8[9] memory c1 = [
            bytes8('NjlmZjM3'),
            'ZmYzNzY5',
            'Mzc2OWZm',
            'ZmZmZjkw',
            'OTBmZmZm',
            'ZmY5MGZm',
            'ZmZmZmZm',
            'ODA4MDgw',
            'MDAwMDAw'
        ];

        // Construct a discrete tokenURI from a unique combination of the above.
        uint256 c0i = (tokenId % 72) / 8;
        uint256 s0i = tokenId / 72;
        uint256 c1i = (tokenId % 8 + (tokenId / 8)) % 9;
        return string(
            abi.encodePacked(
                h0, h1, h2, h3, h4, h5, c0[c0i], m0, s0[s0i], m1, c1[c1i], f0
           )
       );
    }

    /**
     * @dev Derive and return a tokenURI json payload formatted as a
     * data URI.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "discreet #',
                        _toString(tokenId),
                        '", "description": "One of 1296 distinct images, stored and derived ',
                        'entirely on-chain, that comprise the discreet.eth collection. It ',
                        'will become reclaimable if 4,194,304 blocks elapse without this ',
                        'token being minted or transferred.", "image": "',
                        tokenImageURI(tokenId),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @dev Derive and return a contract-level json payload formatted as a
     * data URI.
     */
    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "discreet.eth", ',
                                '"description": "A set of 1296 distinct images, stored and derived entirely ',
                                'on-chain, that comprise the discreet.eth collection. Each token will ',
                                'become reclaimable if 4,194,304 blocks elapse without a mint or transfer of ',
                                'the token in question. Created with #1283 by 0age."}'
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Coalesce supportsInterface from inherited contracts.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
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