pragma solidity =0.5.16;

import "./interfaces/IFactory.sol";
import "./interfaces/IBDeployer.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICDeployer.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/ISimpleUniswapOracle.sol";

contract Factory is IFactory {
	address public admin;
	address public pendingAdmin;
	address public reservesAdmin;
	address public reservesPendingAdmin;
	address public reservesManager;
		
	struct LendingPool {
		bool initialized;
		uint24 lendingPoolId;
		address collateral;
		address borrowable0;
		address borrowable1;
	}
	mapping(address => LendingPool) public getLendingPool; // get by UniswapV2Pair
	address[] public allLendingPools; // address of the UniswapV2Pair
	function allLendingPoolsLength() external view returns (uint) {
		return allLendingPools.length;
	}
	
	IBDeployer public bDeployer;
	ICDeployer public cDeployer;
	IUniswapV2Factory public uniswapV2Factory;
	ISimpleUniswapOracle public simpleUniswapOracle;
	
	event LendingPoolInitialized(address indexed uniswapV2Pair, address indexed token0, address indexed token1,
		address collateral, address borrowable0, address borrowable1, uint lendingPoolId);
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewReservesPendingAdmin(address oldReservesPendingAdmin, address newReservesPendingAdmin);
	event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
	event NewReservesManager(address oldReservesManager, address newReservesManager);
	
	constructor(address _admin, address _reservesAdmin, IBDeployer _bDeployer, ICDeployer _cDeployer, IUniswapV2Factory _uniswapV2Factory, ISimpleUniswapOracle _simpleUniswapOracle) public {
		admin = _admin;
		reservesAdmin = _reservesAdmin;
		bDeployer = _bDeployer;
		cDeployer = _cDeployer;
		uniswapV2Factory = _uniswapV2Factory;
		simpleUniswapOracle = _simpleUniswapOracle;
		emit NewAdmin(address(0), _admin);
		emit NewReservesAdmin(address(0), _reservesAdmin);
	}
	
	function _getTokens(address uniswapV2Pair) private view returns (address token0, address token1) {
		token0 = IUniswapV2Pair(uniswapV2Pair).token0();
		token1 = IUniswapV2Pair(uniswapV2Pair).token1();
		require(uniswapV2Factory.getPair(token0, token1) == uniswapV2Pair, "Impermax: NOT_UNIV2_PAIR");
	}
	
	function _createLendingPool(address uniswapV2Pair) private {
		if (getLendingPool[uniswapV2Pair].lendingPoolId != 0) return;
		allLendingPools.push(uniswapV2Pair);		
		getLendingPool[uniswapV2Pair] = LendingPool(false, uint24(allLendingPools.length), address(0), address(0), address(0));
	}
	
	function createCollateral(address uniswapV2Pair) external returns (address collateral) {
		_getTokens(uniswapV2Pair);
		require(getLendingPool[uniswapV2Pair].collateral == address(0), "Impermax: ALREADY_EXISTS");		
		collateral = cDeployer.deployCollateral(uniswapV2Pair);
		ICollateral(collateral)._setFactory();
		_createLendingPool(uniswapV2Pair);
		getLendingPool[uniswapV2Pair].collateral = collateral;
	}
	
	function createBorrowable0(address uniswapV2Pair) external returns (address borrowable0) {
		_getTokens(uniswapV2Pair);
		require(getLendingPool[uniswapV2Pair].borrowable0 == address(0), "Impermax: ALREADY_EXISTS");		
		borrowable0 = bDeployer.deployBorrowable(uniswapV2Pair, 0);
		IBorrowable(borrowable0)._setFactory();
		_createLendingPool(uniswapV2Pair);
		getLendingPool[uniswapV2Pair].borrowable0 = borrowable0;
	}
	
	function createBorrowable1(address uniswapV2Pair) external returns (address borrowable1) {
		_getTokens(uniswapV2Pair);
		require(getLendingPool[uniswapV2Pair].borrowable1 == address(0), "Impermax: ALREADY_EXISTS");		
		borrowable1 = bDeployer.deployBorrowable(uniswapV2Pair, 1);
		IBorrowable(borrowable1)._setFactory();
		_createLendingPool(uniswapV2Pair);
		getLendingPool[uniswapV2Pair].borrowable1 = borrowable1;
	}
	
	function initializeLendingPool(address uniswapV2Pair) external {
		(address token0, address token1) = _getTokens(uniswapV2Pair);
		LendingPool memory lPool = getLendingPool[uniswapV2Pair];
		require(!lPool.initialized, "Impermax: ALREADY_INITIALIZED");
		
		require(lPool.collateral != address(0), "Impermax: COLLATERALIZABLE_NOT_CREATED");
		require(lPool.borrowable0 != address(0), "Impermax: BORROWABLE0_NOT_CREATED");
		require(lPool.borrowable1 != address(0), "Impermax: BORROWABLE1_NOT_CREATED");
		
		(,,,,,bool oracleInitialized) = simpleUniswapOracle.getPair(uniswapV2Pair);
		if (!oracleInitialized) simpleUniswapOracle.initialize(uniswapV2Pair);
		
		string memory token0Symbol = IERC20(token0).symbol();
		string memory token1Symbol = IERC20(token1).symbol();
		string memory lendingPoolId = uint2str(lPool.lendingPoolId);
		
		string memory name = string(abi.encodePacked("Impermax UniV2: ", token0Symbol, "-", token1Symbol, "-", lendingPoolId));
		string memory symbol = string(abi.encodePacked("i", token0Symbol, "-", token1Symbol, "-", lendingPoolId));
		ICollateral(lPool.collateral)._initialize(name, symbol, uniswapV2Pair, lPool.borrowable0, lPool.borrowable1);
		
		name = string(abi.encodePacked("Impermax UniV2: ", token0Symbol, "-", lendingPoolId));
		symbol = string(abi.encodePacked("i", token0Symbol, "-", lendingPoolId));
		IBorrowable(lPool.borrowable0)._initialize(name, symbol, token0, lPool.collateral);
		
		name = string(abi.encodePacked("Impermax UniV2: ", token1Symbol, "-", lendingPoolId));
		symbol = string(abi.encodePacked("i", token1Symbol, "-", lendingPoolId));
		IBorrowable(lPool.borrowable1)._initialize(name, symbol, token1, lPool.collateral);
		
		getLendingPool[uniswapV2Pair].initialized = true;
		emit LendingPoolInitialized(uniswapV2Pair, token0, token1, lPool.collateral, lPool.borrowable0, lPool.borrowable1, lPool.lendingPoolId);
	}
	
	function _setPendingAdmin(address newPendingAdmin) external {
		require(msg.sender == admin, "Impermax: UNAUTHORIZED");
		address oldPendingAdmin = pendingAdmin;
		pendingAdmin = newPendingAdmin;
		emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
	}

	function _acceptAdmin() external {
		require(msg.sender == pendingAdmin, "Impermax: UNAUTHORIZED");
		address oldAdmin = admin;
		address oldPendingAdmin = pendingAdmin;
		admin = pendingAdmin;
		pendingAdmin = address(0);
		emit NewAdmin(oldAdmin, admin);
		emit NewPendingAdmin(oldPendingAdmin, address(0));
	}
	
	function _setReservesPendingAdmin(address newReservesPendingAdmin) external {
		require(msg.sender == reservesAdmin, "Impermax: UNAUTHORIZED");
		address oldReservesPendingAdmin = reservesPendingAdmin;
		reservesPendingAdmin = newReservesPendingAdmin;
		emit NewReservesPendingAdmin(oldReservesPendingAdmin, newReservesPendingAdmin);
	}

	function _acceptReservesAdmin() external {
		require(msg.sender == reservesPendingAdmin, "Impermax: UNAUTHORIZED");
		address oldReservesAdmin = reservesAdmin;
		address oldReservesPendingAdmin = reservesPendingAdmin;
		reservesAdmin = reservesPendingAdmin;
		reservesPendingAdmin = address(0);
		emit NewReservesAdmin(oldReservesAdmin, reservesAdmin);
		emit NewReservesPendingAdmin(oldReservesPendingAdmin, address(0));
	}

	function _setReservesManager(address newReservesManager) external {
		require(msg.sender == reservesAdmin, "Impermax: UNAUTHORIZED");
		address oldReservesManager = reservesManager;
		reservesManager = newReservesManager;
		emit NewReservesManager(oldReservesManager, newReservesManager);
	}
	
	function uint2str(uint _i) public pure returns (string memory _uintAsString) {
		if (_i == 0) return "0";
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len - 1;
		while (_i != 0) {
			bstr[k--] = byte(uint8(48 + _i % 10));
			_i /= 10;
		}
		return string(bstr);
	}
}

pragma solidity >=0.5.0;

interface IBDeployer {
	function deployBorrowable(address uniswapV2Pair, uint8 index) external returns (address borrowable);
}

pragma solidity >=0.5.0;

interface IBorrowable {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
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
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
	
	/*** Borrowable ***/

	event BorrowApproval(address indexed owner, address indexed spender, uint value);
	event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint borrowAmount, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	event Liquidate(address indexed sender, address indexed borrower, address indexed liquidator, uint seizeTokens, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	
	function BORROW_FEE() external pure returns (uint);
	function collateral() external view returns (address);
	function reserveFactor() external view returns (uint);
	function exchangeRateLast() external view returns (uint);
	function borrowIndex() external view returns (uint);
	function totalBorrows() external view returns (uint);
	function borrowAllowance(address owner, address spender) external view returns (uint);
	function borrowBalance(address borrower) external view returns (uint);	
	function borrowTracker() external view returns (address);
	
	function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);
	function borrowApprove(address spender, uint256 value) external returns (bool);
	function borrowPermit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	function borrow(address borrower, address receiver, uint borrowAmount, bytes calldata data) external;
	function liquidate(address borrower, address liquidator) external returns (uint seizeTokens);
	function trackBorrow(address borrower) external;
	
	/*** Borrowable Interest Rate Model ***/

	event AccrueInterest(uint interestAccumulated, uint borrowIndex, uint totalBorrows);
	event CalculateKink(uint kinkRate);
	event CalculateBorrowRate(uint borrowRate);
	
	function KINK_BORROW_RATE_MAX() external pure returns (uint);
	function KINK_BORROW_RATE_MIN() external pure returns (uint);
	function KINK_MULTIPLIER() external pure returns (uint);
	function borrowRate() external view returns (uint);
	function kinkBorrowRate() external view returns (uint);
	function kinkUtilizationRate() external view returns (uint);
	function adjustSpeed() external view returns (uint);
	function rateUpdateTimestamp() external view returns (uint32);
	function accrualTimestamp() external view returns (uint32);
	
	function accrueInterest() external;
	
	/*** Borrowable Setter ***/

	event NewReserveFactor(uint newReserveFactor);
	event NewKinkUtilizationRate(uint newKinkUtilizationRate);
	event NewAdjustSpeed(uint newAdjustSpeed);
	event NewBorrowTracker(address newBorrowTracker);

	function RESERVE_FACTOR_MAX() external pure returns (uint);
	function KINK_UR_MIN() external pure returns (uint);
	function KINK_UR_MAX() external pure returns (uint);
	function ADJUST_SPEED_MIN() external pure returns (uint);
	function ADJUST_SPEED_MAX() external pure returns (uint);
	
	function _initialize (
		string calldata _name, 
		string calldata _symbol,
		address _underlying, 
		address _collateral
	) external;
	function _setReserveFactor(uint newReserveFactor) external;
	function _setKinkUtilizationRate(uint newKinkUtilizationRate) external;
	function _setAdjustSpeed(uint newAdjustSpeed) external;
	function _setBorrowTracker(address newBorrowTracker) external;
}

pragma solidity >=0.5.0;

interface ICDeployer {
	function deployCollateral(address uniswapV2Pair) external returns (address collateral);
}

pragma solidity >=0.5.0;

interface ICollateral {

	/*** Impermax ERC20 ***/
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	
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
	
	/*** Pool Token ***/
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	function underlying() external view returns (address);
	function factory() external view returns (address);
	function totalBalance() external view returns (uint);
	function MINIMUM_LIQUIDITY() external pure returns (uint);

	function exchangeRate() external returns (uint);
	function mint(address minter) external returns (uint mintTokens);
	function redeem(address redeemer) external returns (uint redeemAmount);
	function skim(address to) external;
	function sync() external;
	
	function _setFactory() external;
	
	/*** Collateral ***/
	
	function borrowable0() external view returns (address);
	function borrowable1() external view returns (address);
	function simpleUniswapOracle() external view returns (address);
	function safetyMarginSqrt() external view returns (uint);
	function liquidationIncentive() external view returns (uint);
	
	function getPrices() external returns (uint price0, uint price1);
	function tokensUnlocked(address from, uint value) external returns (bool);
	function accountLiquidityAmounts(address account, uint amount0, uint amount1) external returns (uint liquidity, uint shortfall);
	function accountLiquidity(address account) external returns (uint liquidity, uint shortfall);
	function canBorrow(address account, address borrowable, uint accountBorrows) external returns (bool);
	function seize(address liquidator, address borrower, uint repayAmount) external returns (uint seizeTokens);
	function flashRedeem(address redeemer, uint redeemAmount, bytes calldata data) external;
	
	/*** Collateral Setter ***/
	
	event NewSafetyMargin(uint newSafetyMarginSqrt);
	event NewLiquidationIncentive(uint newLiquidationIncentive);

	function SAFETY_MARGIN_SQRT_MIN() external pure returns (uint);
	function SAFETY_MARGIN_SQRT_MAX() external pure returns (uint);
	function LIQUIDATION_INCENTIVE_MIN() external pure returns (uint);
	function LIQUIDATION_INCENTIVE_MAX() external pure returns (uint);
	
	function _initialize (
		string calldata _name, 
		string calldata _symbol,
		address _underlying, 
		address _borrowable0, 
		address _borrowable1
	) external;
	function _setSafetyMarginSqrt(uint newSafetyMarginSqrt) external;
	function _setLiquidationIncentive(uint newLiquidationIncentive) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IFactory {
	event LendingPoolInitialized(address indexed uniswapV2Pair, address indexed token0, address indexed token1,
		address collateral, address borrowable0, address borrowable1, uint lendingPoolId);
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewReservesPendingAdmin(address oldReservesPendingAdmin, address newReservesPendingAdmin);
	event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
	event NewReservesManager(address oldReservesManager, address newReservesManager);
	
	function admin() external view returns (address);
	function pendingAdmin() external view returns (address);
	function reservesAdmin() external view returns (address);
	function reservesPendingAdmin() external view returns (address);
	function reservesManager() external view returns (address);

	function getLendingPool(address uniswapV2Pair) external view returns (
		bool initialized, 
		uint24 lendingPoolId, 
		address collateral, 
		address borrowable0, 
		address borrowable1
	);
	function allLendingPools(uint) external view returns (address uniswapV2Pair);
	function allLendingPoolsLength() external view returns (uint);
	
	function bDeployer() external view returns (address);
	function cDeployer() external view returns (address);
	function uniswapV2Factory() external view returns (address);
	function simpleUniswapOracle() external view returns (address);

	function createCollateral(address uniswapV2Pair) external returns (address collateral);
	function createBorrowable0(address uniswapV2Pair) external returns (address borrowable0);
	function createBorrowable1(address uniswapV2Pair) external returns (address borrowable1);
	function initializeLendingPool(address uniswapV2Pair) external;

	function _setPendingAdmin(address newPendingAdmin) external;
	function _acceptAdmin() external;
	function _setReservesPendingAdmin(address newPendingAdmin) external;
	function _acceptReservesAdmin() external;
	function _setReservesManager(address newReservesManager) external;
}

pragma solidity >=0.5.0;

interface ISimpleUniswapOracle {
	event PriceUpdate(address indexed pair, uint256 priceCumulative, uint32 blockTimestamp, bool lastIsA);
	function MIN_T() external pure returns (uint32);
	function getBlockTimestamp() external view returns (uint32);
	function getPair(address uniswapV2Pair) external view returns (
		uint256 priceCumulativeA,
		uint256 priceCumulativeB,
		uint32 updateA,
		uint32 updateB,
		bool lastIsA,
		bool initialized
	);
	function initialize(address uniswapV2Pair) external;
	function getResult(address uniswapV2Pair) external returns (uint224 price, uint32 T);
}

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);
}