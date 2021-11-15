// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BetU is Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for string;

    uint256 public constant ZOOM_STAKE = 10**8;
    uint256 public constant ZOOM_FEE = 10**8;
    string public baseURI;

    struct Bet {
        uint256 id;
        uint256 side;// 0: maker| 1: taker
        uint256 odds;
        address creator;
        address player;
        address token_stake;
        uint256 stake;
        uint256 result;// 1: win| 0: lose || none
    }

    struct BetGame {
        uint256 fixture_id;
        string fixture_uri;
        address creator;
        address maker;
        uint256 fee;
        address token_stake;
        uint256 min_stake;
        uint256 max_stake;// 0: unlimited| p2p: max_stake = maker stake * (maker odds - 1)
        uint256 bet_type;// 1: 1x2
        uint256 odds_type;// 1: Home | 2: Draw| 3: Away
        uint256 status;// 0: not_started| 1: live| 2: end
    }

    mapping(address => bool) public whiteListTokenStake;
    mapping(uint256 => BetGame) public betGames;
    mapping(uint256 => mapping(address => Bet)) public bets;
    mapping(address => bool) public operators;

    event CreateBetGameEvent(BetGame betGame);
    event BetGameEvent(BetGame betGame);
    event BetWinnerEvent(Bet bet);
    event PlaceBetGameEvent(Bet bet);

    uint256 public betAccess;// 0: all | 1: operator
    modifier checkBetGameAccess() {
        if(betAccess == 1){
            require(operators[_msgSender()], "only operator");
        }
        _;
    }

    constructor() public {
        operators[_msgSender()] = true;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBetAccess(uint256 status) external onlyOwner {
        betAccess = status;
    }

    function setOperator(address _sender, bool status) external onlyOwner {
        operators[_sender] = status;
    }

    function setWhiteListTokenStake(address _token, bool _status) external onlyOwner {
        require(_token != address(0), 'invalid token');
        whiteListTokenStake[_token] = _status;
    }

    function _betGamesExists(uint256 _bet_game_id) internal view returns (bool) {
        return betGames[_bet_game_id].creator != address(0);
    }

    function fixtureURI(uint256 _bet_game_id) public view returns (string memory) {
        require(_betGamesExists(_bet_game_id), "bet game not found");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, betGames[_bet_game_id].fixture_uri)) : "";
    }

    function createBetGame(
        uint256 _bet_game_id,
        uint256 _fixture_id,
        string memory _fixture_uri,
        uint256 _fee,
        uint256 _min_stake,
        uint256 _max_stake,
        uint256 _bet_type,
        uint256 _odds_type,
        address _token_stake,
        address _maker
    ) external whenNotPaused checkBetGameAccess {
        require(msg.sender != address(0) && _maker != address(0), 'invalid player');
        require(whiteListTokenStake[_token_stake] == true && _token_stake != address(0), 'invalid token stake');
        require(!_betGamesExists(_bet_game_id), 'player created bet game');
        require(_maker != address(0), 'invalid player');

        BetGame memory newGame = betGames[_bet_game_id];
        newGame.fixture_id = _fixture_id;
        newGame.fixture_uri = _fixture_uri;
        newGame.creator = msg.sender;
        newGame.maker = _maker;
        newGame.fee = _fee;
        newGame.token_stake = _token_stake;
        newGame.min_stake = _min_stake;
        newGame.max_stake = _max_stake;
        newGame.bet_type = _bet_type;
        newGame.odds_type = _odds_type;
        newGame.status = 1;

        betGames[_bet_game_id] = newGame;
        emit CreateBetGameEvent(newGame);
    }

    function placeBet(uint256 _bet_game_id, uint256 _stake, uint256 _side, uint256 _odds, address _token_stake, address _player) external whenNotPaused {
        require(msg.sender != address(0) && _player != address(0), 'invalid player');
        require(whiteListTokenStake[_token_stake] == true && _token_stake != address(0), 'invalid token stake');
        require(_betGamesExists(_bet_game_id), 'bet game not found');
        require(betGames[_bet_game_id].token_stake == _token_stake, 'token stake not support');
        require(betGames[_bet_game_id].status == 1, 'bet game not live');
        require(bets[_bet_game_id][_player].stake > 0, 'player has bet');
        require(betGames[_bet_game_id].min_stake < _stake, 'stake must be greater');
        if(betGames[_bet_game_id].max_stake > 0){
            require(betGames[_bet_game_id].max_stake >= _stake, 'stake must be less than');
        }

        Bet memory newPlaceBet = bets[_bet_game_id][msg.sender];

        newPlaceBet.stake = _stake;
        newPlaceBet.side = _side;
        newPlaceBet.creator = msg.sender;
        newPlaceBet.player = _player;
        newPlaceBet.odds = _odds;
        newPlaceBet.token_stake = _token_stake;
        newPlaceBet.result = 0;

        bets[_bet_game_id][_player] = newPlaceBet;

        emit PlaceBetGameEvent(newPlaceBet);
    }

    function setWinner(uint256 _bet_game_id, address _playerWin) external whenNotPaused {
        require(operators[msg.sender], 'operator can set winner');
        require(betGames[_bet_game_id].status == 1, 'bet game not live');

        bets[_bet_game_id][_playerWin].result = 1;
        betGames[_bet_game_id].status = 2;

        emit BetWinnerEvent(bets[_bet_game_id][_playerWin]);
        emit BetGameEvent(betGames[_bet_game_id]);
    }

    function stopBetGame(uint256 _bet_game_id) external whenNotPaused {
        require(operators[msg.sender], 'operator can stop');
        require(_betGamesExists(_bet_game_id), 'bet game not found');
        betGames[_bet_game_id].status = 0;
        emit BetGameEvent(betGames[_bet_game_id]);
    }

    function betResult(uint256 _bet_game_id, address _player) public view returns (uint256){
        return bets[_bet_game_id][_player].result;
    }

    function getBetGame(uint256 _bet_game_id) public view returns (BetGame memory){
        return betGames[_bet_game_id];
    }

    function getBet(uint256 _bet_game_id, address _player) public view returns (Bet memory){
        return bets[_bet_game_id][_player];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

