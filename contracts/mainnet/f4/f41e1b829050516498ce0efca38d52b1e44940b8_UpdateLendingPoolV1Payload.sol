/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ILendingPoolAddressesProvider {
  function setLendingPoolImpl(address _pool) external;
}

interface IProposalExecutor {
  function execute() external;
}

/**
 * @title UpdateLendingPoolV1Payload
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * - Updates the implementation of Aave v1 to update the logic of repayment on behalf, facilitation migration to Aave v2
 **/
contract UpdateLendingPoolV1Payload is IProposalExecutor {
  event ProposalExecuted();

  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

  address public constant NEW_LENDING_POOL_IMPL = 0xC1eC30dfD855c287084Bf6e14ae2FDD0246Baf0d;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    LENDING_POOL_ADDRESSES_PROVIDER.setLendingPoolImpl(NEW_LENDING_POOL_IMPL);

    emit ProposalExecuted();
  }
}