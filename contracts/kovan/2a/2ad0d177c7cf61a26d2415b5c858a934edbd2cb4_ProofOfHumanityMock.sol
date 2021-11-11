/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// File: contracts/Mocks/ProofOfHumanityMock.sol

pragma solidity ^0.7.0;

contract ProofOfHumanityMock {
  
    mapping(address => bool) public isRegistered;
    uint private deployment = block.timestamp;

    function setHuman(address _human, bool _isRegistered) external {
        isRegistered[_human] = _isRegistered;
    }
}