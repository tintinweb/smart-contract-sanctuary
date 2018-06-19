pragma solidity ^0.4.11;

contract IHashtag {

    // inherited
    function owner() public constant returns(address);
    function transferOwnership(address newOwner);

    function name() public constant returns(string);
    function registeredDeals() public constant returns(uint);
    function successfulDeals() public constant returns(uint);
    function validFactories() public constant returns(bool);
    function commission() public constant returns(uint);
    function metadataHash() public constant returns(string);
    function setMetadataHash(string _metadataHash);
    function addFactory(address _factoryAddress);
    function removeFactory(address _factoryAddress);
    function getRepTokenAddress() returns(address);
    function getTokenAddress() returns(address);
    function getConflictResolver() returns(address);
    function registerDeal(address _dealContract,address _dealOwner);
    function mintRep(address _receiver,uint _amount);
}
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}
contract HashtagList is Ownable {

    mapping (address => string) storedMap;

    function setBytesRaw(string x) {
        storedMap[msg.sender] = x;
    }

    function setBytes(address _hashtagAddress, string x) {
        IHashtag hashtag = IHashtag(_hashtagAddress);
        if (msg.sender != hashtag.getConflictResolver()) {
            throw;
        }

        storedMap[_hashtagAddress] = x;
    }

    function getMap(address _hashtagAddress) constant returns (string returnValue) {
        returnValue = storedMap[_hashtagAddress];
    }

}