// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./Pool.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract CreditLine is Initializable, OwnableUpgradeSafe {
  // Credit line terms
  address public borrower;
  uint public collateral;
  uint public limit;
  uint public interestApr;
  uint public minCollateralPercent;
  uint public paymentPeriodInDays;
  uint public termInDays;

  // Accounting variables
  uint public balance;
  uint public interestOwed;
  uint public principalOwed;
  uint public prepaymentBalance;
  uint public collateralBalance;
  uint public termEndBlock;
  uint public nextDueBlock;
  uint public lastUpdatedBlock;

  function initialize(
    address _borrower,
    uint _limit,
    uint _interestApr,
    uint _minCollateralPercent,
    uint _paymentPeriodInDays,
    uint _termInDays
  ) public initializer {
    __Ownable_init();
    borrower = _borrower;
    limit = _limit;
    interestApr = _interestApr;
    minCollateralPercent = _minCollateralPercent;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lastUpdatedBlock = block.number;
  }

  function setTermEndBlock(uint newTermEndBlock) external onlyOwner returns (uint) {
    return termEndBlock = newTermEndBlock;
  }

  function setNextDueBlock(uint newNextDueBlock) external onlyOwner returns (uint) {
    return nextDueBlock = newNextDueBlock;
  }

  function setBalance(uint newBalance) external onlyOwner returns(uint) {
    return balance = newBalance;
  }

  function setInterestOwed(uint newInterestOwed) external onlyOwner returns (uint) {
    return interestOwed = newInterestOwed;
  }

  function setPrincipalOwed(uint newPrincipalOwed) external onlyOwner returns (uint) {
    return principalOwed = newPrincipalOwed;
  }

  function setPrepaymentBalance(uint newPrepaymentBalance) external onlyOwner returns (uint) {
    return prepaymentBalance = newPrepaymentBalance;
  }

  function setCollateralBalance(uint newCollateralBalance) external onlyOwner returns (uint) {
    return collateralBalance = newCollateralBalance;
  }

  function setLastUpdatedBlock(uint newLastUpdatedBlock) external onlyOwner returns (uint) {
    return lastUpdatedBlock = newLastUpdatedBlock;
  }

  function authorizePool(address poolAddress) external onlyOwner {
    address erc20address = Pool(poolAddress).erc20address();

    // Approve the pool for an infinite amount
    ERC20UpgradeSafe(erc20address).approve(poolAddress, uint(-1));
  }
}
