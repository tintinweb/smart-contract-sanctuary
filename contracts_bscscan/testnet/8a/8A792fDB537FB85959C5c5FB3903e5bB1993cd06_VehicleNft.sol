// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC721.sol";

contract VehicleNft is ERC721 {
    uint256 public tokenCounter;

    constructor() ERC721("VEHICLE-TOKEN", "Vehicle") {
        tokenCounter=0;
    }


    function   safeMint(address to) public  returns(uint256) {
        uint256 newTokenId=tokenCounter;
        _safeMint(to, newTokenId);
        tokenCounter=tokenCounter+1;
        return newTokenId;
    }

    function safeMint( address to,bytes memory _data) public  returns(uint256){
        uint256 newTokenId=tokenCounter;
        _safeMint(to, newTokenId,_data);
        tokenCounter=tokenCounter+1;
        return newTokenId;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }





}