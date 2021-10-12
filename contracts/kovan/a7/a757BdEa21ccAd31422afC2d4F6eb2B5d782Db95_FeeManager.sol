// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Ownable } from "../roles/Ownable.sol";
import { IContractAddresses } from "../interfaces/IContractAddresses.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IStakingManager } from "../interfaces/IStakingManager.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";


contract FeeManager is IFeeManager, Ownable
{
  IContractAddresses private constant _ADDRESSES = IContractAddresses(0xC9419F8fC4fC8312363c0cF191E4B614dbacd2FA);

  uint256 private constant _BASIS_POINT = 10000;


  // % values; all scaled in basis point
  struct Rate
  {
    uint256 deposit;
    uint256 borrow;
    uint256 defaulted;
  }

  Rate private _rate;
  address private _burner;


  constructor ()
  {
    _burner = msg.sender;

    _rate = Rate({ deposit: 1000, borrow: 100, defaulted: 700 });
  }

  function updateRate (Rate calldata rate) external onlyOwner
  {
    require(rate.deposit > 0 && rate.borrow > 0 && rate.defaulted > 0, "!valid values");
    // 100 = 1% in basis point
    require(rate.deposit <= 1500 && rate.borrow <= 125 && rate.defaulted <= 750, "too high");

    _rate = rate;
  }

  function getRate () external view returns (Rate memory)
  {
    return _rate;
  }

  function setBurner (address burner) external onlyOwner
  {
    require(burner != address(0), "0 addr");

    _burner = burner;
  }

  function getBurner () external view override returns (address)
  {
    return _burner;
  }


  function _calcPercentOf (uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
  }

  // interestRate in basis point
  function getDepositFeeOnInterest (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external view override returns (uint256)
  {
    uint256 interest = _calcPercentOf(deposit, interestRate);
    uint256 oneUSDOfDepositToken = IOracle(_ADDRESSES.oracle()).convertFromUSD(depositToken, 1e18);

    // 7500 = 75% in basis point; 75% -> 25% discount
    uint256 fee = _calcPercentOf(interest, IStakingManager(_ADDRESSES.stakingManager()).isDiscountableDepositor(depositor) ? _calcPercentOf(_rate.deposit, 7500) : _rate.deposit);


    return Math.max(fee, oneUSDOfDepositToken);
  }

  function getBorrowFeeOnDebt (address borrower, address debtToken, uint256 debt, address collateralToken) external view override returns (uint256)
  {
    // 25 = 0.25% in basis point; 1 - 0.25 = 0.75% -> 25% discount
    uint256 fee = IStakingManager(_ADDRESSES.stakingManager()).isDiscountableBorrower(borrower) ? _rate.borrow - 25 : _rate.borrow;


    return _calcPercentOf(IOracle(_ADDRESSES.oracle()).convert(debtToken, collateralToken, debt), fee);
  }

  function getDefaultFee (uint256 collateral) external view override returns (uint256)
  {
    return _calcPercentOf(collateral, _rate.defaulted);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


contract Ownable
{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  modifier onlyOwner ()
  {
    require(msg.sender == _owner, "!owner");
    _;
  }

  constructor ()
  {
    _owner = msg.sender;

    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner () public view returns (address)
  {
    return _owner;
  }

  function renounceOwnership () public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));

    _owner = address(0);
  }

  function transferOwnership (address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addr");

    emit OwnershipTransferred(_owner, newOwner);

    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IContractAddresses
{
  function vault () external view returns (address);

  function oracle () external view returns (address);

  function tokenRegistry () external view returns (address);

  function coordinator () external view returns (address);

  function depositManager () external view returns (address);

  function borrowManager () external view returns (address);

  function feeManager () external view returns (address);

  function stakingManager () external view returns (address);

  function rewardManager () external view returns (address);

  function collateralizationManager () external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IOracle
{
  function getRate (address from, address to) external view returns (uint256);

  function convertFromUSD (address to, uint256 amount) external view returns (uint256);

  function convertToUSD (address from, uint256 amount) external view returns (uint256);

  function convert (address from, address to, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IStakingManager
{
  function isStakingDepositor (address account) external view returns (bool);

  function isStakingBorrower (address account) external view returns (bool);

  function isDiscountableDepositor (address account) external view returns (bool);

  function isDiscountableBorrower (address account) external view returns (bool);

  // interestRate in basis point
  function increaseDepositorExpectedStake (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external;

  function increaseBorrowerExpectedStake (address borrower, address debtToken, uint256 debt, uint256 debtRepaymentTimestamp) external;

  // interestRate in basis point
  function decreaseDepositorExpectedStake (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external;

  function decreaseBorrowerExpectedStake (address borrower, address debtToken, uint256 debt) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IFeeManager
{
  function getBurner () external view returns (address);

  function getDefaultFee (uint256 collateral) external view returns (uint256);

  // interestRate in basis point
  function getDepositFeeOnInterest (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external view returns (uint256);

  function getBorrowFeeOnDebt (address borrower, address debtToken, uint256 debt, address collateralToken) external view returns (uint256);
}