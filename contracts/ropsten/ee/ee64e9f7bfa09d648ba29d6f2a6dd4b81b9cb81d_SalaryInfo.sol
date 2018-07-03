pragma solidity ^0.4.24;

contract SalaryInfo {
    struct User {
        uint salaryId;
        string name;
        string userAddress;
        uint salary;
    }
    User[] public users;

    function addUser(uint _salaryId, string _name, string _userAddress, uint _salary) public returns(uint) {
        users.length++;
        users[users.length-1].salaryId = _salaryId;
        users[users.length-1].name = _name;
        users[users.length-1].userAddress = _userAddress;
        users[users.length-1].salary = _salary;
        return users.length;
    }

    function getUsersCount() public constant returns(uint) {
        return users.length;
    }

    function getUser(uint index) public constant returns(uint, string, string, uint) {
        return (users[index].salaryId, users[index].name, users[index].userAddress, users[index].salary);
    }
}