/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
/*
 @ERR_001: Cuenta ya Registrada
 @ERR_002: Identificacion ya registrada
 @ERR_003: No existe cuente registrada
 @ERR_004: No existe identification registrada
 @ERR_005: No es el creador
 @ERR_006: No es el existe permiso
 @ERR_007: Plata diferente
 @Test: "A","A","1"
 **/

contract ThesisContract {
    address public owner;

    struct Employee {
        string name;
        string surname;
        string identification;
        address account;
        uint amount;
    }

    enum StateWorkPermission {Requested, Approved, Cancel, Denied, Finished}
    struct WorkPermission {
        uint id;
        uint amount;
        uint256 initialDate;
        uint256 finalDate;
        string reason;
        StateWorkPermission state;
        address account;
    }

    mapping(address => Employee) private ListOfEmployees;
    mapping(address => bool) private listOfEmployeesRegistration;
    address [] private listAccounts;

    mapping(address => WorkPermission[]) private listPermissionsByEmployee;
    uint idOfPermissions;

    event employeeRegister(address adr, string data);

    constructor() {
        owner = msg.sender;
        idOfPermissions = 0;
    }

    function register(string memory name, string memory surname, string memory identification) public {
        require(!isEmployeeIsRegister(msg.sender), "ERR_001");
        require(!isIdentificationRegistered(identification), "ERR_002");
        Employee storage employee = ListOfEmployees[msg.sender];
        employee.name = name;
        employee.surname = surname;
        employee.identification = identification;
        employee.account = msg.sender;
        employee.amount = 1;
        listOfEmployeesRegistration[msg.sender] = true;
        listAccounts.push(msg.sender);
        emit employeeRegister(msg.sender, string(abi.encodePacked(name, " ", surname, " ", identification)));
    }

    function registerAdmin(address adr, string memory name, string memory surname, string memory identification) public {
        require(!isEmployeeIsRegister(adr), "ERR_001");
        require(!isIdentificationRegistered(identification), "ERR_002");
        Employee storage employee = ListOfEmployees[adr];
        employee.name = name;
        employee.surname = surname;
        employee.identification = identification;
        employee.account = adr;
        employee.amount = 1;
        listOfEmployeesRegistration[adr] = true;
        listAccounts.push(adr);
    }

    function isEmployeeIsRegister(address adr) private view returns (bool){
        return listOfEmployeesRegistration[adr];
    }

    function isIdentificationRegistered(string memory identification) private view returns (bool){
        for (uint i = 0; i < listAccounts.length; i++) {
            Employee memory employee = ListOfEmployees[listAccounts[i]];
            if (keccak256(bytes(employee.identification)) == keccak256(bytes(identification)))
                return true;
        }
        return false;
    }

    function getEmployeeByAccount(address adr) public view returns (string memory, string memory, string memory, address, uint){
        require(isEmployeeIsRegister(msg.sender), "ERR_003");
        Employee memory employee = ListOfEmployees[adr];
        return (employee.name, employee.surname, employee.identification, employee.account, employee.amount);
    }

    function getEmployeeByIdentification(string memory identification) public view returns (string memory, string memory, string memory, address, uint){
        require(isIdentificationRegistered(identification), "ERR_004");
        for (uint i = 0; i < listAccounts.length; i++) {
            Employee memory employee = ListOfEmployees[listAccounts[i]];
            if (keccak256(bytes(employee.identification)) == keccak256(bytes(identification)))
                return (employee.name, employee.surname, employee.identification, employee.account, employee.amount);

        }
        return ("", "", "", msg.sender, 0);
    }

    function createPermissionByAdmin(uint256 initialDate, uint256 finalDate, string memory reason, address adr) public payable {
        require(isEmployeeIsRegister(adr), "ERR_003");
        Employee storage employee = ListOfEmployees[adr];
        require((employee.amount * (1 ether)) <= msg.value, "ERR_007");
        idOfPermissions ++;
        uint id = idOfPermissions;
        listPermissionsByEmployee[employee.account].push(WorkPermission(id, msg.value, initialDate, finalDate, reason, StateWorkPermission.Requested, adr));
        employee.amount ++;
    }

    function createPermissionByUser(uint256 initialDate, uint256 finalDate, string memory reason) public payable {
        createPermissionByAdmin(initialDate, finalDate, reason, msg.sender);
    }

    function getAmount() public view returns (uint) {
        require(isEmployeeIsRegister(msg.sender), "ERR_003");
        return ListOfEmployees[msg.sender].amount;
    }

    function getAmountByAdmin(address adr) public view returns (uint) {
        require(isEmployeeIsRegister(adr), "ERR_003");
        return ListOfEmployees[adr].amount;
    }

    function getPermissionByAccount(uint index, address adr) public view returns (uint, uint256, uint256, uint256, string memory, StateWorkPermission, address){
        require(isEmployeeIsRegister(adr), "ERR_003");
        WorkPermission memory permission = listPermissionsByEmployee[adr][index];
        return (permission.id, permission.amount, permission.initialDate, permission.finalDate, permission.reason, permission.state, permission.account);
    }

    function getPermission(uint index) public view returns (uint, uint256, uint256, uint256, string memory, StateWorkPermission, address){
        require(isEmployeeIsRegister(msg.sender), "ERR_003");
        WorkPermission memory permission = listPermissionsByEmployee[msg.sender][index];
        return (permission.id, permission.amount, permission.initialDate, permission.finalDate, permission.reason, permission.state, permission.account);
    }

    function getAllPermission() public onlyOwner view returns (WorkPermission[] memory) {
        return listPermissionsByEmployee[msg.sender];
    }

    function changeStatePermissionAdmin(uint id, address adr, StateWorkPermission state) public {
        require(isEmployeeIsRegister(msg.sender), "ERR_003");
        WorkPermission[] storage list = listPermissionsByEmployee[adr];
        for (uint i = 0; i < list.length; i++) {
            WorkPermission storage permission = list[i];
            if (permission.id == id) {
                permission.state = state;
                if (StateWorkPermission.Denied == state) {
                    uint amount = permission.amount / 2;
                    payable(adr).transfer(amount);
                    permission.amount = amount;
                }
            }
        }
    }

    function changeStatePermission(uint id, StateWorkPermission state) public {
        require(isEmployeeIsRegister(msg.sender), "ERR_003");
        WorkPermission[] storage list = listPermissionsByEmployee[msg.sender];
        for (uint i = 0; i < list.length; i++) {
            WorkPermission storage permission = list[i];
            if (permission.id == id) {
                permission.state = state;
                if (StateWorkPermission.Cancel == state) {
                    uint amount = permission.amount / 2;
                    payable(msg.sender).transfer(amount);
                    permission.amount = amount;
                }
            }
        }
    }

    function isOnlyOwner() public onlyOwner view returns (bool) {
        return true;
    }


    function getCountEmployees() public onlyOwner view returns (uint) {
        return listAccounts.length;
    }

    function getIndexEmployeeByAccount(uint index) public view returns (string memory, string memory, string memory, address, uint){
        return getEmployeeByAccount(listAccounts[index]);
    }


    modifier onlyOwner() {
        require((msg.sender == owner), "ERR_005");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function getContractBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }

}