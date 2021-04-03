/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ILendingPoolConfigurator {
  function disableReserveStableBorrowRate(address _reserve) external;
}


interface ILendingPoolAddressesProvider {
  
  function setLendingPoolImpl(address _pool) external;

  function setLendingPoolCoreImpl(address _lendingPoolCore) external;
  
  function getLendingPool() external view returns (address);
}


interface IProposalExecutor {
  function execute() external;
}


interface ILendingPoolV1 {
  function getReserves() external view returns (address[] memory);
}

/**
 * @title AIP11
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * - Disables new stable rates borrowings on Aave v1
 * - Updates the implementation of Aave v1 to replace rebalancing with swap to variable
 * @author Emilio Frangella
 **/
contract AIP11Payload is IProposalExecutor {
  event ProposalExecuted();

  ILendingPoolConfigurator public constant LENDING_POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x4965f6FA20fE9728deCf5165016fc338a5a85aBF);

  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

  address public constant NEW_LENDING_POOL_IMPL = 0xDB9217fad3c1463093fc2801Dd0a22C930850A61;
  address public constant NEW_LENDING_POOL_CORE_IMPL = 0x2847A5D7Ce69790cb40471d454FEB21A0bE1F2e3;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    LENDING_POOL_ADDRESSES_PROVIDER.setLendingPoolImpl(NEW_LENDING_POOL_IMPL);
    LENDING_POOL_ADDRESSES_PROVIDER.setLendingPoolCoreImpl(NEW_LENDING_POOL_CORE_IMPL);

    address[] memory reserves =
      ILendingPoolV1(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPool()).getReserves();
    for (uint256 i = 0; i < reserves.length; i++) {
      LENDING_POOL_CONFIGURATOR.disableReserveStableBorrowRate(reserves[i]);
    }

    emit ProposalExecuted();
  }
}