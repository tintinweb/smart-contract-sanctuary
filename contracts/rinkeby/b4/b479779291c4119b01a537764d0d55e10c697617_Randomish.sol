/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.5.1;

contract Randomish {

    uint public constant MAX = uint(0) - uint(1); // using underflow to generate the maximum possible value
    uint public constant SCALE = 500;
    uint public constant SCALIFIER = MAX / SCALE;
    uint public constant OFFSET = 100; 


    // generate a randomish  number between 100 and 600.
    // Warning: It is trivial to know the number this function returns BEFORE calling it. 

    function randomish() public view returns(uint) {
        uint seed = uint(keccak256(abi.encodePacked(now)));
        uint scaled = seed / SCALIFIER;
        uint adjusted = scaled + OFFSET;
        return adjusted;
    }
}