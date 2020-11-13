// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./Pool.sol";
import "./Accountant.sol";
import "./CreditLine.sol";
import "./OwnerPausable.sol";

contract CreditDesk is Initializable, OwnableUpgradeSafe, OwnerPausable {
  using SafeMath for uint256;

  // Approximate number of blocks
  uint public constant blocksPerDay = 5760;
  address public poolAddress;
  uint public maxUnderwriterLimit = 0;
  uint public transactionLimit = 0;

  struct Underwriter {
    uint governanceLimit;
    address[] creditLines;
  }

  struct Borrower {
    address[] creditLines;
  }

  event PaymentMade(address indexed payer, address indexed creditLine, uint interestAmount, uint principalAmount, uint remainingAmount);
  event PrepaymentMade(address indexed payer, address indexed creditLine, uint prepaymentAmount);
  event DrawdownMade(address indexed borrower, address indexed creditLine, uint drawdownAmount);
  event CreditLineCreated(address indexed borrower, address indexed creditLine);
  event PoolAddressUpdated(address indexed oldAddress, address indexed newAddress);
  event GovernanceUpdatedUnderwriterLimit(address indexed underwriter, uint newLimit);
  event LimitChanged(address indexed owner, string limitType, uint amount);

  mapping(address => Underwriter) public underwriters;
  mapping(address => Borrower) private borrowers;

  function initialize(address _poolAddress) public initializer {
    __Ownable_init();
    __OwnerPausable__init();
    setPoolAddress(_poolAddress);
  }

  function setUnderwriterGovernanceLimit(address underwriterAddress, uint limit) external onlyOwner whenNotPaused {
    Underwriter storage underwriter = underwriters[underwriterAddress];
    require(withinMaxUnderwriterLimit(limit), "This limit is greater than the max allowed by the protocol");
    underwriter.governanceLimit = limit;
    emit GovernanceUpdatedUnderwriterLimit(underwriterAddress, limit);
  }

  function createCreditLine(address _borrower, uint _limit, uint _interestApr, uint _minCollateralPercent, uint _paymentPeriodInDays, uint _termInDays) external whenNotPaused {
    Underwriter storage underwriter = underwriters[msg.sender];
    Borrower storage borrower = borrowers[_borrower];
    require(underwriterCanCreateThisCreditLine(_limit, underwriter), "The underwriter cannot create this credit line");

    CreditLine cl = new CreditLine();
    cl.initialize(_borrower, _limit, _interestApr, _minCollateralPercent, _paymentPeriodInDays, _termInDays);
    cl.authorizePool(poolAddress);

    underwriter.creditLines.push(address(cl));
    borrower.creditLines.push(address(cl));
    emit CreditLineCreated(_borrower, address(cl));
	}

  function drawdown(uint amount, address creditLineAddress) external whenNotPaused {
    CreditLine cl = CreditLine(creditLineAddress);
    require(cl.borrower() == msg.sender, "You do not belong to this credit line");
    // Not strictly necessary, but provides a better error message to the user
    require(getPool().enoughBalance(poolAddress, amount), "Pool does not have enough balance for this drawdown");
    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");
    require(withinCreditLimit(amount, cl), "The borrower does not have enough credit limit for this drawdown");

    if (cl.balance() == 0) {
      cl.setTermEndBlock(calculateNewTermEndBlock(cl));
      cl.setNextDueBlock(calculateNextDueBlock(cl));
    }
    (uint interestOwed, uint principalOwed) = getInterestAndPrincipalOwedAsOf(cl, block.number);
    uint balance = cl.balance().add(amount);

    updateCreditLineAccounting(cl, balance, interestOwed, principalOwed);
    getPool().transferFrom(poolAddress, msg.sender, amount);

    emit DrawdownMade(msg.sender, address(cl), amount);
  }

  function pay(address creditLineAddress, uint amount) external payable whenNotPaused {
    CreditLine cl = CreditLine(creditLineAddress);

    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");
    // Not strictly necessary, but provides a faster/better error message to the user
    require(getPool().enoughBalance(msg.sender, amount), "You have insufficent balance for this payment");

    (uint paymentRemaining, uint interestPayment, uint principalPayment) = handlePayment(cl, amount, block.number, true);
    if (paymentRemaining > 0) {
      getPool().transferFrom(msg.sender, creditLineAddress, paymentRemaining);
      cl.setCollateralBalance(cl.collateralBalance().add(paymentRemaining));
    }
    if (interestPayment > 0) {
      getPool().collectInterestRepayment(msg.sender, interestPayment);
    }
    if (principalPayment > 0) {
      getPool().collectPrincipalRepayment(msg.sender, principalPayment);
    }

    emit PaymentMade(cl.borrower(), address(cl), interestPayment, principalPayment, paymentRemaining);
  }

  function prepay(address payable creditLineAddress, uint amount) external payable whenNotPaused {
    CreditLine cl = CreditLine(creditLineAddress);

    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");

    getPool().transferFrom(msg.sender, creditLineAddress, amount);
    uint newPrepaymentBalance = cl.prepaymentBalance().add(amount);
    cl.setPrepaymentBalance(newPrepaymentBalance);

    emit PrepaymentMade(msg.sender, address(cl), amount);
  }

  function addCollateral(address payable creditLineAddress, uint amount) external payable whenNotPaused {
    CreditLine cl = CreditLine(creditLineAddress);

    getPool().transferFrom(msg.sender, creditLineAddress, amount);
    uint newCollateralBalance = cl.collateralBalance().add(amount);
    cl.setCollateralBalance(newCollateralBalance);
  }

  function assessCreditLine(address creditLineAddress) external whenNotPaused {
    CreditLine cl = CreditLine(creditLineAddress);
    // Do not assess until a full period has elapsed
    if (block.number < cl.nextDueBlock()) {
      return;
    }

    (uint paymentRemaining, uint interestPayment, uint principalPayment) = handlePayment(cl, cl.prepaymentBalance(), cl.nextDueBlock(), false);

    cl.setPrepaymentBalance(paymentRemaining);
    getPool().collectInterestRepayment(msg.sender, interestPayment);
    getPool().collectPrincipalRepayment(msg.sender, principalPayment);
    cl.setNextDueBlock(calculateNextDueBlock(cl));
    if (cl.principalOwed() > 0) {
      handleLatePayments(cl);
    }
    emit PaymentMade(cl.borrower(), address(cl), interestPayment, principalPayment, paymentRemaining);
  }

  function setPoolAddress(address newPoolAddress) public onlyOwner whenNotPaused returns (address) {
    // Sanity check the new address;
    Pool(newPoolAddress).totalShares();

    emit PoolAddressUpdated(poolAddress, newPoolAddress);
    return poolAddress = newPoolAddress;
  }

  function setMaxUnderwriterLimit(uint amount) public onlyOwner whenNotPaused {
    maxUnderwriterLimit = amount;
    emit LimitChanged(msg.sender, "maxUnderwriterLimit", amount);
  }

  function setTransactionLimit(uint amount) public onlyOwner whenNotPaused {
    transactionLimit = amount;
    emit LimitChanged(msg.sender, "transactionLimit", amount);
  }

  // Public View Functions (Getters)

  function getUnderwriterCreditLines(address underwriterAddress) public view whenNotPaused returns (address[] memory) {
    return underwriters[underwriterAddress].creditLines;
  }

  function getBorrowerCreditLines(address borrowerAddress) public view whenNotPaused returns (address[] memory) {
    return borrowers[borrowerAddress].creditLines;
  }

  /*
   * Internal Functions
  */

  function handlePayment(CreditLine cl, uint paymentAmount, uint asOfBlock, bool allowFullBalancePayOff) internal returns (uint, uint, uint) {
    (uint interestOwed, uint principalOwed) = getInterestAndPrincipalOwedAsOf(cl, asOfBlock);
    Accountant.PaymentAllocation memory pa = Accountant.allocatePayment(paymentAmount, cl.balance(), interestOwed, principalOwed);

    uint newBalance = cl.balance().sub(pa.principalPayment);
    if (allowFullBalancePayOff) {
      newBalance = newBalance.sub(pa.additionalBalancePayment);
    }
    uint totalPrincipalPayment = cl.balance().sub(newBalance);
    uint paymentRemaining = paymentAmount.sub(pa.interestPayment).sub(totalPrincipalPayment);

    updateCreditLineAccounting(cl, newBalance, interestOwed.sub(pa.interestPayment), principalOwed.sub(pa.principalPayment));

    assert(paymentRemaining.add(pa.interestPayment).add(totalPrincipalPayment) == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function handleLatePayments(CreditLine cl) internal {
    // No op for now;
  }

  function getPool() internal view returns (Pool) {
    return Pool(poolAddress);
  }

  function getInterestAndPrincipalOwedAsOf(CreditLine cl, uint blockNumber) internal view returns (uint, uint) {
    (uint interestAccrued, uint principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(cl, blockNumber);
    return (cl.interestOwed().add(interestAccrued), cl.principalOwed().add(principalAccrued));
  }

  function withinCreditLimit(uint amount, CreditLine cl) internal view returns(bool) {
    return cl.balance().add(amount) <= cl.limit();
  }

  function withinTransactionLimit(uint amount) internal view returns(bool) {
    return amount <= transactionLimit;
  }

  function calculateNewTermEndBlock(CreditLine cl) internal view returns (uint) {
    return block.number.add(blocksPerDay.mul(cl.termInDays()));
  }

  function calculateNextDueBlock(CreditLine cl) internal view returns (uint) {
    uint blocksPerPeriod = cl.paymentPeriodInDays().mul(blocksPerDay);
    uint currentNextDueBlock;
    if (cl.nextDueBlock() != 0) {
      currentNextDueBlock = cl.nextDueBlock();
    } else {
      currentNextDueBlock = block.number;
    }
    return currentNextDueBlock.add(blocksPerPeriod);
  }

  function underwriterCanCreateThisCreditLine(uint newAmount, Underwriter storage underwriter) internal view returns(bool) {
    uint creditCurrentlyExtended = getCreditCurrentlyExtended(underwriter);
    uint totalToBeExtended = creditCurrentlyExtended.add(newAmount);
    return totalToBeExtended <= underwriter.governanceLimit;
  }

  function withinMaxUnderwriterLimit(uint amount) internal view returns (bool) {
    return amount <= maxUnderwriterLimit;
  }

  function getCreditCurrentlyExtended(Underwriter storage underwriter) internal view returns (uint) {
    uint creditExtended = 0;
    for (uint i = 0; i < underwriter.creditLines.length; i++) {
      CreditLine cl = CreditLine(underwriter.creditLines[i]);
      creditExtended = creditExtended.add(cl.limit());
    }
    return creditExtended;
  }

  function updateCreditLineAccounting(CreditLine cl, uint balance, uint interestOwed, uint principalOwed) internal {
    cl.setBalance(balance);
    cl.setInterestOwed(interestOwed);
    cl.setPrincipalOwed(principalOwed);
    cl.setLastUpdatedBlock(block.number);

    if (balance == 0) {
      cl.setTermEndBlock(0);
      cl.setNextDueBlock(0);
    }
  }
}
