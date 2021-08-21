/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Animalcare  {
    // 0.01 eth for creating a request for donation
    uint CREATE_Donation = 1e16;
    address donor;
    address animal_feedSupply;
    address geoTagteam;

 string public picHash;    

    function setImage(string memory _imageHash) public {
        picHash = _imageHash;
    }
    
    function getImage() public view returns(string memory){
        return picHash;
    }

    struct Animals {
        address doctor;
        address donator; // creator - vetenary (Doctor)
        uint shedno;
        string picHash;
    }
    

    mapping(uint => Animals) _animals;
    mapping(address => address) _animal_shed; // check mapping based on the whole logic
    mapping(uint => bool) _blacklist; // animal shed lisitngs
    mapping(uint => string) shedDetails;
    mapping(uint => string) health;

    constructor() {
        donor = msg.sender;
    }

    modifier animalExists(uint _animalHash) {
        require(_animals[_animalHash].donator != address(0), 'animal with the given hash does not exist');
        _;
    } 
   
    uint animalHash;
    
    uint shedno;
function createShed(string memory _data) public{
    shedno ++;
    shedDetails[shedno] = _data;
}
function createAnimal(address _doctor, uint _shedno, string memory _imageHash) public {
    animalHash ++;
    setImage(_imageHash);
    Animals memory animals = Animals({
        doctor:_doctor,
        donator:donor,
        shedno:_shedno,
        picHash:_imageHash
    });
    
     
} 

function updateAnimalHealth(uint _animalHash, string memory _healthRecord) public {
    health[_animalHash] = _healthRecord;
}

    function createDonation(uint _animalHash) public payable {
        require(msg.value == CREATE_Donation, 'incorrect fee paid');
        require(_animals[_animalHash].donator == address(0), 'animal with the given hash already exists');
        payable (address(this)).transfer(msg.value);
        _animals[_animalHash].donator = msg.sender;
       
    }

    function updateData(uint _animalHash, address _doc) public animalExists(_animalHash) {
        _animals[_animalHash].doctor = _doc;
    } 

    //auditing the facility
    function changeShed(uint _animalHash, uint _newShed) public animalExists(_animalHash) {
        require(msg.sender == _animals[_animalHash].donator, 'only the donator can change the provider');
       _animals[_animalHash].shedno = _newShed;
    }

    function blacklistShed(uint _badShed) public {
        require(msg.sender == donor, 'only the owner can blacklist a provider');
        _blacklist[_badShed] = true;
    }

    function unblockShed(uint _proveShed) public {
        require(msg.sender == donor, 'only the owner can unblock a provider');
        _blacklist[_proveShed] = false;
    }

    function getData(uint _animalHash) public view animalExists(_animalHash) returns(string memory,string memory, uint) {
        Animals memory currentProduct = _animals[_animalHash];
        return (currentProduct.picHash, health[_animalHash], currentProduct.shedno);
    } 
    receive()external payable{}
    // should display ipfs stored data and pictures via hash - check with sir! picHash,healthrecord,shed details
}