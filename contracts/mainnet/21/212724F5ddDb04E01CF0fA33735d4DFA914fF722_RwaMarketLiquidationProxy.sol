// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {ILendingPoolCollateralManager} from '../interfaces/ILendingPoolCollateralManager.sol';

interface IRestrictedToken {
  function hasMember(address usr) external view returns (bool);
}

contract RwaMarketLiquidationProxy is ILendingPoolCollateralManager, Ownable {
  address private collateralManager;

  function setManager(address _collateralManager) external onlyOwner {
    collateralManager = _collateralManager;
  }

  function seize(
    address user,
    address[] calldata assets,
    address to
  ) external override returns (uint256, string memory) {
    return (0, "not-allowed");
  }

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external override returns (uint256, string memory) {
    require(
      IRestrictedToken(collateralAsset).hasMember(msg.sender) == true,
      'sender is not a member for this asset'
    );
    ILendingPoolCollateralManager(collateralManager).liquidationCall(
      collateralAsset,
      debtAsset,
      user,
      debtToCover,
      receiveAToken
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title ILendingPoolCollateralManager
 * @author Aave
 * @notice Defines the actions involving management of collateral in the protocol.
 **/
interface ILendingPoolCollateralManager {
  /**
   * @dev Emitted when a borrower is liquidated
   * @param collateral The address of the collateral being liquidated
   * @param principal The address of the reserve
   * @param user The address of the user being liquidated
   * @param debtToCover The total amount liquidated
   * @param liquidatedCollateralAmount The amount of collateral being liquidated
   * @param liquidator The address of the liquidator
   * @param receiveAToken true if the liquidator wants to receive aTokens, false otherwise
   **/
  event LiquidationCall(
    address indexed collateral,
    address indexed principal,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the collateral of a user has been seized
   * @param user The user whose collateral has been seized
   * @param asset The addresse of the underlying asset to seize
   * @param to The address that will receive the funds
   * @param amount The amount seized
   **/
  event Seized(
    address indexed user,
    address indexed to,
    address indexed asset,
    uint256 amount
  );

  /**
   * @dev Emitted when a reserve is disabled as collateral for an user
   * @param reserve The address of the reserve
   * @param user The address of the user
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted when a reserve is enabled as collateral for an user
   * @param reserve The address of the reserve
   * @param user The address of the user
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Users can invoke this function to liquidate an undercollateralized position.
   * @param collateral The address of the collateral to liquidated
   * @param principal The address of the principal reserve
   * @param user The address of the borrower
   * @param debtToCover The amount of principal that the liquidator wants to repay
   * @param receiveAToken true if the liquidators wants to receive the aTokens, false if
   * he wants to receive the underlying asset directly
   **/
  function liquidationCall(
    address collateral,
    address principal,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external returns (uint256, string memory);

  /**
   * @dev Function to seize the collateral of a user. Only whitelisters of the user can call this function
   * @param user The user whose collateral has been seized
   * @param assets The addresses of the underlying assets to seize
   * @param to The address that will receive the funds
   **/
  function seize(
    address user,
    address[] calldata assets,
    address to
  ) external returns (uint256, string memory);
}