// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "../OwnerPausable.sol";
import "../Pool.sol";
import "../Accountant.sol";
import "../CreditLine.sol";

contract FakeV2CreditDesk is Initializable, OwnableUpgradeSafe, OwnerPausable {
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
    poolAddress = _poolAddress;
  }

  function someBrandNewFunction() public pure returns(uint) {
    return 5;
  }

  function getUnderwriterCreditLines(address underwriterAddress) public view returns (address[] memory) {
    return underwriters[underwriterAddress].creditLines;
  }

  /*
   * Internal Functions
  */

}
