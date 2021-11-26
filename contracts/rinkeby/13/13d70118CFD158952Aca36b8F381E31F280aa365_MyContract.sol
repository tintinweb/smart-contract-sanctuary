/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MyContract {

    struct constat {
        uint256 userId;
        uint256 assuranceId;
        string constatCid;
        string QRcode;
        uint256 state;
    }

    constat[] private constats;

    function addConstat(uint256 _userId,uint256 _assuranceId,string memory _constatCid,string memory _qrCode,uint256 _state) public {
        constats.push(constat(_userId,_assuranceId, _constatCid,_qrCode,_state));
    }
    
    function changeState(string memory _constatCid,uint256 _state) public {
        for(uint256 i = 0; i < constats.length ; i++){
            if(keccak256(abi.encodePacked((constats[i].constatCid))) ==  keccak256(abi.encodePacked((_constatCid)))){
                constats[i].state = _state;
            }
        }
    }
    
    function returnState(string memory _constatCid) public view returns (uint256 state) {
        for(uint256 i = 0; i < constats.length ; i++){
            if(keccak256(abi.encodePacked((constats[i].constatCid))) ==  keccak256(abi.encodePacked((_constatCid)))){
                return constats[i].state ;
            }
        }
    }

    function getConstatByUserId(uint256 _userId)public view returns (constat[] memory _constat)
    {
    uint256 count;
        for (uint256 i = 0; i < constats.length ; i++) {
            if (constats[i].userId ==  _userId) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userId ==  _userId ) {
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
            if (constats[i].userId ==  _userId && constats[i].state== 0) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userId ==  _userId && constats[i].state== 0) {
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
            if (constats[i].userId ==  _userId && constats[i].state== 1) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userId ==  _userId && constats[i].state== 1) {
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
            if (constats[i].assuranceId ==  _assuranceId) {
                count++;
            }
        }
        constat [] memory res = new constat[](count);
        uint j;
        for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].assuranceId ==  _assuranceId) {
                res[j] = constats[i];
                j++;
            }    
        }
    return (res);
    }

    function getSecondConstatByQrCodeForUser(string memory _qrCode,uint256 _userId)public view returns (constat memory _constat){
         for (uint256 i = 0; i < constats.length; i++) {
            if (constats[i].userId !=  _userId && keccak256(abi.encodePacked((constats[i].QRcode))) == keccak256(abi.encodePacked((_qrCode)))) {
                return constats[i];
            }    
        }
    }

    function getSecondConstatByQrCodeForAssurance(string memory _qrCode, string memory _constatCid)public view returns (constat memory _constat){
         for (uint256 i = 0; i < constats.length; i++) {
            if (keccak256(abi.encodePacked((constats[i].constatCid))) != keccak256(abi.encodePacked((_constatCid))) && keccak256(abi.encodePacked((constats[i].QRcode))) == keccak256(abi.encodePacked((_qrCode)))) {
                return constats[i];
            }    
        }
    }
    
    function getAllConstat()public view returns (constat[] memory _constat)
    {
    return (constats);
    }
    
}