// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Nesters {
    // For simplicity, we use the contract owner (the platform) as the "Government" for now
    address public contractOwner;
    uint256[] activeHouses;
    mapping(uint256 => House) public houses;
    mapping(address => User) users;

    modifier onlyGov() {
        require(
            msg.sender == contractOwner,
            'Only the Government can mint (verify) houses'
        );
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    struct User {
        string name;
        uint256[] properties; // only for faster data access, ownership is defined by the House
        int256 reputationToken;
        uint256 votingToken;
    }

    struct House {
        uint256 ID;
        address owner;
        string physicalAddr;
        // some other fields may need to be verified when minted
        bool active; // fileds below need to be instantiated before active
        uint256 price;
        uint256 colateral;
        uint256 startDate; // set by the tenant
        uint256 rentingPeriod; // timestamp per second
    }

    function registerUser(address _addr, string memory _name) public {
        require(len(_name) > 0, 'Name cannot be empty');
        require(len(users[_addr].name) == 0, 'User already exists');

        uint256[] memory _properties;
        User memory user = User(_name, _properties, 0, 0);
        users[_addr] = user;
    }

    function mintHouse(
        address _owner,
        string memory _physicalAddr,
        uint256 _id
    ) public onlyGov {
        require(houses[_id].ID == 0, 'House already exists');
        require(len(users[_owner].name) > 0, 'User does not exist');

        House memory house = House(
            _id,
            _owner,
            _physicalAddr,
            false,
            0,
            0,
            0,
            0
        );
        houses[_id] = house;
        users[_owner].properties.push(_id);
    }

    function getUser(address _addr) public view returns (User memory) {
        return users[_addr];
    }

    function getActiveHouses() public view returns (uint256[] memory) {
        return activeHouses;
    }

    /**
    Landlords set the renting price, the house is now active
    Actived house can be seen on website
     */
    function activeHouse(
        uint256 _id,
        uint256 _price,
        uint256 _colateral
    ) public {
        require(
            houses[_id].owner == msg.sender,
            'Only the landlord can activate the house'
        );

        houses[_id].price = _price;
        houses[_id].colateral = _colateral;
        houses[_id].active = true;
        activeHouses.push(_id);
    }

    /**
     * Helper Function: Returns the length of a string
     * Need to use "bytes" cuz https://ethereum.stackexchange.com/a/46254
     */
    function len(string memory _str) private pure returns (uint256) {
        return bytes(_str).length;
    }
}