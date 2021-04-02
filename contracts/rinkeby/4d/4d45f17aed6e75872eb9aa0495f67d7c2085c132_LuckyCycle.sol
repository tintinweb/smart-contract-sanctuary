/**
 *Submitted for verification at Etherscan.io on 2021-04-01
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/Interfaces.sol

/* solium-disable */
pragma solidity >=0.6.0 <0.7.0;


/* solium-disable-next-line */
interface ICycleToken is IERC20 {
    function mint(uint256 amount) external;

    function burn(uint256 amount) external;

    function setAuction(address account) external;
}

interface IUniswapV2Router02 {
    function factory() external view returns (address);

    function WETH() external view returns (address);
}

// File: contracts/Lottery.sol

/* solium-disable */
pragma solidity >=0.6.0 <0.7.0;




interface IAuction {
    function getFlipStakers() external view returns (address[] memory);

    function getFlipStake(address user)
        external
        view
        returns (uint256, uint256);

    function totalFlipStaked() external view returns (uint256);
}

contract LuckyCycle is Ownable {
    using SafeMath for uint256;

    mapping(uint256 => mapping(address => uint256)) public entryLengths;
    mapping(uint256 => address[]) public lotteryBag;

    // Variables for lottery information
    mapping(uint256 => address) public winners;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public bnbBalances;
    mapping(uint256 => uint256) public bnbPerRound;
    mapping(uint256 => uint256) public totalParticipatedCycles;

    address public cycleTokenAddress;
    address public auctionAddress;

    uint256 public amountToBurn;
    uint256 public amountForFlipFarmers;

    uint256 public startTime;
    uint256 public period;

    uint256 public round;

    uint256 private bnbForPreviousWinners;

    constructor(
        address _cycleAddress,
        address _auctionAddress,
        uint256 _startTime,
        uint256 _period
    ) public {
        cycleTokenAddress = _cycleAddress;
        auctionAddress = _auctionAddress;
        startTime = _startTime;
        period = _period;
    }

    modifier checkStartTime {
        require(block.timestamp > startTime, "Lottery not started yet");

        _;
    }

    modifier checkLotteryLive {
        require(block.timestamp < startTime + period, "Round already ended");

        _;
    }

    function declareWinner() external checkStartTime {
        require(
            block.timestamp >= startTime + period,
            "Current Round not ended yet"
        );

        if (lotteryBag[round].length > 0) {
            uint256 index = generateRandomNumber() % lotteryBag[round].length;
            address winnerAddress = lotteryBag[round][index];

            // Set winner for the previous epoch
            winners[round] = winnerAddress;
            balances[winnerAddress] = balances[winnerAddress].add(
                totalParticipatedCycles[round].div(2)
            );
            bnbBalances[winnerAddress] =
                address(this).balance -
                bnbForPreviousWinners;
            bnbPerRound[round] = address(this).balance - bnbForPreviousWinners;
            bnbForPreviousWinners = address(this).balance;

            amountToBurn = amountToBurn.add(
                totalParticipatedCycles[round].mul(45).div(100)
            );
            amountForFlipFarmers = amountForFlipFarmers.add(
                totalParticipatedCycles[round].mul(5).div(100)
            );

            burnAndRewardFlipFarmers();

            // event
            WinnerDeclared(
                winnerAddress,
                entryLengths[round][winnerAddress],
                round
            );
        }

        startTime = block.timestamp;
        round += 1;
    }

    function participate(uint256 ticketLength)
        external
        checkStartTime
        checkLotteryLive
    {
        require(ticketLength > 0, "You cannot buy zero tickets");

        ICycleToken(cycleTokenAddress).transferFrom(
            _msgSender(),
            address(this),
            ticketLength * 10**18
        );

        entryLengths[round][_msgSender()] = entryLengths[round][_msgSender()]
            .add(ticketLength);
        totalParticipatedCycles[round] = totalParticipatedCycles[round].add(
            ticketLength * 10**18
        );

        for (uint256 i = 0; i < ticketLength; i++) {
            lotteryBag[round].push(_msgSender());
        }

        // event
        PlayerParticipated(_msgSender(), ticketLength, round);
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, now, lotteryBag[round])
                )
            );
    }

    function burnAndRewardFlipFarmers() private {
        ICycleToken(cycleTokenAddress).transfer(
            0x000000000000000000000000000000000000dEaD,
            amountToBurn
        );
        amountToBurn = 0;

        address[] memory flipFarmers =
            IAuction(auctionAddress).getFlipStakers();
        uint256 totalFlipStaked = IAuction(auctionAddress).totalFlipStaked();

        for (uint256 i = 0; i < flipFarmers.length; i++) {
            (uint256 flipStaked, ) =
                IAuction(auctionAddress).getFlipStake(flipFarmers[i]);
            uint256 amount =
                amountForFlipFarmers.mul(flipStaked).div(totalFlipStaked);
            ICycleToken(cycleTokenAddress).transfer(flipFarmers[i], amount);
        }

        amountForFlipFarmers = 0;
    }

    function claimWinnerReward() external {
        require(balances[_msgSender()] > 0, "Balance is zero");

        ICycleToken(cycleTokenAddress).transfer(
            _msgSender(),
            balances[_msgSender()]
        );
        balances[_msgSender()] = 0;

        _msgSender().transfer(bnbBalances[_msgSender()]);
        bnbForPreviousWinners = bnbForPreviousWinners.sub(
            bnbBalances[_msgSender()]
        );
        bnbBalances[_msgSender()] = 0;
    }

    // Events
    event WinnerDeclared(
        address beneficiary,
        uint256 entryCount,
        uint256 epoch
    );

    event PlayerParticipated(
        address beneficiary,
        uint256 entryCount,
        uint256 epoch
    );
}