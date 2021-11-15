pragma solidity =0.5.16;

import "./BStorage.sol";
import "./PoolToken.sol";

contract BAllowance is PoolToken, BStorage {	

	event BorrowApproval(address indexed owner, address indexed spender, uint256 value);

	function _borrowApprove(address owner, address spender, uint256 value) private {
		borrowAllowance[owner][spender] = value;
		emit BorrowApproval(owner, spender, value);
	}
	
	function borrowApprove(address spender, uint256 value) external returns (bool) {
		_borrowApprove(msg.sender, spender, value);
		return true;
	}
	
	function _checkBorrowAllowance(address owner, address spender, uint256 value) internal {
		uint _borrowAllowance = borrowAllowance[owner][spender];
		if (spender != owner && _borrowAllowance != uint256(-1)) {
			require(_borrowAllowance >= value, "YampFinance: BORROW_NOT_ALLOWED");
			borrowAllowance[owner][spender] = _borrowAllowance - value;
		}	
	}

	// keccak256("BorrowPermit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant BORROW_PERMIT_TYPEHASH = 0xf6d86ed606f871fa1a557ac0ba607adce07767acf53f492fb215a1a4db4aea6f;
	function borrowPermit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
		_checkSignature(owner, spender, value, deadline, v, r, s, BORROW_PERMIT_TYPEHASH);
		_borrowApprove(owner, spender, value);
	}
}

pragma solidity =0.5.16;

import "./Borrowable.sol";
import "./interfaces/IBDeployer.sol";

/*
 * This contract is used by the Factory to deploy Borrowable(s)
 * The bytecode would be too long to fit in the Factory
 */

contract BDeployer is IBDeployer {
	constructor () public {}
	
	function deployBorrowable(address uniswapV2Pair, uint8 index) external returns (address borrowable) {
		bytes memory bytecode = type(Borrowable).creationCode;
		bytes32 salt = keccak256(abi.encodePacked(msg.sender, uniswapV2Pair, index));
		assembly {
			borrowable := create2(0, add(bytecode, 32), mload(bytecode), salt)
		}
	}
}

pragma solidity =0.5.16;

import "./BStorage.sol";
import "./PoolToken.sol";

contract BInterestRateModel is PoolToken, BStorage {

	// When utilization is 100% borrowRate is kinkBorrowRate * KINK_MULTIPLIER
	// kinkBorrowRate relative adjustment per second belongs to [1-adjustSpeed, 1+adjustSpeed*(KINK_MULTIPLIER-1)]
	uint public constant KINK_MULTIPLIER = 5;
	uint public constant KINK_BORROW_RATE_MAX = 31.7097920e9; //100% per year
	uint public constant KINK_BORROW_RATE_MIN = 0.31709792e9; //1% per year

	event AccrueInterest(uint interestAccumulated, uint borrowIndex, uint totalBorrows);
	event CalculateKinkBorrowRate(uint kinkBorrowRate);
	event CalculateBorrowRate(uint borrowRate);
		
	function _calculateBorrowRate() internal {
		uint _kinkUtilizationRate = kinkUtilizationRate;		
		uint _adjustSpeed = adjustSpeed;
		uint _borrowRate = borrowRate;	
		uint _kinkBorrowRate = kinkBorrowRate;
		uint32 _rateUpdateTimestamp = rateUpdateTimestamp;		
	
		// update kinkBorrowRate using previous borrowRate
		uint32 timeElapsed = getBlockTimestamp() - _rateUpdateTimestamp; // underflow is desired
		if(timeElapsed > 0) {
			rateUpdateTimestamp = getBlockTimestamp();
			uint adjustFactor;
			
			if (_borrowRate < _kinkBorrowRate) {
				// never overflows, _kinkBorrowRate is never 0
				uint tmp = (_kinkBorrowRate - _borrowRate) * 1e18 / _kinkBorrowRate * _adjustSpeed * timeElapsed / 1e18;
				adjustFactor = tmp > 1e18 ? 0 : 1e18 - tmp;
			} else {
				// never overflows, _kinkBorrowRate is never 0
				uint tmp = (_borrowRate - _kinkBorrowRate) * 1e18 / _kinkBorrowRate * _adjustSpeed * timeElapsed / 1e18;
				adjustFactor = tmp + 1e18;
			}
			
			// never overflows
			_kinkBorrowRate = _kinkBorrowRate * adjustFactor / 1e18;
			if(_kinkBorrowRate > KINK_BORROW_RATE_MAX) _kinkBorrowRate = KINK_BORROW_RATE_MAX;
			if(_kinkBorrowRate < KINK_BORROW_RATE_MIN) _kinkBorrowRate = KINK_BORROW_RATE_MIN;

			kinkBorrowRate = uint48(_kinkBorrowRate);
			emit CalculateKinkBorrowRate(_kinkBorrowRate);
		}
		
		uint _utilizationRate;
		{ // avoid stack to deep
		uint _totalBorrows = totalBorrows; // gas savings
		uint _actualBalance = totalBalance.add(_totalBorrows);
		_utilizationRate = (_actualBalance == 0) ? 0 : _totalBorrows * 1e18 / _actualBalance;
		}
		
		// update borrowRate using the new kinkBorrowRate	
		if(_utilizationRate <= _kinkUtilizationRate) {
			// never overflows, _kinkUtilizationRate is never 0
			_borrowRate = _kinkBorrowRate * _utilizationRate / _kinkUtilizationRate;
		} else {
			// never overflows, _kinkUtilizationRate is always < 1e18
			uint overUtilization = (_utilizationRate - _kinkUtilizationRate) * 1e18 / (1e18 - _kinkUtilizationRate);
			// never overflows
			_borrowRate = ((KINK_MULTIPLIER - 1) * overUtilization + 1e18) * _kinkBorrowRate / 1e18;
		}
		borrowRate = uint48(_borrowRate);
		emit CalculateBorrowRate(_borrowRate);
	}
	
	// applies accrued interest to total borrows and reserves
	function accrueInterest() public {
		uint _borrowIndex = borrowIndex;
		uint _totalBorrows = totalBorrows;
		uint32 _accrualTimestamp = accrualTimestamp;
		
		uint32 blockTimestamp = getBlockTimestamp();
		if (_accrualTimestamp == blockTimestamp) return;
		uint32 timeElapsed = blockTimestamp - _accrualTimestamp; // underflow is desired
		accrualTimestamp = blockTimestamp;
		
		uint interestFactor = uint(borrowRate).mul(timeElapsed);	
		uint interestAccumulated = interestFactor.mul(_totalBorrows).div(1e18);
		_totalBorrows = _totalBorrows.add( interestAccumulated );
		_borrowIndex = _borrowIndex.add( interestFactor.mul(_borrowIndex).div(1e18) );
	
		borrowIndex = safe112(_borrowIndex);
		totalBorrows = safe112(_totalBorrows);
		emit AccrueInterest(interestAccumulated, _borrowIndex, _totalBorrows);
	}
		
	function getBlockTimestamp() public view returns (uint32) {
		return uint32(block.timestamp % 2**32);
	}
}

pragma solidity =0.5.16;

import "./BStorage.sol";
import "./PoolToken.sol";
import "./interfaces/IFactory.sol";

contract BSetter is PoolToken, BStorage {

	uint public constant RESERVE_FACTOR_MAX = 0.20e18; //20%
	uint public constant KINK_UR_MIN = 0.50e18; //50%
	uint public constant KINK_UR_MAX = 0.99e18; //99%
	uint public constant ADJUST_SPEED_MIN = 0.05787037e12; //0.5% per day
	uint public constant ADJUST_SPEED_MAX = 5.787037e12; //50% per day

	event NewReserveFactor(uint newReserveFactor);
	event NewKinkUtilizationRate(uint newKinkUtilizationRate);
	event NewAdjustSpeed(uint newAdjustSpeed);
	event NewBorrowTracker(address newBorrowTracker);
	
	// called once by the factory at time of deployment
	function _initialize (
		string calldata _name, 
		string calldata _symbol,
		address _underlying, 
		address _collateral
	) external {
		require(msg.sender == factory, "YampFinance: UNAUTHORIZED"); // sufficient check
		_setName(_name, _symbol);
		underlying = _underlying;
		collateral = _collateral;
		exchangeRateLast = initialExchangeRate;
	}
	
	function _setReserveFactor(uint newReserveFactor) external nonReentrant {
		_checkSetting(newReserveFactor, 0, RESERVE_FACTOR_MAX);
		reserveFactor = newReserveFactor;
		emit NewReserveFactor(newReserveFactor);
	}

	function _setKinkUtilizationRate(uint newKinkUtilizationRate) external nonReentrant {
		_checkSetting(newKinkUtilizationRate, KINK_UR_MIN, KINK_UR_MAX);
		kinkUtilizationRate = newKinkUtilizationRate;
		emit NewKinkUtilizationRate(newKinkUtilizationRate);
	}

	function _setAdjustSpeed(uint newAdjustSpeed) external nonReentrant {
		_checkSetting(newAdjustSpeed, ADJUST_SPEED_MIN, ADJUST_SPEED_MAX);
		adjustSpeed = newAdjustSpeed;
		emit NewAdjustSpeed(newAdjustSpeed);
	}

	function _setBorrowTracker(address newBorrowTracker) external nonReentrant {
		_checkAdmin();
		borrowTracker = newBorrowTracker;
		emit NewBorrowTracker(newBorrowTracker);
	}
	
	function _checkSetting(uint parameter, uint min, uint max) internal view {
		_checkAdmin();
		require(parameter >= min, "YampFinance: INVALID_SETTING");
		require(parameter <= max, "YampFinance: INVALID_SETTING");
	}
	
	function _checkAdmin() internal view {
		require(msg.sender == IFactory(factory).admin(), "YampFinance: UNAUTHORIZED");
	}
}

pragma solidity =0.5.16;

contract BStorage {

	address public collateral;

	mapping (address => mapping (address => uint256)) public borrowAllowance;
	
	struct BorrowSnapshot {
		uint112 principal;		// amount in underlying when the borrow was last updated
		uint112 interestIndex;	// borrow index when borrow was last updated
	}
	mapping(address => BorrowSnapshot) internal borrowBalances;	

	// use one memory slot
	uint112 public borrowIndex = 1e18;
	uint112 public totalBorrows;
	uint32 public accrualTimestamp = uint32(block.timestamp % 2**32);	

	uint public exchangeRateLast;
		
	// use one memory slot
	uint48 public borrowRate;
	uint48 public kinkBorrowRate = 3.1709792e9; //10% per year
	uint32 public rateUpdateTimestamp = uint32(block.timestamp % 2**32);

	uint public reserveFactor = 0.10e18; //10%
	uint public kinkUtilizationRate = 0.70e18; //70%
	uint public adjustSpeed = 0.5787037e12; //5% per day
	address public borrowTracker;

    function safe112(uint n) internal pure returns (uint112) {
        require(n < 2**112, "YampFinance: SAFE112");
        return uint112(n);
    }
}

pragma solidity =0.5.16;

import "./PoolToken.sol";
import "./BAllowance.sol";
import "./BInterestRateModel.sol";
import "./BSetter.sol";
import "./BStorage.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IYampFinanceCallee.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IBorrowTracker.sol";
import "./libraries/Math.sol";

contract Borrowable is IBorrowable, PoolToken, BStorage, BSetter, BInterestRateModel, BAllowance {

	uint public constant BORROW_FEE = 0.001e18; //0.1%

	event Borrow(address indexed sender, address indexed borrower, address indexed receiver, uint borrowAmount, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
	event Liquidate(address indexed sender, address indexed borrower, address indexed liquidator, uint seizeTokens, uint repayAmount, uint accountBorrowsPrior, uint accountBorrows, uint totalBorrows);
		
	constructor() public {}

	/*** PoolToken ***/
	
	function _update() internal {
		super._update();
		_calculateBorrowRate();
	}
	
	function _mintReserves(uint _exchangeRate, uint _totalSupply) internal returns (uint) {
		uint _exchangeRateLast = exchangeRateLast;
		if (_exchangeRate > _exchangeRateLast) {
			uint _exchangeRateNew = _exchangeRate.sub( _exchangeRate.sub(_exchangeRateLast).mul(reserveFactor).div(1e18) );
			uint liquidity = _totalSupply.mul(_exchangeRate).div(_exchangeRateNew).sub(_totalSupply);
			if (liquidity == 0) return _exchangeRate;
			address reservesManager = IFactory(factory).reservesManager();
			_mint(reservesManager, liquidity);
			exchangeRateLast = _exchangeRateNew;
			return _exchangeRateNew;
		}
		else return _exchangeRate;
	}
	
	function exchangeRate() public accrue returns (uint)	{
		uint _totalSupply = totalSupply;
		uint _actualBalance = totalBalance.add(totalBorrows);
		if (_totalSupply == 0 || _actualBalance == 0) return initialExchangeRate;
		uint _exchangeRate = _actualBalance.mul(1e18).div(_totalSupply);
		return _mintReserves(_exchangeRate, _totalSupply);
	}
	
	// force totalBalance to match real balance
	function sync() external nonReentrant update accrue {}
	
	/*** Borrowable ***/

	// this is the stored borrow balance; the current borrow balance may be slightly higher
	function borrowBalance(address borrower) public view returns (uint) {
		BorrowSnapshot memory borrowSnapshot = borrowBalances[borrower];
		if (borrowSnapshot.interestIndex == 0) return 0; // not initialized
		return uint(borrowSnapshot.principal).mul(borrowIndex).div(borrowSnapshot.interestIndex);
	}
	
	function _trackBorrow(address borrower, uint accountBorrows, uint _borrowIndex) internal {
		address _borrowTracker = borrowTracker;
		if (_borrowTracker == address(0)) return;
		IBorrowTracker(_borrowTracker).trackBorrow(borrower, accountBorrows, _borrowIndex);
	}
	
	function _updateBorrow(address borrower, uint borrowAmount, uint repayAmount) private returns (uint accountBorrowsPrior, uint accountBorrows, uint _totalBorrows) {
		accountBorrowsPrior = borrowBalance(borrower);
		if (borrowAmount == repayAmount) return (accountBorrowsPrior, accountBorrowsPrior, totalBorrows);
		uint112 _borrowIndex = borrowIndex;
		if (borrowAmount > repayAmount) {
			BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];
			uint increaseAmount = borrowAmount - repayAmount;
			accountBorrows = accountBorrowsPrior.add(increaseAmount);
			borrowSnapshot.principal = safe112(accountBorrows);
			borrowSnapshot.interestIndex = _borrowIndex;
			_totalBorrows = uint(totalBorrows).add(increaseAmount);	
			totalBorrows = safe112(_totalBorrows);
		}
		else {
			BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];
			uint decreaseAmount = repayAmount - borrowAmount;		
			accountBorrows = accountBorrowsPrior > decreaseAmount ? accountBorrowsPrior - decreaseAmount : 0;
			borrowSnapshot.principal = safe112(accountBorrows);
			if(accountBorrows == 0) {
				borrowSnapshot.interestIndex = 0;
			} else {
				borrowSnapshot.interestIndex = _borrowIndex;
			}
			uint actualDecreaseAmount = accountBorrowsPrior.sub(accountBorrows);
			_totalBorrows = totalBorrows; // gas savings
			_totalBorrows = _totalBorrows > actualDecreaseAmount ? _totalBorrows - actualDecreaseAmount : 0;
			totalBorrows = safe112(_totalBorrows);			
		}
		_trackBorrow(borrower, accountBorrows, _borrowIndex);
	}
	
	// this low-level function should be called from another contract
	function borrow(address borrower, address receiver, uint borrowAmount, bytes calldata data) external nonReentrant update accrue {		
		uint _totalBalance = totalBalance;
		require(borrowAmount <= _totalBalance, "YampFinance: INSUFFICIENT_CASH");
		_checkBorrowAllowance(borrower, msg.sender, borrowAmount);
		
		// optimistically transfer funds
		if (borrowAmount > 0) _safeTransfer(receiver, borrowAmount);
		if (data.length > 0) IYampFinanceCallee(receiver).yampFinanceBorrow(msg.sender, borrower, borrowAmount, data);
		uint balance = IERC20(underlying).balanceOf(address(this));
		
		uint borrowFee = borrowAmount.mul(BORROW_FEE).div(1e18);
		uint adjustedBorrowAmount = borrowAmount.add(borrowFee);
		uint repayAmount = balance.add(borrowAmount).sub(_totalBalance);
		(uint accountBorrowsPrior, uint accountBorrows, uint _totalBorrows) = _updateBorrow(borrower, adjustedBorrowAmount, repayAmount);
		
		if(adjustedBorrowAmount > repayAmount) require(
			ICollateral(collateral).canBorrow(borrower, address(this), accountBorrows),
			"YampFinance: INSUFFICIENT_LIQUIDITY"
		);
		
		emit Borrow(msg.sender, borrower, receiver, borrowAmount, repayAmount, accountBorrowsPrior, accountBorrows, _totalBorrows);
	}

	// this low-level function should be called from another contract
	function liquidate(address borrower, address liquidator) external nonReentrant update accrue returns (uint seizeTokens) {
		uint balance = IERC20(underlying).balanceOf(address(this));
		uint repayAmount = balance.sub(totalBalance);		
		
		uint actualRepayAmount = Math.min(borrowBalance(borrower), repayAmount);
		seizeTokens = ICollateral(collateral).seize(liquidator, borrower, actualRepayAmount);	
		(uint accountBorrowsPrior, uint accountBorrows, uint _totalBorrows) = _updateBorrow(borrower, 0, repayAmount);
		
		emit Liquidate(msg.sender, borrower, liquidator, seizeTokens, repayAmount, accountBorrowsPrior, accountBorrows, _totalBorrows);
	}
	
	function trackBorrow(address borrower) external {
		_trackBorrow(borrower, borrowBalance(borrower), borrowIndex);
	}
	
	modifier accrue() {
		accrueInterest();
		_;
	}
}

pragma solidity =0.5.16;

import "./YampFinanceERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPoolToken.sol";
import "./libraries/SafeMath.sol";

contract PoolToken is IPoolToken, YampFinanceERC20 {
   	uint internal constant initialExchangeRate = 1e18;
	address public underlying;
	address public factory;
	uint public totalBalance;
	uint public constant MINIMUM_LIQUIDITY = 1000;
	
	event Mint(address indexed sender, address indexed minter, uint mintAmount, uint mintTokens);
	event Redeem(address indexed sender, address indexed redeemer, uint redeemAmount, uint redeemTokens);
	event Sync(uint totalBalance);
	
	/*** Initialize ***/
	
	// called once by the factory
	function _setFactory() external {
		require(factory == address(0), "YampFinance: FACTORY_ALREADY_SET");
		factory = msg.sender;
	}
	
	/*** PoolToken ***/
	
	function _update() internal {
		totalBalance = IERC20(underlying).balanceOf(address(this));
		emit Sync(totalBalance);
	}

	function exchangeRate() public returns (uint) 
	{
		uint _totalSupply = totalSupply; // gas savings
		uint _totalBalance = totalBalance; // gas savings
		if (_totalSupply == 0 || _totalBalance == 0) return initialExchangeRate;
		return _totalBalance.mul(1e18).div(_totalSupply);
	}
	
	// this low-level function should be called from another contract
	function mint(address minter) external nonReentrant update returns (uint mintTokens) {
		uint balance = IERC20(underlying).balanceOf(address(this));
		uint mintAmount = balance.sub(totalBalance);
		mintTokens = mintAmount.mul(1e18).div(exchangeRate());

		if(totalSupply == 0) {
			// permanently lock the first MINIMUM_LIQUIDITY tokens
			mintTokens = mintTokens.sub(MINIMUM_LIQUIDITY);
			_mint(address(0), MINIMUM_LIQUIDITY);
		}
		require(mintTokens > 0, "YampFinance: MINT_AMOUNT_ZERO");
		_mint(minter, mintTokens);
		emit Mint(msg.sender, minter, mintAmount, mintTokens);
	}

	// this low-level function should be called from another contract
	function redeem(address redeemer) external nonReentrant update returns (uint redeemAmount) {
		uint redeemTokens = balanceOf[address(this)];
		redeemAmount = redeemTokens.mul(exchangeRate()).div(1e18);

		require(redeemAmount > 0, "YampFinance: REDEEM_AMOUNT_ZERO");
		require(redeemAmount <= totalBalance, "YampFinance: INSUFFICIENT_CASH");
		_burn(address(this), redeemTokens);
		_safeTransfer(redeemer, redeemAmount);
		emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);		
	}

	// force real balance to match totalBalance
	function skim(address to) external nonReentrant {
		_safeTransfer(to, IERC20(underlying).balanceOf(address(this)).sub(totalBalance));
	}

	// force totalBalance to match real balance
	function sync() external nonReentrant update {}
	
	/*** Utilities ***/
	
	// same safe transfer function used by UniSwapV2 (with fixed underlying)
	bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
	function _safeTransfer(address to, uint amount) internal {
		(bool success, bytes memory data) = underlying.call(abi.encodeWithSelector(SELECTOR, to, amount));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "YampFinance: TRANSFER_FAILED");
	}
	
	// prevents a contract from calling itself, directly or indirectly.
	bool internal _notEntered = true;
	modifier nonReentrant() {
		require(_notEntered, "YampFinance: REENTERED");
		_notEntered = false;
		_;
		_notEntered = true;
	}
	
	// update totalBalance with current balance
	modifier update() {
		_;
		_update();
	}
}

pragma solidity =0.5.16;

import "./libraries/SafeMath.sol";

// This contract is basically UniswapV2ERC20 with small modifications
// src: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol

contract YampFinanceERC20 {
	using SafeMath for uint;
	
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint public totalSupply;
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;
	
	bytes32 public DOMAIN_SEPARATOR;
	mapping(address => uint) public nonces;
	
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	constructor() public {}	
	
	function _setName(string memory _name, string memory _symbol) internal {
		name = _name;
		symbol = _symbol;
		uint chainId;
		assembly {
			chainId := chainid
		}
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
				keccak256(bytes(_name)),
				keccak256(bytes("1")),
				chainId,
				address(this)
			)
		);
	}

	function _mint(address to, uint value) internal {
		totalSupply = totalSupply.add(value);
		balanceOf[to] = balanceOf[to].add(value);
		emit Transfer(address(0), to, value);
	}

	function _burn(address from, uint value) internal {
		balanceOf[from] = balanceOf[from].sub(value);
		totalSupply = totalSupply.sub(value);
		emit Transfer(from, address(0), value);
	}

	function _approve(address owner, address spender, uint value) private {
		allowance[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _transfer(address from, address to, uint value) internal {
		balanceOf[from] = balanceOf[from].sub(value, "YampFinance: TRANSFER_TOO_HIGH");
		balanceOf[to] = balanceOf[to].add(value);
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint value) external returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint value) external returns (bool) {
		if (allowance[from][msg.sender] != uint(-1)) {
			allowance[from][msg.sender] = allowance[from][msg.sender].sub(value, "YampFinance: TRANSFER_NOT_ALLOWED");
		}
		_transfer(from, to, value);
		return true;
	}
	
	function _checkSignature(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s, bytes32 typehash) internal {
		require(deadline >= block.timestamp, "YampFinance: EXPIRED");
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(typehash, owner, spender, value, nonces[owner]++, deadline))
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		require(recoveredAddress != address(0) && recoveredAddress == owner, "YampFinance: INVALID_SIGNATURE");	
	}

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
		_checkSignature(owner, spender, value, deadline, v, r, s, PERMIT_TYPEHASH);
		_approve(owner, spender, value);
	}
}

pragma solidity >=0.5.0;

interface IBDeployer {
	function deployBorrowable(address uniswapV2Pair, uint8 index) external returns (address borrowable);
}

pragma solidity >=0.5.0;

interface IBorrowTracker {
	function trackBorrow(address borrower, uint borrowBalance, uint borrowIndex) external;
}

pragma solidity >=0.5.0;

interface IBorrowable {

	/*** YampFinance ERC20 ***/
	
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

interface ICollateral {

	/*** YampFinance ERC20 ***/
	
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

interface IPoolToken {

	/*** YampFinance ERC20 ***/
	
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
}

pragma solidity >=0.5.0;

interface IYampFinanceCallee {
    function yampFinanceBorrow(address sender, address borrower, uint borrowAmount, bytes calldata data) external;
    function yampFinanceRedeem(address sender, uint redeemAmount, bytes calldata data) external;
}

pragma solidity =0.5.16;

// a library for performing various math operations
// forked from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/Math.sol

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity =0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

