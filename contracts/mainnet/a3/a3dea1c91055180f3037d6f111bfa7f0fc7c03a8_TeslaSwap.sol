/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

// Sources flattened with hardhat v2.0.10 https://hardhat.org

// File contracts/interfaces/ICurve.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurve {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}


// File contracts/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


// File contracts/interfaces/ISynthetix.sol

pragma solidity ^0.8.0;

interface ISynthetix {
    function exchangeOnBehalf(
        address exchangeForAddress, 
        bytes32 sourceCurrencyKey, 
        uint256 sourceAmount, 
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);
}


// File contracts/interfaces/IDelegateApprovals.sol

pragma solidity ^0.8.0;

interface IDelegateApprovals {
    function approveExchangeOnBehalf(address delegate) external;
}


// File contracts/TeslaSwap.sol


pragma solidity ^0.8.0;




contract TeslaSwap {
  ICurve public curve;
  ISynthetix public synthetix;
  IERC20 public USDC;
  IERC20 public sUSD;
  IERC20 public sTSLA;
  
  constructor(address _USDC, address _sUSDC, address _sTSLA, address _curve, address _synthetix) {
    USDC = IERC20(_USDC);
    sUSD = IERC20(_sUSDC);
    sTSLA = IERC20(_sTSLA);
    curve = ICurve(_curve);
    synthetix = ISynthetix(_synthetix);

    USDC.approve(address(curve), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
  }

  function swapUSDCForTequila (
    uint256 amountIn,
    uint256 amountOutMin
  ) external {
    USDC.transferFrom(msg.sender, address(this), amountIn);

    curve.exchange(1, 3, amountIn, amountOutMin);
    uint256 sUSDOut = sUSD.balanceOf(address(this));
    sUSD.transfer(msg.sender, sUSDOut);

    synthetix.exchangeOnBehalf(msg.sender, "sUSD", sUSDOut, "sTSLA");
  }
}