/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// File contracts/Hasher.sol

pragma solidity ^0.8.0;

contract Hasher {
    
    uint randomValueNonce;
    mapping(address => uint) public userRandomValue;
    
    function generateRandomValue() public {
        uint randoVal = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomValueNonce)));
        userRandomValue[msg.sender] = randoVal;
        randomValueNonce = (randoVal % 20);
    }

    /// @notice Generate hash values for users to use in pricing session
    function getHash(uint _appraisal) view public returns (bytes32) {
        return keccak256(abi.encodePacked(_appraisal, msg.sender, userRandomValue[msg.sender]));
    }
    
    function getUserRandomValue(address _user) view external returns (uint){
        return userRandomValue[_user];
    }
}