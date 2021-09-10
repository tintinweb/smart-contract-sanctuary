/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.5.1;

contract Randomish {

    uint public constant MAX = uint(0) - uint(1); // using underflow to generate the maximum possible value
    uint public constant SCALE = 20;
    uint public constant SCALIFIER = MAX / SCALE;
    uint public constant OFFSET = 1; 


    // generate a randomish  number between 1 and 20.
    // Warning: It is trivial to know the number this function returns BEFORE calling it. 

    function randomish() public view returns(uint) {
        uint seed = uint(keccak256(abi.encodePacked(now)));
        uint scaled = seed / SCALIFIER;
        uint adjusted = scaled + OFFSET;
        return adjusted;
    }
}