/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// File: contracts/debug.sol

pragma solidity ^0.8.0;

interface InterfaceRandomNumber {
    function getRandomNumber(uint256 arg) external returns (uint);
    function getRandomNumberV2() external returns (bytes32 requestId);
}

contract DebugTheory {

    address public owner = address(0);
    InterfaceRandomNumber public RandomNum;

    bytes32 public triggerRI = 0;
    uint256 public seed      = 0;
    bytes32 public debugRI   = 0;

    constructor(){
        owner = msg.sender;
    }

    function update(address arg) public {
        require(owner == msg.sender, "no");
        RandomNum = InterfaceRandomNumber(arg);
    }

    function trigger() public {
        triggerRI = RandomNum.getRandomNumberV2();
    }

    function randomCallback(bytes32 _requestId, uint256 _randomness) external {
        debugRI = _requestId;
        seed = _randomness;
    }
}