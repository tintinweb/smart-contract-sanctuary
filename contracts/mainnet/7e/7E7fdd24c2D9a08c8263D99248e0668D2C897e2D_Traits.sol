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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
  struct TokenTraits {
    bool isVillager;
    uint8 alphaIndex;
  }

  function getTokenTraits(uint256 tokenId) external view returns (TokenTraits memory);
  function generateTokenTraits(uint256 tokenId, uint256 seed) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ITraits.sol";

contract Traits is ITraits, Ownable {

  // a mapping from an address to whether or not it can interact
  mapping(address => bool) private controllers;

  // mapping of generated tokens
  mapping(uint256 => bool) private tokensGenerated;
  // mapping of known token traits
  mapping(uint256 => TokenTraits) private tokenTraits;
  // mapping of alpha index rarities
  uint8[] private alphaIndexRarities;
  // mapping of alpha index aliases
  uint8[] private alphaIndexAliases;

  /**
   * create the contract and initialize the alpha index roll tables
   */
  constructor() {
    alphaIndexRarities = [8, 160, 73, 255];
    alphaIndexAliases = [2, 3, 3, 3];
  }

  /**
   * get the traits for a given token
   * @param tokenId the token ID
   * @return a struct of traits for the given token ID
   */
  function getTokenTraits(uint256 tokenId) external view override returns (TokenTraits memory) {
    require(controllers[_msgSender()], "TRAITS: Only controllers can get traits");
    require(tokensGenerated[tokenId], "TRAITS: Token doesn't exist or hasn't been revealed");

    return tokenTraits[tokenId];
  }

  /**
   * generate the traits for a token and store it in this contract
   * @param tokenId the token ID
   * @param seed the generated seed from DOS
   */
  function generateTokenTraits(uint256 tokenId, uint256 seed) external override {
    require(controllers[_msgSender()], "TRAITS: Only controllers can generate traits");

    bool isVillager = (seed & 0xFFFF) % 10 != 0;
    uint8 alphaRoll = uint8(((seed >> 16) & 0xFFFF)) % uint8(alphaIndexRarities.length);
    uint8 alphaIndex;

    if (seed >> 24 < alphaIndexRarities[alphaRoll]) {
      alphaIndex = alphaRoll;
    } else {
      alphaIndex = alphaIndexAliases[alphaRoll];
    }

    tokensGenerated[tokenId] = true;

    tokenTraits[tokenId] = TokenTraits({
      isVillager: isVillager,
      alphaIndex: alphaIndex
    });
  }

  /**
   * enables an address to interact
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from interacting
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}