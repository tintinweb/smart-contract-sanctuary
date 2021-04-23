/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;


interface University {
    
    
     function admitMe(string memory student) external  payable returns(bool admitted);
     function choseMajor(string memory student, string memory major) external;
     function submitScore(string memory student, int score)  external;

}

contract TemplateUniversity is University {
    string public name ;
    string[2] public majorList ;
    int public scoreMinimum ;
    mapping(address => string) private addressToProspectStudent;
    mapping(address => string) private addressToAdmittedStudent;
    mapping(string => int) private studentToScore;
    mapping(string => string) public studentToMajorRequesting;
    
    modifier majorIsOffered() {
        require(isIntendedMajorOffered(), "requested major is not offered" );
        _;
    }
    
    modifier appropriateCost(){
        require(msg.value == 100, "incorrect funds");
        _;
    }
    
    constructor(string memory name1, string memory major1, string memory major2, int scoreMin ){
        name = name1;
        scoreMinimum = scoreMin;
        majorList[0] = major1;
        majorList[1] =  major2;
        
        //Had this initially so I can pass the list of major but no way to test it on remix so I chose to pass in majors as single params
        /*for (uint i = 0; i < majorList.length; i++) {
        
            majorList[i] = bytes32ToString(majors[i]);
        }
        */
        
    }
    
    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory item){
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
        }
    return string(bytesArray);
    }
    
  
    function submitScore(string memory student, int score) override external {
        
        studentToScore[student] = score;
        addressToProspectStudent[msg.sender] = student;
        
    }
    
    function choseMajor(string memory student, string memory  major) override external {
        
        studentToMajorRequesting[student] = major;
        
    }
    
    
     function admitMe(string memory student) override public payable  majorIsOffered appropriateCost returns (bool admitted){
        
        require(studentToScore[student] >= scoreMinimum, "Your exam score is below school requirement, submit another score");
        addressToAdmittedStudent[msg.sender] = student;
        return true;
        
        
    }
    
    function isIntendedMajorOffered() private view returns (bool ismajoroffered){
        string memory student = addressToProspectStudent[msg.sender];
        string memory requestedMajor = studentToMajorRequesting[student];
        //; majorList[i] == requestedMajor
        for(uint256 i = 0; i < majorList.length; i++) {
        
        string memory currentMajor = majorList[i];
            if (keccak256(abi.encodePacked((currentMajor))) == keccak256(abi.encodePacked((requestedMajor)))) {
        
                return true;
        
            }
        
        }
    
        return false;
    }
    
}