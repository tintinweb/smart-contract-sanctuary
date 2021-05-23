/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/RockPaperScissors.sol

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

 /**
  * @title RockPaperScissors
  * @dev 2-person simulation of the classic game of rock, paper, scissors using ERC20
  */
contract RockPaperScissors {

    string private constant ERROR_ROUND_DOES_NOT_EXIST = "ERROR_ROUND_DOES_NOT_EXIST";
    string private constant ERROR_ROUND_ALREADY_EXISTS = "ERROR_ROUND_ALREADY_EXISTS";
    string private constant ERROR_ROUND_IS_FULL = "ERROR_ROUND_IS_FULL";
    string private constant ERROR_ROUND_PLAYER_ALREADY_EXIST = "ERROR_ROUND_PLAYER_ALREADY_EXIST";
    string private constant ERROR_ROUND_PLAYER_DOES_NOT_EXIST = "ERROR_ROUND_PLAYER_DOES_NOT_EXIST";
    string private constant ERROR_MOVE_ALREADY_COMMITTED = "ERROR_MOVE_ALREADY_COMMITTED";
    string private constant ERROR_NOT_ENOUGH_TOKENS = "ERROR_NOT_ENOUGH_TOKENS";
    string private constant ERROR_MOVE_ALREADY_REVEALED = "ERROR_MOVE_ALREADY_REVEALED";
    string private constant ERROR_COMMITTED_MOVE_REFUSED = "ERROR_COMMITTED_MOVE_REFUSED";
    string private constant ERROR_INVALID_HASHING_SALT = "ERROR_INVALID_HASHING_SALT";
    string private constant ERROR_INVALID_REVEALED_MOVE = "ERROR_INVALID_REVEALED_MOVE";

    // 0 indicates that no move was made.
    uint8 internal constant REVEALED_MOVE_MISSING = uint8(0);
    
    /* 
     *  Possible moves
     *  1. Rock
     *  2. Paper
     *  3. Scissors
     */
    uint8 internal constant MAX_POSSIBLE_MOVES = uint8(3);
    
    // 4 indicates a draw round.
    uint8 internal constant DRAW_ROUND = uint8(4);

    IERC20 constant internal WAGER_TOKEN = IERC20(0x2F363dD061cc8b3411c3C91C0CfAc0Fa1B62F656); // WPOKT on Rinkeby
    
    struct CastedMove {
        bytes32 committedMove;                         // Hash of the move casted by the player
        uint8 revealedMove;                              // Revealed move submitted by the player
    }
    
    struct Round {
        address bob;
        address alice;
        uint8 winningMove;         
        uint8 maxAllowedMoves; 
        uint256 wagerTokenAmount;         
        uint8 revealedMovesCount;
        mapping (address => CastedMove) moves;      // Mapping of players addresses to their casted move
    }

    // Round records indexed by their ID
    mapping (uint256 => Round) internal roundRecords;

    struct Move {
        uint8 weakTo;
        uint8 strongTo;
    }
    
    Move[4] internal movesData;

    event RoundCreated(uint256 indexed roundId, uint256 wagerAmount);
    event PlayerJoined(uint256 indexed roundId, address indexed player);
    event MoveCommitted(uint256 indexed roundId, address indexed player, bytes32 commitment);
    event MoveRevealed(uint256 indexed roundId, address indexed player, uint8 revealedMove, address revealer);


    constructor() {
        _initializeMoves();
    }

    /**
    * @dev Ensure a certain round exists
    * @param _roundId Identification number of the round to be checked
    */
    modifier roundExists(uint256 _roundId) {
        Round storage round = roundRecords[_roundId];
        require(_existsRound(round), ERROR_ROUND_DOES_NOT_EXIST);
        _;
    }

    /**
    * @dev Internal function to check if a round instance was already created
    * @param _round Round instance to be checked
    * @return True if the given round instance was already created, false otherwise
    */
    function _existsRound(Round storage _round) internal view returns (bool) {
        return _round.bob != address(0);
    }

    /**
    * @dev Internal function to tell whether a certain commited move is valid for a given round instance or not. 
    * @notice This function assumes the given round exists.
    * @param _round Round instance to check the commited move of
    * @param _revealedMove commited move to check if valid or not
    * @return True if the given commited move is valid for the requested round instance, false otherwise.
    */
    function _isValidRevealedMove(Round storage _round, uint8 _revealedMove) internal view returns (bool) {
        return _revealedMove > REVEALED_MOVE_MISSING && _revealedMove <= _round.maxAllowedMoves;
    }

    /**
    * @notice Create a new round instance with ID #`_roundId` and `_wagerAmount` wagered amount
    * @param _roundId ID of the new round instance to be created
    * @param _wagerAmount Wagered amount of tokens for the new round instance to be created
    */
    function create(uint256 _roundId, uint256 _wagerAmount) external {
        Round storage round = roundRecords[_roundId];
        require(!_existsRound(round), ERROR_ROUND_ALREADY_EXISTS);

        round.bob = msg.sender;
        round.maxAllowedMoves = MAX_POSSIBLE_MOVES;
        round.wagerTokenAmount = _wagerAmount;

        emit RoundCreated(_roundId, _wagerAmount);
        emit PlayerJoined(_roundId, msg.sender);
    }

    /**
    * @notice Commit a move for round #`_roundId`
    * @param _roundId ID of the round instance to commit a move to
    * @param _commitment Hashed committed move to be stored for future reveal
    */
    function commit(uint256 _roundId, bytes32 _commitment) external payable roundExists(_roundId) {
        _ensurePlayerJoined(_roundId, msg.sender);
        
        CastedMove storage castedMove = roundRecords[_roundId].moves[msg.sender];
        require(castedMove.committedMove == bytes32(0), ERROR_MOVE_ALREADY_COMMITTED);

        WAGER_TOKEN.transferFrom(msg.sender, address(this), roundRecords[_roundId].wagerTokenAmount);

        castedMove.committedMove = _commitment;
        emit MoveCommitted(_roundId, msg.sender, _commitment);
    }

    /**
    * @notice Reveal `_committedMove` round of `_player` for round #`_roundId`
    * @param _roundId ID of the round instance to reveal a move of
    * @param _player Address of the player to reveal a move for
    * @param _revealedMove Committed move revealed by the player to be revealed
    * @param _salt Salt to decrypt and validate the committed move of the player
    */
    function reveal(uint256 _roundId, address _player, uint8 _revealedMove, bytes32 _salt) external roundExists(_roundId) {
        _ensurePlayerJoined(_roundId, msg.sender);
        
        Round storage round = roundRecords[_roundId];
        CastedMove storage castedMove = round.moves[_player];
        _checkValidSalt(castedMove, _revealedMove, _salt);
        require(_isValidRevealedMove(round, _revealedMove), ERROR_INVALID_REVEALED_MOVE);

        castedMove.revealedMove = _revealedMove;
        round.revealedMovesCount += 1;

        emit MoveRevealed(_roundId, _player, _revealedMove, msg.sender);

        if (round.revealedMovesCount == 2) {
            // Nothing
        }
    }

    /**
    * @dev Joins an already created round that is not full.
    * @param _roundId ID of the round instance to join
    */
    function join(uint256 _roundId) external roundExists(_roundId) {
        Round storage round = roundRecords[_roundId];
        require(msg.sender != round.bob, ERROR_ROUND_PLAYER_ALREADY_EXIST);
        require(round.alice == address(0), ERROR_ROUND_IS_FULL);
        require(WAGER_TOKEN.balanceOf(msg.sender) >= round.wagerTokenAmount, ERROR_NOT_ENOUGH_TOKENS);
        
        round.alice = msg.sender;
        emit PlayerJoined(_roundId, msg.sender);
    }

    /**
    * @dev Internal function to check if user joined a round
    * @param _roundId ID of the round instance to check
    */
    function _ensurePlayerJoined(uint256 _roundId, address _player) internal view {
        Round storage round = roundRecords[_roundId];
        require(round.bob == _player || round.alice == _player, ERROR_ROUND_PLAYER_DOES_NOT_EXIST);
    }

    /**
    * @dev Get the winner of a round instance. If the winner is missing, that means no one played in
    *      the given round instance.
    * @param _roundId ID of the round instance querying the winning outcome of
    * @return Winner of the given round instance or missing
    */
    function getWinningMove(uint256 _roundId) external view roundExists(_roundId) returns (uint8) {
        Round storage round = roundRecords[_roundId];
        uint8 winningMove = round.winningMove;
        return winningMove == REVEALED_MOVE_MISSING ? REVEALED_MOVE_MISSING : winningMove;
    }

    /**
    * @dev Compute the winner and distribute wagered tokens of a round.
    * @param _roundId ID of the round instance querying the winning outcome of
    */
    function computeRound(uint256 _roundId) internal {
        Round storage round = roundRecords[_roundId];
        CastedMove storage bob = round.moves[round.bob];
        CastedMove storage alice = round.moves[round.alice];
        address winner;

        if (movesData[bob.revealedMove].strongTo == alice.revealedMove) {
            round.winningMove = bob.revealedMove;
            winner = round.alice;
        }

        else if (movesData[bob.revealedMove].weakTo == alice.revealedMove) {
            round.winningMove = alice.revealedMove;
            winner = round.bob;
        }
        
        if (winner != address(0))
            WAGER_TOKEN.transferFrom(address(this), winner, round.wagerTokenAmount);
        else
            round.winningMove = DRAW_ROUND;
    }

    function _initializeMoves() internal {
        // Rock (1)
        Move storage rock = movesData[1];
        rock.weakTo = 2;
        rock.strongTo = 3;

        // Paper (2)
        Move storage paper = movesData[2];
        paper.weakTo = 3;
        paper.strongTo = 1;

        // Scissors (3)
        Move storage scissors = movesData[3];
        scissors.weakTo = 1;
        scissors.strongTo = 2;
    }

    /**
    * @dev Hash a move using a given salt
    * @param _commitedMove Committed move to be hashed
    * @param _salt Encryption salt
    * @return Hashed move
    */
    function hashMove(uint8 _commitedMove, bytes32 _salt) external pure returns (bytes32) {
        return _hashMove(_commitedMove, _salt);
    }

    /**
    * @dev Internal function to hash a round commited move using a given salt
    * @param _commitedMove Committed move to be hashed
    * @param _salt Encryption salt
    * @return Hashed outcome
    */
    function _hashMove(uint8 _commitedMove, bytes32 _salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_commitedMove, _salt));
    }

    /**
    * @dev Internal function to check if a move can be revealed for the given commited move and salt
    * @param _castedMove Casted move to be revealed
    * @param _commitedMove Move thas has to be proved
    * @param _salt Salt to decrypt and validate the provided move for a casted move
    */
    function _checkValidSalt(CastedMove storage _castedMove, uint8 _commitedMove, bytes32 _salt) internal view {
        require(_castedMove.revealedMove == REVEALED_MOVE_MISSING, ERROR_MOVE_ALREADY_REVEALED);
        require(_castedMove.committedMove == _hashMove(_commitedMove, _salt), ERROR_INVALID_HASHING_SALT);
    }

}