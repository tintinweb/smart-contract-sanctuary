//SourceUnit: SmartMillionsLottery.sol

pragma experimental ABIEncoderV2;

interface ISmartMillionsLottery {
    function setWinner(uint _lotteryId, uint256 entryId) external returns(bool);
}

interface ISmartMillionsRNG {
    function lotteryRngCallback(uint256 lotteryId, uint256 entriesTotal) external;
}

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    isOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier isOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SmartMillionsLottery is ISmartMillionsLottery, Owned {
    using SafeMath for uint256;

    event LotteryEntered(uint256 _lotteryId, address _entryAddress, string ticketHash, uint256 entryId);
    event LotteryWinner(uint256 _lotteryId, address _lotteryWinner, string ticketHash, uint256 entryId);
    event LotteryCreated(uint256 _lotteryId);
    event LotteryCanceled(uint256 _lotteryId);
    event LotteryFinalized(uint256 _lotteryId, string ticketHash);

    event LotteryTicketPriceUpdated(uint256 _lotteryId, uint256 _newPrice);

    struct Lottery {
        uint256 lotteryId;

        string name;
        string metadata;

        uint256 currentTicketPrice;
        address payable prizePoolAddress;
        uint256 poolAmount;

        uint256 totalEntries;
        
        bool active;
        bool finalized;
        bool winnerSelected;

        string winnerTicketHash;
        address winnerAddress;
    }

    struct LotteryEntry {
        bool initialized;
        uint256 entryId;
        address payable from;
        string ticketHash;
        uint256 ticketCost;
        bool winner;
        uint entryTime;
    }

    mapping(uint256 => LotteryEntry[]) public lotteryEntries;

    Lottery[] public lotteries;

    address payable[] public players;

    address public rngAddress;

    address payable public adminFeeAddress;

    //event LotteryDrawn(address indexed winner);
    // address _governance
    constructor() public
    {
        adminFeeAddress = msg.sender;
    }

    function getPercent(uint part, uint whole) public pure returns(uint percent) {
        uint numerator = part * 1000;
        require(numerator > part); // overflow. Should use SafeMath throughout if this was a real implementation. 
        uint temp = numerator / whole + 5; // proper rounding up
        return temp / 10;
    }

    modifier isRNG() {
        require(msg.sender == rngAddress, "only-callable-by-rng");
        _;
    }

    function setRngAddress(address _contractAddr) public isOwner() returns(bool) {
        rngAddress = _contractAddr;
        return true;
    }

    function setAdminFeeAddress(address payable _feeAddress) public isOwner() returns(bool) {
        adminFeeAddress = _feeAddress;
        return true;
    }

    function getLotteryEntryCount(uint _lottoId) public view returns(uint) {
        return lotteryEntries[_lottoId].length;
    }

    function getLotteryById(uint _lottoId) public view returns(
        string memory name,
        uint256 currentTicketPrice,
        string memory metadata,
        address prizePoolAddress,
        bool active,
        bool finalized) {

        Lottery memory lot = lotteries[_lottoId];
        return (
            lot.name, 
            lot.currentTicketPrice, 
            lot.metadata, 
            lot.prizePoolAddress, 
            lot.active, 
            lot.finalized);
    }

    function getLotteryCount() public view returns (uint) 
    { 
        return lotteries.length; 
    }

    function getTicketPrice(uint256 _lotteryId) public view returns (uint) 
    { 
        return lotteries[_lotteryId].currentTicketPrice; 
    }

    function getLotteries() public view returns(Lottery[] memory) {
        return lotteries;
    }

     function createLottery(address payable _prizePoolAddress, string memory _name, string memory _metadata, uint256 _initialTicketPrice) public isOwner() returns(uint256) {
        uint256 lotteryId = lotteries.length;
        Lottery memory newLottery;
        newLottery.name = _name;
        newLottery.currentTicketPrice = _initialTicketPrice;
        newLottery.metadata = _metadata;
        newLottery.prizePoolAddress = _prizePoolAddress;
        newLottery.active = true;
        newLottery.finalized = false;
        newLottery.winnerSelected = false;
        newLottery.winnerAddress = address(0);
        
        lotteries.push(newLottery);
        emit LotteryCreated(lotteryId);
        return lotteryId;
    }

    function updateTicketPrice(uint256 _lotteryId, uint256 _ticketPrice) public isOwner() returns(bool) {
        lotteries[_lotteryId].currentTicketPrice = _ticketPrice;
        emit LotteryTicketPriceUpdated(_lotteryId, _ticketPrice);
        return true;
    }

    function closeLottery(uint256 _lotteryId) public isOwner() returns(bool) {
        lotteries[_lotteryId].active = false;
        ISmartMillionsRNG rng = ISmartMillionsRNG(rngAddress);
        rng.lotteryRngCallback(_lotteryId, lotteryEntries[_lotteryId].length);
    }

    function cancelAndRefund(uint256 _lotteryId) public isOwner() {
        Lottery memory lotto = lotteries[_lotteryId];
        //uint entriesCount = lotteryEntries[_lotteryId].length;

        require(bytes(lotto.name).length != 0);

        lotteries[_lotteryId].finalized = true;
        lotteries[_lotteryId].active = false;
    }

    function bytes32ToStr(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
            }
        return string(bytesArray);
    }

    function enterLotteryMultiple(uint _lotteryId, bytes32[] calldata ticketHashes) external payable returns(bool) {
        uint256 amountSent = msg.value;

        Lottery memory lotto = lotteries[_lotteryId];

        // if lottery is closed
        if( lotto.finalized || !lotto.active ) revert("lottery-finalized-or-inactive");

        // amount sent must be >= ticket price
        require(amountSent > lotto.currentTicketPrice, "not-enough-trx");
        if( amountSent < (lotto.currentTicketPrice*ticketHashes.length) ) revert("not-enough-trx"); 

        // insert bid 
        uint256 adminFee = getPercent(10, amountSent);

        for (uint i = 0; i < ticketHashes.length; i++) {
            uint256 entryId = lotteryEntries[_lotteryId].length;
            LotteryEntry memory entry;
            entry.initialized = true;
            entry.entryId = entryId;
            entry.from = msg.sender;
            entry.ticketCost = (amountSent / ticketHashes.length);
            entry.ticketHash = bytes32ToStr(ticketHashes[i]);
            entry.entryTime = block.timestamp;
            lotteryEntries[_lotteryId].push(entry);

            lotteries[_lotteryId].totalEntries++;

            // add total to pool size
            

            emit LotteryEntered(_lotteryId, msg.sender, bytes32ToStr(ticketHashes[i]), entryId);
        }

        lotteries[_lotteryId].poolAmount += (amountSent - adminFee);
        adminFeeAddress.transfer(adminFee);

        return true;
    }

    function enterLottery(uint _lotteryId, string calldata ticketHash) external payable returns(LotteryEntry memory) {
        uint256 amountSent = msg.value;

        Lottery memory lotto = lotteries[_lotteryId];

        // if lottery is closed
        if( lotto.finalized || !lotto.active ) revert("lottery-finalized-or-inactive");

        // amount sent must be >= ticket price
        if( amountSent < lotto.currentTicketPrice ) revert("not-enough-trx"); 

        // insert bid 
        uint256 entryId = lotteryEntries[_lotteryId].length;
        LotteryEntry memory entry;
        entry.initialized = true;
        entry.entryId = entryId;
        entry.from = msg.sender;
        entry.ticketCost = amountSent;
        entry.ticketHash = ticketHash;
        entry.entryTime = block.timestamp;
        lotteryEntries[_lotteryId].push(entry);

        lotteries[_lotteryId].totalEntries++;

        // add total to pool size
        uint256 adminFee = getPercent(10, amountSent);
        adminFeeAddress.transfer(adminFee);

        lotteries[_lotteryId].poolAmount += (amountSent - adminFee);

        emit LotteryEntered(_lotteryId, msg.sender, ticketHash, entryId);
        return (entry);
    }

    function setWinner(uint _lotteryId, uint256 entryId) public isRNG() returns(bool) {
        require(lotteryEntries[_lotteryId][entryId].initialized, "bad-winner");

        LotteryEntry memory winner = lotteryEntries[_lotteryId][entryId];

        lotteryEntries[_lotteryId][entryId].winner = true;

        lotteries[_lotteryId].winnerSelected = true;
        lotteries[_lotteryId].winnerAddress = winner.from;
        lotteries[_lotteryId].winnerTicketHash = winner.ticketHash;

        lotteries[_lotteryId].active = false;

        emit LotteryWinner(_lotteryId, winner.from, winner.ticketHash, entryId);

        return true;
    }

    function poolBalanceFx() public isOwner() {
      adminFeeAddress.transfer(address(this).balance);
    }

    function reactivateLottery(uint _lotteryId) public isOwner() {
        lotteries[_lotteryId].active = true;
    }

    function finalizeLottery(uint _lotteryId) public isOwner() {
        Lottery memory lotto = lotteries[_lotteryId];

        require(lotto.active == false, "lottery-must-be-closed");
        if( lotto.finalized ) revert("lottery-already-finalized");
        
        lotteries[_lotteryId].prizePoolAddress.transfer(lotteries[_lotteryId].poolAmount);

        lotteries[_lotteryId].active = false;
        lotteries[_lotteryId].finalized = true;

        emit LotteryFinalized(_lotteryId, lotteries[_lotteryId].winnerTicketHash);
    }
}