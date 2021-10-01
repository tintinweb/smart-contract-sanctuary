/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.0;

interface IRandom {
    function getRandom(address sender) external returns (uint randomNumber);

    function getViewRandom(address sender) external view returns (uint randomNumber);
}

contract Random is IRandom {
    event NewRandom(string clientSeed, string serverSeed, uint randNum, uint id);

    address immutable private server;
    address private token;

    mapping (address => uint) _randomNumbers;
    mapping (string => bool) _seeds;

    constructor(address serverAddress) {
        server = serverAddress;
    }
    
    function setRandom(uint randNum, address user, string memory clientSeed, string memory serverSeed, uint id) external {
        require(msg.sender == server, "Random: Only server can set random value for user");
        require(_randomNumbers[user] == 0, "Random: User has already random value");
        require(_seeds[serverSeed] == false, "Random: The seed has been already used");
        emit NewRandom(clientSeed, serverSeed, randNum, id);
        _randomNumbers[user] = randNum * 1000;
    }

    function setTokenAddress(address tokenAddress) external {
        require(server == msg.sender, "Random: Only server can set token address");
        token = tokenAddress;
    }

    function getViewRandom(address sender) external override view returns (uint randomNumber){
        return _randomNumbers[sender];
    }

    function getRandom(address sender) external override returns (uint randomNumber){
        require(token == msg.sender, "Random: Only token address can call this function");
        uint randNum = _randomNumbers[sender];
        _randomNumbers[sender] = 0;
        return randNum;
    }
}