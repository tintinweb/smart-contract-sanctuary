pragma solidity ^0.4.23;

/**
 * @title LotteryTest
 * @dev The CrankysLottery contract is an ETH lottery contract
 * that allows unlimited entries at the cost of 1 ETH per entry.
 * Winners are rewarded the pot.
 */
contract LotteryTest {
    
    mapping(address => uint256) winners;
    /*
        record bet
    */
    struct betUser{
        address user;
        int bets;
    }
    
    struct tNum{
        int8 betHash; // 號碼
        int bets;
        mapping( address => betUser) betusers;
    }
    
    struct tGtype{
        uint8 betType; // 類型
        int bets;
        mapping( int8 => tNum) tnums;

    }    

    struct tGnum{
        uint8 blockNum; // 期數
        mapping( uint8 => tGtype) tgtypes;
    }

    mapping (uint => tGnum) tgums;
    //record bet end
    //record pool
    
    struct Pool{
        uint8 gtype;
        int  Amount;
    }
    
    mapping (uint8=>Pool) pools;
    
    // betting parameters
    uint public maxWin = 0; // maximum prize won
    uint public hashFirst = 0; // start time of building hashes database
    uint public hashLast = 0; // last saved block of hashes
    uint public hashNext = 0; // next available bet block.number
    uint public hashBetSum = 0; // used bet volume of next block
    uint public hashBetMax = 5 ether; // maximum bet size per block
    uint[] public hashes; // space for storing lottery results
    uint8 public Periods = 0; // 期數
    bool public betclose = true; // 關盤 true 開盤 false

    // events
    event LogBet(address indexed player, uint8 bettype, int8 bethash, uint blocknumber, uint betsize, bool betclose);
    event getStatus(uint8 gnum,bool close);

  	address public owner;
    uint private latestBlockNumber;
    bytes32 private cumulativeHash;
    mapping(address => bool) public authorized;

    constructor() public {
		owner = msg.sender;
        authorized[owner] = true;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
    }
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != 0);
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != 0);
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

  	/**
   	 * @dev Throws if called by any account other than the owner.
   	 */
  	modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}


    function getBetclose() constant external returns (bool) {
        return betclose;
    }

    function getPeriods() constant external returns (uint8) {
        return Periods;
    }

    /**
     * @dev Set 開關盤
     * @param _betclose The betclose true or false.
     */
    function setBetclose(bool _betclose) external onlyAuthorized {
        require(betclose != _betclose);
        betclose = _betclose;
        emit getStatus(Periods,betclose);
    }
    /**
     * @dev Set 期數
     * @param _periods The periods is num.
     */
    function setPeriods(uint8 _periods) external onlyAuthorized {
        require(_periods != Periods && betclose==true);
        Periods = _periods;
        emit getStatus(Periods,betclose);
    }

    function placeBet(uint8 _type, int8 _hash, uint8 _periods, int _tik) public payable returns (bool) {
        uint _wei = msg.value;
        assert(bool(betclose) == false && uint8(_periods) == uint8(Periods));
        int _totalvalue=20000000000000000 * _tik;
        assert(_wei == uint(_totalvalue));

        cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
        latestBlockNumber = block.number;

        int g_all_tik= this.getAllbetByGtype(_type)+_tik;
        int all_tik = this.getAllbetByNum( _type, _hash)+ _tik;
        _tik+=this.getbetData( _type, _hash, msg.sender);
        int all_amount= this.getPoolbyGtype(_type)+_totalvalue;
        
        pools[_type]=Pool(_type,all_amount);
        
        tgums[_periods]=tGnum(_periods);
        tgums[_periods].tgtypes[_type]=tGtype(_type,g_all_tik);
        tgums[_periods].tgtypes[_type].tnums[_hash]=tNum(_hash,all_tik);
        tgums[_periods].tgtypes[_type].tnums[_hash].betusers[msg.sender]=betUser(msg.sender,_tik);

        emit LogBet(msg.sender,_type,_hash,_periods,msg.value,bool(betclose));
        return true;
        
    }
    function getPoolbyGtype(uint8 _type) constant external returns (int){
        Pool storage rec= pools[_type];
        return rec.Amount;
    }
    function getAllbetByGtype(uint8 _btype) constant external returns (int) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        return rec1.bets;        
    }
    function getAllbetByNum(uint8 _btype,int8 _bnum) constant external returns (int) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return rec2.bets;        
    }
    function getbetData(uint8 _btype,int8 _bnum,address _owner) constant external returns (int) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        betUser storage rec3=rec2.betusers[_owner];
        return rec3.bets;        
    }

    function drawWinner(uint8 _periods,uint8 _btype,int8 _bhash) public onlyAuthorized returns (address) {
        
        _btype;_bhash;
        int allbetNum=this.getAllbetByGtype(_btype);
        require(allbetNum>0);
        betclose=true;
        
        delete tgums[_periods];
        return msg.sender;
    }

    function withdraw() public onlyAuthorized returns (bool) {
        uint256 amount = winners[msg.sender];
        winners[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            return true;
        } else {
            winners[msg.sender] = amount;
            return false;
        }
    }

}