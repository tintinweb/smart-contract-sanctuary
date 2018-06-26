pragma solidity ^0.4.23;

contract SimpleBillboard2 {
    
    address owner;
    mapping(address => string) ads;
    
    constructor() public {
        owner = msg.sender;
    }    
    
    function getBillboard(address _owner) view public returns(string) {
        return ads[_owner];
    }
    
    function setBillboard(string _ads) public {
        ads[msg.sender] = _ads;
    }
    
    function removeAds(address _ownerAds) public {
        require(owner == msg.sender);
        delete ads[_ownerAds];
    }
    
}