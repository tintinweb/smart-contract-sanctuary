// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';

import './ERC721Ownable.sol';
import './ERC721WithRoyalties.sol';

/// @title ERC721Full
/// @dev This contains all the different overrides needed on
///      ERC721 / Enumerable / URIStorage / Royalties
/// @author Simon Fremaux (@dievardump)
abstract contract ERC721Full is
    ERC721Ownable,
    ERC721Burnable,
    ERC721WithRoyalties
{
    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721, ERC721WithRoyalties)
        returns (bool)
    {
        return
            // either ERC721Enumerable
            ERC721Enumerable.supportsInterface(interfaceId) ||
            // or Royalties
            ERC721WithRoyalties.supportsInterface(interfaceId);
    }

    /// @inheritdoc	ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @inheritdoc	ERC721Ownable
    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC721, ERC721Ownable)
        returns (bool)
    {
        return ERC721Ownable.isApprovedForAll(owner_, operator);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import '../OpenSea/BaseOpenSea.sol';

/// @title ERC721Ownable
/// @author Simon Fremaux (@dievardump)
contract ERC721Ownable is Ownable, ERC721Enumerable, BaseOpenSea {
    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_
    ) ERC721(name_, symbol_) {
        // set contract uri if present
        if (bytes(contractURI_).length > 0) {
            _setContractURI(contractURI_);
        }

        // set OpenSea proxyRegistry for gas-less trading if present
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Royalties/ERC2981/IERC2981Royalties.sol';
import '../Royalties/RaribleSecondarySales/IRaribleSecondarySales.sol';

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
contract ERC721WithRoyalties is IERC2981Royalties, IRaribleSecondarySales {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IRaribleSecondarySales).interfaceId;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256)
        public
        view
        virtual
        override
        returns (address _receiver, uint256 _royaltyAmount)
    {
        _receiver = address(this);
        _royaltyAmount = 0;
    }

    /// @inheritdoc	IRaribleSecondarySales
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        returns (address payable[] memory recipients)
    {
        // using ERC2981 implementation to get the recipient & amount
        (address recipient, uint256 amount) = royaltyInfo(tokenId, 10000);
        if (amount != 0) {
            recipients = new address payable[](1);
            recipients[0] = payable(recipient);
        }
    }

    /// @inheritdoc	IRaribleSecondarySales
    function getFeeBps(uint256 tokenId)
        public
        view
        override
        returns (uint256[] memory fees)
    {
        // using ERC2981 implementation to get the amount
        (, uint256 amount) = royaltyInfo(tokenId, 10000);
        if (amount != 0) {
            fees = new uint256[](1);
            fees[0] = amount;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's support
contract BaseOpenSea {
    string private _contractURI;
    ProxyRegistry private _proxyRegistry;

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRaribleSecondarySales {
    /// @notice returns a list of royalties recipients
    /// @param tokenId the token Id to check for
    /// @return all the recipients for tokenId
    function getFeeRecipients(uint256 tokenId)
        external
        view
        returns (address payable[] memory);

    /// @notice returns a list of royalties amounts
    /// @param tokenId the token Id to check for
    /// @return all the amounts for tokenId
    function getFeeBps(uint256 tokenId)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to randomize using (min, max, seed, offsetBit etc...)
library Randomize {
    struct Random {
        uint256 seed;
        uint256 offsetBit;
    }

    /// @notice get an random number between (min and max) using seed and offseting bits
    ///         this function assumes that max is never bigger than 0xffffff (hex color with opacity included)
    /// @dev this function is simply used to get random number using a seed.
    ///      if does bitshifting operations to try to reuse the same seed as much as possible.
    ///      should be enough for anyth
    /// @param random the randomizer
    /// @param min the minimum
    /// @param max the maximum
    /// @return result the resulting pseudo random number
    function next(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256 result) {
        uint256 newSeed = random.seed;
        uint256 newOffset = random.offsetBit + 3;

        uint256 maxOffset = 4;
        uint256 mask = 0xf;
        if (max > 0xfffff) {
            mask = 0xffffff;
            maxOffset = 24;
        } else if (max > 0xffff) {
            mask = 0xfffff;
            maxOffset = 20;
        } else if (max > 0xfff) {
            mask = 0xffff;
            maxOffset = 16;
        } else if (max > 0xff) {
            mask = 0xfff;
            maxOffset = 12;
        } else if (max > 0xf) {
            mask = 0xff;
            maxOffset = 8;
        }

        // if offsetBit is too high to get the max number
        // just get new seed and restart offset to 0
        if (newOffset > (256 - maxOffset)) {
            newOffset = 0;
            newSeed = uint256(keccak256(abi.encode(newSeed)));
        }

        uint256 offseted = (newSeed >> newOffset);
        uint256 part = offseted & mask;
        result = min + (part % (max - min));

        random.seed = newSeed;
        random.offsetBit = newOffset;
    }

    function nextInt(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (int256 result) {
        result = int256(Randomize.next(random, min, max));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title IVariety interface
/// @author Simon Fremaux (@dievardump)
interface IVariety is IERC721 {
    /// @notice mint `seeds.length` token(s) to `to` using `seeds`
    /// @param to token recipient
    /// @param seeds each token seed
    function plant(address to, bytes32[] memory seeds)
        external
        returns (uint256);

    /// @notice this function returns the seed associated to a tokenId
    /// @param tokenId to get the seed of
    function getTokenSeed(uint256 tokenId) external view returns (bytes32);

    /// @notice This function allows an owner to ask for a seed update
    ///         this can be needed because although I test the contract as much as possible,
    ///         it might be possible that one token does not render because the seed creates
    ///         error or even "out of gas" computation. That's why this would allow an owner
    ///         in such case, to request for a seed change that will then be triggered by Sower
    /// @param tokenId id to regenerate seed for
    function requestSeedChange(uint256 tokenId) external;

    /// @notice This function allows Sower to answer to a seed change request
    ///         in the event where a seed would produce errors of rendering
    ///         1) this function can only be called by Sower if the token owner
    ///         asked for a new seed
    ///         2) this function will only be called if there is a rendering error
    ///         or, Vitalik Buterin forbid, a duplicate
    /// @param tokenId id to regenerate seed for
    function changeSeedAfterRequest(uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Variety.sol';
import './Renderer/512PrintRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @title TheBoard
/// @author Simon Fremaux (@dievardump)
contract _512Print is Variety {
    using Strings for uint256;

    _512PrintRenderer public renderer;

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param sower_ Sower contract
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address sower_,
        address renderer_
    ) Variety(name_, symbol_, contractURI_, openseaProxyRegistry_, sower_) {
        renderer = _512PrintRenderer(renderer_);
    }

    /// @dev internal function to get the name. Should be overrode by actual Variety contract
    /// @param tokenId the token to get the name of
    /// @return seedlingName the token name
    function _getName(uint256 tokenId)
        internal
        view
        override
        returns (string memory seedlingName)
    {
        seedlingName = names[tokenId];
        if (bytes(seedlingName).length == 0) {
            seedlingName = string(
                abi.encodePacked('512Print.sol #', tokenId.toString())
            );
        }
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function _render(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return
            _512PrintRenderer(renderer).render(
                _getName(tokenId),
                tokenId,
                seed
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../../../Randomize.sol';

/// @title TheBoard
/// @author Simon Fremaux (@dievardump)
contract _512PrintRenderer {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    using Randomize for Randomize.Random;

    struct Configuration {
        int256 spacing;
        string background1;
        string background2;
        string stroke1;
        string stroke2;
        string background;
        string stroke;
        bool degen;
        bool animated;
        bool backgroundGradient;
        bool strokeGradient;
        bool rotated;
        bool rounded;
        bool missing;
        bytes left;
        bytes right;
    }

    constructor() {}

    function start(bytes32 seed)
        public
        pure
        returns (Randomize.Random memory, Configuration memory)
    {
        Randomize.Random memory random = Randomize.Random({
            seed: uint256(seed),
            offsetBit: 0
        });

        Configuration memory config = _getConfiguration(random);

        return (random, config);
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        bytes32 seed
    ) external pure returns (string memory) {
        (Randomize.Random memory random, Configuration memory config) = start(
            seed
        );

        string memory id = uint256(seed).toString();

        bytes memory svg = abi.encodePacked(
            'data:application/json;utf8,{"name":"',
            name,
            '","image":"data:image/svg+xml;utf8,',
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 1200 1200' width='1200' height='1200'>"
            "<defs><clipPath id='print-clip-",
            id,
            "'><rect x='40' y='40' width='1120' height='1120' /></clipPath>"
        );

        svg = abi.encodePacked(
            svg,
            config.backgroundGradient
                ? string(_renderBackgroundGradient(id, config, random))
                : '',
            config.strokeGradient
                ? string(_renderStrokeGradient(id, config, random))
                : '',
            '</defs>',
            "<rect width='100%' height='100%' fill='",
            config.backgroundGradient
                ? string(abi.encodePacked('url(#print-background-', id, ')'))
                : config.background1,
            "'/><g x='40' y='40' stroke-linecap='round' stroke-width='",
            random.next(1, config.rounded ? 8 : 4).toString(),
            "' stroke='",
            config.strokeGradient
                ? string(abi.encodePacked('url(#print-stroke-', id, ')'))
                : config.stroke1,
            "' fill='",
            config.backgroundGradient
                ? string(abi.encodePacked('url(#print-background-', id, ')'))
                : config.background1,
            "' style='clip-path: url(#print-clip-",
            id,
            ")'>"
        );

        _fill(random, config);

        svg = abi.encodePacked(svg, config.left, config.right);

        svg = abi.encodePacked(
            svg,
            "</g><text text-anchor='end' x='1160' y='1180' fill='",
            config.strokeGradient
                ? string(abi.encodePacked('url(#print-stroke-', id, ')'))
                : config.stroke1,
            "'>#",
            tokenId.toString(),
            '</text></svg>"'
        );

        svg = abi.encodePacked(
            svg,
            ',"license":"Full ownership with unlimited commercial rights.","creator":"@dievardump"'
            ',"description":"Left or Right? Repeat. Add some fun.\\n\\n512Print Seedling is my take on the Solidity version of the renowned 10Print algorithm and the second of the [sol]Seedlings, an experiment of art and collectible NFTs 100% generated with Solidity.\\nby @dievardump\\n\\nLicense: Full ownership with unlimited commercial rights.\\n\\nMore info at https://solSeedlings.art"'
            ',"properties":{"Background":"',
            config.backgroundGradient ? 'Gradient' : 'Unicolor',
            '","Stroke":"',
            config.strokeGradient ? 'Gradient' : 'Unicolor',
            '"'
        );

        svg = abi.encodePacked(
            svg,
            config.degen ? ',"Particularity":"Degen"' : '',
            config.rotated ? ',"Angle":"45deg"' : '',
            config.rounded ? ',"Variante":"Rounded"' : '',
            config.animated ? ',"Rendering":"Animated"' : '',
            '}}'
        );

        return string(svg);
    }

    function _fill(Randomize.Random memory random, Configuration memory config)
        internal
        pure
    {
        if (config.rounded) {
            _renderRounded(random, config);
        } else {
            _renderClassic(random, config);
        }
    }

    function _renderClassic(
        Randomize.Random memory random,
        Configuration memory config
    ) internal pure {
        bytes memory result;
        int256 offset;
        int256 half = config.spacing / 2;
        for (int256 y; y < 1160; y += config.spacing) {
            for (int256 x; x < 1160; x += config.spacing) {
                if (config.missing && random.next(0, 100) < 15) continue;
                if (random.next(0, 2) == 0) {
                    if (!config.degen || random.next(0, 100) >= 10) {
                        result = _getLine(
                            x,
                            config.rotated ? y + half : y,
                            x + config.spacing,
                            config.rotated ? y + half : y + config.spacing,
                            0
                        );
                    } else {
                        offset = (random.nextInt(10, 20) * config.spacing) / 2;
                        result = _getLine(
                            x - offset,
                            config.rotated ? y + half : y - offset,
                            x + offset,
                            config.rotated ? y + half : y + offset,
                            random.next(10, 28)
                        );
                    }

                    config.left = abi.encodePacked(config.left, result);
                } else {
                    if (!config.degen || random.next(0, 100) >= 10) {
                        result = _getLine(
                            config.rotated ? x + half : x,
                            y + config.spacing,
                            config.rotated ? x + half : x + config.spacing,
                            y,
                            0
                        );
                    } else {
                        offset = (random.nextInt(10, 20) * config.spacing) / 2;
                        result = _getLine(
                            config.rotated ? x + half : x - offset,
                            y + offset,
                            config.rotated ? x + half : x + offset,
                            y - offset,
                            random.next(10, 28)
                        );
                    }

                    config.right = abi.encodePacked(config.right, result);
                }
            }
        }
    }

    function _renderRounded(
        Randomize.Random memory random,
        Configuration memory config
    ) internal pure {
        uint256 spacing = uint256(config.spacing);
        string memory half = (spacing / 2).toString();

        bytes memory element;

        // 50% change being round
        string memory strSpacing = spacing.toString();
        bytes memory roundedBase = _getRoundedBase(half, strSpacing);
        bytes memory cross = _getCross(half, strSpacing);
        bytes memory rotate = abi.encodePacked(
            ' rotate(90, ',
            half,
            ', ',
            half,
            ')'
        );

        int256 temp;
        bool doRotate;
        for (int256 y; y < 1160; y += config.spacing) {
            for (int256 x; x < 1160; x += config.spacing) {
                temp = random.nextInt(0, 100);
                if (temp < 50) {
                    element = roundedBase;
                } else {
                    element = cross;
                    if (temp > 83) {
                        element = abi.encodePacked(
                            element,
                            _getRoundedCircle(half, config.spacing / 4)
                        );
                    } else if (temp > 66) {
                        temp = config.animated
                            ? random.nextInt(20, 50)
                            : int256(0);
                        element = abi.encodePacked(
                            element,
                            _getSquare(
                                uint256(config.spacing / 4).toString(),
                                half,
                                uint256(temp)
                            )
                        );
                    }
                }

                doRotate = (random.next(0, 2) == 0);
                temp = random.nextInt(5, 10);
                config.left = abi.encodePacked(
                    config.left,
                    "<g transform='translate(",
                    uint256(x).toString(),
                    ',',
                    uint256(y).toString(),
                    ')',
                    doRotate ? rotate : bytes(''),
                    "' ",
                    config.degen
                        ? abi.encodePacked(
                            " stroke-width='",
                            uint256(temp).toString(),
                            "' "
                        )
                        : bytes(''),
                    '>',
                    element,
                    '</g>'
                );
            }
        }
    }

    function _getCross(string memory half, string memory spacing)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            "<line x1='",
            half,
            "' y1='0' x2='",
            half,
            "' y2='",
            spacing,
            "' />",
            "<line x1='0' y1='",
            half,
            "' x2='",
            spacing,
            "' y2='",
            half,
            "' />"
        );
    }

    function _getSquare(
        string memory position,
        string memory size,
        uint256 animation
    ) internal pure returns (bytes memory svg) {
        svg = abi.encodePacked(
            "<rect x='",
            position,
            "' y='",
            position,
            "' width='",
            size,
            "' height='",
            size,
            "' rx='6'>"
        );

        if (animation > 0) {
            svg = abi.encodePacked(
                svg,
                "<animateTransform attributeName='transform' attributeType='XML' type='rotate' dur='",
                animation.toString(),
                "s' from='0 ",
                size,
                ' ',
                size,
                "' to='360 ",
                size,
                ' ',
                size,
                "' repeatCount='indefinite' />"
            );
        }

        svg = abi.encodePacked(svg, '</rect>');
    }

    function _getRoundedCircle(string memory half, int256 size)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            "<circle cx='",
            half,
            "' cy='",
            half,
            "' r='",
            uint256(size).toString(),
            "' />"
        );
    }

    function _getRoundedBase(string memory half, string memory spacing)
        internal
        pure
        returns (bytes memory svg)
    {
        svg = abi.encodePacked(
            "<path d='M ",
            half,
            ' 0',
            'a ',
            half,
            ' ',
            half,
            ' 0 0 1 -',
            half,
            ' ',
            half,
            '',
            'm '
        );

        svg = abi.encodePacked(
            svg,
            spacing,
            ' 0',
            'a ',
            half,
            ' ',
            half,
            ' 0 0 0 -',
            half,
            ' ',
            half,
            "' fill='none'/>"
        );
    }

    function _getLine(
        int256 x0,
        int256 y0,
        int256 x1,
        int256 y1,
        uint256 strokeWidth
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<path fill='none' ",
                strokeWidth != 0
                    ? string(
                        abi.encodePacked(
                            "stroke-width='",
                            strokeWidth.toString(),
                            "'"
                        )
                    )
                    : '',
                " d='M",
                x0 < 0
                    ? string(abi.encodePacked('-', uint256(x0 * -1).toString()))
                    : uint256(x0).toString(),
                ',',
                y0 < 0
                    ? string(abi.encodePacked('-', uint256(y0 * -1).toString()))
                    : uint256(y0).toString(),
                'L',
                x1 < 0
                    ? string(abi.encodePacked('-', uint256(x1 * -1).toString()))
                    : uint256(x1).toString(),
                ',',
                y1 < 0
                    ? string(abi.encodePacked('-', uint256(y1 * -1).toString()))
                    : uint256(y1).toString(),
                "'/>"
            );
    }

    function _renderBackgroundGradient(
        string memory id,
        Configuration memory config,
        Randomize.Random memory random
    ) internal pure returns (bytes memory result) {
        uint256 animation = random.next(10000, 20000);
        result = abi.encodePacked(
            "<linearGradient id='print-background-",
            id,
            "' gradientTransform='rotate(",
            random.next(0, 360).toString(),
            ", 600, 600)' gradientUnits='userSpaceOnUse'><stop offset='0%' stop-color='",
            config.background1,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.background1,
                ';',
                config.background2,
                ';',
                config.background1,
                "' repeatCount='indefinite' />"
            );
        }

        result = abi.encodePacked(
            result,
            "</stop><stop offset='100%' stop-color='",
            config.background2,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.background2,
                ';',
                config.background1,
                ';',
                config.background2,
                "' repeatCount='indefinite' />"
            );
        }

        return abi.encodePacked(result, '</stop></linearGradient>');
    }

    function _renderStrokeGradient(
        string memory id,
        Configuration memory config,
        Randomize.Random memory random
    ) internal pure returns (bytes memory result) {
        uint256 animation = random.next(10000, 20000);
        result = abi.encodePacked(
            "<linearGradient id='print-stroke-",
            id,
            "' gradientTransform='rotate(",
            random.next(0, 360).toString(),
            ", 600, 600)' gradientUnits='userSpaceOnUse'><stop offset='0%' stop-color='",
            config.stroke1,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.stroke1,
                ';',
                config.stroke2,
                ';',
                config.stroke1,
                "' repeatCount='indefinite' />"
            );
        }

        result = abi.encodePacked(
            result,
            "</stop><stop offset='100%' stop-color='",
            config.stroke2,
            "'>"
        );

        if (config.animated) {
            result = abi.encodePacked(
                result,
                "<animate attributeName='stop-color' dur='",
                animation.toString(),
                "ms' values='",
                config.stroke2,
                ';',
                config.stroke1,
                ';',
                config.stroke2,
                "' repeatCount='indefinite' />"
            );
        }

        result = abi.encodePacked(result, '</stop></linearGradient>');
    }

    function _getConfiguration(Randomize.Random memory random)
        internal
        pure
        returns (Configuration memory config)
    {
        string[16] memory darker = [
            '#000000',
            '#1A1A2E',
            '#2C061F',
            '#352F44',
            '#1D2D50',
            '#2A363B',
            '#61105E',
            '#84142D',
            '#173F5F',
            '#29435C',
            '#A7226E',
            '#C70D3A',
            '#355C7D',
            '#20639B',
            '#6C5B7B',
            '#2D6E7E'
        ];

        string[20] memory lighter = [
            '#FFFFFF',
            '#E4FBFF',
            '#F7D9D9',
            '#B5EAEA',
            '#00FFF5',
            '#B6C9F0',
            '#FECEAB',
            '#FFF591',
            '#F8B195',
            '#F7DB4F',
            '#FF847C',
            '#3CAEA3',
            '#DA7F8F',
            '#F67280',
            '#2F9599',
            '#F26B38',
            '#C06C84',
            '#ED553B',
            '#E84A5F',
            '#EC2049'
        ];

        bool rounded = (random.next(0, 100) < 33);

        // if not rounded, 5% rotated
        bool rotated = !rounded && (random.next(0, 100) < 5);

        // if rotated; then degen, else 20%
        bool degen = (rotated || (random.next(0, 100) < 20));

        uint256 temp = random.next(0, 100);
        int256 spacing = random.nextInt(rounded ? 120 : 90, 160);
        if (spacing % 2 != 0) {
            spacing++;
        }

        config = Configuration({
            spacing: spacing,
            background1: '#000',
            background2: '#000',
            stroke1: '#fff',
            stroke2: '#fff',
            background: 'Black',
            stroke: 'White',
            degen: degen,
            animated: false,
            backgroundGradient: false,
            strokeGradient: false,
            rotated: rotated,
            missing: !rounded && (random.next(0, 100) < 5),
            left: '',
            right: '',
            rounded: rounded
        });

        if (temp >= 4 && temp < 8) {
            // black on white
            config.background1 = '#fff';
            config.background2 = '#fff';
            config.stroke1 = '#000';
            config.stroke2 = '#000';
            config.background = 'White';
            config.stroke = 'Black';
        } else if (temp < 26) {
            // black on lighter background
            config.background1 = config.background2 = lighter[
                random.next(0, lighter.length)
            ];
            config.stroke1 = '#000';
            config.stroke2 = '#000';

            config.background = 'Lighter';
            config.stroke = 'Black';
        } else if (temp < 44) {
            // white on darker background
            config.background1 = config.background2 = darker[
                random.next(0, darker.length)
            ];
            config.stroke1 = '#fff';
            config.stroke2 = '#fff';

            config.background = 'Darker';
            config.stroke = 'White';
        } else if (temp < 62) {
            // light gradient on black
            config.background1 = '#000';
            config.background2 = '#000';
            temp = random.next(0, lighter.length);
            config.stroke1 = lighter[temp];
            config.stroke2 = lighter[
                (temp + random.next(lighter.length / 2, lighter.length)) %
                    lighter.length
            ];

            config.background = 'Black';
            config.stroke = 'Light gradient';
        } else if (temp < 80) {
            // dark gradient on white
            config.background1 = '#fff';
            config.background2 = '#fff';

            temp = random.next(0, darker.length);
            config.stroke1 = darker[temp];
            config.stroke2 = darker[
                (temp + random.next(darker.length / 2, darker.length)) %
                    darker.length
            ];

            config.background = 'White';
            config.stroke = 'Darker gradient';
        } else if (temp < 90) {
            // dark gradient on light gradient
            temp = random.next(0, lighter.length);
            config.background1 = lighter[temp];
            config.background2 = lighter[
                (temp + random.next(lighter.length / 2, lighter.length)) %
                    lighter.length
            ];
            temp = random.next(0, darker.length);
            config.stroke1 = darker[temp];
            config.stroke2 = darker[
                (temp + random.next(darker.length / 2, darker.length)) %
                    darker.length
            ];

            config.background = 'Lighter gradient';
            config.stroke = 'Darker gradient';
        } else {
            // light gradient on dark gradient
            temp = random.next(0, darker.length);
            config.background1 = darker[temp];
            config.background2 = darker[
                (temp + random.next(darker.length / 2, darker.length)) %
                    darker.length
            ];

            temp = random.next(0, lighter.length);
            config.stroke1 = lighter[temp];
            config.stroke2 = lighter[
                (temp + random.next(lighter.length / 2, lighter.length)) %
                    lighter.length
            ];

            config.background = 'Darker gradient';
            config.stroke = 'Lighter gradient';
        }

        config.backgroundGradient =
            keccak256(abi.encodePacked((config.background1))) !=
            keccak256(abi.encodePacked((config.background2)));
        config.strokeGradient =
            keccak256(abi.encodePacked((config.stroke1))) !=
            keccak256(abi.encodePacked((config.stroke2)));

        // if rounded or gradient, it can be animated
        config.animated =
            (rounded || (config.backgroundGradient || config.strokeGradient)) &&
            (random.next(0, 100) < 10);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////************@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////*******************@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///***********************@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///**************************@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///**********/**************/*@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////****/****************//@@@@@
// @@@*********@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(///////////*****************//@@@@@@
// @@@**************//////@@@@@@@@@@@@@@@@@@@((////////////***************//@@@@@@@
// @@@*********************////@@@@@@@@@@@@@((///////////////************//@@@@@@@@
// @@@@//**************//***//////@@@@@@@@@@(///////////////////*******//@@@@@@@@@@
// @@@@@/*****************////////((@@@@@@@((///((////////////////***//@@@@@@@@@@@@
// @@@@@@//*************////////////((@@@@@((//((////////////////////@@@@@@@@@@@@@@
// @@@@@@@//**********///////////////((@@@@((((//////////////////@@@@@@@@@@@@@@@@@@
// @@@@@@@@///******//////////////((//((@@@(((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@//*///////////////////(//((@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@////////////////////(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@/((((/////////////((((/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@((((((((@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@###(((((((((((((((((((((((((###@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@####################################@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@#############################################@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './IVariety.sol';
import '../NFT/ERC721Helpers/ERC721Full.sol';

/// @title Variety Contract
/// @author Simon Fremaux (@dievardump)
contract Variety is IVariety, ERC721Full {
    event SeedChangeRequest(uint256 indexed tokenId, address indexed operator);

    // seedlings Sower
    address public sower;

    // last tokenId
    uint256 public lastTokenId;

    // each token seed
    mapping(uint256 => bytes32) internal tokenSeed;

    // names
    mapping(uint256 => string) public names;

    // useNames
    mapping(bytes32 => bool) public usedNames;

    // tokenIds with a request for seeds change
    mapping(uint256 => bool) internal seedChangeRequests;

    modifier onlySower() {
        require(msg.sender == sower, 'Not Sower.');
        _;
    }

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param sower_ Sower contract
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address sower_
    ) ERC721Ownable(name_, symbol_, contractURI_, openseaProxyRegistry_) {
        sower = sower_;
    }

    /// @notice mint `seeds.length` token(s) to `to` using `seeds`
    /// @param to token recipient
    /// @param seeds each token seed
    function plant(address to, bytes32[] memory seeds)
        external
        override
        onlySower
        returns (uint256)
    {
        uint256 tokenId = lastTokenId;
        for (uint256 i; i < seeds.length; i++) {
            tokenId++;
            _safeMint(to, tokenId);
            tokenSeed[tokenId] = seeds[i];
        }
        lastTokenId = tokenId;

        return tokenId;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Full, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice tokenURI override that returns a data:json application
    /// @inheritdoc	ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        return _render(tokenId, tokenSeed[tokenId]);
    }

    /// @notice ERC2981 support - 4% royalties sent to Sower
    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = sower;
        royaltyAmount = (value * 400) / 10000;
    }

    /// @inheritdoc IVariety
    function getTokenSeed(uint256 tokenId)
        external
        view
        override
        returns (bytes32)
    {
        require(_exists(tokenId), 'TokenSeed query for nonexistent token');
        return tokenSeed[tokenId];
    }

    /// @inheritdoc IVariety
    function requestSeedChange(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');
        seedChangeRequests[tokenId] = true;
        emit SeedChangeRequest(tokenId, msg.sender);
    }

    /// @inheritdoc IVariety
    function changeSeedAfterRequest(uint256 tokenId)
        external
        override
        onlySower
    {
        require(seedChangeRequests[tokenId] == true, 'No request for token.');
        seedChangeRequests[tokenId] = false;
        tokenSeed[tokenId] = keccak256(
            abi.encode(
                tokenSeed[tokenId],
                block.timestamp,
                block.difficulty,
                blockhash(block.number - 1)
            )
        );
    }

    /// @notice Function allowing an owner to set the seedling name
    ///         User needs to be extra careful. Some characters might completly break the token.
    ///         Since the metadata are generated in the contract.
    ///         if this ever happens, you can simply reset the name to nothing or for something else
    /// @dev sender must be tokenId owner
    /// @param tokenId the token to name
    /// @param seedlingName the name
    function setName(uint256 tokenId, string memory seedlingName) external {
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');

        bytes32 byteName = keccak256(abi.encodePacked(seedlingName));

        // if the name is not empty, verify it is not used
        if (bytes(seedlingName).length > 0) {
            require(usedNames[byteName] == false, 'Name already used');
            usedNames[byteName] = true;
        }

        // if it already has a name, mark all name as unused
        string memory oldName = names[tokenId];
        if (bytes(oldName).length > 0) {
            byteName = keccak256(abi.encodePacked(oldName));
            usedNames[byteName] = false;
        }

        names[tokenId] = seedlingName;
    }

    /// @notice function to get a token name
    /// @dev token must exist
    /// @param tokenId the token to get the name of
    /// @return the token name
    function getName(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), 'Unknown token');
        return _getName(tokenId);
    }

    /// @dev internal function to get the name. Should be overrode by actual Variety contract
    /// @param tokenId the token to get the name of
    /// @return the token name
    function _getName(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return bytes(names[tokenId]).length > 0 ? names[tokenId] : 'Variety';
    }

    /// @notice Function allowing to check the rendering for a given seed
    ///         This allows to know what a seed would render without minting
    /// @param seed the seed to render
    /// @return the json
    function renderSeed(bytes32 seed) public view returns (string memory) {
        return _render(0, seed);
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function _render(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        returns (string memory)
    {
        seed;
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"',
                    _getName(tokenId),
                    '"}'
                )
            );
    }
}

