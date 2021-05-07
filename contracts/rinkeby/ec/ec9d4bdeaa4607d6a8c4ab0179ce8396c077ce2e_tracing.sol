/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity ^0.5.16;

contract tracing {
    bytes32[] public listofIDs;
    bytes32[] public contactsMeetInfo;
    
    uint length = 0;

    function insertToBlockchain(bytes32[] memory infectedID, bytes32[] memory meetInfo) public {
        length += infectedID.length;
        for(uint i = 0; i < infectedID.length; ++i){
            listofIDs.push(infectedID[i]);
            contactsMeetInfo.push(meetInfo[i]);
        }
    }

    function getListOfIds() public view returns(bytes32[] memory){
        return listofIDs;
    }
    
    function getContactsMeetInfo() public view returns(bytes32[] memory){
        return contactsMeetInfo;
    }
    
    function clearData() public {
        delete listofIDs;
        delete contactsMeetInfo;
    }
}