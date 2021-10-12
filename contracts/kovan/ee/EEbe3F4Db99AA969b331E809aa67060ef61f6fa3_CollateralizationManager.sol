// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { Ownable } from "../roles/Ownable.sol";
import { IContractAddresses } from "../interfaces/IContractAddresses.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { ITokenRegistry } from "../interfaces/ITokenRegistry.sol";
import { IStakingManager } from "../interfaces/IStakingManager.sol";
import { Ratio, ICollateralizationManager } from "../interfaces/ICollateralizationManager.sol";


contract CollateralizationManager is ICollateralizationManager, Ownable
{
  IContractAddresses private constant _ADDRESSES = IContractAddresses(0xC9419F8fC4fC8312363c0cF191E4B614dbacd2FA);
  address private constant _KAE = 0x6d601e901d9eE9Ec4989E28C1B9A312399aEA494;

  uint256 private constant _BASIS_POINT = 10000;


  // [token] => ratio; all ratios are in basis point
  mapping(address => Ratio) private _ratio;


  function _tokenReg () internal view returns (ITokenRegistry)
  {
    return ITokenRegistry(_ADDRESSES.tokenRegistry());
  }


  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
  }

  function _convert(address from, address to, uint256 amount) private view returns (uint256)
  {
    return IOracle(_ADDRESSES.oracle()).convert(from, to, amount);
  }


  function getTokenRatio (address token) external view override returns (Ratio memory)
  {
     return _ratio[token];
  }

  function setRatios (address[] calldata tokens, Ratio[] calldata ratios) external onlyOwner
  {
    require(tokens.length == ratios.length, "!=");

    for (uint256 i = 0; i < ratios.length; i++)
    {
      address token = tokens[i];
      Ratio memory ratio = ratios[i];

      require(token != address(0), "0 addr");
      // in basis point
      require(ratio.init >= 12500, "!valid init");
      require(ratio.liquidation >= 12000 && ratio.liquidation <= 14500, "!valid liq");

      _ratio[token] = ratio;
    }
  }

  function _isValidPairing (address debtToken, address collateralToken) private view returns (bool)
  {
    return debtToken != _KAE && debtToken != collateralToken && _tokenReg().isBothWhitelisted(debtToken, collateralToken) && !_tokenReg().isBothStable(debtToken, collateralToken);
  }

  function isSufficientInitialCollateral (address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view override returns (bool)
  {
    require(_isValidPairing(debtToken, collateralToken), "!valid pair");

    uint256 debtInCollateralTokenAtInitRatio = _convert(debtToken, collateralToken, _calcPercentOf(debt, _ratio[collateralToken].init));


    return collateral >= debtInCollateralTokenAtInitRatio;
  }

  function _calcCollateralRatio (uint256 debtInCollateralTokenAtLiqRatio, uint256 collateral, uint256 liquidationRatio) private pure returns (uint256)
  {
    // in basis point
    return collateral / (debtInCollateralTokenAtLiqRatio / liquidationRatio);
  }

  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view override returns (bool, uint256)
  {
    uint256 liqRatio = _ratio[collateralToken].liquidation;

    if (IStakingManager(_ADDRESSES.stakingManager()).isDiscountableBorrower(borrower) && !_tokenReg().isStableToken(collateralToken))
    {
      // 350 = 3.5% in basis point
      liqRatio = liqRatio - _calcPercentOf(liqRatio, 350);
    }

    uint256 debtInCollateralTokenAtLiqRatio = _convert(debtToken, collateralToken, _calcPercentOf(debt, liqRatio));


    return (collateral > debtInCollateralTokenAtLiqRatio, _calcCollateralRatio(debtInCollateralTokenAtLiqRatio, collateral, liqRatio));
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


interface ITokenRegistry
{
  function isWhitelisted (address token) external view returns (bool);

  function isStableToken (address token) external view returns (bool);

  function isBothWhitelisted (address tokenA, address tokenB) external view returns (bool);

  function isBothStable (address tokenA, address tokenB) external view returns (bool);
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


// all scaled in basis point
struct Ratio
{
  uint256 init;
  uint256 liquidation;
}

interface ICollateralizationManager
{
  function getTokenRatio (address token) external view returns (Ratio memory);

  function isSufficientInitialCollateral (address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view returns (bool);

  // returns (bool isSufficient, uint collateralizationRatio% in basis point)
  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view returns (bool, uint256);
}