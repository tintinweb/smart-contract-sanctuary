// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./pancake-swap/libraries/TransferHelper.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";
import { BokkyPooBahsDateTimeLibrary as TimeLibrary } from "./libraries/BokkyPooBahsDateTimeLibrary.sol";
import "./TokenERC20.sol";
import "./Control.sol";

contract Token is TokenERC20, Control, ReentrancyGuard {
	IUniswapV2Router public immutable dexRouter;
	address public immutable dexFactory;

	uint256 public currentPrice;
	uint256 public averagePrice1;
	uint256 public averagePrice2;
	uint256 public timestamp;

	uint256 private _totalBurn;
	uint256 private _totalFee;

	bool private _inSwap;

	mapping(address => UserLimit) private _userLimit;

	struct UserLimit {
		uint128 year;
		uint128 month;
		uint256 monthLimit;
	}

	modifier initialized() {
		require(_isInitialized, "Contract must be initialized");
		_;
	}

	modifier lockTheSwap() {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	event Rebase(uint256 newTotalSupply, uint256 previousTotalSupply, bool isInflationRebase);
	event Log(string msg, uint256 val1, uint256 val2, uint256 val3);

	// This is denominated in Fragments, because the gons-fragments conversion might change before
	// it's fully paid.
	constructor(
		string memory _name,
		string memory _symbol,
		IUniswapV2Router _dexRouter,
		address _dexFactory
	) TokenERC20(_name, _symbol) {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		dexRouter = _dexRouter;
		dexFactory = _dexFactory;
		_totalSupply = INITIAL_FRAGMENTS_SUPPLY;
		_gonsPerFragment = TOTAL_GONS / _totalSupply;
		_gonBalances[msg.sender] = TOTAL_GONS;
		feeAddress = msg.sender;
	}

	/**
	 * @notice Initialize contract once pool is created
	 * @param _startTime: unix timestamp of starting year of inflations
	 * @param _initialPrice: price with 18 decimals
	 */
	function initializeContract(uint256 _startTime, uint256 _initialPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!_isInitialized, "Already initialized");
		_isInitialized = true;
		startTime = _startTime;
		lastRebase = _startTime;
		initialPrice = _initialPrice;
	}

	/**
	 * @notice External Rebase function which makes inflation rebase or averagePriceFall rebase
	 * @dev Notifies Fragments contract about a new rebase cycle.
	 */
	function rebase() external initialized {
		(uint256 currentSupply, bool isRebase, bool isInflRebase) = _getAvailToClaim();
		require(isRebase, "Rebase is not needed!");
		if (isInflRebase) {
			(, uint256 daysPassFromRebase) = _getDaysPass();
			lastRebase = TimeLibrary.addDays(lastRebase, daysPassFromRebase);
		}
		uint256 supplyDelta = currentSupply - _totalSupply;
		_rebase(supplyDelta);
		emit Rebase(supplyDelta, _totalSupply, isInflRebase);
	}

	/**
	 * @notice Function for writing price from back
	 * @param _currentPrice: current price
	 * @param _averagePrice1: previos average price
	 * @param _averagePrice2: current average price
	 * @param _timestamp: timestamp that use for asserting that price updates not long ago
	 */
	function writeData(
		uint256 _currentPrice,
		uint256 _averagePrice1,
		uint256 _averagePrice2,
		uint256 _timestamp
	) external {
		currentPrice = _currentPrice;
		averagePrice1 = _averagePrice1;
		averagePrice2 = _averagePrice2;
		timestamp = _timestamp;
	}

	/**
	 * @notice Adding liquidity without fee
	 * @dev Public payable function for adding liquidity in TKN-ETH pair without fee
	 * @param tokenAmount: token amount
	 * @param amountTokenMin:  min token amount going to pool
	 * @param amountETHMin: min ETH amount going to pool
	 * @param to address for LP-tokens
	 */
	function noFeeAddLiquidityETH(
		uint256 tokenAmount,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to
	) external payable lockTheSwap nonReentrant {
		require(msg.value > 0 && tokenAmount > 0, "ZERO");
		TransferHelper.safeTransferFrom(address(this), _msgSender(), address(this), tokenAmount);
		_approve(address(this), address(dexRouter), tokenAmount);
		(uint256 token, uint256 eth, ) = dexRouter.addLiquidityETH{ value: msg.value }(address(this), tokenAmount, amountTokenMin, amountETHMin, to, block.timestamp);
		if (tokenAmount > token) TransferHelper.safeTransfer(address(this), _msgSender(), tokenAmount - token);
		if (msg.value > eth) payable(_msgSender()).transfer(msg.value - eth);
	}

	/**
	 * @notice Adding liquidity without fee
	 * @dev Public payable function for adding liquidity in TKN-<TOKEN> pair without fee
	 * @param token1 another token address
	 * @param tokenAmount0 TKN token amount
	 * @param tokenAmount1 another token amount
	 * @param amountToken0Min min TKN amount going to pool
	 * @param amountToken0Min min <TOKEN> amount going to pool
	 * @param to address for LP-tokens
	 */
	function noFeeAddLiquidity(
		address token1,
		uint256 tokenAmount0,
		uint256 tokenAmount1,
		uint256 amountToken0Min,
		uint256 amountToken1Min,
		address to
	) external lockTheSwap nonReentrant {
		require(tokenAmount0 > 0 && tokenAmount1 > 0, "ZERO");
		require(token1 != address(this) && token1 != address(0), "INVALID ADDRESSES");
		TransferHelper.safeTransferFrom(address(this), _msgSender(), address(this), tokenAmount0);
		_approve(address(this), address(dexRouter), tokenAmount0);
		TransferHelper.safeTransferFrom(token1, _msgSender(), address(this), tokenAmount1);
		TransferHelper.safeApprove(token1, address(dexRouter), tokenAmount1);
		(uint256 finalToken0, uint256 finalToken1, ) = dexRouter.addLiquidity(
			address(this),
			token1,
			tokenAmount0,
			tokenAmount1,
			amountToken0Min,
			amountToken1Min,
			to,
			block.timestamp
		);

		if (finalToken0 < tokenAmount0) TransferHelper.safeTransfer(address(this), _msgSender(), tokenAmount0 - finalToken0);

		if (finalToken1 < tokenAmount1) TransferHelper.safeTransfer(token1, _msgSender(), tokenAmount1 - finalToken1);
	}

	/**
	 * @notice Remove liquidity
	 * @dev Public function for removing liquidity from TKN-ETH pair without fee
	 * @param liquidity LP-token amount to burn
	 * @param amountTokenMin min sBomb amount going to user
	 * @param amountETHMin min ETH amount going to user
	 * @param to address for ETH & TKN
	 */
	function noFeeRemoveLiquidityETH(
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to
	) external lockTheSwap nonReentrant {
		require(liquidity > 0, "ZERO");
		address pair = IUniswapV2Factory(dexRouter.factory()).getPair(address(this), dexRouter.WETH());
		require(pair != address(0), "INVALID PAIR");
		TransferHelper.safeTransferFrom(pair, _msgSender(), address(this), liquidity);
		IERC20(pair).approve(address(dexRouter), liquidity);
		dexRouter.removeLiquidityETH(address(this), liquidity, amountTokenMin, amountETHMin, to, block.timestamp);
	}

	/**
	 * @notice Remove liquidity
	 * @dev Public function for removing liquidity from SBOMB-<TOKEN> pair without 6% fee
	 * @param token1 another token address
	 * @param liquidity LP-token amount
	 * @param amount0Min min sBomb amount going to user
	 * @param amount1Min min <TOKEN> amount going to user
	 * @param to address for <TOKEN> & SBOMB
	 */
	function noFeeRemoveLiquidity(
		address token1,
		uint256 liquidity,
		uint256 amount0Min,
		uint256 amount1Min,
		address to
	) external lockTheSwap nonReentrant {
		require(liquidity > 0, "ZERO");
		address pair = IUniswapV2Factory(dexRouter.factory()).getPair(address(this), address(token1));
		require(pair != address(0), "INVALID PAIR");
		TransferHelper.safeTransferFrom(pair, _msgSender(), address(this), liquidity);
		IERC20(pair).approve(address(dexRouter), liquidity);
		dexRouter.removeLiquidity(address(this), token1, liquidity, amount0Min, amount1Min, to, block.timestamp);
	}

	/**
	 * @notice View function to check what you can claim
	 * @param user: address of user
	 * @return how much user can claim after rebase
	 */
	function getAvailToClaim(address user) external view initialized returns (uint256) {
		(uint256 currentSupply, bool isRebase, ) = _getAvailToClaim();
		if (!isRebase) return 0;
		uint256 totalSupply = currentSupply;

		if (totalSupply > MAX_SUPPLY) {
			totalSupply = MAX_SUPPLY;
		}
		uint256 balanceBefore = balanceOf(user);
		uint256 gonsPerFragment = TOTAL_GONS / (totalSupply + _totalFee + _totalBurn);
		return (_gonBalances[user] / gonsPerFragment) - balanceBefore;
	}

	/**
	 * @notice Get what amount user can sell without fee
	 * @param user: address of user
	 * @return limitAvail fee free amount
	 */
	function getFreeToSell(address user) external view initialized returns (uint256 limitAvail) {
		limitAvail = _maxSub((balanceOf(user) * feeFree) / 100, _userLimit[user].monthLimit);
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
		require(to != address(0x0), "Not valid address");
		require(value != 0, "Value must not be 0");
		uint256 gonValue = value * _gonsPerFragment;
		uint256 fee;
		uint256 feeGon;
		if (_isDexAddress(to) && !_inSwap) {
			(fee, feeGon) = _feeCount(from, value);

			require(gonValue + feeGon <= _gonBalances[from], "Not enough funds");
			_feeToOwner(feeGon);
			_feeToBurn(fee);
			_feeToHolders(fee);
			_userLimit[from].monthLimit = _userLimit[from].monthLimit + (value);
		}
		_gonBalances[from] = _gonBalances[from] - gonValue - feeGon;
		_gonBalances[to] = _gonBalances[to] + (gonValue);

		_rebase(0);
		emit Transfer(msg.sender, to, value);
	}

	/**
	 * @notice private function for rebase mechanism
	 * @dev the function takes into account change of totalBurn, totalFee
	 * @param supplyDelta: set how much should changes totalSupply
	 */
	function _rebase(uint256 supplyDelta) private {
		_totalSupply = (_totalSupply + supplyDelta > MAX_SUPPLY) ? MAX_SUPPLY : _totalSupply + supplyDelta;

		_gonsPerFragment = TOTAL_GONS / (_totalSupply + _totalFee + _totalBurn);
	}

	/**
	 * @notice Update limit for user
	 * @param user: address user
	 */
	function _updateLimit(address user) private {
		(uint256 year, uint256 month, ) = TimeLibrary.timestampToDate(block.timestamp);
		UserLimit storage limit = _userLimit[user];
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
	function _feeCount(address from, uint256 value) private returns (uint256 fee, uint256 feeGon) {
		_updateLimit(from);

		// LimitAvailable = max((0.1 * balanceUser - curLimit),0)
		uint256 limitAvail = _maxSub((balanceOf(from) * feeFree) / 100, _userLimit[from].monthLimit);

		fee = (_maxSub(value, limitAvail) * transferFee) / 100;

		feeGon = fee * _gonsPerFragment;
	}

	/**
	 * @notice Owner fee
	 * @param feeGon: fee for transfer on Gon
	 */
	function _feeToOwner(uint256 feeGon) private {
		_gonBalances[feeAddress] = _gonBalances[feeAddress] + ((feeGon * operateFee) / 100);
	}

	/**
	 * @notice Burn fee
	 * @param fee: fee for transfer
	 */
	function _feeToBurn(uint256 fee) private {
		_totalBurn = _totalBurn + ((fee * burnFee) / 100);
		_totalSupply = _totalSupply - ((fee * burnFee) / 100);
	}

	/**
	 * @notice Holders fee
	 * @param fee: fee for transfer
	 */
	function _feeToHolders(uint256 fee) private {
		_totalFee = _totalFee + ((fee * holderFee) / 100);
	}

	/**
	 * @notice Function to check what you can claim
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
		require(block.timestamp - timestamp <= time, "Cant access recent price");
		bool isFall = true;
		bool isInflRebase = false;
		uint256 supplyDelta;
		uint256 price1;
		uint256 price2;
		uint256 curPrice = currentPrice;
		(uint256 daysPassAll, uint256 daysPassFromRebase) = _getDaysPass();

		(uint256 oldPrice, uint256 newPrice) = (averagePrice1, averagePrice2);

		if (newPrice < (oldPrice * 99) / 100) {
			price1 = (curPrice * oldPrice) / newPrice; // 18
		} else {
			price1 = 0;
		}
		if (daysPassFromRebase == 0) {
			price2 = 0;
		} else {
			price2 = (((coeffInflations * daysPassAll * 10000) / 365 + 1e8) * initialPrice) / 1e8; // 18
		}
		if (price1 > price2 && price1 > curPrice) {
			supplyDelta = ((_totalSupply * oldPrice) / newPrice); // 0
		} else if (price2 > curPrice) {
			price2 = (((coeffInflations * daysPassFromRebase * 10000) / 365 + 1e8) * initialPrice) / 1e8; // 18
			supplyDelta = ((_totalSupply * price2) / curPrice);
			isInflRebase = true;
		} else {
			isFall = false;
		}
		return (supplyDelta, isFall, isInflRebase);
	}

	function _getDaysPass() private view returns (uint256, uint256) {
		uint256 daysPassAll = TimeLibrary.diffDays(startTime, block.timestamp);
		uint256 daysPassFromRebase = TimeLibrary.diffDays(lastRebase, block.timestamp);
		if (daysPassAll <= 365 && daysPassFromRebase > 0) {
			return (daysPassAll, daysPassFromRebase);
		} else {
			return (0, 0);
		}
	}

	function _isContract(address addr) private view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(addr)
		}
		return size > 0;
	}

	function _isDexAddress(address destination) private view returns (bool) {
		if (!_isContract(destination)) return false;
		address token0;
		try IUniswapV2Pair(destination).token0() returns (address _token0) {
			token0 = _token0;
		} catch (bytes memory) {
			return false;
		}

		address token1;
		try IUniswapV2Pair(destination).token1() returns (address _token1) {
			token1 = _token1;
		} catch (bytes memory) {
			return false;
		}

		address goodPair = IUniswapV2Factory(dexFactory).getPair(token0, token1);
		if (goodPair != destination) {
			return false;
		}

		if (token0 != address(this) && token1 != address(this)) {
			return false;
		}

		return true;
	}

	/**
	 * @notice |left - right|
	 * @param left: first var
	 * @param right: second var
	 * @return modulo of subtraction
	 */
	function _maxSub(uint256 left, uint256 right) private pure returns (uint256) {
		int256 res = int256(left) - int256(right);
		if (res < 0) res = 0;
		return uint256(res);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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

	// uint256 constant SECONDS_PER_DAY = 180;
	// uint256 constant SECONDS_PER_HOUR = 60;
	// uint256 constant SECONDS_PER_MINUTE = 1;
	// int256 constant OFFSET19700101 = 2440588;

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

	function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
		newTimestamp = timestamp + _days * SECONDS_PER_DAY;
		require(newTimestamp >= timestamp);
	}

	function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
		require(fromTimestamp <= toTimestamp);
		_days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Router {
	function WETH() external view returns (address);

	function factory() external pure returns (address);

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

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Pair {
	function token0() external view returns (address);

	function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Factory {
	function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract TokenERC20 is ERC20 {
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
	 * @return Token decimals.
	 */
	function decimals() public pure override returns (uint8) {
		return DECIMALS;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Control is AccessControl {
	bytes32 public constant MANAGER = keccak256("manager");

	address public feeAddress;
	uint256 public startTime;
	uint256 public lastRebase;

	uint8 public transferFee = 50;
	uint8 public feeFree = 10;
	uint8 public operateFee = 10;
	uint8 public burnFee = 10;
	uint8 public holderFee = 80;
	uint16 public time = 3600;
	uint32 public coeffInflations = 1200; // coeff with 2 decimals
	uint256 public initialPrice;
	bool internal _isInitialized;

	modifier isValidPercent(uint256 percent) {
		require(percent >= 0 && percent <= 100, "Not valid value");
		_;
	}

	modifier isPermitToChange() {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MANAGER, msg.sender), "You not allowed");
		_;
	}

	modifier isValidAddress(address adr) {
		require(adr != address(0), "Address must not be '0x0'");
		_;
	}

	/**
	 * @notice Set address which will receive fee
	 * @param _feeAddress: fee address
	 */
	function setFeeAddress(address _feeAddress) external isPermitToChange isValidAddress(_feeAddress) {
		feeAddress = _feeAddress;
	}

	/**
	 * @notice Set time which will price from oracle counts valid
	 * @param _time: time in seconds
	 */
	function setTime(uint16 _time) external isPermitToChange {
		time = _time;
	}

	/**
	 * @notice Set percentages which takes from any transfer to dex pools
	 * @param _transferFee: number in range [0,100]
	 */
	function setTransferFee(uint8 _transferFee) external isValidPercent(_transferFee) isPermitToChange {
		transferFee = _transferFee;
	}

	/**
	 * @notice Set percentages which user can sold monthly without fee
	 * @param _feeFree: number in range [0,100]
	 */
	function setFeeFree(uint8 _feeFree) external isValidPercent(_feeFree) isPermitToChange {
		feeFree = _feeFree;
	}

	/**
	 * @notice Set distribution in percentages of fee that takes from sold
	 * @dev burn fee will calculate as 100 - operateFee - holderFee
	 * @param _operateFee: fee to operation address in range [0,100]
	 * @param _holderFee: fee to all holders in range [0,100]
	 */
	function setFee(uint8 _operateFee, uint8 _holderFee) external isValidPercent(_operateFee) isValidPercent(_holderFee) isPermitToChange {
		require(_operateFee + _holderFee <= 100, "Fee sum must below 0");
		operateFee = _operateFee;
		holderFee = _holderFee;
		burnFee = 100 - _operateFee - _holderFee;
	}

	/**
	 * @notice Set rate of inflation for estimate price
	 * @param inflKoef: rate of inflation with two decimals
	 */
	function setInflactionKoeff(uint32 inflKoef) external isPermitToChange {
		require(inflKoef != 0, "Must be not 0");
		coeffInflations = inflKoef;
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

/**
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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