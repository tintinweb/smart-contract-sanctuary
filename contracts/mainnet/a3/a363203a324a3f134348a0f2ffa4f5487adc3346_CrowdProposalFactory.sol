// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import './ICompound.sol';
import './CrowdProposal.sol';

contract CrowdProposalFactory {
    /// @notice `COMP` token contract address
    address public immutable comp;
    /// @notice Compound protocol `GovernorBravo` contract address
    address public immutable governor;
    /// @notice Minimum Comp tokens required to create a crowd proposal
    uint public immutable compStakeAmount;

    /// @notice An event emitted when a crowd proposal is created
    event CrowdProposalCreated(address indexed proposal, address indexed author, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description);

     /**
     * @notice Construct a proposal factory for crowd proposals
     * @param comp_ `COMP` token contract address
     * @param governor_ Compound protocol `GovernorBravo` contract address
     * @param compStakeAmount_ The minimum amount of Comp tokes required for creation of a crowd proposal
     */
    constructor(address comp_,
                address governor_,
                uint compStakeAmount_) public {
        comp = comp_;
        governor = governor_;
        compStakeAmount = compStakeAmount_;
    }

    /**
    * @notice Create a new crowd proposal
    * @notice Call `Comp.approve(factory_address, compStakeAmount)` before calling this method
    * @param targets The ordered list of target addresses for calls to be made
    * @param values The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    * @param signatures The ordered list of function signatures to be called
    * @param calldatas The ordered list of calldata to be passed to each call
    * @param description The block at which voting begins: holders must delegate their votes prior to this block
    */
    function createCrowdProposal(address[] memory targets,
                                 uint[] memory values,
                                 string[] memory signatures,
                                 bytes[] memory calldatas,
                                 string memory description) external {
        CrowdProposal proposal = new CrowdProposal(msg.sender, targets, values, signatures, calldatas, description, comp, governor);
        emit CrowdProposalCreated(address(proposal), msg.sender, targets, values, signatures, calldatas, description);

        // Stake COMP and force proposal to delegate votes to itself
        IComp(comp).transferFrom(msg.sender, address(proposal), compStakeAmount);
    }
}