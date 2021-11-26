// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract hotsea {

    ERC721 nft = ERC721(0x87BD1b0AE8B88A409118D73894F3D9b7D13E4bd9);
    uint price = 1;

    function setPrice(uint _price) public {
        require(msg.sender == 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7);
        price = _price;
    }

    function sell() public payable {
        require( msg.value == price * 1 ether);
        nft.transferFrom(0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7, msg.sender, 12);
    }

    function withdraw() public {
        require( msg.sender == 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7 );
        payable(0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7).transfer(address(this).balance);
    }
}