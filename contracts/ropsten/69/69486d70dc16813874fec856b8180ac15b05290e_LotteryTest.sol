pragma solidity ^0.4.23;

/**
 * @title LotteryTest
 * that allows unlimited entries 1 ticket at the cost of 0.02 ETH per entry.
 * Winners are rewarded the pot.
 */
contract LotteryTest {
    
    mapping(address => uint256) winners;
    mapping(uint => mapping(uint8 => int8)) public results;
    mapping(uint => mapping(uint8 => bool)) public results_status;
    
    struct Pstatus{
        bool status;
    }
    mapping( uint => Pstatus) draws;
    
    struct tNum{
        int8 betHash; // 號碼
        uint bets;
        mapping( address => uint) betusers;
        address[] betAddress;
    }
    
    struct tGtype{
        uint8 betType; // 類型
        uint bets;
        mapping( int8 => tNum) tnums;

    }    

    struct tGnum{
        uint blockNum; // 期數
        mapping( uint8 => tGtype) tgtypes;
    }

    mapping (uint => tGnum) tgums;
    
    struct Pool{
        uint  Amount;
    }
    
    mapping (uint8=>Pool) pools;
    

    // betting parameters
    uint public Periods = 0; // 期數
    bool public betclose = true; // 關盤 true 開盤 false
    uint public drawP = 50;
    // events
    event LogBet(address indexed player, uint8 bettype, int8 bethash, uint blocknumber, uint betsize, bool betclose);
    event getStatus(uint _periods,bool close);
    event watchPoolbyGtype(uint8 _type,uint Amount);
    event watchResult(uint _periods,uint8 _type,int8 _bhash,bool _status);
    event drawBet(uint _periods,uint8 _type,int8 _hash,address winner,uint Amount);

  	address public owner;
    mapping(address => bool) public authorized;

    constructor() public {
		owner = msg.sender;
        authorized[owner] = true;
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

    function getDrawP() constant external returns (uint) {
        return drawP;
    }
    
    function getBetclose() constant external returns (bool) {
        return betclose;
    }

    function getPeriods() constant external returns (uint) {
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
    function setPeriods(uint _periods) external onlyAuthorized {
        require(_periods != Periods && betclose==true);
        Periods = _periods;
        emit getStatus(Periods,betclose);
    }

    function setDrawP(uint _drawp) external onlyAuthorized {
        require(_drawp > 0 && _drawp<=1000);
        drawP = _drawp;
    }
    
    function placeBet(uint8 _type, int8 _hash, uint _periods, uint _tik) public payable returns (bool) {
        require(_hash>0 && _hash<50 && _type>0 && _type<8 && _periods!=0);
        assert(betclose == false && _periods == Periods);
        uint _wei = msg.value;
        uint _totalvalue=20000000000000000 * _tik;
        assert(_wei >= uint(_totalvalue));

        uint g_all_tik= this.getAllbetByGtype(_type)+_tik;
        uint all_tik = this.getAllbetByNum( _type, _hash)+ _tik;
        uint org_tik=this.getbetData( _type, _hash, msg.sender);
        _tik+=org_tik;
        uint all_amount= this.getPoolbyGtype(_type)+_totalvalue;
        
        pools[_type]=Pool(all_amount);
        
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
    function getPoolbyGtype(uint8 _type) constant external returns (uint){
        Pool storage rec= pools[_type];
        return rec.Amount;
    }
    function getAllbetByGtype(uint8 _btype) constant external returns (uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        return rec1.bets;        
    }
    function getAllbetByNum(uint8 _btype,int8 _bnum) constant external returns (uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return rec2.bets;        
    }
    function getbetData(uint8 _btype,int8 _bnum,address _owner) constant external returns (uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return rec2.betusers[_owner];
    }

    function getBetUint(uint8 _btype,int8 _bnum) constant internal returns (uint){
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        uint tmp_uint=0;
        uint TotalPool=this.getPoolbyGtype(_btype);
        for(uint i=0;i<rec2.betAddress.length;i++){
            tmp_uint+=rec2.betusers[rec2.betAddress[i]];
        }
        uint rs=TotalPool/tmp_uint;
        return rs;
    }

    function getResult(uint _periods,uint8 _btype) constant external returns (int8,bool){
        return (results[_periods][_btype],results_status[_periods][_btype]);
    }

    /**
     * set Result number
     * 
     * 
    */
    function setResult(uint _periods,uint8 _btype,int8 _bhash) external onlyAuthorized returns(uint,uint8,int8,bool) {
        require(_periods!=0 && _btype!=0 && _bhash!=0);
        if(betclose==false){
            betclose=true;
            emit getStatus(Periods,betclose);
        }
        results[_periods][_btype]=_bhash;
        results_status[_periods][_btype]=true;
        emit watchResult(_periods,_btype,_bhash,results_status[_periods][_btype]);
        return (_periods,_btype,_bhash,results_status[_periods][_btype]);
    }
    /**
     *派彩狀況 
     * 
     */
    function getDrawStatus(uint _periods) constant external returns(bool){
        Pstatus storage rec=draws[_periods];
        return rec.status;
    }

    function drawWinner(uint _period) public onlyAuthorized returns (bool) {
        require(betclose==true && draws[_period].status==false);
        for(uint8 j=1;j<=7;j++){
            require(results_status[_period][j]==true && results[_period][j]!=0);
            int8 _bhash=results[_period][j];
            if(this.getPoolbyGtype(j)>0 && this.getAllbetByGtype(j)>0 && this.getAllbetByNum(j,_bhash)>0){
                uint uint_amount=0;
                //派彩抽成
                uint own_p=this.getPoolbyGtype(j)*drawP/1000;
                if(withdraw(owner,own_p)){
                    updPool(j,own_p);
                    emit drawBet(_period,j,_bhash,owner,own_p);
                }else{
                    return false;
                }

                
                tGnum storage rec = tgums[_period];
                tGtype storage rec1 = rec.tgtypes[j];
                tNum storage rec2=rec1.tnums[_bhash];
                uint_amount=getBetUint(j,_bhash);
                for(uint i=0;i<rec2.betAddress.length;i++){
                    uint win=rec2.betusers[rec2.betAddress[i]]*uint_amount;
                    if(withdraw(rec2.betAddress[i],win)){
                        
                        updPool(j,win);
                        emit drawBet(_period,j,_bhash,rec2.betAddress[i],win);
                    }else{
                        return false;
                    }

                }
            }
        }
        draws[_period].status=true;
        return true;
    }
    function withdraw(address _user,uint amount) private returns(bool) {
        _user.transfer(amount);
        return true;
    }
    function updPool(uint8 _btype,uint _actAmount) private returns (uint) {
        pools[_btype].Amount-=_actAmount;
        return pools[_btype].Amount;
    }
}