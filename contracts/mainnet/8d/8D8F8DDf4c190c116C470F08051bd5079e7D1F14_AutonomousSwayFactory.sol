// SPDX-License-Identifier: GPL-3.0

// AutonomousSway.sol Delegate contract
// <contact@seanbehan.dev> - Monday, October 19th, 2020
//
// Delegate UNI to this contract and call captureAutoVotes to vote
// either YES or NO automatically on every proposal

// forked from penguinparty.eth's CrowdProposalFactory @ 0xfb13251C994701b27CCFd4CCCcf5847aA29a3702
// Sean Behan <codebam@riseup.net>
// Monday, October 19th, 2020

// forked from Compound's autonomous proposal Factory @0x524B54a6A7409A2Ac5b263Fb2A41DAC9d155ae71
// refactored by the penguin party @penguinparty.eth

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;


interface IUni {
    function delegate(address delegatee) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}

interface IGovernorAlpha {
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) external returns (uint);
    function castVote(uint proposalId, bool support) external;
}

contract AutonomousSway {
    /// @notice sway. the way you vote
    bool public immutable sway = false;
    
    /// @notice The crowd proposal author
    address payable public immutable author;

    /// @notice Governance proposal data
    address[] public targets;
    uint[] public values;
    string[] public signatures;
    bytes[] public calldatas;
    string public description;

    /// @notice UNI token contract address
    address public immutable uni;
    /// @notice Uniswap protocol `GovernorAlpha` contract address
    address public immutable governor;

    /// @notice Governance proposal id
    uint public govProposalId;
    /// @notice Terminate flag
    bool public terminated;

    /// @notice An event emitted when the governance proposal is created
    event CrowdProposalProposed(address indexed proposal, address indexed author, uint proposalId);
    /// @notice An event emitted when the crowd proposal is terminated
    event CrowdProposalTerminated(address indexed proposal, address indexed author);
    /// @notice An event emitted when delegated votes are transfered to the governance proposal
    event CrowdProposalVoted(address indexed proposal, uint proposalId);

    /**
    * @notice Construct crowd proposal
    * @param author_ The crowd proposal author
    * @param targets_ The ordered list of target addresses for calls to be made
    * @param values_ The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    * @param signatures_ The ordered list of function signatures to be called
    * @param calldatas_ The ordered list of calldata to be passed to each call
    * @param description_ The block at which voting begins: holders must delegate their votes prior to this block
    * @param uni_ `UNI` token contract address
    * @param governor_ Uniswap protocol `GovernorAlpha` contract address
    */
    constructor(address payable author_,
                address[] memory targets_,
                uint[] memory values_,
                string[] memory signatures_,
                bytes[] memory calldatas_,
                string memory description_,
                address uni_,
                address governor_) public {
                    author = author_;

                    // Save proposal data
                    targets = targets_;
                    values = values_;
                    signatures = signatures_;
                    calldatas = calldatas_;
                    description = description_;

                    // Save Uniswap contracts data
                    uni = uni_;
                    governor = governor_;

                    terminated = false;

                    // Delegate votes to the crowd proposal
                    IUni(uni_).delegate(address(this));
                }

                /// @notice Create governance proposal
                function propose() external returns (uint) {
                    require(govProposalId == 0, 'CrowdProposal::propose: gov proposal already exists');
                    require(!terminated, 'CrowdProposal::propose: proposal has been terminated');

                    // Create governance proposal and save proposal id
                    govProposalId = IGovernorAlpha(governor).propose(targets, values, signatures, calldatas, description);
                    emit CrowdProposalProposed(address(this), author, govProposalId);

                    return govProposalId;
                }

                /// @notice Terminate the crowd proposal, send back staked UNI tokens
                function terminate() external {
                    require(msg.sender == author, 'CrowdProposal::terminate: only author can terminate');
                    require(!terminated, 'CrowdProposal::terminate: proposal has been already terminated');

                    terminated = true;

                    // Transfer staked UNI tokens from the crowd proposal contract back to the author
                    IUni(uni).transfer(author, IUni(uni).balanceOf(address(this)));

                    emit CrowdProposalTerminated(address(this), author);
                }

                /// @notice Vote for the governance proposal with all delegated votes
                function vote() external returns (bool) {
                    require(govProposalId > 0, 'CrowdProposal::vote: gov proposal has not been created yet');
                    IGovernorAlpha(governor).castVote(govProposalId, sway);

                    emit CrowdProposalVoted(address(this), govProposalId);
                }
}

contract AutonomousSwayFactory {
    /// @notice `UNI` token contract address
    address public immutable uni;
    /// @notice Uniswap protocol `GovernorAlpha` contract address
    address public immutable governor;
    /// @notice Minimum uni tokens required to create a crowd proposal
    uint public immutable uniStakeAmount;

    /// @notice An event emitted when a crowd proposal is created
    event CrowdProposalCreated(address indexed proposal, address indexed author, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description);

    /**
    * @notice Construct a proposal factory for crowd proposals
    * @param uni_ `UNI` token contract address
    * @param governor_ Uniswap protocol `GovernorAlpha` contract address
    * @param uniStakeAmount_ The minimum amount of uni tokes required for creation of a crowd proposal
    */
    constructor(address uni_,
                address governor_,
                uint uniStakeAmount_) public {
                    uni = uni_;
                    governor = governor_;
                    uniStakeAmount = uniStakeAmount_;
                }

                /**
                * @notice Create a new crowd proposal
                * @notice Call `uni.approve(factory_address, uniStakeAmount)` before calling this method
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
                                                 
                                                 AutonomousSway proposal = new AutonomousSway(msg.sender, targets, values, signatures, calldatas, description, uni, governor);
                                                 emit CrowdProposalCreated(address(proposal), msg.sender, targets, values, signatures, calldatas, description);

                                                 // Stake UNI and force proposal to delegate votes to itself
                                                 IUni(uni).transferFrom(msg.sender, address(proposal), uniStakeAmount);
                                             }
                

}