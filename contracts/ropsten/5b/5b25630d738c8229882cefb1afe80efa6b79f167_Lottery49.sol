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
     * result strart && end flag
     */
    struct Pstatus{
        bool start_status;        
        bool draw_status;
    }
    mapping( uint => Pstatus) draws;
    /**
     * each bets of Periods
     */
    struct tNum{
        int8 betHash; // bet number
        uint bets; //bet amount
        mapping( address => uint) betusers;
        address[] betAddress;
    }
    struct tGtype{
        uint8 betType; // game type
        uint bets;
        mapping( int8 => tNum) tnums;

    }
    struct tGnum{
        uint blockNum; // Periods
        mapping( uint8 => tGtype) tgtypes;
    }
    mapping (uint => tGnum) tgums;
    struct Pool{
        uint  Amount;
    }
    mapping (uint8=>Pool) pools;
    // betting parameters
    uint public Periods = 0; 
    bool public betclose = true; 
    uint public drawP = 50;
    // events
    event LogBet(address indexed player, uint8 bettype, int8 bethash, uint blocknumber, uint betsize, bool betclose);
    event getStatus(uint _periods,bool close);
    event watchPoolbyGtype(uint8 _type, uint bets, uint Amount);
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
     * @dev Set betclose
     * @param _betclose The betclose true or false.
     */
    function setBetclose(bool _betclose) external onlyAuthorized {
        require(betclose != _betclose);
        betclose = _betclose;
        emit getStatus(Periods,betclose);
    }
    /**
     * @dev Set Periods
     * @param _periods The periods is num.
     */
    function setPeriods(uint _periods) external onlyAuthorized {
        require(_periods != Periods && betclose && !draws[_periods].start_status);
        Periods = _periods;
        draws[_periods]=Pstatus({start_status:true,draw_status:false});
        emit getStatus(Periods,betclose);
    }
    function setDrawP(uint _drawp) external onlyAuthorized {
        require(_drawp > 0 && _drawp<=1000);
        drawP = _drawp;
    }
    function placeBet(uint8 _type, int8 _hash, uint _periods, uint _tik) public payable returns (bool) {
        require(_hash>0 && _hash<50 && _type>0 && _type<8 && _periods!=0);
        require(!betclose && _periods == Periods && draws[_periods].start_status);
        uint _wei = msg.value;
        uint _totalvalue=20000000000000000 * _tik;
        require(_wei >= uint(_totalvalue));
        tGtype storage rec1 = tgums[Periods].tgtypes[_type];
        tNum storage rec2=rec1.tnums[_hash];
        if(rec2.betusers[msg.sender]==0){
            tgums[_periods].tgtypes[_type].tnums[_hash].betAddress.push(msg.sender);
        }
        pools[_type].Amount+=_totalvalue;
        tgums[_periods]=tGnum(_periods);
        tgums[_periods].tgtypes[_type]=tGtype(_type,rec1.bets+_tik);
        tgums[_periods].tgtypes[_type].tnums[_hash].betHash=_hash;
        tgums[_periods].tgtypes[_type].tnums[_hash].bets+=_tik;
        tgums[_periods].tgtypes[_type].tnums[_hash].betusers[msg.sender]+=_tik;
        emit watchPoolbyGtype( _type, rec1.bets, pools[_type].Amount);
        return true;
    }
    function getPoolbyGtype(uint8 _type) constant external returns (uint8,uint){
        Pool storage rec= pools[_type];
        return (_type,rec.Amount);
    }
    function getAllbetByGtype(uint8 _btype) constant external returns (uint8,uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        return (_btype,rec1.bets);        
    }
    function getAllbetByNum(uint8 _btype,int8 _bnum) constant external returns (uint8,int8,uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return (_btype,_bnum,rec2.bets);        
    }
    function getbetData(uint8 _btype,int8 _bnum,address _owner) constant external returns (uint8,int8,address,uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return (_btype,_bnum,_owner,rec2.betusers[_owner]);
    }
    function getBetUint(uint8 _btype,int8 _bnum) constant internal returns (uint){
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        Pool storage recP= pools[_btype];
        return recP.Amount/rec2.bets;
    }
    function getResult(uint _periods,uint8 _btype) constant external returns (uint8,int8,bool){
        return (_btype,results[_periods][_btype],results_status[_periods][_btype]);
    }
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
    function getDrawStatus(uint _periods) constant external returns(bool){
        Pstatus storage rec=draws[_periods];
        return rec.draw_status;
    }
    function drawWinner(uint _periods,uint8 _btype) public onlyAuthorized returns (bool) {
        require(betclose && !draws[_periods].draw_status && draws[_periods].start_status);
        require(results_status[_periods][_btype] && results[_periods][_btype]!=0);
        int8 _bhash=results[_periods][_btype];
        tGtype storage rec1 = tgums[_periods].tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bhash];
        if(pools[_btype].Amount>0 && rec1.bets>0 && rec2.bets>0){
            uint uint_amount=0;

            uint own_p=pools[_btype].Amount*drawP/1000;
            if(withdraw(owner,own_p)){
                updPool(_btype,own_p);
                emit drawBet(_periods,_btype,_bhash,owner,own_p);
            }else{
                return false;
            }
            //winner
            uint_amount=getBetUint(_btype,_bhash);
            for(uint i=0;i<rec2.betAddress.length;i++){
                uint win=rec2.betusers[rec2.betAddress[i]]*uint_amount;
                if(withdraw(rec2.betAddress[i],win)){
                    updPool(_btype,win);
                    emit drawBet(_periods,_btype,_bhash,rec2.betAddress[i],win);
                }else{
                    return false;
                }
            }
        }
        if(getResultStatus(_periods)){
            draws[_periods].draw_status=true;
        }
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
    function getResultStatus(uint _periods) view private returns (bool) {
        for(uint8 i=1;i<=7;i++){
            if(!results_status[_periods][i]){
                return false;
            }
        }
        return true;
    }
}