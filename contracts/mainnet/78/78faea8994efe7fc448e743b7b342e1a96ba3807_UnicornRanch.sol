pragma solidity ^0.4.11;

contract ERC20Token {
  function balanceOf(address _who) constant returns (uint balance);
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  function transferFrom(address _from, address _to, uint _value);
  function transfer(address _to, uint _value);
}
contract GroveAPI {
  function insert(bytes32 indexName, bytes32 id, int value) public;
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract UnicornRanch {
  using SafeMath for uint;

  enum VisitType { Spa, Afternoon, Day, Overnight, Week, Extended }
  enum VisitState { InProgress, Completed, Repossessed }
  
  struct Visit {
    uint unicornCount;
    VisitType t;
    uint startBlock;
    uint expiresBlock;
    VisitState state;
    uint completedBlock;
    uint completedCount;
  }
  struct VisitMeta {
    address owner;
    uint index;
  }
  
  address public cardboardUnicornTokenAddress;
  address public groveAddress;
  address public owner = msg.sender;
  mapping (address => Visit[]) bookings;
  mapping (bytes32 => VisitMeta) public bookingMetadataForKey;
  mapping (uint8 => uint) public visitLength;
  mapping (uint8 => uint) public visitCost;
  uint public visitingUnicorns = 0;
  uint public repossessionBlocks = 43200;
  uint8 public repossessionBountyPerTen = 2;
  uint8 public repossessionBountyPerHundred = 25;
  uint public birthBlockThreshold = 43860;
  uint8 public birthPerTen = 1;
  uint8 public birthPerHundred = 15;

  event NewBooking(address indexed _who, uint indexed _index, VisitType indexed _type, uint _unicornCount);
  event BookingUpdate(address indexed _who, uint indexed _index, VisitState indexed _newState, uint _unicornCount);
  event RepossessionBounty(address indexed _who, uint _unicornCount);
  event DonationReceived(address indexed _who, uint _unicornCount);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  function UnicornRanch() {
    visitLength[uint8(VisitType.Spa)] = 720;
    visitLength[uint8(VisitType.Afternoon)] = 1440;
    visitLength[uint8(VisitType.Day)] = 2880;
    visitLength[uint8(VisitType.Overnight)] = 8640;
    visitLength[uint8(VisitType.Week)] = 60480;
    visitLength[uint8(VisitType.Extended)] = 120960;
    
    visitCost[uint8(VisitType.Spa)] = 0;
    visitCost[uint8(VisitType.Afternoon)] = 0;
    visitCost[uint8(VisitType.Day)] = 10 szabo;
    visitCost[uint8(VisitType.Overnight)] = 30 szabo;
    visitCost[uint8(VisitType.Week)] = 50 szabo;
    visitCost[uint8(VisitType.Extended)] = 70 szabo;
  }


  function getBookingCount(address _who) constant returns (uint count) {
    return bookings[_who].length;
  }
  function getBooking(address _who, uint _index) constant returns (uint _unicornCount, VisitType _type, uint _startBlock, uint _expiresBlock, VisitState _state, uint _completedBlock, uint _completedCount) {
    Visit storage v = bookings[_who][_index];
    return (v.unicornCount, v.t, v.startBlock, v.expiresBlock, v.state, v.completedBlock, v.completedCount);
  }

  function bookSpaVisit(uint _unicornCount) payable {
    return addBooking(VisitType.Spa, _unicornCount);
  }
  function bookAfternoonVisit(uint _unicornCount) payable {
    return addBooking(VisitType.Afternoon, _unicornCount);
  }
  function bookDayVisit(uint _unicornCount) payable {
    return addBooking(VisitType.Day, _unicornCount);
  }
  function bookOvernightVisit(uint _unicornCount) payable {
    return addBooking(VisitType.Overnight, _unicornCount);
  }
  function bookWeekVisit(uint _unicornCount) payable {
    return addBooking(VisitType.Week, _unicornCount);
  }
  function bookExtendedVisit(uint _unicornCount) payable {
    return addBooking(VisitType.Extended, _unicornCount);
  }
  
  function addBooking(VisitType _type, uint _unicornCount) payable {
    if (_type == VisitType.Afternoon) {
      return donateUnicorns(availableBalance(msg.sender));
    }
    require(msg.value >= visitCost[uint8(_type)].mul(_unicornCount)); // Must be paying proper amount

    ERC20Token cardboardUnicorns = ERC20Token(cardboardUnicornTokenAddress);
    cardboardUnicorns.transferFrom(msg.sender, address(this), _unicornCount); // Transfer the actual asset
    visitingUnicorns = visitingUnicorns.add(_unicornCount);
    uint expiresBlock = block.number.add(visitLength[uint8(_type)]); // Calculate when this booking will be done
    
    // Add the booking to the ledger
    bookings[msg.sender].push(Visit(
      _unicornCount,
      _type,
      block.number,
      expiresBlock,
      VisitState.InProgress,
      0,
      0
    ));
    uint newIndex = bookings[msg.sender].length - 1;
    bytes32 uniqueKey = keccak256(msg.sender, newIndex); // Create a unique key for this booking
    
    // Add a reference for that key, to find the metadata about it later
    bookingMetadataForKey[uniqueKey] = VisitMeta(
      msg.sender,
      newIndex
    );
    
    if (groveAddress > 0) {
      // Insert into Grove index for applications to query
      GroveAPI g = GroveAPI(groveAddress);
      g.insert("bookingExpiration", uniqueKey, int(expiresBlock));
    }
    
    // Send event about this new booking
    NewBooking(msg.sender, newIndex, _type, _unicornCount);
  }
  
  function completeBooking(uint _index) {
    require(bookings[msg.sender].length > _index); // Sender must have at least this many bookings
    Visit storage v = bookings[msg.sender][_index];
    require(block.number >= v.expiresBlock); // Expired time must be past
    require(v.state == VisitState.InProgress); // Visit must not be complete or repossessed
    
    uint unicornsToReturn = v.unicornCount;
    ERC20Token cardboardUnicorns = ERC20Token(cardboardUnicornTokenAddress);

    // Determine if any births occurred
    uint birthCount = 0;
    if (SafeMath.sub(block.number, v.startBlock) >= birthBlockThreshold) {
      if (v.unicornCount >= 100) {
        birthCount = uint(birthPerHundred).mul(v.unicornCount / 100);
      } else if (v.unicornCount >= 10) {
        birthCount = uint(birthPerTen).mul(v.unicornCount / 10);
      }
    }
    if (birthCount > 0) {
      uint availableUnicorns = cardboardUnicorns.balanceOf(address(this)) - visitingUnicorns;
      if (availableUnicorns < birthCount) {
        birthCount = availableUnicorns;
      }
      unicornsToReturn = unicornsToReturn.add(birthCount);
    }
        
    // Update the status of the Visit
    v.state = VisitState.Completed;
    v.completedBlock = block.number;
    v.completedCount = unicornsToReturn;
    bookings[msg.sender][_index] = v;
    
    // Transfer the asset back to the owner
    visitingUnicorns = visitingUnicorns.sub(unicornsToReturn);
    cardboardUnicorns.transfer(msg.sender, unicornsToReturn);
    
    // Send event about this update
    BookingUpdate(msg.sender, _index, VisitState.Completed, unicornsToReturn);
  }
  
  function repossessBooking(address _who, uint _index) {
    require(bookings[_who].length > _index); // Address in question must have at least this many bookings
    Visit storage v = bookings[_who][_index];
    require(block.number > v.expiresBlock.add(repossessionBlocks)); // Repossession time must be past
    require(v.state == VisitState.InProgress); // Visit must not be complete or repossessed
    
    visitingUnicorns = visitingUnicorns.sub(v.unicornCount);
    
    // Send event about this update
    BookingUpdate(_who, _index, VisitState.Repossessed, v.unicornCount);
    
    // Calculate Bounty amount
    uint bountyCount = 1;
    if (v.unicornCount >= 100) {
        bountyCount = uint(repossessionBountyPerHundred).mul(v.unicornCount / 100);
    } else if (v.unicornCount >= 10) {
      bountyCount = uint(repossessionBountyPerTen).mul(v.unicornCount / 10);
    }
    
    // Send bounty to bounty hunter
    ERC20Token cardboardUnicorns = ERC20Token(cardboardUnicornTokenAddress);
    cardboardUnicorns.transfer(msg.sender, bountyCount);
    
    // Send event about the bounty payout
    RepossessionBounty(msg.sender, bountyCount);

    // Update the status of the Visit
    v.state = VisitState.Repossessed;
    v.completedBlock = block.number;
    v.completedCount = v.unicornCount - bountyCount;
    bookings[_who][_index] = v;
  }
  
  function availableBalance(address _who) internal returns (uint) {
    ERC20Token cardboardUnicorns = ERC20Token(cardboardUnicornTokenAddress);
    uint count = cardboardUnicorns.allowance(_who, address(this));
    if (count == 0) {
      return 0;
    }
    uint balance = cardboardUnicorns.balanceOf(_who);
    if (balance < count) {
      return balance;
    }
    return count;
  }
  
  function() payable {
    if (cardboardUnicornTokenAddress == 0) {
      return;
    }
    return donateUnicorns(availableBalance(msg.sender));
  }
  
  function donateUnicorns(uint _unicornCount) payable {
    if (_unicornCount == 0) {
      return;
    }
    ERC20Token cardboardUnicorns = ERC20Token(cardboardUnicornTokenAddress);
    cardboardUnicorns.transferFrom(msg.sender, address(this), _unicornCount);
    DonationReceived(msg.sender, _unicornCount);
  }
  
  /**
   * Change ownership of the Ranch
   */
  function changeOwner(address _newOwner) onlyOwner {
    owner = _newOwner;
  }

  /**
   * Change the outside contracts used by this contract
   */
  function changeCardboardUnicornTokenAddress(address _newTokenAddress) onlyOwner {
    cardboardUnicornTokenAddress = _newTokenAddress;
  }
  function changeGroveAddress(address _newAddress) onlyOwner {
    groveAddress = _newAddress;
  }
  
  /**
   * Update block durations for various types of visits
   */
  function changeVisitLengths(uint _spa, uint _afternoon, uint _day, uint _overnight, uint _week, uint _extended) onlyOwner {
    visitLength[uint8(VisitType.Spa)] = _spa;
    visitLength[uint8(VisitType.Afternoon)] = _afternoon;
    visitLength[uint8(VisitType.Day)] = _day;
    visitLength[uint8(VisitType.Overnight)] = _overnight;
    visitLength[uint8(VisitType.Week)] = _week;
    visitLength[uint8(VisitType.Extended)] = _extended;
  }
  
  /**
   * Update ether costs for various types of visits
   */
  function changeVisitCosts(uint _spa, uint _afternoon, uint _day, uint _overnight, uint _week, uint _extended) onlyOwner {
    visitCost[uint8(VisitType.Spa)] = _spa;
    visitCost[uint8(VisitType.Afternoon)] = _afternoon;
    visitCost[uint8(VisitType.Day)] = _day;
    visitCost[uint8(VisitType.Overnight)] = _overnight;
    visitCost[uint8(VisitType.Week)] = _week;
    visitCost[uint8(VisitType.Extended)] = _extended;
  }
  
  /**
   * Update bounty reward settings
   */
  function changeRepoSettings(uint _repoBlocks, uint8 _repoPerTen, uint8 _repoPerHundred) onlyOwner {
    repossessionBlocks = _repoBlocks;
    repossessionBountyPerTen = _repoPerTen;
    repossessionBountyPerHundred = _repoPerHundred;
  }
  
  /**
   * Update birth event settings
   */
  function changeBirthSettings(uint _birthBlocks, uint8 _birthPerTen, uint8 _birthPerHundred) onlyOwner {
    birthBlockThreshold = _birthBlocks;
    birthPerTen = _birthPerTen;
    birthPerHundred = _birthPerHundred;
  }

  function withdraw() onlyOwner {
    owner.transfer(this.balance); // Send all ether in this contract to this contract&#39;s owner
  }
  function withdrawForeignTokens(address _tokenContract) onlyOwner {
    ERC20Token token = ERC20Token(_tokenContract);
    token.transfer(owner, token.balanceOf(address(this))); // Send all owned tokens to this contract&#39;s owner
  }
  
}