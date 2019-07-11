/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity =0.5.1;

contract MJIB_CDBS {

    address owner;

    struct Case {
        bytes32 hash;
        uint time;
    }
    mapping (string => Case) caseList;

    constructor() public {
        owner = msg.sender;
    }

    function createCase(string memory caseID, bytes32 hash) public {
        require(msg.sender == owner, "Permission Denied.");
        require(caseList[caseID].hash == 0x0, "Case ID exists.");
        require(caseList[caseID].time == 0, "Case ID exists.");
        caseList[caseID].hash = hash;
        caseList[caseID].time = now;
    }

    function getCase(string memory caseID) public view returns (bytes32, uint) {
        return (caseList[caseID].hash, caseList[caseID].time);
    }

}