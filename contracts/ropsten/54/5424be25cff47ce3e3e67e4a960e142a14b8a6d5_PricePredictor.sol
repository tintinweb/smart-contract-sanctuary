/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

///SPDX-License-Identifier: No-license
pragma solidity "0.8.4";

contract PricePredictor{
    event Win(string winner);
    mapping(address => Player) private  _players;
    address [] private  _playersAddresses;
    address private _owner;
    
    struct Player{
        string name;
        uint prediction;
    }
    
    constructor (){
        // require(msg.value >= 1 ether, "Need to add one ether at the beginning - just for fun ;)");
        _owner = msg.sender;
    }
    
    modifier _isOwner(){
        require(msg.sender == _owner);
        _;
    }
    
    function Join(string memory name, uint price) public payable{
        _playersAddresses.push(msg.sender);
        _players[msg.sender] = Player(name, price);
    }
    
    function PickTheWinner(uint price) public payable {
        int bestResult = 0;
        address currentWinner;
        string memory winnersName;
        for (uint i = 0; i < _playersAddresses.length; i++) {
           uint playerPrice = _players[_playersAddresses[i]].prediction;
           int currentPrediction = int(playerPrice) - int(price);
           
           if (currentPrediction < 0){
               currentPrediction = currentPrediction * -1;
           }
           
           if (bestResult == 0){
               bestResult = currentPrediction;
               currentWinner = _playersAddresses[i];
               winnersName = _players[_playersAddresses[i]].name;
           }
           else{
               if (currentPrediction < bestResult) {
                    bestResult = currentPrediction;
                    currentWinner = _playersAddresses[i];
               }
           }
        }
        
        uint256 contractBalance = address(this).balance;
        address payable winner = payable(currentWinner);
        winner.transfer(contractBalance);
        
        emit Win(winnersName);
        
        _playersAddresses = new address[](0);
    }
}