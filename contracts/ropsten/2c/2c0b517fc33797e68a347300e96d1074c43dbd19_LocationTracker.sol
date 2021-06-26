/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LocationTracker {
    
    mapping(uint256 => Location) public location;
    uint locationIndex = 0;
    address public owner;
    
    struct Location {
        uint256 timeStamp;
        int256 lattitude;
        int256 longitude;
    }
    
    constructor() {      
        owner = msg.sender;
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function addLocation(int256 _lattitude, int256 _longitude) public isOwner {
        incrementIndex();
        location[locationIndex] = Location(block.timestamp, _lattitude, _longitude);
    }
    
    function incrementIndex() internal {
        locationIndex += 1;
    }
    
    function viewLocation(uint _locationIndex) public view returns(uint256, int256, int256) {
        return (location[_locationIndex].timeStamp, location[_locationIndex].lattitude, location[_locationIndex].longitude);
    }
    
}