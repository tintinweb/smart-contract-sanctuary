/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.5.16;

contract tracing {
    bytes32[] public listofIDs;
    uint length = 0;

    function insertToBlockchain(bytes32[] memory infectedID) public {
        length += infectedID.length;
        for(uint i = 0; i < infectedID.length; ++i){
            listofIDs.push(infectedID[i]);
        }
    }

    function readFromBlockchain() public view returns(bytes32[] memory){
        return listofIDs;
    }
}