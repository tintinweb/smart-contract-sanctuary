/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: Context

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: IUniswapV2Pair

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// Part: IUniswapV2Router01

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// Part: SafeMath

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Part: IUniswapV2Router02

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

// Part: Ownable

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: TokenInterface

interface TokenInterface is IERC20 {
    function burnFromVault(uint256 amount) external returns (bool);
}

// File: WeedVault.sol

contract WEEDVault is Context, Ownable {
    using SafeMath for uint256;

    TokenInterface public _WEED;
    TokenInterface public _LINK;
    TokenInterface public _UNI;
    TokenInterface public _weth;

    IUniswapV2Pair public _WEEDETHV2Pair;
    IUniswapV2Pair public _usdcETHV2Pair;

    IUniswapV2Router02 private _uniswapV2Router;

    address public _daoTreasury;

    uint16 public _allocPointForWEEDReward;
    uint16 public _allocPointForSwapReward;

    uint16 public _treasuryFee;
    uint16 public _rewardFee;
    uint16 public _lotteryFee;
    uint16 public _swapRewardFee;
    uint16 public _burnFee;
    uint16 public _earlyUnstakeFee;

    uint16 public _allocPointForLINK;
    uint16 public _allocPointForUNI;
    uint16 public _allocPointForWETH;

    uint256 public _firstRewardPeriod;
    uint256 public _secondRewardPeriod;

    uint256 public _firstRewardAmount;
    uint256 public _secondRewardAmount;

    uint256 public _claimPeriodForWEEDReward;
    uint256 public _claimPeriodForSwapReward;

    uint256 public _lockPeriod;

    uint256 public _minDepositETHAmount;

    bool public _enabledLock;
    bool public _enabledLottery;

    uint256 public _startBlock;

    uint256 private _lotteryAmount;
    uint256 public _lotteryLimit;

    uint256 public _collectedAmountForStakers;
    uint256 public _collectedAmountForSwap;
    uint256 public _collectedAmountForLottery;

    uint256 public _lotteryPaidOut;

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastClimedBlockForWEEDReward;
        uint256 lastClimedBlockForSwapReward;
        uint256 lockedTo;
    }

    mapping(address => StakerInfo) public _stakers;

    // Info of winners for lottery.
    struct WinnerInfo {
        address winner;
        uint256 amount;
        uint256 timestamp;
    }
    WinnerInfo[] private winnerInfo;

    event ChangedEnabledLock(address indexed owner, bool lock);
    event ChangedEnabledLottery(address indexed owner, bool lottery);
    event ChangedLockPeriod(address indexed owner, uint256 period);
    event ChangedMinimumETHDepositAmount(address indexed owner, uint256 value);
    event ChangedRewardPeriod(address indexed owner, uint256 firstRewardPeriod, uint256 secondRewardPeriod);
    event ChangedClaimPeriod(address indexed owner, uint256 claimPeriodForWEEDReward, uint256 claimPeriodForSwapReward);
    event ChangedWEEDAddress(address indexed owner, address indexed WEED);
    event ChangedWEEDETHPair(address indexed owner, address indexed WEEDETHPair);
    event ChangedFeeInfo(address indexed owner, uint16 treasuryFee, uint16 rewardFee, uint16 lotteryFee, uint16 swapRewardFee, uint16 burnFee);
    event ChangedAllocPointsForSwapReward(address indexed owner, uint16 valueForLINK, uint16 valueForUNI, uint16 valueForWETH);
    event ChangedBurnFee(address indexed owner, uint16 value);
    event ChangedEarlyUnstakeFee(address indexed owner, uint16 value);
    event ChangedLotteryInfo(address indexed owner, uint16 lotteryFee, uint256 lotteryLimit);

    event ClaimedWEEDAvailableReward(address indexed owner, uint256 amount);
    event ClaimedSwapAvailableReward(address indexed owner, uint256 amount);
    event ClaimedWEEDReward(address indexed owner, uint256 available, uint256 pending);
    event ClaimedSwapReward(address indexed owner, uint256 amount);

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);

    event SentLotteryAmount(address indexed owner, uint256 amount, bool status);
    event EmergencyWithdrawToken(address indexed from, address indexed to, uint256 amount);
    event SwapAndLiquifyForWEED(address indexed msgSender, uint256 totAmount, uint256 ethAmount, uint256 WEEDAmount);

    // Modifier

    modifier onlyWEED() {
        require(
            address(_WEED) == _msgSender(),
            "Ownable: caller is not the WEED token contract"
        );
        _;
    }

    constructor(
        address daoTreasury,
        address LINK,
        address UNI,
        address weth,
        address usdcETHV2Pair
    ) public {
        _daoTreasury = daoTreasury;

        _LINK = TokenInterface(LINK);
        _UNI = TokenInterface(UNI);
        _weth = TokenInterface(weth);

        _usdcETHV2Pair = IUniswapV2Pair(usdcETHV2Pair);
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _firstRewardPeriod = 71500; // around 11 days, could be changed by governance
        _secondRewardPeriod = 429000; // around 66 days, could be changed by governance

        _firstRewardAmount = 2000e18; // 2000 WEED tokens, could be changed by governance
        _secondRewardAmount = 7900e18; // 7900 WEED tokens, could be changed by governance

        _claimPeriodForWEEDReward = 91000; // around 14 days, could be changed by governance
        _claimPeriodForSwapReward = 585000; // around 90 days, could be changed by governance

        _allocPointForWEEDReward = 8000; // 80% of reward will go to WEED reward, could be changed by governance
        _allocPointForSwapReward = 2000; // 20% of reward will go to swap(weth, UNI, LINK) reward, could be changed by governance

        // Set values divited from taxFee
        _treasuryFee = 2500; // 25% of taxFee to treasuryFee, could be changed by governance
        _rewardFee = 5000; // 50% of taxFee to stakers, could be changed by governance
        _lotteryFee = 500; // 5% of lottery Fee, could be changed by governance
        _swapRewardFee = 2000; // 20% of taxFee to swap tokens, could be changed by governance

        _earlyUnstakeFee = 1000; // 10% of early unstake fee, could be changed by governance

        // set alloc points of LINK, UNI, WETH in swap rewards, could be changed by governance
        _allocPointForLINK = 5000; // 50% of fee to buy LINK token, could be changed by governance
        _allocPointForUNI = 3000; // 30% of fee to buy UNI token, could be changed by governance
        _allocPointForWETH = 2000; // 20% of fee to buy WETH token, could be changed by governance

        // set the burn fee for withdraw early
        _burnFee = 2000; // 20% of pending reward to burn when staker request to withdraw pending reward, could be changed by governance

        _minDepositETHAmount = 1e17; // 0.1 ether, could be changed by governance
        _lockPeriod = 90 days; // could be changed by governance

        _enabledLock = true; // could be changed by governance
        _enabledLottery = true; // could be changed by governance

        _lotteryLimit = 1200e6; // $1200(1200 usd, decimals 6), could be changed by governance
        _startBlock = block.number;
    }

    /**
     * @dev Change Minimum Deposit ETH Amount. Call by only Governance.
     */
    function changeMinimumDepositETHAmount(uint256 amount) external onlyOwner {
        _minDepositETHAmount = amount;

        emit ChangedMinimumETHDepositAmount(_msgSender(), amount);
    }

    /**
     * @dev Change value of reward period. Call by only Governance.
     */
    function changeRewardPeriod(uint256 firstRewardPeriod, uint256 secondRewardPeriod) external onlyOwner {
        _firstRewardPeriod = firstRewardPeriod;
        _secondRewardPeriod = secondRewardPeriod;

        emit ChangedRewardPeriod(_msgSender(), firstRewardPeriod, secondRewardPeriod);
    }

    /**
     * @dev Change value of claim period. Call by only Governance.
     */
    function changeClaimPeriod(uint256 claimPeriodForWEEDReward, uint256 claimPeriodForSwapReward) external onlyOwner {
        _claimPeriodForWEEDReward = claimPeriodForWEEDReward;
        _claimPeriodForSwapReward = claimPeriodForSwapReward;

        emit ChangedClaimPeriod(_msgSender(), claimPeriodForWEEDReward, claimPeriodForSwapReward);
    }

    /**
     * @dev Enable lock functionality. Call by only Governance.
     */
    function enableLock(bool isLock) external onlyOwner {
        _enabledLock = isLock;

        emit ChangedEnabledLock(_msgSender(), isLock);
    }

    /**
     * @dev Enable lottery functionality. Call by only Governance.
     */
    function enableLottery(bool lottery) external onlyOwner {
        _enabledLottery = lottery;

        emit ChangedEnabledLottery(_msgSender(), lottery);
    }

    /**
     * @dev Change maximun lock period. Call by only Governance.
     */
    function changeLockPeriod(uint256 period) external onlyOwner {
        _lockPeriod = period;

        emit ChangedLockPeriod(_msgSender(), _lockPeriod);
    }

    function changeWEEDAddress(address WEED) external onlyOwner {
        _WEED = TokenInterface(WEED);

        emit ChangedWEEDAddress(_msgSender(), WEED);
    }

    function changeWEEDETHPair(address WEEDETHPair) external onlyOwner {
        _WEEDETHV2Pair = IUniswapV2Pair(WEEDETHPair);

        emit ChangedWEEDETHPair(_msgSender(), WEEDETHPair);
    }

    /**
     * @dev Update the treasury fee for this contract
     * defaults at 25% of taxFee, It can be set on only by WEED governance.
     * Note contract owner is meant to be a governance contract allowing WEED governance consensus
     */
    function changeFeeInfo(
        uint16 treasuryFee,
        uint16 rewardFee,
        uint16 lotteryFee,
        uint16 swapRewardFee,
        uint16 burnFee
    ) external onlyOwner {
        _treasuryFee = treasuryFee;
        _rewardFee = rewardFee;
        _lotteryFee = lotteryFee;
        _swapRewardFee = swapRewardFee;
        _burnFee = burnFee;

        emit ChangedFeeInfo(_msgSender(), treasuryFee, rewardFee, lotteryFee, swapRewardFee, burnFee);
    }

    function changeEarlyUnstakeFee(uint16 fee) external onlyOwner {
        _earlyUnstakeFee = fee;

        emit ChangedEarlyUnstakeFee(_msgSender(), fee);
    }

    /**
     * @dev Update the dev fee for this contract
     * defaults at 5% of taxFee, It can be set on only by WEED governance.
     * Note contract owner is meant to be a governance contract allowing WEED governance consensus
     */
    function changeLotteryInfo(uint16 lotteryFee, uint256 lotteryLimit) external onlyOwner {
        _lotteryFee = lotteryFee;
        _lotteryLimit = lotteryLimit;

        emit ChangedLotteryInfo(_msgSender(), lotteryFee, lotteryLimit);
    }

    /**
     * @dev Update the alloc points for LINK, weth, UNI rewards
     * defaults at 50, 30, 20 of
     * Note contract owner is meant to be a governance contract allowing WEED governance consensus
     */
    function changeAllocPointsForSwapReward(
        uint16 allocPointForLINK_,
        uint16 allocPointForUNI_,
        uint16 allocPointForWETH_
    ) external onlyOwner {
        _allocPointForLINK = allocPointForLINK_;
        _allocPointForUNI = allocPointForUNI_;
        _allocPointForWETH = allocPointForWETH_;

        emit ChangedAllocPointsForSwapReward(_msgSender(), allocPointForLINK_, allocPointForUNI_, allocPointForWETH_);
    }

    function addTaxFee(uint256 amount) external onlyWEED returns (bool) {
        uint256 daoTreasuryReward = amount.mul(uint256(_treasuryFee)).div(10000);
        _WEED.transfer(_daoTreasury, daoTreasuryReward);

        uint256 stakerReward = amount.mul(uint256(_rewardFee)).div(10000);
        _collectedAmountForStakers = _collectedAmountForStakers.add(stakerReward);

        uint256 lotteryReward =  amount.mul(uint256(_lotteryFee)).div(10000);
        _collectedAmountForLottery = _collectedAmountForLottery.add(lotteryReward);

        _collectedAmountForSwap = _collectedAmountForSwap.add(amount.sub(daoTreasuryReward).sub(stakerReward).sub(lotteryReward));

        return true;
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return _WEEDETHV2Pair.balanceOf(address(this));
    }

    function getWinners() external view returns (uint256) {
        return winnerInfo.length;
    }

    // Get WEED reward per block
    function getWEEDPerBlockForWEEDReward() public view returns (uint256) {
        uint256 multiplier = getMultiplier(_startBlock, block.number);

        if (multiplier == 0 || getTotalStakedAmount() == 0) {
            return 0;
        } else if (multiplier <= _firstRewardPeriod) {
            return _firstRewardAmount
                    .mul(uint256(_allocPointForWEEDReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_firstRewardPeriod)
                    .div(10000);
        } else if (multiplier > _firstRewardPeriod && multiplier <= _secondRewardPeriod) {
            return _secondRewardAmount
                    .mul(uint256(_allocPointForWEEDReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_secondRewardPeriod)
                    .div(10000);
        } else {
            return _collectedAmountForStakers.mul(1 ether).div(getTotalStakedAmount()).div(multiplier);
        }
    }

    function getWEEDPerBlockForSwapReward() public view returns (uint256) {
        uint256 multiplier = getMultiplier(_startBlock, block.number);

        if (multiplier == 0 || getTotalStakedAmount() == 0) {
            return 0;
        } else if (multiplier <= _firstRewardPeriod) {
            return _firstRewardAmount
                    .mul(uint256(_allocPointForSwapReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_firstRewardPeriod)
                    .div(10000);
        } else if (multiplier > _firstRewardPeriod && multiplier <= _secondRewardPeriod) {
            return _secondRewardAmount
                    .mul(uint256(_allocPointForSwapReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_secondRewardPeriod)
                    .div(10000);
        } else {
            return _collectedAmountForSwap.mul(1 ether).div(getTotalStakedAmount()).div(multiplier);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to) public pure returns (uint256) {
        return to.sub(from);
    }

    function _getLastAvailableClaimedBlock(
        uint256 from,
        uint256 to,
        uint256 period
    ) internal pure returns (uint256) {
        require(from <= to, "Vault: Invalid parameters for block number.");
        require(period > 0, "Vault: Invalid period.");

        uint256 multiplier = getMultiplier(from, to);

        return from.add(multiplier.sub(multiplier.mod(period)));
    }

    function swapETHForTokens(uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> WEED
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(_WEED);

        // make the swap
        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(0, path, address(this), block.timestamp);
    }

    function addLiquidityForEth(uint256 tokenAmount, uint256 ethAmount)
        private
    {
        _WEED.approve(address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(_WEED),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function swapAndLiquifyForWEED(uint256 amount) private returns (bool) {
        uint256 halfForEth = amount.div(2);
        uint256 otherHalfForWEED = amount.sub(halfForEth);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = _WEED.balanceOf(address(this));

        // swap ETH for tokens
        swapETHForTokens(otherHalfForWEED);

        // how much WEED did we just swap into?
        uint256 newBalance = _WEED.balanceOf(address(this)).sub(initialBalance);

        // add liquidity to uniswap
        addLiquidityForEth(newBalance, halfForEth);

        emit SwapAndLiquifyForWEED(_msgSender(), amount, halfForEth, newBalance);

        return true;
    }

    function swapTokensForTokens(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 tokenAmount,
        address receivedAddress
    ) private returns (bool) {
        address[] memory path = new address[](2);
        path[0] = fromTokenAddress;
        path[1] = toTokenAddress;

        IERC20(fromTokenAddress).approve(
            address(_uniswapV2Router),
            tokenAmount
        );

        // make the swap
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of pair token
            path,
            receivedAddress,
            block.timestamp
        );

        return true;
    }

    receive() external payable {}

    function stake() external payable returns (bool) {
        require(!isContract(_msgSender()), "Vault: Could not be contract.");
        require(msg.value >= _minDepositETHAmount, "Vault: insufficient staking amount.");

        // Check Initial Balance
        uint256 initialBalance = _WEEDETHV2Pair.balanceOf(address(this));

        // Call swap for WEED&ETH
        require(swapAndLiquifyForWEED(msg.value), "Vault: Failed to get LP tokens.");

        uint256 newBalance = _WEEDETHV2Pair.balanceOf(address(this)).sub(initialBalance);

        StakerInfo storage staker = _stakers[_msgSender()];

        if (staker.stakedAmount > 0) {
            claimWEEDReward();
            claimSwapReward();
        } else {
            staker.lastClimedBlockForWEEDReward = block.number;
            staker.lastClimedBlockForSwapReward = block.number;
        }

        staker.stakedAmount = staker.stakedAmount.add(newBalance);
        staker.lockedTo = _lockPeriod.add(block.timestamp);

        emit Staked(_msgSender(), newBalance);

        return _sendLotteryAmount();
    }

    /**
     * @dev Stake LP Token to get WEED-ETH LP tokens
     */
    function stakeLPToken(uint256 amount) external returns (bool) {
        require(!isContract(_msgSender()), "Vault: Could not be contract.");

        _WEEDETHV2Pair.transferFrom(_msgSender(), address(this), amount);

        StakerInfo storage staker = _stakers[_msgSender()];

        if (staker.stakedAmount > 0) {
            claimWEEDReward();
            claimSwapReward();
        } else {
            staker.lastClimedBlockForWEEDReward = block.number;
            staker.lastClimedBlockForSwapReward = block.number;
        }

        staker.stakedAmount = staker.stakedAmount.add(amount);
        staker.lockedTo = _lockPeriod.add(block.timestamp);

        emit Staked(_msgSender(), amount);

        return _sendLotteryAmount();
    }

    /**
     * @dev Unstake staked WEED-ETH LP tokens
     */
    function unstake(uint256 amount) external returns (bool) {
        require(!isContract(_msgSender()), "Vault: Could not be contract.");

        StakerInfo storage staker = _stakers[_msgSender()];

        require(
            staker.stakedAmount > 0 &&
            amount > 0 &&
            amount <= staker.stakedAmount,
            "Vault: Invalid amount to unstake."
        );

        claimWEEDReward();

        claimSwapReward();

        if (_enabledLock &&
            _stakers[_msgSender()].lockedTo > 0 &&
            block.timestamp < _stakers[_msgSender()].lockedTo
        ) {
            uint256 feeAmount = amount.mul(uint256(_earlyUnstakeFee)).div(10000);
            _WEEDETHV2Pair.transfer(_daoTreasury, feeAmount);
            _WEEDETHV2Pair.transfer(_msgSender(), amount.sub(feeAmount));
        } else {
           _WEEDETHV2Pair.transfer(_msgSender(), amount);
        }

        staker.stakedAmount = staker.stakedAmount.sub(amount);

        emit Unstaked(_msgSender(), amount);

        return _sendLotteryAmount();
    }

    function getWEEDReward(address account) public view returns (uint256 available, uint256 pending) {
        StakerInfo memory staker = _stakers[account];
        uint256 multiplier = getMultiplier(staker.lastClimedBlockForWEEDReward, block.number);

        if (staker.stakedAmount <= 0 || multiplier <= 0)  {
            return (0, 0);
        }

        uint256 WEEDPerblock = getWEEDPerBlockForWEEDReward();
        uint256 pendingBlockNum = multiplier.mod(_claimPeriodForWEEDReward);

        pending = WEEDPerblock.mul(pendingBlockNum).mul(staker.stakedAmount).div(1 ether);
        available = WEEDPerblock.mul(multiplier.sub(pendingBlockNum)).mul(staker.stakedAmount).div(1 ether);
    }

    function getSwapReward(address account) public view returns (uint256 available, uint256 pending) {
        StakerInfo memory staker = _stakers[account];
        uint256 multiplier = getMultiplier(staker.lastClimedBlockForSwapReward, block.number);

        if (staker.stakedAmount <= 0 || multiplier <= 0)  {
            return (0, 0);
        }

        uint256 WEEDPerblock = getWEEDPerBlockForSwapReward();
        uint256 pendingBlockNum = multiplier.mod(_claimPeriodForSwapReward);

        pending = WEEDPerblock.mul(pendingBlockNum).mul(staker.stakedAmount).div(1 ether);
        available = WEEDPerblock.mul(multiplier.sub(pendingBlockNum)).mul(staker.stakedAmount).div(1 ether);
    }

    function claimWEEDAvailableReward() public returns (bool) {

        (uint256 available, ) = getWEEDReward(_msgSender());

        require(available > 0, "Vault: No available reward.");

        require(
            safeWEEDTransfer(_msgSender(), available),
            "Vault: Failed to transfer."
        );

        emit ClaimedWEEDAvailableReward(_msgSender(), available);

        StakerInfo storage staker = _stakers[_msgSender()];
        staker.lastClimedBlockForWEEDReward = _getLastAvailableClaimedBlock(
            staker.lastClimedBlockForWEEDReward,
            block.number,
            _claimPeriodForWEEDReward
        );

        return _sendLotteryAmount();
    }

    function claimWEEDReward() public returns (bool) {
        (uint256 available, uint256 pending) = getWEEDReward(_msgSender());

        require(available > 0 || pending > 0, "Vault: No rewards");

        StakerInfo storage staker = _stakers[_msgSender()];

        if (available > 0) {
            require(
                safeWEEDTransfer(_msgSender(), available),
                "Vault: Failed to transfer."
            );
        }

        if (pending > 0) {
            uint256 burnAmount = pending.mul(_burnFee).div(10000);
            _WEED.burnFromVault(burnAmount);
            safeWEEDTransfer(_msgSender(), pending.sub(burnAmount));
            staker.lastClimedBlockForWEEDReward = block.number;
        } else if (available > 0) {
            staker.lastClimedBlockForWEEDReward = _getLastAvailableClaimedBlock(
                staker.lastClimedBlockForWEEDReward,
                block.number,
                _claimPeriodForWEEDReward
            );
        }

        emit ClaimedWEEDReward(_msgSender(), available, pending);

        return _sendLotteryAmount();
    }

    function claimSwapAvailableReward() public returns (bool) {

        (uint256 available, ) = getSwapReward(_msgSender());

        _swapAndClaimTokens(available);

        emit ClaimedSwapAvailableReward(_msgSender(), available);

        StakerInfo storage staker = _stakers[_msgSender()];
        staker.lastClimedBlockForSwapReward = _getLastAvailableClaimedBlock(
            staker.lastClimedBlockForSwapReward,
            block.number,
            _claimPeriodForSwapReward
        );

        return _sendLotteryAmount();
    }

    function claimSwapReward() public returns (bool) {

        (uint256 available, uint256 pending) = getSwapReward(_msgSender());

        if (pending > 0) {
            uint256 burnAmount = pending.mul(_burnFee).div(10000);
            _WEED.burnFromVault(burnAmount);
            pending = pending.sub(burnAmount);
        }

        _swapAndClaimTokens(available.add(pending));

        emit ClaimedSwapReward(_msgSender(), available.add(pending));

        StakerInfo storage staker = _stakers[_msgSender()];

        if (pending > 0) {
            staker.lastClimedBlockForSwapReward = block.number;
        } else {
            staker.lastClimedBlockForSwapReward = _getLastAvailableClaimedBlock(
                staker.lastClimedBlockForSwapReward,
                block.number,
                _claimPeriodForSwapReward
            );
        }

        return _sendLotteryAmount();
    }

    /**
     * @dev Withdraw WEED token from vault wallet to owner when only emergency!
     *
     */
    function emergencyWithdrawToken() external onlyOwner {
        require(_msgSender() != address(0), "Vault: Invalid address");

        uint256 tokenAmount = _WEED.balanceOf(address(this));
        require(tokenAmount > 0, "Vault: Insufficient amount");

        _WEED.transfer(_msgSender(), tokenAmount);
        emit EmergencyWithdrawToken(address(this), _msgSender(), tokenAmount);
    }

    function _swapAndClaimTokens(uint256 rewards) internal {
        require(rewards > 0, "Vault: No reward state");

        uint256 wethOldBalance = IERC20(_weth).balanceOf(address(this));

        // Swap WEED -> WETH And Get Weth Tokens For Reward
        require(
            swapTokensForTokens(
                address(_WEED),
                address(_weth),
                rewards,
                address(this)
            ),
            "Vault: Failed to swap from WEED to WETH."
        );

        // Get New Swaped ETH Amount
        uint256 wethNewBalance = IERC20(_weth).balanceOf(address(this)).sub(wethOldBalance);

        require(wethNewBalance > 0, "Vault: Invalid WETH amount.");

        uint256 LINKTokenReward = wethNewBalance.mul(_allocPointForLINK).div(10000);
        uint256 UNITokenReward = wethNewBalance.mul(_allocPointForUNI).div(10000);
        uint256 wethTokenReward = wethNewBalance.sub(LINKTokenReward).sub(UNITokenReward);

        // Transfer Weth Reward Tokens From Contract To Staker
        require(
            IERC20(_weth).transfer(_msgSender(), wethTokenReward),
            "Vault: Faild to WETH"
        );

        // Swap WETH -> LINK and give LINK token to User as reward
        require(
            swapTokensForTokens(
                address(_weth),
                address(_LINK),
                LINKTokenReward,
                _msgSender()
            ),
            "Vault: Failed to swap LINK."
        );

        // Swap WEED -> UNI and give UNI token to User as reward
        require(
            swapTokensForTokens(
                address(_weth),
                address(_UNI),
                UNITokenReward,
                _msgSender()
            ),
            "Vault: Failed to swap UNI."
        );
    }

    /**
     * @dev internal function to send lottery rewards
     */
    function _sendLotteryAmount() internal returns (bool) {
        if (!_enabledLottery || _lotteryAmount <= 0)
            return false;

        uint256 usdcReserve = 0;
        uint256 ethReserve1 = 0;
        uint256 WEEDReserve = 0;
        uint256 ethReserve2 = 0;
        address token0 = _usdcETHV2Pair.token0();

        if (token0 == address(_weth)){
            (ethReserve1, usdcReserve, ) = _usdcETHV2Pair.getReserves();
        } else {
            (usdcReserve, ethReserve1, ) = _usdcETHV2Pair.getReserves();
        }

        token0 = _WEEDETHV2Pair.token0();

        if (token0 == address(_weth)){
            (ethReserve2, WEEDReserve, ) = _WEEDETHV2Pair.getReserves();
        } else {
            (WEEDReserve, ethReserve2, ) = _WEEDETHV2Pair.getReserves();
        }

        if (ethReserve1 <= 0 || WEEDReserve <= 0)
            return false;

        uint256 WEEDPrice = usdcReserve.mul(1 ether).div(ethReserve1).mul(ethReserve2).div(WEEDReserve);
        uint256 lotteryValue = WEEDPrice.mul(_lotteryAmount).div(1 ether);

        if (lotteryValue > 0 && lotteryValue >= _lotteryLimit) {
            uint256 amount = _lotteryLimit.mul(1 ether).div(WEEDPrice);

            if (amount > _lotteryAmount)
                amount = _lotteryAmount;

            _WEED.transfer(_msgSender(), amount);
            _lotteryAmount = _lotteryAmount.sub(amount);
            _lotteryPaidOut = _lotteryPaidOut.add(amount);

            emit SentLotteryAmount(_msgSender(), amount, true);

            winnerInfo.push(
                WinnerInfo({
                    winner: _msgSender(),
                    amount: amount,
                    timestamp: block.timestamp
                })
            );
        }

        return false;
    }

    function safeWEEDTransfer(address to, uint256 amount) internal returns (bool) {
        uint256 WEEDBal = _WEED.balanceOf(address(this));

        if (amount > WEEDBal) {
            _WEED.transfer(to, WEEDBal);
        } else {
            _WEED.transfer(to, amount);
        }

        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}