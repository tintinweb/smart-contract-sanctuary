/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT-License
pragma abicoder v2;
pragma solidity ^0.8.7;

contract employee_contract {
	struct employee {
		string employee_id;
		string first_name;
		string last_name;
		string position_id;
		string birth_date;
		string onboarding_date;
		string department_id;
	}

	employee[] public _employee;

	function add_employee(
		string memory _employee_id,
		string memory _first_name,
		string memory _last_name,
		string memory _position_id,
		string memory _birth_date,
		string memory _onboarding_date,
		string memory _department_id
	) public {
		_employee.push(
			employee(
				_employee_id,
				_first_name,
				_last_name,
				_position_id,
				_birth_date,
				_onboarding_date,
				_department_id
			)
		);
	}

	function count() public view returns (uint256) {
		return _employee.length;
	}
}