/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity 0.8.0;


// SPDX-License-Identifier: MIT
contract GetRandom {
    uint256 mintedCount;
    uint256[] mintedNumber;
    
    mapping(uint => bool) public minted;
    
    function getRandom() public returns (uint256) {
        uint256 nonce = 0;
        uint256 randomnumber = uint(keccak256(abi.encodePacked(getTime(), getBlock(), getDifficulty(), nonce, address(this), msg.sender))) % 1000;
        if(randomnumber == 0) {
            randomnumber = randomnumber + 1;
        }
        if(minted[randomnumber] == true) {
            nonce = randomnumber + block.timestamp;
            getRandom();
        }
        minted[randomnumber] = true;
        mintedNumber.push(randomnumber);
        mintedCount++;
        return randomnumber;
    }
    
    function returnAllNumber() public view returns (uint256[] memory) {
        return mintedNumber;
    }
    
    function mintedLenght() public view returns (uint256) {
        return mintedCount;
    }
    
    function getTime() internal view returns(uint256) {
        return block.timestamp;
    }
    
    function getBlock() internal view returns(uint256) {
        return block.number;
    }
    
    function getDifficulty() internal view returns(uint256) {
        return block.difficulty;
    }
}