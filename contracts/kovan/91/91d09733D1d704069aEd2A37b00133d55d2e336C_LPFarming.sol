/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

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
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface TokenInterface is IERC20 {
    function withdraw(uint wad) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
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

interface IPancakeSwapV2Factory {
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

interface IPancakeSwapV2Pair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
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
}

interface IPancakeSwapV2Router01 {
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

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
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

contract LPFarming is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint128;

    uint128 constant private BASE_MULTIPLIER = uint128(1 * 10 ** 18);
    uint128 constant private MIN_LOCK_DURATION = uint128(4); // 4 weeks
    uint128 constant private MAX_LOCK_DURATION = uint128(104); // 104 weeks
    uint256 constant private TOTAL_REWARD_AMOUNT = 68 * 10**6 * 10**18; // 68M

    mapping(uint128 => uint256) _epochRewardAmount;

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public _epoch1Start;

    // duration of each epoch
    uint256 public _epochDuration;

    struct Stake {
        uint256 amount;
        uint128 startEpochId;
        uint128 endEpochId;
        uint128 lockWeeks;
        uint128 lastClaimEpochId;
    }

    // _stakes[user][]
    mapping(address => Stake[]) private _stakes;

    mapping(uint128 => uint256) private _totalMultipliers;

    // id of last init epoch, for optimization purposes moved from struct to a single id.
    uint128 public lastInitializedEpoch;

    address private _team;

    TokenInterface public _wbnb;
    TokenInterface public _dexf;
    TokenInterface public _busd;
    TokenInterface public _btcb;
    TokenInterface public _eth;

    IPancakeSwapV2Pair public _dexfBNBV2Pair;
    IPancakeSwapV2Router02 private _pancakeswapV2Router;

    event ChangedDexfAddress(address indexed owner, address indexed dexf);
    event ChangedDexfBNBPair(address indexed owner, address indexed pair);

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event ClaimedReward(address indexed owner);
    event Received(address sender, uint amount);
    event ManualEpochInit(address indexed caller, uint128 indexed epochId);

    event SwapAndLiquifyFromBNB(address indexed msgSender, uint256 totAmount, uint256 bnbAmount, uint256 amount);

    constructor() {
        _wbnb = TokenInterface(0xc778417E063141139Fce010982780140Aa0cD5Ab);
        _dexf = TokenInterface(0xbD03a365818C8CFd11F6A9132BcA9B0016792BAb);
        _busd = TokenInterface(0xE5575Eaf9b51A30EC7fCCa4588195f313CF151fe);
        _btcb = TokenInterface(0x495180b00BaBCeaeB8963C6AA3a154DDC514e1B6);
        _eth = TokenInterface(0x29DF3E182b7a84DaA1c0a7b34885807DD3052CE0);

        _pancakeswapV2Router = IPancakeSwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Create a Pancakeswap pair for dexf
        address pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory())
            .getPair(address(_dexf), _pancakeswapV2Router.WETH());
        if (pair != address(0)) {
            _dexfBNBV2Pair = IPancakeSwapV2Pair(pair);
        } else {
            _dexfBNBV2Pair = IPancakeSwapV2Pair(IPancakeSwapV2Factory(_pancakeswapV2Router.factory())
                .createPair(address(_dexf), _pancakeswapV2Router.WETH()));
        }

        _epoch1Start = block.timestamp + 180; // to test after 3 minutes
        _epochDuration = 600; // to test 1 hours

        _team = msg.sender;
    }

    /**
     * @dev Change Dexf token contract address. Call by only owner.
     */
    function changeDexfAddress(address dexf) external onlyOwner {
        _dexf = TokenInterface(dexf);

        emit ChangedDexfAddress(_msgSender(), dexf);
    }

    /**
     * @dev Change LP token contract address. Call by only owner.
     */
    function changeDexfBNBPair(address dexfBNBV2Pair) external onlyOwner {
        _dexfBNBV2Pair = IPancakeSwapV2Pair(dexfBNBV2Pair);

        emit ChangedDexfBNBPair(_msgSender(), dexfBNBV2Pair);
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < _epoch1Start) {
            return 0;
        }

        return uint128((block.timestamp - _epoch1Start) / _epochDuration + 1);
    }

    function getStakes(address account) public view returns (Stake[] memory) {
        return _stakes[account];
    }

    function calcMultiplier(uint256 numOfWeeks) public pure returns (uint256) {
        if (numOfWeeks < 4) {
            return 0;
        } else if (numOfWeeks >= 104) {
            return 300;
        } else {
            uint16[100] memory multipliers = [
                100, 104, 108, 112, 115, 119, 122, 125, 128, 131,
                134, 136, 139, 142, 144, 147, 149, 152, 154, 157,
                159, 161, 164, 166, 168, 170, 173, 175, 177, 179,
                181, 183, 185, 187, 189, 191, 193, 195, 197, 199,
                201, 203, 205, 207, 209, 211, 213, 214, 216, 218,
                220, 222, 223, 225, 227, 229, 230, 232, 234, 236,
                237, 239, 241, 242, 244, 246, 247, 249, 251, 252,
                254, 255, 257, 259, 260, 262, 263, 265, 267, 268,
                270, 271, 273, 274, 276, 277, 279, 280, 282, 283,
                285, 286, 288, 289, 291, 292, 294, 295, 297, 298
            ];

            return uint256(multipliers[numOfWeeks - 4]);
        }
    }

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "Epoch can be init only in order");
        lastInitializedEpoch = epochId;

        if (epochId == 0) {
            _totalMultipliers[epochId] = 0;
        } else {
            _totalMultipliers[epochId] = _totalMultipliers[epochId - 1];
        }
    }

    /*
     * manualEpochInit can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function manualEpochInit(uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");
        _initEpoch(epochId);

        emit ManualEpochInit(msg.sender, epochId);
    }

    function swapBNBForTokens(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(_dexf);

        // make the swap
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbAmount
        }(0, path, address(this), block.timestamp);
    }

    function addLiquidityBNB(uint256 tokenAmount, uint256 bnbAmount) private {
        _dexf.approve(address(_pancakeswapV2Router), tokenAmount);

        // add the liquidity
        _pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(_dexf),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function swapAndLiquifyFromBNB(uint256 amount) private returns (bool) {
        uint256 halfForEth = amount.div(2);
        uint256 otherHalfForDexf = amount.sub(halfForEth);

        uint256 initialBalance = _dexf.balanceOf(address(this));

        // swap BNB for tokens
        swapBNBForTokens(otherHalfForDexf);

        // how much Dexf did we just swap into?
        uint256 newBalance = _dexf.balanceOf(address(this)).sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidityBNB(newBalance, halfForEth);

        emit SwapAndLiquifyFromBNB(_msgSender(), amount, halfForEth, newBalance);

        return true;
    }

    function swapAndLiquifyFromDexf(uint256 amount) private returns (bool) {
        uint256 halfForEth = amount.div(2);
        uint256 otherHalfForDexf = amount.sub(halfForEth);

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(_dexf);
        path[1] = _pancakeswapV2Router.WETH();

        _dexf.approve(
            address(_pancakeswapV2Router),
            halfForEth
        );

        // swap Dexf for BNB
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            halfForEth,
            0, // accept any amount of pair token
            path,
            address(this),
            block.timestamp
        );

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidityBNB(otherHalfForDexf, newBalance);

        return true;
    }

    function swapAndLiquifyFromToken(
        address fromTokenAddress,
        uint256 tokenAmount
    ) private returns (bool) {
        address[] memory path = new address[](2);
        path[0] = fromTokenAddress;
        path[1] = _pancakeswapV2Router.WETH();

        IERC20(fromTokenAddress).approve(
            address(_pancakeswapV2Router),
            tokenAmount
        );

        uint256 initialBNBBalance = address(this).balance;

        // make the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of pair token
            path,
            address(this),
            block.timestamp
        );

        uint256 BNBAmount = address(this).balance.sub(initialBNBBalance);

        return swapAndLiquifyFromBNB(BNBAmount);
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
            address(_pancakeswapV2Router),
            tokenAmount
        );

        // make the swap
        _pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of pair token
            path,
            receivedAddress,
            block.timestamp
        );

        return true;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Stake BNB
     */
    function stake(uint128 lockWeeks) external payable nonReentrant returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");
        require(lockWeeks >= MIN_LOCK_DURATION && lockWeeks <= MAX_LOCK_DURATION, "Farming: Invalid lock duration");

        // Check Initial Balance
        uint256 initialBalance = _dexfBNBV2Pair.balanceOf(address(this));

        require(swapAndLiquifyFromBNB(msg.value), "Farming: Failed to get LP tokens.");

        uint256 newBalance = _dexfBNBV2Pair.balanceOf(address(this)).sub(initialBalance);

        uint128 currentEpochId = getCurrentEpoch();

        Stake[] storage stakes = _stakes[_msgSender()];
        stakes.push(Stake(newBalance, currentEpochId, 0, lockWeeks, currentEpochId > 0 ? currentEpochId - 1 : 0));

        if (lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }
        _totalMultipliers[currentEpochId] = _totalMultipliers[currentEpochId].add(newBalance.mul(calcMultiplier(lockWeeks)));

        emit Staked(_msgSender(), newBalance);

        return true;
    }

    /**
     * @dev Stake Dexf
     */
    function stakeDexf(uint256 tokenAmount, uint128 lockWeeks) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");
        require(lockWeeks >= MIN_LOCK_DURATION && lockWeeks <= MAX_LOCK_DURATION, "Farming: Invalid lock duration");

        // Transfer token to Contract
        _dexf.transferFrom(_msgSender(), address(this), tokenAmount);

        // Check Initial Balance
        uint256 initialBalance = _dexfBNBV2Pair.balanceOf(address(this));

        require(swapAndLiquifyFromDexf(tokenAmount), "Farming: Failed to get LP tokens.");

        uint256 newBalance = _dexfBNBV2Pair.balanceOf(address(this)).sub(initialBalance);

        uint128 currentEpochId = getCurrentEpoch();

        Stake[] storage stakes = _stakes[_msgSender()];
        stakes.push(Stake(newBalance, currentEpochId, 0, lockWeeks, currentEpochId > 0 ? currentEpochId - 1 : 0));

        if (lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }
        _totalMultipliers[currentEpochId] = _totalMultipliers[currentEpochId].add(newBalance.mul(calcMultiplier(lockWeeks)));

        emit Staked(_msgSender(), newBalance);

        return true;
    }

    /**
     * @dev Stake ERC20 Token
     */
    function stakeToken(
        address fromTokenAddress,
        uint256 tokenAmount,
        uint128 lockWeeks
    ) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");
        require(lockWeeks >= MIN_LOCK_DURATION && lockWeeks <= MAX_LOCK_DURATION, "Farming: Invalid lock duration");

        // Transfer token to Contract
        IERC20(fromTokenAddress).transferFrom(_msgSender(), address(this), tokenAmount);

        // Check Initial Balance
        uint256 initialBalance = _dexfBNBV2Pair.balanceOf(address(this));

        require(swapAndLiquifyFromToken(fromTokenAddress, tokenAmount), "Farming: Failed to get LP tokens.");

        uint256 newBalance = _dexfBNBV2Pair.balanceOf(address(this)).sub(initialBalance);

        uint128 currentEpochId = getCurrentEpoch();

        Stake[] storage stakes = _stakes[_msgSender()];
        stakes.push(Stake(newBalance, currentEpochId, 0, lockWeeks, currentEpochId > 0 ? currentEpochId - 1 : 0));

        if (lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }
        _totalMultipliers[currentEpochId] = _totalMultipliers[currentEpochId].add(newBalance.mul(calcMultiplier(lockWeeks)));

        emit Staked(_msgSender(), newBalance);

        return true;
    }

    /**
     * @dev Stake LP Token
     */
    function stakeLPToken(uint256 amount, uint128 lockWeeks) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");
        require(lockWeeks >= MIN_LOCK_DURATION && lockWeeks <= MAX_LOCK_DURATION, "Farming: Invalid lock duration");

        // Transfer token to Contract
        _dexfBNBV2Pair.transferFrom(_msgSender(), address(this), amount);

        uint128 currentEpochId = getCurrentEpoch();

        Stake[] storage stakes = _stakes[_msgSender()];
        stakes.push(Stake(amount, currentEpochId, 0, lockWeeks, currentEpochId > 0 ? currentEpochId - 1 : 0));

        if (lastInitializedEpoch < currentEpochId) {
            _initEpoch(currentEpochId);
        }
        _totalMultipliers[currentEpochId] = _totalMultipliers[currentEpochId].add(amount.mul(calcMultiplier(lockWeeks)));

        emit Staked(_msgSender(), amount);

        return true;
    }

    /**
     * @dev Unstake staked Dexf-BNB LP tokens
     */
    function unstake(uint128 index) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");

        Stake[] storage stakes = _stakes[_msgSender()];

        require(stakes.length > index && index >= 0, "Farming: Invalid index.");

        uint128 currentEpochId = getCurrentEpoch();

        require(stakes[index].endEpochId == 0, "Farming: Already unstaked");
        require(currentEpochId > 1 && currentEpochId > stakes[index].startEpochId, "Farming: Invalid unstake.");
        require(
            (currentEpochId - stakes[index].startEpochId) * _epochDuration > 600,
            "Farming: Lock is not finished."
        );

        // Transfer token to user
        _dexfBNBV2Pair.transfer(_msgSender(), stakes[index].amount);

        stakes[index].endEpochId = currentEpochId - 1;
        _totalMultipliers[currentEpochId] = _totalMultipliers[currentEpochId].sub(stakes[index].amount.mul(calcMultiplier(stakes[index].lockWeeks)));

        emit Unstaked(_msgSender(), stakes[index].amount);

        return true;
    }

    // function claim() public returns (bool) {
    //     emit ClaimedReward(_msgSender());

    //     return true;
    // }

    function getEpochRewardAmount(uint128 epochId) private returns (uint256) {
        if (epochId == 0) {
            return 0;
        }

        if (_epochRewardAmount[epochId] > 0) {
            return _epochRewardAmount[epochId];
        }

        uint256 total = TOTAL_REWARD_AMOUNT;
        for (uint128 i; i < epochId - 1; i++) {
            total = total.mul(9995).div(10000);
        }
        _epochRewardAmount[epochId] = total.mul(5).div(10000);
        return _epochRewardAmount[epochId];
    }

    function claimForStake(uint128 index) public returns (bool) {
        uint128 currentEpochId = getCurrentEpoch();
        require(currentEpochId > 1, "Farming: Invalid claim day");

        Stake[] storage stakes = _stakes[_msgSender()];

        require(stakes.length > index && index >= 0, "Farming: Invalid index.");

        uint256 total;
        uint128 lastEpochId = stakes[index].endEpochId > 0 ? stakes[index].endEpochId : currentEpochId - 1;
        for (uint128 i = stakes[index].lastClaimEpochId + 1; i <= lastEpochId; i++) {
            if (_totalMultipliers[i] == 0) {
                continue;
            }
            uint256 epochRewardAmount = getEpochRewardAmount(i);
            total = total.add(
                epochRewardAmount.mul(
                    stakes[index].amount.mul(calcMultiplier(stakes[index].lockWeeks))
                ).div(
                    _totalMultipliers[i]
                )
            );
        }

        if (total > 0) {
            safeDexfTransfer(_msgSender(), total);
            stakes[index].lastClaimEpochId = lastEpochId;

            emit ClaimedReward(_msgSender());
        }

        return true;
    }

    function removeOddTokens() external returns (bool) {
        require(_msgSender() == _team, "Invalid team address");

        uint256 wbnbOdd = _wbnb.balanceOf(address(this));
        uint256 dexfOdd = _dexf.balanceOf(address(this));
        uint256 busdOdd = _busd.balanceOf(address(this));
        uint256 btcbOdd = _btcb.balanceOf(address(this));
        uint256 wethOdd = _eth.balanceOf(address(this));

        if (wbnbOdd > 0) {
            _wbnb.withdraw(wbnbOdd);
        }

        if (dexfOdd > 0) {
            _dexf.transfer(_msgSender(), dexfOdd);
        }

        if (busdOdd > 0) {
            _busd.transfer(_msgSender(), busdOdd);
        }

        if (btcbOdd > 0) {
            _btcb.transfer(_msgSender(), btcbOdd);
        }

        if (wethOdd > 0) {
            _eth.withdraw(wethOdd);
        }

        uint256 bnbOdd = address(this).balance;
        if (bnbOdd > 0) {
            msg.sender.transfer(bnbOdd);
        }

        return true;
    }

    function safeDexfTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 bal = _dexf.balanceOf(address(this));

        if (amount > bal) {
            _dexf.transfer(to, bal);

            return bal;
        }

        _dexf.transfer(to, amount);

        return amount;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}