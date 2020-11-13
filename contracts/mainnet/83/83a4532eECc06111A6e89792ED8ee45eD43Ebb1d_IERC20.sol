// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/// Know more: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

interface IERC20 {
  function initialSupply()
  external view returns (uint256);

  function totalSupply()
  external view returns (uint256);

  function totalSupplyCap()
  external view returns (uint256);

  function balanceOf(
    address account
  ) external view returns (uint256);

  function transfer(
    address recipient,
    uint256 amount
  ) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function approve(
    address spender,
    uint256 amount
  ) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}