/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: GPL-3.0

// pragma solidity >=0.7.0 <0.8.0;
pragma solidity >=0.4.22 <0.9.0;


contract BaggageTracking {
   
   //Users are added by PNR number
    mapping(string=>bool) public users;
    
    mapping(string=>bool) public tags;
    
    mapping(string=>CheckinStage) public tagStage;
   
    //User can have multiple Tags (hence Bags)
    mapping(string => string[]) public userBags;
    
    // //RFIDTag is attached to a Bag
    // mapping(string => string) public RFIDToBags;

    //RFID Tag (hence the bag) goes through multiple Checkinpoints
    mapping(string => Checkin[]) public bagCheckins;   
    
    // different checkpoints
    /*
        0 - Unassigned,
        1 - Counter,
        2 - LoadedInAirplane,
        3 - ArrivalCheckinBelt,
        4 - OutofAirport,
        5 - UserConfirmed
    */
    enum CheckinStage {
        Unassigned,
        Counter,
        LoadedInAirplane,
        ArrivalCheckinBelt,
        OutofAirport,
        UserConfirmed
    }
    
    // Checkpoint data
    struct Checkin {
        CheckinStage checkpoint;
        uint256 date;
    }
    
    Checkin checkin;
    

    //owner of the smart contract
    address public owner = msg.sender;

    // constructor() {
    //     owner = msg.sender;
    // }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    function addUser(string memory pnr) public isOwner {
        users[pnr] = true;
    }
    
    function addRFIDTag(string memory _RFID) public isOwner {
        tags[_RFID] = true;
    }
    
    function addUserBag(string memory pnr, string memory bag) public isOwner {
        require(users[pnr],"No such PNR Registered");
        require(tags[bag],"Tag not available");
        userBags[pnr].push(bag);
        tags[bag] = false;
        checkin = Checkin(CheckinStage.Counter, block.timestamp);
        tagStage[bag] = CheckinStage.Counter;
        bagCheckins[bag].push(checkin);
    }
    
    
    function updateBagCheckinWithStage(string memory tag, CheckinStage stage) public isOwner {
        require(tagStage[tag] != CheckinStage.OutofAirport,"bag already out of Airport..");
        require(tagStage[tag] < stage, "Bag already crossed that stage..!");
        require(stage != CheckinStage.UserConfirmed);
        checkin = Checkin(stage, block.timestamp);
        tagStage[tag] = stage;
        bagCheckins[tag].push(checkin);
    }
    
    function updateBagCheckin(string memory tag) public isOwner {
        require(tagStage[tag] != CheckinStage.OutofAirport,"bag already out of Airport..");
        CheckinStage stage = tagStage[tag];
        stage = CheckinStage(uint(stage) + 1);
        require(stage != CheckinStage.UserConfirmed);
        checkin = Checkin(stage, block.timestamp);
        tagStage[tag] = stage;
        bagCheckins[tag].push(checkin);
    }

    function _burn(string memory pnr, uint index) internal {
        require(index < userBags[pnr].length);
        userBags[pnr][index] = userBags[pnr][userBags[pnr].length-1];
        delete userBags[pnr][userBags[pnr].length-1];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}

    function confirmBaggage(string memory pnr, string memory tag) public isOwner {
        require(tagStage[tag] == CheckinStage.OutofAirport,"bag already out of Airport..");
        require(tagStage[tag] != CheckinStage.UserConfirmed);
        bool hasBag = false;
        for(uint i=0; i<userBags[pnr].length; i++) {
            string memory _bag = userBags[pnr][i];
            if(compareStrings(_bag, tag)) {
                hasBag = true;
            }
        }
        require(hasBag, "Bag does not belong to the user");
        checkin = Checkin(CheckinStage.UserConfirmed, block.timestamp);
        tagStage[tag] = CheckinStage.UserConfirmed;
        bagCheckins[tag].push(checkin);
        tags[tag] = true;
    }
    
    function getUserBags(string memory _pnr) public view returns (uint) {
        return userBags[_pnr].length;
    }

    function getBagCheckins(string memory tag) public view returns (uint) {
        return bagCheckins[tag].length;
    }    
}