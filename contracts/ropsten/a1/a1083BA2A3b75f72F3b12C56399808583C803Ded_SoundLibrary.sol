/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SoundLibrary {
    
    struct Sound {
        uint256 id;
        string hash;
        uint256 price;
        address payable author;
    }

    uint256 public soundCount = 0;
    mapping(uint256 => Sound) public sounds;
    mapping(uint256 => address[]) private soundToDownloaders;
    
    constructor() {
        
    }
    
    function uploadSound(string memory _hash, uint256 _price) public {
        require(bytes(_hash).length > 0);
       
    
        sounds[soundCount] = Sound(soundCount, _hash, _price, payable(msg.sender));
        soundCount++;
    }
    
    function sample(uint256 _id) public payable {
        require(_id <= soundCount);
        Sound memory _sound = sounds[_id];
        
        soundToDownloaders[_id].push(msg.sender);
        address payable _author = _sound.author;
        
        _author.transfer(msg.value);
        
    }
    
    function getApprovedDownloader(uint256 _id) public view returns(address[] memory) {
        return soundToDownloaders[_id];
    }
    
    function getPriceOfSound(uint256 _id) public view returns(uint256) {
        Sound memory _sound = sounds[_id];
        
        return _sound.price;
    }

}