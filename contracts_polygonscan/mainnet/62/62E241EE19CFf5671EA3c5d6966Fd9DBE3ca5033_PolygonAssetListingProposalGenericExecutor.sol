// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {ILendingPoolConfiguratorV2} from './ILendingPoolConfiguratorV2.sol';
import {IProposalGenericExecutor} from './IProposalGenericExecutor.sol';
import {IOverlyingAsset} from './IOverlyingAsset.sol';
import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
/**
 * @title AssetListingProposalGenericExecutor
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * @author Aave
 **/
contract PolygonAssetListingProposalGenericExecutor is IProposalGenericExecutor {
  event ProposalExecuted();

  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER = 
    ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute(
    address token,
    address aToken,
    address stableDebtToken,
    address variablDebtToken,
    address interestStrategy,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    uint256 reserveFactor,
    uint8 decimals,
    bool enableBorrow,
    bool enableStableBorrow,
    bool enableAsCollateral
  ) external override {
    ILendingPoolConfiguratorV2 LENDING_POOL_CONFIGURATOR_V2 =
      ILendingPoolConfiguratorV2(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator());
    /*require(
      token == IOverlyingAsset(aToken).UNDERLYING_ASSET_ADDRESS(),
      'ATOKEN: WRONG_UNDERLYING_TOKEN'
    );
    require(
      token == IOverlyingAsset(stableDebtToken).UNDERLYING_ASSET_ADDRESS(),
      'STABLE_DEBT: WRONG_UNDERLYING_TOKEN'
    );
    require(
      token == IOverlyingAsset(variablDebtToken).UNDERLYING_ASSET_ADDRESS(),
      'VARIABLE_DEBT: WRONG_UNDERLYING_TOKEN'
    );*/
    LENDING_POOL_CONFIGURATOR_V2.initReserve(
      aToken,
      stableDebtToken,
      variablDebtToken,
      decimals,
      interestStrategy
    );
    if (enableBorrow) {
      LENDING_POOL_CONFIGURATOR_V2.enableBorrowingOnReserve(token, enableStableBorrow);
    }
    LENDING_POOL_CONFIGURATOR_V2.setReserveFactor(token, reserveFactor);
    if (enableAsCollateral) {
      LENDING_POOL_CONFIGURATOR_V2.configureReserveAsCollateral(
        token,
        ltv,
        liquidationThreshold,
        liquidationBonus
      );
    }

    emit ProposalExecuted();
  }
}