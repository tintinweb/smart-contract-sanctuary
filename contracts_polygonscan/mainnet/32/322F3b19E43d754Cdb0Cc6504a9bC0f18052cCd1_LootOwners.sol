//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LootOwners is Ownable {
  // Struct for updating the owners
  struct OwnerUpdate {
    address owner;
    uint256[] tokenIds;
  }

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    returns (uint256)
  {
    require(
      index < balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * The update should include entries for incoming owners and
   * any existing owners whose balances have changed
   *
   * It can also include entries for owners whose balances may not have
   * changed but haven't yet been indexed by the contract
   *
   * It's not necessary to include entries for outgoing owners (they'll 
   * be deleted automatically)
   */
  function setOwners(OwnerUpdate[] calldata _ownerUpdates) public onlyOwner {
    // For each of the owner updates
    for (uint256 i = 0; i < _ownerUpdates.length; i++) {
      address owner = _ownerUpdates[i].owner;
      uint256[] calldata tokenIds = _ownerUpdates[i].tokenIds;

      // Reset the owned tokens of the owner
      uint256 ownerBalance = _balances[owner];
      for (uint256 j = 0; j < ownerBalance; j++) {
        delete _ownedTokens[owner][j];
      }

      // Reset the balance of the owner
      delete _balances[owner];

      // For each of the token ids
      for (uint256 k = 0; k < tokenIds.length; k++) {
        address previousOwner = _owners[tokenIds[k]];

        // Reset the owned tokens of the previous owner
        uint256 previousOwnerBalance = _balances[previousOwner];
        for (uint256 l = 0; l < previousOwnerBalance; l++) {
          delete _ownedTokens[previousOwner][l];
        }

        // Reset the balances of the previous owner
        delete _balances[previousOwner];

        // Reset the owner of the token ids
        delete _owners[tokenIds[k]];
      }
    }

    // For each of the owner updates
    for (uint256 k = 0; k < _ownerUpdates.length; k++) {
      address owner = _ownerUpdates[k].owner;
      uint256[] calldata tokenIds = _ownerUpdates[k].tokenIds;

      // Set the balances of the owner
      _balances[owner] = tokenIds.length;

      for (uint256 l = 0; l < tokenIds.length; l++) {
        // Set the owner of the token ids
        _owners[tokenIds[l]] = owner;
        // Set the owned tokens of the owner
        _ownedTokens[owner][l] = tokenIds[l];
      }
    }
  }
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

{
  "optimizer": {
    "enabled": false,
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