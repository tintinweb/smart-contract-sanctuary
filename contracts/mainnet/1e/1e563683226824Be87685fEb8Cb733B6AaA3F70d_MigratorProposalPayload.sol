/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IProposalExecutor {
  function execute() external;
}

interface IProxyWithAdminActions {
  event AdminChanged(address previousAdmin, address newAdmin);
  function changeAdmin(address newAdmin) external;
}


contract MigratorProposalPayload is IProposalExecutor {
  event ProposalExecuted();

  address public constant SHORT_EXECUTOR_V2=0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
  address public constant MIGRATOR_PROXY=0x317625234562B1526Ea2FaC4030Ea499C5291de4;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {

    IProxyWithAdminActions(MIGRATOR_PROXY).changeAdmin(SHORT_EXECUTOR_V2);

    emit ProposalExecuted();
  }
}