/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

// File: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

// File: contracts/Epoch.sol

pragma solidity ^0.6.0;




contract Epoch is Ownable {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastExecutedAt;

    /* ========== CONSTRUCTOR ========== */

    constructor(uint256 _period) public {
        period = _period;
    }

    /* ========== Modifier ========== */

    modifier checkStartTime {
        require(startTime != 0, "Epoch: not started yet");
        require(block.timestamp >= startTime, "Epoch: not started yet");

        _;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(
            _startTime > block.timestamp,
            "Epoch: invalid start time, should be later than now"
        );
        startTime = _startTime;
        lastExecutedAt = startTime;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // epoch
    function getLastEpoch() public view returns (uint256) {
        return lastExecutedAt.sub(startTime).div(period);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return Math.max(startTime, block.timestamp).sub(startTime).div(period);
    }

    // params
    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    /* ========== GOVERNANCE ========== */

    // function setPeriod(uint256 _period) external onlyOwner {
    //     period = _period;
    // }

    // ========== MUTATE FUNCTIONS ==========

    function updateEpoch() internal {
        lastExecutedAt = block.timestamp;
    }
}

// File: contracts/Auction.sol

pragma solidity >=0.6.0 <0.7.0;









contract Auction is Context, Epoch, ReentrancyGuard {
    using SafeMath for uint256;

    struct AuctionLobbyParticipate {
        uint256[] epoches;
        mapping(uint256 => uint256) BNBParticipated;
        mapping(uint256 => uint256) cycleEarned;
        uint256 availableCycle;
    }

    struct CycleStake {
        uint256 epoch;
        uint256 cycleStaked;
        uint256 BNBEarned;
        bool active;
    }

    struct FlipStake {
        uint256 flipStaked;
        uint256 cycleEarned;
    }

    uint256 teamSharePercent = 50;
    uint256 rewardForFlipStakersPercent = 50;
    uint256 percentMax = 1000;

    address public BNBAddress;
    address public CYCLEBNBAddress;

    uint256 private constant DAILY_MINT_CAP = 100_000 * 10**18;

    // Can only get via view functions since need to update rewards if required
    mapping(address => AuctionLobbyParticipate)
        private auctionLobbyParticipates;
    mapping(address => CycleStake[]) private cycleStakes;

    mapping(address => FlipStake) private flipStakes;

    address[] auctionLobbyParticipaters;
    address[] cycleStakers;
    address[] flipStakers;

    // epoch => data
    mapping(uint256 => uint256) private dailyTotalBNB;

    uint256 public totalCycleStaked;
    uint256 public totalFlipStaked;

    address payable public teamAddress;
    uint256 private teamShare;

    ICycleToken private cycleToken;

    event Participate(uint256 amount, uint256 participateTime, address account);
    event TakeShare(uint256 reward, uint256 participateTime, address account);
    event Stake(uint256 amount, uint256 stakeTime, address account);
    event Unstake(uint256 reward, uint256 stakeTime, address account);
    event StakeFlip(uint256 amount, uint256 stakeTime, address account);
    event UnstakeFlip(uint256 reward, uint256 stakeTime, address account);

    constructor(
        address cycleTokenAddress,
        address uniswapV2Router02Address,
        address payable _teamAddress
    ) public Epoch(900) {
        // 1 day period
        require(cycleTokenAddress != address(0), "ZERO ADDRESS");
        require(uniswapV2Router02Address != address(0), "ZERO ADDRESS");
        require(_teamAddress != address(0), "ZERO ADDRESS");

        cycleToken = ICycleToken(cycleTokenAddress);
        teamAddress = _teamAddress;

        IUniswapV2Router02 uniswapV2Router02 =
            IUniswapV2Router02(uniswapV2Router02Address);

        BNBAddress = uniswapV2Router02.WETH();

        address uniswapV2FactoryAddress = uniswapV2Router02.factory();
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2FactoryAddress);
        CYCLEBNBAddress = factory.getPair(BNBAddress, cycleTokenAddress);

        if (CYCLEBNBAddress == address(0))
            CYCLEBNBAddress = factory.createPair(BNBAddress, cycleTokenAddress);
    }

    modifier checkValue(uint256 amount) {
        require(amount > 0, "Amount cannot be zero");

        _;
    }

    modifier distributeRewards {
        if (getLastEpoch() < getCurrentEpoch()) {
            uint256 prevEpoch = getLastEpoch();

            updateEpoch();

            if (dailyTotalBNB[prevEpoch] > 0) {
                // Distribute the minted tokens to auction participaters
                for (uint256 i = 0; i < auctionLobbyParticipaters.length; i++) {
                    address participater = auctionLobbyParticipaters[i];

                    AuctionLobbyParticipate storage ap =
                        auctionLobbyParticipates[participater];

                    uint256 newReward =
                        DAILY_MINT_CAP.mul(ap.BNBParticipated[prevEpoch]).div(
                            dailyTotalBNB[prevEpoch]
                        );

                    ap.cycleEarned[prevEpoch] = newReward;
                    ap.availableCycle = ap.availableCycle.add(newReward);
                }

                // Distribute BNB to cycle stakers
                if (cycleStakers.length > 0) {
                    for (uint256 i = 0; i < cycleStakers.length; i++) {
                        address cycleStaker = cycleStakers[i];

                        CycleStake[] storage stakes = cycleStakes[cycleStaker];

                        for (uint256 j = 0; j < stakes.length; j++) {
                            if (
                                stakes[j].active &&
                                getCurrentEpoch().sub(stakes[j].epoch) < 100
                            ) {
                                stakes[j].BNBEarned = stakes[j].BNBEarned.add(
                                    dailyTotalBNB[prevEpoch]
                                        .mul(percentMax - teamSharePercent)
                                        .div(percentMax)
                                        .mul(stakes[j].cycleStaked)
                                        .div(totalCycleStaked)
                                );
                            }
                        }
                    }
                } else {
                    // If no stakers, then send to the team fund
                    teamShare = teamShare.add(
                        dailyTotalBNB[prevEpoch]
                            .mul(percentMax - teamSharePercent)
                            .div(percentMax)
                    );
                }
            }
        }

        _;
    }

    // Participate in auction lobby
    function participate()
        external
        payable
        nonReentrant
        checkValue(msg.value)
        checkStartTime
        distributeRewards
    {
        uint256 currentEpoch = getCurrentEpoch();

        // mint tokens only when the first auction participate happens in each epoch
        if (dailyTotalBNB[currentEpoch] == 0) {
            cycleToken.mint(DAILY_MINT_CAP);
            takeTeamShare();
        }

        AuctionLobbyParticipate storage auctionParticipate =
            auctionLobbyParticipates[_msgSender()];

        if (auctionParticipate.epoches.length == 0) {
            auctionLobbyParticipaters.push(_msgSender());
        }

        auctionParticipate.BNBParticipated[currentEpoch] = auctionParticipate
            .BNBParticipated[currentEpoch]
            .add(msg.value);

        if (
            auctionParticipate.epoches.length == 0 ||
            auctionParticipate.epoches[auctionParticipate.epoches.length - 1] <
            currentEpoch
        ) {
            auctionParticipate.epoches.push(currentEpoch);
        }

        dailyTotalBNB[currentEpoch] = dailyTotalBNB[currentEpoch].add(
            msg.value
        );

        // 5% of the deposited BNB goes to team
        teamShare = teamShare.add(
            msg.value.mul(teamSharePercent).div(percentMax)
        );

        emit Participate(msg.value, currentEpoch, _msgSender());
    }

    function takeAuctionLobbyShare() external nonReentrant distributeRewards {
        require(
            auctionLobbyParticipates[_msgSender()].availableCycle > 0,
            "Nothing to withdraw"
        );

        AuctionLobbyParticipate storage ap =
            auctionLobbyParticipates[_msgSender()];

        cycleToken.transfer(_msgSender(), ap.availableCycle);

        emit TakeShare(ap.availableCycle, getCurrentEpoch(), _msgSender());

        ap.availableCycle = 0;
    }

    function stake(uint256 amount)
        external
        nonReentrant
        checkValue(amount)
        checkStartTime
        distributeRewards
    {
        CycleStake[] storage stakes = cycleStakes[_msgSender()];

        uint256 activeLen = 0;

        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].active) {
                activeLen++;
            }
        }

        if (activeLen == 0) {
            cycleStakers.push(_msgSender());
        }

        stakes.push(CycleStake(getCurrentEpoch(), amount, 0, true));
        totalCycleStaked = totalCycleStaked.add(amount);

        cycleToken.transferFrom(_msgSender(), address(this), amount);

        distributeToFlipStakersAndBurn(amount);

        emit Stake(amount, getCurrentEpoch(), _msgSender());
    }

    function unstake(uint256 index) external nonReentrant distributeRewards {
        require(
            cycleStakes[_msgSender()][index].BNBEarned > 0,
            "Nothing to unstake"
        );
        require(
            cycleStakes[_msgSender()][index].active,
            "You already unstaked for this stake"
        );

        uint256 reward = cycleStakes[_msgSender()][index].BNBEarned;
        _msgSender().transfer(reward);

        totalCycleStaked = totalCycleStaked.sub(
            cycleStakes[_msgSender()][index].cycleStaked
        );

        // Deactivate this stake
        cycleStakes[_msgSender()][index].active = false;

        uint256 activeLen = 0;

        for (uint256 i = 0; i < cycleStakes[_msgSender()].length; i++) {
            if (cycleStakes[_msgSender()][i].active) {
                activeLen++;
            }
        }

        if (activeLen == 0) {
            deleteFromArrayByValue(_msgSender(), cycleStakers);
        }

        emit Unstake(reward, getCurrentEpoch(), _msgSender());
    }

    function stakeFlip(uint256 amount)
        external
        nonReentrant
        checkValue(amount)
        checkStartTime
    {
        FlipStake storage flipStake = flipStakes[_msgSender()];

        if (flipStake.flipStaked == 0) {
            flipStakers.push(_msgSender());
        }

        flipStake.flipStaked = flipStake.flipStaked.add(amount);
        totalFlipStaked = totalFlipStaked.add(amount);

        // Burn staking flips
        IERC20(CYCLEBNBAddress).transferFrom(_msgSender(), address(0), amount);

        emit StakeFlip(amount, getCurrentEpoch(), _msgSender());
    }

    function takeFlipReward(address user) external {
        require(flipStakes[user].cycleEarned > 0, "Nothing to withdraw");

        FlipStake storage flipStake = flipStakes[user];

        cycleToken.transfer(user, flipStake.cycleEarned);
        flipStake.cycleEarned = 0;
    }

    // Team can withdraw its share if wants
    function takeTeamShare() public distributeRewards {
        if (teamShare > 0) {
            teamAddress.transfer(teamShare);
            teamShare = 0;
        }
    }

    // =========== Distribute function ==============

    function distributeToFlipStakersAndBurn(uint256 cycleAmount) private {
        uint256 cycleRewardsForFlipStakers =
            cycleAmount.mul(rewardForFlipStakersPercent).div(percentMax);

        for (uint256 i = 0; i < flipStakers.length; i++) {
            FlipStake storage flipStake = flipStakes[flipStakers[i]];
            flipStake.cycleEarned = flipStake.cycleEarned.add(
                cycleRewardsForFlipStakers.mul(flipStake.flipStaked).div(
                    totalFlipStaked
                )
            );
        }

        uint256 burnCycleAmount = cycleAmount;
        if (flipStakers.length > 0) {
            burnCycleAmount = burnCycleAmount.sub(cycleRewardsForFlipStakers);
        }

        cycleToken.burn(burnCycleAmount);
    }

    // =========== View functions =============

    function getCycleAddress() external view returns (address) {
        return address(cycleToken);
    }

    function getAuctionLobbyParticipateEpoches(address user)
        external
        view
        returns (uint256[] memory)
    {
        return auctionLobbyParticipates[user].epoches;
    }

    function getAuctionLobbyParticipateBNBParticipated(
        address user,
        uint256 epoch
    ) external view returns (uint256) {
        return auctionLobbyParticipates[user].BNBParticipated[epoch];
    }

    function getAuctionLobbyParticipateCycleEarned(address user, uint256 epoch)
        external
        view
        returns (uint256)
    {
        if (epoch < getLastEpoch() || getLastEpoch() == getCurrentEpoch()) {
            return auctionLobbyParticipates[user].cycleEarned[epoch];
        } else {
            return calculateNewBNBEarned(user);
        }
    }

    function getAuctionLobbyParticipateAvailableCycle(address user)
        external
        view
        returns (uint256)
    {
        return
            auctionLobbyParticipates[user].availableCycle +
            calculateNewBNBEarned(user);
    }

    function getCycleStakeLength(address user) external view returns (uint256) {
        return cycleStakes[user].length;
    }

    function getCycleStake(address user, uint256 index)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            cycleStakes[user][index].epoch,
            cycleStakes[user][index].cycleStaked,
            cycleStakes[user][index].BNBEarned +
                calculateNewCycleEarned(user, index),
            cycleStakes[user][index].active
        );
    }

    function getFlipStake(address user)
        external
        view
        returns (uint256, uint256)
    {
        return (flipStakes[user].flipStaked, flipStakes[user].cycleEarned);
    }

    function getDailyTotalBNB(uint256 epoch) external view returns (uint256) {
        return dailyTotalBNB[epoch];
    }

    function getTeamShare() external view returns (uint256) {
        if (getLastEpoch() < getCurrentEpoch()) {
            if (dailyTotalBNB[getLastEpoch()] > 0) {
                if (cycleStakers.length == 0) {
                    // If no stakers, then send to the team fund
                    return
                        teamShare.add(
                            dailyTotalBNB[getLastEpoch()]
                                .mul(percentMax - teamSharePercent)
                                .div(percentMax)
                        );
                }
            }
        }

        return teamShare;
    }

    // =========== Calculate new rewards =============

    function calculateNewBNBEarned(address user)
        private
        view
        returns (uint256)
    {
        uint256 lastEpoch = getLastEpoch();

        if (lastEpoch < getCurrentEpoch()) {
            if (dailyTotalBNB[lastEpoch] > 0) {
                return
                    DAILY_MINT_CAP
                        .mul(
                        auctionLobbyParticipates[user].BNBParticipated[
                            lastEpoch
                        ]
                    )
                        .div(dailyTotalBNB[lastEpoch]);
            }
        }

        return 0;
    }

    function calculateNewCycleEarned(address user, uint256 j)
        private
        view
        returns (uint256)
    {
        uint256 lastEpoch = getLastEpoch();

        if (lastEpoch < getCurrentEpoch()) {
            if (dailyTotalBNB[lastEpoch] > 0) {
                return
                    dailyTotalBNB[lastEpoch]
                        .mul(percentMax - teamSharePercent)
                        .div(percentMax)
                        .mul(cycleStakes[user][j].cycleStaked)
                        .div(totalCycleStaked);
            }
        }

        return 0;
    }

    // =========== Array Utilites ============

    function findIndexFromArray(address value, address[] memory array)
        private
        pure
        returns (uint256)
    {
        uint256 i = 0;
        for (; i < array.length; i++) {
            if (array[i] == value) {
                return i;
            }
        }

        return i;
    }

    function deleteFromArrayByValue(address value, address[] storage array)
        private
    {
        uint256 i = findIndexFromArray(value, array);

        while (i < array.length - 1) {
            array[i] = array[i + 1];
            i++;
        }

        array.pop();
    }
}