/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.20;

contract Vote {
    
    address[] public players;
    mapping (address => bool) public uniquePlayers;
    string public winner;
    string[] subject;
    uint256[] rating;
    
    function init () public {
        subject[0] = "Математический анализ";
        subject[1] = "Дифференциальные уравнения";
        subject[2] = "Дискретная математика";
        subject[3] = "Информатика";
        subject[4] = "Теория вероятности";
    }
    
    function play(address _participant, uint256 first, uint256 second, uint256 third) public {
        require (uniquePlayers[_participant] == false);
        require (first != second && first != third && second != third);
        require (first >= 0 && first <= 4);
        require (second >= 0 && second <= 4);
        require (third >= 0 && third <= 4);
        
        rating[first] = rating[first] + 1;
        rating[second] = rating[second] + 1;
        rating[third] = rating[third] + 1;
        
        players.push(_participant);
        uniquePlayers[_participant] = true;
    }
    
    function draw() external {
        
        uint256 winnerIndex = 0;
        
        for (uint256 i = 1; i <= 4; i++)
        {
            if (rating[i] > rating[winnerIndex])
            {
                winnerIndex = i; 
            }
        }
        
        winner = subject[winnerIndex];
    }
    
}