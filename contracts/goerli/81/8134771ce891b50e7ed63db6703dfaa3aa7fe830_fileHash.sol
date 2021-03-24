/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity <=0.8.3;

contract fileHash{
    uint counter;
    struct record{
        string hash;
        uint timestamp;
    }
    
    mapping(uint => record) id2hash;
    mapping(string => uint) hash2id;
    
    function setHash(string memory _hash) public{
        id2hash[counter].hash = _hash;
        id2hash[counter].timestamp = block.timestamp;
        hash2id[_hash] = counter;
        counter++;
    }
    
    function getIDByHash(string memory _hash) public view returns(uint){
        return hash2id[_hash];
    }
    
    function getHashByID(uint _id) public view returns(string memory _hash){
        return id2hash[_id].hash;
    }
    
    function getTimestampByID(uint _id) public view returns(uint){
        return id2hash[_id].timestamp;
    }
    
    function getTimestampByHash(string memory _hash) public view returns(uint){
        uint id = getIDByHash(_hash);
        return id2hash[id].timestamp;
    }
    
    function getCount() public view returns(uint){
        return counter;
    }
}