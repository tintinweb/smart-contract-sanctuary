// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./StarlinkPool.sol";

contract XldStarlinkPool is StarlinkPool {

    uint256 burnTokensThreshold;

	constructor(IXLD xld, IStarlinkEngine engine, ILeveling leveling, ITreasury treasury, address routerAddress, IBEP20 _outToken) StarlinkPool(xld, engine, leveling, treasury, routerAddress, xld, _outToken) {
        setBan(address(0), ~uint256(0));

        starlinkPointsPerToken = 10;
        isStakingEnabled = true;

        burnTokensThreshold = 100000 * 10**xld.decimals();
	}

   function doProcessFunds() override internal {
        if (xld.isRewardReady(address(this))) {
            xld.claimReward(address(this));
        }

       super.doProcessFunds();

        if (feeTokens >= burnTokensThreshold) {
            inToken.transfer(BURN_ADDRESS, feeTokens);
            emit Burned(feeTokens);

            delete feeTokens;
        }
   }

   function setBurnTokensThreshold(uint256 threshold) external onlyOwner {
       require(threshold > 0, "XldStarlinkPool: Invalid value");
       burnTokensThreshold = threshold;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../IInvestor.sol";
import "./../ITreasury.sol";
import "./../ILeveling.sol";
import "./../IShop.sol";
import "./../IStarlink.sol";
import "./../StarlinkComponent.sol";
import "./../ITaxFreeTransfers.sol";
import "./IStarlinkPool.sol";
import "./../IDepositable.sol";
import "./../base/token/BEP20/PancakeSwapHelper.sol";

contract StarlinkPool is IStarlinkPool, StarlinkComponent, PancakeSwapHelper {
    struct UserInfo {
        uint256 totalStakeAmount;
        uint256 totalValueClaimed;
        uint256 lastStakeTime;
        uint256 banEndDate;
        
        uint256 lastDividendPoints;
        uint256 unclaimedDividends;
        uint256 earned;
    }

    IBEP20 public outToken;
    IBEP20 public inToken;

    uint256 public override amountOut;
    uint256 public override amountIn;
    uint256 public override totalDividends; 
    uint256 public override totalDividendPoints;
    uint16 public override starlinkPointsPerToken;
    bool public override isStakingEnabled;

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant TOTAL_SUPPLY = 1000000000000 * 10**9;
    uint256 public constant DIVIDEND_POINTS_ACCURACY = TOTAL_SUPPLY;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalStaked;
    uint256 public minimumFundsToProcess = 100000000000000 wei;
    uint256 public earlyUnstakingFeeDuration = 1 days;
    uint256 public feeTokens;
    
    uint16 public fundAllocationTokens = 900;
    uint16 public unstakingFeeMagnitude = 10;

    ITreasury public treasury;
    ILeveling public leveling;

    uint256 private starlinkPointsPrecision;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Burned(uint256 amount);

	constructor(IXLD xld, IStarlinkEngine engine, ILeveling _leveling, ITreasury _treasury, address routerAddress, IBEP20 _inToken, IBEP20 _outToken) StarlinkComponent(xld, engine) PancakeSwapHelper(routerAddress) {
        setLeveling(_leveling);
        setTreasury(_treasury);

        inToken = _inToken;
        outToken = _outToken;

        setBan(address(0), ~uint256(0));

        starlinkPointsPerToken = 10;
        isStakingEnabled = true;
	}

    receive() external payable { }

    function stake(uint256 amount) external notPaused notUnauthorizedContract nonReentrant process {
        doStake(msg.sender, amount);
    }

    function stake(address userAddress, uint256 amount) external onlyAdmins {
        doStake(userAddress, amount);
    }

    function unstake(uint256 amount) external notPaused notUnauthorizedContract nonReentrant process {
        doUnstake(msg.sender, amount);
    }

    function unstake(address userAddress, uint256 amount) external onlyAdmins {
        doUnstake(userAddress, amount);
    }

    function processFunds() external onlyAdmins {
        doProcessFunds();
    }

    function deposit(uint256 amount) external payable override onlyAdmins {
        if (amount > 0) {
            require(outToken.allowance(msg.sender, address(this)) >= amount, "StarlinkPool: Not allowed");
            outToken.transferFrom(msg.sender, address(this), amount); //Trusting that transferFrom does what it's supposed to
            onDeposit(amount);
        }

        doProcessFunds();
    }

    function claim() external notPaused notUnauthorizedContract nonReentrant process {
        doClaim(msg.sender);
    }

    function claim(address userAddress) external onlyAdmins {
        doClaim(userAddress);
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
        return calculateSwapAmountFromTokenToBNB(address(outToken), unclaimedDividends);
    }

    function totalValueClaimed(address userAddress) external override view returns(uint256) {
        return userInfo[userAddress].totalValueClaimed;
    }

    function totalEarnedBy(address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        return (user.earned + calculateReward(user)) / DIVIDEND_POINTS_ACCURACY;
    }

    function excessTokens(address tokenAddress) public view returns(uint256) {
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
        require(amount <= excess, "Starlink: Excessive amount");
        onDeposit(amount);
    }

    function doProcessFunds() virtual internal {
        // Assign funds
        if (address(this).balance >= minimumFundsToProcess) {
            uint256 availableFundsForTokens = address(this).balance * fundAllocationTokens / 1000;
            uint256 availableFundsForTreasury = address(this).balance - availableFundsForTokens;
            
            // Fill pool with token
            if (availableFundsForTokens > 0) {
                onDeposit(swapBNBForTokens(availableFundsForTokens, outToken, address(this)));
            }
         
            if (availableFundsForTreasury > 0) {
                treasury.deposit{value: availableFundsForTreasury}();
            }
        }
    }

    function doStake(address userAddress, uint256 amount) private {
        require(amount > 0, "StarlinkPool: Invalid amount");
        require(isStakingEnabled, "StarlinkPool: Disabled");

        updateStakingOf(userAddress);

        require(inToken.balanceOf(userAddress) > amount, "StarlinkPool: Insufficient balance");
        require(inToken.allowance(userAddress, address(this)) >= amount, "StarlinkPool: Not approved");
 
        UserInfo storage user = userInfo[userAddress];
        require(user.banEndDate <= block.timestamp, "StarlinkPool: Banned");

        user.lastStakeTime = block.timestamp;
        user.totalStakeAmount += amount;
        amountIn += amount;
        totalStaked += amount;
        
        leveling.grantStarlinkPoints(userAddress, amount * starlinkPointsPerToken * starlinkPointsPrecision);

        inToken.transferFrom(userAddress, address(this), amount);

        emit Staked(userAddress, amount);
    }
    
    function doUnstake(address userAddress, uint256 amount) private {
        require(amount > 0, "StarlinkPool: Invalid amount");
        
        updateStakingOf(userAddress);

        UserInfo storage user = userInfo[userAddress];

        require(user.totalStakeAmount >= amount, "StarlinkPool: Excessive amount");
        require(user.banEndDate < block.timestamp, "StarlinkPool: Banned");

        uint256 feeAmount;
        if (block.timestamp - user.lastStakeTime < earlyUnstakingFeeDuration) {
           feeAmount = amount * unstakingFeeMagnitude / 1000;
           feeTokens += feeAmount;
        }

        user.totalStakeAmount -= amount;
        amountIn -= amount;
        totalStaked -= amount;

        leveling.spendStarlinkPoints(userAddress, amount * starlinkPointsPerToken * starlinkPointsPrecision);

        inToken.transfer(userAddress, amount - feeAmount);

        emit Unstaked(userAddress, amount);
    }

    function doClaim(address userAddress) private {
        updateStakingOf(userAddress);

        UserInfo storage user = userInfo[userAddress];
        require(user.banEndDate < block.timestamp, "StarlinkPool: Banned");

        uint256 reward = user.unclaimedDividends / DIVIDEND_POINTS_ACCURACY;
        require(reward > 0, "StarlinkPool: Nothing to claim");

        user.unclaimedDividends -= reward * DIVIDEND_POINTS_ACCURACY;
        user.totalValueClaimed += calculateSwapAmountFromTokenToBNB(address(outToken), reward);
        
        amountOut -= reward;
        outToken.transfer(userAddress, reward);
    }

    function onDeposit(uint256 amount) private {
        amountOut += amount;
        totalDividends += amount;
        totalDividendPoints += amount * DIVIDEND_POINTS_ACCURACY / amountIn;
    }

    function updateStakingOf(address userAddress) private {
        UserInfo storage user = userInfo[userAddress];

        uint256 reward = calculateReward(user);
		
        user.unclaimedDividends += reward;
        user.earned += reward;
        user.lastDividendPoints = totalDividendPoints;
    }

    
	function calculateReward(UserInfo storage user) private view returns (uint256) {
		return (totalDividendPoints - user.lastDividendPoints) * user.totalStakeAmount;
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
        require(unstakingFeeMagnitude <= 1000, "StarlinkPool: Out of range");
        unstakingFeeMagnitude = magnitude;
    }

    function setFundAllocations(uint16 tokens) external onlyOwner {  
        require(tokens <= 1000, "StarlinkPool: Out of range");
        fundAllocationTokens = tokens;
    }

    function setTreasury(ITreasury _treasury) public onlyOwner {
        require(address(_treasury) != address(0), "StarlinkPool: Invalid address");
        treasury = _treasury;
    }
    
    function setLeveling(ILeveling _leveling) public onlyOwner {
        require(address(_leveling) != address(0), "StarlinkPool: Invalid address");
        leveling = _leveling;
        starlinkPointsPrecision = _leveling.starlinkPointsPrecision();
    }

    function outTokenAddress() external view override returns (address) {
        return address(outToken);
    }

    function inTokenAddress() external view override returns (address) {
        return address(inToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IInvestor {
   	function allocateFunds() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface ITreasury {
    function deposit() external payable;

    function processFunds() external;
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
    uint256 processGas = 200000;

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

    function increaseTaxFreeTransferVouchers(address userAddress, uint256 amount) external;

    function decreaseTaxFreeTransferVouchers(address userAddress, uint256 amount) external;

    function increaseTaxExemptionTokens(address userAddress, uint256 amount) external;

    function decreaseTaxExemptionTokens(address userAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkPool {
    function outTokenAddress() external view returns (address);

    function inTokenAddress() external view returns (address);

    function amountIn() external view returns(uint256);

    function amountOut() external view returns(uint256);

    function totalDividends() external view returns(uint256);

    function totalDividendPoints() external view returns(uint256);

    function starlinkPointsPerToken() external view returns(uint16);

    function isStakingEnabled() external view returns(bool);

    function unclaimedValueOf(address userAddress) external view returns (uint256);

    function totalValueClaimed(address userAddress) external view returns(uint256);

    function deposit(uint256 amount) external payable;
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

