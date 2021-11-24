// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

/**
@title BadgerDAO NFTControl Control
@author @swoledoteth
@notice NFTControl is the on chain source of truth for the Boost NFT Weights.
The parameter exposed by NFT Control: 
- NFT Weight
@dev All operations must be conducted by an nft control manager.
The deployer is the original manager and can add or remove managers as needed.
*/
contract NFTControl is Ownable {
  event NFTWeightChanged(address indexed _nft, uint256 indexed _id, uint256 indexed _weight);

  mapping(address => bool) public manager;
  mapping(address => mapping(uint256 => uint256)) public nftWeight;

  modifier onlyManager() {
    require(manager[msg.sender], "!manager");
    _;
  }

  constructor(address _owner) {
    manager[msg.sender] = true;
    transferOwnership(_owner);
  }

  /// @param _manager address to add as manager
  function addManager(address _manager) external onlyOwner {
    manager[_manager] = true;
  }

  /// @param _manager address to remove as manager
  function removeManager(address _manager) external onlyOwner {
    manager[_manager] = false;
  }

  /// @param _nft address of nft to set weight
  /// @param _id id of nft to set weight
  /// @param _weight weight to set wei

  function setNFTWeight(address _nft, uint256 _id, uint256 _weight)
    external
    onlyManager
  {
    nftWeight[_nft][_id] = _weight;
    emit NFTWeightChanged(_nft, _id, _weight);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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