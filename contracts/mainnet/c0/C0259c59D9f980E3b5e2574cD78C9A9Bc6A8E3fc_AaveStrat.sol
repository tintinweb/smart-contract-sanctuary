//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}

contract AaveStrat {
  function balanceOf(address account) external view returns (uint256){
    address bpool = 0xC697051d1C6296C24aE3bceF39acA743861D9A81;
    IERC20 aave = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IERC20 abpt = IERC20(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);
    IERC20 stkABPT = IERC20(0xa1116930326D21fB917d5A27F1E9943A9595fb47);
    uint aaveInPool = aave.balanceOf(bpool);
    uint abptSupply = abpt.totalSupply();
    uint abptBalance = abpt.balanceOf(account);
    abptBalance += stkABPT.balanceOf(account);
    return (abptBalance * aaveInPool)/abptSupply;
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}