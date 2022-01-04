// SPDX-License-Identifier: MIT

pragma solidity >=0.8;

// import 'hardhat/console.sol';

/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2 modifies Version 1 by enabling updateable parameters.
 */
contract BaseInterestRate {
	event NewInterestParams(
		uint256 baseRatePerBlock,
		uint256 multiplierPerBlock,
		uint256 jumpMultiplierPerBlock,
		uint256 kink,
		uint256 reserveRate
	);

	/**
	 * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
	 */
	address public owner;

	/**
	 * @notice The approximate number of blocks per year that is assumed by the interest rate model
	 */
	uint64 public constant blocksPerYear = 2102400;

	/**
	 * @notice The multiplier of utilization rate that gives the slope of the interest rate
	 */
	uint256 public multiplierPerBlock;

	/**
	 * @notice The base interest rate which is the y-intercept when utilization rate is 0
	 */
	uint256 public baseRatePerBlock;

	/**
	 * @notice The multiplierPerBlock after hitting a specified utilization point
	 */
	uint256 public jumpMultiplierPerBlock;

	/**
	 * @notice The utilization point at which the jump multiplier is applied
	 */
	uint256 public kink;

	uint256 public reserveRate = 0.3e16;

	/**
	 * @notice Construct an interest rate model
	 * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
	 * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
	 * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
	 * @param kink_ The utilization point at which the jump multiplier is applied
	 * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
	 */
	constructor(
		uint256 baseRatePerYear,
		uint256 multiplierPerYear,
		uint256 jumpMultiplierPerYear,
		uint256 kink_,
		address owner_
	) {
		owner = owner_;

		updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_, reserveRate);
	}

	/**
	 * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
	 * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
	 * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
	 * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
	 * @param kink_ The utilization point at which the jump multiplier is applied
	 * @param reserveRate the protocol fee rate (diff between supply rate and borrow rate)
	 */
	function updateJumpRateModel(
		uint256 baseRatePerYear,
		uint256 multiplierPerYear,
		uint256 jumpMultiplierPerYear,
		uint256 kink_,
		uint256 reserveRate
	) external {
		require(msg.sender == owner, 'only the owner may call this function.');

		updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_, reserveRate);
	}

	/**
	 * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
	 * @param cash The amount of cash in the market
	 * @param borrows The amount of borrows in the market
	 * @param reserves The amount of reserves in the market (currently unused)
	 * @return The utilization rate as a mantissa between [0, 1e18]
	 */
	function utilizationRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) public pure returns (uint256) {
		// Utilization rate is 0 when there are no borrows
		if (borrows == 0) {
			return 0;
		}

		return (borrows * 1e18) / (cash + borrows + reserves);
	}

	/**
	 * @notice Calculates the current borrow rate per block, with the error code expected by the market
	 * @param cash The amount of cash in the market
	 * @param borrows The amount of borrows in the market
	 * @param reserves The amount of reserves in the market
	 * @return rate The borrow rate percentage per block as a mantissa (scaled by 1e18)
	 */
	function getBorrowRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) public view returns (uint256 rate) {
		uint256 util = utilizationRate(cash, borrows, reserves);

		if (util <= kink) {
			rate = ((util * multiplierPerBlock) / 1e18) + baseRatePerBlock;
		} else {
			uint256 normalRate = ((kink * multiplierPerBlock) / 1e18) + baseRatePerBlock;
			uint256 excessUtil = util - kink;
			rate = ((excessUtil * jumpMultiplierPerBlock) / 1e18) + normalRate;
		}
		// console.log('borrow rate: %s', rate);
	}

	/**
	 * @notice Calculates the current supply rate per block
	 * @param cash The amount of cash in the market
	 * @param borrows The amount of borrows in the market
	 * @param reserves The amount of reserves in the market
	 * @return rate The supply rate percentage per block as a mantissa (scaled by 1e18)
	 */
	function getSupplyRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) public view returns (uint256 rate) {
		uint256 oneMinusReserveFactor = uint256(1e18) - reserveRate;
		uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
		uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
		rate = (utilizationRate(cash, borrows, reserves) * rateToPool) / 1e18;
	}

	/**
	 * @notice Internal function to update the parameters of the interest rate model
	 * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
	 * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
	 * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
	 * @param kink_ The utilization point at which the jump multiplier is applied
	 * @param reserveRate_ the protocol fee rate (diff between supply rate and borrow rate)
	 */
	function updateJumpRateModelInternal(
		uint256 baseRatePerYear,
		uint256 multiplierPerYear,
		uint256 jumpMultiplierPerYear,
		uint256 kink_,
		uint256 reserveRate_
	) internal {
		baseRatePerBlock = baseRatePerYear / blocksPerYear;
		multiplierPerBlock = (multiplierPerYear * 1e18) / (blocksPerYear * kink_);
		jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;
		kink = kink_;
		reserveRate = reserveRate;
		emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink, reserveRate);
	}
}