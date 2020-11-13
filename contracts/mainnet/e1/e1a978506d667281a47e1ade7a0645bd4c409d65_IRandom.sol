pragma solidity ^0.7.4;

/*
* @title IRandom contract interface.
*/
interface IRandom {
    // @notice get random number between min max values
    function getNumber(uint min, uint max) external pure returns (uint256);
}
