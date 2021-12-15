/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotiumBribe {
    struct Proposal {
      uint256 deadline;
      uint256 maxIndex;
    }

    event Bribed(address _token, uint256 _amount, bytes32 indexed _proposal, uint256 _choiceIndex);

    /// @param _proposal bytes32 of snapshot IPFS hash id for a given proposal
    function proposalInfo(bytes32 _proposal) external view returns (Proposal memory)    ;

    function depositBribe(address _token, uint256 _amount, bytes32 _proposal, uint256 _choiceIndex) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(
        address to,
        uint256 amount
    ) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library BribesLogic {
    /// @dev sends the token incentives to curve gauge votes for the next vote cycle/period
    function sendBribe(address _token, bytes32 _proposal, uint _tokensPerVote, uint _choiceIndex,  bytes32 _lastProposal, address _votiumBribe) public {
        uint balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "No tokens");

        if (_tokensPerVote > balance) {
            _tokensPerVote = balance;
        }

        // this makes sure that the token incentives can be sent only once per proposal
        require(_proposal != _lastProposal, "Bribe already sent");

        IVotiumBribe.Proposal memory proposal = IVotiumBribe(_votiumBribe).proposalInfo(_proposal);

        require(block.timestamp < proposal.deadline, "Proposal Expired"); // make sure the proposal exists
        require(_choiceIndex <= proposal.maxIndex, "Gauge doesnt exist"); // make sure the gauge index exists in the proposal

        IVotiumBribe(_votiumBribe).depositBribe(_token, _tokensPerVote, _proposal, _choiceIndex);
    }
}