/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function burn(uint256 amount) external returns (bool);

  function decimals() external view returns (uint8);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface IVault {
  function minAmountIn() external view returns (uint256);

  function tokenAddress() external view returns (address);

  function withdraw(uint256 amountIn) external returns (uint256);

  function deposit() external payable;
}

contract Vault is IVault {
  uint256 public constant override minAmountIn = 100_000 * (10**18);

  address public immutable override tokenAddress;

  constructor(address _token) {
    require(_token != address(0), 'zero address');
    require(IERC20(_token).decimals() == 18, 'invalid token');
    tokenAddress = _token;
  }

  event Withdraw(
    address indexed owner,
    uint256 amountIn,
    uint256 etheretherOut
  );

  function withdraw(uint256 amountIn) external override returns (uint256) {
    require(amountIn >= minAmountIn, 'too few token');
    uint256 totalEther = address(this).balance;
    require(totalEther > 0, 'no ether');
    IERC20 erc = IERC20(tokenAddress);
    uint256 totalAmount = erc.totalSupply();
    uint256 etherOut = (totalEther * amountIn) / totalAmount;

    erc.transferFrom(msg.sender, address(this), amountIn);
    erc.burn(amountIn);

    safeTransferETH(msg.sender, etherOut);
    emit Withdraw(msg.sender, amountIn, etherOut);
    return etherOut;
  }

  event Deposit(address, uint256);

  function deposit() external payable override {
    emit Deposit(msg.sender, msg.value);
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'STE');
  }
}