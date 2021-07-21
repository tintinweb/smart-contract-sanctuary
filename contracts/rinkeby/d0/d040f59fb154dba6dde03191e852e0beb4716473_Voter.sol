/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity ^0.4.26;

contract Voter{
    //voter details
    struct VoterDetails {
        bytes32 name;
        bytes32 nic;
        uint128 hashOfSecret1;
        uint128 hashOfSecret2;
        bool submitted_to_review;
        bool to_be_deleted;
        bool to_be_added;
        bool deleted;
        bool verified;
        bool temp_registered;
        bool voted;
    }

    uint numVoters;

    mapping (address => VoterDetails) voters;

    function getNumOfVoters() public view returns(uint) {
        return numVoters;
    }

    //this should be updated by the applicant
    function addVoter(bytes32 name, bytes32 nic, uint128 hashOfSecret1,uint128 hashOfSecret2) public returns(bool,bool,bool,bool,bool,bool,bool) {
       //if user doesn't exist
       if(voters[msg.sender].name==0x0){
         voters[msg.sender] = VoterDetails(name,nic,hashOfSecret1,hashOfSecret2,false,false,false,false,false,false,false);
         numVoters++;
         voters[msg.sender].submitted_to_review = true;
         return (voters[msg.sender].submitted_to_review,voters[msg.sender].to_be_deleted,voters[msg.sender].to_be_added,voters[msg.sender].deleted,voters[msg.sender].verified,voters[msg.sender].temp_registered,voters[msg.sender].voted);
       }
       //if user exist(that means account reseted)
       voters[msg.sender].hashOfSecret1 = hashOfSecret1;
       voters[msg.sender].hashOfSecret2 = hashOfSecret2;
       voters[msg.sender].submitted_to_review = true;
       return (voters[msg.sender].submitted_to_review,voters[msg.sender].to_be_deleted,voters[msg.sender].to_be_added,voters[msg.sender].deleted,voters[msg.sender].verified,voters[msg.sender].temp_registered,voters[msg.sender].voted);

    }

    //query specific voter details
      function getVoter(address voterId) public view returns (bytes32,bytes32,uint128,uint128,bool,bool,bool,bool,bool,bool,bool) {
        VoterDetails memory v = voters[voterId];
        return (v.name,v.nic,v.hashOfSecret1,v.hashOfSecret2,v.submitted_to_review,v.to_be_deleted,v.to_be_added,v.deleted,v.verified,v.temp_registered,v.voted);
     }

    //this should be updated by the grama nildari
    function toBeDeleted(address voterAddress) public{
      voters[voterAddress].submitted_to_review = false;
      voters[voterAddress].to_be_added=false;
      voters[voterAddress].to_be_deleted = true;
    }

    //Voted
    function voted(address voterAddress) public{
      voters[voterAddress].voted = true;
    }


    //this should be updated by the grama nildari
    function toBeAdded(address voterAddress) public{
      voters[voterAddress].submitted_to_review=false;
      voters[voterAddress].to_be_deleted=false;
      voters[voterAddress].to_be_added=true;
    }

    //this should be updated by the district office
    function deleted(address voterAddress) public{
      voters[voterAddress].submitted_to_review=false;
      voters[voterAddress].to_be_added=false;
      voters[voterAddress].to_be_deleted=false;
      voters[voterAddress].verified=false;
      voters[voterAddress].deleted=true;
    }

    //this should be updated by the district office
    function verified(address voterAddress) public{
      voters[voterAddress].submitted_to_review=false;
      voters[voterAddress].to_be_added=false;
      voters[voterAddress].to_be_deleted=false;
      voters[voterAddress].deleted=false;
      voters[voterAddress].verified=true;
    }

    function reset(address voterAddress) public{
      voters[voterAddress].submitted_to_review=false;
      voters[voterAddress].to_be_added=false;
      voters[voterAddress].to_be_deleted=false;
      voters[voterAddress].deleted=false;
      voters[voterAddress].verified=false;
      voters[voterAddress].temp_registered=true;
      voters[voterAddress].voted=false;
    }


}