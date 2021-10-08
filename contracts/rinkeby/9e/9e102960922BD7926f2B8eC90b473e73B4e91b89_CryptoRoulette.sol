pragma solidity 0.4.19;

// CryptoRoulette
//
// Guess the number secretly stored in the blockchain and win the whole contract balance!
// A new number is randomly chosen after each try.
//
// To play, call the play() method with the guessed number (1-20).  Bet price: 0.1 ether

contract CryptoRoulette {

    uint256 private secretNumber;
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
        shuffle();
    }

    function shuffle() internal {
        // randomly set secretNumber with a value between 1 and 20
        secretNumber = uint8(keccak256(block.timestamp, block.blockhash(block.number-1))) % 20 + 1;
    }

    function play(uint256 number) payable public {
        require(msg.value >= betPrice && number <= 20);

        Game game;
        game.player = msg.sender; // this line
        game.number = number;
        gamesPlayed.push(game);

        
        if (number == secretNumber) {
            // win!
            msg.sender.transfer(this.balance);
        }

        shuffle();
        lastPlayed = now;
    }

    function() public payable { }
}