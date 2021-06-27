/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IVoteEmitter {
	event Vote(address indexed dispatcher, address voter, uint8[] percentiles);

	function dispatch(address voter, uint8[] memory percentiles) external;
}

contract VoteEmitter is IVoteEmitter {
	function dispatch(address voter, uint8[] memory percentiles)
		external
		override
	{
		emit Vote(msg.sender, voter, percentiles);
	}
}

contract Vote {
	struct Attributes {
		address proposer;
		string subject;
		string body;
		uint256 period;
		string[] options;
		string bodyMimeType;
		string optionsMimeType;
	}
	address public voteEmitter;
	address public proposer;
	string public subject;
	string public body;
	uint256 public period;
	string[] public options;
	string public bodyMimeType;
	string public optionsMimeType;

	mapping(address => bool) public isAlreadyVote;

	constructor(
		string memory _subject,
		string memory _body,
		string[] memory _options,
		string memory _bodyMimeType,
		string memory _optionsMimeType,
		address _voteEmitter,
		uint256 _votingBlock,
		address _proposer
	) {
		voteEmitter = _voteEmitter;
		proposer = _proposer;
		subject = _subject;
		body = _body;
		period = _votingBlock + block.number;
		options = _options;
		bodyMimeType = _bodyMimeType;
		optionsMimeType = _optionsMimeType;
	}

	function attributes() external view returns (Attributes memory) {
		return
			Attributes(
				proposer,
				subject,
				body,
				period,
				options,
				bodyMimeType,
				optionsMimeType
			);
	}

	function vote(uint8[] memory percentiles) external {
		require(block.number < period, "over the period");
		require(isAlreadyVote[msg.sender] == false, "already vote");
		isAlreadyVote[msg.sender] = true;
		IVoteEmitter(voteEmitter).dispatch(msg.sender, percentiles);
	}
}

contract VoteFactory {
	address public voteEmitter;

	event VoteCreate(address indexed sender, address vote);

	constructor(address _voteEmitter) {
		voteEmitter = _voteEmitter;
	}

	function create(
		string memory _subject,
		string memory _body,
		string[] memory _options,
		string memory _bodyMimeType,
		string memory _optionsMimeType,
		uint256 _votingBlock
	) external {
		Vote vote = new Vote(
			_subject,
			_body,
			_options,
			_bodyMimeType,
			_optionsMimeType,
			voteEmitter,
			_votingBlock,
			msg.sender
		);
		emit VoteCreate(msg.sender, address(vote));
	}
}