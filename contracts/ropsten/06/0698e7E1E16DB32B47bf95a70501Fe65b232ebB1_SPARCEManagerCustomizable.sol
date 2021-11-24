/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: NOLICENSE

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

interface SPARCESpawningManager {
    function isSpawningAllowed(uint256 _genes, address _owner) external view returns (bool);
    function isRebirthAllowed(uint256 _axieId, uint256 _genes) external view returns (bool);
}

interface SPARCERetirementManager {
    function isRetirementAllowed(uint256 _axieId, bool _rip) external view returns (bool);
}

interface SPARCEMarketplaceManager {
    function isTransferAllowed(address _from, address _to, uint256 _axieId) external view returns (bool);
}

interface SPARCEGeneManager {
    function isEvolvementAllowed(uint256 _axieId, uint256 _newGenes) external view returns (bool);
}

// solium-disable-next-line lbrace
contract SPARCEManagerCustomizable is
  SPARCESpawningManager,
  SPARCERetirementManager,
  SPARCEMarketplaceManager,
  SPARCEGeneManager,
  Ownable
{

  bool public allowedAll;

  function setAllowAll(bool _allowedAll) external onlyOwner {
    allowedAll = _allowedAll;
  }

  function isSpawningAllowed(uint256, address) external override view returns (bool) {
    return allowedAll;
  }

  function isRebirthAllowed(uint256, uint256) external override view returns (bool) {
    return allowedAll;
  }

  function isRetirementAllowed(uint256, bool) external override view returns (bool) {
    return allowedAll;
  }

  function isTransferAllowed(address, address, uint256) external override view returns (bool) {
    return allowedAll;
  }

  function isEvolvementAllowed(uint256, uint256) external override view returns (bool) {
    return allowedAll;
  }
}