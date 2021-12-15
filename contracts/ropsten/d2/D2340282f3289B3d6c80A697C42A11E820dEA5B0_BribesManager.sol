/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

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

contract BribesManager {
    address public immutable TOKEN;
    uint public immutable GAUGE_INDEX;
    uint public immutable TOKENS_PER_VOTE;
    bytes32 public lastProposal;
    address constant VOTIUM_BRIBE = 0x19BBC3463Dd8d07f55438014b021Fb457EBD4595;

    /// @param token Address of the reward/incentive token
    /// @param gaugeIndex index of the gauge in the voting proposal choices
    /// @param tokensPerVote number of tokens to add as incentives per vote
    constructor(address token, uint gaugeIndex, uint tokensPerVote) {
        TOKEN = token;
        GAUGE_INDEX = gaugeIndex;
        TOKENS_PER_VOTE = tokensPerVote;
    }

    /// @param _proposal bytes32 of snapshot IPFS hash id for a given proposal
    function sendBribe(bytes32 _proposal) public {
        IERC20(TOKEN).approve(VOTIUM_BRIBE, TOKENS_PER_VOTE);
        BribesLogic.sendBribe(TOKEN, _proposal, TOKENS_PER_VOTE, GAUGE_INDEX, lastProposal, VOTIUM_BRIBE);
        lastProposal = _proposal;
    }
}