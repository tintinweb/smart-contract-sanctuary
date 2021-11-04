// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Nesters {
    // For simplicity, we use the contract owner (the platform) as the "Government" for now
    address public contractOwner;
    uint256[] activeHouses;
    mapping(uint256 => House) public houses;
    mapping(address => User) users;
    mapping(uint256 => Transaction) public histories;
    uint256 historySize;

    modifier onlyGov() {
        require(
            msg.sender == contractOwner,
            'Only the Government can mint (verify) houses'
        );
        _;
    }

    constructor() {
        contractOwner = msg.sender;
        historySize = 0;
    }

    struct Transaction {
        uint256 houseID;
        address tennat;
        uint256 price;
        uint256 colateral;
        uint256 startDate;
        uint256 rentingPeriod;
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
        bool offer;
        address tennat;
        uint256 startDate; // set by the tenant
        uint256 rentingPeriod; // timestamp per second
        uint256[] history;
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

        uint256[] memory _history;
        House memory house = House(
            _id,
            _owner,
            _physicalAddr,
            false,
            0,
            0,
            false,
            address(0),
            0,
            0,
            _history
        );
        houses[_id] = house;
        users[_owner].properties.push(_id);
    }

    function getUser(address _addr) public view returns (User memory) {
        return users[_addr];
    }

    function getActiveHouses(uint256 _now) public returns (uint256[] memory) {
        uint256[] memory newHousesList = new uint256[](15);
        uint256 j = 0;
        // Do the Lazy Evaluation here, since only houses that are once active can be returned
        // Also remove those houses that are not active anymore
        for (uint256 i = 0; i < activeHouses.length; i++) {
            if (houses[activeHouses[i]].active) {
                newHousesList[j] = activeHouses[i];
                j++;
            } else {
                checkHouse(activeHouses[i], _now);
            }
        }
        activeHouses = newHousesList;

        return activeHouses;
    }

    /**
    Check if the house renting period has expired, set the values correspondingly
     */
    function checkHouse(uint256 _id, uint256 _now) private {
        if (!houses[_id].offer) {
            if (_now - houses[_id].startDate > houses[_id].rentingPeriod) {
                Transaction memory t = Transaction(
                    _id,
                    houses[_id].tennat,
                    houses[_id].price,
                    houses[_id].colateral,
                    houses[_id].startDate,
                    houses[_id].rentingPeriod
                );

                houses[_id].history.push(historySize);
                histories[historySize] = t;
                historySize++;

                houses[_id].tennat = address(0);
                houses[_id].price = 0;
                houses[_id].colateral = 0;
                houses[_id].startDate = 0;
                houses[_id].rentingPeriod = 0;
            }
        }
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

    function makeOffer(
        uint256 _id,
        uint256 _startDate,
        uint256 _rentingPeriod
    ) public {
        houses[_id].tennat = msg.sender;
        houses[_id].startDate = _startDate;
        houses[_id].rentingPeriod = _rentingPeriod;
        houses[_id].offer = true;
    }

    function acceptOffer(uint256 _id) public {
        require(
            houses[_id].owner == msg.sender,
            'Only the landlord can accept the offer'
        );

        houses[_id].active = false;
        houses[_id].offer = false;
    }

    /**
     * Helper Function: Returns the length of a string
     * Need to use "bytes" cuz https://ethereum.stackexchange.com/a/46254
     */
    function len(string memory _str) private pure returns (uint256) {
        return bytes(_str).length;
    }
}