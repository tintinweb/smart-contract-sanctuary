pragma solidity ^0.4.24;

contract CryptoFlipCar2  {
    mapping(uint256 => mapping(uint256 => bytes32)) public names;

    function setName(uint256 cardType, uint256 cardId, bytes32 name) public {
        names[cardType][cardId] = name;
    }
}