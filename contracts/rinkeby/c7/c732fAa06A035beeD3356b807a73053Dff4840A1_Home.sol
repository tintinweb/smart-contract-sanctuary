/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// File contracts/Home.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;


contract Home {
    address public admin;
    address internal greeter;
    struct User {
        bool isVaild;
        string name;
        string profile;
        uint8 age;
    }
    mapping(address => User) users;

    event CreateUser(address _sender);
    event UpdateProfile(address _sender, string _profile);

    constructor(address _greeter) {
        admin = msg.sender;
        greeter = _greeter;
    }

    function createUser(
        address _address,
        string calldata _name,
        string calldata _profile,
        uint8 _age
    ) public onlyAdmin newUser(_address) {
        User memory _user;
        _user.isVaild = true;
        _user.name = _name;
        _user.profile = _profile;
        _user.age = _age;
        users[_address] = _user;
        emit CreateUser(_address);
    }

    function updateProfile(string memory _profile) public isValid(msg.sender) {
        User memory _user = users[msg.sender];
        _user.profile = _profile;
        users[msg.sender] = _user;
        emit UpdateProfile(msg.sender, _profile);
    }

    function queryMyInfo()
        public
        view
        isValid(msg.sender)
        returns (
            string memory,
            string memory,
            uint8
        )
    {
        User memory user = users[msg.sender];
        return (user.name, user.profile, user.age);
    }

    modifier newUser(address _address) {
        require(!users[_address].isVaild, "user is exist");
        _;
    }

    modifier isValid(address _address) {
        require(users[_address].isVaild, "user is invalid");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "need admin");
        _;
    }
}