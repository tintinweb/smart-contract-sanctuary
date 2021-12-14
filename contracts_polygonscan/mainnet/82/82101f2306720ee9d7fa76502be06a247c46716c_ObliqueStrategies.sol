/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Data {
    function drawRandom() external view returns (string memory);
}

contract ObliqueStrategies {
    address public owner;
    address private data;
    event CardDrawn(string strategy, address recipient);

    constructor() {
        owner = msg.sender;
    }

    function draw() public  {
        require(data != address(0), "data not set");
        emit CardDrawn(Data(data).drawRandom(), msg.sender);
    }

    function updateData(address addr) public {
        require(msg.sender == owner, "not owner");
        data = addr;
    }
}