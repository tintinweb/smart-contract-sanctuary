pragma solidity ^0.4.23;

/**
 * @title LotteryTest
 * @dev The CrankysLottery contract is an ETH lottery contract
 * that allows unlimited entries at the cost of 1 ETH per entry.
 * Winners are rewarded the pot.
 */
contract LotteryTest {
    struct Bet {
        uint192 value; // bet size
        uint32 betType; // 類型
        uint32 betHash; // 號碼
        uint32 blockNum; // 期數
    }
    mapping (address => Bet) bets;
    address[] private betaddrs;
    mapping(address => uint256) winners;

    // betting parameters
    uint public maxWin = 0; // maximum prize won
    uint public hashFirst = 0; // start time of building hashes database
    uint public hashLast = 0; // last saved block of hashes
    uint public hashNext = 0; // next available bet block.number
    uint public hashBetSum = 0; // used bet volume of next block
    uint public hashBetMax = 5 ether; // maximum bet size per block
    uint[] public hashes; // space for storing lottery results
    uint public Periods = 0; // 期數
    bool public betclose = true; // 關盤 true 開盤 false

    // events
    event LogBet(address indexed player, uint bettype, uint bethash, uint blocknumber, uint betsize, bool betclose);

  	address public owner;
    uint private latestBlockNumber;
    bytes32 private cumulativeHash;

    constructor() public {
		owner = msg.sender;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
    }

  	/**
   	 * @dev Throws if called by any account other than the owner.
   	 */
  	modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}

    /**
     * @dev Set 開關盤
     * @param _betclose The betclose true or false.
     */
    function setBetclose(bool _betclose) external onlyOwner {
        betclose = _betclose;
    }

    function getBetclose() constant external returns (bool) {
        return bool(betclose);
    }

    function getPeriods() constant external returns (uint) {
        return uint(Periods);
    }

    /**
     * @dev Set 期數
     * @param _periods The periods is num.
     */
    function setPeriods(uint _periods) external onlyOwner {
        Periods = _periods;
    }

    /**
     * @dev Set maximum bet size per block
     * @param _maxsum The maximum bet size in wei.
     */
    function setBetMax(uint _maxsum) external onlyOwner {
        hashBetMax = _maxsum;
    }

    /**
     * @dev Reset bet size accounting, to increase bet volume above safe limits
     */
    function resetBet() external onlyOwner {
        hashNext = block.number + 3;
        hashBetSum = 0;
    }

    /**
     * @dev Show bet size.
     * @param _owner The address of the player.
     */
    function betValueOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].value);
    }

    /**
     * @dev Show block number of lottery run for the bet.
     * @param _owner The address of the player.
     */
    function betHashOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].betHash);
    }

    /**
     * @dev Show block number of lottery run for the bet.
     * @param _owner The address of the player.
     */
    function betBlockNumberOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].blockNum);
    }

    function placeBet(uint _type, uint _hash, uint _periods) public payable returns (bool) {
        uint _wei = msg.value;
        assert(betclose == false && _periods == Periods);
        assert(_wei == 20000000000000000);
        cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
        latestBlockNumber = block.number;
        betaddrs.push(msg.sender);
        uint24 betType = uint24(_type);
        uint24 bethash = uint24(_hash);
        uint24 blockNum = uint24(_periods);
        bets[msg.sender] = Bet({value: uint192(msg.value), betType: uint32(betType), betHash: uint32(bethash), blockNum: uint32(blockNum)});
        emit LogBet(msg.sender,uint(betType),uint(bethash),uint(blockNum),msg.value,bool(betclose));
        return true;
    }

    function drawWinner() public onlyOwner returns (address) {
        assert(betaddrs.length > 4);
        latestBlockNumber = block.number;
        bytes32 _finalHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber-1), cumulativeHash));
        uint256 _randomInt = uint256(_finalHash) % betaddrs.length;
        address _winner = betaddrs[_randomInt];
        winners[_winner] = 20000000000000000 * betaddrs.length;
        cumulativeHash = bytes32(0);
        delete betaddrs;
        return _winner;
    }

    function withdraw() public returns (bool) {
        uint256 amount = winners[msg.sender];
        winners[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            return true;
        } else {
            winners[msg.sender] = amount;
            return false;
        }
    }

    function getBet(uint256 betNumber) public view returns (address) {
        return betaddrs[betNumber];
    }

    function getNumberOfBets() public view returns (uint256) {
        return betaddrs.length;
    }
}