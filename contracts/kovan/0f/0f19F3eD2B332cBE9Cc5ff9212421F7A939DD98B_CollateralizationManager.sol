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
  IContractAddresses private constant _ADDRESSES = IContractAddresses(0xB14aB9E5A7F11433d67Aad5ae3ef85BEdd6fb81E);
  address private constant _KAE = 0x6d601e901d9eE9Ec4989E28C1B9A312399aEA494;

  uint256 private constant _BASIS_POINT = 10000;


  // [token] => ratio; all ratios are in basis point
  mapping(address => Ratio) private _ratio;


  constructor ()
  {
    _ratio[0xC22780731758d1E309B9774009027D2Eb325F66f] = Ratio({ init: 12500, liquidation: 12000 });
    _ratio[0x10fa2511aB6945F48Cc637A5d4817a24c3688e9b] = Ratio({ init: 12500, liquidation: 12000 });

    _ratio[0xd67AB1D41c1bf29B0F8a2284B26f395B40d9F6B6] = Ratio({ init: 13500, liquidation: 12500 });

    _ratio[0xfae6315a60964c3C6647D7B4DD426e9953129468] = Ratio({ init: 15000, liquidation: 13500 });
    _ratio[0x6eEbF3069a5dcd836C127fd55E2C33EF37397722] = Ratio({ init: 15000, liquidation: 13500 });
    _ratio[0xC5e2569C401698f701610682988953ac924A010D] = Ratio({ init: 15000, liquidation: 13500 });
    _ratio[0x27EA102C03f356309A2fc59D9eCEA64502967790] = Ratio({ init: 15000, liquidation: 13500 });
  }

  function _calcPercentOf (uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return (amount * percent) / _BASIS_POINT;
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

  function _isValidPair (address tokenRegistry, address debtToken, address collateralToken) private view returns (bool)
  {
    return debtToken != _KAE && debtToken != collateralToken && ITokenRegistry(tokenRegistry).isValidPair(debtToken, collateralToken);
  }

  function checkIsSufficientInitialCollateral (address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view returns (bool)
  {
    // >= debtInCollateralToken @ token init ratio
    return _isValidPair(_ADDRESSES.tokenRegistry(), debtToken, collateralToken) && collateral >= _calcPercentOf(debtInCollateralToken, _ratio[collateralToken].init);
  }


  function isSufficientInitialCollateral (address tokenRegistry, address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view override returns (bool)
  {
    require(_isValidPair(tokenRegistry, debtToken, collateralToken), "!valid pair");


    // >= debtInCollateralToken @ token init ratio
    return collateral >= _calcPercentOf(debtInCollateralToken, _ratio[collateralToken].init);
  }

  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view override returns (bool, uint256)
  {
    uint256 liqRatio = _ratio[collateralToken].liquidation;

    if (IStakingManager(_ADDRESSES.stakingManager()).isDiscountedBorrower(borrower) && !ITokenRegistry(_ADDRESSES.tokenRegistry()).isStableToken(collateralToken))
    {
      // 350 = 3.5% in basis point
      liqRatio = liqRatio - _calcPercentOf(liqRatio, 350);
    }


    uint256 debtInCollateralTokenAtLiqRatio = IOracle(_ADDRESSES.oracle()).convert(debtToken, collateralToken, _calcPercentOf(debt, liqRatio));


    return ( collateral > debtInCollateralTokenAtLiqRatio, (collateral / (debtInCollateralTokenAtLiqRatio / liqRatio)) );
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


struct Contracts
{
  address oracle;
  address tokenRegistry;
  address coordinator;
  address stakingManager;
  address feeManager;
  address rewardManager;
  address collateralizationManager;
}

interface IContractAddresses
{
  function coordinators () external view returns (Contracts memory);


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
  function getConversionRate (address from, address to) external view returns (uint256);

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

  function isValidPair (address debtToken, address collateralToken) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IStakingManager
{
  function isStakingDepositor (address account) external view returns (bool);

  function isStakingBorrower (address account) external view returns (bool);

  function isDiscountedDepositor (address account) external view returns (bool);

  function isDiscountedBorrower (address account) external view returns (bool);


  // interestRate in basis point
  function increaseDepositorExpectedStake (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external;

  // interestRate in basis point
  function decreaseDepositorExpectedStake (address depositor, address depositToken, uint256 deposit, uint256 interestRate) external;


  function increaseBorrowerExpectedStake (address borrower, uint256 debt, uint256 debtInUSD, uint256 debtRepaymentTimestamp) external;

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

  function isSufficientInitialCollateral (address tokenRegistry, address debtToken, address collateralToken, uint256 debtInCollateralToken, uint256 collateral) external view returns (bool);

  // returns (bool isSufficient, uint collateralizationRatio% in basis point)
  function isSufficientCollateral (address borrower, address debtToken, uint256 debt, address collateralToken, uint256 collateral) external view returns (bool, uint256);
}