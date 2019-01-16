pragma solidity ^0.4.23;

/**
 * @title LotteryTest
 * that allows unlimited entries 1 ticket at the cost of 0.02 ETH per entry.
 * Winners are rewarded the pot.
 */
contract LotteryTest {
    
    mapping(address => uint256) winners;
       
    struct tNum{
        int8 betHash; // 號碼
        int bets;
        mapping( address => int) betusers;
        address[] betAddress;
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
    event watchPoolbyGtype(uint8 _type,int Amount);
    event drawBet(uint _periods,uint8 _type,int8 _hash,address winner,int Amount);

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
        assert(_wei >= uint(_totalvalue));

        cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
        latestBlockNumber = block.number;

        int g_all_tik= this.getAllbetByGtype(_type)+_tik;
        int all_tik = this.getAllbetByNum( _type, _hash)+ _tik;
        int org_tik=this.getbetData( _type, _hash, msg.sender);
        _tik+=org_tik;
        int all_amount= this.getPoolbyGtype(_type)+_totalvalue;
        
        pools[_type]=Pool(_type,all_amount);
        
        tgums[_periods]=tGnum(_periods);
        tgums[_periods].tgtypes[_type]=tGtype(_type,g_all_tik);
        
        tgums[_periods].tgtypes[_type].tnums[_hash].betHash=_hash;
        tgums[_periods].tgtypes[_type].tnums[_hash].bets=all_tik;
        tgums[_periods].tgtypes[_type].tnums[_hash].betusers[msg.sender]=_tik;
        if(org_tik==0){
            tgums[_periods].tgtypes[_type].tnums[_hash].betAddress.push(msg.sender);
        }
        emit watchPoolbyGtype(_type,all_amount);
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
        return rec2.betusers[_owner];
    }

    function getBetUint(uint8 _btype,int8 _bnum) constant external returns (int){
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        int tmp_uint=0;
        int TotalPool=this.getPoolbyGtype(_btype);
        for(uint i=0;i<rec2.betAddress.length;i++){
            tmp_uint+=rec2.betusers[rec2.betAddress[i]];
        }
        
        return TotalPool/tmp_uint;
    }

    function drawWinner(uint8 _periods,uint8 _btype,int8 _bhash) public onlyAuthorized returns (bool) {
        if(betclose=false){
            betclose=true;
        }
        
        int totalAmount=this.getPoolbyGtype(_btype);
        require(totalAmount>0);
        int totalBets=this.getAllbetByGtype(_btype);
        require(totalBets>0);
        int winner_bets=this.getAllbetByNum(_btype,_bhash);
        require(winner_bets>0);
        int uint_amount=0;
        // int TotalPool=this.getPoolbyGtype(_btype);
        
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bhash];
        uint_amount=this.getBetUint(_btype,_bhash);
        for(uint i=0;i<rec2.betAddress.length;i++){
            int win=rec2.betusers[rec2.betAddress[i]]*uint_amount;
            rec2.betAddress[i].transfer(uint(win));
            pools[_btype].Amount-=win;
            emit drawBet(_periods,_btype,_bhash,rec2.betAddress[i],win);
        }
        delete tgums[_periods];
        return true;
    }

}