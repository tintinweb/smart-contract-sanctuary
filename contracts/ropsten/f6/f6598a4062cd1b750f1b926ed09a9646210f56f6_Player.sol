/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity >=0.4.25 <0.6.0;

contract Starter
{
    enum StateType { GameProvisioned, Pingponging, GameFinished}
    event Log(string _myString);
    StateType public State;

    string public PingPongGameName;
    address public GameStarter;
    Player public GamePlayer;
    int public PingPongTimes;

    constructor (string memory gameName) public{
        PingPongGameName = gameName;
        GameStarter = msg.sender;

        GamePlayer = new Player(PingPongGameName);

        State = StateType.GameProvisioned;
    }

    function StartPingPong(int pingPongTimes) public
    {   
        PingPongTimes = pingPongTimes;

        State = StateType.Pingponging;

        GamePlayer.Ping(pingPongTimes);
    }

    function Pong(int currentPingPongTimes) public
    {   
        //
        int remainingPingPongTimes = currentPingPongTimes - 1;

        if(remainingPingPongTimes > 0)
        {
            State = StateType.Pingponging;
            emit Log("Inside_Contract_1");
            GamePlayer.Ping(remainingPingPongTimes);
        }
        else
        {
            emit Log("Inside_Contract_1");
            State = StateType.GameFinished;
            GamePlayer.FinishGame();
        }
    }

    function FinishGame() public
    {
        State = StateType.GameFinished;
    }
}

contract Player
{
    enum StateType {PingpongPlayerCreated, PingPonging, GameFinished}
    event Log(string _myString);
    StateType public State;

    address public GameStarter;
    string public PingPongGameName;

    constructor (string memory pingPongGameName) public {
        GameStarter = msg.sender;
        PingPongGameName = pingPongGameName;

        State = StateType.PingpongPlayerCreated;
    }

    function Ping(int currentPingPongTimes) public
    {
        int remainingPingPongTimes = currentPingPongTimes - 1;

        Starter starter = Starter(msg.sender);
        if(remainingPingPongTimes > 0)
        {
            State = StateType.PingPonging;
            emit Log("Inside_Contract_2");
            starter.Pong(remainingPingPongTimes);
        }
        else
        {
            emit Log("Inside_Contract_2");
            State = StateType.GameFinished;
            starter.FinishGame();
        }
    }

    function FinishGame() public
    {
        State = StateType.GameFinished;
    }
}