// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./IBNBHCharacter.sol";



interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
    function getRandomSeedUsingHash(address user, bytes32 hash) external view returns (uint256 seed);
}


contract BNBHero is Ownable {

    IRandoms public randoms;
    IBNBHCharacter public characters;
    IBEP20 public bnbhToken;
    uint256 public characterPrice = 5000 * 10 ** 18;

    event UpdatedCharacterPrice(uint256 price);
    event UpdatedTokenContract(address tokenAddress);
    event UpdatedCharacterContract(address characterAddress);
    constructor() {
        randoms = IRandoms(0x413A7553Bfce459FB69ebE5a0587d6C5447BA3c5);        
    }
    function setCharacterPrice (uint256 price) public onlyOwner{
        characterPrice = price;
        emit UpdatedCharacterPrice(price);
    }
    function setBNBHTokenContract(address tokenAddress) public onlyOwner {
        bnbhToken = IBEP20(tokenAddress);
        emit UpdatedTokenContract(tokenAddress);
    }
    function setCharacterContract(address characterAddress) public onlyOwner {
        characters = IBNBHCharacter(characterAddress);
        emit UpdatedCharacterContract(characterAddress);
    }
    function createNewHero() public {
        require(bnbhToken.balanceOf(msg.sender) >= characterPrice, "Insufficient BNBH balance");
        bnbhToken.transferFrom(msg.sender, address(this), characterPrice);
        uint256 seed = randoms.getRandomSeed(msg.sender);
        characters.mint(msg.sender, seed);        
    }
}