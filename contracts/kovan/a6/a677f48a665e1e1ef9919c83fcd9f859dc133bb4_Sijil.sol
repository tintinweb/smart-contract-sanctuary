/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Sijil {
	address public ministryOfEducation;

	struct Record {
		string studentID;
		string studentName;
		address institution;
		string programme;
		string result;
		string modeOfStudy;
		string hash;
		string date;
	}

	Record[] records;

	struct Institution {
		uint index;
		address adr;
		string name;
		bool isApproved;
	}

	Institution[] public institutions;
	mapping(address => bool) public isApproved;

	constructor() public {
		ministryOfEducation = msg.sender;
	}

	modifier onlyMinistryOfEducation {
		require(
			msg.sender == ministryOfEducation,
			"Only the Ministry Of Education can run this function."
		);
		_;
	}

	function create(string memory name, address adr)
		public onlyMinistryOfEducation {
		require(adr != address(0), "Address is equal to zero.");
		uint id = institutions.length;
		institutions.push(Institution(id, adr, name, true));
		isApproved[adr] = true;
	}

	function approve(address adr)
		public onlyMinistryOfEducation {
		require(adr != address(0), "Address is equal to zero.");
		require(!isApproved[adr], "Address is already approved.");
		uint index = getInstitutionIndex(adr);
		institutions[index].isApproved = true;
		isApproved[adr] = true;
	}

	function disapprove(address adr)
		public onlyMinistryOfEducation {
		require(adr != address(0), "Address is equal to zero.");
		require(isApproved[adr], "Address is not approved.");
		uint index = getInstitutionIndex(adr);
		institutions[index].isApproved = false;
		isApproved[adr] = false;
	}

	function update(address ministry)
		public onlyMinistryOfEducation {
		require(ministry != address(0), "Address is equal to zero.");
		ministryOfEducation = ministry;
	}

	function addRecord(
		string memory studentID,
		string memory studentName,
		string memory programme,
		string memory result,
		string memory modeOfStudy,
		string memory hash,
		string memory date)
		public {
		require(isApproved[msg.sender], "Address is not approved.");
		require(!isHashExist(hash), "Hash already exists.");
		records.push(
			Record(
				studentID,
				studentName,
				msg.sender,
				programme,
				result,
				modeOfStudy,
				hash,
				date
			)
		);
	}

	function getRecord(string memory hash)
		public view returns (Record memory) {
		for (uint i=0; i<records.length; i++) {
			if (keccak256(abi.encodePacked((records[i].hash))) ==
			keccak256(abi.encodePacked(hash))) {
				return records[i];
			}
		}
	}

	function isHashExist(string memory hash)
		public view returns (bool) {
		for (uint i=0; i<records.length; i++) {
			if (keccak256(abi.encodePacked((records[i].hash))) ==
			keccak256(abi.encodePacked(hash))) {
				return true;
			}
		}
		return false;
	}

	function getInstitutionIndex(address adr)
		public view returns (uint) {
		for (uint i=0; i<institutions.length; i++) {
			if (institutions[i].adr == adr) {
				return institutions[i].index;
			}
		}
	}

	function getInstitutions() public view returns (Institution[] memory) {
		return institutions;
	}

	function getRecords() public view returns (Record[] memory) {
		return records;
	}
}