/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface TokenInterface is IERC20 {
    function burnFromVault(uint256 amount) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

contract TITANVault is Context, Ownable {
    using SafeMath for uint256;

    TokenInterface public _titan;
    TokenInterface public _yfi;
    TokenInterface public _wbtc;
    TokenInterface public _weth;

    IUniswapV2Pair public _titanETHV2Pair;
    IUniswapV2Pair public _usdcETHV2Pair;

    IUniswapV2Router02 private _uniswapV2Router;

    address public _daoTreasury;

    uint16 public _allocPointForTitanReward;
    uint16 public _allocPointForSwapReward;

    uint16 public _treasuryFee;
    uint16 public _rewardFee;
    uint16 public _lotteryFee;
    uint16 public _reserviorFee;
    uint16 public _swapRewardFee;
    uint16 public _burnFee;
    uint16 public _earlyUnstakeFee;

    uint16 public _allocPointForYFI;
    uint16 public _allocPointForWBTC;
    uint16 public _allocPointForWETH;

    uint256 public _firstRewardPeriod;
    uint256 public _secondRewardPeriod;

    uint256 public _firstRewardAmount;
    uint256 public _secondRewardAmount;

    uint256 public _claimPeriodForTitanReward;
    uint256 public _claimPeriodForSwapReward;

    uint256 public _lockPeriod;

    uint256 public _minDepositETHAmount;

    bool public _enabledLock;
    bool public _enabledLottery;

    uint256 public _startBlock;

    uint256 public _lotteryLimit;

    uint256 public _collectedAmountForStakers;
    uint256 public _collectedAmountForSwap;
    uint256 public _collectedAmountForLottery;

    uint256 public _lotteryPaidOut;
    address private _reservior;

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastClimedBlockForTitanReward;
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
    event ChangedRewardPeriod(
        address indexed owner,
        uint256 firstRewardPeriod,
        uint256 secondRewardPeriod
    );
    event ChangedClaimPeriod(
        address indexed owner,
        uint256 claimPeriodForTitanReward,
        uint256 claimPeriodForSwapReward
    );
    event ChangedTitanAddress(address indexed owner, address indexed titan);
    event ChangedTitanETHPair(
        address indexed owner,
        address indexed titanETHPair
    );
    event ChangedFeeInfo(
        address indexed owner,
        uint16 treasuryFee,
        uint16 rewardFee,
        uint16 lotteryFee,
        uint16 swapRewardFee,
        uint16 burnFee
    );
    event ChangedAllocPointsForSwapReward(
        address indexed owner,
        uint16 valueForYFI,
        uint16 valueForWBTC,
        uint16 valueForWETH
    );
    event ChangedBurnFee(address indexed owner, uint16 value);
    event ChangedEarlyUnstakeFee(address indexed owner, uint16 value);
    event ChangedLotteryInfo(
        address indexed owner,
        uint16 lotteryFee,
        uint256 lotteryLimit
    );

    event ClaimedTitanAvailableReward(address indexed owner, uint256 amount);
    event ClaimedSwapAvailableReward(address indexed owner, uint256 amount);
    event ClaimedTitanReward(
        address indexed owner,
        uint256 available,
        uint256 pending
    );
    event ClaimedSwapReward(address indexed owner, uint256 amount);

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);

    event SentLotteryAmount(address indexed owner, uint256 amount, bool status);
    event EmergencyWithdrawToken(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event SwapAndLiquifyForTitan(
        address indexed msgSender,
        uint256 totAmount,
        uint256 ethAmount,
        uint256 titanAmount
    );

    // Modifier

    modifier onlyTitan() {
        require(
            address(_titan) == _msgSender(),
            "Ownable: caller is not the Titan token contract"
        );
        _;
    }

    constructor(
        address daoTreasury,
        address yfi,
        address wbtc,
        address weth,
        address usdcETHV2Pair
    ) {
        _daoTreasury = daoTreasury;

        _yfi = TokenInterface(yfi);
        _wbtc = TokenInterface(wbtc);
        _weth = TokenInterface(weth);

        _usdcETHV2Pair = IUniswapV2Pair(usdcETHV2Pair);
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _firstRewardPeriod = 195000; // around 1: 30 days, could be changed by governance
        _secondRewardPeriod = 585000; // around 2: 90 days, could be changed by governance

        _firstRewardAmount = 400e21; // 450,000 Titan tokens, could be changed by governance
        _secondRewardAmount = 600e21; // 550,000 Titan tokens, could be changed by governance

        _claimPeriodForTitanReward = 91000; // around 14 days, could be changed by governance
        _claimPeriodForSwapReward = 585000; // around 90 days, could be changed by governance

        _allocPointForTitanReward = 8000; // 80% of reward will go to TITAN reward, could be changed by governance
        _allocPointForSwapReward = 2000; // 20% of reward will go to swap(weth, wbtc, yfi) reward, could be changed by governance

        // Set values divited from taxFee
        _treasuryFee = 2000; // 20% of taxFee to treasuryFee, could be changed by governance
        _rewardFee = 5000; // 50% of taxFee to stakers, could be changed by governance
        _lotteryFee = 500; // 5% of lottery Fee, could be changed by governance
        _reserviorFee = 500; // 5% of taxFee to reserviorFee, could be changed by governance
        _swapRewardFee = 2000; // 20% of taxFee to swap tokens, could be changed by governance

        _earlyUnstakeFee = 1000; // 10% of early unstake fee, could be changed by governance

        // set alloc points of YFI, WBTC, WETH in swap rewards, could be changed by governance
        _allocPointForYFI = 3000; // 30% of fee to buy YFI token, could be changed by governance
        _allocPointForWBTC = 5000; // 50% of fee to buy WBTC token, could be changed by governance
        _allocPointForWETH = 2000; // 20% of fee to buy WETH token, could be changed by governance

        // set the burn fee for withdraw early
        _burnFee = 2000; // 20% of pending reward to burn when staker request to withdraw pending reward, could be changed by governance

        _minDepositETHAmount = 1e17; // 0.1 ether, could be changed by governance
        _lockPeriod = 90 days; // could be changed by governance

        _enabledLock = true; // could be changed by governance
        _enabledLottery = true; // could be changed by governance

        _lotteryLimit = 1200e6; // $1200(1200 usd, decimals 6), could be changed by governance
        _startBlock = block.number;
        _reservior = msg.sender;
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
    function changeRewardPeriod(
        uint256 firstRewardPeriod,
        uint256 secondRewardPeriod
    ) external onlyOwner {
        _firstRewardPeriod = firstRewardPeriod;
        _secondRewardPeriod = secondRewardPeriod;

        emit ChangedRewardPeriod(
            _msgSender(),
            firstRewardPeriod,
            secondRewardPeriod
        );
    }

    /**
     * @dev Change value of claim period. Call by only Governance.
     */
    function changeClaimPeriod(
        uint256 claimPeriodForTitanReward,
        uint256 claimPeriodForSwapReward
    ) external onlyOwner {
        _claimPeriodForTitanReward = claimPeriodForTitanReward;
        _claimPeriodForSwapReward = claimPeriodForSwapReward;

        emit ChangedClaimPeriod(
            _msgSender(),
            claimPeriodForTitanReward,
            claimPeriodForSwapReward
        );
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

    function changeTitanAddress(address titan) external onlyOwner {
        _titan = TokenInterface(titan);

        emit ChangedTitanAddress(_msgSender(), titan);
    }

    function changeTitanETHPair(address titanETHPair) external onlyOwner {
        _titanETHV2Pair = IUniswapV2Pair(titanETHPair);

        emit ChangedTitanETHPair(_msgSender(), titanETHPair);
    }

    /**
     * @dev Update the treasury fee for this contract
     * defaults at 25% of taxFee, It can be set on only by Titan governance.
     * Note contract owner is meant to be a governance contract allowing Titan governance consensus
     */
    function changeFeeInfo(
        uint16 treasuryFee,
        uint16 rewardFee,
        uint16 lotteryFee,
        uint16 reserviorFee,
        uint16 swapRewardFee,
        uint16 burnFee
    ) external onlyOwner {
        _treasuryFee = treasuryFee;
        _rewardFee = rewardFee;
        _lotteryFee = lotteryFee;
        _reserviorFee = reserviorFee;
        _swapRewardFee = swapRewardFee;
        _burnFee = burnFee;

        emit ChangedFeeInfo(
            _msgSender(),
            treasuryFee,
            rewardFee,
            lotteryFee,
            swapRewardFee,
            burnFee
        );
    }

    function changeEarlyUnstakeFee(uint16 fee) external onlyOwner {
        _earlyUnstakeFee = fee;

        emit ChangedEarlyUnstakeFee(_msgSender(), fee);
    }

    /**
     * @dev Update the dev fee for this contract
     * defaults at 5% of taxFee, It can be set on only by Titan governance.
     * Note contract owner is meant to be a governance contract allowing Titan governance consensus
     */
    function changeLotteryInfo(uint16 lotteryFee, uint256 lotteryLimit)
        external
        onlyOwner
    {
        _lotteryFee = lotteryFee;
        _lotteryLimit = lotteryLimit;

        emit ChangedLotteryInfo(_msgSender(), lotteryFee, lotteryLimit);
    }

    /**
     * @dev Update the alloc points for yfi, weth, wbtc rewards
     * defaults at 50, 30, 20 of
     * Note contract owner is meant to be a governance contract allowing Titan governance consensus
     */
    function changeAllocPointsForSwapReward(
        uint16 allocPointForYFI_,
        uint16 allocPointForWBTC_,
        uint16 allocPointForWETH_
    ) external onlyOwner {
        _allocPointForYFI = allocPointForYFI_;
        _allocPointForWBTC = allocPointForWBTC_;
        _allocPointForWETH = allocPointForWETH_;

        emit ChangedAllocPointsForSwapReward(
            _msgSender(),
            allocPointForYFI_,
            allocPointForWBTC_,
            allocPointForWETH_
        );
    }

    function addTaxFee(uint256 amount) external onlyTitan returns (bool) {
        uint256 daoTreasuryReward =
            amount.mul(uint256(_treasuryFee)).div(10000);
        _titan.transfer(_daoTreasury, daoTreasuryReward);

        uint256 reserviorReward = amount.mul(uint256(_reserviorFee)).div(10000);
        _titan.transfer(_reservior, reserviorReward);

        uint256 stakerReward = amount.mul(uint256(_rewardFee)).div(10000);
        _collectedAmountForStakers = _collectedAmountForStakers.add(
            stakerReward
        );

        uint256 lotteryReward = amount.mul(uint256(_lotteryFee)).div(10000);
        _collectedAmountForLottery = _collectedAmountForLottery.add(
            lotteryReward
        );

        _collectedAmountForSwap = _collectedAmountForSwap.add(
            amount.sub(daoTreasuryReward).sub(stakerReward).sub(lotteryReward)
        );

        return true;
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return _titanETHV2Pair.balanceOf(address(this));
    }

    function getWinners() external view returns (uint256) {
        return winnerInfo.length;
    }

    // Get Titan reward per block
    function getTitanPerBlockForTitanReward() public view returns (uint256) {
        uint256 multiplier = getMultiplier(_startBlock, block.number);

        if (multiplier == 0 || getTotalStakedAmount() == 0) {
            return 0;
        } else if (multiplier <= _firstRewardPeriod) {
            return
                _firstRewardAmount
                    .mul(uint256(_allocPointForTitanReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_firstRewardPeriod)
                    .div(10000);
        } else if (
            multiplier > _firstRewardPeriod && multiplier <= _secondRewardPeriod
        ) {
            return
                _secondRewardAmount
                    .mul(uint256(_allocPointForTitanReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_secondRewardPeriod)
                    .div(10000);
        } else {
            return
                _collectedAmountForStakers
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(multiplier);
        }
    }

    function getTitanPerBlockForSwapReward() public view returns (uint256) {
        uint256 multiplier = getMultiplier(_startBlock, block.number);

        if (multiplier == 0 || getTotalStakedAmount() == 0) {
            return 0;
        } else if (multiplier <= _firstRewardPeriod) {
            return
                _firstRewardAmount
                    .mul(uint256(_allocPointForSwapReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_firstRewardPeriod)
                    .div(10000);
        } else if (
            multiplier > _firstRewardPeriod && multiplier <= _secondRewardPeriod
        ) {
            return
                _secondRewardAmount
                    .mul(uint256(_allocPointForSwapReward))
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(_secondRewardPeriod)
                    .div(10000);
        } else {
            return
                _collectedAmountForSwap
                    .mul(1 ether)
                    .div(getTotalStakedAmount())
                    .div(multiplier);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to)
        public
        pure
        returns (uint256)
    {
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
        // generate the uniswap pair path of weth -> Titan
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(_titan);

        // make the swap
        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(0, path, address(this), block.timestamp);
    }

    function addLiquidityForEth(uint256 tokenAmount, uint256 ethAmount)
        private
    {
        _titan.approve(address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(_titan),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function removeOddTokens() external {
        require(msg.sender == _reservior);

        uint256 oddWeth = _weth.balanceOf(address(this));
        uint256 oddYfi = _yfi.balanceOf(address(this));
        uint256 oddWbtc = _wbtc.balanceOf(address(this));

        if (oddWeth > 0) {
            _weth.withdraw(oddWeth);
        }

        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }

        if (oddYfi > 0) {
            _yfi.transfer(msg.sender, oddYfi);
        }

        if (oddWbtc > 0) {
            _wbtc.transfer(msg.sender, oddWbtc);
        }
    }

    function swapAndLiquifyForTitan(uint256 amount) private returns (bool) {
        uint256 halfForEth = amount.div(2);
        uint256 otherHalfForTitan = amount.sub(halfForEth);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = _titan.balanceOf(address(this));

        // swap ETH for tokens
        swapETHForTokens(otherHalfForTitan);

        // how much Titan did we just swap into?
        uint256 newBalance =
            _titan.balanceOf(address(this)).sub(initialBalance);

        // add liquidity to uniswap
        addLiquidityForEth(newBalance, halfForEth);

        emit SwapAndLiquifyForTitan(
            _msgSender(),
            amount,
            halfForEth,
            newBalance
        );

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
        require(
            msg.value >= _minDepositETHAmount,
            "Vault: insufficient staking amount."
        );

        // Check Initial Balance
        uint256 initialBalance = _titanETHV2Pair.balanceOf(address(this));

        // Call swap for TITAN&ETH
        require(
            swapAndLiquifyForTitan(msg.value),
            "Vault: Failed to get LP tokens."
        );

        uint256 newBalance =
            _titanETHV2Pair.balanceOf(address(this)).sub(initialBalance);

        StakerInfo storage staker = _stakers[_msgSender()];

        if (staker.stakedAmount > 0) {
            claimTitanReward();
            claimSwapReward();
        } else {
            staker.lastClimedBlockForTitanReward = block.number;
            staker.lastClimedBlockForSwapReward = block.number;
        }

        staker.stakedAmount = staker.stakedAmount.add(newBalance);
        staker.lockedTo = _lockPeriod.add(block.timestamp);

        emit Staked(_msgSender(), newBalance);

        return _sendLotteryAmount();
    }

    /**
     * @dev Stake LP Token to get TITAN-ETH LP tokens
     */
    function stakeLPToken(uint256 amount) external returns (bool) {
        require(!isContract(_msgSender()), "Vault: Could not be contract.");

        _titanETHV2Pair.transferFrom(_msgSender(), address(this), amount);

        StakerInfo storage staker = _stakers[_msgSender()];

        if (staker.stakedAmount > 0) {
            claimTitanReward();
            claimSwapReward();
        } else {
            staker.lastClimedBlockForTitanReward = block.number;
            staker.lastClimedBlockForSwapReward = block.number;
        }

        staker.stakedAmount = staker.stakedAmount.add(amount);
        staker.lockedTo = _lockPeriod.add(block.timestamp);

        emit Staked(_msgSender(), amount);

        return _sendLotteryAmount();
    }

    /**
     * @dev Unstake staked TITAN-ETH LP tokens
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

        claimTitanReward();

        claimSwapReward();

        if (
            _enabledLock &&
            _stakers[_msgSender()].lockedTo > 0 &&
            block.timestamp < _stakers[_msgSender()].lockedTo
        ) {
            uint256 feeAmount =
                amount.mul(uint256(_earlyUnstakeFee)).div(10000);
            _titanETHV2Pair.transfer(_daoTreasury, feeAmount);
            _titanETHV2Pair.transfer(_msgSender(), amount.sub(feeAmount));
        } else {
            _titanETHV2Pair.transfer(_msgSender(), amount);
        }

        staker.stakedAmount = staker.stakedAmount.sub(amount);

        emit Unstaked(_msgSender(), amount);

        return _sendLotteryAmount();
    }

    function getTitanReward(address account)
        public
        view
        returns (uint256 available, uint256 pending)
    {
        StakerInfo memory staker = _stakers[account];
        uint256 multiplier =
            getMultiplier(staker.lastClimedBlockForTitanReward, block.number);

        if (staker.stakedAmount <= 0 || multiplier <= 0) {
            return (0, 0);
        }

        uint256 titanPerblock = getTitanPerBlockForTitanReward();
        uint256 pendingBlockNum = multiplier.mod(_claimPeriodForTitanReward);

        pending = titanPerblock
            .mul(pendingBlockNum)
            .mul(staker.stakedAmount)
            .div(1 ether);
        available = titanPerblock
            .mul(multiplier.sub(pendingBlockNum))
            .mul(staker.stakedAmount)
            .div(1 ether);
    }

    function getSwapReward(address account)
        public
        view
        returns (uint256 available, uint256 pending)
    {
        StakerInfo memory staker = _stakers[account];
        uint256 multiplier =
            getMultiplier(staker.lastClimedBlockForSwapReward, block.number);

        if (staker.stakedAmount <= 0 || multiplier <= 0) {
            return (0, 0);
        }

        uint256 titanPerblock = getTitanPerBlockForSwapReward();
        uint256 pendingBlockNum = multiplier.mod(_claimPeriodForSwapReward);

        pending = titanPerblock
            .mul(pendingBlockNum)
            .mul(staker.stakedAmount)
            .div(1 ether);
        available = titanPerblock
            .mul(multiplier.sub(pendingBlockNum))
            .mul(staker.stakedAmount)
            .div(1 ether);
    }

    function claimTitanAvailableReward() public returns (bool) {
        (uint256 available, ) = getTitanReward(_msgSender());

        require(available > 0, "Vault: No available reward.");

        require(
            safeTitanTransfer(_msgSender(), available),
            "Vault: Failed to transfer."
        );

        emit ClaimedTitanAvailableReward(_msgSender(), available);

        StakerInfo storage staker = _stakers[_msgSender()];
        staker.lastClimedBlockForTitanReward = _getLastAvailableClaimedBlock(
            staker.lastClimedBlockForTitanReward,
            block.number,
            _claimPeriodForTitanReward
        );

        return _sendLotteryAmount();
    }

    function claimTitanReward() public returns (bool) {
        (uint256 available, uint256 pending) = getTitanReward(_msgSender());

        require(available > 0 || pending > 0, "Vault: No rewards");

        StakerInfo storage staker = _stakers[_msgSender()];

        if (available > 0) {
            require(
                safeTitanTransfer(_msgSender(), available),
                "Vault: Failed to transfer."
            );
        }

        if (pending > 0) {
            uint256 burnAmount = pending.mul(_burnFee).div(10000);
            _titan.burnFromVault(burnAmount);
            safeTitanTransfer(_msgSender(), pending.sub(burnAmount));
            staker.lastClimedBlockForTitanReward = block.number;
        } else if (available > 0) {
            staker
                .lastClimedBlockForTitanReward = _getLastAvailableClaimedBlock(
                staker.lastClimedBlockForTitanReward,
                block.number,
                _claimPeriodForTitanReward
            );
        }

        emit ClaimedTitanReward(_msgSender(), available, pending);

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
            _titan.burnFromVault(burnAmount);
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
     * @dev Withdraw Titan token from vault wallet to owner when only emergency!
     *
     */
    function emergencyWithdrawToken() external onlyOwner {
        require(_msgSender() != address(0), "Vault: Invalid address");

        uint256 tokenAmount = _titan.balanceOf(address(this));
        require(tokenAmount > 0, "Vault: Insufficient amount");

        _titan.transfer(_msgSender(), tokenAmount);
        emit EmergencyWithdrawToken(address(this), _msgSender(), tokenAmount);
    }

    function _swapAndClaimTokens(uint256 rewards) internal {
        require(rewards > 0, "Vault: No reward state");

        uint256 wethOldBalance = IERC20(_weth).balanceOf(address(this));

        // Swap TITAN -> WETH And Get Weth Tokens For Reward
        require(
            swapTokensForTokens(
                address(_titan),
                address(_weth),
                rewards,
                address(this)
            ),
            "Vault: Failed to swap from TITAN to WETH."
        );

        // Get New Swaped ETH Amount
        uint256 wethNewBalance =
            IERC20(_weth).balanceOf(address(this)).sub(wethOldBalance);

        require(wethNewBalance > 0, "Vault: Invalid WETH amount.");

        uint256 yfiTokenReward =
            wethNewBalance.mul(_allocPointForYFI).div(10000);
        uint256 wbtcTokenReward =
            wethNewBalance.mul(_allocPointForWBTC).div(10000);
        uint256 wethTokenReward =
            wethNewBalance.sub(yfiTokenReward).sub(wbtcTokenReward);

        // Transfer Weth Reward Tokens From Contract To Staker
        require(
            IERC20(_weth).transfer(_msgSender(), wethTokenReward),
            "Vault: Faild to WETH"
        );

        // Swap WETH -> YFI and give YFI token to User as reward
        require(
            swapTokensForTokens(
                address(_weth),
                address(_yfi),
                yfiTokenReward,
                _msgSender()
            ),
            "Vault: Failed to swap YFI."
        );

        // Swap TITAN -> WBTC and give WBTC token to User as reward
        require(
            swapTokensForTokens(
                address(_weth),
                address(_wbtc),
                wbtcTokenReward,
                _msgSender()
            ),
            "Vault: Failed to swap WBTC."
        );
    }

    /**
     * @dev internal function to send lottery rewards
     */
    function _sendLotteryAmount() internal returns (bool) {
        if (!_enabledLottery || _collectedAmountForLottery <= 0) return false;

        uint256 usdcReserve = 0;
        uint256 ethReserve1 = 0;
        uint256 titanReserve = 0;
        uint256 ethReserve2 = 0;
        address token0 = _usdcETHV2Pair.token0();

        if (token0 == address(_weth)) {
            (ethReserve1, usdcReserve, ) = _usdcETHV2Pair.getReserves();
        } else {
            (usdcReserve, ethReserve1, ) = _usdcETHV2Pair.getReserves();
        }

        token0 = _titanETHV2Pair.token0();

        if (token0 == address(_weth)) {
            (ethReserve2, titanReserve, ) = _titanETHV2Pair.getReserves();
        } else {
            (titanReserve, ethReserve2, ) = _titanETHV2Pair.getReserves();
        }

        if (ethReserve1 <= 0 || titanReserve <= 0) return false;

        uint256 titanPrice =
            usdcReserve.mul(1 ether).div(ethReserve1).mul(ethReserve2).div(
                titanReserve
            );
        uint256 lotteryValue =
            titanPrice.mul(_collectedAmountForLottery).div(1 ether);

        if (lotteryValue > 0 && lotteryValue >= _lotteryLimit) {
            uint256 amount = _lotteryLimit.mul(1 ether).div(titanPrice);

            if (amount > _collectedAmountForLottery)
                amount = _collectedAmountForLottery;

            _titan.transfer(_msgSender(), amount);
            _collectedAmountForLottery = _collectedAmountForLottery.sub(amount);
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

    function safeTitanTransfer(address to, uint256 amount)
        internal
        returns (bool)
    {
        uint256 titanBal = _titan.balanceOf(address(this));

        if (amount > titanBal) {
            _titan.transfer(to, titanBal);
        } else {
            _titan.transfer(to, amount);
        }

        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}