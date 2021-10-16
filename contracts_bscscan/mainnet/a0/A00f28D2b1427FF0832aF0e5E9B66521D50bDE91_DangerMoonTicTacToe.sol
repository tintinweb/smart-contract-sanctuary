/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

// DangerMoonTicTacToe is a solidity implementation of the tic tac toe game.
// You can find the rules at https://en.wikipedia.org/wiki/Tic-tac-toe
// Shamelessly forked from
// https://github.com/schemar/TicTacToe/blob/master/contracts/TicTacToe.sol

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = payable(msgSender);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    // Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    // Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IERC20 {

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

interface IDangerMoon is IERC20 {
    function _minimumTokensForReflection() external returns (uint256);
}

contract DangerMoonTicTacToe is Ownable {

    using SafeMath for uint256;

    // Teams enumerates all possible teams
    enum Teams { None, TeamOne, TeamTwo }
    // Winners enumerates all possible winners
    enum Winners { None, TeamOne, TeamTwo, Draw }

    // GameCreated signals that `creator` created a new game with this `gameId`.
    event GameCreated(uint256 gameId, address creator, bool isTeamOneEven);
    // PlayerJoinedGame signals that `player` joined the game with the id `gameId`.
    // That player has the player number `playerNumber` in that game.
    event PlayerJoinedGame(uint256 gameId, address player, uint8 teamNumber);
    // PlayerVotesMove signals that `player` filled in the board of the game with
    // the id `gameId`. They did so at the coordinates `xCoord`, `yCoord`.
    event PlayerVotesMove(uint256 gameId, address player, uint256 numVotes, uint8 xCoord, uint8 yCoord);
    // TeamMadeMove signals that `team` filled in the board of the game with
    // the id `gameId`. They did so at the coordinates `xCoord`, `yCoord`.
    event TeamMadeMove(uint256 gameId, uint8 teamNumber, uint8 xCoord, uint8 yCoord);
    event TeamSkippedMove(uint256 gameId, uint8 teamNumber);
    // GameOver signals that the game with the id `gameId` is over.
    // The winner is indicated by `winner`. No more moves are allowed in this game.
    event GameOver(uint256 gameId, Winners winner);

    // Game stores the state of a round of tic tac toe.
    // As long as `winner` is `None`, the game is not over.
    // `turn` defines who may go next.
    // Player one must make the first move.
    // The `board` has the size 3x3 and in each cell, a player
    // can be listed. Initializes as `None` player, as that is the
    // first element in the enumeration.
    // That means that players are free to fill in any cell at the
    // start of the game.
    struct Game {
        uint256 turnEndBlock;
        uint256 blocksPerTurn;
        uint256 prizePool;
        uint256 teamOneTotalVoteFees;
        uint256 teamTwoTotalVoteFees;
        uint256 totalVotesThisTurn;
        uint256 turnNumber;
        uint256[3][3] votes;
        Teams[3][3] board;
        bool isTeamOneEven;
        Winners winner;
        Teams turn;
        // Tracking player deposits for refunds + prize payouts
        mapping(address => uint256) teamOneVoteFees;
        mapping(address => uint256) teamTwoVoteFees;
    }

    // playerVotes stores the games youve voted on. This lets us render the
    // the games you care about in the UI.
    mapping(address => uint256[]) playerVotes;
    // games stores all the games.
    // Games that are already over as well as games that are still running.
    // It is possible to iterate over all games, as the keys of the mapping
    // are known to be the integers from `0` to `getNumGames() - 1`.
    Game[] public games;
    // determines number of votes per in-game turn
    uint8 public minimumVotesPerTurn = 25;
    // determines number of blocks per in-game turn
    uint16 public minimumBlocksPerTurn = 1200; // 1200 blocks is about 1 hour on BSC
    // dangermoon team's cut of prize pool
    uint8 public takeFeePercent = 10;
    // cost of a tictactoe vote as a percent of dangermoon's daily minimum entry
    uint8 public entryFeePercent = 10;
    // lets the team lock this game contract and migrate to new version
    bool public lockNewGame = false;
    // dangermoon contract (for transfers, reading the daily $10 price, etc)
    IDangerMoon public dangermoon;

    constructor(address _dangermoonAddress) public {
      dangermoon = IDangerMoon(_dangermoonAddress);
    }

    function setLockNewGame(bool _lockNewGame) public onlyOwner() {
        lockNewGame = _lockNewGame;
    }

    function setTakeFeePercent(uint8 _takeFeePercent) public onlyOwner() {
        takeFeePercent = _takeFeePercent;
    }

    function setEntryFeePercent(uint8 _entryFeePercent) public onlyOwner() {
        entryFeePercent = _entryFeePercent;
    }

    function setMinimumVotesPerTurn(uint8 _minimumVotesPerTurn) public onlyOwner() {
        minimumVotesPerTurn = _minimumVotesPerTurn;
    }

    function setMinimumBlocksPerTurn(uint8 _minimumBlocksPerTurn) public onlyOwner() {
        minimumBlocksPerTurn = _minimumBlocksPerTurn;
    }

    function withdrawDangerMoon(uint256 amount) public onlyOwner() {
        if (amount == 0) {
            amount = dangermoon.balanceOf(address(this));
        }
        if (amount > 0) {
            dangermoon.transfer(owner(), amount);
        }
    }

    function getNumGames() public view returns (uint256) {
        return games.length;
    }

    function getPlayerVotes() public view returns (uint256[] memory) {
        return playerVotes[msg.sender];
    }

    function getGameVotes(uint256 gameId) public view returns (uint256[3][3] memory) {
        return games[gameId].votes;
    }

    function getGameBoard(uint256 gameId) public view returns (Teams[3][3] memory) {
        return games[gameId].board;
    }

    function getGamePayouts(uint256 gameId) public view returns (uint256 draw, uint256 win) {

        Game storage game = games[gameId];
        Teams playerTeam = getPlayerTeam(gameId, msg.sender);

        uint256 playerDeposit;
        uint256 totalVoteFees;
        if (playerTeam == Teams.TeamOne) {
            playerDeposit = game.teamOneVoteFees[msg.sender];
            totalVoteFees = game.teamOneTotalVoteFees;
        } else {
            playerDeposit = game.teamTwoVoteFees[msg.sender];
            totalVoteFees = game.teamTwoTotalVoteFees;
        }
        uint256 playerWinnings = playerDeposit.mul(10**20).div(totalVoteFees).mul(game.prizePool).div(10**20);
        uint256 drawTakeFee = playerDeposit.mul(takeFeePercent).div(10**2);
        uint256 winTakeFee = playerWinnings.mul(takeFeePercent).div(10**2);

        return (
          playerDeposit.sub(drawTakeFee),
          playerWinnings.sub(winTakeFee)
        );
    }

    // newGame creates a new game and returns the new game's `gameId`.
    // The `gameId` is required in subsequent calls to identify the game.
    function newGame(uint256 _blocksPerTurn) public returns (uint256 gameId) {
        require(
          _blocksPerTurn >= minimumBlocksPerTurn,
          "Turns must be at least the minimum number of blocks"
        );
        require(!lockNewGame, "Cant create a new game right now");

        games.push();
        uint256 newIndex = games.length - 1;
        games[newIndex].turn = Teams.TeamOne;
        games[newIndex].isTeamOneEven = (uint256(msg.sender).mod(2) == 0);
        games[newIndex].turnEndBlock = block.number.add(_blocksPerTurn);
        games[newIndex].blocksPerTurn = _blocksPerTurn;

        emit GameCreated(newIndex, msg.sender, games[newIndex].isTeamOneEven);

        return newIndex;
    }

    function isPlayerOnTeamOne(bool isTeamOneEven, address player) private pure returns (bool) {
        if (isTeamOneEven) {
            return (uint256(player).mod(2) == 0);
        }
        return (uint256(player).mod(2) != 0);
    }

    function getPlayerTeam(uint256 gameId, address player) public view returns (Teams team) {
        if (isPlayerOnTeamOne(games[gameId].isTeamOneEven, player)) {
            return Teams.TeamOne;
        }
        return Teams.TeamTwo;
    }

    // voteMove denotes a player votes to make a move on the game board.
    // The player is identified as the sender of the message.
    // once minimumVotesPerTurn votes are reached, the turn is over
    // once the elapsed time has passed, the turn is over
    function voteMove(uint256 gameId, uint256 numVotes, uint8 xCoord, uint8 yCoord) public returns (bool success, string memory reason) {
        Game storage game = games[gameId];

        // CHECKS
        require(gameId < games.length, "No such game exists.");
        require(numVotes <= minimumVotesPerTurn, "Too many votes.");
        require(game.winner == Winners.None, "The game already has a winner, it is over.");
        require(game.board[xCoord][yCoord] == Teams.None, "There is already a mark at the given coordinates.");
        require(xCoord <= 2 && yCoord <= 2, "coordinates can only be 0, 1, or 2.");
        require(
          game.turnNumber < 4 ||
          game.teamOneVoteFees[msg.sender] != 0 ||
          game.teamTwoVoteFees[msg.sender] != 0,
          "You must join a game before the fourth round."
        );

        // Check if we have to end the previous team's turn
        if (block.number > game.turnEndBlock) {
            Winners winner = endVote(gameId);
            // We check for winners after each vote concludes
            if (winner != Winners.None) return (true, "The game is over.");
        }

        // Players can only vote for a move on their team's turn
        require(game.turn == getPlayerTeam(gameId, msg.sender), "It is not your teams turn.");

        // EFFECTS
        // Transfer dangermoon vote-fee to this contract
        uint256 tenUsdWorth = dangermoon._minimumTokensForReflection();
        uint256 voteFee = tenUsdWorth.mul(entryFeePercent).div(10**2).mul(numVotes);
        uint256 allowance = dangermoon.allowance(msg.sender, address(this));
        require(allowance >= voteFee, "This contract is not approved to transfer enough DangerMoon.");
        dangermoon.transferFrom(msg.sender, address(this), voteFee);

        // keep track of which games player is playing
        playerVotes[msg.sender].push(gameId);

        // Update game prize pool and player's vote-contribution to weight prize payouts
        game.prizePool = game.prizePool.add(voteFee);
        if (game.turn == Teams.TeamOne) {
            game.teamOneTotalVoteFees = game.teamOneTotalVoteFees.add(voteFee);
            game.teamOneVoteFees[msg.sender] = game.teamOneVoteFees[msg.sender].add(voteFee);
        } else {
            game.teamTwoTotalVoteFees = game.teamTwoTotalVoteFees.add(voteFee);
            game.teamTwoVoteFees[msg.sender] = game.teamTwoVoteFees[msg.sender].add(voteFee);
        }

        // Record the player's vote
        game.totalVotesThisTurn = game.totalVotesThisTurn.add(numVotes);
        game.votes[xCoord][yCoord] = game.votes[xCoord][yCoord].add(numVotes);
        emit PlayerVotesMove(gameId, msg.sender, numVotes, xCoord, yCoord);

        // A vote was made and there is no winner yet.
        // Let the next team play if we have reached max votes for this turn.
        if (game.totalVotesThisTurn >= minimumVotesPerTurn) {
            Winners winner = endVote(gameId);
            // We check for winners after each vote concludes
            if (winner != Winners.None) return (true, "The game is over.");
        }

        return (true, "");
    }

    // endVote updates game state given all players votes.
    function endVote(uint256 gameId) private returns (Winners winner) {
        Game storage game = games[gameId];

        uint256 maxVote = 0;
        uint8 maxVoteX;
        uint8 maxVoteY;
        for (uint8 x = 0; x < 3; x++) {
            for (uint8 y = 0; y < 3; y++) {
                if (game.votes[x][y] > maxVote) {
                    maxVote = game.votes[x][y];
                    maxVoteX = x;
                    maxVoteY = y;
                }
            }
        }

        Winners _winner = Winners.None;

        if (maxVote == 0) {

            // The team skipped voting...
            emit TeamSkippedMove(gameId, uint8(game.turn));

            // They lose by default
            if (game.turn == Teams.TeamOne) {
                _winner = Winners.TeamTwo;
            } else {
                _winner = Winners.TeamOne;
            }

        } else {
            // The team voted...
            // Record the vote result
            game.board[maxVoteX][maxVoteY] = game.turn;
            emit TeamMadeMove(gameId, uint8(game.turn), maxVoteX, maxVoteY);

            // Check if there is a winner now that we have a new move.
            _winner = calculateWinner(game.board);
        }

        if (_winner != Winners.None) {
            // If there is a winner (can be a `Draw`) it must be recorded
            game.winner = _winner;
            emit GameOver(gameId, game.winner);
            return game.winner;
        }

        // Make it the next team's turn now that voting concluded
        if (game.turn == Teams.TeamOne) {
            game.turn = Teams.TeamTwo;
        } else {
            game.turn = Teams.TeamOne;
        }

        // Begin voting for next team
        game.turnEndBlock = block.number.add(game.blocksPerTurn);
        game.turnNumber = game.turnNumber.add(1);
        game.totalVotesThisTurn = 0;
        // Clear current votes
        delete game.votes;

        return Winners.None;
    }

    // getCurrentTeam returns the team that should make the next move.
    // Returns the `None` team if it is no team's turn.
    function getCurrentTeam(Game storage _game) private view returns (Teams team) {
        if (_game.turn == Teams.TeamOne) {
            return Teams.TeamOne;
        }

        if (_game.turn == Teams.TeamTwo) {
            return Teams.TeamTwo;
        }

        return Teams.None;
    }

    // calculateWinner returns the winner on the given board.
    // The returned winner can be `None` in which case there is no winner and no draw.
    function calculateWinner(Teams[3][3] memory _board) private pure returns (Winners winner) {
        // First we check if there is a victory in a row.
        // If so, convert `Teams` to `Winners`
        // Subsequently we do the same for columns and diagonals.
        Teams team = winnerInRow(_board);
        if (team == Teams.TeamOne) {
            return Winners.TeamOne;
        }
        if (team == Teams.TeamTwo) {
            return Winners.TeamTwo;
        }

        team = winnerInColumn(_board);
        if (team == Teams.TeamOne) {
            return Winners.TeamOne;
        }
        if (team == Teams.TeamTwo) {
            return Winners.TeamTwo;
        }

        team = winnerInDiagonal(_board);
        if (team == Teams.TeamOne) {
            return Winners.TeamOne;
        }
        if (team == Teams.TeamTwo) {
            return Winners.TeamTwo;
        }

        // If there is no winner and no more space on the board,
        // then it is a draw.
        if (isBoardFull(_board)) {
            return Winners.Draw;
        }

        return Winners.None;
    }

    // winnerInRow returns the player that wins in any row.
    // To win in a row, all cells in the row must belong to the same player
    // and that player must not be the `None` player.
    function winnerInRow(Teams[3][3] memory _board) private pure returns (Teams winner) {
        for (uint8 x = 0; x < 3; x++) {
            if (
                _board[x][0] == _board[x][1]
                && _board[x][1]  == _board[x][2]
                && _board[x][0] != Teams.None
            ) {
                return _board[x][0];
            }
        }

        return Teams.None;
    }

    // winnerInColumn returns the player that wins in any column.
    // To win in a column, all cells in the column must belong to the same player
    // and that player must not be the `None` player.
    function winnerInColumn(Teams[3][3] memory _board) private pure returns (Teams winner) {
        for (uint8 y = 0; y < 3; y++) {
            if (
                _board[0][y] == _board[1][y]
                && _board[1][y] == _board[2][y]
                && _board[0][y] != Teams.None
            ) {
                return _board[0][y];
            }
        }

        return Teams.None;
    }

    // winnerInDiagoral returns the player that wins in any diagonal.
    // To win in a diagonal, all cells in the diaggonal must belong to the same player
    // and that player must not be the `None` player.
    function winnerInDiagonal(Teams[3][3] memory _board) private pure returns (Teams winner) {
        if (
            _board[0][0] == _board[1][1]
            && _board[1][1] == _board[2][2]
            && _board[0][0] != Teams.None
        ) {
            return _board[0][0];
        }

        if (
            _board[0][2] == _board[1][1]
            && _board[1][1] == _board[2][0]
            && _board[0][2] != Teams.None
        ) {
            return _board[0][2];
        }

        return Teams.None;
    }

    // isBoardFull returns true if all cells of the board belong to a team other than `None`.
    function isBoardFull(Teams[3][3] memory _board) private pure returns (bool isFull) {
        for (uint8 x = 0; x < 3; x++) {
            for (uint8 y = 0; y < 3; y++) {
                if (_board[x][y] == Teams.None) {
                    return false;
                }
            }
        }

        return true;
    }

    function claimWinnings(uint256 gameId) public {
      // CHECKS
      require(gameId < games.length, "No such game exists.");

      Game storage game = games[gameId];
      Teams playerTeam = getPlayerTeam(gameId, msg.sender);

      require(game.winner != Winners.None, "The game doesnt have a winner yet, it is not over.");
      require(
        game.winner == Winners.Draw || uint8(game.winner) == uint8(playerTeam),
        "The game was not a draw and your team lost."
      );
      require(
        game.teamOneVoteFees[msg.sender] != 0 || game.teamTwoVoteFees[msg.sender] != 0,
        "You have no DangerMoon to claim, you may have already claimed it."
      );

      if (game.winner == Winners.Draw) {

        // A draw lets you pull your deposit out minus our take fee
        uint256 playerDeposit;
        if (playerTeam == Teams.TeamOne) {
            playerDeposit = game.teamOneVoteFees[msg.sender];
            game.teamOneVoteFees[msg.sender] = 0;
        } else {
            playerDeposit = game.teamTwoVoteFees[msg.sender];
            game.teamTwoVoteFees[msg.sender] = 0;
        }
        uint256 takeFee = playerDeposit.mul(takeFeePercent).div(10**2);
        dangermoon.transfer(owner(), takeFee);
        dangermoon.transfer(msg.sender, playerDeposit.sub(takeFee));

      } else {

        // Distribute winnings
        uint256 playerDeposit;
        uint256 totalVoteFees;
        if (playerTeam == Teams.TeamOne) {
            playerDeposit = game.teamOneVoteFees[msg.sender];
            totalVoteFees = game.teamOneTotalVoteFees;
            game.teamOneVoteFees[msg.sender] = 0;
        } else {
            playerDeposit = game.teamTwoVoteFees[msg.sender];
            totalVoteFees = game.teamTwoTotalVoteFees;
            game.teamTwoVoteFees[msg.sender] = 0;
        }
        uint256 playerWinnings = playerDeposit.mul(10**20).div(totalVoteFees).mul(game.prizePool).div(10**20);
        uint256 takeFee = playerWinnings.mul(takeFeePercent).div(10**2);
        dangermoon.transfer(owner(), takeFee);
        dangermoon.transfer(msg.sender, playerWinnings.sub(takeFee));

      }
    }

}