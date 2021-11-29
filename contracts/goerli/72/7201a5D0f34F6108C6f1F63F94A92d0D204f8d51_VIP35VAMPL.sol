// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.7.5;

/**
 * @title AssetListingProposalGenericExecutor
 * @notice Proposal payload to be executed by the Volmex Governance contract via DELEGATECALL
 * @author Volmex
 **/
contract VIP35VAMPL {
  event ProposalExecuted();

  /**
   * @dev Payload execution function, called once a proposal passed in the Volmex governance
   */
  function execute() external {
    emit ProposalExecuted();
  }
}