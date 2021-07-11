// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract WorldBook {
    address owner;
    address public constant athos = 0xd53f3100E46AF45068C45E2F38DFF674C4c3EEb2;
    address public constant ivan = 0xD7b86D53112D454BC6F702E4E03C3EbE1C6407Ad;
    address public constant wafa = 0xe1d3e6295aF5f53a8f9C76eBf57553C426Bf258D;
    User[] registers;
    event RegisterAdded(address indexed customer);

    struct User {
        address addr;
        string name;
        string lastname;
        string city;
        string region;
        string country;
        string father;
        string mother;
        string phrase;
        string picture;
        uint256 timestamp;
    }

    mapping(string => User[]) public usersList;

    constructor() {
        owner = msg.sender;
    }

    function addRegister(
        string memory _date,
        uint256 timestamp,
        string memory _name,
        string memory _lastname,
        string memory city,
        string memory region,
        string memory country,
        string memory father,
        string memory mother,
        string memory picture,
        string memory _phrase
    ) public payable {
        User memory user = User(
            msg.sender,
            _name,
            _lastname,
            city,
            region,
            country,
            father,
            mother,
            _phrase,
            picture,
            timestamp
        );

        usersList[_date].push(user);

        // uint256 mitad = msg.value / 2;
        // uint256 cuarto = mitad / 2;

        payable(athos).transfer(msg.value / 3);
        payable(ivan).transfer(msg.value / 3);
        payable(wafa).transfer(msg.value / 3);

        emit RegisterAdded(msg.sender);
    }

    function getRegisters(string memory dateStr)
        public
        view
        returns (User[] memory)
    {
        return usersList[dateStr];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwnerBalance() public view returns (uint256) {
        return owner.balance;
    }

    function getClientBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}