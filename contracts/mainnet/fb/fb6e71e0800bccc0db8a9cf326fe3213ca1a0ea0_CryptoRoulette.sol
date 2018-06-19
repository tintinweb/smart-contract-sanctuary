pragma solidity ^0.4.24;

// To play, call the play() method with the guessed number.  Bet price: 0.1 ether

contract CryptoRoulette {

    uint256 public secretNumber;
    uint256 public lastPlayed;
    uint256 public betPrice = 0.1 ether;
    address public ownerAddr;

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gamesPlayed;

    function CryptoRoulette() public {
        ownerAddr = msg.sender;
        generateNewRandom();
    }

    function generateNewRandom() internal {
        // initialize secretNumber with a value between 0 and 15
        secretNumber = uint8(sha3(now, block.blockhash(block.number-1))) % 16;
    }

    function play(uint256 number) payable public {
        require(msg.value >= betPrice && number < 16);

        Game game;
        game.player = msg.sender;
        game.number = number;
        gamesPlayed.push(game);

        if (number == secretNumber) {
            // win!
            if(msg.value*15>this.balance){
                msg.sender.transfer(this.balance);
            }
            else{
                msg.sender.transfer(msg.value*15);
            }
        }

        generateNewRandom();
        lastPlayed = now;
    }

    function kill() public {
        if (msg.sender == ownerAddr && now > lastPlayed + 1 days) {
            suicide(msg.sender);
        }
    }

    function() public payable { }
}