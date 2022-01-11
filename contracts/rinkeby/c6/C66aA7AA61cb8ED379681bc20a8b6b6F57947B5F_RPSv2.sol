// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RPSv2 is ReentrancyGuard {
    using SafeMath for uint;

    event GetGameOutcome(GameOutcome);

    enum GameStatus {
        nonExistent,
        started,
        participated,
        ended
    }

    enum GameOutcome {
        draw,
        playerOne,
        playerTwo
    }

    struct Game {
        address playerOne;
        address playerTwo;
        uint stake;
        uint  playerOneChoice;
        uint  playerTwoChoice;
        bytes32 playerOneHash;
        bytes32 playerTwoHash;
        GameStatus  status;
        GameOutcome outcome;
    }

    mapping (address => Game) public games;
    mapping (address => uint) public playerBalances;

	//Start
    function startGame(bytes32 gameHash, address opponent, uint gameStake) external {
        require(gameHash != "", "gameHash not provided");
        require(opponent != address(0x0) && opponent != msg.sender, "Problem with other player...");
        require(games[msg.sender].status == GameStatus.nonExistent, "Old game/No game");
        require(gameStake <= playerBalances[msg.sender], "Players funds are insufficient");

        playerBalances[msg.sender] = playerBalances[msg.sender].sub(gameStake);
        
        games[msg.sender].playerOneHash = gameHash;
        games[msg.sender].playerOne = msg.sender;
        games[msg.sender].playerTwo = opponent;
        games[msg.sender].stake = gameStake;
        games[msg.sender].status = GameStatus.started;
    }

    //player 2 enters game
    function participateGame(bytes32 gameHash, address opponent) external {
        require(gameHash != "", "gameHash not provided");
        require(opponent != address(0x0), "Problem with other player...");
        require(games[opponent].playerTwo == msg.sender, "You are not Player 2 for this game");
        require(games[opponent].status == GameStatus.started, "Game not started or has already been participated in");

        uint gameStake = games[opponent].stake;
        require(gameStake <= playerBalances[msg.sender], "Player funds are insufficient");

        playerBalances[msg.sender] = playerBalances[msg.sender].sub(gameStake);

        games[opponent].playerTwoHash = gameHash;
        games[opponent].status = GameStatus.participated;
    }

    //After hashes are sent in and both players have played - each player sends their salt with their choice
    function revealChoice(uint choice, bytes32 salt, address playerOne) external {        
        require(games[playerOne].status == GameStatus.participated, "Game does not exist or player Two has not placed a bet yet");                
       
        if(games[playerOne].playerOne == msg.sender) {
            require(games[playerOne].playerOneHash == getSaltedHash(choice, salt), "problem with salt");
            games[playerOne].playerOneChoice = choice;
        } else if(games[playerOne].playerTwo == msg.sender) {
            require(games[playerOne].playerTwoHash == getSaltedHash(choice, salt), "problem with salt");
            games[playerOne].playerTwoChoice = choice;
        } else {
            revert("Problem with addresses");
        }
    }
    
    function endGame(address playerOne) external returns(GameOutcome gameResult) {
        //can we finish the game?
        require(
          games[playerOne].playerOneChoice > 0 &&
          games[playerOne].playerTwoChoice > 0 ,
          "Both players need to reveal their choice before game can be completed"
        );

        address playerTwo = games[playerOne].playerTwo;
        uint playerOneChoice = games[playerOne].playerOneChoice;
        uint playerTwoChoice = games[playerOne].playerTwoChoice;
        uint stake = games[playerOne].stake;

        //winning player: (3 + playerOneChoice - playerTwoChoice) % 3
        gameResult = GameOutcome((uint(3).add(uint(playerOneChoice)).sub(uint(playerTwoChoice))).mod(3));

        if(gameResult == GameOutcome.draw){
            playerBalances[playerOne] = playerBalances[playerOne].add(stake);
            playerBalances[playerTwo] = playerBalances[playerTwo].add(stake);
        }
        else if(gameResult == GameOutcome.playerOne){
            playerBalances[playerOne] = playerBalances[playerOne].add(stake.mul(2));
        }
        else if(gameResult == GameOutcome.playerTwo){
            playerBalances[playerTwo] = playerBalances[playerTwo].add(stake.mul(2));
        }
        else{
            revert("Invalid Game Outcome");
        }

        //use these lines and comment out deleteGame() to view a completed game in console
        //games[playerOne].outcome = gameResult;
        //games[playerOne].status = GameStatus.ended;
        deleteGame(playerOne);

        emit GetGameOutcome(gameResult);
        return gameResult;
    }
    
    function getSaltedHash(uint answer, bytes32 salt) internal pure returns (bytes32) {
       return keccak256(abi.encodePacked(answer, salt));
    }
   
    function deleteGame(address playerOne) internal {
        delete games[playerOne];

        //the game disappears after being played, so if you want to leave data behind for testing, you can just delete certain pieces of data
        // delete games[playerOne].playerOne;
        // delete games[playerOne].playerTwo;
        // delete games[playerOne].stake;
        // delete games[playerOne].playerOneChoice;
        // delete games[playerOne].playerTwoChoice;
        // delete games[playerOne].playerOneHash;
        // delete games[playerOne].playerTwoHash;
        // delete games[playerOne].status;
        // delete games[playerOne].outcome;
    }

    //deposit a player's funds
    function deposit() external payable {
        playerBalances[msg.sender] = playerBalances[msg.sender].add(msg.value);
    }
    
    //withdraw a player's funds
    function withdraw() external nonReentrant {
        uint playerBalance = playerBalances[msg.sender];
        require(playerBalance > 0, "No balance");
        
        playerBalances[msg.sender] = 0;
        (bool success, ) = address(msg.sender).call{ value: playerBalance }("");
        require(success, "withdraw failed to send");
    }
    
    function getContractBalance() external view returns(uint contractBalance) {
        return address(this).balance;
    }

    function getPlayerBalance(address playerAddress) external view returns(uint playerBalance) {
        return playerBalances[playerAddress];
    }

    function getMsgSender() external view returns(address msgsender) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}