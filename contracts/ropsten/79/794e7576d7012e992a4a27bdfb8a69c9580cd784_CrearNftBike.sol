/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract CrearNftBike{
    string name;
    string color;
    string brand;
    uint256 fuel;
    uint256 level;


    function CrearNft(string calldata _name, string calldata _color, string calldata _brand, uint256 _fuel, 
    uint256 _level ) public{
        name = _name;
        color = _color;
        brand = _brand;
        fuel = _fuel;
        level = _level;
        
    }

    function ReadNftName() public view returns(string memory){
            return name;
    }

    function ReadNftColor() public view returns(string memory){
            return color;
    }

    function ReadNftBrand() public view returns(string memory){
            return brand;
    }

    function ReadNftFuel() public view returns(uint256){
            return fuel;
    }

    function ReadNftLevel() public view returns(uint256){
            return level;
    }


}