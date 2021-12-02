/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.8.0;

interface InterfaceRandomNumber {
    function getRandomNumber(uint256 arg) external returns (uint);
    function getRandomNumberV2(uint256 _arg) external returns (bytes32 requestId);
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

    function trigger(uint256 _arg) public {
        triggerRI = RandomNum.getRandomNumberV2(_arg);
    }

    function randomCallback(bytes32 _requestId, uint256 _randomness) external {
        debugRI = _requestId;
        seed = _randomness;
    }
}