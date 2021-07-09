// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./BlackSwanERC20.sol";
import "./BlackSwanFund.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeMathInt.sol";
import "./AddressBook.sol";

interface ILiquidityOracle {
	function getData() external returns (uint256, bool);

	function getUsdcVolume() external view returns (uint256);
}

contract BlackSwanPolicy is OwnableUpgradeable {
	using SafeMath for uint256;
	using SafeMathInt for int256;
	event LogRebalance(
		uint256 indexed epoch,
		uint256 supplyDelta,
		uint256 timestampSec
	);
	//AddressBook to get addresses
	AddressBook public addressBook;

	//Store rebalance datas
	struct RebalanceData {
		uint256 timestamp;
		uint256 liquidityPercentage;
	}
	mapping(uint256 => RebalanceData) public rebalanceDatas;
	// The number of rebalance cycles since inception
	uint256 public epoch;
	// Target Equilibrium for liquidity
	int256 public liquidityTargetEquilibrium;

	//Below equilibrium buffer level
	uint256 public bufferZone;

	// More than this much time must pass between rebase operations.
	uint256 public minRebalanceTimeIntervalSec;

	// Block timestamp of last rebase operation
	uint256 public lastRebalanceTimestampSec;

	// The rebalance window begins this many seconds into the minRebaseTimeInterval period.
	// For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
	uint256 public rebalanceWindowOffsetSec;

	// The length of the time window where a rebase operation is allowed to execute, in seconds.
	uint256 public rebalanceWindowLengthSec;

	// Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
	// Both are 18 decimals fixed point numbers.

	// MAX_SUPPLY = MAX_INT256
	uint256 private constant MAX_SUPPLY = type(uint256).max;

	constructor(int256 _liquidityTargetEquilibrium, AddressBook _addressBook)
		public
	{
		__Ownable_init();
		addressBook = _addressBook;
		liquidityTargetEquilibrium = _liquidityTargetEquilibrium;
		epoch = 0;
		bufferZone = 75;
		minRebalanceTimeIntervalSec = 1 days;
		rebalanceWindowOffsetSec = 85440; // 11:44PM UTC
		rebalanceWindowLengthSec = 16 minutes; // offset until midnight
	}

	modifier onlyOrchestrator() {
		require(
			_msgSender() == addressBook.getAddress("ORCHESTRATOR"),
			"Only Orchestrator can call this method"
		);
		_;
	}

	function rebalance() external onlyOrchestrator {
		require(inRebalanceWindow(), "Not in rebalance window");
		require(
			lastRebalanceTimestampSec.add(minRebalanceTimeIntervalSec) <=
				block.timestamp,
			"Min rebalance time should pass since last rebalance"
		);
		BlackSwanERC20 blackSwan =
			BlackSwanERC20(addressBook.getAddress("BLACKSWAN"));
		ILiquidityOracle liquidityOracle =
			ILiquidityOracle(addressBook.getAddress("LIQUIDITY_ORACLE"));
		(uint256 liquidityVolume, bool volumeValid) = liquidityOracle.getData();
		require(volumeValid);
		epoch = epoch + 1;
		uint256 currentSupply = blackSwan.totalSupply();
		uint256 liquidityPercentage =
			(liquidityVolume * 100 * 1e18) / (currentSupply);
		int256 liquidityDifference =
			int256(liquidityPercentage) - liquidityTargetEquilibrium;
		RebalanceData memory currentData =
			RebalanceData(block.timestamp, liquidityPercentage);
		rebalanceDatas[epoch] = currentData;

		if (liquidityDifference > 0) {
			int256 liquidityIntDifference =
				int256(liquidityDifference) / int256(10);
			uint256 supplyDelta =
				(currentSupply * uint256(liquidityIntDifference)) /
					(100 * 1e18);

			uint256 newTotalSupply =
				blackSwan.rebalance(epoch, supplyDelta, true);
			uint256 stableCoinVolume = liquidityOracle.getUsdcVolume();
			// When it's above equilibrium sell for 0.5% of usdc
			uint256 usdcAmount = (500 * stableCoinVolume) / 100000;
			BlackSwanFund(addressBook.getAddress("FUND_ADDRESS"))
				.swapSwanToUsdc(usdcAmount);

			assert(newTotalSupply <= MAX_SUPPLY);
			emit LogRebalance(epoch, supplyDelta, block.timestamp);
		} else if (liquidityDifference < 0) {
			int256 liquidityIntDifference =
				int256(liquidityDifference.abs()) / int256(10);
			uint256 supplyDelta =
				(currentSupply * uint256(liquidityIntDifference)) /
					(100 * 1e18);

			blackSwan.rebalance(epoch, 0, false);
			if (
				int256(liquidityPercentage) <
				(liquidityTargetEquilibrium * int256(bufferZone)) / 100
			) {
				BlackSwanFund(addressBook.getAddress("FUND_ADDRESS"))
					.provideLiquidity();
			}

			emit LogRebalance(epoch, supplyDelta, block.timestamp);
		}
		lastRebalanceTimestampSec = block.timestamp;
		setLiquidityEquilibrium(liquidityDifference > 0 ? true : false);
	}

	/**
	 * @return If the latest block timestamp is within the rebalance time window it, returns true.
	 *         Otherwise, returns false.
	 */
	function inRebalanceWindow() public view returns (bool) {
		return (block.timestamp.mod(minRebalanceTimeIntervalSec) >=
			rebalanceWindowOffsetSec &&
			block.timestamp.mod(minRebalanceTimeIntervalSec) <
			(rebalanceWindowOffsetSec.add(rebalanceWindowLengthSec)));
	}

	/**
	 * @dev Set liquidity target for equilibrium calculations
	 */
	function setLiquidityTarget(int256 _newTarget) external onlyOwner {
		require(_newTarget > 0);
		liquidityTargetEquilibrium = _newTarget;
	}

	/**
    @dev Set liquidity equilibrium dynamically according last 30 rebalance liquidity level
     */
	function setLiquidityEquilibrium(bool _belowEquilibrium) internal {
		uint256 tempLiquidityLevel;

		if (epoch >= 30) {
			for (uint256 i = 0; i < 30; i++) {
				tempLiquidityLevel += rebalanceDatas[epoch - i]
					.liquidityPercentage;
			}

			liquidityTargetEquilibrium = int256(tempLiquidityLevel) / 30;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./AddressBook.sol";

contract BlackSwanERC20 is ERC20Upgradeable, OwnableUpgradeable {
	uint256 public founderOneAllocation;
	uint256 public founderTwoAllocation;
	uint256 public founderOneMonthlyClaim;
	uint256 public founderTwoMonthlyClaim;
	uint256 public founderOneLastClaim;
	uint256 public founderTwoLastClaim;
	uint256 public developmentAllocation;
	uint256 public developmentMonhlyClaim;
	uint256 public developmentLastClaim;

	AddressBook public addressBook;
	uint256 public buyLimit;
	uint256 public sellLimit;
	modifier onlyMonetaryPolicy() {
		require(
			_msgSender() == addressBook.getAddress("POLICY"),
			"Only Monetary Policy can call this method"
		);
		_;
	}
	modifier onlyFund() {
		require(
			_msgSender() == addressBook.getAddress("FUND_ADDRESS"),
			"Only Fund can call this method"
		);
		_;
	}

	uint256 private constant MAX_SUPPLY = type(uint256).max; // (2^128) - 1
	event LogRebalance(uint256 indexed epoch, uint256 totalSupply);
	event LogMonetaryPolicyUpdated(address monetaryPolicy);
	event EmergencyFundSupplied(uint256 timestamp, uint256 amount);

	function initialize(
		address _owner,
		uint256 _initialSupply,
		uint256 _founderOneAllocation,
		uint256 _founderTwoAllocation,
		uint256 _developmentAllocation,
		AddressBook _addressBook
	) public initializer {
		__ERC20_init("BlackSwan", "SWAN");
		__Ownable_init();
		_mint(_owner, _initialSupply);
		founderOneAllocation = _founderOneAllocation;
		founderTwoAllocation = _founderTwoAllocation;
		developmentAllocation = _developmentAllocation;
		founderOneMonthlyClaim = _founderOneAllocation / 24;
		founderTwoMonthlyClaim = _founderTwoAllocation / 24;
		developmentMonhlyClaim = _developmentAllocation / 24;
		addressBook = _addressBook;
		buyLimit = (1000 * totalSupply()) / 10**6;
		sellLimit = (1000 * totalSupply()) / 10**6;

		emit Transfer(address(0), _msgSender(), totalSupply());
	}

	function claimFounderDividend() external {
		address founderOne = addressBook.getAddress("FOUNDER_ONE");
		address founderTwo = addressBook.getAddress("FOUNDER_TWO");
		address development = addressBook.getAddress("DEVELOPMENT");
		require(
			(_msgSender() == founderOne &&
				block.timestamp >= founderOneLastClaim + 30 days) ||
				(_msgSender() == founderTwo &&
					block.timestamp >= founderTwoLastClaim + 30 days) ||
				(_msgSender() == development &&
					block.timestamp >= developmentLastClaim + 30 days),
			"Only founders can call this method and should passed 30 days since last call"
		);
		if (_msgSender() == founderOne) {
			if (founderOneAllocation >= founderOneMonthlyClaim) {
				_mint(_msgSender(), founderOneMonthlyClaim);
				founderOneAllocation -= founderOneMonthlyClaim;
				founderOneLastClaim = block.timestamp;
			} else if (founderOneAllocation > 0) {
				_mint(_msgSender(), founderOneAllocation);
				founderOneAllocation = 0;
				founderOneLastClaim = block.timestamp;
			}
		} else if (_msgSender() == founderTwo) {
			if (founderTwoAllocation >= founderTwoMonthlyClaim) {
				_mint(_msgSender(), founderTwoMonthlyClaim);
				founderTwoAllocation -= founderTwoMonthlyClaim;
				founderTwoLastClaim = block.timestamp;
			} else if (founderTwoAllocation > 0) {
				_mint(_msgSender(), founderTwoAllocation);
				founderTwoAllocation = 0;
				founderOneLastClaim = block.timestamp;
			}
		} else if (_msgSender() == development) {
			if (developmentAllocation >= developmentMonhlyClaim) {
				_mint(_msgSender(), developmentMonhlyClaim);
				developmentAllocation -= developmentMonhlyClaim;
				developmentLastClaim = block.timestamp;
			} else if (developmentAllocation > 0) {
				_mint(_msgSender(), developmentAllocation);
				developmentAllocation = 0;
				developmentLastClaim = block.timestamp;
			}
		}
	}

	/**
	 * @dev Notifies token contract about a new rebase cycle.
	 * @param supplyDelta The number of new tokens to add into circulation via expansion.
	 * @return The total number of token after the supply adjustment.
	 */
	function rebalance(
		uint256 epoch,
		uint256 supplyDelta,
		bool isLiquidityAbove
	) external onlyMonetaryPolicy returns (uint256) {
		if (isLiquidityAbove) {
			if (supplyDelta == 0) {
				emit LogRebalance(epoch, totalSupply());
				return totalSupply();
			}
			_mint(addressBook.getAddress("SWAN_LAKE"), supplyDelta);
		}
		emit LogRebalance(epoch, totalSupply());
		return totalSupply();
	}

	function emergencyFundSupply(uint256 _amount) external onlyFund {
		_mint(addressBook.getAddress("FUND_ADDRESS"), _amount);
		emit EmergencyFundSupplied(block.timestamp, _amount);
	}

	function _isSell(address sender, address recipient)
		internal
		view
		returns (bool)
	{
		// Transfer to pair from non-router address is a sell swap

		return
			sender != addressBook.getAddress("UNISWAP_ROUTER") &&
			recipient == addressBook.getAddress("UNISWAP_PAIR");
	}

	function _isBuy(address sender) internal view returns (bool) {
		// Transfer from pair is a buy swap
		return sender == addressBook.getAddress("UNISWAP_PAIR");
	}

	function updateBuyLimit(uint256 limit) external onlyOwner {
		// Buy limit can only be 0.1% or disabled, set to 0 to disable
		uint256 maxLimit = (1000 * totalSupply()) / 10**6;
		require(limit == maxLimit || limit == 0, "Buy limit out of bounds");

		buyLimit = limit;
	}

	function _validateTransfer(
		address sender,
		address recipient,
		uint256 amount
	) private view {
		// Excluded addresses don't have limits

		if (_isBuy(sender) && buyLimit != 0) {
			require(amount <= buyLimit, "Buy amount exceeds limit");
		} else if (_isSell(sender, recipient) && sellLimit != 0) {
			require(amount <= sellLimit, "Sell amount exceeds limit");
		}
	}

	function transfer(address recipient, uint256 amount)
		public
		virtual
		override
		returns (bool)
	{
		_validateTransfer(_msgSender(), recipient, amount);
		return super.transfer(recipient, amount);
	}

	function updateSellLimit(uint256 limit) external onlyOwner {
		// Min sell limit is 0.1%, max is 0.5%. Set to 0 to disable
		uint256 minLimit = (1000 * totalSupply()) / 10**6;
		uint256 maxLimit = (5000 * totalSupply()) / 10**6;

		require(
			(limit <= maxLimit && limit >= minLimit) || limit == 0,
			"Sell limit out of bounds"
		);

		sellLimit = limit;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "./libraries/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/Interfaces.sol";
import "./BlackSwanERC20.sol";
import "./AddressBook.sol";

contract BlackSwanFund is OwnableUpgradeable {
	using SafeMath for uint256;

	AddressBook public addressBook;
	uint256[] public rewardDistrubitionPercentage = [
		250000000000,
		200000000000,
		200000000000,
		75000000000,
		50000000000,
		50000000000,
		25000000000,
		25000000000,
		20000000000,
		20000000000,
		10000000000,
		10000000000,
		10000000000,
		10000000000,
		10000000000,
		10000000000,
		10000000000,
		5000000000,
		5000000000,
		5000000000
	];
	uint256 public initialRewardValue;
	uint256 public daysAfterBelowEquilibrium;
	uint256 public slippage;
	uint256 public liquidityMinAmount;

	event LiquidityProvided(
		address poolAddress,
		uint256 stableCoinAmount,
		uint256 swanAmount
	);
	event TokensSwapped(
		address poolAddress,
		uint256 stableCoinAmount,
		uint256 swanAmount
	);

	constructor(AddressBook _addressBook) {
		__Ownable_init();
		addressBook = _addressBook;
		slippage = 99;
		liquidityMinAmount = 99;
	}

	/**
    @dev Function that swap tokens through Uniswap router
    @param _usdcAmount usdc amount that we would get
     */
	function swapSwanToUsdc(uint256 _usdcAmount) public onlyOwner {
		daysAfterBelowEquilibrium = 0;
		IUniswapV2Router02 uniswapRouterContract =
			IUniswapV2Router02(addressBook.getAddress("UNISWAP_ROUTER"));
		(uint256 reserve0, uint256 reserve1, ) =
			IUniswapV2Pair(addressBook.getAddress("UNISWAP_PAIR"))
				.getReserves();
		uint256 swanAmount = getAmountIn(_usdcAmount, reserve0, reserve1);
		address blackSwanAddress = addressBook.getAddress("BLACKSWAN");
		uint256 fundSwanAmount =
			IERC20(blackSwanAddress).balanceOf(address(this));
		if (swanAmount > fundSwanAmount) {
			_emergencyFundCall(swanAmount - fundSwanAmount);
		}
		address[] memory path = new address[](2);
		path[0] = blackSwanAddress;
		path[1] = addressBook.getAddress("USDC");
		IERC20(blackSwanAddress).approve(
			address(uniswapRouterContract),
			swanAmount
		);
		uniswapRouterContract.swapExactTokensForTokens(
			swanAmount,
			(_usdcAmount * slippage) / 100,
			path,
			address(this),
			block.timestamp
		);
		emit TokensSwapped(
			address(uniswapRouterContract),
			_usdcAmount,
			swanAmount
		);
	}

	/**
    @dev Function that provide liquidity to pools in exchange get 
    * BPT then provide it to swan lake during below equibrium situations
     */
	function provideLiquidity() public onlyOwner {
		address rewardPool = addressBook.getAddress("REWARD_POOL");
		if (rewardPool == address(0x0)) return;
		setInitialRewardValue();
		if (daysAfterBelowEquilibrium <= 19) {
			uint256 stableCoinAmount =
				(initialRewardValue *
					rewardDistrubitionPercentage[daysAfterBelowEquilibrium]) /
					1e12; // divide to 1e12 to bring down usdc's decimals which is 6
			daysAfterBelowEquilibrium = daysAfterBelowEquilibrium + 1;
			IUniswapV2Router02 uniswapRouterContract =
				IUniswapV2Router02(addressBook.getAddress("UNISWAP_ROUTER"));
			(uint256 reserve0, uint256 reserve1, ) =
				IUniswapV2Pair(addressBook.getAddress("UNISWAP_PAIR"))
					.getReserves();
			uint256 swanAmount = (stableCoinAmount * reserve0) / reserve1;
			address swanAddress = addressBook.getAddress("BLACKSWAN");
			address usdcAddress = addressBook.getAddress("USDC");
			uint256 fundSwanAmount =
				IERC20(swanAddress).balanceOf(address(this));
			if (swanAmount > fundSwanAmount) {
				_emergencyFundCall(swanAmount - fundSwanAmount);
			}
			IERC20(usdcAddress).approve(
				address(uniswapRouterContract),
				stableCoinAmount
			);
			IERC20(swanAddress).approve(
				address(uniswapRouterContract),
				swanAmount
			);
			address rewardPoolTemp = rewardPool;
			uint256 stableCoinAmountTemp = stableCoinAmount;
			uniswapRouterContract.addLiquidity(
				swanAddress,
				usdcAddress,
				swanAmount,
				stableCoinAmount,
				(swanAmount * liquidityMinAmount) / 100,
				(stableCoinAmountTemp * liquidityMinAmount) / 100,
				rewardPoolTemp,
				block.timestamp
			);

			emit LiquidityProvided(
				addressBook.getAddress("UNISWAP_PAIR"),
				stableCoinAmount,
				swanAmount
			);
		}
	}

	// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) internal pure returns (uint256 amountIn) {
		require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
		require(
			reserveIn > 0 && reserveOut > 0,
			"UniswapV2Library: INSUFFICIENT_LIQUIDITY"
		);
		uint256 numerator = reserveIn.mul(amountOut).mul(1000);
		uint256 denominator = reserveOut.sub(amountOut).mul(997);
		amountIn = (numerator / denominator).add(1);
	}

	function setInitialRewardValue() internal {
		if (daysAfterBelowEquilibrium == 0) {
			initialRewardValue = IERC20(addressBook.getAddress("USDC"))
				.balanceOf(address(this));
		}
	}

	function _emergencyFundCall(uint256 _amount) internal {
		BlackSwanERC20 bSwan =
			BlackSwanERC20(addressBook.getAddress("BLACKSWAN"));
		bSwan.emergencyFundSupply(_amount);
	}

	function setSlippageAndMinLiquidityAmount(
		uint256 _slippage,
		uint256 _liquidityMinAmount
	) external {
		require(_msgSender() == addressBook.getAddress("SETTER"));
		slippage = _slippage;
		liquidityMinAmount = _liquidityMinAmount;
	}

	function recoverFunds() external {
		require(_msgSender() == addressBook.getAddress("SETTER"));
		address rewardPool = addressBook.getAddress("REWARD_POOL");
		if (rewardPool == address(0x0)) return;
		uint256 stableCoinAmount =
			IERC20(addressBook.getAddress("USDC")).balanceOf(address(this));

		IUniswapV2Router02 uniswapRouterContract =
			IUniswapV2Router02(addressBook.getAddress("UNISWAP_ROUTER"));
		(uint256 reserve0, uint256 reserve1, ) =
			IUniswapV2Pair(addressBook.getAddress("UNISWAP_PAIR"))
				.getReserves();
		uint256 swanAmount = (stableCoinAmount * reserve0) / reserve1;
		address swanAddress = addressBook.getAddress("BLACKSWAN");
		address usdcAddress = addressBook.getAddress("USDC");
		uint256 fundSwanAmount = IERC20(swanAddress).balanceOf(address(this));
		if (swanAmount > fundSwanAmount) {
			_emergencyFundCall(swanAmount - fundSwanAmount);
		}
		IERC20(usdcAddress).approve(
			address(uniswapRouterContract),
			stableCoinAmount
		);
		IERC20(swanAddress).approve(address(uniswapRouterContract), swanAmount);
		address rewardPoolTemp = rewardPool;
		uint256 stableCoinAmountTemp = stableCoinAmount;
		uniswapRouterContract.addLiquidity(
			swanAddress,
			usdcAddress,
			swanAmount,
			stableCoinAmount,
			(swanAmount * liquidityMinAmount) / 100,
			(stableCoinAmountTemp * liquidityMinAmount) / 100,
			rewardPoolTemp,
			block.timestamp
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.1;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
	/**
	 * @dev Multiplies two numbers, reverts on overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	/**
	 * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	/**
	 * @dev Adds two numbers, reverts on overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	/**
	 * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
	 * reverts when dividing by zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

// SPDX-License-Identifier: MIT
/*
MIT License
Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity >=0.6.0 <0.8.1;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);

	/**
	 * @dev Multiplies two int256 variables and fails on overflow.
	 */
	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;

		// Detect overflow when multiplying MIN_INT256 with -1
		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}

	/**
	 * @dev Division of two int256 variables and fails on overflow.
	 */
	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing MIN_INT256 by -1
		require(b != -1 || a != MIN_INT256);

		// Solidity already throws when dividing by 0.
		return a / b;
	}

	/**
	 * @dev Subtracts two int256 variables and fails on overflow.
	 */
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}

	/**
	 * @dev Adds two int256 variables and fails on overflow.
	 */
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}

	/**
	 * @dev Converts to absolute value, and fails on overflow.
	 */
	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AddressBook is OwnableUpgradeable {
	mapping(bytes32 => address) public addresses;

	constructor() {
		__Ownable_init();
	}

	function getAddress(string memory name) external view returns (address) {
		return addresses[keccak256(bytes(name))];
	}

	function setAddress(string memory name, address addr) external onlyOwner {
		addresses[keccak256(bytes(name))] = addr;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.1;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function decimals() external view returns (uint8);

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

interface IUniswapV2Pair {
	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);
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

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

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

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

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

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

interface IERC2917 is IERC20 {
	/// @dev This emit when interests amount per block is changed by the owner of the contract.
	/// It emits with the old interests amount and the new interests amount.
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityIncreased(address indexed user, uint256 value);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityDecreased(address indexed user, uint256 value);

	/// @dev Return the current contract's interests rate per block.
	/// @return The amount of interests currently producing per each block.
	function interestsPerBlock() external view returns (uint256);

	/// @notice Change the current contract's interests rate.
	/// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
	/// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
	function changeInterestRatePerBlock(uint256 value) external returns (bool);

	/// @notice It will get the productivity of given user.
	/// @dev it will return 0 if user has no productivity proved in the contract.
	/// @return user's productivity and overall productivity.
	function getProductivity(address user)
		external
		view
		returns (uint256, uint256);

	/// @notice increase a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity added success.
	function increaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice decrease a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity removed success.
	function decreaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice take() will return the interests that callee will get at current block height.
	/// @dev it will always calculated by block.number, so it will change when block height changes.
	/// @return amount of the interests that user are able to mint() at current block height.
	function take() external view returns (uint256);

	/// @notice similar to take(), but with the block height joined to calculate return.
	/// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
	/// @return amount of interests and the block height.
	function takeWithBlock() external view returns (uint256, uint256);

	/// @notice mint the avaiable interests to callee.
	/// @dev once it mint, the amount of interests will transfer to callee's address.
	/// @return the amount of interests minted.
	function mint() external returns (uint256);
}

interface MultiSigWallet {
	function submitTransaction(
		address destination,
		uint256 value,
		bytes calldata data
	) external returns (uint256);

	function addOwner(address owner) external;

	function replaceOwner(address owner, address newOwner) external;

	function changeRequirement(uint256 _required) external;
}