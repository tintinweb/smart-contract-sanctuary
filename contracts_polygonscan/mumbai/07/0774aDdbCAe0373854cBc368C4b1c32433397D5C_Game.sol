// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Rock Paper Scissors Game
/// @author Damian Piorun aka KlaatuCarpenter
contract Game {
   
    enum Choice {
        None,
        Rock,
        Paper,
        Scissors
    }
    struct Move {
        bytes32 blindedMove;
        uint256 wager;
        uint256 timeStamp;
        address counterPlayer;
        bool notRevealed;
        Choice choice;
    }
    mapping(address => Move) public moves;
    mapping(address => uint256) public balance;

    /// Events
    event GameEnded(address indexed winner, address indexed playerOne, address indexed playerTwo);

    /// Errors
    error TooEarly(uint256 time);
    error NotPossibleDuringGame();
    error TwoPlayersAreNeeded();
    error RevealMoveFirst(address player);
    error InsufficientDeposit(uint256 deposit, uint256 minDeposit);
    error ChallengeNotTaken();
    error ResultFunctionShouldBeCalled();
    error NothingToReveal();

    modifier onlyAfter5Minutes(uint256 time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    /// Withdraw funds
    function withdraw() external returns (bool) {
        if (moves[msg.sender].counterPlayer != address(0)) revert NotPossibleDuringGame();
        uint256 amount = balance[msg.sender];
        if (amount > 0) {
            balance[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
        return true;
    }

    /// The game can only be won, when the move is correctly
    /// revealed in the revealing phase.
    /// @param _blindedMove == keccak256(abi.encodePacked(move, salt))
    /// @param _wager - is bet. Players can play vary wagers. In the result smaller is taken.
    /// @param _counterPlayer - cannot be address zero and msg.sender
    function move(bytes32 _blindedMove, uint256 _wager , address _counterPlayer) external { 
        /// Prevent user to play with self
        if (_counterPlayer == msg.sender || _counterPlayer == address(0)) revert TwoPlayersAreNeeded();
        /// Prevent user to move several times, without revealing.
        if (moves[msg.sender].counterPlayer != address(0)) revert NotPossibleDuringGame();
        if (balance[msg.sender] < (2 *_wager)) revert InsufficientDeposit(balance[msg.sender], (2 * _wager));
        Move storage m = moves[msg.sender];       
        m.blindedMove = _blindedMove;
        m.wager = _wager;
        m.timeStamp = block.timestamp;
        m.counterPlayer = _counterPlayer;
        m.notRevealed = true;
        m.choice = Choice.None;
    }

    /// Reveal users blinded move
    /// @param _choice - should be the same as the one given to _blindedMove in move function
    /// @param _salt - should be the same as the one given to _blindedMove in move function
    function reveal(Choice _choice, bytes32 _salt) external returns(bool) {
        if (!moves[msg.sender].notRevealed) revert NothingToReveal();
        address counterPlayer = moves[msg.sender].counterPlayer;
        if (moves[counterPlayer].counterPlayer != msg.sender) revert ChallengeNotTaken();
        moves[msg.sender].notRevealed = false; 
        if (moves[msg.sender].blindedMove == keccak256(abi.encodePacked(_choice, _salt))) {
            moves[msg.sender].choice = _choice;
            return true;
        }
        return false;
    }

    /// If the other player is not cooperative, it is possible to finish the game after 5 minutes
    /// regardless of what the other player did
    function terminateGame() external onlyAfter5Minutes(moves[msg.sender].timeStamp + 5 minutes) {
        address counterPlayer = moves[msg.sender].counterPlayer;
        if (moves[counterPlayer].counterPlayer == msg.sender) {
            if (moves[msg.sender].notRevealed) revert RevealMoveFirst(msg.sender);
            if (!moves[counterPlayer].notRevealed) {
                revert ResultFunctionShouldBeCalled();
            } else {
                /// If counter player made a move, but he does not want to reveal, this scenario occurs:
                /// The counter player's choice is None.
                /// The wager is doubled, so the player, who does not reveals on his own, lose two times more.
                moves[counterPlayer].notRevealed = false;
                moves[counterPlayer].choice = Choice.None;
                moves[counterPlayer].wager *= 2;
                moves[msg.sender].wager *= 2;
                return;
            }
        } 
        /// Otherwise if counter player did not play this game, just reset player's move
        moves[msg.sender].wager = 0;
        moves[msg.sender].counterPlayer = address(0);
        moves[msg.sender].notRevealed = false; 
    }

    /// Check the result of the game
    function result() external returns(address) {
        address _playerA = msg.sender;
        address _playerB = moves[_playerA].counterPlayer;
        
        if (_playerB == address(0)) revert TwoPlayersAreNeeded();
        if (moves[_playerA].notRevealed) revert RevealMoveFirst(_playerA);
        if (moves[_playerB].notRevealed) revert RevealMoveFirst(_playerB);

        /// Set the wager of the game     
        uint256 amount = 0;
        if(moves[_playerA].wager > moves[_playerB].wager) {
            amount = moves[_playerB].wager;
        } else {
            amount = moves[_playerA].wager;
        }

        /// Reset wagers of players
        moves[_playerA].wager = 0;
        moves[_playerB].wager = 0;
    
        if (moves[_playerA].choice == moves[_playerB].choice) {
            emit GameEnded(address(0), _playerA, _playerB);
            /// Reset counter players to enable these players play together again and withdraw
            moves[_playerA].counterPlayer = address(0);
            moves[_playerB].counterPlayer = address(0);
            return address(0);
        } else if (
            (moves[_playerA].choice == Choice.Rock      && moves[_playerB].choice == Choice.Scissors) || 
            (moves[_playerA].choice == Choice.Paper     && moves[_playerB].choice == Choice.Rock) || 
            (moves[_playerA].choice == Choice.Scissors  && moves[_playerB].choice == Choice.Paper) ||
            (moves[_playerA].choice != Choice.None      && moves[_playerB].choice == Choice.None)
        ) {
            
            balance[_playerB] -= amount;
            balance[_playerA] += amount;
            emit GameEnded(_playerA, _playerA, _playerB);
            /// Reset counter players to enable these players play together again and withdraw
            moves[_playerA].counterPlayer = address(0);
            moves[_playerB].counterPlayer = address(0);
            return _playerA;
        } else {
            balance[_playerA] -= amount;
            balance[_playerB] += amount;
            emit GameEnded(_playerB, _playerA, _playerB);
            /// Reset counter players to enable these players play together again and withdraw
            moves[_playerA].counterPlayer = address(0);
            moves[_playerB].counterPlayer = address(0);
            return _playerB;
        }
    }
}