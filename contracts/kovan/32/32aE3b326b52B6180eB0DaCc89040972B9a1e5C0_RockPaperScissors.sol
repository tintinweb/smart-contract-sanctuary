//SPDX-License-Identifier:MIT
pragma solidity 0.6.12;

contract RockPaperScissors {

    uint constant public BET_MIN        = 1 finney;    // The minimum bet
    uint constant public REVEAL_TIMEOUT = 10 minutes;  // Max delay of revelation phase
    uint public initialBet;                            // Bet of first player
    uint private firstReveal;                          // Moment of first reveal

    enum Moves {None, Rock, Paper, Scissors}
    enum Outcomes {None, PlayerA, PlayerB, Draw}   // Possible outcomes

    // Players addresses
    address payable playerA;
    address payable playerB;
    //fomoPool address
    address payable fomoPool;
    //fomotimer
    uint public fomotimer;

    // Encrypted moves
    bytes32 private encrMovePlayerA;
    bytes32 private encrMovePlayerB;

    // Clear moves set only after both players have committed their encrypted moves
    Moves private movePlayerA;
    Moves private movePlayerB;

    //Player do registration here 

    // Bet must be greater than a minimum amount and greater than bet of first player
    modifier validBet() {
        require(msg.value >= BET_MIN);
        require(initialBet == 0 || msg.value == initialBet,"provide initial bet amount");
        _;
    }

    modifier notAlreadyRegistered() {
        require(msg.sender != playerA && msg.sender != playerB);
        _;
    }

    // Register a player.
    // Return player's ID upon successful registration.
    function register() public payable validBet notAlreadyRegistered returns (uint) {
        if (playerA == address(0x0)) {
            playerA    = msg.sender;
            initialBet = msg.value;
            return 1;
        } else if (playerB == address(0x0)) {
            playerB = msg.sender;
            return 2;
        }
        else
        revert("Only 2 player allowed");
    }

//Player will play there move

    modifier isRegistered() {
        require (msg.sender == playerA || msg.sender == playerB);
        _;
    }
    

    // Save player's encrypted move.
    // Return 'true' if move was valid, 'false' otherwise.
    function play(bytes32 encrMove) public isRegistered returns (bool) {
        if (msg.sender == playerA && encrMovePlayerA == 0x0) {
            encrMovePlayerA = encrMove;
            return true;
        } else if (msg.sender == playerB && encrMovePlayerB == 0x0) {
            encrMovePlayerB = encrMove;
            return true;
        } else {
           return false;
        }
    }

//Player will reveal their move 
//we use provable fairness as 
/* the player provides a SHA256 hash of the concatenation of a move, 
represented by an integer, and a secret password. The contract stores 
this hash and nobody except the player has access to the actual move. 
Once such a hash has been committed, it cannot be modified.

*/
    modifier commitPhaseEnded() {
        require(encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
        _;
    }

    // Compare clear move given by the player with saved encrypted move.
    // Return clear move upon success, 'Moves.None' otherwise.
    function reveal(string memory clearMove) public isRegistered commitPhaseEnded returns (Moves) {
        bytes32 encrMove = keccak256(abi.encodePacked(clearMove));  // Hash of clear input (= "move-password")
        Moves move       = Moves(getFirstChar(clearMove));       // Actual move (Rock / Paper / Scissors)

        // If move invalid, exit
        if (move == Moves.None) {
            return Moves.None;
        }

        // If hashes match, clear move is saved
        if (msg.sender == playerA && encrMove == encrMovePlayerA) {
            movePlayerA = move;
        } else if (msg.sender == playerB && encrMove == encrMovePlayerB) {
            movePlayerB = move;
        } else {
            return Moves.None;
        }

        // Timer starts after first revelation from one of the player
        if (firstReveal == 0) {
            firstReveal = now;
        }

        return move;
    }

    // Return first character of a given string.
    function getFirstChar(string memory str) private pure returns (uint) {
        byte firstByte = bytes(str)[0];
        if (firstByte == 0x31) {
            return 1;
        } else if (firstByte == 0x32) {
            return 2;
        } else if (firstByte == 0x33) {
            return 3;
        } else {
            return 0;
        }
    }

  //contract will wait for 10 minutes for 2nd player to reveal ,if he/she fail ,then he/she will loose the bet

    modifier revealPhaseEnded() {
        require((movePlayerA != Moves.None && movePlayerB != Moves.None) ||
                (firstReveal != 0 && now > firstReveal + REVEAL_TIMEOUT));
        _;
    }

    // Compute the outcome and pay the winner(s).
    // Return the outcome.
    function getOutcome() public revealPhaseEnded returns (Outcomes) {
        Outcomes outcome;

        if (movePlayerA == movePlayerB) {
            outcome = Outcomes.Draw;
        } else if ((movePlayerA == Moves.Rock     && movePlayerB == Moves.Scissors) ||
                   (movePlayerA == Moves.Paper    && movePlayerB == Moves.Rock)     ||
                   (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)    ||
                   (movePlayerA != Moves.None     && movePlayerB == Moves.None)) {
            outcome = Outcomes.PlayerA;
        } else {
            outcome = Outcomes.PlayerB;
        }

        address payable addrA = playerA;
        address payable addrB = playerB;
        uint betPlayerA       = initialBet;
        reset();  // Reset game before paying to avoid reentrancy attacks or use non-reanantrant modifier
        pay(addrA, addrB, betPlayerA, outcome);

        return outcome;
    }

    // Pay the winner(s).
    function pay(address payable addrA, address payable addrB, uint betPlayerA, Outcomes outcome) private {
        // Uncomment lines below if you need to adjust the gas limit
        if (outcome == Outcomes.PlayerA) {
            addrA.transfer(address(this).balance);
            //5 % goes to fomo pool
        } else if (outcome == Outcomes.PlayerB) {
            //5 % goes to fomo pool
            addrB.transfer(address(this).balance);
        } else {
            addrA.transfer(betPlayerA);
            addrB.transfer(address(this).balance);
        }
    }

    // Reset the game.
    function reset() private {
        initialBet      = 0;
        firstReveal     = 0;
        playerA         = address(0x0);
        playerB         = address(0x0);
        encrMovePlayerA = 0x0;
        encrMovePlayerB = 0x0;
        movePlayerA     = Moves.None;
        movePlayerB     = Moves.None;
    }

   //Getter function ,for knowing some of the contract state 

    // Return contract balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Return player's ID
    function whoAmI() public view returns (uint) {
        if (msg.sender == playerA) {
            return 1;
        } else if (msg.sender == playerB) {
            return 2;
        } else {
            return 0;
        }
    }

    // Return 'true' if both players have commited a move, 'false' otherwise.
    function bothPlayed() public view returns (bool) {
        return (encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
    }

    // Return 'true' if both players have revealed their move, 'false' otherwise.
    function bothRevealed() public view returns (bool) {
        return (movePlayerA != Moves.None && movePlayerB != Moves.None);
    }

    // Return time left before the end of the revelation phase.
    function revealTimeLeft() public view returns (int) {
        if (firstReveal != 0) {
            return int((firstReveal + REVEAL_TIMEOUT) - now);
        }
        return int(REVEAL_TIMEOUT);
    }
    //move is an integer ranging from 1 to 3 which correspond to rock, paper and scissors  
    //password is a string that should be kept secret.
    function getHash(string memory move_password) public pure returns(bytes32){
        uint move=getFirstChar(move_password);
        require(move>=1 && move<=3,"invalid move");
        return keccak256(abi.encodePacked(move_password));
    }
    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}