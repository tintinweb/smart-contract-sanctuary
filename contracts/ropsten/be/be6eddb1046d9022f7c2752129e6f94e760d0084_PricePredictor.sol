/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

//SPDX-License-Identifier: No-license
pragma solidity "0.8.7";

contract PricePredictor{
    struct userPreditions {
        string name;
        uint prediction;
        address addr;
    }
    
    mapping (uint => userPreditions) playersPredictions;
    address public owner;
    uint private totalNumberOfPlayers = 0;
    
    event WinnerChosen(string a);
    
    constructor(){
        owner = msg.sender;
    }
    
    function Join (uint price, string memory name) public payable {
        require(msg.value >= 0.01 ether, "Need to add at least 0.01 ether");
       
        playersPredictions[totalNumberOfPlayers] = userPreditions(name, price, msg.sender);
        totalNumberOfPlayers++;
    }
    
    function PickTheWinner (uint price) public isOwner {
        
        int bestResult = 0;
        address payable currentWinner;
        string memory winnerName;
        
        for (uint i = 0; i < totalNumberOfPlayers; i++) {
                                     
            int temp = int(playersPredictions[i].prediction) - int(price);
            
            if (temp < 0) {
                temp = temp * -1;
            }
            
            if (bestResult == 0 || temp < bestResult) {
                bestResult = temp;
                currentWinner = payable(playersPredictions[i].addr); 
                winnerName = playersPredictions[i].name;
            }
        }
        
        uint contractBalance = address(this).balance;
        currentWinner.transfer(contractBalance);
        
        emit WinnerChosen(winnerName);
        // send stored balance to the winner
        // clear arrays?
        
        totalNumberOfPlayers = 0;
    }
    
    modifier isOwner() {
        require(msg.sender == owner,  "JEDI i FOKI PANY");
        _;
    }
}