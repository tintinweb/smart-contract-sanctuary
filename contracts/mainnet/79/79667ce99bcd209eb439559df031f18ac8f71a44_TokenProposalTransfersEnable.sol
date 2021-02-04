/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// This is a Tornado Cash Governance proposal.
// See this post for more information on the proposal:
// https://torn.community/t/proposal-1-enable-torn-transfers/38

interface ITorn {
    function changeTransferability(bool decision) external;
}

contract TokenProposalTransfersEnable {
    function executeProposal() public {
        ITorn torn = ITorn(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);
        torn.changeTransferability(true);
    }
}