//SourceUnit: MiningContract.sol

pragma solidity ^0.4.25;

contract MiningContract {
    uint public tokenId = 1002573;
    uint public stageSize = 5;
    uint public stageReward = 3000000;
    
    uint public prevStage;
    address public richestAddress;
    uint public richestBalance;
    
    event Mine(address winner, uint reward);
    
    function getCurrentStage() public view returns (uint) {
        return block.number / stageSize;
    }
    
    function mine() external {
        uint balance = msg.sender.tokenBalance(tokenId);
        require(balance > 0);

        uint stage = getCurrentStage();
        
        if (stage > prevStage) {
            if (prevStage > 0 && richestBalance > 0) {
                uint amount = stageReward * (stage - prevStage);
                richestAddress.transferToken(amount, tokenId);
                emit Mine(richestAddress, amount);
                richestBalance = 0;
            }
            prevStage = stage;
        }
        
        if (balance > richestBalance) {
            richestBalance = balance;
            richestAddress = msg.sender;
        }
    }
}