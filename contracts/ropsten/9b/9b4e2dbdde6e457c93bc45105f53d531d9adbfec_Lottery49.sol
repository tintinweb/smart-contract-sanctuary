pragma solidity ^0.4.23;

/**
 * @title Lottery49
 * dev by Dell Luo (r5012928 @ gmail.com)
 * bet from 01 to 49 number on 1 to 7 pools 
 * In accordance with the Hong Kong Mark Six lottery draw order 
 * that allows unlimited entries 1 ticket at the cost of 0.02 ETH per entry.
 * The winners receive a bonus based on the bet ratio.
 */
contract Lottery49 {
    
    mapping(address => uint256) winners;
    mapping(uint => mapping(uint8 => int8)) public results;
    mapping(uint => mapping(uint8 => bool)) public results_status;
    
    /**
     * 紀錄期號派彩狀態
     */
    struct Pstatus{
        bool status;
    }
    mapping( uint => Pstatus) draws;
    /**
     * 記錄各期下注紀錄
     */
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
    /**
     * 記錄彩池
     */
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
    //彩池紀錄
    event watchPoolbyGtype(uint8 _type,uint Amount);
    //結果通知
    event watchResult(uint _periods,uint8 _type,int8 _bhash,bool _status);
    //派彩通知
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
        require(betclose == false && _periods == Periods);
        uint _wei = msg.value;
        uint _totalvalue=20000000000000000 * _tik;
        require(_wei >= uint(_totalvalue));
        tGtype storage rec1 = tgums[Periods].tgtypes[_type];
        tNum storage rec2=rec1.tnums[_hash];
        uint g_all_tik= rec1.bets+_tik;
        uint all_tik = rec2.bets+ _tik;
        uint org_tik= rec2.betusers[msg.sender];
        _tik+=org_tik;
        // Pool storage recP= pools[_type];
        // uint all_amount= recP.Amount+_totalvalue;
        
        pools[_type].Amount+=_totalvalue;
        
        tgums[_periods]=tGnum(_periods);
        tgums[_periods].tgtypes[_type]=tGtype(_type,g_all_tik);
        
        tgums[_periods].tgtypes[_type].tnums[_hash].betHash=_hash;
        tgums[_periods].tgtypes[_type].tnums[_hash].bets=all_tik;
        tgums[_periods].tgtypes[_type].tnums[_hash].betusers[msg.sender]=_tik;
        if(org_tik==0){
            tgums[_periods].tgtypes[_type].tnums[_hash].betAddress.push(msg.sender);
        }
        emit watchPoolbyGtype(_type,pools[_type].Amount);
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
        Pool storage recP= pools[_btype];
        uint tmp_uint=0;
        for(uint i=0;i<rec2.betAddress.length;i++){
            tmp_uint+=rec2.betusers[rec2.betAddress[i]];
        }
        return recP.Amount/tmp_uint;
    }

    function getResult(uint _periods,uint8 _btype) constant external returns (uint8,int8,bool){
        return (_btype,results[_periods][_btype],results_status[_periods][_btype]);
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
     * true:已派彩
     */
    function getDrawStatus(uint _periods) constant external returns(bool){
        Pstatus storage rec=draws[_periods];
        return rec.status;
    }

    function drawWinner(uint _periods) public onlyAuthorized returns (bool) {
        require(betclose==true && draws[_periods].status==false);
        for(uint8 j=1;j<=7;j++){
            require(results_status[_periods][j]==true && results[_periods][j]!=0);
            int8 _bhash=results[_periods][j];
            tGtype storage rec1 = tgums[_periods].tgtypes[j];
            tNum storage rec2=rec1.tnums[_bhash];
            if(pools[j].Amount>0 && rec1.bets>0 && rec2.bets>0){
                uint uint_amount=0;
                //派彩抽成
                uint own_p=pools[j].Amount*drawP/1000;
                if(withdraw(owner,own_p)){
                    updPool(j,own_p);
                    emit drawBet(_periods,j,_bhash,owner,own_p);
                }else{
                    return false;
                }
                uint_amount=getBetUint(j,_bhash);
                for(uint i=0;i<rec2.betAddress.length;i++){
                    uint win=rec2.betusers[rec2.betAddress[i]]*uint_amount;
                    if(withdraw(rec2.betAddress[i],win)){
                        updPool(j,win);
                        emit drawBet(_periods,j,_bhash,rec2.betAddress[i],win);
                    }else{
                        return false;
                    }
                }
            }
        }
        
        draws[_periods].status=true;
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