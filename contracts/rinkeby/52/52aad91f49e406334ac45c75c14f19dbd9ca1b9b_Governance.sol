/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Governance {
	modifier onlyAdmin {
		require (msg.sender == admin);
		_;
	}

	modifier onlyValidator {
		bool isValidator = false;
		for (uint i = 0; i < 3; i++) {
			if (actualValidators[i] == msg.sender) {
				isValidator = true;
			}
		}
		require (isValidator);
		_;
	}

	struct Validator {
		string name;
		string email;
		uint256 createdAt;
	}

	struct Approval {
		address property;
		string propertyDescription;
		string extraInfo;
		uint status;
		uint votes;
		mapping (address => uint) approvals;
	}

	address admin;
	
	enum GovernanceStatus { INACTIVE, ACTIVE }
	enum ApprovalStatus { ONGOING, APPROVED, REFUSED }
	enum Vote { AWAITING, APPROVED, REFUSED }
	
	uint private status;
	uint private qtyActualValidators;
	uint private qtyApprovals;
	address[] private actualValidators = new address[](3);
	
	mapping (address => Validator) allValidators;
  	mapping (uint => Approval) approvals;

	event NewValidator(address indexed _validator, string _name, string _email);
	event NewApproval(uint _approval);
	event GovernanceUpdated(string _status);
	event NewVote (address indexed _validator, uint _approval);
	event FinishVotation(uint _approval, uint result);

	constructor() {
		admin = msg.sender;
		status = 0;
	}

	function createValidator(string memory _name, string memory _email, address _address) public onlyAdmin {
		require (status == 0);
		require (qtyActualValidators < 3);

		Validator memory validator = Validator(_name, _email, block.timestamp);
		allValidators[_address] = validator;
		actualValidators[qtyActualValidators] = _address;
		qtyActualValidators++;

		emit NewValidator(_address, _name, _email);
		
		if (qtyActualValidators == 3) {
			status = 1;
			emit GovernanceUpdated('active');
		}
		
	}

	function createApproval(address _property, string memory _description, string memory _extra) public onlyAdmin returns (uint){
		require (status == 1, "Status must be ACTIVE");
		Approval storage newApproval = approvals[qtyApprovals++];
		newApproval.property = _property;
		newApproval.propertyDescription = _description;
		newApproval.extraInfo = _extra;
		newApproval.status = 0;

		emit NewApproval(qtyApprovals);
		return (qtyApprovals);
	}

	function calculateVotes(uint _approvalId) private returns (uint result) {
		uint approve = 0;
		uint refuse = 0;
		for (uint i = 0; i < 3; i++) {
			if (approvals[_approvalId].approvals[actualValidators[i]] == 1)
				approve++;
			else
				refuse++;
		}

		if (approve > refuse)
			approvals[_approvalId].status = 1;
		else
			approvals[_approvalId].status = 2;

		return approvals[_approvalId].status;
	}

	function vote(uint _approvalId, uint _vote) public onlyValidator returns (bool response) {
		require(approvals[_approvalId].status == 0, "erro 1");
		require(approvals[_approvalId].approvals[msg.sender] == 0, "erro 2");

		approvals[_approvalId].approvals[msg.sender] = _vote;
		approvals[_approvalId].votes++;

		if (approvals[_approvalId].votes == 3) {
			emit FinishVotation(_approvalId, calculateVotes(_approvalId));
		}

		emit NewVote(msg.sender, _approvalId);
		return true;
	}

	function readValidators(address id) public view returns(string memory, string memory) {
		return (allValidators[id].name, allValidators[id].email);
	}

	function readApproval(uint approvalId) public view returns (address, string memory, string memory, uint, uint) {
		return (
			approvals[approvalId].property,
			approvals[approvalId].propertyDescription,
			approvals[approvalId].extraInfo,
			approvals[approvalId].status,
			approvals[approvalId].votes
		);
	}
}