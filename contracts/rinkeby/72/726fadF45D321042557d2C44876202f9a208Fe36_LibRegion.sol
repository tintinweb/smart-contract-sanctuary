// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.9;

library LibRegion {
	
    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //Costing Config
    uint constant regionCostBase = 100;
    uint constant initialGrowthOffset = 5;
    uint constant regionGrowthExponent = 2;
    uint constant fakePercentMultiplier = 10000;
    uint constant fakePercent = 2000; //fakePercentMultiplier * 20%
    //With these numbers, the result should be roughly:
    //region 1 - 500 fame
    //region 2 - 720 fame
    //region 3 - 980 fame
    //region 4 - 1280 fame
    //region 5 - 1620 fame
    //region 6 - 2000 fame
    //region 7 - 2420 fame
    //region 8 - 2880 fame
    //region 9 - 3380 fame
    //and so on, up to 216,320 fame for region 100

    //Value Constraints
    uint8 constant minConnections = 1;
    uint8 constant maxConnections = 8;

    //Misc Config
    uint8 constant connectionChancePercent = 25;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Enums
    //////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////
    // Structs
    //////////////////////////////////////////////////////////////////////////////////////////

    struct regionHeader {
        address owner;
        bytes32 bytesName;
        string description;
        string linkURL;
        string regionMetaURL;
        uint seed;
        uint balance;
        uint32 creationTime;
    }

    struct region {
        regionHeader header;
        uint[] connections;
        mapping(uint=>uint) config;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Constructors/Initializers
    //////////////////////////////////////////////////////////////////////////////////////////

    function initialize(region storage r, address owner, uint randomSeed) public {
        r.header = regionHeader(
            owner,                      //Owner
            bytes32(0),                 //Name (in Bytes32 format)
            "",                         //Description
            "",                         //Link URL
            "",                         //RegionMetaURL
            random(randomSeed,1),       //Random Seed
            0,                          //Starting Balance
            uint32(block.timestamp)     //Creation Time
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Utilities
    //////////////////////////////////////////////////////////////////////////////////////////

    function random(uint seeda, uint seedb) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeda,seedb)));  
    }

	function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 source) public pure returns (string memory result) {
        uint8 len = 32;
        uint8 i = 0;
        for(i=0;i<32;i++){
            if(source[i]==0){
                len = i;
                break;
            }
        }
        bytes memory bytesArray = new bytes(len);
        for (i=0;i<len;i++) {
            bytesArray[i] = source[i];
        }
        result = string(bytesArray);
    }

    function getMinConnectionCount() public pure returns (uint8) {
        return minConnections;
    }
    
    function getMaxConnectionCount() public pure returns (uint8) {
        return maxConnections;
    }

    function getConnectionChancePercent() public pure returns (uint8) {
        return connectionChancePercent;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derivation / Calaculation Pure Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function getRandomProperty(region storage r, string memory propertyKey) public view returns (uint) {
        uint idx = uint(keccak256(abi.encodePacked(propertyKey)));
        return random(r.header.seed,idx);
    }

    function getName(region storage r) public view returns(string memory name) {
        name = bytes32ToString(r.header.bytesName);
    }

    function needsAnotherConnection(region storage r) public view returns(bool) {
        if(r.connections.length<minConnections){
            return true;
        }else{
            uint8 roll = uint8(random(r.header.seed,r.connections.length)%100);
            return roll<connectionChancePercent;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getRegionCost(uint regionCounter) public pure returns(uint) {
        return (((regionCounter+initialGrowthOffset)**regionGrowthExponent)*(regionCostBase*fakePercent))/fakePercentMultiplier;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////

    function setName(region storage r, string memory name) public {
        require(r.header.bytesName==bytes32(0));
        r.header.bytesName = stringToBytes32(name);
    }

    function addConnection(region storage r, uint connectionID) public {
        r.connections.push(connectionID);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buying Things
    //////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

}