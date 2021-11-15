// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IInvestor.sol";
import "./ITreasury.sol";
import "./ILeveling.sol";
import "./IShop.sol";
import "./IStarlink.sol";
import "./StarlinkComponent.sol";
import "./ITaxFreeTransfers.sol";
import "./IDepositable.sol";
import "./base/token/BEP20/PancakeSwapHelper.sol";

contract Starlink is IStarlink, IDepositable, StarlinkComponent, PancakeSwapHelper {
    struct UserInfo {
        uint256 totalStakeAmount;
        uint256 lastStakeTime;
        uint256 banEndDate;
        uint256 totalValueClaimed;
    }

    struct Pool {
        address token;
        uint256 amountOut;
        uint256 amountIn;
        uint256 totalDividends;
        uint256 totalDividendPoints;
        uint16 starlinkPointsPerToken;
        bool isFillEnabled;
        bool isFillRewardPoolEnabled;
        bool isStakingEnabled;
    }

    struct UserStaking {
        uint256 amount;
        uint256 lastDividendPoints;
        uint256 unclaimedDividends;
        uint256 earned;
    }

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant TOTAL_SUPPLY = 1000000000000 * 10**9;

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => UserStaking)) public userPoolStake;
    mapping(address => uint256) public poolIndexByTokenAddress;
    Pool[] public pools;
    address public stakingPool;
    uint256 public totalStaked;
    uint256 public minimumFundsToProcess = 1 wei;
    uint256 public earlyUnstakingFeeDuration = 1 days;
    uint256 public tokensPendingBurn;
    uint16 public fundAllocationXldRewardPool = 100;
    uint16 public fundAllocationOtherRewardPool = 50;
    uint16 public fundAllocationTokens = 750;
    uint16 public unstakingFeeMagnitude = 10;
    uint16 public updatePoolIndex;

    ITreasury public treasury;
    ILeveling public leveling;

    uint256 private starlinkPointsPrecision;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event FillRewardPoolFailed(address poolAddress, uint256 amount);
    event UserInitialized(address indexed user);
    event Burned(uint256 amount);

	constructor(IXLD xld, IStarlinkEngine engine, address routerAddress) StarlinkComponent(xld, engine) PancakeSwapHelper(routerAddress) {
        setStakingPool(address(this));
        addPool(address(xld), 10, true);
        setBan(address(0), ~uint256(0));
	}

    receive() external payable { }

    function stake(address poolToken, uint256 amount) external notPaused notUnauthorizedContract nonReentrant process {
        doStake(msg.sender, poolToken, amount);
    }

    function stake(address userAddress, address poolToken, uint256 amount) external onlyAdmins {
        doStake(userAddress, poolToken, amount);
    }

    function unstake(address poolToken, uint256 amount) external notPaused notUnauthorizedContract nonReentrant process {
        doUnstake(msg.sender, poolToken, amount);
    }

    function unstake(address userAddress, address poolToken, uint256 amount) external onlyAdmins {
        doUnstake(userAddress, poolToken, amount);
    }

    function addPool(address tokenAddress, uint16 starlinkPointsPerToken, bool isEnabled) public onlyAdmins {
        require(pools.length < 256, "Starlink: Too many pools");
        require(!poolExists(tokenAddress), "Starlink: Pool already exists");

        Pool memory pool = Pool({ 
            token: tokenAddress, 
            amountIn: 0,
            amountOut: 0,
            starlinkPointsPerToken: starlinkPointsPerToken, 
            totalDividends: 0,
            totalDividendPoints: 0,
            isFillEnabled: isEnabled,
            isFillRewardPoolEnabled: isEnabled, 
            isStakingEnabled: isEnabled
        });

        pools.push(pool);
        poolIndexByTokenAddress[tokenAddress] = pools.length - 1;
    }

    function deletePool(address tokenAddress) public onlyAdmins {
        require(poolExists(tokenAddress), "Starlink: Pool does not exist");

        Pool storage pool = pools[poolIndexByTokenAddress[tokenAddress]];
        uint256 index = poolIndexByTokenAddress[pool.token];

        Pool storage lastPool = pools[pools.length - 1];

        if (index < pools.length - 1) {
            // Replace with last one
            pools[index] = lastPool;
            poolIndexByTokenAddress[lastPool.token] = index;
        }
        
        // Delete last one
        delete poolIndexByTokenAddress[lastPool.token];
        delete pools[pools.length - 1];
    }

    function updatePool(address tokenAddress, bool isFillEnabled, bool isFillRewardPoolEnabled, bool isStakingEnabled) external onlyAdmins {
        require(poolExists(tokenAddress), "Starlink: Pool does not exist");

        Pool storage pool = pools[poolIndexByTokenAddress[tokenAddress]];
        pool.isFillEnabled = isFillEnabled;
        pool.isFillRewardPoolEnabled = isFillRewardPoolEnabled;
        pool.isStakingEnabled = isStakingEnabled;
    }

    function poolExists(address tokenAddress) public view returns(bool) {
        return pools.length > 0 && pools[poolIndexByTokenAddress[tokenAddress]].token == tokenAddress;
    }

    function processFunds(uint256 gas) external override notPaused nonReentrant notUnauthorizedContract {
        doProcessFunds(gas);
    }

    function ratioOfPool(address tokenAddress) public view returns(uint256) {
        Pool storage pool = pools[poolIndexByTokenAddress[tokenAddress]];
        return ratioOfPool(pool);
    }

    function excessTokens(address tokenAddress) public view returns(uint256) {
        Pool storage pool = pools[poolIndexByTokenAddress[tokenAddress]];
        uint256 balance = (IBEP20(tokenAddress)).balanceOf(address(this));
        if (tokenAddress == address(xld)) {
            balance -= tokensPendingBurn + totalStaked;
        }

        return balance - pool.amountOut;
    }

    function disburse(address tokenAddress, uint256 amount) external onlyAdmins {
        uint256 excess = excessTokens(tokenAddress);
        require(amount <= excess, "Starlink: Excessive amount");
        onDeposit(tokenAddress, amount);
    }

    function deposit(address tokenAddress, uint256 amount) external payable override notPaused {
        require(amount > 0, "Starlink: Invalid amount");

        if (tokenAddress == address(0)) {
            require(msg.value == amount, "Starlink: Invalid amount");
        } else {
            require(poolExists(tokenAddress), "Starlink: Invalid address");

            IBEP20 token = IBEP20(tokenAddress);
            require(token.allowance(msg.sender, address(this)) >= amount, "Starlink: Not allowed");

            token.transferFrom(msg.sender, address(this), amount);
            onDeposit(tokenAddress, amount);
        }
    }

    function poolOf(address token) external view returns (Pool memory) {
        require(poolExists(token), "Pool does not exist");
        return pools[poolIndexByTokenAddress[token]];
    }

    function claim(address token) external notPaused notUnauthorizedContract nonReentrant process {
        doClaim(msg.sender, token);
    }

    function claim(address userAddress, address token) external onlyAdmins {
        doClaim(userAddress, token);
    }

    function amountStakedBy(address userAddress, address token) external view returns (uint256) {
        UserStaking storage userStake = userPoolStake[userAddress][token];
        return userStake.amount;
    }

    function unclaimedDividendsOf(address userAddress, address token) external view returns (uint256) {
        Pool storage pool = pools[poolIndexByTokenAddress[token]];
        UserStaking storage userStake = userPoolStake[userAddress][token];

        return userStake.unclaimedDividends + calculateReward(pool, userStake);
    }

    function totalUnclaimedValueOf(address userAddress) external view returns (uint256) {
        uint256 totalUnclaimedValue;
        for(uint i = 0; i < pools.length; i++) {
            Pool storage pool = pools[poolIndexByTokenAddress[pools[i].token]];
            UserStaking storage userStake = userPoolStake[userAddress][pools[i].token];

            uint256 unclaimedDividends = userStake.unclaimedDividends + calculateReward(pool, userStake);
            totalUnclaimedValue += calculateSwapAmountFromTokenToBNB(pools[i].token, unclaimedDividends);
        }
        
        return totalUnclaimedValue;
    }

    function totalEarnedBy(address userAddress, address token) external view returns (uint256) {
        Pool storage pool = pools[poolIndexByTokenAddress[token]];
        UserStaking storage userStake = userPoolStake[userAddress][token];

        return userStake.earned + calculateReward(pool, userStake);
    }


    function doProcessFunds(uint256 gas) private {
        // Claim rewards based on XLD balance from staking and re-distribute them as rewards to everyone who stake
        if (xld.isRewardReady(address(this))) {
            xld.claimReward(address(this));
        }

        // Assign funds
        uint256 funds = address(this).balance;
        if (funds >= minimumFundsToProcess) {
            uint256 availableFundsForXLDRewardPool = funds * fundAllocationXldRewardPool  / 1000;
            uint256 availableFundsForOtherRewardPools = funds * fundAllocationOtherRewardPool / 1000;
            uint256 availableFundsForTokens = funds * fundAllocationTokens / 1000;
            uint256 availableFundsForTreasury = funds - availableFundsForXLDRewardPool - availableFundsForOtherRewardPools - availableFundsForTokens;
            
            // Fill XLD reward pool (Core action)
            if (availableFundsForXLDRewardPool > 0) {
                (bool sent,) = address(xld).call{value : availableFundsForXLDRewardPool}("");
                if (!sent) {
                    emit FillRewardPoolFailed(address(xld), availableFundsForXLDRewardPool);
                } 
            }

            if (totalStaked > 0) {
                updatePools(gas, availableFundsForTokens, availableFundsForOtherRewardPools);
            }
         
            if (availableFundsForTreasury > 0) {
                treasury.deposit{value: availableFundsForTreasury}(address(xld), 0);
            }
        }

        if (tokensPendingBurn > 0) {
            burn(tokensPendingBurn);
            delete tokensPendingBurn;
        }
    }

    function updatePools(uint256 gas, uint256 fundsForTokens, uint256 fundsForRewardPools) private {
	    uint256 gasUsed = 0;
		uint256 gasLeft = gasleft();
		uint256 iteration = 0;

        uint16 poolIndex = updatePoolIndex; //Save gas by updating storage only once

        while(gasUsed < gas && iteration < pools.length) {
            if (poolIndex >= pools.length) {
                poolIndex = 0;
            }

            updatePool(poolIndex, fundsForTokens, fundsForRewardPools);

            unchecked {
                uint256 newGasLeft = gasleft();
			
                if (gasLeft > newGasLeft) {
                    uint256 consumedGas = gasLeft - newGasLeft;
                    gasUsed += consumedGas;
                    gasLeft = newGasLeft;
                }

                iteration++;
                poolIndex++;
            }
        }

        updatePoolIndex = poolIndex;
    }

    function updatePool(uint index, uint fundsForTokens, uint fundsForRewardPool) private {
        Pool storage pool = pools[index];
        uint256 ratio = pool.amountIn * 100000 / totalStaked;

        // Fill pool with tokens
        if (pool.isFillEnabled) {
            uint256 allocatedFunds = fundsForTokens * ratio / 100000;
            
            if (allocatedFunds > 0) {
                uint256 amountBought = swapBNBForTokens(allocatedFunds, IBEP20(pool.token), address(this));
                onDeposit(pool, amountBought);
            }
        }

        // Fill rewards
        if (pool.isFillRewardPoolEnabled) {
            uint256 allocatedFunds = fundsForRewardPool * ratio / 100000;
            if (allocatedFunds > 0) {
                (bool sent,) = pool.token.call{value : allocatedFunds}("");
                if (!sent) {
                    emit FillRewardPoolFailed(pool.token, allocatedFunds);
                }
            }
        }
    }

    function doStake(address userAddress, address poolToken, uint256 amount) private {
        require(amount > 0, "Starlink: Invalid amount");

        updateStakingOf(userAddress, poolToken);

        Pool storage pool = pools[poolIndexByTokenAddress[poolToken]];
        require(pool.isStakingEnabled, "Starlink: Disabled");

        uint256 balance = xld.balanceOf(userAddress);
        require(balance > amount, "Starlink: Insufficient balance");
        require(xld.allowance(userAddress, stakingPool) >= amount, "Starlink: Not approved");
        require(xld.calculateRewardCycleExtension(balance, amount) == 0, "Starlink: Penalty");

        UserInfo storage user = userInfo[userAddress];
        require(user.banEndDate <= block.timestamp, "Starlink: Banned");

        if (user.lastStakeTime == 0) {
            emit UserInitialized(userAddress);
        }

        UserStaking storage userStake = userPoolStake[userAddress][poolToken];

        userStake.amount += amount;
        user.totalStakeAmount += amount;
        pool.amountIn += amount;
        totalStaked += amount;
        user.lastStakeTime = block.timestamp;

        leveling.grantStarlinkPoints(userAddress, amount * pool.starlinkPointsPerToken);
        xld.transferFrom(userAddress, stakingPool, amount);
        emit Staked(userAddress, amount);
    }
    
    function doUnstake(address userAddress, address poolToken, uint256 amount) private {
        require(amount > 0, "Starlink: Invalid amount");
        
        updateStakingOf(userAddress, poolToken);

        Pool storage pool = pools[poolIndexByTokenAddress[poolToken]];

        UserStaking storage userStake = userPoolStake[userAddress][poolToken];
        require(userStake.amount >= amount, "Starlink: Excessive amount");

        UserInfo storage user = userInfo[userAddress];
        require(xld.calculateRewardCycleExtension(xld.balanceOf(userAddress), amount) == 0, "Starlink: Penalty");
        require(user.banEndDate < block.timestamp, "Starlink: Banned");

        uint256 feeAmount;
        if (block.timestamp - user.lastStakeTime < earlyUnstakingFeeDuration) {
           feeAmount = amount * unstakingFeeMagnitude / 1000;
           tokensPendingBurn += feeAmount;
        }

        userStake.amount -= amount;
        user.totalStakeAmount -= amount;
        pool.amountIn -= amount;
        totalStaked -= amount;

        leveling.spendStarlinkPoints(userAddress, amount * pool.starlinkPointsPerToken);
        xld.transferFrom(stakingPool, userAddress, amount - feeAmount);
        emit Unstaked(userAddress, amount);
    }

    function ratioOfPool(Pool storage pool) private view returns(uint256) {
        return pool.amountIn * 100000 / totalStaked;
    }

    function doClaim(address userAddress, address token) private {
        updateStakingOf(userAddress, token);

        Pool storage pool = pools[poolIndexByTokenAddress[token]];

        UserInfo storage user = userInfo[userAddress];
        require(user.banEndDate < block.timestamp, "Starlink: Banned");

        UserStaking storage userStake = userPoolStake[userAddress][token];
        uint256 reward = userStake.unclaimedDividends;
        require(reward > 0, "Starlink: Nothing to claim");
        userStake.unclaimedDividends = 0;
        user.totalValueClaimed += calculateSwapAmountFromTokenToBNB(token, reward);
        
        pool.amountOut -= reward;
        (IBEP20(token)).transferFrom(stakingPool, userAddress, reward);
    }

    function onDeposit(address tokenAddress, uint256 amount) private {
        Pool storage pool = pools[poolIndexByTokenAddress[tokenAddress]];
        onDeposit(pool, amount);
    }

    function onDeposit(Pool storage pool, uint256 amount) private {
        pool.amountOut += amount;
        pool.totalDividends += amount;
        pool.totalDividendPoints += amount / pool.amountIn;
    }

    function updateStakingOf(address userAddress, address token) private {
        Pool storage pool = pools[poolIndexByTokenAddress[token]];
        UserStaking storage userStake = userPoolStake[userAddress][token];

        uint256 reward = calculateReward(pool, userStake);
		
        userStake.unclaimedDividends += reward;
        userStake.earned += reward;
        userStake.lastDividendPoints = pool.totalDividendPoints;
    }

    
	function calculateReward(Pool storage pool, UserStaking storage userStake) private view returns (uint256) {
		return (pool.totalDividendPoints - userStake.lastDividendPoints) * userStake.amount;
    }

    function buy(uint256 bnbAmount, address destination) private returns(uint256) {
        require(destination != address(0) && destination != BURN_ADDRESS, "XldIntegrated: Invalid buy address");

        if (bnbAmount > 0) {
            return swapBNBForTokens(bnbAmount, xld, destination);
        }

        return 0;
    }

    function onPancakeSwapRouterUpdated() internal override {
        super.onPancakeSwapRouterUpdated();
        xld.approve(_pancakeSwapRouterAddress, ~uint256(0));
    }

    function setMinimumFundsToProcess(uint256 amount) external onlyOwner {  
        minimumFundsToProcess = amount;
    }

    function setBan(address userAddress, uint256 banEndDate) public onlyAdmins {
        UserInfo storage user = userInfo[userAddress];
        user.banEndDate = banEndDate;
    }

    function setEarlyUnstakingFeeDuration(uint256 duration) external onlyOwner {  
        earlyUnstakingFeeDuration = duration;
    }

    function setUnstakingFeeMagnitude(uint16 magnitude) external onlyOwner {
        require(unstakingFeeMagnitude <= 1000, "Starlink: Out of range");
        unstakingFeeMagnitude = magnitude;
    }

    function setFundAllocations(uint16 xldRewardPool, uint16 otherRewardPool, uint16 tokens) external onlyOwner {  
        require(xldRewardPool +  otherRewardPool + tokens <= 1000, "Starlink: Out of range");

        fundAllocationXldRewardPool = xldRewardPool;
        fundAllocationOtherRewardPool = otherRewardPool;
        fundAllocationTokens = tokens;
    }

    function setTreasury(ITreasury _treasury) external onlyOwner {
        require(address(_treasury) != address(0), "Starlink: Invalid address");
        treasury = _treasury;
    }

    function poolsLength() external view returns (uint256) {
        return pools.length;
    }

    function setStakingPool(address pool) public onlyOwner {
        require(pool != address(0), "Starlink: Invalid address");
        stakingPool = pool;
        xld.approve(stakingPool, ~uint256(0));
    }
    
    function setLeveling(ILeveling _leveling) external onlyOwner {
        require(address(_leveling) != address(0), "Starlink: Invalid address");
        leveling = _leveling;
        starlinkPointsPrecision = _leveling.starlinkPointsPrecision();
    }

    function xldAddress() external override view returns (address) {
        return address(xld);
    }

    function burn(uint256 amount) internal {
        if (amount > 0) {
            xld.transfer(BURN_ADDRESS, amount);
            emit Burned(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IInvestor {
   	function deposit() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IDepositable.sol";

interface ITreasury is IDepositable {
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILeveling {

    function grantStarlinkPoints(address userAddress, uint256 amount) external;

    function spendStarlinkPoints(address userAddress, uint256 amount) external;

    function levelUp(address userAddress) external;

    function changeName(address userAddress, bytes32 newName) external;

    function grantXp(address userAddress, uint256 amount, uint256 reasonId) external;
    
    function activateXpBoost(address userAddress, uint8 rate, uint256 duration) external;

    function deactivateXpBoost(address userAddress) external;

    function grantRestXp(address userAddress, uint256 amount) external;

    function spendRestXp(address userAddress, uint256 amount) external;

    function currentXpOf(address userAddress) external view returns(uint256); 

    function xpOfLevel(uint256 level) external pure returns (uint256);

    function levelOf(address userAddress) external view returns(uint256);

    function starlinkPointsPrecision() external pure returns(uint256);

    function setNameChangeVouchers(address userAddress, uint8 amount) external;

    function increaseNameChangeVouchers(address userAddress, uint8 amount) external;

    function decreaseNameChangeVouchers(address userAddress, uint8 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IShop {
    function upsertItem(uint256 id, uint8 typeId, uint256 price, uint8 discountRate, uint8 bulkDiscountRate, uint256 val1, uint256 val2, address fulfilment, address fundsReceiver) external;

    function itemInfo(uint256 id) external view returns(uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlink {
   	function processFunds(uint256 gas) external;

	function xldAddress() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./base/token/BEP20/IXLD.sol";
import "./IStarlink.sol";
import "./IStarlinkEngine.sol";
import "./base/access/AccessControlled.sol";
import "./base/token/BEP20/EmergencyWithdrawable.sol";

contract StarlinkComponent is AccessControlled, EmergencyWithdrawable {
    IXLD public xld;
    IStarlinkEngine public engine;
    uint256 processGas = 500000;

    modifier process() {
        if (processGas > 0) {
            engine.addGas(processGas);
        }
        
        _;
    }

    constructor(IXLD _xld, IStarlinkEngine _engine) {
        require(address(_xld) != address(0), "StarlinkComponent: Invalid address");
       
        xld = _xld;
        setEngine(_engine);
    }

    function setProcessGas(uint256 gas) external onlyOwner {
        processGas = gas;
    }

    function setEngine(IStarlinkEngine _engine) public onlyOwner {
        require(address(_engine) != address(0), "StarlinkComponent: Invalid address");

        engine = _engine;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITaxFreeTransfers {
    function taxFreeTransfer(address source, address destination, uint256 amount) external;

    function setTaxFreeTransferVouchers(address userAddress, uint8 amount) external;

    function increaseTaxFreeTransferVouchers(address userAddress, uint8 amount) external;

    function decreaseTaxFreeTransferVouchers(address userAddress, uint8 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IDepositable {
    function deposit(address token, uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./PancakeSwap/IPancakeRouter02.sol";
import "./PancakeSwap/IPancakeFactory.sol";
import "./PancakeSwap/IPancakePair.sol";
import "./IBEP20.sol";

contract PancakeSwapHelper is AccessControlled {

	address internal _pancakeSwapRouterAddress;
	IPancakeRouter02 internal _pancakeswapV2Router;

	constructor(address routerAddress) {
		//0x10ED43C718714eb63d5aA57B78B54704E256024E for main net
		setPancakeSwapRouter(routerAddress);
	}

    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
		require(routerAddress != address(0), "Cannot use the zero address as router address");

		_pancakeSwapRouterAddress = routerAddress; 
		_pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
		
		onPancakeSwapRouterUpdated();
	}


	// Returns how many tokens can be bought with the given amount of BNB in PCS
	function calculateSwapAmountFromBNBToToken(address token, uint256 amountBNB) public view returns (uint256) {
		if (token == _pancakeswapV2Router.WETH()) {
			return amountBNB;
		}

		IPancakePair pair = IPancakePair(IPancakeFactory(_pancakeswapV2Router.factory()).getPair(_pancakeswapV2Router.WETH(), token));
		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

		// Ensure reserve0 is WETH
		(uint112 _reserve0, uint112 _reserve1) = pair.token0() == _pancakeswapV2Router.WETH() ? (reserve0, reserve1) : (reserve1, reserve0);
		if (_reserve0 == 0) {
			return _reserve1;
		}
		
		return amountBNB * _reserve1 / _reserve0;
	}

	function calculateSwapAmountFromTokenToBNB(address token, uint256 amountTokens) public view returns (uint256) {
		if (token == _pancakeswapV2Router.WETH()) {
			return amountTokens;
		}

		IPancakePair pair = IPancakePair(IPancakeFactory(_pancakeswapV2Router.factory()).getPair(_pancakeswapV2Router.WETH(), token));
		(uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

		// Ensure reserve0 is WETH
		(uint112 _reserve0, uint112 _reserve1) = pair.token0() == _pancakeswapV2Router.WETH() ? (reserve0, reserve1) : (reserve1, reserve0);
		if (_reserve1 == 0) {
			return _reserve0;
		}

		return amountTokens * _reserve0 / _reserve1;
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


	function onPancakeSwapRouterUpdated() internal virtual {

	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IBEP20.sol";

interface IXLD is IBEP20 {
   	function processRewardClaimQueue(uint256 gas) external;

    function calculateRewardCycleExtension(uint256 balance, uint256 amount) external view returns (uint256);

    function claimReward() external;

    function claimReward(address addr) external;

    function isRewardReady(address user) external view returns (bool);

    function isExcludedFromFees(address addr) external view returns(bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function rewardClaimQueueIndex() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkEngine {
    function addGas(uint256 amount) external;

    function donate() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

pragma solidity 0.8.6;

import "../../../base/access/AccessControlled.sol";
import "./IBEP20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IPancakeRouter01.sol";

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

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.6;

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

pragma solidity 0.8.6;

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

pragma solidity 0.8.6;

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

