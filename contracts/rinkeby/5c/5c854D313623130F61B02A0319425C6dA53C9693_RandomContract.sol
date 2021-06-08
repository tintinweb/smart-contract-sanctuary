/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// File: contracts\RandomInterface.sol

pragma solidity 0.6.6;

interface RandomInterface{

    function getRandomNumber() external returns(uint256);
}

// File: contracts\RandomContract.sol

pragma solidity 0.6.6;


contract RandomContract is RandomInterface{

    uint256 private seed;

    function getRandomNumber() external override returns(uint256){
        seed = seed + now + 3;
        bytes32 hash = blockhash(block.number - 1);
        uint256 random = uint256(keccak256(abi.encodePacked(hash, now, seed))) % block.number;
        return random;
    }
}