// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from "./Ownable.sol";

import {IRollCallBridge} from "./IRollCallBridge.sol";
import {IRollCallGovernor} from "./IRollCallGovernor.sol";
import {IRollCallVoter} from "./IRollCallVoter.sol";
import {iOVM_CrossDomainMessenger} from "./iOVM_CrossDomainMessenger.sol";

contract RollCallBridge is IRollCallBridge, Ownable {
    iOVM_CrossDomainMessenger private immutable _cdm;
    address public voter;

    constructor(iOVM_CrossDomainMessenger cdm_) public {
        _cdm = cdm_;
    }

    function setVoter(address voter_) external onlyOwner {
        voter = voter_;
    }

    function propose(bytes32 id) external override {
        IRollCallGovernor governor = IRollCallGovernor(msg.sender);
        IRollCallGovernor.Proposal memory proposal = governor.proposal(id);

        bytes memory message = abi.encodeWithSelector(
            IRollCallVoter.propose.selector,
            msg.sender,
            id,
            governor.sources(),
            governor.slots(),
            proposal.snapshot,
            proposal.start,
            proposal.end
        );

        _cdm.sendMessage(voter, message, 1900000); // 1900000 gas is given for free
    }

    function queue(
        address governor,
        bytes32 id,
        uint256[10] calldata votes
    ) external override onlyVoter {
        IRollCallGovernor(governor).queue(id, votes);
    }

    /**
     * @dev Throws if called by any account other than the L2 voter contract.
     */
    modifier onlyVoter() {
        require(
            msg.sender == address(_cdm) && _cdm.xDomainMessageSender() == voter,
            "bridge: not voter"
        );
        _;
    }
}