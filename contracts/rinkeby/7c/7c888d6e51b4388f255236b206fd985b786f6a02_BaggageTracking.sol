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
        0 - Counter,
        1 - LoadedInAirplane,
        2 - ArrivalCheckinBelt,
        3 - OutofAirport
    */
    enum CheckinStage {
        Counter,
        DepartureCheckinBelt,
        LoadedInAirplane,
        ArrivalCheckinBelt,
        OutofAirport
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
    }
    
    
    function updateBagCheckinWithStage(string memory tag, CheckinStage stage) public isOwner {
        require(tagStage[tag] != CheckinStage.OutofAirport,"bag already out of Airport..");
        require(tagStage[tag] < stage, "Bag already crossed that stage..!");
        checkin = Checkin(stage, block.timestamp);
        tagStage[tag] = stage;
        bagCheckins[tag].push(checkin);
    }
    
    function updateBagCheckin(string memory tag) public isOwner {
        require(tagStage[tag] != CheckinStage.OutofAirport,"bag already out of Airport..");
        CheckinStage stage = tagStage[tag];
        stage = CheckinStage(uint(stage) + 1);
        checkin = Checkin(stage, block.timestamp);
        tagStage[tag] = stage;
        bagCheckins[tag].push(checkin);
    }
    
    function getUserBags(string memory _pnr) public view returns (uint) {
        return userBags[_pnr].length;
    }    
}