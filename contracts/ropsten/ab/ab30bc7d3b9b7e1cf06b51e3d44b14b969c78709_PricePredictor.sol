/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

///SPDX-License-Identifier: No-license
pragma solidity "0.8.4";

contract PricePredictor{
    event Win(string winner);
    mapping(uint => Player) private  _players;
    address private _owner;
    uint private totalNumberOfPlayers;
    
    struct Player{
        address sender;
        string name;
        uint prediction;
    }
    
    constructor () payable{
        require(msg.value >= 0.001 ether, "Need to add at least 0.001 ether at the beginning - just for fun ;)");
        _owner = msg.sender;
        totalNumberOfPlayers = 0;
    }
    
    modifier _isOwner(){
        require(msg.sender == _owner);
        _;
    }
    
    function Join(string memory name, uint price) public payable{
        require(msg.value >= 0.001 ether, "Need to add at least 0.001 ether");
        
        _players[totalNumberOfPlayers] = Player(msg.sender, name, price);
        totalNumberOfPlayers++;
    }
    
    function PickTheWinner(uint price) public _isOwner {
        int bestResult = 0;
        address currentWinner;
        string memory winnersName;
        for (uint i = 0; i < totalNumberOfPlayers; i++) {
           uint playerPrice = _players[i].prediction;
           int currentPrediction = int(playerPrice) - int(price);
           
           if (currentPrediction < 0){
               currentPrediction = currentPrediction * -1;
           }
           
           if (bestResult == 0 || currentPrediction < bestResult) {
                bestResult = currentPrediction;
                currentWinner = _players[i].sender;
                winnersName = _players[i].name;
            }     
        }
        
        uint256 contractBalance = address(this).balance;
        address payable winner = payable(currentWinner);
        winner.transfer(contractBalance);
        
        emit Win(winnersName);
        
        totalNumberOfPlayers = 0;
    }
}