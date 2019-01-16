pragma solidity ^0.5.0;

 
contract TorrentContract {
    address public owner;
    string[] public torrents;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function addTorrent(string memory magnetLink) public {
        torrents.push(magnetLink);
    }
}