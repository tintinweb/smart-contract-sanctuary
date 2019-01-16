pragma solidity >=0.4.23 <0.6.0;

/**
 * @title Lottery49
 * dev by Dell Luo (r5012928 @ gmail.com)
 * bet from 01 to 49 number on 1 to 7 pools 
 * In accordance with the Hong Kong Mark Six lottery draw order 
 * that allows unlimited entries 1 ticket at the cost of 0.02 ETH per entry.
 * The winners receive a bonus based on the bet ratio.
 */
contract Lottery49 {
    
    // mapping(address => uint256) winners;
    // mapping(uint => mapping(uint8 => int8)) public results;
    // mapping(uint => mapping(uint8 => bool)) public results_status;
    struct Result{
        bool status;
        bool draws;
        int8 res;
    }
    struct GamePeriods{
        bool status;
        bool draws;
        mapping(int8 => Result) gameresults;
    }
    mapping(uint32 => GamePeriods) public results;

  /**
     * each bets of Periods
     */
    struct tNum{
        int8 betHash; // bet number
        uint bets; //bet amount
        mapping( address => uint) betusers;
        mapping( address => uint) draws;
        address[] betAddress;
    }
    struct tGtype{
        int8 betType; // game type
        uint bets;
        mapping( int8 => tNum) tnums;
    }
    struct tGnum{
        uint blockNum; // Periods
        mapping( int8 => tGtype) tgtypes;
    }
    mapping (uint => tGnum) tgums;
    struct Pool{
        uint  Amount;
    }
    mapping (int8=>Pool) pools;
    // betting parameters
    uint32 public Periods = 0;
    uint public CloseTime=0;
    uint public betbasic=20000000000000000;
    bool public betclose = true; 
    uint public drawP = 50;
    address public sConAddress=0;
    // events
    event LogBet(address indexed player, int8 bettype, int8 bethash, uint blocknumber, uint betsize, bool betclose);
    event getStatus(uint32 _periods,bool close);
    event watchPoolbyGtype(int8 _type, uint bets, uint Amount);
    event watchResult(uint32 _periods,int8 _type,int8 _bhash,bool _status);
    event drawBet(uint32 _periods,int8 _type,int8 _hash,address winner,uint Amount);

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
  	modifier updresultstatus() {
        GamePeriods storage rec = results[Periods];
    	require(rec.gameresults[1].status==true);
    	require(rec.gameresults[2].status==true);
    	require(rec.gameresults[3].status==true);
    	require(rec.gameresults[4].status==true);
    	require(rec.gameresults[5].status==true);
    	require(rec.gameresults[6].status==true);
    	require(rec.gameresults[7].status==true);
    	results[Periods].status=true;
    	_;
    	results[Periods].status=false;
  	}
  	modifier upddrawsstatus() {
        GamePeriods storage rec = results[Periods];
    	require(rec.gameresults[1].draws==true);
    	require(rec.gameresults[2].draws==true);
    	require(rec.gameresults[3].draws==true);
    	require(rec.gameresults[4].draws==true);
    	require(rec.gameresults[5].draws==true);
    	require(rec.gameresults[6].draws==true);
    	require(rec.gameresults[7].draws==true);
    	results[Periods].draws=true;
    	_;
    	results[Periods].draws=false;
  	}
  	function getNow() public view returns (uint) {
        return now;
    }
    function getDrawP() public view returns (uint) {
        return drawP;
    }
    function getBetclose() public view returns (bool) {
        return betclose;
    }
    function getPeriods() public view returns (uint32) {
        return Periods;
    }
    function getBetBasic() public view returns (uint){
        return betbasic;
    }
    function setBetBasic(uint _betbasic) external onlyAuthorized {
        require(_betbasic>0 && _betbasic!= betbasic);
        betbasic=_betbasic;
    
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
    function setPeriods(uint32 _periods,uint _closetime) external onlyAuthorized {
        require(_periods != Periods && betclose && !results[_periods].status && _closetime>now);
        Periods = _periods;
        CloseTime=_closetime;
        results[_periods].status=true;
        emit getStatus(Periods,betclose);
    }
    function setDrawP(uint _drawp) external onlyAuthorized {
        require(_drawp > 0 && _drawp<=1000);
        drawP = _drawp;
    }
    function placeBet(int8 _type, int8 _hash, uint32 _periods, uint _tik) public payable returns (bool) {
        require(_hash>0 && _hash<50 && _type>0 && _type<8 && _periods!=0 && _periods == Periods,"Bad input!");
        require(!betclose && results[_periods].status && now <= CloseTime,"Game closed!");
        uint _wei = msg.value;
        uint _totalvalue=betbasic * _tik;
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
    function getPoolbyGtype(int8 _type) public view returns (int8,uint){
        Pool storage rec= pools[_type];
        return (_type,rec.Amount);
    }
    function getAllbetByGtype(int8 _btype) public view returns (int8,uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        return (_btype,rec1.bets);        
    }
    function getAllbetByNum(int8 _btype,int8 _bnum) public view returns (int8,int8,uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return (_btype,_bnum,rec2.bets);        
    }
    function getbetData(int8 _btype,int8 _bnum,address _owner) public view returns (int8,int8,address,uint) {
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        return (_btype,_bnum,_owner,rec2.betusers[_owner]);
    }
    function getBetUint(int8 _btype,int8 _bnum) constant internal returns (uint){
        tGnum storage rec = tgums[Periods];
        tGtype storage rec1 = rec.tgtypes[_btype];
        tNum storage rec2=rec1.tnums[_bnum];
        Pool storage recP= pools[_btype];
        return recP.Amount/rec2.bets;
    }
    function getResult(uint32 _periods,int8 _btype) public view returns (int8,int8,bool){
        GamePeriods storage rec = results[_periods];
        return (_btype,rec.gameresults[_btype].res,rec.gameresults[_btype].status);
    }
    function setResult(uint32 _periods,int8 _btype,int8 _bhash) external onlyAuthorized updresultstatus returns(uint,int8,int8,bool) {
        assert(_periods!=0 && _btype!=0 && _bhash!=0 && now > CloseTime);
        if(betclose==false){
            betclose=true;
            emit getStatus(Periods,betclose);
        }
        results[_periods].gameresults[_btype].res=_bhash;
        results[_periods].gameresults[_btype].status=true;
        emit watchResult(_periods,_btype,_bhash,results[_periods].gameresults[_btype].status);
        return (_periods,_btype,_bhash,results[_periods].gameresults[_btype].status);
    }
    function getDrawStatus(uint32 _periods) public view returns(bool){
        GamePeriods storage rec=results[_periods];
        return rec.draws;
    }
    function drawWinner(uint32 _periods,int8 _btype) public onlyAuthorized upddrawsstatus returns (bool) {
        require(betclose && !results[_periods].draws && results[_periods].status && now > CloseTime);
        require(results[_periods].gameresults[_btype].status && results[_periods].gameresults[_btype].res!=0);
        int8 _bhash=results[_periods].gameresults[_btype].res;
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
                if(win>0){
                    if(withdraw(rec2.betAddress[i],win)){
                        tgums[_periods].tgtypes[_btype].tnums[_bhash].draws[rec2.betAddress[i]]=rec2.betusers[rec2.betAddress[i]];
                        tgums[_periods].tgtypes[_btype].tnums[_bhash].betusers[rec2.betAddress[i]]=0;
                        updPool(_btype,win);
                        emit drawBet(_periods,_btype,_bhash,rec2.betAddress[i],win);
                    }else{
                        return false;
                    }
                }
            }
        }
       return true;
    }
    function withdraw(address _user,uint amount) private returns(bool) {
        require(address(this).balance >= amount);
        return _user.send(amount);
    }
    
    function ShiftContract() onlyOwner public returns(bool){
        require(sConAddress!=0);
        uint256 OwnPay = address(this).balance;
        sConAddress.transfer(OwnPay);
        return true;
    }
    function updPool(int8 _btype,uint _actAmount) private returns (uint) {
        pools[_btype].Amount-=_actAmount;
        return pools[_btype].Amount;
    }
    
}