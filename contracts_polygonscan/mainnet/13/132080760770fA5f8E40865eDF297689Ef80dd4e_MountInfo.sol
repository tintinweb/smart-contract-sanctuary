//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MountInfo is Ownable, Pausable {

  // Easier to use an array, the order is TokenId, Race, Generation
  mapping(uint => uint[3]) mountInfo;
  mapping(uint => bool) public mountInfoAdded;
  mapping(uint => bool) public invalidMount;
  mapping(uint => uint) public recruitedCount;
  mapping(uint => uint) public rarityToSpeed;

  // EVENTs

  event mountAdded(uint tokenId, uint rarity, uint race);

  // Constructor

  constructor() {
    rarityToSpeed[1] = 150;
    rarityToSpeed[2] = 175;
    rarityToSpeed[3] = 200;
    rarityToSpeed[4] = 250;
    rarityToSpeed[5] = 300;
    rarityToSpeed[6] = 350;
  }


  // Core Functions

  // Rarities are: 1: Common 2: Uncommon 3: Rare 4: Epic 5: Legendary 6: Mythic
  // Races are: 1: White Mare 2: Black Mare 3: Brown Mare 4: Centurion Charger 5: Night Mare 

  function addMount(uint _tokenId, uint _rarity, uint _race) public onlyOwner {
    require(mountInfoAdded[_tokenId] == false, "This Mount has already been added!");
    mountInfo[_tokenId] = [
      _tokenId,
      _rarity,
      _race
    ];
    mountInfoAdded[_tokenId] = true;
    emit mountAdded(_tokenId, _rarity, _race);
  }

  function add10Mounts(
    uint[3] memory mount1, 
    uint[3] memory mount2, 
    uint[3] memory mount3, 
    uint[3] memory mount4, 
    uint[3] memory mount5,
    uint[3] memory mount6,
    uint[3] memory mount7,
    uint[3] memory mount8,
    uint[3] memory mount9,
    uint[3] memory mount10
  ) public onlyOwner {
    addMount(mount1[0], mount1[1], mount1[2]);
    addMount(mount2[0], mount2[1], mount2[2]);
    addMount(mount3[0], mount3[1], mount3[2]);
    addMount(mount4[0], mount4[1], mount4[2]);
    addMount(mount5[0], mount5[1], mount5[2]);
    addMount(mount6[0], mount6[1], mount6[2]);
    addMount(mount7[0], mount7[1], mount7[2]);
    addMount(mount8[0], mount8[1], mount8[2]);
    addMount(mount9[0], mount9[1], mount9[2]);
    addMount(mount10[0], mount10[1], mount10[2]);
  }

  function updateMount(uint _tokenId, uint _rarity, uint _race) public onlyOwner {
    mountInfo[_tokenId] = [_tokenId, _rarity, _race];
  }

  function markInvalid(uint _tokenId) public onlyOwner {
    invalidMount[_tokenId] = true;
  }

  function checkMount(uint _tokenId) external view returns(uint[3] memory) {
    return mountInfo[_tokenId];
  }

  function mountSpeed(uint _mountId) external view returns(uint) {
    uint rarity = mountInfo[_mountId][1];
    return rarityToSpeed[rarity];
  }

  function changeRarityToSpeed(uint _rarity, uint _speed) external onlyOwner {
    rarityToSpeed[_rarity] = _speed;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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