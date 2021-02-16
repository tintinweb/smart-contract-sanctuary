/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.4.26;

contract Game {

    address public dad;
    address public boy;
    address public lastBrother;
    bool playing;

    modifier onlyDad {
        if (msg.sender != dad) throw;
        _;
    }

    function Game(address _boy) payable {
        boy = _boy;
        dad = msg.sender;
        playing = true;
    }


    function sendBrother(address brother) onlyDad {
        if (brother == 0) throw;
        lastBrother = boy; 
        boy = brother;
    }

    function endGame() onlyDad {     
        if (boy.send(this.balance)) {
            playing = false;
        }
    }
}

contract Dad {
    mapping (bytes32 => gameInfo) public records;

    struct gameInfo {
        Game game;
        uint money;
    }

    modifier onlyBoySelf(bytes32 name) {
        if (msg.sender != records[name].game.boy()) throw;
        _;
    }

    function gameStart(bytes32 name) payable {
        Game newGame = new Game(msg.sender);
        gameInfo info = records[name];
        info.game = newGame;
        info.money = msg.value;
    }

    function send(bytes32 name, address brother) onlyBoySelf(name) {
        if (brother == 0) throw;
        gameInfo info = records[name];
        info.game.sendBrother(brother);
    }

    function gameOver(bytes32 name) onlyBoySelf(name) {
        gameInfo info = records[name];
        Game hisGame = info.game;
        info.money = 0;
        info.game = Game(0);
        hisGame.endGame();    
    }
}