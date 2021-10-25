// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ApeRegistry
 * @version 1.1.0
 * @author Francesco Sullo <[email protected]>
 * @dev A registry for all Ape contracts
 */

//import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IApeRegistry.sol";
import "./IRegistryUser.sol";
import "../access/OwnedByMultiSigOwner.sol";

contract ApeRegistry is IApeRegistry, OwnedByMultiSigOwner {
  mapping(bytes32 => address) internal _registry;
  bytes32[] internal _contractsList;

  function register(bytes32[] memory contractHashes, address[] memory addrs) external override onlyMultiSigOwner {
    require(contractHashes.length == addrs.length, "ApeRegistry: contractHashes and addresses are inconsistent");
    bool changesDone;
    for (uint256 i = 0; i < contractHashes.length; i++) {
      bytes32 contractHash = contractHashes[i];
      bool exists = _registry[contractHash] != address(0);
      if (addrs[i] == address(0)) {
        if (exists) {
          delete _registry[contractHash];
          for (uint256 j = 0; j < _contractsList.length; j++) {
            if (_contractsList[j] == contractHash) {
              _contractsList[j] = _contractsList[_contractsList.length - 1];
              _contractsList.pop();
              break;
            }
          }
          changesDone = true;
        }
      } else {
        _registry[contractHash] = addrs[i];
        if (!exists) {
          _contractsList.push(contractHash);
        }
        changesDone = true;
      }
      if (changesDone) {
        emit RegistryUpdated(contractHashes[i], addrs[i]);
      }
    }
    if (changesDone && !_requiresMultiSigOwner) {
      // at this initial step, there is no risk of going out of gas
      // currently, it requires almost 900,000 gas
      updateAllContracts();
      // after setting the following, only the multiSigOwner can make changes
      _requiresMultiSigOwner = true;
    }
  }

  function updateContracts(uint256 initialIndex, uint256 limit) public override onlyMultiSigOwner {
    IRegistryUser registryUser;
    bool done;
    for (uint256 j = initialIndex; j < limit; j++) {
      if (_contractsList[j] != 0) {
        registryUser = IRegistryUser(_registry[_contractsList[j]]);
        registryUser.updateRegisteredContracts();
        done = true;
      }
    }
    if (done) {
      emit ChangePushedToSubscribers();
    }
  }

  function updateAllContracts() public override onlyMultiSigOwner {
    // this could go out of gas
    updateContracts(0, _contractsList.length);
  }

  function get(bytes32 contractHash) external view override returns (address) {
    return _registry[contractHash];
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

interface IApeRegistry {
  event RegistryUpdated(bytes32 contractHash, address addr);
  event ChangePushedToSubscribers();

  function register(bytes32[] memory contractHashes, address[] memory addrs) external;

  function get(bytes32 contractHash) external view returns (address);

  function updateContracts(uint256 initialIndex, uint256 limit) external;

  function updateAllContracts() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistryUser {
  function updateRegisteredContracts() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OwnedByMultiSigOwner
 * @version 1.1.0
 * @author Francesco Sullo <[email protected]>
 * @dev A registry for all Ape contracts
 */

//import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnedByMultiSigOwner.sol";

contract OwnedByMultiSigOwner is IOwnedByMultiSigOwner, Ownable {
  address public multiSigOwner;

  // must be set after the initial set up
  bool internal _requiresMultiSigOwner;

  modifier onlyMultiSigOwner() {
    if (_requiresMultiSigOwner) {
      require(_msgSender() != address(0) && _msgSender() == multiSigOwner, "OwnedByMultiSigOwner: not the multi sig owner");
    } else {
      require(_msgSender() == owner(), "OwnedByMultiSigOwner: not the owner");
    }
    _;
  }

  function setMultiSigOwner(address addr) external override onlyOwner {
    multiSigOwner = addr;
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

interface IOwnedByMultiSigOwner {
  function setMultiSigOwner(address addr) external;
}