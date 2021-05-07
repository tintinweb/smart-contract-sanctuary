// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

import { IFujiAdmin } from "./IFujiAdmin.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract FujiAdmin is IFujiAdmin, Ownable {
  address[] private _vaults;
  address private _flasher;
  address private _fliquidator;
  address payable private _ftreasury;
  address private _controller;
  address private _aWhiteList;
  address private _vaultHarvester;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Bonus Factor for Flash Liquidation
  Factor public bonusFlashL;

  // Bonus Factor for normal Liquidation
  Factor public bonusL;

  constructor() public {
    // 0.04
    bonusFlashL.a = 1;
    bonusFlashL.b = 25;

    // 0.05
    bonusL.a = 1;
    bonusL.b = 20;
  }

  // Setter Functions

  /**
   * @dev Sets the flasher contract address
   * @param _newFlasher: flasher address
   */
  function setFlasher(address _newFlasher) external onlyOwner {
    _flasher = _newFlasher;
  }

  /**
   * @dev Sets the fliquidator contract address
   * @param _newFliquidator: new fliquidator address
   */
  function setFliquidator(address _newFliquidator) external onlyOwner {
    _fliquidator = _newFliquidator;
  }

  /**
   * @dev Sets the Treasury contract address
   * @param _newTreasury: new Fuji Treasury address
   */
  function setTreasury(address payable _newTreasury) external onlyOwner {
    _ftreasury = _newTreasury;
  }

  /**
   * @dev Sets the controller contract address.
   * @param _newController: controller address
   */
  function setController(address _newController) external onlyOwner {
    _controller = _newController;
  }

  /**
   * @dev Sets the Whitelistingcontract address
   * @param _newAWhiteList: controller address
   */
  function setaWhitelist(address _newAWhiteList) external onlyOwner {
    _aWhiteList = _newAWhiteList;
  }

  /**
   * @dev Sets the VaultHarvester address
   * @param _newVaultHarverster: controller address
   */
  function setVaultHarvester(address _newVaultHarverster) external onlyOwner {
    _vaultHarvester = _newVaultHarverster;
  }

  /**
   * @dev Set Factors "a" and "b" for a Struct Factor
   * For bonusL; Sets the Bonus for normal Liquidation, should be < 1, a/b
   * For bonusFlashL; Sets the Bonus for flash Liquidation, should be < 1, a/b
   * @param _newFactorA: A number
   * @param _newFactorB: A number
   * @param _isbonusFlash: is bonusFlashFactor
   */
  function setFactor(
    uint64 _newFactorA,
    uint64 _newFactorB,
    bool _isbonusFlash
  ) external onlyOwner {
    if (_isbonusFlash) {
      bonusFlashL.a = _newFactorA;
      bonusFlashL.b = _newFactorB;
    } else {
      bonusL.a = _newFactorA;
      bonusL.b = _newFactorB;
    }
  }

  /**
   * @dev Adds a Vault.
   * @param _vaultAddr: Address of vault to be added
   */
  function addVault(address _vaultAddr) external onlyOwner {
    //Loop to check if vault address is already there
    _vaults.push(_vaultAddr);
  }

  /**
   * @dev Overrides a Vault address at location in the vaults Array
   * @param _position: position in the array
   * @param _vaultAddr: new provider fuji address
   */
  function overrideVault(uint8 _position, address _vaultAddr) external onlyOwner {
    _vaults[_position] = _vaultAddr;
  }

  // Getter Functions

  function getFlasher() external view override returns (address) {
    return _flasher;
  }

  function getFliquidator() external view override returns (address) {
    return _fliquidator;
  }

  function getTreasury() external view override returns (address payable) {
    return _ftreasury;
  }

  function getController() external view override returns (address) {
    return _controller;
  }

  function getaWhiteList() external view override returns (address) {
    return _aWhiteList;
  }

  function getVaultHarvester() external view override returns (address) {
    return _vaultHarvester;
  }

  function getvaults() external view returns (address[] memory theVaults) {
    theVaults = _vaults;
  }

  function getBonusFlashL() external view override returns (uint64, uint64) {
    return (bonusFlashL.a, bonusFlashL.b);
  }

  function getBonusLiq() external view override returns (uint64, uint64) {
    return (bonusL.a, bonusL.b);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IFujiAdmin {
  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getaWhiteList() external view returns (address);

  function getVaultHarvester() external view returns (address);

  function getBonusFlashL() external view returns (uint64, uint64);

  function getBonusLiq() external view returns (uint64, uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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