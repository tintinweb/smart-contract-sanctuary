// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./../base/pool/AutoCollectablePool.sol";

contract FuturaMainPool is AutoCollectablePool {
    uint256 public processingFeesThreshold = 500000000000000000 wei;
    address public processingFeesDestination;

    constructor(IFutura futura, address processingFeeDestination, address routerAddress, IBEP20 _outToken) AutoCollectablePool(futura,routerAddress, _outToken) { 
        setProcessingFeesDestination(processingFeeDestination);
    }

    function doProcessFunds(uint256 gas) internal override {
        super.doProcessFunds(gas);

        if (processingFees >= processingFeesThreshold) {
            swapBNBForTokens(swapTokensForBNB(processingFees, outToken, address(this)), futura, processingFeesDestination);
            delete processingFees;
        }
    }

    function swapBNBForTokens(uint256 bnbAmount, IBEP20 token, address to) internal returns(uint256) { 
        // Generate pair for WBNB -> Token
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(token);

        // Swap and send the tokens to the 'to' address
        uint256 previousBalance = token.balanceOf(to);
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(0, path, to, block.timestamp + 360);
        return token.balanceOf(to) - previousBalance;
    }

    function swapTokensForBNB(uint256 tokenAmount, IBEP20 token, address to) internal returns(uint256) {
        uint256 initialBalance = to.balance;
        
        // Generate pair for Token -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = _pancakeswapV2Router.WETH();

        // Swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp + 360);
        
        // Return the amount received
        return to.balance - initialBalance;
    }
    
    function setProcessingFeesThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 0, "FuturaEthPool: Invalid value");
        processingFeesThreshold = threshold;
    }

    function setProcessingFeesDestination(address destination) public onlyOwner {
        require(destination != address(0), "FuturaEthPool: Invalid address");
        processingFeesDestination = destination;
    }

    function approvePancake() external onlyOwner {
        outToken.approve(address(_pancakeswapV2Router), ~uint256(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./StakeFuturaPool.sol";

abstract contract AutoCollectablePool is StakeFuturaPool {

    address[] public autoCollectAddresses;
    mapping(address => uint256) public autoCollectIndices;
    uint256 public autoCollectIndex;

    uint256 public processingFeeMagnitude = 10;
    uint256 public processingFees;
    uint256 public minEarningsToAutoCollect = 100000 wei;
    bool public isAutoCollectAvailable = true;

    event AutoCollectStatusChanged(address indexed user, bool isEnabled);
    event AutoCollected(address indexed user, uint256 amount);

    constructor(IFutura futura, address routerAddress, IBEP20 _outToken) StakeFuturaPool(futura, routerAddress, _outToken) {

    }

    function processAutoCollect(uint256 gas) external onlyAdmins {
        doProcessAutoCollect(gas);
    }

    function autoCollect(address userAddress) external onlyAdmins {
        doAutoCollect(userAddress);
    }

    function doProcessAutoCollect(uint256 gas) internal {
        uint256 gasUsed ;
        uint256 gasLeft = gasleft();
        uint256 iteration;
        uint256 userIndex = autoCollectIndex; 

        while(gasUsed < gas && iteration < autoCollectAddresses.length) {
            if (userIndex >= autoCollectAddresses.length) {
                userIndex = 0;
            }

            doAutoCollect(autoCollectAddresses[userIndex]);
           
           unchecked {
                uint256 newGasLeft = gasleft();

                if (gasLeft > newGasLeft) {
                    gasUsed += gasLeft - newGasLeft;
                    gasLeft = newGasLeft;
                }

                iteration++;
                userIndex++;
            }
        }

        autoCollectIndex = userIndex;
    }

    function doAutoCollect(address userAddress) internal virtual { 
        updateStakingOf(userAddress);

        UserInfo storage user = userInfo[userAddress];

        uint256 reward = user.unclaimedDividends / DIVIDEND_POINTS_ACCURACY;
        if (reward < minEarningsToAutoCollect) {
            return;
        }

        // Claim
        user.unclaimedDividends -= reward * DIVIDEND_POINTS_ACCURACY;
        amountOut -= reward;

        // Apply fee
        uint256 fee =  reward * processingFeeMagnitude / 1000;
        reward -= fee;
        processingFees += fee;

        
        user.totalValueClaimed += reward;
        
        emit AutoCollected(userAddress, reward);

        sendReward(userAddress, reward);
    }

    function setAutoCollectEnabled(bool isEnabled) external notUnauthorizedContract {
        doSetAutoCollectEnabled(msg.sender, isEnabled);
    }

    function setAutoCollectEnabled(address userAddress, bool isEnabled) external onlyAdmins {
        doSetAutoCollectEnabled(userAddress, isEnabled);
    }

    function doSetAutoCollectEnabled(address userAddress, bool isEnabled) internal {
        require(isEnabled != isAutoCollectEnabled(userAddress), "AutoCollectablePool: Value unchanged");

        if (isEnabled) {
            autoCollectIndices[userAddress] = autoCollectAddresses.length;
            autoCollectAddresses.push(userAddress);
        } else {
            uint256 index = autoCollectIndices[userAddress];
            address lastAddress = autoCollectAddresses[autoCollectAddresses.length - 1];

            autoCollectIndices[lastAddress] = index;
            autoCollectAddresses[index] = lastAddress; 
            autoCollectAddresses.pop();
            
            delete autoCollectIndices[userAddress];
        }

        emit AutoCollectStatusChanged(userAddress, isEnabled);
    }

    function isAutoCollectEnabled(address userAddress) public view returns(bool) {
        uint256 index = autoCollectIndices[userAddress];
        return index < autoCollectAddresses.length  && autoCollectAddresses[index] == userAddress;
    }

    function setMinEarningsToAutoCollect(uint256 value) external onlyOwner {
        require(value > 0, "AutoCollectablePool: Invalid value");
        minEarningsToAutoCollect = value;
    }

    function setProcessingFeeMagnitude(uint256 magnitude) external onlyOwner {
        require(magnitude <= 1000, "AutoCompoundPool: Invalid value");
        processingFeeMagnitude = magnitude;
    }

    function setIsAutoCollectAvailable(bool isAvailable) external onlyOwner {
        isAutoCollectAvailable = isAvailable;
    }

    function autoCollectAddressesLength() external view returns(uint256) {
        return autoCollectAddresses.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./FuturaLinkPool.sol";

contract StakeFuturaPool is FuturaLinkPool {
    uint256 burnTokensThreshold;

    constructor(IFutura futura, address _routerAddress, IBEP20 _outToken) FuturaLinkPool(futura, _routerAddress, futura, _outToken) {
        futuralinkPointsPerToken = 10;
        isStakingEnabled = true;

        burnTokensThreshold = 100000 * 10**futura.decimals();
    }

   function doProcessFunds(uint256 gas) override virtual internal {
        if (futura.isRewardReady(address(this))) {
            futura.claimReward(address(this));
        }

       super.doProcessFunds(gas);

        if (feeTokens >= burnTokensThreshold) {
            inToken.transfer(BURN_ADDRESS, feeTokens);
            emit Burned(feeTokens);

            delete feeTokens;
        }
   }

   function setBurnTokensThreshold(uint256 threshold) external onlyOwner {
       require(threshold > 0, "StakeFuturaPool: Invalid value");
       burnTokensThreshold = threshold;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "./../FuturaLinkComponent.sol";
import "./../../interfaces/IFuturaLink.sol";
import "./../../interfaces/IFuturaLinkPool.sol";
import "./../../interfaces/IPancakePair.sol";
import "./../../../contracts/interfaces/IPancakeRouterV2.sol";

contract FuturaLinkPool is IFuturaLinkPool, FuturaLinkComponent {
    struct UserInfo {
        uint256 totalStakeAmount;
        uint256 totalValueClaimed;
        uint256 lastStakeTime;

        uint256 lastDividendPoints;
        uint256 unclaimedDividends;
        uint256 earned;
    }

    uint256 public constant DIVIDEND_POINTS_ACCURACY = TOTAL_SUPPLY;

    IBEP20 public outToken;
    IBEP20 public inToken;
    
    uint256 public override amountOut;
    uint256 public override amountIn;
    uint256 public override totalDividends; 
    uint256 public override totalDividendPoints;
    uint16 public override futuralinkPointsPerToken;
    bool public override isStakingEnabled;
    uint256 public override earlyUnstakingFeeDuration = 1 days;
    uint16 public override unstakingFeeMagnitude = 10;

    uint256 public disburseBatchDivisor;
    uint256 public disburseBatchTime;
    uint256 public dividendPointsToDisbursePerSecond;
    uint256 public lastAvailableDividentPoints;
    uint256 public disburseDividendsTimespan = 2 hours;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalStaked;

    uint256 public feeTokens;
    uint16 public fundAllocationMagnitude = 850;
    

    address internal _pancakeSwapRouterAddress;
    IPancakeRouter02 internal _pancakeswapV2Router;
    IPancakePair internal outTokenPair;

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant TOTAL_SUPPLY = 1000000000000 * 10**9;

    uint256 internal futuralinkPointsPrecision;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Burned(uint256 amount);

    constructor(IFutura futura, address routerAddress, IBEP20 _inToken, IBEP20 _outToken) FuturaLinkComponent(futura) {
        inToken = _inToken;
        outToken = _outToken;

        futuralinkPointsPerToken = 10;
        isStakingEnabled = true;
        
        setPancakeSwapRouter(routerAddress);
    }

    receive() external payable { }

    function stake(uint256 amount) external notPaused notUnauthorizedContract process {
        doStake(msg.sender, amount);
    }

    function stake(address userAddress, uint256 amount) external onlyAdmins {
        doStake(userAddress, amount);
    }

    function unstake(uint256 amount) external notPaused notUnauthorizedContract process {
        doUnstake(msg.sender, amount);
    }

    function unstake(address userAddress, uint256 amount) external onlyAdmins {
        doUnstake(userAddress, amount);
    }

    function stakeOnBehalf(address userAddress, uint256 amount) external onlyAdmins {
        doStake(msg.sender, userAddress, amount);
    }

    function deposit(uint256 amount, uint256 gas) external payable virtual override onlyAdmins {
        if (amount > 0) {
            require(outToken.allowance(msg.sender, address(this)) >= amount, "FuturaLinkPool: Not allowed");
            outToken.transferFrom(msg.sender, address(this), amount);
            onDeposit(amount);
        }

        if (gas > 0) {
            doProcessFunds(gas);
        }
    }

    function claim() external notPaused notUnauthorizedContract process {
        doClaim(msg.sender);
    }

    function claim(address userAddress) external onlyAdmins {
        doClaim(userAddress);
    }

    function claimFor(address userAddress) external onlyAdmins {
        // Required to allow auto-compound to other pools
        doClaim(userAddress, msg.sender);
    }

    function amountStakedBy(address userAddress) external view returns (uint256) {
        return userInfo[userAddress].totalStakeAmount;
    }

    function unclaimedDividendsOf(address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        return (user.unclaimedDividends + calculateReward(user)) / DIVIDEND_POINTS_ACCURACY;
    }

    function unclaimedValueOf(address userAddress) external override view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        uint256 unclaimedDividends = (user.unclaimedDividends + calculateReward(user)) / DIVIDEND_POINTS_ACCURACY;
        return valueOfOutTokens(unclaimedDividends);
    }

    function totalValueClaimed(address userAddress) external override view returns(uint256) {
        return userInfo[userAddress].totalValueClaimed;
    }

    function totalEarnedBy(address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        return (user.earned + calculateReward(user)) / DIVIDEND_POINTS_ACCURACY;
    }

    function excessTokens(address tokenAddress) public virtual view returns(uint256) {
        uint256 balance = (IBEP20(tokenAddress)).balanceOf(address(this));

        if (tokenAddress == address(inToken)) {
            balance -= totalStaked + feeTokens;
        }

        if (tokenAddress == address(outToken)) {
            balance -= amountOut;
        }

        return balance;
    }

    function disburse(uint256 amount) external onlyAdmins {
        uint256 excess = excessTokens(address(outToken));
        require(amount <= excess, "FuturaLink: Excessive amount");
        onDeposit(amount);
    }

    function doProcessFunds(uint256) virtual internal {
        uint256 availableFundsForTokens = address(this).balance;
        
         // Fill pool with token
        if (availableFundsForTokens > 0) {
            onDeposit(buyOutTokens(availableFundsForTokens));
        }
    }


    function doStake(address userAddress, uint256 amount) internal {
        doStake(userAddress, userAddress, amount);
    }

    function doStake(address spender, address userAddress, uint256 amount) internal {
        require(amount > 0, "FuturaLinkPool: Invalid amount");
        require(isStakingEnabled, "FuturaLinkPool: Disabled");

        updateStakingOf(userAddress);

        require(inToken.balanceOf(spender) > amount, "FuturaLinkPool: Insufficient balance");
        require(inToken.allowance(spender, address(this)) >= amount, "FuturaLinkPool: Not approved");
 
        UserInfo storage user = userInfo[userAddress];

        user.lastStakeTime = block.timestamp;
        user.totalStakeAmount += amount;
        amountIn += amount;
        totalStaked += amount;
        updateDividendsBatch();

        inToken.transferFrom(spender, address(this), amount);
        emit Staked(userAddress, amount);
    }
    
    function doUnstake(address userAddress, uint256 amount) internal {
        require(amount > 0, "FuturaLinkPool: Invalid amount");
        
        updateStakingOf(userAddress);

        UserInfo storage user = userInfo[userAddress];
        require(user.totalStakeAmount >= amount, "FuturaLinkPool: Excessive amount");

        user.totalStakeAmount -= amount;
        amountIn -= amount;
        totalStaked -= amount;
        updateDividendsBatch();

        uint256 feeAmount;
        if (block.timestamp - user.lastStakeTime < earlyUnstakingFeeDuration) {
           feeAmount = amount * unstakingFeeMagnitude / 1000;
           feeTokens += feeAmount;
        }
        
        inToken.transfer(userAddress, amount - feeAmount);
        emit Unstaked(userAddress, amount);
    }

    function doClaim(address userAddress) private {
        doClaim(userAddress, userAddress);
    }

    function doClaim(address userAddress, address receiver) private {
        updateStakingOf(userAddress);

        UserInfo storage user = userInfo[userAddress];

        uint256 reward = user.unclaimedDividends / DIVIDEND_POINTS_ACCURACY;
        require(reward > 0, "FuturaLinkPool: Nothing to claim");

        user.unclaimedDividends -= reward * DIVIDEND_POINTS_ACCURACY;
        user.totalValueClaimed += valueOfOutTokens(reward);
        
        amountOut -= reward;
        sendReward(receiver, reward);
    }

    function sendReward(address userAddress, uint256 reward) internal virtual {
        outToken.transfer(userAddress, reward);
    }

    function onDeposit(uint256 amount) internal {
        if (amountIn == 0) {
            //Excess of tokens
            return;
        }

        amountOut += amount;
        totalDividends += amount;

        // Gradually handout a new batch of dividends
        lastAvailableDividentPoints = totalAvailableDividendPoints();
        disburseBatchTime = block.timestamp;

        totalDividendPoints += amount * DIVIDEND_POINTS_ACCURACY / amountIn;

        dividendPointsToDisbursePerSecond = (totalDividendPoints - lastAvailableDividentPoints) / disburseDividendsTimespan;
        disburseBatchDivisor = amountIn;
    }

    function updateDividendsBatch() internal {
        if (amountIn == 0) {
            return;
        }

        lastAvailableDividentPoints = totalAvailableDividendPoints();
        disburseBatchTime = block.timestamp;

        uint256 remainingPoints = totalDividendPoints - lastAvailableDividentPoints;
        if (remainingPoints == 0) {
            return;
        }

        totalDividendPoints = totalDividendPoints + (remainingPoints * disburseBatchDivisor / amountIn) - remainingPoints;
        dividendPointsToDisbursePerSecond = (totalDividendPoints - lastAvailableDividentPoints) / (disburseDividendsTimespan - (block.timestamp - disburseBatchTime));

        disburseBatchDivisor = amountIn;
    }

    function totalAvailableDividendPoints() internal view returns(uint256) {
        uint256 points = lastAvailableDividentPoints + (block.timestamp - disburseBatchTime) * dividendPointsToDisbursePerSecond;
        if (points > totalDividendPoints) {
            return totalDividendPoints;
        }

        return points;
    }

    function updateStakingOf(address userAddress) internal {
        UserInfo storage user = userInfo[userAddress];

        uint256 reward = calculateReward(user);

        user.unclaimedDividends += reward;
        user.earned += reward;
        user.lastDividendPoints = totalAvailableDividendPoints();
    }

    function calculateReward(UserInfo storage user) private view returns (uint256) {
        return (totalAvailableDividendPoints() - user.lastDividendPoints) * user.totalStakeAmount;
    }
    
    function buyOutTokens(uint256 weiFunds) internal virtual returns(uint256) { 
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(outToken);

        uint256 previousBalance = outToken.balanceOf(address(this));
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: weiFunds }(0, path, address(this), block.timestamp + 360);
        return outToken.balanceOf(address(this)) - previousBalance;
    }

    function valueOfOutTokens(uint256 amount) internal virtual view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = outTokenPair.getReserves();

        // Ensure reserve0 is WETH
        (uint112 _reserve0, uint112 _reserve1) = outTokenPair.token0() == _pancakeswapV2Router.WETH() ? (reserve0, reserve1) : (reserve1, reserve0);
        if (_reserve1 == 0) {
            return _reserve0;
        }

        return amount * _reserve0 / _reserve1;
    }

    function setEarlyUnstakingFeeDuration(uint256 duration) external onlyOwner {  
        earlyUnstakingFeeDuration = duration;
    }

    function setUnstakingFeeMagnitude(uint16 magnitude) external onlyOwner {
        require(unstakingFeeMagnitude <= 1000, "FuturaLinkPool: Out of range");
        unstakingFeeMagnitude = magnitude;
    }

    function setFundAllocationMagnitude(uint16 magnitude) external onlyOwner {  
        require(magnitude <= 1000, "FuturaLinkPool: Out of range");
        fundAllocationMagnitude = magnitude;
    }

    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(0), "FuturaLinkPool: Invalid address");

        _pancakeSwapRouterAddress = routerAddress; 
        _pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);

        outTokenPair = IPancakePair(IPancakeFactory(_pancakeswapV2Router.factory()).getPair(_pancakeswapV2Router.WETH(), address(outToken)));
    }

    function setDisburseDividendsTimespan(uint256 timespan) external onlyOwner {
        require(timespan > 0, "FuturaLinkPool: Invalid value");
        
        disburseDividendsTimespan = timespan;
        onDeposit(0);
    }

    function outTokenAddress() external view override returns (address) {
        return address(outToken);
    }

    function inTokenAddress() external view override returns (address) {
        return address(inToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

import "./../interfaces/IFutura.sol";
import "./../interfaces/IFuturaLink.sol";
import "./../interfaces/IFuturaLinkFuel.sol";
import "./utils/AccessControlled.sol";
import "./utils/EmergencyWithdrawable.sol";

contract FuturaLinkComponent is AccessControlled, EmergencyWithdrawable {
    IFutura public futura;
    IFuturaLinkFuel public fuel;
    uint256 public processGas = 300000;

    modifier process() {
        if (processGas > 0) {
            fuel.addGas(processGas);
        }
        
        _;
    }

    constructor(IFutura _futura) {
        require(address(_futura) != address(0), "FuturaLinkComponent: Invalid address");
       
        futura = _futura;
    }

    function setProcessGas(uint256 gas) external onlyOwner {
        processGas = gas;
    }

    function setFutura(IFutura _futura) public onlyOwner {
        require (address(_futura) != address(0), "FuturaLinkComponent: Invalid address");
        futura = _futura;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

interface IFuturaLink {
   	function processFunds(uint256 gas) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

interface IFuturaLinkPool {
    function outTokenAddress() external view returns (address);

    function inTokenAddress() external view returns (address);

    function amountIn() external view returns(uint256);

    function amountOut() external view returns(uint256);

    function totalDividends() external view returns(uint256);

    function totalDividendPoints() external view returns(uint256);

    function futuralinkPointsPerToken() external view returns(uint16);

    function isStakingEnabled() external view returns(bool);

    function earlyUnstakingFeeDuration() external view returns(uint256);

    function unstakingFeeMagnitude() external view returns(uint16);

    function unclaimedValueOf(address userAddress) external view returns (uint256);

    function totalValueClaimed(address userAddress) external view returns(uint256);

    function deposit(uint256 amount, uint256 gas) external payable;

}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

interface IPancakePair {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakeFactory {
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

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

import "./../../contracts/interfaces/IBEP20.sol";

interface IFutura is IBEP20 {
    function processRewardClaimQueue(uint256 gas) external;

    function calculateRewardCycleExtension(uint256 balance, uint256 amount) external view returns (uint256);

    function claimReward() external;

    function claimReward(address addr) external;

    function isRewardReady(address user) external view returns (bool);

    function isExcludedFromFees(address addr) external view returns(bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function rewardClaimQueueIndex() external view returns(uint256);

    function setFirstToken(string memory token) external;

    function setSecondToken(string memory token) external;

    function getFirstToken(address user) external view returns (address);

    function getSecondToken(address user) external view returns (address);

    function isTokenAllowed(string memory symbol) external view returns (bool);

    function getTokenAddress(string memory symbol) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

interface IFuturaLinkFuel {
    function addGas(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

/**
 * @dev Contract module that helps prevent calls to a function.
 */
abstract contract AccessControlled {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address private _owner;
    bool private _isPaused;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _authorizedContracts;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _status = _NOT_ENTERED;
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        setAdmin(_owner, true);
        setAdmin(address(this), true);
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "AccessControlled: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
        require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        _;
    }

    modifier notUnauthorizedContract() {
        if (!_authorizedContracts[msg.sender]) {
            require(!_isContract(msg.sender), "AccessControlled: unauthorized contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: unauthorized proxy contract not allowed");
        }
        _;
    }

    modifier isNotUnauthorizedContract(address addr) {
        if (!_authorizedContracts[addr]) {
            require(!_isContract(addr), "AccessControlled: contract not allowed");
        }
        
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "AccessControlled: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by a non-admin account
     */
    modifier onlyAdmins() {
        require(_admins[msg.sender], "AccessControlled: caller does not have permission");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "AccessControlled: paused");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function setAdmin(address addr, bool _isAdmin) public onlyOwner {
        _admins[addr] = _isAdmin;
    }

    function isAdmin(address addr) public view returns(bool) {
        return _admins[addr];
    }

    function setAuthorizedContract(address addr, bool isAuthorized) public onlyOwner {
        _authorizedContracts[addr] = isAuthorized;
    }

    function pause() public onlyOwner {
        _isPaused = true;
    }

    function unpause() public onlyOwner {
        _isPaused = false;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

import "./AccessControlled.sol";
import "./../../../contracts/interfaces/IBEP20.sol";

abstract contract EmergencyWithdrawable is AccessControlled {
    /**
     * @notice Withdraw unexpected tokens sent to the contract
     */
    function withdrawStuckTokens(address token) external onlyOwner {
        uint256 amount = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(msg.sender, amount);
    }
    
    /**
     * @notice Withdraws funds of the contract - only for emergencies
     */
    function emergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: UNLICENSED

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}