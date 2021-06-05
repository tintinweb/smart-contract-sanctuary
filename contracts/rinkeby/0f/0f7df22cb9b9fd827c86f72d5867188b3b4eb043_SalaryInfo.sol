/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// pragma solidity =0.5.17;
pragma solidity ^ 0.5.0;
contract SalaryInfo {
    struct User {
        uint salaryId;
        string name;
        string userAddress;
        uint salary;
        string[] tests;
    }
    User[] public users;

    function addUser(uint _salaryId, string memory _name, string memory _userAddress, uint _salary) public returns(uint) {
        users.length++;
        users[users.length-1].salaryId = _salaryId;
        users[users.length-1].name = _name;
        users[users.length-1].userAddress = _userAddress;
        users[users.length-1].salary = _salary;
        users[users.length-1].tests[0] = "aaa";
        users[users.length-1].tests[1] = "bbb";
        return users.length;
    }

    function getUsersCount() public view returns(uint) {
        return users.length;
    }

    function getUser(uint  index) public view returns(uint, string memory, string memory, uint) {
        return (users[index].salaryId, users[index].name, users[index].userAddress, users[index].salary);
    }
}