/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
 
contract BlockchainCoursePupils {
    address owner;
    uint public pupilsCount;

    struct pupil{
        string group;
        string name;
        string yearsOfSchooling;
    }

    mapping(address => pupil) pupils;    
    mapping(uint => address) pupilsIndex;
    mapping(address => bool) checkPupilsAddress;

    constructor(){
        owner = msg.sender;
        pupilsCount = 0;
    }
    
    event addPupilEvent(address, string, string, string);
    event editPupilEvent(address, string, string, string);

    function addPupil(string calldata group, string calldata name,  string calldata yearsOfSchooling)public{
        pupils[msg.sender] = pupil(group, name, yearsOfSchooling);
        if(checkPupilsAddress[msg.sender] == false){
            pupilsIndex[++pupilsCount] = msg.sender;
            checkPupilsAddress[msg.sender] = true;
            emit addPupilEvent(msg.sender, group, name, yearsOfSchooling);           
        }
        else{
            emit editPupilEvent(msg.sender, group, name, yearsOfSchooling);    
        }
    }

    function getPupilByAddress()public view returns(pupil memory){
        return pupils[msg.sender];
    }

    function getPupilByAddress(address _pupilAddress)public view returns(pupil memory){
        return pupils[_pupilAddress];
    }

    function getAllPupils()public view returns(pupil[] memory){
        pupil[] memory pupilsArray = new pupil[](pupilsCount);
        for(uint i = 0; i < pupilsCount; i++){
            pupilsArray[i] = pupils[pupilsIndex[i + 1]];
        }
        return pupilsArray;
    }

    function getAllPupilsAddress()public view returns(address[] memory){
        address[] memory pupilsAddressArray = new address[](pupilsCount);
        for(uint i = 0; i < pupilsCount; i++){
            pupilsAddressArray[i] = pupilsIndex[i + 1];
        }
        return pupilsAddressArray;
    }
}