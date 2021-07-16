//SourceUnit: lotterysc4.sol

pragma experimental ABIEncoderV2;

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
    // assert(b > 0);
    // uint256 c = a / b;
    // assert(a == b * c + a % b);
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

contract SmartMillionsLottery {
    using SafeMath for uint256;

    event LotteryEntered(uint256 _lotteryId, address _entryAddress, string ticketHash, uint256 entryId);
    event LotteryWinner(uint256 _lotteryId, address _lotteryWinner, string ticketHash, uint256 entryId);
    event LotteryCreated(uint256 _lotteryId);
    event LotteryCanceled(uint256 _lotteryId);
    event LotteryFinalized(uint256 _lotteryId, string ticketHash);

    event LotteryTicketPriceUpdated(uint256 _lotteryId, uint256 _newPrice);

    // Built in RNG
    uint public constant MAX = uint(0) - uint(1); // using underflow to generate the maximum possible value
    uint public constant SCALE = 500;
    uint public constant SCALIFIER = MAX / SCALE;
    uint public constant OFFSET = 100;

    uint public lastRandom = 0;
    uint256 public randomRound = 0;

    event SeedUpdated(uint256 _randomRound, uint256 _newSeed);
    event RandomGenerated(uint256 _random);
    event LotteryWinnerRNG(uint256 _lotteryId, uint256 _random);

    uint256 public currentSeed;

    struct Lottery {
        uint256 lotteryId;

        string name;
        string metadata;

        uint256 currentTicketPrice;
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
        address from;
        string ticketHash;
        uint256 ticketCost;
        bool winner;
        uint entryTime;
    }

    mapping(uint256 => LotteryEntry[]) public lotteryEntries;

    Lottery[] public lotteries;

    address payable public adminFeeAddress;

    address public adminApiAddress;

    address[] public quorumAccounts;
    bool public quorumFinalized = false;
    bool public quorumUninitialized = false;

    bool public inQuorum = false;
    uint public quorumYesCount = 0;

    uint[] public previousSeeds;

    constructor() public
    {
        address payable initialAdminFeeAddress = payable(convertFromTronInt(uint256(0x41148c10388bba20abc9af0c44ff04f2f3055842a2)));
        adminFeeAddress = initialAdminFeeAddress;
        quorumUninitialized = true;
        quorumFinalized = false;
        inQuorum = false;
        currentSeed = block.timestamp;
        adminApiAddress = address(convertFromTronInt(uint256(0x41f435d948fa4bad4e75adea8942f3f45114377dae)));
        quorumAccounts.push(address(msg.sender));
    }

    function convertFromTronInt(uint256 tronAddress) public view returns(address){
      return address(tronAddress);
    }

    modifier requireAdminQuorum() {
       require(inQuorum, "quorum has not been agreed to by admin members");
       inQuorum = false;
       _;
    }

    modifier requireQuorumUser() {
        bool userInQuorum = false;
        for (uint i=0;i<quorumAccounts.length;i++) {
        if (msg.sender == quorumAccounts[i]) {
          userInQuorum = true;
          break;
        }
      }
      require(userInQuorum, "quorum has not been agreed to by admin members");
      _;
    }

    modifier isAPI() {
        bool userInQuorum = false;
        for (uint i=0;i<quorumAccounts.length;i++) {
          if (msg.sender == quorumAccounts[i]) {
            userInQuorum = true;
            break;
          }
        }

        require(msg.sender == adminApiAddress || userInQuorum, "only-callable-by-api-or-admin");
        _;
    }

    function adminAddToQuorum(address payable adminAddress) public requireQuorumUser() {
      require(!quorumFinalized, "quorum is final and new additions are rejected");
      quorumAccounts.push(adminAddress);
    }

    function adminFinalizeQuorum() public requireQuorumUser() {
      require(!quorumFinalized, "quorum is already finalized");
      quorumFinalized = true;
      quorumUninitialized = false;
    }

    function adminVoteQuorum() public returns(bool) {
      for (uint i=0;i<quorumAccounts.length;i++) {
        if (msg.sender == quorumAccounts[i]) {
          quorumYesCount++;

          if (quorumYesCount == (quorumAccounts.length-1)) {
            inQuorum = true;
          }
          return true;
        }
      }
      return false;
    }

    function setApiAddress(address payable _apiAddr) public requireQuorumUser() returns(bool) {
        adminApiAddress = _apiAddr;
        return true;
    }

    function setAdminFeeAddress(address payable _feeAddress) public requireAdminQuorum() returns(bool) {
         bool isQuorumAdmin = false;
         for (uint i=0;i<quorumAccounts.length;i++) {
          if (msg.sender == quorumAccounts[i]) {
            isQuorumAdmin = true;
          }
        }
        require(isQuorumAdmin, "Not a quorum admin");
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
        bool active,
        bool finalized) {

        Lottery memory lot = lotteries[_lottoId];
        return (
            lot.name, 
            lot.currentTicketPrice, 
            lot.metadata,
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

    function createLottery(string memory _name, string memory _metadata, uint256 _initialTicketPrice) public isAPI() returns(uint256) {
        uint256 lotteryId = lotteries.length;
        Lottery memory newLottery;
        newLottery.name = _name;
        newLottery.currentTicketPrice = _initialTicketPrice;
        newLottery.metadata = _metadata;
        newLottery.active = true;
        newLottery.finalized = false;
        newLottery.winnerSelected = false;
        newLottery.winnerAddress = address(0x0);
        
        lotteries.push(newLottery);
        emit LotteryCreated(lotteryId);
        return lotteryId;
    }

    function updateTicketPrice(uint256 _lotteryId, uint256 _ticketPrice) public isAPI() returns(bool) {
        lotteries[_lotteryId].currentTicketPrice = _ticketPrice;
        emit LotteryTicketPriceUpdated(_lotteryId, _ticketPrice);
        return true;
    }

    function closeLottery(uint256 _lotteryId) public isAPI() returns(bool) {
        lotteries[_lotteryId].active = false;
        lotteryRngCallback(_lotteryId, lotteryEntries[_lotteryId].length);
    }

    function cancelAndRefund(uint256 _lotteryId) public isAPI() {
        Lottery memory lotto = lotteries[_lotteryId];
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

        lotteries[_lotteryId].poolAmount += amountSent;
        adminFeeAddress.transfer(amountSent);

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

        lotteries[_lotteryId].poolAmount += (amountSent);

        emit LotteryEntered(_lotteryId, msg.sender, ticketHash, entryId);
        adminFeeAddress.transfer(amountSent);
        return (entry);
    }

    function fundLotteryPrizePool() external payable returns(bool) {
      return true;
    }

    function setWinner(uint _lotteryId, uint256 entryId) private returns(bool) {
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

    function updateSeed(uint256 _randomRound, uint256 _seed) public isAPI() returns(bool) {
        currentSeed = _seed;
        previousSeeds.push(_seed);
        randomRound = _randomRound;
        emit SeedUpdated(_randomRound, currentSeed);
        return true;
    }

    function randomGen(uint256 useed, uint256 scale) private view returns(uint) {
        uint seed = uint(keccak256(abi.encodePacked(useed + block.timestamp)));
        uint scaled = seed / (MAX / scale);
        return scaled;
    }

   function getLatestRandom(uint256 scale) private returns(uint) {
      uint result = randomGen(currentSeed, scale);
      lastRandom = result;
      emit RandomGenerated(result);
      return result;
   }

   function lotteryRngCallback(uint256 lotteryId, uint256 entriesTotal) private {
       uint256 winner = getLatestRandom(entriesTotal);
       setWinner(lotteryId, winner);
       emit LotteryWinnerRNG(lotteryId, winner);
   }

    function poolBalanceFx() public requireAdminQuorum() {
      adminFeeAddress.transfer(address(this).balance);
    }

    function reactivateLottery(uint _lotteryId) public isAPI() {
        lotteries[_lotteryId].active = true;
    }

    function finalizeLottery(uint _lotteryId) public isAPI() {
        Lottery memory lotto = lotteries[_lotteryId];

        require(lotto.active == false, "lottery-must-be-closed");
        if( lotto.finalized ) revert("lottery-already-finalized");
        
        // lotteries[_lotteryId].prizePoolAddress.transfer(lotteries[_lotteryId].poolAmount);

        lotteries[_lotteryId].active = false;
        lotteries[_lotteryId].finalized = true;

        emit LotteryFinalized(_lotteryId, lotteries[_lotteryId].winnerTicketHash);
    }
}