// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { Chess } from "./Chess.sol";
import { Engine } from "./Engine.sol";
import { fiveoutofnineART } from "./fiveoutofnineART.sol";

/// @title fiveoutofnine NFT - the first 100% on-chain chess engine.
/// @author fiveoutofnine
/// @notice This file has few docstrings (by choice) because most of it is standard. Refer to
/// {Chess}, {Engine}, and {fiveoutofnineART} for thorough documentation.
contract fiveoutofnine is ERC721, Ownable, ReentrancyGuard {
    using Chess for uint256;
    using Strings for uint256;

    uint256 public board;
    uint256 private internalId;

    mapping(uint256 => uint256) public tokenInternalIds;
    mapping(uint256 => Chess.Move) public tokenMoves;

    uint256 public totalSupply;
    string private baseURI;

    constructor() ERC721("fiveoutofnine", unicode"♞") {
        honorableMints();
        board = 0x32562300110101000010010000000C0099999000BCDE0B000000001;
        internalId = (1 << 0x80) | 2;
        totalSupply = 11;
    }

    function mintMove(uint256 _move, uint256 _depth) external payable nonReentrant {
        require(_depth >= 3 && _depth <= 10);
        require((internalId >> 0x80) < 59 && uint128(internalId) < 59);

        playMove(_move, _depth);
        _safeMint(msg.sender, totalSupply++);
    }

    function playMove(uint256 _move, uint256 _depth) internal {
        unchecked {
            uint256 inMemoryBoard = board;
            require(inMemoryBoard.isLegalMove(_move));

            inMemoryBoard = inMemoryBoard.applyMove(_move);
            (uint256 bestMove, bool isWhiteCheckmated) = Engine.searchMove(inMemoryBoard, _depth);

            tokenInternalIds[totalSupply] = internalId++;
            tokenMoves[totalSupply] = Chess.Move(board, (_depth << 24) | (_move << 12) | bestMove);

            if (bestMove == 0 || uint128(internalId) >= 59) {
                resetBoard();
            } else {
                board = inMemoryBoard.applyMove(bestMove);
                if (isWhiteCheckmated) {
                    resetBoard();
                }
            }
        }
    }

    function resetBoard() internal {
        board = 0x3256230011111100000000000000000099999900BCDECB000000001;
        internalId = ((internalId >> 0x80) + 1) << 0x80;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return bytes(baseURI).length == 0
            ? _tokenURI(_tokenId)
            : string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function _tokenURI(uint256 _tokenId) public view returns (string memory) {
        return fiveoutofnineART.getMetadata(tokenInternalIds[_tokenId], tokenMoves[_tokenId]);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function honorableMints() internal {
        _safeMint(0xA85572Cd96f1643458f17340b6f0D6549Af482F5, 0);
        tokenInternalIds[0] = 0;
        tokenMoves[0] = Chess.Move(
            0x3256230011111100000000000000000099999900BCDECB000000001,
            0x851C4A2
        );

        _safeMint(0x3759328b1CE944642d36a61F06783f2865212515, 1);
        tokenInternalIds[1] = 1;
        tokenMoves[1] = Chess.Move(
            0x3256230010111100000000000190000099099900BCDECB000000001,
            0x759E51C
        );

        _safeMint(0xFD8eA0F05dB884A78B1A1C1B3767B9E5D6664764, 2);
        tokenInternalIds[2] = 2;
        tokenMoves[2] = Chess.Move(
            0x3256230010101100000100009190000009099900BCDECB000000001,
            0x64DB565
        );

        _safeMint(0x174787a207BF4eD4D8db0945602e49f42c146474, 3);
        tokenInternalIds[3] = 3;
        tokenMoves[3] = Chess.Move(
            0x3256230010100100000100009199100009009900BCDECB000000001,
            0x645A725
        );

        _safeMint(0x6dEa5dCFa64DC0bb4E5AC53A375A4377CF4eD0Ee, 4);
        tokenInternalIds[4] = 4;
        tokenMoves[4] = Chess.Move(
            0x3256230010100100000000009199100009009000BCDECB000000001,
            0x631A4DB
        );

        _safeMint(0x333601a803CAc32B7D17A38d32c9728A93b422f4, 5);
        tokenInternalIds[5] = 5;
        tokenMoves[5] = Chess.Move(
            0x3256230010000100001000009199D00009009000BC0ECB000000001,
            0x6693315
        );

        _safeMint(0x530cF036Ed4Fa58f7301a9C788C9806624ceFD19, 6);
        tokenInternalIds[6] = 6;
        tokenMoves[6] = Chess.Move(
            0x32502300100061000010000091990000090D9000BC0ECB000000001,
            0x64E1554
        );

        _safeMint(0xD6A9cB7aB95293a7D38f416Cd3A4Fe9059CCd5B2, 7);
        tokenInternalIds[7] = 7;
        tokenMoves[7] = Chess.Move(
            0x325023001006010000100D009199000009009000BC0ECB000000001,
            0x63532A5
        );

        _safeMint(0xaFDc1A3EF3992f53C10fC798d242E15E2F0DF51A, 8);
        tokenInternalIds[8] = 8;
        tokenMoves[8] = Chess.Move(
            0x305023001006010000100D0091992000090C9000B00ECB000000001,
            0x66E4000
        );

        _safeMint(0xC1A80D351232fD07EE5733b5F581E01C269068A9, 9);
        tokenInternalIds[9] = 1 << 0x80;
        tokenMoves[9] = Chess.Move(
            0x3256230011111100000000000000000099999900BCDECB000000001,
            0x646155E
        );

        _safeMint(0xF42D1c0c0165AF5625b2ecD5027c5C5554e5b039, 10);
        tokenInternalIds[10] = (1 << 0x80) | 1;
        tokenMoves[10] = Chess.Move(
            0x3256230011110100000001000000000099999000BCDECB000000001,
            0x62994DB
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
pragma solidity ^0.8.9;

import { Engine } from "./Engine.sol";

/// @title Utils library for fiveoutofnine (a 100% on-chain 6x6 chess engine)
/// @author fiveoutofnine
/// @dev Understand the representations of the chess pieces, board, and moves very carefully before
/// using this library:
/// ======================================Piece Representation======================================
/// Each chess piece is defined with 4 bits as follows:
///     * The first bit denotes the color (0 means black; 1 means white).
///     * The last 3 bits denote the type:
///         | Bits | # | Type   |
///         | ---- | - | ------ |
///         | 000  | 0 | Empty  |
///         | 001  | 1 | Pawn   |
///         | 010  | 2 | Bishop |
///         | 011  | 3 | Rook   |
///         | 100  | 4 | Knight |
///         | 101  | 5 | Queen  |
///         | 110  | 6 | King   |
/// ======================================Board Representation======================================
/// The board is an 8x8 representation of a 6x6 chess board. For efficiency, all information is
/// bitpacked into a single uint256. Thus, unlike typical implementations, board positions are
/// accessed via bit shifts and bit masks, as opposed to array accesses. Since each piece is 4 bits,
/// there are 64 ``indices'' to access:
///                                     63 62 61 60 59 58 57 56
///                                     55 54 53 52 51 50 49 48
///                                     47 46 45 44 43 42 41 40
///                                     39 38 37 36 35 34 33 32
///                                     31 30 29 28 27 26 25 24
///                                     23 22 21 20 19 18 17 16
///                                     15 14 13 12 11 10 09 08
///                                     07 06 05 04 03 02 01 00
/// All numbers in the figure above are in decimal representation.
/// For example, the piece at index 27 is accessed with ``(board >> (27 << 2)) & 0xF''.
///
/// The top/bottom rows and left/right columns are treated as sentinel rows/columns for efficient
/// boundary validation (see {Chess-generateMoves} and {Chess-isValid}). i.e., (63, ..., 56),
/// (07, ..., 00), (63, ..., 07), and (56, ..., 00) never contain pieces. Every bit in those rows
/// and columns should be ignored, except for the last bit. The last bit denotes whose turn it is to
/// play (0 means black's turn; 1 means white's turn). e.g. a potential starting position:
///                                Black
///                       00 00 00 00 00 00 00 00                    Black
///                       00 03 02 05 06 02 03 00                 ♜ ♝ ♛ ♚ ♝ ♜
///                       00 01 01 01 01 01 01 00                 ♟ ♟ ♟ ♟ ♟ ♟
///                       00 00 00 00 00 00 00 00     denotes
///                       00 00 00 00 00 00 00 00    the board
///                       00 09 09 09 09 09 09 00                 ♙ ♙ ♙ ♙ ♙ ♙
///                       00 11 12 13 14 12 11 00                 ♖ ♘ ♕ ♔ ♘ ♖
///                       00 00 00 00 00 00 00 01                    White
///                                White
/// All numbers in the example above are in decimal representation.
/// ======================================Move Representation=======================================
/// Each move is allocated 12 bits. The first 6 bits are the index the piece is moving from, and the
/// last 6 bits are the index the piece is moving to. Since the index representing a square is at
/// most 54, 6 bits sufficiently represents any index (0b111111 = 63 > 54). e.g. 1243 denotes a move
/// from index 19 to 27 (1243 = (19 << 6) | 27).
///
/// Since the board is represented by a uint256, consider including ``using Chess for uint256''.
library Chess {
    using Chess for uint256;
    using Chess for Chess.MovesArray;

    /// The depth, white's move, and black's move are bitpacked in that order as `metadata` for
    /// efficiency. As explained above, 12 bits sufficiently describe a move, so both white's and
    /// black's moves are allocated 12 bits each.
    struct Move {
        uint256 board;
        uint256 metadata;
    }

    /// ``moves'' are bitpacked into uint256s for efficiency. Since every move is defined by at most
    /// 12 bits, a uint256 can contain up to 21 moves via bitpacking (21 * 12 = 252 < 256).
    /// Therefore, `items` can contain up to 21 * 5 = 105 moves. 105 is a safe upper bound for the
    /// number of possible moves a given side may have during a real game, but be wary because there
    /// is no formal proof of the upper bound being less than or equal to 105.
    struct MovesArray {
        uint256 index;
        uint256[5] items;
    }

    /// @notice Takes in a board position, and applies the move `_move` to it.
    /// @dev After applying the move, the board's perspective is updated (see {rotate}). Thus,
    /// engines with symmterical search algorithms -- like negamax search -- probably work best.
    /// @param _board The board to apply the move to.
    /// @param _move The move to apply.
    /// @return The reversed board after applying `_move` to `_board`.
    function applyMove(uint256 _board, uint256 _move) internal pure returns (uint256) {
        unchecked {
            // Get piece at the from index
            uint256 piece = (_board >> ((_move >> 6) << 2)) & 0xF;
            // Replace 4 bits at the from index with 0000
            _board &= type(uint256).max ^ (0xF << ((_move >> 6) << 2));
            // Replace 4 bits at the to index with 0000
            _board &= type(uint256).max ^ (0xF << ((_move & 0x3F) << 2));
            // Place the piece at the to index
            _board |= (piece << ((_move & 0x3F) << 2));

            return _board.rotate();
        }
    }

    /// @notice Switches the perspective of the board by reversing its 4-bit subdivisions (e.g.
    /// 1100-0011 would become 0011-1100).
    /// @dev Since the last bit exchanges positions with the 4th bit, the turn identifier is updated
    /// as well.
    /// @param _board The board to reverse the perspective on.
    /// @return `_board` reversed.
    function rotate(uint256 _board) internal pure returns (uint256) {
        uint256 rotatedBoard;

        unchecked {
            for (uint256 i; i < 64; ++i) {
                rotatedBoard = (rotatedBoard << 4) | (_board & 0xF);
                _board >>= 4;
            }
        }

        return rotatedBoard;
    }

    /// @notice Generates all possible pseudolegal moves for a given position and color.
    /// @dev The last bit denotes which color to generate the moves for (see {Chess}). Also, the
    /// function errors if more than 105 moves are found (see {Chess-MovesArray}). All moves are
    /// expressed in code as shifts respective to the board's 8x8 representation (see {Chess}).
    /// @param _board The board position to generate moves for.
    /// @return Bitpacked uint256(s) containing moves.
    function generateMoves(uint256 _board) internal pure returns (uint256[5] memory) {
        Chess.MovesArray memory movesArray;
        uint256 move;
        uint256 moveTo;

        unchecked {
            // `0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289` is a mapping of indices
            // relative to the 6x6 board to indices relative to the 8x8 representation (see
            // {Chess-getAdjustedIndex}).
            for (
                uint256 index = 0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289;
                index != 0;
                index >>= 6
            ) {
                uint256 adjustedIndex = index & 0x3F;
                uint256 adjustedBoard = _board >> (adjustedIndex << 2);
                uint256 piece = adjustedBoard & 0xF;
                // Skip if square is empty or not the color of the board the function call is
                // analyzing.
                if (piece == 0 || piece >> 3 != _board & 1) continue;
                // The first bit can be discarded because the if statement above catches all
                // redundant squares.
                piece &= 7;

                if (piece == 1) { // Piece is a pawn.
                    // 1 square in front of the pawn is empty.
                    if ((adjustedBoard >> 0x20) & 0xF == 0) {
                        movesArray.append(adjustedIndex, adjustedIndex + 8);
                        // The pawn is in its starting row and 2 squares in front is empty. This
                        // must be nested because moving 2 squares would not be valid if there was
                        // an obstruction 1 square in front (i.e. pawns can not jump over pieces).
                        if (adjustedIndex >> 3 == 2 && (adjustedBoard >> 0x40) & 0xF == 0) {
                            movesArray.append(adjustedIndex, adjustedIndex + 0x10);
                        }
                    }
                    // Moving to the right diagonal by 1 captures a piece.
                    if (_board.isCapture(adjustedBoard >> 0x1C)) {
                        movesArray.append(adjustedIndex, adjustedIndex + 7); 
                    }
                    // Moving to the left diagonal by 1 captures a piece.
                    if (_board.isCapture(adjustedBoard >> 0x24)) {
                        movesArray.append(adjustedIndex, adjustedIndex + 9);
                    }
                } else if (piece > 3 && piece & 1 == 0) { // Piece is a knight or a king.
                    // Knights and kings always only have 8 positions to check relative to their
                    // current position, and the relative distances are always the same. For
                    // knights, positions to check are ±{6, 10, 15, 17}. This is bitpacked into
                    // `0x060A0F11` to reduce code redundancy. Similarly, the positions to check for
                    // kings are ±{1, 7, 8, 9}, which is `0x01070809` when bitpacked.
                    for (move = piece == 4 ? 0x060A0F11 : 0x01070809; move != 0; move >>= 8) {
                        if (_board.isValid(moveTo = adjustedIndex + (move & 0xFF))) {
                            movesArray.append(adjustedIndex, moveTo);
                        }
                        if (move <= adjustedIndex
                            && _board.isValid(moveTo = adjustedIndex - (move & 0xFF)))
                        {
                            movesArray.append(adjustedIndex, moveTo);
                        }
                    }
                } else {
                    // This else block generates moves for all sliding pieces. All of the 8 for
                    // loops terminate
                    //     * before a sliding piece makes an illegal move
                    //     * or after a sliding piece captures a piece.
                    if (piece != 2) { // Ortholinear pieces (i.e. rook and queen)
                        for (move = adjustedIndex + 1; _board.isValid(move); move += 1) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 1; _board.isValid(move); move -= 1) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex + 8; _board.isValid(move); move += 8) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 8; _board.isValid(move); move -= 8) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                    }
                    if (piece != 3) { // Diagonal pieces (i.e. bishop and queen)
                        for (move = adjustedIndex + 7; _board.isValid(move); move += 7) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 7; _board.isValid(move); move -= 7) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex + 9; _board.isValid(move); move += 9) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 9; _board.isValid(move); move -= 9) {
                            // Handles the edge case where a white bishop believes it can capture
                            // the ``piece'' at index 0, when it is actually the turn identifier It
                            // would mistakenly believe it is valid move via capturing a black pawn.
                            if (move == 0) break;
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                    }
                }
            }
        }

        return movesArray.items;
    }

    /// @notice Determines whether a move is a legal move or not (includes checking whether king is
    /// checked or not after the move).
    /// @param _board The board to analyze.
    /// @param _move The move to check.
    /// @return Whether the move is legal or not.
    function isLegalMove(uint256 _board, uint256 _move) internal pure returns (bool) {
        unchecked {
            uint256 fromIndex = _move >> 6;
            uint256 toIndex = _move & 0x3F;
            if ((0x7E7E7E7E7E7E00 >> fromIndex) & 1 == 0) return false;
            if ((0x7E7E7E7E7E7E00 >> toIndex) & 1 == 0) return false;

            uint256 pieceAtFromIndex = (_board >> (fromIndex << 2)) & 0xF;
            if (pieceAtFromIndex == 0) return false;
            if (pieceAtFromIndex >> 3 != _board & 1) return false;
            pieceAtFromIndex &= 7;

            uint256 adjustedBoard = _board >> (toIndex << 2);
            uint256 indexChange = toIndex < fromIndex
                    ? fromIndex - toIndex
                    : toIndex - fromIndex;
            if (pieceAtFromIndex == 1) {
                if (toIndex <= fromIndex) return false;
                indexChange = toIndex - fromIndex;
                if ((indexChange == 7 || indexChange == 9)) {
                    if (!_board.isCapture(adjustedBoard)) return false;
                } else if (indexChange == 8) {
                    if (!isValid(_board, toIndex)) return false;
                } else if (indexChange == 0x10) {
                    if (!isValid(_board, toIndex - 8) || !isValid(_board, toIndex)) return false;
                } else {
                    return false;
                }
            } else if (pieceAtFromIndex == 4 || pieceAtFromIndex == 6) {
                if (((pieceAtFromIndex == 4 ? 0x28440 : 0x382) >> indexChange) & 1 == 0) {
                    return false;
                }
                if (!isValid(_board, toIndex)) return false;
            } else {
                bool rayFound;
                if (pieceAtFromIndex != 2) {
                    rayFound = searchRay(_board, fromIndex, toIndex, 1)
                        || searchRay(_board, fromIndex, toIndex, 8);
                }
                if (pieceAtFromIndex != 3) {
                    rayFound = rayFound
                        || searchRay(_board, fromIndex, toIndex, 7)
                        || searchRay(_board, fromIndex, toIndex, 9);
                }
                if (!rayFound) return false;
            }

            if (Engine.negaMax(_board.applyMove(_move), 1) < -1_260) return false;

            return true;
        }
    }

    /// @notice Determines whether there is a clear path along a direction vector from one index to
    /// another index on the board.
    /// @dev The board's representation essentially flattens it from 2D to 1D, so `_directionVector`
    /// should be the change in index that represents the direction vector.
    /// @param _board The board to analyze.
    /// @param _fromIndex The index of the starting piece.
    /// @param _toIndex The index of the ending piece.
    /// @param _directionVector The direction vector of the ray.
    /// @return Whether there is a clear path between `_fromIndex` and `_toIndex` or not.
    function searchRay(
        uint256 _board,
        uint256 _fromIndex,
        uint256 _toIndex,
        uint256 _directionVector
    )
        internal pure
        returns (bool)
    {
        unchecked {
            uint256 indexChange;
            uint256 rayStart;
            uint256 rayEnd;
            if (_fromIndex < _toIndex) {
                indexChange = _toIndex - _fromIndex;
                rayStart = _fromIndex + _directionVector;
                rayEnd = _toIndex;
            } else {
                indexChange = _fromIndex - _toIndex;
                rayStart = _toIndex;
                rayEnd = _fromIndex - _directionVector;
            }
            if (indexChange % _directionVector != 0) return false;

            for (
                rayStart = rayStart;
                rayStart < rayEnd;
                rayStart += _directionVector
            ) {
                if (!isValid(_board, rayStart)) return false;
                if (isCapture(_board, _board >> (rayStart << 2))) return false;
            }

            if (!isValid(_board, rayStart)) return false;

            return rayStart == rayEnd;
        }
    }

    /// @notice Determines whether a move results in a capture or not.
    /// @param _board The board prior to the potential capture.
    /// @param _indexAdjustedBoard The board bitshifted to the to index to consider.
    /// @return Whether the move is a capture or not.
    function isCapture(uint256 _board, uint256 _indexAdjustedBoard) internal pure returns (bool) {
        unchecked {
            return (_indexAdjustedBoard & 0xF) != 0 // The square is not empty.
                && (_indexAdjustedBoard & 0xF) >> 3 != _board & 1; // The piece is opposite color.
        }
    }

    /// @notice Determines whether a move is valid or not (i.e. within bounds and not capturing
    /// same colored piece).
    /// @dev As mentioned above, the board representation has 2 sentinel rows and columns for
    /// efficient boundary validation as follows:
    ///                                           0 0 0 0 0 0 0 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 0 0 0 0 0 0 0,
    /// where 1 means a piece is within the board, and 0 means the piece is out of bounds. The bits
    /// are bitpacked into a uint256 (i.e. ``0x7E7E7E7E7E7E00 = 0 << 63 | ... | 0 << 0'') for
    /// efficiency.
    ///
    /// Moves that overflow the uint256 are computed correctly because bitshifting more than bits
    /// available results in 0. However, moves that underflow the uint256 (i.e. applying the move
    /// results in a negative index) must be checked beforehand.
    /// @param _board The board on which to consider whether the move is valid.
    /// @param _toIndex The to index of the move.
    /// @return Whether the move is valid or not.
    function isValid(uint256 _board, uint256 _toIndex) internal pure returns (bool) {
        unchecked {
            return (0x7E7E7E7E7E7E00 >> _toIndex) & 1 == 1 // Move is within bounds.
                && ((_board >> (_toIndex << 2)) & 0xF == 0 // Square is empty.
                    || (((_board >> (_toIndex << 2)) & 0xF) >> 3) != _board & 1); // Piece captured.
        }
    }

    /// @notice Maps an index relative to the 6x6 board to the index relative to the 8x8
    /// representation.
    /// @dev The indices are mapped as follows:
    ///                           35 34 33 32 31 30              54 53 52 51 50 49
    ///                           29 28 27 26 25 24              46 45 44 43 42 41
    ///                           23 22 21 20 19 18    mapped    38 37 36 35 34 33
    ///                           17 16 15 14 13 12      to      30 29 28 27 26 25
    ///                           11 10 09 08 07 06              22 21 20 19 18 17
    ///                           05 04 03 02 01 00              14 13 12 11 10 09
    /// All numbers in the figure above are in decimal representation. The bits are bitpacked into a
    /// uint256 (i.e. ``0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289 = 54 << (6 * 35) |
    /// ... | 9 << (6 * 0)'') for efficiency.
    /// @param _index Index relative to the 6x6 board.
    /// @return Index relative to the 8x8 representation.
    function getAdjustedIndex(uint256 _index) internal pure returns (uint256) {
        unchecked {
            return (
                (0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289 >> (_index * 6)) & 0x3F
            );
        }
    }

    /// @notice Appends a move to a {Chess-MovesArray} object.
    /// @dev Since each uint256 fits at most 21 moves (see {Chess-MovesArray}), {Chess-append}
    /// bitpacks 21 moves per uint256 before moving on to the next uint256.
    /// @param _movesArray {Chess-MovesArray} object to append the new move to.
    /// @param _fromMoveIndex Index the piece moves from.
    /// @param _toMoveIndex Index the piece moves to.
    function append(MovesArray memory _movesArray, uint256 _fromMoveIndex, uint256 _toMoveIndex)
        internal pure
    {
        unchecked {
            uint256 currentIndex = _movesArray.index;
            uint256 currentPartition = _movesArray.items[currentIndex];

            if (currentPartition > (1 << 0xF6)) {
                _movesArray.items[++_movesArray.index] = (_fromMoveIndex << 6) | _toMoveIndex;
            } else {
                _movesArray.items[currentIndex] = (currentPartition << 0xC)
                    | (_fromMoveIndex << 6)
                    | _toMoveIndex;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Chess } from "./Chess.sol";

/// @title A 6x6 chess engine with negamax search
/// @author fiveoutofnine
/// @notice Docstrings below are written from the perspective of black (i.e. written as if the
/// engine is always black). However, due to negamax's symmetric nature, the engine may be used for
/// white as well.
library Engine {
    using Chess for uint256;
    using Engine for uint256;

    /// @notice Searches for the ``best'' move.
    /// @dev The ply depth must be at least 3 because game ending scenarios are determined lazily.
    /// This is because {generateMoves} generates pseudolegal moves. Consider the following:
    ///     1. In the case of white checkmates black, depth 2 is necessary:
    ///         * Depth 1: This is the move black plays after considering depth 2.
    ///         * Depth 2: Check whether white captures black's king within 1 turn for every such
    ///           move. If so, white has checkmated black.
    ///     2. In the case of black checkmates white, depth 3 is necessary:
    ///         * Depth 1: This is the move black plays after considering depths 2 and 3.
    ///         * Depth 2: Generate all pseudolegal moves for white in response to black's move.
    ///         * Depth 3: Check whether black captures white's king within 1 turn for every such
    ///         * move. If so, black has checkmated white.
    /// The minimum depth required to cover all the cases above is 3. For simplicity, stalemates
    /// are treated as checkmates.
    ///
    /// The function returns 0 if the game is over after white's move (no collision with any
    /// potentially real moves because 0 is not a valid index), and returns true if the game is over
    /// after black's move.
    /// @param _board The board position to analyze.
    /// @param _depth The ply depth to analyze to. Must be at least 3.
    /// @return The best move for the player (denoted by the last bit in `_board`).
    /// @return Whether white is checkmated or not.
    function searchMove(uint256 _board, uint256 _depth) internal pure returns (uint256, bool) {
        uint256[5] memory moves = _board.generateMoves();
        if (moves[0] == 0) return (0, false);
        // See {Engine-negaMax} for explanation on why `bestScore` is set to -4_196.
        int256 bestScore = -4_196;
        int256 currentScore;
        uint256 bestMove;

        unchecked {
            for (uint256 i; moves[i] != 0; ++i) {
                for (uint256 movePartition = moves[i]; movePartition != 0; movePartition >>= 0xC) {
                    currentScore = _board.evaluateMove(movePartition & 0xFFF)
                        + negaMax(_board.applyMove(movePartition & 0xFFF), _depth - 1);
                    if (currentScore > bestScore) {
                        bestScore = currentScore;
                        bestMove = movePartition & 0xFFF;
                    }
                }
            }
        }

        // 1_260 is equivalent to 7 queens (7 * 180 = 1260). Since a king's capture is equivalent to
        // an evaluation of 4_000, ±1_260 catches all lines that include the capture of a king.
        if (bestScore < -1_260) return (0, false);
        return (bestMove, bestScore > 1_260);
    }

    /// @notice Searches and evaluates moves using a variant of the negamax search algorithm.
    /// @dev For efficiency, the function evaluates how good moves are and sums them up, rather than
    /// evaluating entire board positions. Thus, the only pruning the algorithm performs is when a
    /// king is captured. If a king is captured, it always returns -4,000, which is the king's value
    /// (see {Chess}) because there is nothing more to consider.
    /// @param _board The board position to analyze.
    /// @param _depth The ply depth to analyze to.
    /// @return The cumulative score searched to a ply depth of `_depth`, assuming each side picks
    /// their ``best'' (as decided by {Engine-evaluateMove}) moves.
    function negaMax(uint256 _board, uint256 _depth) internal pure returns (int256) {
        // Base case for the recursion.
        if (_depth == 0) return 0;
        uint256[5] memory moves = _board.generateMoves();
        // There is no ``best'' score if there are no moves to play.
        if (moves[0] == 0) return 0;
        // `bestScore` is initially set to -4_196 because no line will result in a cumulative
        // evaluation of <-4_195. -4_195 occurs, for example. when the engine's king is captured
        // (-4000), and the player captures an engine's queen on index 35 (-181) with knight from
        // index 52 (-14).
        int256 bestScore = -4_196;
        int256 currentScore;
        uint256 bestMove;

        unchecked {
            for (uint256 i; moves[i] != 0; ++i) {
                for (uint256 movePartition = moves[i]; movePartition != 0; movePartition >>= 0xC) {
                    currentScore = _board.evaluateMove(movePartition & 0xFFF);
                    if (currentScore > bestScore) {
                        bestScore = currentScore;
                        bestMove = movePartition & 0xFFF;
                    }
                }
            }

            // If a king is captured, stop the recursive call stack and return a score of -4_000.
            // There is nothing more to consider.
            if (((_board >> ((bestMove & 0x3F) << 2)) & 7) == 6) return -4_000;
            return _board & 1 == 0
                ? bestScore + negaMax(_board.applyMove(bestMove), _depth - 1)
                : -bestScore + negaMax(_board.applyMove(bestMove), _depth - 1);
        }
    }

    /// @notice Uses piece-square tables (PSTs) to evaluate how ``good'' a move is.
    /// @dev The PSTs were selected semi-arbitrarily with chess strategies in mind (e.g. pawns are
    /// good in the center). Updating them changes the way the engine ``thinks.'' Each piece's PST
    /// is bitpacked into as few uint256s as possible for efficiency (see {Engine-getPst} and
    /// {Engine-getPstTwo}):
    ///          Pawn                Bishop               Knight                   Rook
    ///    20 20 20 20 20 20    62 64 64 64 64 62    54 56 54 54 56 58    100 100 100 100 100 100
    ///    30 30 30 30 30 30    64 66 66 66 66 64    56 60 64 64 60 56    101 102 102 102 102 101
    ///    20 22 24 24 22 20    64 67 68 68 67 64    58 64 68 68 64 58     99 100 100 100 100  99
    ///    21 20 26 26 20 21    64 68 68 68 68 64    58 65 68 68 65 58     99 100 100 100 100  99
    ///    21 30 16 16 30 21    64 67 66 66 67 64    56 60 65 65 60 56     99 100 100 100 100  99
    ///    20 20 20 20 20 20    62 64 64 64 64 62    54 56 58 58 56 54    100 100 101 101 100 100
    ///                            Queen                         King
    ///                   176 178 179 179 178 176    3994 3992 3990 3990 3992 3994
    ///                   178 180 180 180 180 178    3994 3992 3990 3990 3992 3994
    ///                   179 180 181 181 180 179    3996 3994 3992 3992 3994 3995
    ///                   179 181 181 181 180 179    3998 3996 3996 3996 3996 3998
    ///                   178 180 181 180 180 178    4001 4001 4000 4000 4001 4001
    ///                   176 178 179 179 178 176    4004 4006 4002 4002 4006 4004
    /// All entries in the figure above are in decimal representation.
    ///
    /// Each entry in the pawn's, bishop's, knight's, and rook's PSTs uses 7 bits, and each entry in
    /// the queen's and king's PSTs uses 12 bits. Additionally, each piece is valued as following:
    ///                                      | Type   | Value |
    ///                                      | ------ | ----- |
    ///                                      | Pawn   | 20    |
    ///                                      | Bishop | 66    |
    ///                                      | Knight | 64    |
    ///                                      | Rook   | 100   |
    ///                                      | Queen  | 180   |
    ///                                      | King   | 4000  |
    /// The king's value just has to be sufficiently larger than 180 * 7 = 1260 (i.e. equivalent to
    /// 7 queens) because check/checkmates are detected lazily (see {Engine-generateMoves}).
    ///
    /// The evaluation of a move is given by
    ///                Δ(PST value of the moved piece) + (PST value of any captured pieces).
    /// @param _board The board to apply the move to.
    /// @param _move The move to evaluate.
    /// @return The evaluation of the move applied to the given position.
    function evaluateMove(uint256 _board, uint256 _move) internal pure returns (int256) {
        unchecked {
            uint256 fromIndex = 6 * (_move >> 9) + ((_move >> 6) & 7) - 7;
            uint256 toIndex = 6 * ((_move & 0x3F) >> 3) + ((_move & 0x3F) & 7) - 7;
            uint256 pieceAtFromIndex = (_board >> ((_move >> 6) << 2)) & 7;
            uint256 pieceAtToIndex = (_board >> ((_move & 0x3F) << 2)) & 7;
            uint256 oldPst;
            uint256 newPst;
            uint256 captureValue;

            if (pieceAtToIndex != 0) {
                if (pieceAtToIndex < 5) { // Piece is not a queen or king
                    captureValue = (getPst(pieceAtToIndex) >> (7 * (0x23 - toIndex))) & 0x7F;
                } else if (toIndex < 0x12) { // Piece is queen or king and in the closer half
                    captureValue = (getPst(pieceAtToIndex) >> (0xC * (0x11 - toIndex))) & 0xFFF;
                } else { // Piece is queen or king and in the further half
                    captureValue = (getPstTwo(pieceAtToIndex) >> (0xC * (0x23 - toIndex))) & 0xFFF;
                }
            }
            if (pieceAtFromIndex < 5) { // Piece is not a queen or king
                oldPst = (getPst(pieceAtFromIndex) >> (7 * fromIndex)) & 0x7F;
                newPst = (getPst(pieceAtFromIndex) >> (7 * toIndex)) & 0x7F;
            } else if (fromIndex < 0x12) { // Piece is queen or king and in the closer half
                oldPst = (getPstTwo(pieceAtFromIndex) >> (0xC * fromIndex)) & 0xFFF;
                newPst = (getPstTwo(pieceAtFromIndex) >> (0xC * toIndex)) & 0xFFF;
            } else { // Piece is queen or king and in the further half
                oldPst = (getPst(pieceAtFromIndex) >> (0xC * (fromIndex - 0x12))) & 0xFFF;
                newPst = (getPst(pieceAtFromIndex) >> (0xC * (toIndex - 0x12))) & 0xFFF;
            }

            return int256(captureValue + newPst) - int256(oldPst);
        }
    }

    /// @notice Maps a given piece type to its PST (see {Engine-evaluateMove} for details on the
    /// PSTs and {Chess} for piece representation).
    /// @dev The queen's and king's PSTs do not fit in 1 uint256, so their PSTs are split into 2
    /// uint256s each. {Chess-getPst} contains the first half, and {Chess-getPstTwo} contains the
    /// second half.
    /// @param _type A piece type defined in {Chess}.
    /// @return The PST corresponding to `_type`.
    function getPst(uint256 _type) internal pure returns (uint256) {
        if (_type == 1) return 0x2850A142850F1E3C78F1E2858C182C50A943468A152A788103C54A142850A14;
        if (_type == 2) return 0x7D0204080FA042850A140810E24487020448912240810E1428701F40810203E;
        if (_type == 3) return 0xC993264C9932E6CD9B365C793264C98F1E4C993263C793264C98F264CB97264;
        if (_type == 4) return 0x6CE1B3670E9C3C8101E38750224480E9D4189120BA70F20C178E1B3874E9C36;
        if (_type == 5) return 0xB00B20B30B30B20B00B20B40B40B40B40B20B30B40B50B50B40B3;
        return 0xF9AF98F96F96F98F9AF9AF98F96F96F98F9AF9CF9AF98F98F9AF9B;
    }

    /// @notice Maps a queen or king to the second half of its PST (see {Engine-getPst}).
    /// @param _type A piece type defined in {Chess}. Must be a queen or a king (see
    /// {Engine-getPst}).
    /// @return The PST corresponding to `_type`.
    function getPstTwo(uint256 _type) internal pure returns (uint256) {
        return _type == 5
            ? 0xB30B50B50B50B40B30B20B40B50B40B40B20B00B20B30B30B20B0
            : 0xF9EF9CF9CF9CF9CF9EFA1FA1FA0FA0FA1FA1FA4FA6FA2FA2FA6FA4;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import { Chess } from "./Chess.sol";
import { Base64 } from "./Base64.sol";

/// @title A library that generates HTML art for fiveoutofnine (an on-chain 6x6 chess engine)
/// @author fiveoutofnine
/// @notice Below details how the metadata and art are generated:
/// ==============================================Name==============================================
/// Expressed as Python3 f-strings below, token names generate as
///                     ``f"fiveoutofnine - Game #{game_id}, Move #{move_id}"''.
/// ==========================================Description===========================================
/// Token descriptions describe white's move in algebraic notation and black's move in algebraic
/// notation. If white's move results in checkmating black or a stalemate, the description will say
/// black resigned (for simplicity, stalemates are treated as checkmates). Since the engine always
/// plays black, and the player always plays white, white is indicated as ``Player'', and black is
/// indicated as ``fiveoutofnine''. Additionally, for every non game-ending turn, a string graphic
/// is generated after the moves' descriptions. An example:
///                             Player plays e4 rook captures e5 queen.
///                             6 · · ♜ · ♚ ♜
///                             5 · ♟ · · ♖ ♟
///                             4 ♟ ♙ ♟ ♙ * ♙
///                             3 ♙ · ♙ · · ·
///                             2 · · · · ♖ ·
///                             1 · ♘ · ♔ · ·
///                               a b c d e f
///
///                             fiveoutofnine resigns.
/// * indicates the square the piece moved from.
/// ==============================================Art===============================================
/// The art is generated as HTML code with in-line CSS (0 JS) according to the following table:
///  | Property       | Name      | Value/Description                       | Determination       |
///  | ============== | ========= | ======================================= | =================== |
///  | Dimension      | 1 × 1     | 1 × 1 pillars                           | Player moved king   |
///  | (6 traits)     | 2 × 2     | 2 × 2 pillars                           | Player moved rook   |
///  |                | 3 × 3     | 3 × 3 pillars                           | Engine moved bishop |
///  |                | 4 × 4     | 4 × 4 pillars                           | Player moved knight |
///  |                | 6 × 6     | 6 × 6 pillars                           | Player moved pawn   |
///  |                | 12 × 12   | 12 × 12 pillars                         | Player moved queen  |
///  | -------------- | --------- | --------------------------------------- | ------------------- |
///  | Height         | Plane     | 8px pillar height                       | 1 / 64 chance[^0]   |
///  | (5 traits)     | 1/4       | 98px pillar height                      | 10 / 64 chance[^0]  |
///  |                | 1/2       | 197px pillar height                     | 10 / 64 chance[^0]  |
///  |                | Cube      | 394px pillar height                     | 40 / 64 chance[^0]  |
///  |                | Infinite  | 1000px pillar height                    | 3 / 64 chance[^0]   |
///  | -------------- | --------- | --------------------------------------- | ------------------- |
///  | Gap[^1]        | None      | 0px gap between the pillars             | 4 / 16 chance[^0]   |
///  | (4 traits)     | Narrow    | 2px gap between the pillars             | 9 / 16 chance[^0]   |
///  |                | Wide      | 12px gap between the pillars            | 2 / 16 chance[^0]   |
///  |                | Ultrawide | 24px gap between the pillars            | 1 / 16 chance[^0]   |
///  | -------------- | --------- | --------------------------------------- | ------------------- |
///  | Color          | Uniform   | All faces are the same color            | 7 / 32 chance[^0]   |
///  | Generation[^2] | Shades    | Faces get darker anticlockwise          | 7 / 32 chance[^0]   |
///  | (6 traits)     | Tints     | Faces get lighter anticlockwise         | 7 / 32 chance[^0]   |
///  |                | Eclipse   | Left face is white; black face is black | 3 / 32 chance[^0]   |
///  |                | Void      | Left and right face are black           | 1 / 32 chance[^0]   |
///  |                | Curated   | One of 8 color themes (see below)       | 7 / 32 chance[^0]   |
///  | -------------- | --------- | --------------------------------------- | ------------------- |
///  | Color          | Nord      | 0x8FBCBBEBCB8BD087705E81ACB48EAD        | 1 / 8 chance[^0]    |
///  | Theme[^3]      | B/W       | 0x000000FFFFFFFFFFFFFFFFFF000000        | 1 / 8 chance[^0]    |
///  | (8 traits)     | Candycorn | 0x0D3B66F4D35EEE964BFAF0CAF95738        | 1 / 8 chance[^0]    |
///  |                | RGB       | 0xFFFF0000FF000000FFFF0000FFFF00        | 1 / 8 chance[^0]    |
///  |                | VSCode    | 0x1E1E1E569CD6D2D1A2BA7FB54DC4AC        | 1 / 8 chance[^0]    |
///  |                | Neon      | 0x00FFFFFFFF000000FF00FF00FF00FF        | 1 / 8 chance[^0]    |
///  |                | Jungle    | 0xBE3400015045020D22EABAACBE3400        | 1 / 8 chance[^0]    |
///  |                | Corn      | 0xF9C233705860211A28346830F9C233        | 1 / 8 chance[^0]    |
///  | -------------- | --------- | --------------------------------------- | ------------------- |
///  | Bit Border[^4] | True      | The bits have a 1px solid black border  | Any pieces captured |
///  | (2 traits)     | False     | The bits don't have any border          | No pieces captuered |
///  | ============== | ========= | ======================================= | =================== |
///  | [^0]: Determined from `_seed`.                                                             |
///  | [^1]: Gap is omitted when dimension is 1 x 1.                                              |
///  | [^2]: The first 5 color generation traits are algorithms. A base color is generated from   |
///  | `seed`, and the remaining colors are generated according to the selected algorithm. The    |
///  | color of the bits is always the complement of the randomly generated base color, and the   |
///  | background color depends on the algorithm:                                                 |
///  |     * Uniform: same as the base color;                                                     |
///  |     * Shades: darkest shade of the base color;                                             |
///  |     * Tints: lightest shade of the base color;                                             |
///  |     * Eclipse: same as the base color;                                                     |
///  |     * Void: complement of the base color.                                                  |
///  | If the selected color generation trait is "Curated," 1 of 8 pre-curated themes is randomly |
///  | selected.                                                                                  |
///  | [^3]: The entries in the 3rd column are bitpacked integers where                           |
///  |     * the first 24 bits represent the background color,                                    |
///  |     * the second 24 bits represent the left face's color,                                  |
///  |     * the third 24 bits represent the right face's color,                                  |
///  |     * the fourth 24 bits represent the top face's color,                                   |
///  |     * and the last 24 bits represent the bits' color.                                      |
///  | [^4]: Bit border is omitted when dimension is 12 x 12.                                     |
library fiveoutofnineART {
    using Strings for uint256;
    using Chess for uint256;

    string internal constant SVG_STYLES = "--n:calc((394px - (var(--b) - 1)*var(--c))/var(--b));--o"
        ":calc(106px + var(--n));--p:calc(var(--a)/2)}section{height:var(--a);width:var(--a);backgr"
        "ound:var(--e);position:absolute;left:0;top:0;right:0;bottom:0;overflow:hidden}.c{height:0;"
        "width:0;position:absolute;transition:0.25s}.c:hover{transform:translate(0px,-64px);transit"
        "ion:0.25s}.c>*{height:var(--n);width:var(--n);border-bottom:4px solid black;border-right:4"
        "px solid black;border-left:1px solid black;border-top:1px solid black;transform-origin:0 0"
        ";position:relative;box-sizing:border-box}.c>*:nth-child(1){width:var(--d);background-color"
        ":var(--f);transform:rotate(90deg)skewX(-30deg)scaleY(0.864)}.c>*:nth-child(2){height:var(-"
        "-d);bottom:var(--n);background-color:var(--g);transform:rotate(-30deg)skewX(-30deg)scaleY("
        "0.864)}#h{background-color:var(--h)}#i{background-color:var(--i)}.c>*:nth-child(3){bottom:"
        "calc(var(--d) + var(--n));background-color:var(--h);display:grid;grid-template-columns:rep"
        "eat(";
    bytes32 internal constant HEXADECIMAL_DIGITS = "0123456789ABCDEF";
    bytes32 internal constant FILE_NAMES = "abcdef";

    /// @notice Takes in data for a given fiveoutofnine NFT and outputs its metadata in JSON form.
    /// Refer to {fiveoutofnineART} for details.
    /// @dev The output is base 64-encoded.
    /// @param _internalId A bitpacked uint256 where the first 128 bits are the game ID, and the
    /// last 128 bits are the move ID within the game.
    /// @param _move A struct with information about the player's move and engine's response (see
    /// {Chess-Move}).
    /// @return Base 64-encoded JSON of metadata generated from `_internalId` and `_move`.
    function getMetadata(uint256 _internalId, Chess.Move memory _move)
        internal pure
        returns (string memory)
    {
        string memory description;
        string memory image;
        string memory attributes;
        uint256 whiteMove;
        uint256 blackMove;
        uint256 boardAfterWhiteMove;
        uint256 boardAfterBlackMove;
        bool whiteCaptures;
        bool blackCaptures;
        uint256 depth;

        {
            whiteMove = (_move.metadata >> 0xC) & 0xFFF;
            blackMove = _move.metadata & 0xFFF;

            boardAfterWhiteMove = _move.board.applyMove(whiteMove);
            boardAfterBlackMove = boardAfterWhiteMove.applyMove(blackMove);

            whiteCaptures = _move.board.isCapture(
                _move.board >> ((whiteMove & 0x3F) << 2)
            );
            blackCaptures = boardAfterWhiteMove.isCapture(
                boardAfterWhiteMove >> ((blackMove & 0x3F) << 2)
            );

            depth = _move.metadata >> 0x18;
        }

        {
            uint256 numSquares;
            {
                uint256 whitePieceType = (_move.board >> ((whiteMove >> 6) << 2)) & 7;
                uint256 blackPieceType = (boardAfterWhiteMove >> ((blackMove >> 6) << 2)) & 7;

                if (whitePieceType == 1) numSquares = 6;
                else if (whitePieceType == 3) numSquares = 2;
                else if (whitePieceType == 4) numSquares = 4;
                else if (whitePieceType == 5) numSquares = 12;
                else numSquares = 1;
                if (blackPieceType == 2) numSquares = 3;
            }

            uint256 seed = uint256(
                keccak256(abi.encodePacked(_internalId, boardAfterBlackMove, _move.metadata))
            );

            (image, attributes) = getImage(
                boardAfterBlackMove,
                numSquares,
                seed,
                whiteCaptures || blackCaptures
            );
        }

        // Lots of unusual identation and braces to get around the 16 local variable limitation.
        {
            description = string(
                abi.encodePacked(
                    "---\\n\\n**Player** plays **`",
                    indexToPosition(whiteMove >> 6, true),
                    "` ",
                    getPieceName((_move.board >> ((whiteMove >> 6) << 2)) & 7),
                    "**",
                    whiteCaptures
                        ? " captures "
                        : " to ",
                    "**`",
                    indexToPosition(whiteMove & 0x3F, true)
                )
            );
        }
        {
            description = string(
                abi.encodePacked(
                    description,
                    "`",
                    whiteCaptures
                        ? " "
                        : "",
                    whiteCaptures
                        ? getPieceName((_move.board >> ((whiteMove & 0x3F) << 2)) & 7)
                        : "",
                    "**.\\n\\n",
                    drawMove(boardAfterWhiteMove, whiteMove >> 6),
                    "\\n\\n---\\n\\n**fiveoutofnine** "
                )
            );
        }

        {
            if (blackMove == 0) {
                description = string(abi.encodePacked(description, "**resigns**."));
            } else {
                description = string(
                    abi.encodePacked(
                        description,
                        "responds with **`",
                        indexToPosition(blackMove >> 6, false),
                        "` ",
                        getPieceName((boardAfterWhiteMove >> ((blackMove >> 6) << 2)) & 7),
                        "**",
                        blackCaptures
                            ? " captures "
                            : " to ",
                        "**`",
                        indexToPosition(blackMove & 0x3F, false),
                        "`",
                        blackCaptures
                            ? " "
                            : "",
                        blackCaptures
                            ? getPieceName((boardAfterWhiteMove>> ((blackMove & 0x3F) << 2)) & 7)
                            : "",
                        "**.\\n\\n",
                        drawMove(boardAfterBlackMove, blackMove >> 6)
                    )
                );
            }
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Game #',
                        Strings.toString(_internalId >> 0x80),
                        ", Move #",
                        Strings.toString(uint128(_internalId)),
                        '",'
                        '"description":"',
                        description,
                        '","animation_url":"data:text/html;base64,',
                        image,
                        '","attributes":[{"trait_type":"Depth","value":',
                        depth.toString(),
                        "},",
                        attributes,
                        "]}"
                    )
                )
            )
        );
    }

    /// @notice Generates the HTML image and its attributes for a given board/seed according to the
    /// table described in {fiveoutofnineART}.
    /// @dev The output of the image is base 64-encoded.
    /// @param _board The board after the player's and engine's move are played.
    /// @param _numSquares The dimension of the board.
    /// @param _seed A hash of the game ID, move ID, board position, and metadata.
    /// @param _pieceCaptured Whether or not any piees were captured.
    /// @return Base 64-encoded image (in HTML) and its attributes.
    function getImage(uint256 _board, uint256 _numSquares, uint256 _seed, bool _pieceCaptured)
        internal pure
        returns (string memory, string memory)
    {
        string memory attributes = string(
            abi.encodePacked(
                '{"trait_type":"Dimension","value":"',
                _numSquares.toString(),
                unicode" × ",
                _numSquares.toString(),
                '"}'
            )
        );
        string memory styles = string(
            abi.encodePacked(
                "<style>:root{--a:1000px;--b:",
                _numSquares.toString(),
                ";--c:"
            )
        );

        {
            string memory tempAttribute;
            string memory tempValue = "0";
            if (_numSquares != 1) {
                if (_seed & 0xF < 4) { (tempAttribute, tempValue) = ("None", "0"); }
                else if (_seed & 0xF < 13) { (tempAttribute, tempValue) = ("Narrow", "2"); }
                else if (_seed & 0xF < 15) { (tempAttribute, tempValue) = ("Wide", "12"); }
                else { (tempAttribute, tempValue) = ("Ultrawide", "24"); }

                attributes = string(
                    abi.encodePacked(
                        attributes,
                        ',{"trait_type":"Gap","value":"',
                        tempAttribute,
                        '"}'
                    )
                );
            }
            styles = string(abi.encodePacked(styles, tempValue, "px;--d:"));
        }
        _seed >>= 4;

        {
            string memory tempAttribute;
            string memory tempValue;
            if (_seed & 0x3F < 1) { (tempAttribute, tempValue) = ("Plane", "8"); }
            else if (_seed & 0x3F < 11) { (tempAttribute, tempValue) = ("1/4", "98"); }
            else if (_seed & 0x3F < 21) { (tempAttribute, tempValue) = ("1/2", "197"); }
            else if (_seed & 0x3F < 51) { (tempAttribute, tempValue) = ("Cube", "394"); }
            else { (tempAttribute, tempValue) = ("Infinite", "1000"); }

            attributes = string(
                abi.encodePacked(
                    attributes,
                    ',{"trait_type":"Height","value":"',
                    tempAttribute,
                    '"}'
                )
            );
            styles = string(abi.encodePacked(styles, tempValue, "px;"));
        }
        _seed >>= 6;

        {
            string memory tempAttribute;
            uint256 colorTheme;
            if (_seed & 0x1F < 25) {
                colorTheme = (_seed >> 5) & 0xFFFFFF;
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        ',{"trait_type":"Base Color","value":',
                        colorTheme.toString(),
                        "}"
                    )
                );
                if (_seed & 0x1F < 7) {
                    tempAttribute = "Uniform";
                    colorTheme = (colorTheme << 0x60)
                        | (colorTheme << 0x48)
                        | (colorTheme << 0x30)
                        | (colorTheme << 0x18)
                        | complementColor(colorTheme);
                } else if (_seed & 0x1F < 14) {
                    tempAttribute = "Shades";
                    colorTheme = (darkenColor(colorTheme, 3) << 0x60)
                        | (darkenColor(colorTheme, 1) << 0x48)
                        | (darkenColor(colorTheme, 2) << 0x30)
                        | (colorTheme << 0x18)
                        | complementColor(colorTheme);
                } else if (_seed & 0x1F < 21) {
                    tempAttribute = "Tints";
                    colorTheme = (brightenColor(colorTheme, 3) << 0x60)
                        | (brightenColor(colorTheme, 1) << 0x48)
                        | (brightenColor(colorTheme, 2) << 0x30)
                        | (colorTheme << 0x18)
                        | complementColor(colorTheme);
                } else if (_seed & 0x1F < 24) {
                    tempAttribute = "Eclipse";
                    colorTheme = (colorTheme << 0x60)
                        | (0xFFFFFF << 0x48)
                        | (colorTheme << 0x18)
                        | complementColor(colorTheme);
                } else {
                    tempAttribute = "Void";
                    colorTheme = (complementColor(colorTheme) << 0x60)
                        | (colorTheme << 0x18)
                        | complementColor(colorTheme);
                }
            } else {
                tempAttribute = "Curated";
                _seed >>= 5;

                attributes = string(
                    abi.encodePacked(
                        attributes,
                        ',{"trait_type":"Color Theme","value":"',
                        ["Nord", "B/W", "Candycorn", "RGB", "VSCode", "Neon", "Jungle", "Corn"]
                        [_seed & 7],
                        '"}'
                    )
                );

                colorTheme = [
                    0x8FBCBBEBCB8BD087705E81ACB48EAD000000FFFFFFFFFFFFFFFFFF000000,
                    0x0D3B66F4D35EEE964BFAF0CAF95738FFFF0000FF000000FFFF0000FFFF00,
                    0x1E1E1E569CD6D2D1A2BA7FB54DC4AC00FFFFFFFF000000FF00FF00FF00FF,
                    0xBE3400015045020D22EABAACBE3400F9C233705860211A28346830F9C233
                ][(_seed & 7) >> 1];
                colorTheme = _seed & 1 == 0
                    ? colorTheme >> 0x78
                    : colorTheme & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            }
            attributes = string(
                abi.encodePacked(
                    attributes,
                    ',{"trait_type":"Color Generation","value":"',
                    tempAttribute,
                    '"}'
                )
            );
            styles = string(
                abi.encodePacked(
                    styles,
                    "--e:",
                    toColorHexString(colorTheme >> 0x60),
                    ";--f:",
                    toColorHexString((colorTheme >> 0x48) & 0xFFFFFF),
                    ";--g:",
                    toColorHexString((colorTheme >> 0x30) & 0xFFFFFF),
                    ";--h:",
                    toColorHexString((colorTheme >> 0x18) & 0xFFFFFF),
                    ";--i:",
                    toColorHexString(colorTheme & 0xFFFFFF),
                    ";"
                )
            );
        }

        {
            string memory tempAttribute;
            styles = string(
                abi.encodePacked(
                    styles,
                    SVG_STYLES,
                    Strings.toString(12 / _numSquares),
                    ",1fr);grid-template-rows:repeat(",
                    Strings.toString(12 / _numSquares),
                    ",1fr);transform:rotate(210deg)skew(-30deg)scaleY(0.864)}"
                )
            );
            if (_numSquares != 12) {
                if (_pieceCaptured) {
                    tempAttribute = "True";
                    styles = string(
                        abi.encodePacked(
                            styles,
                            ".c>*:nth-child(3)>div{border: 1px solid black}"
                        )
                    );
                } else {
                    tempAttribute = "False";
                }
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        ',{"trait_type":"Bit Border","value":"',
                        tempAttribute,
                        '"}'
                    )
                );
            }
        }

        unchecked {
            for (uint256 i; i < 23; ++i) {
                styles = string(
                    abi.encodePacked(
                        styles,
                        ".r",
                        i.toString(),
                        "{top:calc(var(--o) + ",
                        i.toString(),
                        "*(var(--n)/2 + var(--c)))}"
                        ".c",
                        i.toString(),
                        "{left:calc(var(--p) ",
                        i < 11 ? "-" : "+",
                        " 0.866*",
                        i < 11 ? (11 - i).toString() : (i - 11).toString(),
                        "*(var(--n) + var(--c)))}"
                    )
                );
            }

            string memory image;
            for (uint256 row; row < (_numSquares << 1) - 1; ++row) {
                uint256 tempCol = row <= _numSquares - 1
                    ? 11 - row
                    : 11 - ((_numSquares << 1) - 2 - row);
                for (
                    uint256 col = tempCol;
                    col <= (row <= _numSquares - 1
                        ? tempCol + (row << 1)
                        : tempCol + (((_numSquares << 1) - 2 - row) << 1));
                    col = col + 2
                ) {
                    image = string(
                        abi.encodePacked(
                            image,
                            getPillarHtml(_board, 12 / _numSquares, row, col)
                        )
                    );
                }
            }

            return (
                Base64.encode(
                    abi.encodePacked(
                        styles,
                        "</style><section>",
                        image,
                        "</section>"
                    )
                ),
                attributes
            );
        }
    }

    /// @notice Returns the HTML for a particular pillar within the image.
    /// @param _board The board after the player's and engine's move are played.
    /// @param _dim The dimension of the bits within a pillar.
    /// @param _row The row index of the pillar.
    /// @param _col The column index of the pillar.
    /// @return The HTML for the pillar described by the parameters.
    function getPillarHtml(uint256 _board, uint256 _dim, uint256 _row, uint256 _col)
        internal pure
        returns (string memory)
    {
        string memory pillar = string(
            abi.encodePacked(
                '<div class="c r',
                _row.toString(),
                " c",
                _col.toString(),
                '"><div></div><div></div><div>'
            )
        );

        uint256 x;
        uint256 y;
        uint256 colOffset;
        uint256 rowOffset;
        unchecked {
            for (
                uint256 subRow = _row * _dim + ((_dim - 1) << 1);
                subRow >= _row * _dim + (_dim - 1);
                --subRow
            ) {
                rowOffset = 0;
                uint256 tempSubCol = _col <= 11
                    ? 11 - _dim * (11 - _col) + colOffset
                    : 11 + _dim * (_col - 11) + colOffset;
                for (
                    uint256 subCol = tempSubCol;
                    subCol >= tempSubCol + 1 - _dim;
                    --subCol
                ) {
                    x = 11 - ((11 + subCol - (subRow - rowOffset)) >> 1);
                    y = 16 - ((subCol + subRow - rowOffset) >> 1);
                    pillar = string(
                        abi.encodePacked(
                            pillar,
                            '<div id="',
                            (
                                _board
                                >> (Chess.getAdjustedIndex(6 * (y >> 1) + (x >> 1)) << 2)
                                >> (((0xD8 >> ((x & 1) << 2)) >> ((y & 1) << 1)) & 3)
                            )
                            & 1 == 0
                                ? "h"
                                : "i",
                            '"></div>'
                        )
                    );
                    rowOffset++;
                    if (subCol == 0) { break; }
                }
                colOffset++;
                if (subRow == 0) { break; }
            }
        }

        return string(abi.encodePacked(pillar, "</div></div>"));
    }

    /// @notice Draws out a move being played out on a board position as a string with unicode
    /// characters to represent pieces. Files and rows are labeled with standard algebraic
    /// notation. For example:
    /// ```
    /// 6 ♜ ♝ ♛ ♚ ♝ ♜
    /// 5 ♟ ♟ ♟ ♟ ♟ ♟
    /// 4 · · · · · ·
    /// 3 · · ♙ · · ·
    /// 2 ♙ ♙ * ♙ ♙ ♙
    /// 1 ♖ ♘ ♕ ♔ ♘ ♖
    ///  a b c d e f
    /// ```
    /// * indicates the square the piece moved from.
    /// @param _board The board the move is played on.
    /// @param _fromIndex The from index of the move.
    /// @return The string showing the move played out on the board.
    function drawMove(uint256 _board, uint256 _fromIndex) internal pure returns (string memory) {
        string memory boardString = "```\\n";

        if (_board & 1 == 0) _board = _board.rotate();
        else _fromIndex = ((7 - (_fromIndex >> 3)) << 3) + (7 - (_fromIndex & 7));

        for (
            uint256 index = 0x24A2CC34E4524D455665A6DC75E8628E4966A6AAECB6EC72CF4D76;
            index != 0;
            index >>= 6
        ) {
            uint256 indexToDraw = index & 0x3F;
            boardString = string(
                abi.encodePacked(
                    boardString,
                    indexToDraw & 7 == 6
                        ? string(abi.encodePacked(Strings.toString((indexToDraw >> 3)), " "))
                        : "",
                    indexToDraw == _fromIndex
                        ? "*"
                        : getPieceChar((_board >> (indexToDraw << 2)) & 0xF),
                    indexToDraw & 7 == 1 && indexToDraw != 9
                        ? "\\n"
                        : indexToDraw != 9
                            ? " "
                            : ""
                )
            );
        }

        boardString = string(
            abi.encodePacked(
                boardString,
                "\\n  a b c d e f\\n```"
                )
            );

        return boardString;
    }

    /// @notice Computes the complement of 24-bit colors.
    /// @param _color A 24-bit color.
    /// @return The complement of `_color`.
    function complementColor(uint256 _color) internal pure returns (uint256) {
        unchecked {
            return 0xFFFFFF - _color;
        }
    }

    /// @notice Darkens 24-bit colors.
    /// @param _color A 24-bit color.
    /// @param _num The number of shades to darken by.
    /// @return `_color` darkened `_num` times.
    function darkenColor(uint256 _color, uint256 _num) internal pure returns (uint256) {
        return (((_color >> 0x10) >> _num) << 0x10)
            | ((((_color >> 8) & 0xFF) >> _num) << 8)
            | ((_color & 0xFF) >> _num);
    }

    /// @notice Brightens 24-bit colors.
    /// @param _color A 24-bit color.
    /// @param _num The number of tints to brighten by.
    /// @return `_color` brightened `_num` times.
    function brightenColor(uint256 _color, uint256 _num) internal pure returns (uint256) {
        unchecked {
            return ((0xFF - ((0xFF - (_color >> 0x10)) >> _num)) << 0x10)
                | ((0xFF - ((0xFF - ((_color >> 8) & 0xFF)) >> _num)) << 8)
                | (0xFF - ((0xFF - (_color & 0xFF)) >> _num));
        }
    }

    /// @notice Returns the color hex string of a 24-bit color.
    /// @param _integer A 24-bit color.
    /// @return The color hex string of `_integer`.
    function toColorHexString(uint256 _integer) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "#",
                HEXADECIMAL_DIGITS[(_integer >> 0x14) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 0x10) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 0xC) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 8) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 4) & 0xF],
                HEXADECIMAL_DIGITS[_integer & 0xF]
            )
        );
    }

    /// @notice Maps piece type to its corresponding name.
    /// @param _type A piece type defined in {Chess}.
    /// @return The name corresponding to `_type`.
    function getPieceName(uint256 _type) internal pure returns (string memory) {
        if (_type == 1) return "pawn";
        else if (_type == 2) return "bishop";
        else if (_type == 3) return "rook";
        else if (_type == 4) return "knight";
        else if (_type == 5) return "queen";
        return "king";
    }

    /// @notice Converts a position's index to algebraic notation.
    /// @param _index The index of the position.
    /// @param _isWhite Whether the piece is being determined for a white piece or not.
    /// @return The algebraic notation of `_index`.
    function indexToPosition(uint256 _index, bool _isWhite) internal pure returns (string memory) {
        unchecked {
            return _isWhite
                ? string(
                    abi.encodePacked(
                        FILE_NAMES[6 - (_index & 7)],
                        Strings.toString(_index >> 3))
                )
                : string(
                    abi.encodePacked(
                        FILE_NAMES[(_index & 7) - 1],
                        Strings.toString(7 - (_index >> 3))
                    )
                );
        }
    }

    /// @notice Maps pieces to its corresponding unicode character.
    /// @param _piece A piece.
    /// @return The unicode character corresponding to `_piece`. It returns ``.'' otherwise.
    function getPieceChar(uint256 _piece) internal pure returns (string memory) {
        if (_piece == 1) return unicode"♟";
        if (_piece == 2) return unicode"♝";
        if (_piece == 3) return unicode"♜";
        if (_piece == 4) return unicode"♞";
        if (_piece == 5) return unicode"♛";
        if (_piece == 6) return unicode"♚";
        if (_piece == 9) return unicode"♙";
        if (_piece == 0xA) return unicode"♗";
        if (_piece == 0xB) return unicode"♖";
        if (_piece == 0xC) return unicode"♘";
        if (_piece == 0xD) return unicode"♕";
        if (_piece == 0xE) return unicode"♔";
        return unicode"·";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
pragma solidity ^0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz012345678"
        "9+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLength = ((data.length + 2) / 3) << 2;
        string memory result = new string(encodedLength + 0x20);

        assembly {
            mstore(result, encodedLength)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 0x20)
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               let input := mload(dataPtr)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0x12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0xC, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(input, 0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(0xF0, 0x3D3D)) }
            case 2 { mstore(sub(resultPtr, 1), shl(0xF8, 0x3D)) }
        }

        return result;
    }
}