/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MyContract {

    struct constat {
        uint256 userIdA;
        uint256 assuranceIdA;
        string constatCidA;
        uint256 userIdB;
        uint256 assuranceIdB;
        string constatCidB;
        uint8 state;
    }

    constat[] private constats;

    function addConstat(uint256 _userIdA,uint256 _assuranceIdA,string memory _constatCidA,uint256 _userIdB,uint256 _assuranceIdB,string memory _constatCidB,uint8 _state) public {
        constats.push(constat(_userIdA,_assuranceIdA, _constatCidA,_userIdB,_assuranceIdB, _constatCidB,_state));
    }
    
    function changeState(string memory _constatCid) public {
        for(uint256 i = 0; i < constats.length ; i++){
            if(keccak256(abi.encodePacked((constats[i].constatCidA))) ==  keccak256(abi.encodePacked((_constatCid))) ||
            keccak256(abi.encodePacked((constats[i].constatCidB))) == keccak256(abi.encodePacked((_constatCid)))){
                constats[i].state = 1;
            }
        }
    }
    
    function returnState(string memory _constatCid) public view returns (uint8 state) {
        for(uint256 i = 0; i < constats.length ; i++){
            if(keccak256(abi.encodePacked((constats[i].constatCidA))) ==  keccak256(abi.encodePacked((_constatCid))) ||
            keccak256(abi.encodePacked((constats[i].constatCidB))) == keccak256(abi.encodePacked((_constatCid)))){
                return constats[i].state ;
            }
            
        }
    }
    
    function getConstatByUserId(uint256 _userId)public view returns (constat[] memory _constat)
    {
    uint256 count;
        for (uint256 i = 0; i < constats.length ; i++) {
            if (constats[i].userIdA ==  _userId || constats[i].userIdB ==  _userId) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userIdA ==  _userId || constats[i].userIdB ==  _userId) {
                res[j] = constats[i];
                j++;
            }    
        }
    return (res);
    }
    
    function getPendingConstatByuserId(uint256 _userId)public view returns (constat[] memory _constat)
    {
    uint256 count;
        for (uint256 i = 0; i < constats.length ; i++) {
            if (constats[i].userIdA ==  _userId || constats[i].userIdB ==  _userId && constats[i].state== 0) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userIdA ==  _userId || constats[i].userIdB ==  _userId && constats[i].state== 0) {
                res[j] = constats[i];
                j++;
            }    
        }
    return (res);
    }
    
    function getConfirmedConstatByuserId(uint256 _userId)public view returns (constat[] memory _constat)
    {
    uint256 count;
        for (uint256 i = 0; i < constats.length ; i++) {
            if (constats[i].userIdA ==  _userId || constats[i].userIdB ==  _userId && constats[i].state== 1) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userIdA ==  _userId || constats[i].userIdB ==  _userId && constats[i].state== 1) {
                res[j] = constats[i];
                j++;
            }    
        }
    return (res);
    }
    
    function getConstatByAssuranceId(uint256 _assuranceId)public view returns (constat[] memory _constat)
    {
    uint256 count;
        for (uint256 i = 0; i < constats.length ; i++) {
            if (constats[i].assuranceIdA ==  _assuranceId || constats[i].assuranceIdB ==  _assuranceId ) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].assuranceIdA ==  _assuranceId || constats[i].assuranceIdB ==  _assuranceId) {
                res[j] = constats[i];
                j++;
            }    
        }
    return (res);
    }
    
    function getAllConstat()public view returns (constat[] memory _constat)
    {
    return (constats);
    }
    
}