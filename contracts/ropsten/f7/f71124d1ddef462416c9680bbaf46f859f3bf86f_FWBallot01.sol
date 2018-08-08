// 测试投票基本功能
// 初始化投票目标列表
// 外部可以查看投票列表
// 可以查看当前投票的情况
// 可以查看哪些人可以投票
// 创建者可以给别人投票权

pragma solidity ^0.4.22;

// ----------------------------------------------------------------------------
// 安全的数学计算
// ----------------------------------------------------------------------------
contract SafeMath {
	function safeAdd(uint a, uint b) public pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}
	function safeSub(uint a, uint b) public pure returns (uint c) {
		require(b <= a);
		c = a - b;
	}
	function safeMul(uint a, uint b) public pure returns (uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}
	function safeDiv(uint a, uint b) public pure returns (uint c) {
		require(b > 0);
		c = a / b;
	}
}

// 投票智能合约
contract FWBallot01 is SafeMath {
	// 投票者信息
	struct Voter {
		uint weight; 	// 投票权重
		bool voted; 	// 是否已经投票
		uint vote; 		// 投票索引
	}

	// 单个建议，供投票
	struct Proposal {
		bytes32 name; 		// 建议名称
		uint voteCount; 	// 累计得票数
	}

	// 主席
	address public chairperson;
	// 投票者列表
	mapping(address => Voter) public voters;
	// 投票者总人数
	uint voterNum;
	// 已投票者总人数
	uint votedVoterNum;

	// 建议列表，变长数组类型
	Proposal[] public proposals;

	// 最终投票结果
	Proposal winProposal;

	// 构造函数，根据建议名称列表和主席投票权重初始化
	constructor(bytes32[] proposalNames, uint chairpersonWeight) public {
		chairperson = msg.sender;
		// "length of proposal name list must greater than 0."
		require(proposalNames.length>0);
		// "chairperson weight must greater than 0."
		require(chairpersonWeight>0);
		voters[chairperson].weight = chairpersonWeight;
		voterNum = safeAdd(voterNum, 1);

		// 循环遍历建议名称列表，创建建议列表
		for (uint i=0; i<proposalNames.length; i++) {
			proposals.push(Proposal({
				name:proposalNames[i],
				voteCount:0
			}));
		}
	}
	// 给予投票权
	function giveRightToVote(address voterAddr) public {
		// 只有主席能给予投票权
		require(chairperson==msg.sender);
		// The vote already voted.
		require(!voters[voterAddr].voted);
		require(voters[voterAddr].weight==0);
		voters[voterAddr].weight = 1;
		voterNum = safeAdd(voterNum, 1);
	}

	// 投票
	function vote(uint proposalIndex) public {
		// Already voted!
		require(!voters[msg.sender].voted);
		// not allow!
		require(voters[msg.sender].weight>0);
		// invalid proposal index!
		require(proposalIndex>0 && proposalIndex<proposals.length);
		voters[msg.sender].voted = true;
		voters[msg.sender].vote = proposalIndex;

		proposals[proposalIndex].voteCount = safeAdd(proposals[proposalIndex].voteCount, voters[msg.sender].weight);
		votedVoterNum = safeAdd(votedVoterNum, 1);
		if (votedVoterNum==voterNum) {
			voteEnd();
		}
	}

	// 投票结束，会在投票函数中自动触发
	function voteEnd() internal {
		uint index;
		uint voteCount;
		for (uint i=0; i<proposals.length; i++) {
			if (proposals[i].voteCount>voteCount) {
				index = i;
				voteCount = proposals[i].voteCount;
			}
		}
		winProposal = proposals[index];
	}

	// 查看投票结果
	function winnerName() public view
		returns (bytes32 winnerName_) {
		if (winProposal.voteCount>0) {
			winnerName_ = winProposal.name;
		} else {
			winnerName_ = "";
		}
	}
}