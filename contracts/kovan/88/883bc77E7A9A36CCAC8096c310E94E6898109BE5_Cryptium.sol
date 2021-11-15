// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Control is AccessControl {
	bool internal _isInitialized;
	bool internal _isRebaseUnrestricted = true;
	uint8 internal _transferFee = 50;
	uint8 internal _feeFree = 10;
	uint8 internal _operateFee = 10;
	uint8 internal _burnFee = 10;
	uint8 internal _feeDistribAmongOthers = 80;

	uint32 internal period = 3 minutes;
	// uint32 internal period = 3 days; // DEV
	uint80 internal _initialPrice;
	uint80 internal _coeffInflations = 12;

	address internal _operationAddress;
	address internal _rebaseAddress;
	address internal _poolAddress;
	address internal _feeAddress;
	address internal _ownerOldContractToken;

	bytes32 private constant OPERATION = keccak256("operation");
	bytes32 internal constant REBASE = keccak256("rebase");

	uint256 internal _startTime;
	uint256 internal _lastRebase;

	modifier isValidPercent(uint256 percent) {
		require(percent >= 0 && percent <= 100, "Not valid value");
		_;
	}

	modifier isPermitToChange() {
		require(hasRole(OPERATION, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You not allowed");
		_;
	}

	modifier isValidAddress(address adr) {
		require(adr != address(0), "Address must not be '0x0'");
		_;
	}

	// Whitelist
	mapping(address => bool) internal _isWhiteList;

	function changeOwnership(address adr) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(adr) {
		grantRole(DEFAULT_ADMIN_ROLE, adr);
		renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function setOperationAddress(address adr) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(adr) {
		if (_operationAddress == address(0)) {
			grantRole(OPERATION, adr);
		} else {
			revokeRole(OPERATION, _operationAddress);
			grantRole(OPERATION, adr);
		}
		_operationAddress = adr;
	}

	function unsetOperationAddress() external onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(OPERATION, _operationAddress);
		_operationAddress = address(0);
	}

	function setRebaseAddress(address adr) external onlyRole(DEFAULT_ADMIN_ROLE) isValidAddress(adr) {
		_isRebaseUnrestricted = false;

		if (_rebaseAddress == address(0)) {
			grantRole(REBASE, adr);
		} else {
			revokeRole(REBASE, _rebaseAddress);
			grantRole(REBASE, adr);
		}
		_rebaseAddress = adr;
	}

	// DEV func
	function resetStartTime(uint256 startTime, uint80 initialPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_initialPrice = initialPrice;
		_startTime = startTime;
		_lastRebase = startTime;
	}

	function unsetRebaseAddress() external onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(REBASE, _rebaseAddress);
		_rebaseAddress = address(0);
		_isRebaseUnrestricted = true;
	}

	function setPoolAddress(address poolAddress) external isPermitToChange isValidAddress(poolAddress) {
		_poolAddress = poolAddress;
	}

	function setPriceHistoryLength(uint16 len) external isPermitToChange {
		require(len != 0, "must be not 0");
		IUniswapV3Pool(_poolAddress).increaseObservationCardinalityNext(len);
	}

	function setFeeAddress(address feeAddress) external isPermitToChange isValidAddress(feeAddress) {
		_feeAddress = feeAddress;
	}

	function setOwnerOldContractToken(address ownerOldContractToken) external isPermitToChange isValidAddress(ownerOldContractToken) {
		_ownerOldContractToken = ownerOldContractToken;
	}

	function changeWhiteList(address adr, bool flag) external isPermitToChange isValidAddress(adr) {
		require(_isWhiteList[adr] != flag, "Already set");
		_isWhiteList[adr] = flag;
	}

	function setTransferFee(uint8 transferFee) external isValidPercent(transferFee) isPermitToChange {
		_transferFee = transferFee;
	}

	function setFeeFree(uint8 feeFree) external isValidPercent(feeFree) isPermitToChange {
		_feeFree = feeFree;
	}

	function setOperateFee(uint8 operateFee) external isValidPercent(operateFee) isPermitToChange {
		_operateFee = operateFee;
	}

	function setBurnFee(uint8 burnFee) external isValidPercent(burnFee) isPermitToChange {
		_burnFee = burnFee;
	}

	function setFeeDistribAmongOthers(uint8 feeDistrib) external isValidPercent(feeDistrib) isPermitToChange {
		_feeDistribAmongOthers = feeDistrib;
	}

	function setInflactionKoeff(uint80 inflKoef) external isPermitToChange {
		require(inflKoef != 0, "Must be not 0");
		_coeffInflations = inflKoef;
	}

	function setPeriod(uint8 _period) external isPermitToChange {
		require(period > 0, "Period must be positive");
		period = _period;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract CrptERC20 is ERC20 {
	uint8 internal constant DECIMALS = 18;
	uint256 internal constant MAX_UINT256 = type(uint256).max;
	uint256 internal constant INITIAL_FRAGMENTS_SUPPLY = 2 * 10**9 * 10**DECIMALS;

	// TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
	// Use the highest value that fits in a uint256 for max granularity.
	uint256 internal constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
	// MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
	uint256 internal constant MAX_SUPPLY = type(uint128).max; // (2^128) - 1

	// Rate conversion
	uint256 internal _gonsPerFragment;
	uint256 internal _totalSupply;
	// Inner balance
	mapping(address => uint256) internal _gonBalances;

	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

	function decimals() public pure override returns (uint8) {
		return DECIMALS;
	}

	/**
	 * @return The total number of fragments.
	 */
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @param who The address to query.
	 * @return The balance of the specified address.
	 */
	function balanceOf(address who) public view override returns (uint256) {
		return _gonBalances[who] / _gonsPerFragment;
	}

	/**
	 * @param who The address to query.
	 * @return The gon balance of the specified address.
	 */
	function scaledBalanceOf(address who) external view returns (uint256) {
		return _gonBalances[who];
	}

	/**
	 * @return the total number of gons.
	 */
	function scaledTotalSupply() external pure returns (uint256) {
		return TOTAL_GONS;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./CrptERC20.sol";
import "./Control.sol";
import "./libraries/TickMath.sol";
import { BokkyPooBahsDateTimeLibrary as TimeLibrary } from "./libraries/BokkyPooBahsDateTimeLibrary.sol"; // TODO optimise libr
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Cryptium is CrptERC20, Control, ReentrancyGuard {
	address internal immutable _crpto;
	address internal immutable _crptp;

	// Uses for unchange of rate conversion after token burning
	uint256 private _totalMint;
	uint256 private _totalBurn;
	uint256 private _totalFee;

	event Log(string msg, uint256 val1, uint256 val2, uint256 val3, uint256 val4);

	modifier initialized() {
		require(_isInitialized, "Contract must be initialized");
		_;
	}

	struct UserLimit {
		uint128 year;
		uint128 month;
		uint256 monthLimit;
	}

	mapping(address => UserLimit) private _userLimit;

	// This is denominated in Fragments, because the gons-fragments conversion might change before
	// it's fully paid.

	constructor(
		string memory _name,
		string memory _symbol,
		address crpto,
		address crptp
	) CrptERC20(_name, _symbol) {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		require(crpto != address(0) && crptp != address(0), "Address must not be 0");
		_crpto = crpto;
		_crptp = crptp;
		_totalSupply = INITIAL_FRAGMENTS_SUPPLY;
		_gonsPerFragment = TOTAL_GONS / _totalSupply;
		_gonBalances[msg.sender] = TOTAL_GONS;
		_feeAddress = msg.sender;
	}

	/**
	 * @notice Initialize contract once pool is created
	 * @param initialPrice: price from creating with 3 decimals
	 * @param startTime: unix timestamp of starting year of inflations
	 */
	function initializeContract(uint80 initialPrice, uint256 startTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!_isInitialized, "Already initialized");
		_isInitialized = true;
		_initialPrice = initialPrice;
		_startTime = startTime;
		_lastRebase = startTime;
	}

	/**
	 * @notice It allows make swap temporary Cryptium Token to CRPT;
	 * @dev temp token sends to ownerOldContractToken address, new mint to msg.sender; must approve before swap
	 * @param token: address of token
	 * @param amount: amount tokens for swap
	 */
	function swap(address token, uint256 amount) external nonReentrant {
		require(token == _crpto || token == _crptp, "Swapping not CRPTO or CRPTP");
		require(amount != 0, "Not allowed swap 0 token");
		require(_ownerOldContractToken != address(0), "Address must not be '0x0'");
		IERC20 tokenOne = IERC20(token); // 1 for CRPTO; 0 for CRPTP
		_addToken(msg.sender, amount);
		if (_isWhiteList[msg.sender]) {
			_updateLimit(msg.sender);
		}
		require(tokenOne.transferFrom(msg.sender, _ownerOldContractToken, amount), "Cant transfer from");
	}

	/**
	 * @notice External Rebase function which makes inflation rebase or averagePriceFall rebase
	 * @dev Notifies Fragments contract about a new rebase cycle.
	 */
	function rebase() external nonReentrant initialized {
		require(_isRebaseUnrestricted == true || hasRole(REBASE, msg.sender), "Not allowed rebase");
		(uint256 currentSupply, bool isRebase, bool isInflRebase) = _getAvailToClaim();
		require(isRebase, "Rebase is not needed!");
		if (isInflRebase) {
			(uint256 monthsPassAll, ) = _getMonthsPass();
			// _lastRebase = TimeLibrary.addMonths(_startTime, monthsPassAll); // DEV
			_lastRebase = _startTime + monthsPassAll * (3 minutes);
		}
		uint256 supplyDelta = currentSupply - _totalSupply;
		_rebase(supplyDelta);
	}

	/**
	 * @notice View function to check what you can claim
	 * @return
	 */
	function getAvailToClaim(address adr) external view initialized returns (uint256) {
		(uint256 currentSupply, bool isRebase, ) = _getAvailToClaim();
		if (!isRebase) return 0;
		uint256 totalSupply = currentSupply;

		if (totalSupply > MAX_SUPPLY) {
			totalSupply = MAX_SUPPLY;
		}
		uint256 balanceBefore = balanceOf(adr);
		uint256 gonsPerFragment = TOTAL_GONS / (totalSupply + _totalFee + _totalBurn - _totalMint);
		// emit Log("avail to claim", (_gonBalances[adr] / gonsPerFragment) - balanceBefore, 0, 0, 0);
		return (_gonBalances[adr] / gonsPerFragment) - balanceBefore;
	}

	/**
	 * @notice Get what amount user can sell without fee
	 * @param user: address of user
	 * @return limitAvail fee free amount
	 */
	function getFreeToSell(address user) external view initialized returns (uint256 limitAvail) {
		if (_isWhiteList[user]) {
			limitAvail = maxSub((balanceOf(user) * _feeFree) / 100, _userLimit[user].monthLimit);
		} else {
			return balanceOf(user);
		}
	}

	/**
	 * @notice Override transfer function to account for the commission
	 * @param from: address sender
	 * @param to: address recipient
	 * @param value: amount of tokens
	 */
	function _transfer(
		address from,
		address to,
		uint256 value
	) internal override {
		require(to != address(0x0) && to != address(this), "Not valid address");
		require(value != 0, "Value must not be 0");
		uint256 gonValue = value * _gonsPerFragment;

		(uint256 fee, uint256 feeGon) = _feeCount(from, to, value);
		require(gonValue + feeGon <= _gonBalances[from], "Not enough funds");
		if (to == _poolAddress) {
			_userLimit[from].monthLimit = _userLimit[from].monthLimit + (value);
		}
		_gonBalances[from] = _gonBalances[from] - gonValue - feeGon;
		_gonBalances[to] = _gonBalances[to] + (gonValue);

		_feeToOwner(feeGon);
		_feeToBurn(fee);
		_feeToHolders(fee);

		_rebase(0);
		emit Transfer(msg.sender, to, value);
	}

	/**
	 * @notice private function for rebase mechanism
	 * @dev the function takes into account change of totalBurn, totalMint, totalFee
	 * @param supplyDelta: set how much should changes totalSupply
	 */
	function _rebase(uint256 supplyDelta) private {
		_totalSupply = _totalSupply + uint256(supplyDelta);

		if (_totalSupply > MAX_SUPPLY) {
			_totalSupply = MAX_SUPPLY;
		}

		_gonsPerFragment = TOTAL_GONS / (_totalSupply + _totalFee + _totalBurn - _totalMint);
	}

	/**
	 * @notice Add token to user after swap
	 * @param account: address of user whom will mint
	 * @param amount: amount tokens for mint
	 */
	function _addToken(address account, uint256 amount) private {
		_totalMint = _totalMint + amount;
		_gonBalances[account] = _gonBalances[account] + (amount * _gonsPerFragment);
		_totalSupply = _totalSupply + amount;
	}

	/**
	 * @notice Update limit for user from whitelist
	 * @param adr: address of whitelist
	 */
	function _updateLimit(address adr) private {
		(uint256 year, uint256 month, ) = TimeLibrary.timestampToDate(block.timestamp);
		UserLimit storage limit = _userLimit[adr];
		if (limit.year == 0 || limit.year != year || limit.month != month) {
			limit.year = uint16(year);
			limit.month = uint16(month);
			limit.monthLimit = 0;
		}
	}

	/**
	 * @notice Calculates fee
	 * @param from: address sender
	 * @param value: amount of transfer
	 * @return fee in external tokens
	 * @return feeGon in internal tokens
	 */
	function _feeCount(
		address from,
		address to,
		uint256 value
	) private returns (uint256 fee, uint256 feeGon) {
		if (_isWhiteList[from]) {
			_updateLimit(from);
			if (to == _poolAddress) {
				// LimitAvailable = max((0.1 * balanceUser - curLimit),0)
				uint256 limitAvail = maxSub((balanceOf(from) * _feeFree) / 100, _userLimit[from].monthLimit);

				fee = (maxSub(value, limitAvail) * _transferFee) / 100;

				feeGon = fee * _gonsPerFragment;
			}
		}
	}

	/**
	 * @notice Owner fee
	 * @param feeGon: fee for transfer on Gon
	 */
	function _feeToOwner(uint256 feeGon) private {
		_gonBalances[_feeAddress] = _gonBalances[_feeAddress] + ((feeGon * _operateFee) / 100);
	}

	/**
	 * @notice Burn fee
	 * @param fee: fee for transfer
	 */
	function _feeToBurn(uint256 fee) private {
		_totalBurn = _totalBurn + ((fee * _burnFee) / 100);
		_totalSupply = _totalSupply - ((fee * _burnFee) / 100);
	}

	/**
	 * @notice Holders fee
	 * @param fee: fee for transfer
	 */
	function _feeToHolders(uint256 fee) private {
		_totalFee = _totalFee + ((fee * _feeDistribAmongOthers) / 100);
	}

	/**
	 * @notice Return current price
	 * @dev price with 3 decimals
	 * @return current price
	 */
	function _getCurrentPrice() internal view returns (uint256) {
		(uint160 currentPriceSqrt, , , , , , ) = IUniswapV3Pool(_poolAddress).slot0();
		address token0 = IUniswapV3Pool(_poolAddress).token0();
		uint256 currentPrice = (uint256(currentPriceSqrt) * uint256(currentPriceSqrt) * 1000000) >> (96 * 2);

		if (token0 != address(this)) {
			currentPrice = 10000000000 / currentPrice;
		} else {
			currentPrice = currentPrice / 100;
		}
		uint8 decDiff = _getTokenDecimalsDiff();
		currentPrice = currentPrice / (10**decDiff);
		return currentPrice;
	}

	/**
	 * @notice private function to check what you can claim
	 * @dev compare 3 price: current, price which must be base on years inflation and averageDownFall price
	 * @return additional supply needed for rebase
	 * @return true if downfall
	 * @return true if inflation rebase
	 */
	function _getAvailToClaim()
		private
		view
		returns (
			uint256,
			bool,
			bool
		)
	{
		require(_poolAddress != address(0), "Address pool must be set");
		bool isFall = true;
		bool isInflRebase = false;
		uint256 supplyDelta = 0;
		uint256 price1;
		uint256 price2;
		uint256 curPrice = _getCurrentPrice();
		(uint256 monthsPassAll, uint256 monthsPassFromRebase) = _getMonthsPass();

		(uint256 oldPrice, uint256 newPrice) = _getAveragePrices();

		if (newPrice == 0) {
			price1 = 0;
		} else {
			price1 = (curPrice * oldPrice * 100) / newPrice / 100;
		}
		if (monthsPassFromRebase == 0) {
			price2 = 0;
		} else {
			price2 = (_coeffInflations * monthsPassAll * _initialPrice) / 1200 + _initialPrice;
		}

		if (price1 > price2 && price1 > curPrice) {
			supplyDelta = (_totalSupply * ((oldPrice * 1000) / newPrice)) / 1000;
		} else if (price2 > curPrice) {
			price2 = (_coeffInflations * monthsPassFromRebase * _initialPrice) / 1200 + _initialPrice;
			supplyDelta = (_totalSupply * ((price2 * 1000) / curPrice)) / 1000;
			isInflRebase = true;
		} else {
			isFall = false;
		}
		// emit Log("curPrice monthsPassAll monthsPassFromRebase supplyDelta", curPrice, monthsPassAll, monthsPassFromRebase, supplyDelta);
		// emit Log("oldPrice newPrice price1 price2", oldPrice, newPrice, price1, price2);
		return (supplyDelta, isFall, isInflRebase);
	}

	/**
	 * @notice Months pass
	 * @return months pass after startTime or 0 if (> 12 months) or (the rebase was done less than a month ago
	 */
	function _getMonthsPass() private view returns (uint256, uint256) {
		// uint256 monthsPassedAll = TimeLibrary.diffMonths(_startTime, block.timestamp); // DEV
		// uint256 monthsPassedFromLastRebase = TimeLibrary.diffMonths(_lastRebase, block.timestamp);
		uint256 monthsPassedAll = (block.timestamp - _startTime) / (3 minutes);
		uint256 monthsPassedFromLastRebase = (block.timestamp - _lastRebase) / (3 minutes);
		if (monthsPassedAll <= 12 && monthsPassedFromLastRebase > 0) {
			return (monthsPassedAll, monthsPassedFromLastRebase);
		} else {
			return (0, 0);
		}
	}

	/**
	 * @notice Return two average price
	 * @dev takes in account that price changes below 10% is not serious
	 * @return oldPrice: price for the period up to or 0 if there was no price drop
	 * @return newPrice: price for current period or 0 if there was no price drop
	 */
	function _getAveragePrices() private view returns (uint256, uint256) {
		(uint256 oldPrice, uint256 newPrice) = _getTWAT();

		bool isDownFallBool = newPrice < (oldPrice * 9) / 10;
		if (isDownFallBool) {
			return (oldPrice, newPrice);
		} else {
			return (0, 0);
		}
	}

	/**
	 * @notice Get time weight average price
	 * @return oldPrice
	 * @return newPrice
	 */
	function _getTWAT() private view returns (uint256 oldPrice, uint256 newPrice) {
		uint32 valueCount = 3;
		uint32[] memory secondAgos = new uint32[](valueCount);
		secondAgos[2] = (2 * period > block.timestamp - _startTime) ? uint32(block.timestamp - _startTime) : 2 * period;
		secondAgos[1] = (period > block.timestamp - _startTime) ? uint32(block.timestamp - _startTime) : period;
		secondAgos[0] = 0;

		(int56[] memory tickCumulatives, ) = IUniswapV3Pool(_poolAddress).observe(secondAgos);
		uint8 decDiff = _getTokenDecimalsDiff();
		return _getPrice(tickCumulatives, period, decDiff);
	}

	/**
	 * @notice Get two average price based on 3 tickCumulatives value
	 * @param tickCumulatives: tick which uniswap returs instead of price
	 * @param period: period in sec
	 * @param decDiff: difference in decimals between tokens
	 * @return oldPrice price for prev perio
	 * @return newPrice price last period
	 */
	function _getPrice(
		int56[] memory tickCumulatives,
		uint32 period,
		uint8 decDiff
	) internal view returns (uint256 oldPrice, uint256 newPrice) {
		int56 oldValue = (tickCumulatives[1] - tickCumulatives[2]) / int32(period);
		int56 newValue = (tickCumulatives[0] - tickCumulatives[1]) / int32(period);
		uint160 oldSqrtPrice = TickMath.getSqrtRatioAtTick(int24(oldValue));
		uint160 newSqrtPrice = TickMath.getSqrtRatioAtTick(int24(newValue));
		oldPrice = (uint256(oldSqrtPrice) * uint256(oldSqrtPrice) * 1000000) >> (96 * 2);
		newPrice = (uint256(newSqrtPrice) * uint256(newSqrtPrice) * 1000000) >> (96 * 2);
		address token0 = IUniswapV3Pool(_poolAddress).token0();
		if (token0 != address(this)) {
			oldPrice = 10000000000 / oldPrice;
			newPrice = 10000000000 / newPrice;
		} else {
			oldPrice = oldPrice / 100;
			newPrice = newPrice / 100;
		}
		oldPrice = oldPrice / (10**decDiff);
		newPrice = newPrice / (10**decDiff);
	}

	/**
	 * @notice Calculate difference in decimals between tokens
	 * @return decDiffUnsign
	 */
	function _getTokenDecimalsDiff() private view returns (uint8 decDiffUnsign) {
		uint8 dec1 = IERC20Metadata(IUniswapV3Pool(_poolAddress).token0()).decimals();
		uint8 dec2 = IERC20Metadata(IUniswapV3Pool(_poolAddress).token1()).decimals();
		int8 decDiff = int8(dec1) - int8(dec2);
		decDiff = (decDiff < 0) ? (-1 * decDiff) : decDiff;
		decDiffUnsign = uint8(decDiff);
	}

	/**
	 * @notice |left - right|
	 * @param left: first var
	 * @param right: second var
	 * @return modulo of subtraction
	 */
	function maxSub(uint256 left, uint256 right) private pure returns (uint256) {
		int256 res = int256(left) - int256(right);
		if (res < 0) res = 0;
		return uint256(res);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IUniswapV3Pool {
	function slot0()
		external
		view
		returns (
			uint160 sqrtPriceX96,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			uint16 observationCardinalityNext,
			uint8 feeProtocol,
			bool unlocked
		);

	function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

	function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

	function token0() external view returns (address);

	function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
	uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
	uint256 constant SECONDS_PER_HOUR = 60 * 60;
	uint256 constant SECONDS_PER_MINUTE = 60;
	int256 constant OFFSET19700101 = 2440588;

	uint256 constant DOW_MON = 1;
	uint256 constant DOW_TUE = 2;
	uint256 constant DOW_WED = 3;
	uint256 constant DOW_THU = 4;
	uint256 constant DOW_FRI = 5;
	uint256 constant DOW_SAT = 6;
	uint256 constant DOW_SUN = 7;

	// ------------------------------------------------------------------------
	// Calculate the number of days from 1970/01/01 to year/month/day using
	// the date conversion algorithm from
	//   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
	// and subtracting the offset 2440588 so that 1970/01/01 is day 0
	//
	// days = day
	//      - 32075
	//      + 1461 * (year + 4800 + (month - 14) / 12) / 4
	//      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
	//      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
	//      - offset
	// ------------------------------------------------------------------------
	function _daysFromDate(
		uint256 year,
		uint256 month,
		uint256 day
	) internal pure returns (uint256 _days) {
		require(year >= 1970);
		int256 _year = int256(year);
		int256 _month = int256(month);
		int256 _day = int256(day);

		int256 __days = _day -
			32075 +
			(1461 * (_year + 4800 + (_month - 14) / 12)) /
			4 +
			(367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
			12 -
			(3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
			4 -
			OFFSET19700101;

		_days = uint256(__days);
	}

	// ------------------------------------------------------------------------
	// Calculate year/month/day from the number of days since 1970/01/01 using
	// the date conversion algorithm from
	//   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
	// and adding the offset 2440588 so that 1970/01/01 is day 0
	//
	// int L = days + 68569 + offset
	// int N = 4 * L / 146097
	// L = L - (146097 * N + 3) / 4
	// year = 4000 * (L + 1) / 1461001
	// L = L - 1461 * year / 4 + 31
	// month = 80 * L / 2447
	// dd = L - 2447 * month / 80
	// L = month / 11
	// month = month + 2 - 12 * L
	// year = 100 * (N - 49) + year + L
	// ------------------------------------------------------------------------
	function _daysToDate(uint256 _days)
		internal
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day
		)
	{
		int256 __days = int256(_days);

		int256 L = __days + 68569 + OFFSET19700101;
		int256 N = (4 * L) / 146097;
		L = L - (146097 * N + 3) / 4;
		int256 _year = (4000 * (L + 1)) / 1461001;
		L = L - (1461 * _year) / 4 + 31;
		int256 _month = (80 * L) / 2447;
		int256 _day = L - (2447 * _month) / 80;
		L = _month / 11;
		_month = _month + 2 - 12 * L;
		_year = 100 * (N - 49) + _year + L;

		year = uint256(_year);
		month = uint256(_month);
		day = uint256(_day);
	}

	function timestampFromDate(
		uint256 year,
		uint256 month,
		uint256 day
	) internal pure returns (uint256 timestamp) {
		timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
	}

	function timestampFromDateTime(
		uint256 year,
		uint256 month,
		uint256 day,
		uint256 hour,
		uint256 minute,
		uint256 second
	) internal pure returns (uint256 timestamp) {
		timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
	}

	function timestampToDate(uint256 timestamp)
		internal
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day
		)
	{
		(year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
	}

	function timestampToDateTime(uint256 timestamp)
		internal
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day,
			uint256 hour,
			uint256 minute,
			uint256 second
		)
	{
		(year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
		uint256 secs = timestamp % SECONDS_PER_DAY;
		hour = secs / SECONDS_PER_HOUR;
		secs = secs % SECONDS_PER_HOUR;
		minute = secs / SECONDS_PER_MINUTE;
		second = secs % SECONDS_PER_MINUTE;
	}

	function isValidDate(
		uint256 year,
		uint256 month,
		uint256 day
	) internal pure returns (bool valid) {
		if (year >= 1970 && month > 0 && month <= 12) {
			uint256 daysInMonth = _getDaysInMonth(year, month);
			if (day > 0 && day <= daysInMonth) {
				valid = true;
			}
		}
	}

	function isValidDateTime(
		uint256 year,
		uint256 month,
		uint256 day,
		uint256 hour,
		uint256 minute,
		uint256 second
	) internal pure returns (bool valid) {
		if (isValidDate(year, month, day)) {
			if (hour < 24 && minute < 60 && second < 60) {
				valid = true;
			}
		}
	}

	function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
		(uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
		leapYear = _isLeapYear(year);
	}

	function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
		leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
	}

	function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
		weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
	}

	function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
		weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
	}

	function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
		(uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
		daysInMonth = _getDaysInMonth(year, month);
	}

	function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
		if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
			daysInMonth = 31;
		} else if (month != 2) {
			daysInMonth = 30;
		} else {
			daysInMonth = _isLeapYear(year) ? 29 : 28;
		}
	}

	// 1 = Monday, 7 = Sunday
	function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
		uint256 _days = timestamp / SECONDS_PER_DAY;
		dayOfWeek = ((_days + 3) % 7) + 1;
	}

	function getYear(uint256 timestamp) internal pure returns (uint256 year) {
		(year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
	}

	function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
		(, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
	}

	function getDay(uint256 timestamp) internal pure returns (uint256 day) {
		(, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
	}

	function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
		uint256 secs = timestamp % SECONDS_PER_DAY;
		hour = secs / SECONDS_PER_HOUR;
	}

	function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
		uint256 secs = timestamp % SECONDS_PER_HOUR;
		minute = secs / SECONDS_PER_MINUTE;
	}

	function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
		second = timestamp % SECONDS_PER_MINUTE;
	}

	function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
		(uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
		year += _years;
		uint256 daysInMonth = _getDaysInMonth(year, month);
		if (day > daysInMonth) {
			day = daysInMonth;
		}
		newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
		require(newTimestamp >= timestamp);
	}

	function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
		(uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
		month += _months;
		year += (month - 1) / 12;
		month = ((month - 1) % 12) + 1;
		uint256 daysInMonth = _getDaysInMonth(year, month);
		if (day > daysInMonth) {
			day = daysInMonth;
		}
		newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
		require(newTimestamp >= timestamp);
	}

	function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp + _days * SECONDS_PER_DAY;
		require(newTimestamp >= timestamp);
	}

	function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
		require(newTimestamp >= timestamp);
	}

	function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
		require(newTimestamp >= timestamp);
	}

	function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp + _seconds;
		require(newTimestamp >= timestamp);
	}

	function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
		(uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
		year -= _years;
		uint256 daysInMonth = _getDaysInMonth(year, month);
		if (day > daysInMonth) {
			day = daysInMonth;
		}
		newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
		require(newTimestamp <= timestamp);
	}

	function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
		(uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
		uint256 yearMonth = year * 12 + (month - 1) - _months;
		year = yearMonth / 12;
		month = (yearMonth % 12) + 1;
		uint256 daysInMonth = _getDaysInMonth(year, month);
		if (day > daysInMonth) {
			day = daysInMonth;
		}
		newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
		require(newTimestamp <= timestamp);
	}

	function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp - _days * SECONDS_PER_DAY;
		require(newTimestamp <= timestamp);
	}

	function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
		require(newTimestamp <= timestamp);
	}

	function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
		require(newTimestamp <= timestamp);
	}

	function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp - _seconds;
		require(newTimestamp <= timestamp);
	}

	function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
		require(fromTimestamp <= toTimestamp);
		(uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
		(uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
		_years = toYear - fromYear;
	}

	function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
		require(fromTimestamp <= toTimestamp);
		(uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
		(uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
		_months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
	}

	function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
		require(fromTimestamp <= toTimestamp);
		_days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
	}

	function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
		require(fromTimestamp <= toTimestamp);
		_hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
	}

	function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
		require(fromTimestamp <= toTimestamp);
		_minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
	}

	function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
		require(fromTimestamp <= toTimestamp);
		_seconds = toTimestamp - fromTimestamp;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.6;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
	/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
	int24 internal constant MIN_TICK = -887272;
	/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
	int24 internal constant MAX_TICK = -MIN_TICK;

	/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	/// @notice Calculates sqrt(1.0001^tick) * 2^96
	/// @dev Throws if |tick| > max tick
	/// @param tick The input tick for the above formula
	/// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
	/// at the given tick
	function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
		require(absTick <= 887272, "T");

		uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
		if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
		if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
		if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
		if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
		if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
		if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
		if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
		if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
		if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
		if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
		if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
		if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
		if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
		if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
		if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
		if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
		if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
		if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
		if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

		if (tick > 0) ratio = type(uint256).max / ratio;

		// this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
		// we then downcast because we know the result always fits within 160 bits due to our tick input constraint
		// we round up in the division so getTickAtSqrtRatio of the output price is always consistent
		sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

