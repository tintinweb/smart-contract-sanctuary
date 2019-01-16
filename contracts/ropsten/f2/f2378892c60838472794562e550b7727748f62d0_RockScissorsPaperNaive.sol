pragma solidity ^0.4.24;
contract RockScissorsPaperNaive
{
    mapping (string => mapping(string => int)) resultMatrix;
    address player1;
    address player2;
    string public player1Move;
    string public player2Move;

    constructor() public
    {
        // 0 means Draw
        resultMatrix["rock"]["rock"] = 0;
        resultMatrix["rock"]["paper"] = 2;
        resultMatrix["rock"]["scissors"] = 1;
        resultMatrix["paper"]["rock"] = 1;
        resultMatrix["paper"]["paper"] = 0;
        resultMatrix["paper"]["scissors"] = 2;
        resultMatrix["scissors"]["rock"] = 2;
        resultMatrix["scissors"]["paper"] = 1;
        resultMatrix["scissors"]["scissors"] = 0;
    }
    
    function getWinner() public constant returns (int x)
    {
        return resultMatrix[player1Move][player2Move];
    }
    
    function play(string currentMove) public payable
    checkFunds(5)
    returns (int w)
    {
        if (player1 == 0)
            player1 = msg.sender;
        else if (player2 == 0)
            player2 = msg.sender;
        if (msg.sender == player1)
            player1Move = currentMove;
        else if (msg.sender == player2)
            player2Move = currentMove;
            
        if (bytes(player1Move).length != 0 && bytes(player2Move).length != 0)
        {
            int winner = resultMatrix[player1Move][player2Move];
            if (winner == 1)
                player1.transfer(address(this).balance);
            else if (winner == 2)
                player2.transfer(address(this).balance);
            else
            {
                player1.transfer(address(this).balance/2);
                player2.transfer(address(this).balance);
            }
             
            player1Move = "";
            player2Move = "";
            player1 = 0;
            player2 = 0;
            return winner;
        }
        else 
            return -1;
    }

    modifier checkFunds(uint amount)
    {
        if (msg.value < amount)
            revert();
        else
            _;
    }
    
}