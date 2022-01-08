/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

pragma solidity ^0.5.0;

contract NFT4All {

    uint256 public resourceCount = 0;

    mapping(uint256 => Resource) public resources;

    struct Resource {uint256 id; string name; uint256 price; address payable owner; bool purchased; string resourceIPFSHash;}

    event ResourceDetailsAdded(uint256 id, string name, uint256 price, address payable owner, bool purchased, string resourceIPFSHash);
    event ResourceBought(uint256 id, string name, uint256 price, address payable owner, bool purchased, string resourceIPFSHash);

    function addResourceDetails(string memory _name, uint256 _price, string memory _resourceIPFSHash) public {
        require(bytes(_name).length > 0, "");
        require(_price > 0, "");
        resourceCount++;
        resources[resourceCount] = Resource(resourceCount, _name, _price, msg.sender, false, _resourceIPFSHash);
        emit ResourceDetailsAdded(resourceCount, _name, _price, msg.sender, false, _resourceIPFSHash);
    }

    function buyResource(uint256 _id) public payable {
        Resource memory resource = resources[_id];
        address payable _seller = resource.owner;
        require(resource.id > 0 && resource.id <= resourceCount, "");
        require(msg.value >= resource.price, "");
        require(!resource.purchased, "");
        require(_seller != msg.sender, "");
        resource.owner = msg.sender;
        resource.purchased = true;
        resources[_id] = resource;
        address(_seller).transfer(msg.value);
        emit ResourceBought(resourceCount, resource.name, resource.price, msg.sender, true,  resource.resourceIPFSHash);
    }
}