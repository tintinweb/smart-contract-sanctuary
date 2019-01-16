pragma solidity ^0.4.18;

contract agame {
   
    address internal owner;
    uint256 internal startCount;
    
    uint internal roundCount; 
    uint internal startTime;
    uint internal endTime;
    uint256 internal currentRoundSupport;
    uint256 internal currentRoundLeft;
    uint internal timeout;
    
    // prelast return percent
    uint internal preLastPercent = 50;
    uint internal lastPercent = 50;

    function resetPercent(uint pl,uint l) public onlyOwner{
        preLastPercent = pl;
        lastPercent = l;
    }
    
    // sum
    uint256 internal sum_in = 0;
    uint256 internal sum_out = 0;
    uint256 internal sum_end_out = 0;
    uint256 internal sum_big = 0;

    // water list
    mapping(address => uint) shares;
    mapping(address => uint) sends;
    
    uint constant internal decimals = 18;
    uint constant internal min_wei = 1e9;
    uint constant internal dividendFee = 10;
    uint constant internal dynamicDividendFee = 6;
    uint constant internal platformDividendFee = 4;
    uint constant internal bigDividendFee = 1;
    
    uint256 currentBuyId = 1;
   
    struct Buyer{
        address who;
        uint256 amount;
        uint time;
        uint againCount;
        bool isValue;
        uint256[] buyIds;
    }
    
    struct RoundInfo{
        uint256 myRoundCount;
        uint256 buyCount;
        uint256 supportAmount;
        uint256 currentAmount;
        uint startTime;
        uint endTime;
        bool isValue;
        bool hasSendBonus;
    }
    
    RoundInfo internal roundInfo;
    
    constructor(uint param_startCount,uint param_timeout) public{
        require(param_startCount>0, "startCount must > 0");
        owner = msg.sender;
        startCount = param_startCount * 1e18;
        currentRoundLeft = startCount;
        currentRoundSupport = startCount;
        roundCount = 1;
        currentBuyId = 1;
        startTime = now;
        timeout = param_timeout;
        endTime = now + timeout;
        roundInfo = RoundInfo(roundCount, 0, currentRoundSupport, 0, startTime, endTime, true, false);
        roundHistory[roundCount] = roundInfo;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "must be owner");
        _;
    }
    
    modifier running() {
        require((now - startTime) < timeout, "time is out");
        _;
    }
    
    modifier stoped() {
        require((now - startTime) > timeout, "game must be end");
        _;
    }
    
    modifier correctValue(uint256 _eth) {
        require(_eth >= min_wei, "can not lessthan 1 gwei ");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }
    
    modifier correctRoundCount(uint256 _roundCount) {
        require(_roundCount <= roundCount, "roundCount is invalid");
        _;
    }
    
    string contractName = "BADBOY";
    
    mapping(uint256 => mapping(uint256 => Buyer)) roundHistoryList;
    mapping(uint256 => mapping(address => Buyer)) buyerHistoryList;
    mapping(uint256 => address[]) roundAddressList;
    mapping(uint256 => RoundInfo) roundHistory;
    
    event ChangeName(string name_);

    event ChangeTimeout(uint timeout_);
    
    event BuySuccess(address who,uint256 value,uint againCount);
    event AutoBuySuccess(address who,uint256 value,uint againCount);
    
    event SendDivedend(address who,uint256 value);
    event CloseGameReturnEth(address who,uint256 value,uint256 returnValue);
    event NewRound(uint time,uint roundCount,uint256 currentRoundSupport, uint256 currentRoundLeft);

    event ReturnMore(
        address indexed to,
        uint256 buyMum,
        uint256 returnNum
    );
    
    function myName() public view returns(string name_){    
        return contractName;
    }
   
    function setName(string newName) public onlyOwner{
        contractName = newName;
        emit ChangeName(newName);
    }
    
    function setTimeout(uint _timeout) public onlyOwner{
        timeout = _timeout;
        emit ChangeTimeout(timeout);
    }
    
    function transfer(address to_,uint256 amount) public onlyOwner returns(bool success_){
        return _sendDivedend(to_,amount);
    }
    
    // send Divedend to user
    function _sendDivedend(address _to,uint256 _amount) internal returns(bool success_){
        
        uint balanceBeforeTransfer = address(this).balance;
        
        _to.transfer(_amount);
        
        sum_out += _amount;
        
        sends[_to] += _amount;
        
        assert(address(this).balance == balanceBeforeTransfer - _amount);
        
        emit SendDivedend(_to, _amount);
        
        return true;
        
    }
    
    // close game
    function closeGame_sendDivedend(address _to,uint256 _amount,uint256 return_amount) internal returns(bool success_){
        
        uint balanceBeforeTransfer = address(this).balance;
        
        _to.transfer(return_amount);
        
        sum_out += return_amount;
        
        sends[_to] += return_amount;
        
        assert(address(this).balance == balanceBeforeTransfer - return_amount);
        
        emit CloseGameReturnEth(_to, _amount,return_amount);
        
        return true;
        
    }

    function gameInfo() public view returns(string _gameName,uint _roundCount,uint sumIncome,uint sumOut,uint sumBigBonus,uint256 mybalance,uint _leftTime,uint preLastPercent_r,uint lastPercent_r){
        return (contractName,roundCount,sum_in,sum_out,sum_big,address(this).balance,timeout-(now - startTime),preLastPercent,lastPercent);
    }
    
    function viewBuyer(uint _roundCount,address _who) public view returns(address who, uint256 amount, 
        uint time, uint againCount, uint256[] buyId){

        Buyer memory buyer = buyerHistoryList[_roundCount][_who];
        return (buyer.who,buyer.amount,buyer.time,buyer.againCount,buyer.buyIds);

    }
    
    function viewBuyer(uint _roundCount,uint buyerId) public view returns(address who, uint256 amount, 
        uint time, uint againCount, uint256[] buyId){
        Buyer memory buyer = roundHistoryList[_roundCount][buyerId];
        return (buyer.who,buyer.amount,buyer.time,buyer.againCount,buyer.buyIds);
    }
    
    function viewRound(uint _roundCount) public view correctRoundCount(_roundCount) returns(uint256 myRoundCount_Return, 
        uint256 buyCount_Return,uint256 supportAmount_Return,uint256 currentAmount_Return,uint startTime_Return, 
        uint endTime_Return,bool isValue_Return,bool hasSendBonus_Return){
        
        RoundInfo memory _roundInfo = roundHistory[_roundCount];
        return (_roundInfo.myRoundCount, _roundInfo.buyCount,
            _roundInfo.supportAmount,_roundInfo.currentAmount,_roundInfo.startTime,
            _roundInfo.endTime,_roundInfo.isValue,_roundInfo.hasSendBonus);

    }
    
    function viewAddrList(uint _roundCount) public view correctRoundCount(_roundCount) returns(address[] buyerAddressList){
        return roundAddressList[_roundCount];
    }
    
    function sumBuy(address who) public view returns(uint256 sumBuyAmount){
        return shares[who];
    }
    
    function sumGet(address who) public view returns(uint256 sumGetAmount){
        return sends[who];
    }
    
    function currentRound() public view returns(uint256 myRoundCount_Return, uint256 buyCount_Return,uint256 supportAmount_Return,
        uint256 currentAmount_Return,uint startTime_Return, uint endTime_Return,bool hasSendBonus_Return ){

        RoundInfo memory _roundInfo = roundHistory[roundCount];
        return (_roundInfo.myRoundCount, 
            _roundInfo.buyCount,_roundInfo.supportAmount,
            _roundInfo.currentAmount,_roundInfo.startTime,
            _roundInfo.endTime,_roundInfo.hasSendBonus);

    }
  
    function buy(uint _againCount) public payable correctValue(msg.value) running {
        uint256 value = msg.value;
        address sender = msg.sender;
        _invokeBuy(_againCount, sender, value);
        emit BuySuccess(sender,value,_againCount);
    }
    
     
    function _autobuy(uint againCount,address sender,uint256 value) internal running {
        _invokeBuy(againCount, sender, value);
        emit AutoBuySuccess(sender,value,againCount);
    }
    
    function _invokeBuy(uint againCount, address sender, uint256 value) internal running{
        
        uint returnValue = 0;
        
        if(currentRoundLeft <= value){
            returnValue = value - currentRoundLeft;
            value = currentRoundLeft;
        }

        sum_in += value;
        sum_big += value*bigDividendFee/100;
        
        currentRoundLeft -= value;
        shares[sender] += value;
        
        if(returnValue > 0){
            sender.transfer(returnValue);
            emit ReturnMore(sender, value, returnValue);
        }

        
        // define buyerIDs array
        uint256[] memory m_buyIds = new uint256[](currentBuyId);
        
        // roundHistoryList
        roundHistoryList[roundCount][currentBuyId] = Buyer(sender,value,now,againCount,true,m_buyIds);
            
        // buyerHistoryList
        Buyer memory buyer;
        if(buyerHistoryList[roundCount][sender].isValue){ // append
            buyer = buyerHistoryList[roundCount][sender];
            buyer.amount = buyer.amount + value;
            buyerHistoryList[roundCount][sender] = (buyer);
            buyerHistoryList[roundCount][sender].buyIds.push(currentBuyId);
        }else{ // new 
            buyerHistoryList[roundCount][sender] = roundHistoryList[roundCount][currentBuyId];
        }
        
        roundAddressList[roundCount].push(sender);
        
        currentBuyId++;
        
        roundInfo.buyCount++;
        roundInfo.currentAmount = roundInfo.supportAmount - currentRoundLeft;
        roundHistory[roundCount] = roundInfo;
        
        if(currentRoundLeft == 0){
            _initNextRound();
        }

    }
    
    // internal
    function _initNextRound() internal{
        
        currentRoundSupport = currentRoundSupport * (100 + dividendFee + dynamicDividendFee + platformDividendFee + bigDividendFee)/100;
        currentRoundLeft = currentRoundSupport;
        startTime = now;
        endTime = now + timeout;
        currentBuyId = 1;
        
        roundInfo.hasSendBonus = true;
        roundHistory[roundCount] = roundInfo;
        
        roundCount++;
        roundInfo = RoundInfo(roundCount, 0, currentRoundSupport, 0, startTime, endTime, true, false);
        roundHistory[roundCount] = roundInfo;

        if(roundCount > 2){
            
            for (uint256 i = 1; i <= roundHistory[roundCount-2].buyCount; i++){
                
                if(roundHistoryList[roundCount-2][i].againCount>0){
                    _autobuy(roundHistoryList[roundCount-2][i].againCount-1, roundHistoryList[roundCount-2][i].who, roundHistoryList[roundCount-2][i].amount*(100+dividendFee)/100);
                }else{
                    _sendDivedend(roundHistoryList[roundCount-2][i].who,roundHistoryList[roundCount-2][i].amount*(100+dividendFee)/100);
                }

            }
            
        }

        emit NewRound(now, roundCount, currentRoundSupport, currentRoundLeft);
    }
    
    function closeGame() public onlyOwner stoped returns(uint256 balance){
        return invoke_closeGame();
    }
    
    function forceClose() public onlyOwner returns(uint256 balance){
        startTime = now;
        return invoke_closeGame();
    }
    
    function invoke_closeGame() internal returns(uint256 balance){
        
        for (uint256 i = 1; i <= roundHistory[roundCount-1].buyCount; i++){
            closeGame_sendDivedend(roundHistoryList[roundCount-1][i].who,roundHistoryList[roundCount-1][i].amount,roundHistoryList[roundCount-1][i].amount*(preLastPercent)/100);
        }
        
        for (uint256 j = 1; j <= roundHistory[roundCount].buyCount; j++){
            closeGame_sendDivedend(roundHistoryList[roundCount][j].who,roundHistoryList[roundCount][j].amount,roundHistoryList[roundCount][j].amount*(lastPercent)/100);
            if(j == roundHistory[roundCount].buyCount){
                closeGame_sendDivedend(roundHistoryList[roundCount][j].who,sum_big,sum_big);
            }
        }

        return address(this).balance;
        
    }
    
    // view
    function mybalance() public view onlyOwner returns(uint256 balance){
        return address(this).balance;
    }

}