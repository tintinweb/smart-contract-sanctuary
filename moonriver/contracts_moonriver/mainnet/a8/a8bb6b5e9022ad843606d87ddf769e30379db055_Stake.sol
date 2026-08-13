/**
 *Submitted for verification at moonriver.moonscan.io on 2022-04-19
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/libraries/AdminUpgradeable.sol



pragma solidity >=0.8.0;

abstract contract AdminUpgradeable {
    address public admin;
    address public adminCandidate;

    function _initializeAdmin(address _admin) internal {
        require(admin == address(0), "admin already set");

        admin = _admin;
    }

    function candidateConfirm() external {
        require(msg.sender == adminCandidate, "not Candidate");
        emit AdminChanged(admin, adminCandidate);

        admin = adminCandidate;
        adminCandidate = address(0);
    }

    function setAdminCandidate(address _candidate) external onlyAdmin {
        adminCandidate = _candidate;
        emit Candidate(_candidate);
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "not admin");
        _;
    }

    event Candidate(address indexed newAdmin);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
}
// File: contracts/core/interfaces/IFactory.sol



pragma solidity >=0.8.0;

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    event PairCreateLocked(
        address indexed caller
    );
    event PairCreateUnlocked(
        address indexed caller
    );
    event BootstrapSetted(
        address indexed tokenA,
        address indexed tokenB,
        address indexed bootstrap
    );
    event FeetoUpdated(
        address indexed feeto
    );
    event FeeBasePointUpdated(
        uint8 basePoint
    );

    function feeto() external view returns (address);

    function feeBasePoint() external view returns (uint8);

    function lockForPairCreate() external view returns (bool);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
    
    function getBootstrap(address tokenA, address tokenB)
        external
        view
        returns (address bootstrap);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// File: contracts/core/interfaces/IPair.sol



pragma solidity >=0.8.0;

interface IPair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function initialize(address, address) external;
}

// File: contracts/libraries/Math.sol



pragma solidity >=0.8.0;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// File: contracts/libraries/Helper.sol



pragma solidity >=0.8.0;




library Helper {
    using Math for uint256;

    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Helper: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Helper: ZERO_ADDRESS");
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        return IFactory(factory).getPair(tokenA, tokenB);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IPair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferNativeCurrency(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferNativeCurrency: NativeCurrency transfer failed"
        );
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Helper: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "Helper: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Helper: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "Helper: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "Helper: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "Helper: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/periphery/Stake.sol


pragma solidity >=0.8.0;






contract Stake is ReentrancyGuard, AdminUpgradeable {
    using Math for uint256;

    // Info of each staker
    struct StakerInfo {
        uint256 stakedAmount;      // How many stake tokens the user has provided
        uint256 lastUpdatedBlock;  // Last block number that user behavior occurs
        uint256 accInterest;       // Accumulated interest the user has owned
    }

    // The STAKED TOKEN
    address public immutable STAKED_TOKEN;
    // The REWARD TOKEN
    address public immutable REWARD_TOKEN;
    // The block when stake starts
    uint256 public immutable START_BLOCK;
    // The block when stake ends
    uint256 public immutable END_BLOCK;
    // The total interest of whole stake
    uint256 public totalInterest;
    // The total staked amount of whole stake
    uint256 public totalStakedAmount;
    // The total reward amount of whole stake
    uint256 public totalRewardAmount;

    // Is stake paused
    bool private _stakePaused;

    // Info of each staker that stakes token
    mapping(address => StakerInfo) private _stakerInfos;

    event Staked(address indexed user, uint256 amount, uint256 interest);
    event Redeem(address indexed user, uint256 redeemAmount, uint256 interest);
    event RewardsClaimed(address indexed to, uint256 amount);
    event WithdrawExtraFunds(address indexed token, address indexed to, uint256 amount);
    event StakePaused(address indexed caller);
    event StakeUnpaused(address indexed caller);

    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock
    ) {
        require(_startBlock >= block.number, 'INVALID_START_BLOCK');
        require(_endBlock > _startBlock, 'INVALID_STAKE_PERIOD');

        _initializeAdmin(msg.sender);
        STAKED_TOKEN = _stakeToken;
        REWARD_TOKEN = _rewardToken;
        START_BLOCK = _startBlock;
        END_BLOCK = _endBlock;
        totalRewardAmount = IERC20(_rewardToken).balanceOf(address(this));
        
        _stakePaused = false;
    }

    modifier beforeEndPeriod() {
        require(block.number < END_BLOCK, "OVER_PERIOD");
        _;
    }

    modifier whenStakeNotPaused() {
        require(!_stakePaused, "STAKE_PAUSED");
        _;
    }

    /**
     * @dev add reward amount by admin
     **/
    function addReward(uint256 amount) external onlyAdmin beforeEndPeriod {
        Helper.safeTransferFrom(
            REWARD_TOKEN,
            msg.sender,
            address(this),
            amount
        );
        totalRewardAmount = totalRewardAmount.add(amount);
    }

    /**
     * @dev remove reward amount by admin
     **/
    function removeReward(uint256 amount) external onlyAdmin beforeEndPeriod {
        require(amount <= totalRewardAmount, 'INSUFFICIENT_REWARD_AMOUNT');
        Helper.safeTransfer(REWARD_TOKEN, msg.sender, amount);
        totalRewardAmount = totalRewardAmount.sub(amount);
    }

    /**
     * @dev Return funds directly transfered to this contract, will not affect the portion of the amount 
     *      that participated in stake using `stake` function
     **/
    function withdrawExtraFunds(address token, address to, uint256 amount) external onlyAdmin {
        if (token == STAKED_TOKEN) {
            uint256 stakedBalance = IERC20(STAKED_TOKEN).balanceOf(address(this));
            require(stakedBalance.sub(amount) >= totalStakedAmount, 'INSUFFICIENT_STAKED_BALANCE');
        }
        if (token == REWARD_TOKEN) {
            uint256 rewardBalance = IERC20(REWARD_TOKEN).balanceOf(address(this));
            require(rewardBalance.sub(amount) >= totalRewardAmount, 'INSUFFICIENT_REWARD_BALANCE');
        }
        Helper.safeTransfer(token, to, amount);

        emit WithdrawExtraFunds(token, to, amount);
    }
    
    function getStakerInfo(address staker) 
        external 
        view 
        returns (uint256 stakedAmount, uint256 accInterest)  
    {
        StakerInfo memory stakerInfo = _stakerInfos[staker];
        stakedAmount = stakerInfo.stakedAmount;
        accInterest = stakerInfo.accInterest;
    }
    
    function pauseStake() external onlyAdmin {
        require(!_stakePaused, 'STAKE_PAUSED');
        _stakePaused = true;
        emit StakePaused(msg.sender);
    }

    function unpauseStake() external onlyAdmin {
        require(_stakePaused, 'STAKE_UNPAUSED');
        _stakePaused = false;
        emit StakeUnpaused(msg.sender);
    }

    /**
     * @dev Stakes tokens
     * @param amount Amount to stake
     **/
    function stake(uint256 amount) external beforeEndPeriod nonReentrant whenStakeNotPaused {
        require(amount > 0, 'INVALID_ZERO_AMOUNT');
        StakerInfo storage stakerInfo = _stakerInfos[msg.sender];

        Helper.safeTransferFrom(
            STAKED_TOKEN,
            msg.sender,
            address(this),
            amount
        );

        stakerInfo.lastUpdatedBlock = stakerInfo.lastUpdatedBlock < START_BLOCK
            ? START_BLOCK
            : block.number;

        uint256 addedInterest = amount.mul(END_BLOCK.sub(stakerInfo.lastUpdatedBlock));

        totalInterest = totalInterest.add(addedInterest);
        totalStakedAmount = totalStakedAmount.add(amount);

        stakerInfo.stakedAmount = stakerInfo.stakedAmount.add(amount);
        stakerInfo.accInterest = stakerInfo.accInterest.add(addedInterest);
        
        emit Staked(msg.sender, amount, addedInterest);
    }

    /**
     * @dev Redeems staked tokens
     * @param amount Amount to redeem
     **/
    function redeem(uint256 amount) external nonReentrant {
        require(amount > 0, 'INVALID_ZERO_AMOUNT');
        require(block.number > START_BLOCK, "STAKE_NOT_STARTED");

        StakerInfo storage stakerInfo = _stakerInfos[msg.sender];
        require(amount <= totalStakedAmount, 'INSUFFICIENT_TOTAL_STAKED_AMOUNT');
        require(amount <= stakerInfo.stakedAmount, 'INSUFFICIENT_STAKED_AMOUNT');

        stakerInfo.lastUpdatedBlock = block.number < END_BLOCK ? block.number : END_BLOCK;

        uint256 removedInterest = amount.mul(END_BLOCK.sub(stakerInfo.lastUpdatedBlock));

        totalInterest = totalInterest.sub(removedInterest);
        totalStakedAmount = totalStakedAmount.sub(amount);

        stakerInfo.stakedAmount = stakerInfo.stakedAmount.sub(amount);
        stakerInfo.accInterest = stakerInfo.accInterest.sub(removedInterest);

        Helper.safeTransfer(STAKED_TOKEN, msg.sender, amount);
        emit Redeem(msg.sender, amount, removedInterest);
    }

    /**
     * @dev Return the total amount of estimated rewards from an staker
     * @param staker The staker address
     * @return The rewards
     */
    function getEstimatedRewardsBalance(address staker) external view returns (uint256) {
        StakerInfo memory stakerInfo = _stakerInfos[staker];
        if (totalInterest != 0) {
            return totalRewardAmount.mul(stakerInfo.accInterest) / totalInterest;
        }
        return 0;
    }

    /**
     * @dev Claims all amount of `REWARD_TOKEN` calculated from staker interest
     **/
    function claim() external nonReentrant {
        require(block.number > END_BLOCK, "STAKE_NOT_FINISHED");
        require(totalInterest > 0, 'INVALID_ZERO_TOTAL_INTEREST');

        StakerInfo storage stakerInfo = _stakerInfos[msg.sender];
        require(stakerInfo.accInterest > 0, "INSUFFICIENT_ACCUMULATED_INTEREST");

        uint256 claimRewardAmount = totalRewardAmount.mul(stakerInfo.accInterest) / totalInterest;

        stakerInfo.accInterest = 0;
        stakerInfo.lastUpdatedBlock = block.number;

        Helper.safeTransfer(REWARD_TOKEN, msg.sender, claimRewardAmount);
        emit RewardsClaimed(msg.sender, claimRewardAmount);
    }
}