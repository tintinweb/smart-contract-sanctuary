pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Base { 
    using SafeMath for uint256; 
    uint public createTime = now;
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner)  public  onlyOwner {
        owner = _newOwner;
    }    
            
    bool public globalLocked = false;     

    function lock() internal {         
        require(!globalLocked);
        globalLocked = true;
    }

    function unLock() internal {
        require(globalLocked);
        globalLocked = false;
    }    

    function setLock()  public onlyOwner{      
        globalLocked = false;     
    }

    mapping (address => uint256) public userEtherOf;    
    
    function userRefund() public  returns(bool _result) {             
        return _userRefund(msg.sender);
    }

    function _userRefund(address _to) internal returns(bool _result){  
        require (_to != 0x0);  
        lock();
        uint256 amount = userEtherOf[msg.sender];   
        if(amount > 0){
            userEtherOf[msg.sender] = 0;
            _to.transfer(amount); 
            _result = true;
        }
        else{
            _result = false;
        }
        unLock();
    }

    uint public currentEventId = 1;                         

    function getEventId() internal returns(uint _result) {    
        _result = currentEventId;
        currentEventId ++;
    }
   
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is Base {                                             
    string public name = &#39;Don Quixote Token&#39;;                           
    string public symbol = &#39;DON&#39;;
    uint8 public decimals = 9;
    uint256 public totalSupply = (10 ** 9) * (10 ** uint256(decimals));    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

 
    function webGiftUnTransfer(address _from, address _to) public view returns(bool _result);   

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);

        require(_from != _to);
        require(!webGiftUnTransfer(_from, _to));                                         

        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add( balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_value > 0);
        require(_value <= allowance[_from][msg.sender]);    
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {  
        require(_spender != 0x0);
        require(_value > 0);
        //require(_value <= balanceOf[msg.sender]);         
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        require(_spender != 0x0);
        require(_value > 0);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {           
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
        totalSupply = totalSupply.sub(_value);   
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_from != 0x0);
        require(_value > 0);
        assert(1 >= 2);
        symbol = &#39;DON&#39;;
        return false;
    }
}

contract DonQuixoteToken is TokenERC20{          
    address public iniOwner;                      

    function DonQuixoteToken(address _santaClaus)  public {
        require(_santaClaus != 0x0 && _santaClaus != msg.sender);
        owner = msg.sender;
        iniOwner = msg.sender;
        balanceOf[msg.sender] = totalSupply; 
        santaClaus = _santaClaus;
    }

    uint public lastAddYear = now;

    event OnAddYearToken(uint256 _lastTotalSupply, uint256 _currentTotalSupply, uint _years, uint _eventTime, uint _eventId);

    function addYearToken() public returns(bool _result) {   
        _result = false;
        if(now - lastAddYear > 1 years){
            uint256 _lastTotalSupply = totalSupply;
            uint y = (now - lastAddYear).div(1 years);  
            if(y > 0){
                for(uint i = 1; i <= y; i++){
                    totalSupply = totalSupply.mul(102).div(100);       
                }
                uint256 _add = totalSupply.sub(_lastTotalSupply);
                balanceOf[iniOwner] = balanceOf[iniOwner].add(_add);
                lastAddYear = lastAddYear.add(y.mul(1 years));
                emit OnAddYearToken(_lastTotalSupply, totalSupply, y, now, getEventId());
                _result = true;
            }
        }
    }

    address public santaClaus;                         

    function setSantaClaus(address _newSantaClaus)  public  onlyOwner {  
        require(_newSantaClaus != 0x0);
        santaClaus = _newSantaClaus;
    }

    modifier onlySantaClaus {
        require(msg.sender == santaClaus);
        _;
    }

    uint    public webGiftLineTime = now + 60 days;
    uint256 public webGiftTotalAmount = totalSupply * 5 / 100;  
    uint256 public webGiftSentAmount  = 0;                       
    uint256 public webGiftOnceMaxAmount = 600 * (10 ** uint256(decimals));  
    uint256 public webGiftEtherAmount = 0.005 ether;                      
    bool    public stopSendWebGift  = false;

    function setWebGiftEtherAmount(uint256 _value) public onlyOwner{
        require(_value <= 0.1 ether);
        webGiftEtherAmount = _value;
    }

    function setStopSendWebGift(bool _value) public onlyOwner{
        stopSendWebGift = _value;
    }

    function canSendWebGift() public view returns (bool _result){
        _result = (now < webGiftLineTime) && (!stopSendWebGift) && (webGiftSentAmount <= webGiftTotalAmount) && (balanceOf[iniOwner] >= webGiftOnceMaxAmount);
    }

    function canSendWebGifAmount() public view returns(uint256 _result) {     
        _result = 0;
        if(canSendWebGift()){
            _result = webGiftTotalAmount.sub(webGiftSentAmount);  
        }
    }

    function setWebGiftOnceMaxAmount(uint256 _value) public onlyOwner{
        require(_value < 1000 * (10 ** uint256(decimals)) && _value > 0);   
        webGiftOnceMaxAmount = _value;
    }    

    event OnSendWebGiftToken(address _user, uint256 _gifTokenAmount, bool _result, uint _eventTime, uint _eventId);

    function sendWebGiftToken(address _user, uint256 _gifAmount) public onlySantaClaus returns(bool _result)  {
        lock();   
        _result = _sendWebGiftToken( _user,  _gifAmount);
        unLock();
    }

    function _sendWebGiftToken(address _user, uint256 _gifAmount) private returns(bool _result)  { 
        _result = false;
        require(_user != 0x0);
        require(_gifAmount > 0);
        require(_user != iniOwner);                              
        require(_gifAmount <= webGiftOnceMaxAmount);
        require(canSendWebGifAmount() >= _gifAmount);    
        _transfer(iniOwner, _user, _gifAmount);
        webGiftSentAmount = webGiftSentAmount.add(_gifAmount);
        
        _logSendWebGiftAndSendEther(_user, _gifAmount);

        _result = true;
        emit OnSendWebGiftToken(_user, _gifAmount, _result, now,  getEventId());
    }

    function batchSendWebGiftToken(address[] _users, uint256 _gifAmount) public  onlySantaClaus returns(uint _result)  {
        lock();   
        _result = 0;
        for (uint index = 0; index < _users.length; index++) {
            address _user =  _users[index];
            if(_sendWebGiftToken(_user, _gifAmount)){
                _result = _result.add(1);
            } 
        }
        unLock();
    }

    mapping (address=>mapping(address=>bool)) public gameTransferFlagOf;   

    function setGameTransferFlag(address _gameAddress, bool _gameCanTransfer) public { 
        require(_gameAddress != 0x0);
        gameTransferFlagOf[msg.sender][_gameAddress] = !_gameCanTransfer;
    }

    mapping(address => bool) public gameWhiteListOf;                           

    event OnWhiteListChange(address indexed _gameAddr, address _operator, bool _result,  uint _eventTime, uint _eventId);

    function addWhiteList(address _gameAddr) public onlyOwner {
        require (_gameAddr != 0x0);  
        gameWhiteListOf[_gameAddr] = true;
        emit OnWhiteListChange(_gameAddr, msg.sender, true, now, getEventId());
    }  

    function delWhiteList(address _gameAddr) public onlyOwner {
        require (_gameAddr != 0x0);  
        gameWhiteListOf[_gameAddr] = false;   
        emit OnWhiteListChange(_gameAddr, msg.sender, false, now, getEventId()); 
    }
    
    function isWhiteList(address _gameAddr) private view returns(bool _result) {
        require (_gameAddr != 0x0);  
        _result = gameWhiteListOf[_gameAddr];
    }

    function withhold(address _user,  uint256 _amount) public returns (bool _result) {    
        require(_user != 0x0);
        require(_amount > 0);
        require(msg.sender != tx.origin);
        require(!gameTransferFlagOf[_user][msg.sender]);
        require(isWhiteList(msg.sender));
        require(balanceOf[_user] >= _amount);
        
        //lock();     
        _transfer(_user, msg.sender, _amount);
        //unLock();
        return true;
    }


    uint    public gameGiftLineTime = now + 90 days;  
    uint256 public gameGiftMaxAmount  = totalSupply * 5 / 100; 
    uint256 public gameGiftSentAmount  = 0;                      
    uint256 public gameGiftOnceAmount  = 60 * (10 ** uint256(decimals));   
    uint    public gameGiftUserTotalTimes = 100;            
    uint    public gameGiftUserDayTimes = 20;                         
    
    struct gameGiftInfo     
    {
        uint ThisDay;       
        uint DayTimes;     
        uint TotalTimes;  
    }

    mapping(address => gameGiftInfo) public gameGiftInfoList;   

    function _logGameGiftInfo(address _player) private {
        gameGiftInfo storage ggi = gameGiftInfoList[_player];
        uint thisDay = now / (1 days);
        if (ggi.ThisDay == thisDay){
            ggi.DayTimes = ggi.DayTimes.add(1);
        }
        else
        {
            ggi.ThisDay = thisDay;
            ggi.DayTimes = 1;
        }
        ggi.TotalTimes = ggi.TotalTimes.add(1);
    }

    function timesIsOver(address _player) public view returns(bool _result){ 
        gameGiftInfo storage ggi = gameGiftInfoList[_player];
        uint thisDay = now / (1 days);
        if (ggi.ThisDay == thisDay){
            _result = (ggi.DayTimes >= gameGiftUserDayTimes) || (ggi.TotalTimes >= gameGiftUserTotalTimes);
        }
        else{
            _result = ggi.TotalTimes >= gameGiftUserTotalTimes;
        }
    }

    function setGameGiftOnceAmount(uint256 _value) public onlyOwner{
        require(_value > 0 && _value < 100 * (10 ** uint256(decimals)));
        gameGiftOnceAmount = _value;
    }

    function gameGifIsOver() view public returns(bool _result){
        _result = (gameGiftLineTime <= now) || (balanceOf[iniOwner] < gameGiftOnceAmount) || (gameGiftMaxAmount < gameGiftSentAmount.add(gameGiftOnceAmount));    
    }  

    event OnSendGameGift(address _game, address _player, uint256 _gameGiftOnceAmount, uint _eventTime, uint _eventId);
    
    function _canSendGameGift() view private returns(bool _result){
        _result = (isWhiteList(msg.sender)) && (!gameGifIsOver());
    }

    function sendGameGift(address _player) public returns (bool _result) {
        uint256 _tokenAmount = gameGiftOnceAmount;
        _result = _sendGameGift(_player, _tokenAmount);
    }

    function sendGameGift2(address _player, uint256 _tokenAmount) public returns (bool _result) {
        require(gameGiftOnceAmount >= _tokenAmount);
        _result = _sendGameGift(_player, _tokenAmount);
    }

    function _sendGameGift(address _player, uint256 _tokenAmount) private returns (bool _result) {
        require(_player != 0x0);
        require(_tokenAmount > 0 && _tokenAmount <= gameGiftOnceAmount);
        
        if(_player == iniOwner){ 
            return;
        }                                 

        require(msg.sender != tx.origin);
        if(!_canSendGameGift()){   
            return;
        }
        if(timesIsOver(_player)){ 
            return;
        }

        lock();         
        _transfer(iniOwner, _player, _tokenAmount);
        gameGiftSentAmount = gameGiftSentAmount.add(_tokenAmount);
        emit OnSendGameGift(msg.sender,  _player,   _tokenAmount, now, getEventId());
        _logGameGiftInfo(_player);    
        unLock();
        _result = true;
    }


    uint256  public baseIcoPrice =  (0.0002 ether) / (10 ** uint256(decimals)); 
  
    function getIcoPrice() view public returns(uint256 _result){
        _result = baseIcoPrice;
        uint256 addDays = (now - createTime) / (1 days); 
        for(uint i = 1; i <= addDays; i++){
            _result = _result.mul(101).div(100);
        }
    } 
 
    uint256 public icoMaxAmount = totalSupply * 40 / 100;   
    uint256 public icoedAmount = 0;                        
    uint    public icoEndLine = now + 180 days;          

    function icoIsOver() view public returns(bool _result){
        _result = (icoEndLine < now)  || (icoedAmount >= icoMaxAmount) || (balanceOf[iniOwner] < (icoMaxAmount - icoedAmount)); 
    }  

    function getAvaIcoAmount() view public returns(uint256 _result){  
        _result = 0;
        if (!icoIsOver()){
            if (icoMaxAmount > icoedAmount){               
                _result = icoMaxAmount.sub(icoedAmount);  
            }
        }
    }  

    event OnBuyIcoToken(uint256 _tokenPrice, uint256 _tokenAmount, uint256 _etherAmount, address _buyer, uint _eventTime, uint _eventId);

    function buyIcoToken1()  public payable returns (bool _result) {  
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value); 
        }
        _result = _buyIcoToken(totalSupply);    
    }

    function buyIcoToken2(uint256 _tokenAmount)  public payable returns (bool _result) {  
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value); 
        }
        _result = _buyIcoToken(_tokenAmount); 
    }

    function _buyIcoToken(uint256 _tokenAmount)  private returns (bool _result) {  
        _result = false;    
        require(_tokenAmount > 0);   
        require(!icoIsOver());   
        require(msg.sender != iniOwner);                                      
        require(balanceOf[iniOwner] > 0);

        uint256 buyIcoPrice =  getIcoPrice();
        uint256 canTokenAmount = userEtherOf[msg.sender].div(buyIcoPrice);    
        require(userEtherOf[msg.sender] > 0 && canTokenAmount > 0);
        if(_tokenAmount < canTokenAmount){
            canTokenAmount = _tokenAmount;
        }

        lock();

        uint256 avaIcoAmount = getAvaIcoAmount();
        if(canTokenAmount > avaIcoAmount){
             canTokenAmount = avaIcoAmount;
        }
        require(canTokenAmount > 0);
        uint256 etherAmount = canTokenAmount.mul(buyIcoPrice);
        userEtherOf[msg.sender] = userEtherOf[msg.sender].sub(etherAmount);   
        userEtherOf[iniOwner] = userEtherOf[iniOwner].add(etherAmount);        
        _transfer(iniOwner, msg.sender, canTokenAmount);                      
        emit OnBuyIcoToken(buyIcoPrice, canTokenAmount, etherAmount, msg.sender, now, getEventId());
        icoedAmount = icoedAmount.add(canTokenAmount);
        _result = true;

        unLock();
    }

    struct webGiftInfo   
    {
        uint256 Amount; 
        uint PlayingTime; 
    }

    mapping(address  => webGiftInfo) public webGiftList;

    function _logSendWebGiftAndSendEther(address _to, uint256 _amount) private {
        require(_to != 0x0);
        webGiftInfo storage wgi = webGiftList[_to];

        if(wgi.Amount == 0){
            if (userEtherOf[iniOwner] >= webGiftEtherAmount){          
                userEtherOf[iniOwner] = userEtherOf[iniOwner].sub(webGiftEtherAmount);
                _to.transfer(webGiftEtherAmount);
            }
        }

        if(wgi.PlayingTime == 0){
            wgi.Amount = wgi.Amount.add(_amount);
        }
    }

    event OnLogPlaying(address _player, uint _eventTime, uint _eventId);

    function logPlaying(address _player) public returns (bool _result) {
        _result = false;
        require(_player != 0x0);
        require(msg.sender != tx.origin);
        require(isWhiteList(msg.sender)); 

        if (gameGiftLineTime < now) {
            return;
        }
        
        webGiftInfo storage wgi = webGiftList[_player];
        if(wgi.PlayingTime == 0){                                   
            wgi.PlayingTime = now;
            emit OnLogPlaying(_player, now, getEventId());
        }
        _result = true;
    }

    function webGiftUnTransfer(address _from, address _to) public view returns(bool _result){
        require(_from != 0x0);
        require(_to != 0x0);
        if(isWhiteList(_to) || _to == iniOwner){    
            _result = false;
            return;
        }
        webGiftInfo storage wgi = webGiftList[_from];
        _result = (wgi.Amount > 0) && (wgi.PlayingTime == 0) && (now <= gameGiftLineTime);   
    }

    event OnRestoreWebGift(address _user, uint256 _tokenAmount, uint _eventTime, uint _eventId);

    function restoreWebGift(address _user) public  returns (bool _result) { 
        _result = false;
        require(_user != 0x0);
        webGiftInfo storage wgi = webGiftList[_user];
        if ((0 == wgi.PlayingTime) && (0 < wgi.Amount)){  
            if (gameGiftLineTime.sub(20 days) < now  && now <= gameGiftLineTime) {   
                uint256 amount = wgi.Amount;
                if (amount > balanceOf[_user]){
                    amount = balanceOf[_user];
                }
                _transfer(_user, iniOwner, amount);
                emit OnRestoreWebGift(_user, amount, now, getEventId());
                _result = true;
            }
        }
    }

    function batchRestoreWebGift(address[] _users) public  returns (uint _result) {       
        _result = 0;
        for(uint i = 0; i < _users.length; i ++){
            if(restoreWebGift(_users[i])){
                _result = _result.add(1);
            }
        }
    
    }

    
    function () public payable {                      
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value); 
        }

        if(msg.sender != iniOwner){
            if ((userEtherOf[msg.sender] > 0) && (!icoIsOver())){
                _buyIcoToken(totalSupply);             
            }
        }
    }


}