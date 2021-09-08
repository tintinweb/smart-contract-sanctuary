// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

import "./ERC721Virtual.sol";
import "./ISyntheticLoot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/////////////////////////////////////////////////////////////////
//   _    ___      __              __   __                __   //
//  | |  / (_)____/ /___  ______ _/ /  / /   ____  ____  / /_  //
//  | | / / / ___/ __/ / / / __ `/ /  / /   / __ \/ __ \/ __/  //
//  | |/ / / /  / /_/ /_/ / /_/ / /  / /___/ /_/ / /_/ / /_    //
//  |___/_/_/   \__/\__,_/\__,_/_/  /_____/\____/\____/\__/    //
//                                                             //
//  Mintable Synthetic Loot                                    //
//  https://twitter.com/dhof/status/1433110412187287560?s=20   //
//                                                             //
/////////////////////////////////////////////////////////////////

contract VirtualLoot is ERC721Virtual, Ownable {

    ISyntheticLoot private _syntheticLoot;

    constructor (address syntheticLootAddress) ERC721Virtual("VirtualLoot", "vLOOT") {
        _syntheticLoot = ISyntheticLoot(syntheticLootAddress);
    }

    function mintLoot() external {
        _mint(msg.sender, uint256(uint160(msg.sender)));
    }

    function burnLoot(address walletAddress) external {
        uint256 tokenId = uint256(uint160(walletAddress));
        require(_isApprovedOrOwner(_msgSender(), tokenId), "VirtualLoot: burn caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _syntheticLoot.tokenURI(ownerOf(tokenId));
    }

    function weaponComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.weaponComponents(walletAddress);
    }
    
    function chestComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.chestComponents(walletAddress);
    }
    
    function headComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.headComponents(walletAddress);
    }
    
    function waistComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.waistComponents(walletAddress);
    }

    function footComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.footComponents(walletAddress);
    }
    
    function handComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.handComponents(walletAddress);
    }
    
    function neckComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.neckComponents(walletAddress);
    }
    
    function ringComponents(address walletAddress) public view returns (uint256[5] memory) {
        return _syntheticLoot.ringComponents(walletAddress);
    }
    
    function getWeapon(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getWeapon(walletAddress);
    }
    
    function getChest(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getChest(walletAddress);
    }
    
    function getHead(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getHead(walletAddress);
    }
    
    function getWaist(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getWaist(walletAddress);
    }

    function getFoot(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getFoot(walletAddress);
    }
    
    function getHand(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getHand(walletAddress);
    }
    
    function getNeck(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getNeck(walletAddress);
    }
    
    function getRing(address walletAddress) public view returns (string memory) {
        return _syntheticLoot.getRing(walletAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author jpegmint.xyz

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 */
contract ERC721Virtual is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to minted bool status
    mapping(uint256 => bool) private _mintedTokens;

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
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Owners can have max 1 of virutal tokens.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721Virtual: balance query for the zero address");
        return 1;
    }

    /**
     * @dev Owner is always tokenId -> address
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(tokenId != 0, "ERC721Virtual: owner query for nonexistent token");
        return address(uint160(tokenId));
    }

    /**
     @dev Returns whether the token is minted or virtual
     */
    function isMinted(uint256 tokenId) public view virtual returns (bool) {
        return _mintedTokens[tokenId];
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
        return "";
    }

    /**
     * @dev Force use of this ownerOf function
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Virtual: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Virtual: approve caller is not owner nor approved for all"
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
    function transferFrom(address, address, uint256) public virtual override {
        revert("ERC721Virtual: Virtual tokens can not be transferred");
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
    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override {
        revert("ERC721Virtual: Virtual tokens can not be transferred");
    }

    /**
     * @dev Virtual tokens always exist either as virtual or minted
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId != 0;
    }

    /**
     * @dev Force use of this ownerOf function
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721Virtual: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`. safeMint not implemented as tokens are
     * not transferrable and virtual.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721Virtual: mint to the zero address");
        require(to == ownerOf(tokenId), "ERC721Virtual: only wallet can mint own virtual token");
        require(!isMinted(tokenId), "ERC721Virtual: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _mintedTokens[tokenId] = true;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     */
    function _burn(uint256 tokenId) internal virtual {
        require(isMinted(tokenId), "ERC721Virtual: token not minted");
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);
        _mintedTokens[tokenId] = false;

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    
    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index == 0, "ERC721Virtual: owner index out of bounds");
        return uint256(uint160(owner));
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return type(uint160).max;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Virtual: global index out of bounds");
        return index + 1;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/*

    Synthetic Loot
    
    This contract creates a "virtual NFT" of Loot based
    on a given wallet address. 
    
    Because the wallet address is used as the deterministic 
    seed, there can only be one Loot bag per wallet. 
    
    Because it's not a real NFT, there is no 
    minting, transferability, etc.
    
    Creators building on top of Loot can choose to recognize 
    Synthetic Loot as a way to allow a wider range of 
    adventurers to participate in the ecosystem, while
    still being able to differentiate between 
    "original" Loot and Synthetic Loot.
    
    Anyone with an Ethereum wallet has Synthetic Loot.
    
    -----
    
    Also optionally returns data in LootComponents format:
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.
    
    The original LootComponents contract is at address:
    0x3eb43b1545a360d1D065CB7539339363dFD445F3

*/

interface ISyntheticLoot {
    
    function tokenURI(address walletAddress) external view returns (string memory);
    
    function getWeapon(address walletAddress) external view returns (string memory);
    function getChest(address walletAddress) external view returns (string memory);
    function getHead(address walletAddress) external view returns (string memory);
    function getWaist(address walletAddress) external view returns (string memory);
    function getFoot(address walletAddress) external view returns (string memory);
    function getHand(address walletAddress) external view returns (string memory);
    function getNeck(address walletAddress) external view returns (string memory);
    function getRing(address walletAddress) external view returns (string memory);

    function weaponComponents(address walletAddress) external view returns (uint256[5] memory);
    function chestComponents(address walletAddress) external view returns (uint256[5] memory);
    function headComponents(address walletAddress) external view returns (uint256[5] memory);
    function waistComponents(address walletAddress) external view returns (uint256[5] memory);
    function footComponents(address walletAddress) external view returns (uint256[5] memory);
    function handComponents(address walletAddress) external view returns (uint256[5] memory);
    function neckComponents(address walletAddress) external view returns (uint256[5] memory);
    function ringComponents(address walletAddress) external view returns (uint256[5] memory);
}

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

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}