/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

//pragma experimental ABIEncoderV2;
contract T2{
    struct GovProposal {
        address proposer;
        bool canceled;
    }

    function setProposal(GovProposal memory res) internal pure {
        res.proposer = address(0x12);
        res.canceled = false;
    }
    function getProposer() public pure returns(address p)  {
        GovProposal memory  g;
        setProposal(g);
        p=g.proposer;
        return p;
    }
}