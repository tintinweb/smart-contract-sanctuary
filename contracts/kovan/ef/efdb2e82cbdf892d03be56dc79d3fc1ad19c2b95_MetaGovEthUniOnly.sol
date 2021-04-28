/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


// https://github.com/Uniswap/governance/blob/master/contracts/GovernorAlpha.sol
interface UniVote {
    function castVote(uint proposalId, bool support) external;

    function castVoteBySig(
        uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s
    ) external;
}

interface UniProposal {
    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function queue(uint proposalId) external;

    function cancel(uint proposalId) external;

    function execute(uint proposalId) external;
}

contract MetaGovEthUniOnly {

    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event ProposedUni(uint256 indexed proposalId);
    event VotedUni(uint256 indexed proposalId, bool support);

    address private _admin;
    address private _uni;

    constructor(address uni_) {
        _admin = msg.sender;
        _uni = uni_;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function uni() public view returns (address) {
        return _uni;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    function uniCastVote(uint256 proposalId, bool support) public onlyAdmin {
        UniVote(_uni).castVote(proposalId, support);

        emit VotedUni(proposalId, support);
    }

    function uniCastVoteBySig(
        uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s
    ) public onlyAdmin {
        UniVote(_uni).castVoteBySig(proposalId, support, v, r, s);

        emit VotedUni(proposalId, support);
    }

    function uniPropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public onlyAdmin returns (uint256) {
        uint256 proposalId = UniProposal(_uni).propose(
            targets, values, signatures, calldatas, description
        );
        return proposalId;

        emit ProposedUni(proposalId);
    }

    function uniQueue(uint256 proposalId) public onlyAdmin {
        UniProposal(_uni).queue(proposalId);
    }

    function uniCancel(uint256 proposalId) public onlyAdmin {
        UniProposal(_uni).cancel(proposalId);
    }

    function uniExecute(uint256 proposalId) public onlyAdmin {
        UniProposal(_uni).execute(proposalId);
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, 'failed: not admin');
        _;
    }

}