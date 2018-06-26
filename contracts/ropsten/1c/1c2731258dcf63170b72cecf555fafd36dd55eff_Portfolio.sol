pragma solidity ^0.4.17;

// File: contracts/assembly/Allocations.sol

library Allocations {

  uint constant NUM_ALLOCATIONS = 5;

  struct Allocation {
    bytes16 name;
    uint8 percent;
  }

  /**
    * Packs an Investment struct into a 32-byte array
    * AAAASSEEHHHHHHHHHHHHHHHHHHHHHHHH
    * A = amount
    * S = Start time, compressed as days since January 1, 2018
    * S = End time, compressed as days since January 1, 2018
    * H = holding
    */
  function packAllocation(uint8[NUM_ALLOCATIONS] allocations) internal pure returns (bytes32) {
    bytes32 result;
    uint8 total;
    for (uint i = 0; i < NUM_ALLOCATIONS; i++) {
      result = (result << 8) | bytes32(allocations[i]);
      total += allocations[i];
    }
    require(total == 100);
    return result;
  }

  function unpackAllocation(bytes32 packedAllocation) internal pure returns (uint8[NUM_ALLOCATIONS] result) {
    for (uint i = 0; i < NUM_ALLOCATIONS; i++) {
      result[i] = uint8(bytes32(0xFF) & (packedAllocation >> ((NUM_ALLOCATIONS - (i + 1)) * 8)));
    }
  }
}

// File: contracts/assembly/Investments.sol

library Investments {

  uint constant DAYS_FROM_UNIX_TO_JAN1_2018 = 17532;
  uint constant BYTE = 8;

  struct Investment {
    uint32 amount;
    bytes24 holding;
    uint start;
    uint end;
  }

  /**
    * Packs an Investment struct into a 32-byte array
    * AAAASSEEHHHHHHHHHHHHHHHHHHHHHHHH
    * A = amount
    * S = Start time, compressed as days since January 1, 2018
    * S = End time, compressed as days since January 1, 2018
    * H = holding
    */
  function packInvestment(Investment investment) internal pure returns (bytes32) {
    bytes32 result = bytes32(investment.amount);

    bytes32 startDays = bytes32((investment.start / 1 days) - DAYS_FROM_UNIX_TO_JAN1_2018);
    result = (result << (2 * BYTE)) | startDays;

    bytes32 endDays = bytes32((investment.end / 1 days) - DAYS_FROM_UNIX_TO_JAN1_2018);
    result = (result << (2 * BYTE)) | endDays;

    result = (result << (24 * BYTE)) | (bytes32(investment.holding) >> (8 * BYTE));

    return result;
  }

  function unpackInvestment(bytes32 packedInvestment) internal pure returns (Investment result) {
    bytes32 holdingMask = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << (8 * BYTE);
    result.holding = bytes24((packedInvestment << (8 * BYTE)) & holdingMask);
    packedInvestment = packedInvestment >> (24 * BYTE);

    result.end = (uint(packedInvestment & 0xFFFF) + DAYS_FROM_UNIX_TO_JAN1_2018) * 1 days;
    packedInvestment = packedInvestment >> (2 * BYTE);

    result.start = (uint(packedInvestment & 0xFFFF) + DAYS_FROM_UNIX_TO_JAN1_2018) * 1 days;
    packedInvestment = packedInvestment >> (2 * BYTE);

    result.amount = uint32(packedInvestment & 0xFFFFFFFF);
  }
}

// File: zeppelin/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/assembly/Portfolio.sol

contract Portfolio {
  using SafeMath for uint256;

  uint constant NUM_ALLOCATIONS = 5;

  Allocations.Allocation[NUM_ALLOCATIONS] allocations;
  Investments.Investment[] investments;

  address assemblyAddress;

  event AllocationsChanged();
  event InvestmentAdded(uint index);

  function Portfolio(address _assembly) public {
    assemblyAddress = _assembly;

    allocations[0] = Allocations.Allocation(&quot;Tactical Capital&quot;, 48);
    allocations[1] = Allocations.Allocation(&quot;Safety Net&quot;, 20);
    allocations[2] = Allocations.Allocation(&quot;Options&quot;, 20);
    allocations[3] = Allocations.Allocation(&quot;Non-Profit&quot;, 10);
    allocations[4] = Allocations.Allocation(&quot;Management&quot;, 2);
  }

  function getAllocation(uint index) public view returns (bytes16, uint8) {
    return (allocations[index].name, allocations[index].percent);
  }

  function setAllocations(bytes32 newAllocations) public onlyAssembly {
    uint8[NUM_ALLOCATIONS] memory percents = Allocations.unpackAllocation(newAllocations);
    for (uint i = 0; i < NUM_ALLOCATIONS; i++) {
      allocations[i].percent = percents[i];
    }
    assertCorrectAllocations();
    AllocationsChanged();
  }

  function getNumInvestments() public view returns (uint) {
    return investments.length;
  }

  function getInvestment(uint index) public view returns (uint32, bytes24, uint, uint) {
    return (investments[index].amount, investments[index].holding,
      investments[index].start, investments[index].end);
  }

  function addInvestment(bytes32 newInvestment) public onlyAssembly {
    Investments.Investment memory investment = Investments.unpackInvestment(newInvestment);
    investment.start = now;
    investments.push(investment);
    InvestmentAdded(investments.length - 1);
  }

  function assertCorrectAllocations() private {
    uint8 total = 0;
    for (uint8 i = 0; i < NUM_ALLOCATIONS; i++) {
      total += allocations[i].percent;
    }
    require(total == 100);
  }

  modifier onlyAssembly() {
    require(msg.sender == assemblyAddress);
    _;
  }
}