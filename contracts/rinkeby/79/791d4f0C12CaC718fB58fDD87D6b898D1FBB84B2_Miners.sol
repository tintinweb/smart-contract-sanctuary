// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Miners {
    struct Miner  {
        string minerType;
        bool isSkilled;
        bool isMining;
        string uri;
        string resourceType;
        bool isMinted;
        string[] attributes;
        uint256[] values;
        }

    mapping (address => mapping (string => uint[])) public minerBalancesByTypes;
    mapping (address => mapping (string => uint[])) public minerBalancesByMines;
    mapping(address => uint256) public startTimes;
    mapping(uint256=> Miner) public miners;

    function isMinted(uint256 minerId) public view returns(bool isIndeed) {
        return miners[minerId].isMinted;
    }

    function setMinerBalancesByTypes(string memory minerType, uint256 minerId, address owner)  public {
        minerBalancesByTypes[owner][minerType].push(minerId);
    }

    function getMinerBalancesByMines(address owner, string memory resourceType)  public view returns(uint256[] memory){
        return minerBalancesByMines[owner][resourceType];
    }

    function getMinerBalancesByTypes(address owner, string memory minerType)  public view returns(uint256[] memory){
        return minerBalancesByTypes[owner][minerType];
    }

    function isMinerMining(uint256 minerId) public view returns(bool){
        return miners[minerId].isMining;
    }

    function addMinerToMine(address owner, string memory resourceType, uint256 minerId) public {
        miners[minerId].isMining = true;
        minerBalancesByMines[owner][resourceType].push(minerId);
    }

    function findIndex(uint minerId) private {

    }

    function removeMinerFromMine(address owner, string memory resourceType, uint256 minerId) public {
        miners[minerId].isMining = false;
        uint256[] memory minersMining = minerBalancesByMines[owner][resourceType];
        uint256 index = minersMining.length+1;
        for(uint256 i=0; i<minersMining.length; i++) {
             if(minersMining[i]==minerId) {
                 index =i;
             }
        }
        require(index<minersMining.length, "Id not found");
        minerBalancesByMines[owner][resourceType][index] = minerBalancesByMines[owner][resourceType][minersMining.length-1];
        minerBalancesByMines[owner][resourceType].pop();
    }

    function setStartTimes(address owner) public {
        startTimes[owner] = block.timestamp;
    }

    function getStartTimes(address owner) public view returns(uint256){
        return startTimes[owner];
    }

    function setTokenUri(uint256 minerId, string memory tokenURI) public {
        miners[minerId].uri = tokenURI;
    }

    function getMinerType(uint256 minerId) public view returns(string memory){
        return miners[minerId].minerType;
    }

    function getResourceType(uint256 minerId) public view returns(string memory){
        return miners[minerId].minerType;
    }

    function isMinerSkilled(uint256 minerId) public view returns(bool){
        return miners[minerId].isSkilled;
    }

    function addMiner(address owner, uint256 minerId, string memory minerType, string memory resourceType, bool isSkilled, bool isMining,
        string memory tokenURI) public returns(bool success) {
        if(isMinted(minerId)) revert();
        miners[minerId].minerType = minerType;
        miners[minerId].resourceType = resourceType;
        miners[minerId].isSkilled = isSkilled;
        miners[minerId].isMining = isMining;
        miners[minerId].uri = tokenURI;
        miners[minerId].isMinted = true;
        setMinerBalancesByTypes(minerType, minerId, owner);
        return true;
    }

}