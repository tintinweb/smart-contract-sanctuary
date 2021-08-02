/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

// File: contracts/Test.sol

pragma solidity ^0.8.0;

contract Test {

    string public word;

    function say() external view returns (string memory) {
        return word;
    }

    function setWord(string memory _word) external {
        word = _word;
    }

}