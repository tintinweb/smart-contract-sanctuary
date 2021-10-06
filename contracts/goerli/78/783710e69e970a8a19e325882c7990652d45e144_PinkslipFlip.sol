/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: contracts/PinkslipFlip.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;





contract PinkslipFlip is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 constant BIGNUMBER = 10 ** 18;

    /******************
    EVENTS
    ******************/
    event CreatedGame(uint256 indexed gameId, uint256 indexed slotId, address indexed wallet, uint256 amount, uint256 created);
    event CanceledGame(uint256 indexed gameId, uint256 indexed slotId, address indexed wallet, uint256 amount, uint256 created);
    event AcceptedGame(uint256 indexed gameId, uint256 indexed slotId, address indexed wallet, uint256 amount, uint256 created);
    event WinnedGame(uint256 indexed gameId, uint256 indexed slotId, address indexed wallet, uint256 amount, uint256 created);

    /******************
    INTERNAL ACCOUNTING
    *******************/
    address public ERC20;

    uint256 public totalGamesCount = 1;
    uint256 public feePercentage; // 10000 = 100%
    address public feeDestinator;

    mapping (uint256 => Game) public games;
    mapping (uint256 => uint256) public gamesSlots;
    mapping (address => uint256) public addressInSlot;

    struct Game {
        address owner;
        uint256 amount;
        address acceptedBy;
        address winner;
        uint256 endDate;
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    constructor(
        address _ERC20,
        address _feeDestinator,
        uint256 _feePercentage
    )
        public
    {
        require(address(_ERC20) != address(0), 'PinkslipFlip: Address must be different to 0x0');
        require(address(_feeDestinator) != address(0), 'PinkslipFlip: Address must be different to 0x0');
        require(_feePercentage < 10000, 'PinkslipFlip: Fee must be under 100%');
    
        ERC20 = _ERC20;
        feePercentage = _feePercentage;
        feeDestinator = _feeDestinator;
    }

    function createGame(
        uint256 _amount,
        uint256 _gameSlot
    )
        external
        slotAvailable(_gameSlot)
        whenNotPaused()
        returns (uint256)
    {
        require(_amount >= 1000000000000000000, 'PinkslipFlip: Min amount 1 token'); 
        require(_gameSlot >= 0 && _gameSlot < 12, 'PinkslipFlip: Slots from 0 to 11'); 
        
        uint256 lastSlotBySender = addressInSlot[msg.sender];
        uint256 gameIdOnLastUsedSlotBySender = gamesSlots[lastSlotBySender];
        require(
            gameIdOnLastUsedSlotBySender == 0 || 
            games[gameIdOnLastUsedSlotBySender].owner != msg.sender  || 
            _getTime() > games[gameIdOnLastUsedSlotBySender].endDate ,
            'PinkslipFlip: You already on slot'
        );

        uint256 timeNow = _getTime();
        uint256 newGameId = totalGamesCount;
        totalGamesCount += 1;

        games[newGameId] = Game({
            owner: msg.sender,
            amount: _amount,
            acceptedBy: address(0x0),
            winner: address(0x0),
            endDate: timeNow + 24 hours
        });

        gamesSlots[_gameSlot] = newGameId;
        addressInSlot[msg.sender] = _gameSlot;

        emit CreatedGame(newGameId, _gameSlot, msg.sender, _amount, timeNow);

        return newGameId;
    }

    function cancel(
        uint256 _gameSlot
    )
        external
        inProgress(_gameSlot)
        whenNotPaused()
        returns (uint256)
    {
        uint256 _gameId = gamesSlots[_gameSlot];

        require(games[_gameId].owner == msg.sender, 'PinkslipFlip: User is not the owner');

        uint256 timeNow = _getTime();
        games[_gameId].endDate = timeNow;

        gamesSlots[_gameSlot] = 0;
        addressInSlot[msg.sender] = 0;

        emit CanceledGame(_gameId, _gameSlot, msg.sender, games[_gameId].amount, timeNow);
    }

    function accept(
        uint256 _gameSlot
    )
        external
        inProgress(_gameSlot)
        whenNotPaused()
        returns (address)
    {
        require(msg.sender == tx.origin, 'PinkslipFlip: Calls from contracts are not allowed');

        uint256 _gameId = gamesSlots[_gameSlot];

        require(IERC20(ERC20).balanceOf(games[_gameId].owner) >= games[_gameId].amount, 'PinkslipFlip: Creator needs more token balance');
        require(IERC20(ERC20).allowance(games[_gameId].owner, address(this)) >= games[_gameId].amount, 'PinkslipFlip: Creator needs to allows the token');

        require(IERC20(ERC20).balanceOf(msg.sender) >= games[_gameId].amount, 'PinkslipFlip: User needs more token balance');
        require(IERC20(ERC20).allowance(msg.sender, address(this)) >= games[_gameId].amount, 'PinkslipFlip: User needs to allows the token');
        
        require(_gameId != 0, 'PinkslipFlip: Empty slot');
        require(msg.sender != games[_gameId].owner, 'PinkslipFlip: You can not accept your own game');
        
        uint256 timeNow = _getTime();
        uint256 amount = games[_gameId].amount;

        emit AcceptedGame(_gameId, _gameSlot, msg.sender, games[_gameId].amount, timeNow);

        uint256 randNumber = _randomNumber(10, _gameSlot);
        address winnerAddress = address(0x0);

        uint256 totalfee = 0;
        if (feePercentage > 0) {
            totalfee = (amount.mul(2)).mul(feePercentage).div(10000);
        }

        if (randNumber <= 5) {
            winnerAddress = games[_gameId].owner;
            IERC20(ERC20).transferFrom(msg.sender, winnerAddress, amount.sub(totalfee));
            if (totalfee > 0) {
                IERC20(ERC20).transferFrom(msg.sender, feeDestinator, totalfee);
            }
        } else {
            winnerAddress = msg.sender;
            IERC20(ERC20).transferFrom(games[_gameId].owner, winnerAddress, amount.sub(totalfee));
            if (totalfee > 0) {
                IERC20(ERC20).transferFrom(games[_gameId].owner, feeDestinator, totalfee);
            }
        }

        games[_gameId].acceptedBy = msg.sender;
        games[_gameId].winner = winnerAddress;

        gamesSlots[_gameSlot] = 0;
        addressInSlot[games[_gameId].owner] = 0;

        emit WinnedGame(_gameId, _gameSlot, winnerAddress, amount, timeNow);

        return winnerAddress;
    }

    function isSlotAvailable(uint256 _gameSlot) public view returns (bool) {
        uint256 gameId = gamesSlots[_gameSlot];

        return 
            !(games[gameId].owner != address(0x0) &&
            IERC20(ERC20).balanceOf(games[gameId].owner) >= games[gameId].amount &&
            IERC20(ERC20).allowance(games[gameId].owner, address(this)) >= games[gameId].amount &&
            games[gameId].endDate > _getTime());
    }

    function allSlotsStatus() external view returns (bool[] memory) {
        bool[] memory slots = new bool[](12);

        for (uint256 i=0; i < 12; i++) {
            slots[i] = isSlotAvailable(i);
        }

        return slots;
    }

    function setFeeAndDestinator(
        uint256 _feePercentage,
        address _feeDestinator
    )
        external
        onlyOwner()
    {
        require(_feePercentage < 10000, 'PinkslipFlip: Fee must be under 100%'); 
        require(address(_feeDestinator) != address(0), 'PinkslipFlip: Address must be different to 0x0'); 

        feePercentage = _feePercentage;
        feeDestinator = _feeDestinator;
    }


    /******************
    PRIVATE FUNCTIONS
    *******************/
    function _getTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function _randomNumber(uint256 _limit, uint256 _salt) internal view returns (uint256) {
        bytes32 _structHash = keccak256(
            abi.encode(
                blockhash(block.number - 1),
                block.difficulty,
                _getTime(),
                gasleft(),
                _salt
            )
        );
        uint256 randomNumber = uint256(_structHash);
        assembly {randomNumber := add(mod(randomNumber, _limit), 1)}
        return uint8(randomNumber);
    }

    /******************
    MODIFIERS
    *******************/
    modifier inProgress(uint256 _gameSlot) {
        require(_gameSlot >= 0 && _gameSlot < 50, 'PinkslipFlip: Slots from 0 to 49'); 

        uint256 gameId = gamesSlots[_gameSlot];
        require(
            (games[gameId].endDate > _getTime()) && games[gameId].acceptedBy == address(0x0),
            'PinkslipFlip: Game already ended'
        );
        _;
    }

    modifier slotAvailable(uint256 _gameSlot) {
        require(
            isSlotAvailable(_gameSlot),
            'PinkslipFlip: Slot not available'
        );
        _;
    }
}