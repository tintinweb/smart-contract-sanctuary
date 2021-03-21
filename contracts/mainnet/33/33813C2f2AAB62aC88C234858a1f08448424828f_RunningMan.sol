/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// Dependency file: contracts/Round.sol

// SPDX-License-Identifier: MIT

// pragma solidity 0.6.12;


abstract contract RoundStorage {
    // fee to owner of this game
    // fee value = real fee percent value * (10**6)
    uint256 public fee;

    // amount players can bet
    uint256 public amount;

    // number of seconds of a round
    uint public roundTime;

    struct Round {
        // round is over and calculated reward or no
        bool finalized;

        uint startTime;
        uint endTime;
        uint256 fee;
        uint256 amount;
    }

    Round[] public rounds;
}

contract Round is RoundStorage {
    event Bet(uint256 indexed round, address indexed player, uint256 indexed amount);
    event RoundStarted(uint256 indexed round);
    event RoundEnded(uint256 indexed round);

    function getCurrentRoundNumber() public view returns(uint256) {
        if (rounds.length > 0) {
            return rounds.length - 1;
        }

        return 0;
    }

    function getCurrentRound() public view returns (uint256 number, uint start, uint end, uint256 betAmount) {
        uint256 currentRoundNumber = getCurrentRoundNumber();
        return (
            currentRoundNumber,
            rounds[currentRoundNumber].startTime,
            rounds[currentRoundNumber].endTime,
            rounds[currentRoundNumber].amount
        );
    }

    function updateRoundFirstDeposit() internal {
        uint256 currentRound = getCurrentRoundNumber();
        if (rounds[currentRound].endTime == 0) {
            rounds[currentRound].endTime = now + roundTime;
        }
    }

    function roundOver() internal view returns(bool) {
        uint256 currentRound = getCurrentRoundNumber();
        if (rounds[currentRound].endTime == 0) {
            return false;
        } else {
            return rounds[currentRound].endTime < now;
        }
    }

    function newRound() internal {
        rounds.push(Round({
            finalized: false,
            startTime: now,
            endTime: 0, // the round start when have 1 deposit
            fee: fee,
            amount: amount
        }));

        emit RoundStarted(getCurrentRoundNumber());
    }
}


// Dependency file: contracts/TransferHelper.sol


// pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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


// Dependency file: contracts/Balance.sol


// pragma solidity 0.6.12;

// import "contracts/TransferHelper.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";


abstract contract BalanceStorage {
    mapping(address => uint256) public balances;
}

contract Balance is BalanceStorage {
    using SafeMath for uint256;

    // user claim their reward
    function claim() public {
        TransferHelper.safeTransferETH(msg.sender, balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function addBalance(address _user, uint256 _amount) internal {
        balances[_user] = balances[_user].add(_amount);
    }
}


// Dependency file: contracts/Maintainer.sol


// pragma solidity 0.6.12;


abstract contract Maintainer {
    address public maintainer;

    modifier onlyMaintainer() {
        require(msg.sender == maintainer, "ERROR: permission denied, only maintainer");
        _;
    }

    function setMaintainer(address _maintainer) external virtual;
}


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Root file: contracts/RunningMan.sol


pragma solidity 0.6.12;

// import "contracts/Round.sol";
// import "contracts/Balance.sol";
// import "contracts/Maintainer.sol";
// import "contracts/TransferHelper.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


contract RunningMan is Ownable, Round, Balance, Maintainer {
    using SafeMath for uint256;
    uint256 public winPercent;

    enum State {
        UNDEFINED, WIN, LOSE, REFUND
    }

    struct Player {
        address payable addr;
        uint256 balance;
        State state;
    }

    mapping(uint256 => Player[]) public players;

    constructor(
        uint256 _fee,
        uint256 _winPercent,
        uint256 _amount,
        uint256 _roundTime,
        address _maintainer
    ) public {
        fee = _fee;
        amount = _amount;
        roundTime = _roundTime;
        winPercent = _winPercent;
        maintainer = _maintainer;

        newRound();
    }

    // get total bet in this round
    function getCurrentRoundBalance() public view returns(uint256 balance) {
        uint256 currentRound = getCurrentRoundNumber();

        uint256 total;
        for (uint256 i=0; i<players[currentRound].length; i++) {
            total = total.add(players[currentRound][i].balance);
        }
        return total;
    }

    // player get their info in single round
    function getPlayer(uint256 _round, address payable _player) public view returns(uint256 playerBet, State playerState) {
        for (uint256 i=0; i<players[_round].length; i++) {
            if (players[_round][i].addr == _player) {
                return (players[_round][i].balance, players[_round][i].state);
            }
        }

        return (0, State.UNDEFINED);
    }

    // get total players of current round
    function getRoundPlayers(uint256 _round) public view returns(uint256) {
        return players[_round].length;
    }

    // player get their balance in single round
    function getBalance(uint256 _round, address payable _player) public view returns(uint256) {
        if (_round <= rounds.length - 1) {
            for (uint256 i=0; i<players[_round].length; i++) {
                if (players[_round][i].addr == _player) {
                    return players[_round][i].balance;
                }
            }
        }
        return 0;
    }

    function bet() public payable {
        uint256 currentRound = getCurrentRoundNumber();
        require(msg.value == rounds[currentRound].amount, "ERROR: amount not allowed");
        if (rounds[currentRound].endTime !=0 )
            require(rounds[currentRound].endTime >= now, "ERROR: round is over");

        bool isBet;
        for (uint256 i=0; i<players[currentRound].length; i++) {
            if (players[currentRound][i].addr == msg.sender) {
                isBet = true;
            }
        }

        require(isBet == false, "ERROR: already bet");
        
        if (!isBet) {
            players[currentRound].push(Player({
                addr: msg.sender,
                balance: msg.value,
                state: State.UNDEFINED
            }));

            updateRoundFirstDeposit();
            emit Bet(currentRound, msg.sender, msg.value);
        }
    }

    // open new round
    function _open() internal {
        newRound();
    }

    function _end() internal {
        uint256 currentRound = getCurrentRoundNumber();
        _calculate(currentRound);
        rounds[currentRound].finalized = true;

        emit RoundEnded(currentRound);
    }

    // calculate winners and profit
    function _calculate(uint256 _round) internal {
        uint256 onePercent = 100*(10**6);
        uint256 numberOfWinners = players[_round].length.mul(winPercent).div(onePercent);

        if (numberOfWinners <= 0) {
            // not enough players to play the game
            // refund to user
            for (uint256 i=0 ;i<players[_round].length; i++) {
                TransferHelper.safeTransferETH(players[_round][i].addr, players[_round][i].balance);
                players[_round][i].state = State.REFUND;
            }
        } else {
            uint256 totalReward;
            for (uint256 i=0; i<players[_round].length; i++) {
                totalReward = totalReward.add(players[_round][i].balance);
                if (i < numberOfWinners) {
                    players[_round][i].state = State.WIN;
                } else {
                    players[_round][i].state = State.LOSE;
                }
            }

            uint256 feeAmount = totalReward.mul(fee).div(100).div(10**6);
            TransferHelper.safeTransferETH(owner(), feeAmount);
            totalReward = totalReward.sub(feeAmount);

            uint256 winAmount = totalReward.div(numberOfWinners);
            for (uint256 i=0; i<numberOfWinners; i++) {
                players[_round][i].balance = winAmount;
                addBalance(players[_round][i].addr, winAmount);
                totalReward = totalReward.sub(winAmount);
            }

            if (totalReward > 0) {
                TransferHelper.safeTransferETH(owner(), totalReward);
            }
        }
    }

    function setRules(uint256 _fee, uint256 _amount, uint256 _roundTime, uint256 _winPercent) public onlyOwner {
        fee = _fee;
        amount = _amount;
        roundTime = _roundTime;
        winPercent = _winPercent;
    }

    function setMaintainer(address _maintainer) public override onlyOwner {
        maintainer = _maintainer;
    }

    // require the round is over
    // only maintainer address can trigger
    function reset() public onlyMaintainer {
        require(roundOver(), "ERROR: round is not over");
        _end();
        _open();
    }
}