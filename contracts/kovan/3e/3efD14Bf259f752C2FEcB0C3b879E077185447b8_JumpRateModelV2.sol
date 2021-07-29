// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title JumpRateModelV2
/// @author
////////////////////////////////////////////////////////////////////////////////////////////

contract JumpRateModelV2 {
    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock,
        uint256 jumpMultiplierPerBlock,
        uint256 kink
    );

    /// @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
    address public owner;

    /// @notice The approximate number of blocks per year that is assumed by the interest rate model
    uint256 public immutable blocksPerYear;

    /// @notice The multiplier of utilization rate that gives the slope of the interest rate
    uint256 public multiplierPerBlock;

    /// @notice The base interest rate which is the y-intercept when utilization rate is 0
    uint256 public baseRatePerBlock;

    /// @notice The multiplierPerBlock after hitting a specified utilization point
    uint256 public jumpMultiplierPerBlock;

    /// @notice The utilization point at which the jump multiplier is applied
    uint256 public kink;

    /// @dev Maximum borrow rate that can ever be applied per second
    uint256 internal immutable borrowRateMaxMantissa;

    /// @notice Construct an interest rate model
    /// @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
    /// @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
    /// @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
    /// @param kink_ The utilization point at which the jump multiplier is applied
    /// @param owner_ The address of the owner, i.e. which has the ability to update parameters directly
    /// @param borrowRateMaxMantissa_ maximum borrow rate per second
    /// @param blocksPerYear_ the number of blocks on the chain per year
    constructor(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,
        address owner_,
        uint256 borrowRateMaxMantissa_,
        uint256 blocksPerYear_
    ) {
        require(baseRatePerYear > 0, "invalid base rate");
        require(multiplierPerYear > 0, "invalid multiplier per year");
        require(jumpMultiplierPerYear > 0, "invalid jump multiplier per year");
        require(kink_ > 0, "invalid kink");
        require(owner_ != address(0), "invalid owner");
        require(borrowRateMaxMantissa_ > 0, "invalid borrow rate max");
        require(blocksPerYear_ > 0, "invalid blocks per year");

        owner = owner_;
        borrowRateMaxMantissa = borrowRateMaxMantissa_;
        blocksPerYear = blocksPerYear_;
        updateJumpRateModelInternal(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_,
            blocksPerYear_
        );
    }

    /// @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
    /// @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
    /// @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
    /// @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
    /// @param kink_ The utilization point at which the jump multiplier is applied
    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) external {
        require(msg.sender == owner, "only the owner may call this function.");
        require(baseRatePerYear > 0, "invalid base rate");
        require(multiplierPerYear > 0, "invalid multiplier per year");
        require(jumpMultiplierPerYear > 0, "invalid jump multiplier per year");
        require(kink_ > 0, "invalid kink");

        updateJumpRateModelInternal(
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_,
            blocksPerYear
        );
    }

    /// @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market (currently unused)
    /// @return The utilization rate as a mantissa between [0, 1e18]
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return (borrows * (1e18)) / (cash + borrows - reserves);
    }

    /// @notice Calculates the current borrow rate per block, with the error code expected by the market
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market
    /// @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
    function getBorrowRateInternal(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) internal view returns (uint256) {
        uint256 util = utilizationRate(cash, borrows, reserves);

        if (util <= kink) {
            return (util * multiplierPerBlock) / 1e18 + baseRatePerBlock;
        } else {
            uint256 normalRate = (kink * multiplierPerBlock) / 1e18 + baseRatePerBlock;
            uint256 excessUtil = util - kink;
            return (excessUtil * jumpMultiplierPerBlock) / 1e18 + normalRate;
        }
    }

    /**
    /// @notice Calculates the current supply rate per block
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market
    /// @param reserveFactorMantissa The current reserve factor for the market
    /// @return The supply rate percentage per block as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public view returns (uint256) {
        uint256 oneMinusReserveFactor = uint256(1e18) - reserveFactorMantissa;
        uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
        return (utilizationRate(cash, borrows, reserves) * rateToPool) / 1e18;
    }

    /// @notice Internal function to update the parameters of the interest rate model
    /// @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
    /// @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
    /// @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
    /// @param kink_ The utilization point at which the jump multiplier is applied
    function updateJumpRateModelInternal(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,
        uint256 blocksPerYear_
    ) internal {
        baseRatePerBlock = baseRatePerYear / blocksPerYear_;
        multiplierPerBlock = (multiplierPerYear * 1e18) / (blocksPerYear_ * kink_);
        jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear_;
        kink = kink_;

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }

    /// @notice Calculates the current borrow rate per block
    /// @param cash The amount of cash in the market
    /// @param borrows The amount of borrows in the market
    /// @param reserves The amount of reserves in the market
    /// @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256) {
        uint256 borrowRateMantissa = getBorrowRateInternal(cash, borrows, reserves);
        if (borrowRateMantissa > borrowRateMaxMantissa) {
            return borrowRateMaxMantissa;
        } else {
            return borrowRateMantissa;
        }
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 500
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}