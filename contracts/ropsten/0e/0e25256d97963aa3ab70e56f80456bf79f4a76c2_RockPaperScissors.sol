pragma solidity ^0.4.24; // Specify compiler version

contract RockPaperScissors {
    using SafeMath for uint256;

    struct Game {
        bool Initialized; // Game initialized
        address[] Players; // Players in game
        bytes32 InviteCode; // Game invitecode
        bool GameFinished; // Game finished
        uint Block; // Origin block
        uint RoundsPlayed; // Rounds played
        address[] RoundWinners; // Winner of each round
        mapping(address => uint) Bets; // Bets
        mapping(address => uint[]) Moves; // Moves
        mapping(uint => address) PlayerByMove; // Find player by move
    }

    event NewGame (
        address FirstPlayer, // Player initializing game
        bytes32 InviteCode, // Game invite code
        uint Block // Origin block
    );

    event PlayerJoinedGame (
        address Player, // Player joining game
        bytes32 InviteCode, // Game invite code
        uint Block // Origin block
    );

    event PlayerMadeMove (
        address Player, // Player making move
        uint Move, // Move value
        bytes32 InviteCode, // Game invite code
        uint Block // Origin block
    );

    event PlayerMadeBet (
        address Player, // Player making bet
        uint256 Value, // Value of bet
        bytes32 InviteCode, // Game invite code
        uint Block // Origin block
    );

    event PlayerClaimedBet (
        address Player, // Player claiming bet
        uint256 Value, // Value of bet
        bytes32 InviteCode, // Game invite code
        uint Block // Origin block
    );

    event PlayerWon (
        address WinningPlayer, // Winning player
        address LosingPlayer, // Losing player
        bytes32 InviteCode, // Game invite code
        uint Block // Win block
    );

    mapping(bytes32 => Game) public Games;

    function newGame() public returns (bytes32 _inviteCode) {
        address[] memory players = new address[](2); // Initialize array
        address[] memory roundWinners = new address[](3); // Initialize array

        players[0] = msg.sender; // Append sender to players

        Game memory game = Game(true, players, keccak256(abi.encodePacked(players, block.number)), false, block.number, 0, roundWinners); // Initialize game

        Games[game.InviteCode] = game; // Append game to games list

        emit NewGame(msg.sender, game.InviteCode, block.number); // Emit initialized game

        return game.InviteCode; // Return invite code
    }

    function joinGame(bytes32 _inviteCode) public {
        require(Games[_inviteCode].Initialized == true, "Game does not exist."); // Check game exists
        require(Games[_inviteCode].Players[1] == 0, "Game already full."); // Check game isn&#39;t full
        require(Games[_inviteCode].RoundsPlayed == 0, "Game already started."); // Check game hasn&#39;t already started

        Games[_inviteCode].Players[emptyIndex(Games[_inviteCode].Players)] = msg.sender; // Set player

        emit PlayerJoinedGame(msg.sender, _inviteCode, block.number); // Emit joined game
    }

    function move(bytes32 _inviteCode, uint _move) public {
        require(_move > 0 && _move < 4, "Invalid move"); // Check for valid move
        require(Games[_inviteCode].Initialized == true, "Game does not exist."); // Check game exists
        require(Games[_inviteCode].RoundsPlayed != 3, "Game already finished."); // Check game hasn&#39;t already ended
        require(isIn(msg.sender, Games[_inviteCode].Players), "Player not in game."); // Check player is in game
        require(Games[_inviteCode].Players[0] != address(0), "Not enough players."); // Check enough players
        require(Games[_inviteCode].Moves[msg.sender].length <= Games[_inviteCode].Moves[otherPlayer(msg.sender, Games[_inviteCode].Players)].length, "Other player hasn&#39;t moved yet."); // Check other player moved

        Games[_inviteCode].Moves[msg.sender].length++; // Increment capacity
        Games[_inviteCode].Moves[msg.sender][Games[_inviteCode].RoundsPlayed] = _move; // Append move
        Games[_inviteCode].PlayerByMove[Games[_inviteCode].RoundsPlayed.add(_move)]; // Set player by move

        emit PlayerMadeMove(msg.sender, _move, _inviteCode, block.number); // Emit made move

        if (Games[_inviteCode].Moves[msg.sender].length == Games[_inviteCode].Moves[otherPlayer(msg.sender, Games[_inviteCode].Players)].length) {
            uint PlayerOneMove = Games[_inviteCode].Moves[msg.sender][Games[_inviteCode].RoundsPlayed]; // Fetch sender move
            uint OtherPlayerMove = Games[_inviteCode].Moves[otherPlayer(msg.sender, Games[_inviteCode].Players)][Games[_inviteCode].RoundsPlayed]; // Fetch other player move

            if (PlayerOneMove != OtherPlayerMove) { // Check didn&#39;t make same move
                Games[_inviteCode].RoundWinners.length++; // Increment capacity

                if (PlayerOneMove == 1 || OtherPlayerMove == 1) { // Check for rock
                    Games[_inviteCode].RoundWinners[Games[_inviteCode].RoundsPlayed] = Games[_inviteCode].PlayerByMove[Games[_inviteCode].RoundsPlayed.add(1)]; // Add score
                } else if (PlayerOneMove == 2 || OtherPlayerMove == 2) { // Check for paper
                    Games[_inviteCode].RoundWinners[Games[_inviteCode].RoundsPlayed] = Games[_inviteCode].PlayerByMove[Games[_inviteCode].RoundsPlayed.add(2)]; // Add score
                } else if (PlayerOneMove == 3 || OtherPlayerMove == 3) { // Check for scissors
                    Games[_inviteCode].RoundWinners[Games[_inviteCode].RoundsPlayed] = Games[_inviteCode].PlayerByMove[Games[_inviteCode].RoundsPlayed.add(3)]; // Add score
                }

                Games[_inviteCode].RoundsPlayed++; // Increment rounds played

                if (Games[_inviteCode].RoundsPlayed == 3) { // Check if game finished
                    address winner = msg.sender; // Default
                    address loser = otherPlayer(msg.sender, Games[_inviteCode].Players);

                    if ((winCount(_inviteCode, otherPlayer(msg.sender, Games[_inviteCode].Players)) - winCount(_inviteCode, msg.sender)) >= 2) { // Check who won
                        winner = otherPlayer(msg.sender, Games[_inviteCode].Players); // Set winner address
                        loser = msg.sender; // Set loser
                    }

                    emit PlayerWon(winner, loser, _inviteCode, block.number); // Emit player won
                }
            }
        }
    }

    function bet(bytes32 _inviteCode) public payable {
        require(Games[_inviteCode].Initialized == true, "Game does not exist."); // Check game exists
        require(Games[_inviteCode].RoundsPlayed == 0, "Game already started."); // Check game hasn&#39;t already started
        require(isIn(msg.sender, Games[_inviteCode].Players), "Player not in game."); // Check player is in game

        Games[_inviteCode].Bets[msg.sender] += msg.value; // Add bet

        emit PlayerMadeBet(msg.sender, msg.value, _inviteCode, block.number); // Emit made bet
    }

    function claimBet(bytes32 _inviteCode) public {
        require(Games[_inviteCode].Initialized == true, "Game does not exist."); // Check game exists
        require(Games[_inviteCode].RoundsPlayed == 3, "Game hasn&#39;t finished."); // Check game hasn&#39;t already started
        require(isIn(msg.sender, Games[_inviteCode].Players), "Player not in game."); // Check player is in game
        require((winCount(_inviteCode, msg.sender) - winCount(_inviteCode, otherPlayer(msg.sender, Games[_inviteCode].Players))) >= 2, "Player didn&#39;t win game."); // Check won game

        Games[_inviteCode].Bets[otherPlayer(msg.sender, Games[_inviteCode].Players)] = 0; // Reset bet balance
        Games[_inviteCode].Bets[msg.sender] = 0; // Reset bet balance

        msg.sender.transfer(Games[_inviteCode].Bets[msg.sender].add(Games[_inviteCode].Bets[otherPlayer(msg.sender, Games[_inviteCode].Players)])); // Send wager

        emit PlayerClaimedBet(msg.sender, Games[_inviteCode].Bets[msg.sender].add(Games[_inviteCode].Bets[otherPlayer(msg.sender, Games[_inviteCode].Players)]), _inviteCode, block.number); // Emit claimed bet
    }

    function winCount(bytes32 _inviteCode, address _address) view public returns (uint _winCount) {
        uint z = 0; // Set wins iterator
        
        for (uint x = 0; x != 3; x++) { // Iterate through wins
            if (Games[_inviteCode].RoundWinners[x] == _address) { // Check won round
                z++; // Increment win count
            }
        }

        return z; // Return win count
    }

    function otherPlayer(address _value, address[] _array) pure internal returns (address _address) {
        for (uint x = 0; x != _array.length; x++) {
            if (_array[x] != _value) {
                return _array[x]; // Found value
            }
        }

        return 0; // Reached end of array
    }

    function isIn(address _value, address[] _array) pure internal returns (bool _isIn) {
        for (uint x = 0; x != _array.length; x++) {
            if (_array[x] == _value) {
                return true; // Found value
            }
        }

        return false; // Reached end of array
    }

    function emptyIndex(address[] _array) pure internal returns (uint _emptyIndex) {
        for (uint x = 0; x != _array.length; x++) {
            if (_array[x] == 0) {
                return x; // Found index
            }
        }

        revert(); // Reached end of array
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
        return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}