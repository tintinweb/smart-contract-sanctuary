/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

struct LoanBalances {
  int256 outstanding24;
  int256 fee24;
  int256 late24;
  int256 pool24;
  int256 netValue24;
  uint256 lastUpdatedAt;
}

enum LoanStatus {
  REGISTERED,
  DISBURSED,
  CLOSED,
  DEFAULTED
}

struct Loan {
  uint256 repaymentDate;
  int256 principal24;
  int256 amountRepaid24;
  int256 lateFee24;
  uint256 disbursementDate;
  uint256 actualTimeDisbursed;
  int256 dailyRate24;
  address borrower;
  LoanBalances balances;
  LoanStatus status;
}

interface ILoanNFT {
  function mintNewLoan(bytes calldata _loan) external returns (uint256);

  function updateMultipleLoanValues(uint256[] calldata _loanIDs) external;

  function updateLoanValue(uint256 _loanID) external;

  function getTotalLoanValue(address _loanOwner) external view returns (uint256);

  function getLoan(uint256 _loanId) external view returns (Loan memory);

  function getLoanValue(uint256 _loanId)
    external
    view
    returns (
      uint256 loanOutstandingBal,
      uint256 loanFeeBal,
      uint256 loanLatePenaltyBal,
      uint256 loanPoolBal,
      uint256 netLoanValue,
      uint256 lastUpdatedAt
    );

  function updateAmountPaid(uint256 _loanId, int256 _loanRepayment24)
    external
    returns (
      uint256 _amountToPool,
      uint256 _amountToOriginator,
      uint256 _amountToGovernance
    );

  function disburse(uint256 _loanID) external;

  function getNumLoans() external view returns (uint256);

  function getLoanOwner(uint256 _loanID) external view returns (address);
}

abstract contract LoanKeepersJob is KeeperCompatibleInterface {
  uint256 public constant MAX_LOANS_TO_UPDATE = 10;

  address public loanNFTAddress;

  constructor(address _loanNFTAddress) {
    loanNFTAddress = _loanNFTAddress;
  }

  function checkUpkeep(
    bytes calldata /* checkData */
  ) external view override returns (bool upkeepNeeded, bytes memory performData) {
    ILoanNFT loanNFT = ILoanNFT(loanNFTAddress);
    uint256 numLoans = loanNFT.getNumLoans();
    uint256[] memory loanIDs = new uint256[](MAX_LOANS_TO_UPDATE);
    uint256 numLoansToUpdate = 0;
    uint256 currLoanID = 0;

    while (numLoansToUpdate < loanIDs.length && currLoanID < numLoans) {
      if (_shouldUpdateLoan(currLoanID)) {
        loanIDs[numLoansToUpdate] = currLoanID;
        numLoansToUpdate += 1;
      }
      currLoanID += 1;
    }

    upkeepNeeded = numLoansToUpdate > 0;
    performData = abi.encode(loanIDs);
  }

  function _shouldUpdateLoan(uint256 _loanID) internal view virtual returns (bool);
}

enum Tranche {
  JUNIOR,
  SENIOR
}

interface ILendingPool {
  function init(
    address _jCopToken,
    address _sCopToken,
    address _copraGlobal,
    address _loanNFT
  ) external;

  function registerLoan(bytes calldata _loan) external;

  function payLoan(uint256 _loanId, uint256 _amount) external;

  function disburse(uint256 _loanId) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function getOriginator() external view returns (address);

  function updateSeniorObligation() external;

  function getLastUpdatedAt() external view returns (uint256);
}

contract LoanDisburser is LoanKeepersJob {
  constructor(address _loanNFTAddress) LoanKeepersJob(_loanNFTAddress) {}

  function _shouldUpdateLoan(uint256 _loanID) internal view override returns (bool) {
    Loan memory loan = (ILoanNFT(loanNFTAddress)).getLoan(_loanID);
    return loan.disbursementDate <= block.timestamp && loan.actualTimeDisbursed == 0;
  }

  // Capped at 10 loans per execution
  function performUpkeep(bytes calldata performData) external override {
    uint256[] memory loanIDs = abi.decode(performData, (uint256[]));
    for (uint256 i = 0; i < loanIDs.length; i++) {
      uint256 loanID = loanIDs[i];
      address lpAddress = (ILoanNFT(loanNFTAddress)).getLoanOwner(loanID);
      (ILendingPool(lpAddress)).disburse(loanID);
    }
  }
}