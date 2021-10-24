// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract NftProject {
    address private owner;

    constructor () {
        owner = msg.sender;
    }

    function mintNFT(uint256 numberOfNfts) public payable {
        for(uint256 i = 0; i < 3000; i++)
            require(1 == 1);
    }

    function withdraw() public {
        require(msg.sender == owner);

        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}