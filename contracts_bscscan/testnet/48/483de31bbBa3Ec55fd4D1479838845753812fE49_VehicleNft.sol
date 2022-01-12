// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract VehicleNft is Ownable,ERC721 {
    uint256 public tokenCounter;
    address VehicleContract;

    constructor() ERC721("VEHICLE-TOKEN", "Vehicle") {
        tokenCounter=1;
    }
    function   safeMint(address to) public  returns(uint256) {
        require(msg.sender==VehicleContract,"error!");
        uint256 newTokenId=tokenCounter;
        _safeMint(to, newTokenId);
        tokenCounter=tokenCounter+1;
        return newTokenId;
    }

    function safeMint( address to,bytes memory _data) public  returns(uint256){
        require(msg.sender==VehicleContract,"error!");
        uint256 newTokenId=tokenCounter;
        _safeMint(to, newTokenId,_data);
        tokenCounter=tokenCounter+1;
        return newTokenId;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
    function setVehicleContract(address _vehicleContract) external onlyOwner{
        VehicleContract=_vehicleContract;
    }






}