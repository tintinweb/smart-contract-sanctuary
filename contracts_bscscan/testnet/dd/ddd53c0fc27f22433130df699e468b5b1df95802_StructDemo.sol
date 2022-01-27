/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIT
// Solidity program
// to store
// Employee Details
pragma solidity ^0.6.8;

// Creating a Smart Contract
contract StructDemo{

// Structure of employee
struct Employee{
	
	// State variables
	int empid;
	string name;
	string department;
	string designation;
}

Employee []emps;

// Function to add
// employee details
function addEmployee(
	int empid, string memory name,
	string memory department,
	string memory designation
) public{
	Employee memory e
		=Employee(empid,
				name,
				department,
				designation);
	emps.push(e);
}

// Function to get
// details of employee
function getEmployee(
	int empid
) public view returns(
	string memory,
	string memory,
	string memory){
	uint i;
	for(i=0;i<emps.length;i++)
	{
		Employee memory e
			=emps[i];
		
		// Looks for a matching
		// employee id
		if(e.empid==empid)
		{
				return(e.name,
					e.department,
					e.designation);
		}
	}
	
	// If provided employee
	// id is not present
	// it returns Not
	// Found
	return("Not Found",
			"Not Found",
			"Not Found");
}
}