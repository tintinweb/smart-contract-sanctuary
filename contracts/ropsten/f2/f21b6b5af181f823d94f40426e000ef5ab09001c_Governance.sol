/**
 *Submitted for verification at Etherscan.io on 2021-08-13
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
		for (uint i = 0; i <= 3; i++) {
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
		mapping (address => uint) approvals; // 1 sim 2 não
	}

	address admin;
	uint private status;
	uint private qtyActualValidators;
	uint private qtyApprovals;
	address[] private actualValidators = new address[](3);
	mapping (address => Validator) allValidators;
  	mapping (uint => Approval) approvals;

	event NewValidator(address indexed _validator, string _name, string _email);
	event GovernanceUpdated(string _status);
	event Vote (address indexed _validator, uint _approval);
	event FinishVotation(uint _approval, uint result);

	constructor() {
		admin = msg.sender;
	}

	function createValidator(string memory _name, string memory _email, address _address) public onlyAdmin returns(bool response) {
		require (status == 0);
		require (qtyActualValidators < 3);

		Validator memory validator = Validator(_name, _email, block.timestamp);
		allValidators[_address] = validator;
		actualValidators[qtyActualValidators] = _address;
		qtyActualValidators++;
		
		if (qtyActualValidators == 3) {
			status = 1;
			emit GovernanceUpdated('active');
		}
		
		emit NewValidator(_address, _name, _email);
		return true;
	}

	function createApproval(address _property, string memory _description, string memory _extra) public onlyAdmin returns (bool response) {
		require (status == 1);
		Approval storage newApproval = approvals[qtyApprovals++];
		newApproval.property = _property;
		newApproval.propertyDescription = _description;
		newApproval.extraInfo = _extra;
		newApproval.status = 0;

		return true;
	}

	function calculateVotes(uint _approvalId) private returns (uint result) {
		uint approve = 0;
		uint refuse = 0;
		for (uint i = 0; i <= 3; i++) {
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
		require(approvals[_approvalId].status == 1);
		require(approvals[_approvalId].approvals[msg.sender] == 0);

		approvals[_approvalId].approvals[msg.sender] = _vote;
		approvals[_approvalId].votes++;

		if (approvals[_approvalId].votes == 3) {
			emit FinishVotation(_approvalId, calculateVotes(_approvalId));
		}

		emit Vote(msg.sender, _approvalId);
		return true;
	}
}