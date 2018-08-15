pragma solidity ^0.4.24;

contract Payroll {
  address public owner;

  struct Entry {
    address employee;
    uint256 salary;
  }

  Entry[] public entries;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(address[] employees, uint256[] salaries) public {
    require(employees.length > 0);
    require(employees.length == salaries.length);

    owner = msg.sender;

    for (uint256 i = 0; i < employees.length; ++i) {
      entries.push(Entry({
        employee: employees[i],
        salary: salaries[i]
      }));
    }
  }

  function applyRaises(uint256[] raises) public onlyOwner {
    require(raises.length == entries.length);

    uint256[] newSalaries;
    for (uint256 i = 0; i < entries.length; ++i) {
      newSalaries.push(entries[i].salary + raises[i]);
    }

    for (i = 0; i < entries.length; ++i) {
      entries[i].salary = newSalaries[i];
    }
  }
}