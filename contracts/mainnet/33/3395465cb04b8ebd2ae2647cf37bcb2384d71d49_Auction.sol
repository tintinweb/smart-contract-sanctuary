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

interface IDividendToken{                     
    function profitOrgPay() payable external ; 
}

interface IGame { 
    function setBanker(address _banker, uint256 _beginTime, uint256 _endTime) external returns(bool _result); 
    function canSetBanker() view external  returns (bool);  
    function bankerEndTime() constant  external returns (uint);  
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
  
    function setLock()  public onlyOwner {      
        globalLocked = false;     
    }

    mapping (address => uint256) public userEtherOf;    
    
    function userRefund() public  returns(bool _result) {            
        return _userRefund(msg.sender);
    }

    function _userRefund(address _to) internal returns(bool _result) {    
        require (_to != 0x0);  
        lock();
        uint256 amount = userEtherOf[msg.sender];   
        if(amount > 0) {
            userEtherOf[msg.sender] = 0;
            _to.transfer(amount); 
            _result = true;
        }
        else {
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

contract Beneficial is Base {            

    function Beneficial() public {
    }

    address public shareholder;                
    bool public shareholderIsToken = false;     
    string public officialUrl;                 
	
    function setOfficialUrl(string _newOfficialUrl) public onlyOwner{
        officialUrl = _newOfficialUrl;
    }       
     
    function setShareholder(address _newShareholder, bool _isToken) public onlyOwner {
        require(_newShareholder != 0x0);
        shareholderIsToken = _isToken;
        shareholder = _newShareholder;
    }
    
    function _userRefund(address _to) internal  returns(bool _result){ 
        require (_to != 0x0);  
        lock();
        uint256 amount = userEtherOf[msg.sender];   
        if(amount > 0){
            userEtherOf[msg.sender] = 0;
            if(shareholderIsToken && msg.sender == shareholder){       
                IDividendToken token = IDividendToken(shareholder);
                token.profitOrgPay.value(amount)();
            }
            else{
                _to.transfer(amount); 
            }
            _result = true;
        }
        else{
            _result = false;
        }
        unLock();
    }
}

contract Auction is Beneficial {
    function Auction()  Beneficial() public {
        owner = msg.sender;
        shareholder = msg.sender;
    }
   
    int public gameIndex = 1;                      
    mapping(int => address) public indexGameOf;    

    function _addIndexGame(address _gameAddr) private {
            indexGameOf[gameIndex] = _gameAddr;
            gameIndex ++;
    }
   
    mapping(address => bool) public whiteListOf;    
    mapping (uint64 => address) public indexAddress;    

    event OnWhiteListChange(address indexed _Addr, address _operator, bool _result,  uint _eventTime, uint _eventId);

    function addWhiteList(address _Addr) public onlyOwner {
        require (_Addr != 0x0);  
        whiteListOf[_Addr] = true;
        _addIndexGame(_Addr);
        emit OnWhiteListChange(_Addr, msg.sender, true, now, getEventId());
    }  

    function delWhiteList(address _Addr) public onlyOwner {
        require (_Addr != 0x0);  
        whiteListOf[_Addr] = false;    
        emit OnWhiteListChange(_Addr, msg.sender, false, now, getEventId()) ;
    }
    
    function isWhiteListGame(address _Addr) private view returns(bool _result) { 
        _result = whiteListOf[_Addr];
    }

    uint auctionId = 1;             

    struct AuctionObj {
        uint id;                  
        address objAddr;          
        uint256 beginTime;        
        uint256 endTime;          
        uint256 price;            
        address winnerAddr;       
        uint bankerTime;         
        bool emptyGameBanker;   
    } 

    mapping (address => AuctionObj) public auctionObjOf;   

    event OnSetAuctionObj(uint indexed _auctionId, address indexed  _objAddr, uint256 _beginTime, uint256 _endTime, uint _bankerTime, bool _result, uint _code, uint _eventTime, uint _eventId);

    function setAuctionObj(address _gameAddr, uint256 _auctionEndTime, uint _bankerTime)             
        public onlyOwner  returns (bool _result) 
    {
        _result = _setAuctionObj(_gameAddr, _auctionEndTime, _bankerTime);    
    }

    function addWhiteListAddSetAuctionObj(address _gameAddr, uint256 _auctionEndTime, uint _bankerTime) 
        public onlyOwner returns (bool _result)
    {    
         addWhiteList(_gameAddr);
        _result = _setAuctionObj(_gameAddr, _auctionEndTime, _bankerTime);    
    }

    //uint constant minBankTime = 1 days;                

    function _setAuctionObj(address _gameAddr, uint256 _auctionEndTime, uint _bankerTime)  private  returns (bool _result) {   
        _result = false;
        require(_gameAddr != 0x0);
        require(now < _auctionEndTime);
        //require(minBankTime <= _bankerTime);
        //require(_bankerTime < 10 years);
        if(!isWhiteListGame(_gameAddr)) {               
            emit OnSetAuctionObj(auctionId, _gameAddr, now,  _auctionEndTime, _bankerTime, false, 1, now, getEventId()) ;
            return;
        }     
      
        AuctionObj storage ao = auctionObjOf[_gameAddr];
        if(ao.endTime <= now && !ao.emptyGameBanker) {   
            AuctionObj memory  newAO = AuctionObj({
                id: auctionId,
                objAddr: _gameAddr,
                beginTime: now,
                endTime : _auctionEndTime,
                winnerAddr: owner,
                price: 0,
                bankerTime: _bankerTime,
                emptyGameBanker: true                  
            });
            emit OnSetAuctionObj(auctionId, _gameAddr, now,  _auctionEndTime, _bankerTime, true, 0, now, getEventId()) ;
            auctionObjOf[_gameAddr] = newAO;      
            auctionId ++;
            _result = true;
            return;
        }else{
            emit OnSetAuctionObj(auctionId, _gameAddr, now,  _auctionEndTime, _bankerTime, false, 2, now, getEventId()) ;
        }
    }

    event OnBid(uint indexed _auctionId, address _sender, address  _objAddr, uint256 _price, bool  _result, uint  _code, uint _eventTime, uint _eventId);

    function bid(address _objAddr, uint256 _price) public payable returns(bool _result) {    
        _result = false;
        require(_objAddr != 0x0);
		AuctionObj storage ao = auctionObjOf[_objAddr];
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
        if(10**16 > _price){                 
            emit OnBid(ao.id, msg.sender, _objAddr,  _price, false, 3, now, getEventId());
            return;
        }
        if(userEtherOf[msg.sender] < _price){                 
            emit OnBid(ao.id, msg.sender, _objAddr,  _price, false, 1, now, getEventId());
            return;
        }
        if(now < ao.endTime) {                 
            if(_price > ao.price) {            
                userEtherOf[msg.sender] = userEtherOf[msg.sender].sub(_price);          
                userEtherOf[ao.winnerAddr] = userEtherOf[ao.winnerAddr].add(ao.price);    
                ao.price = _price;
                ao.winnerAddr = msg.sender;
                emit OnBid(ao.id, msg.sender, _objAddr,  _price, true, 0, now, getEventId());
                _result = true;
                return;
            }
        }

        emit OnBid(ao.id, msg.sender, _objAddr,  _price, false, 2, now, getEventId());
        return;
    }

    event OnSetGameBanker(uint indexed _auctionId, address indexed _gameAddr, bool indexed _result,  uint _code, uint _eventTime, uint _eventId);

    function setGameBanker(address _gameAddr) public returns (bool _result) {      
        _result = false;
        require(_gameAddr != 0x0);
        //require(isWhiteListGame(_gameAddr));      
        lock();
        AuctionObj storage ao = auctionObjOf[_gameAddr];
        if(ao.id > 0 && ao.endTime <= now) {                                         
            IGame g = IGame(_gameAddr);
            if(g.bankerEndTime() < now && g.canSetBanker()){                      
                _result = g.setBanker(ao.winnerAddr,  now,  now.add(ao.bankerTime));     
                if(_result){
					emit OnSetGameBanker(ao.id, _gameAddr, _result, 0, now, getEventId());
                    ao.emptyGameBanker = false;                                            
                    userEtherOf[shareholder] =  userEtherOf[shareholder].add(ao.price);    
                    _setAuctionObj(_gameAddr,  (now.add(ao.bankerTime)).sub(1 hours) , ao.bankerTime); 
                }else{
				  emit OnSetGameBanker(ao.id, _gameAddr, false, 1, now, getEventId());     
				}
            }else{
                emit OnSetGameBanker(ao.id, _gameAddr, false, 2, now, getEventId());     
            }
        }else{
            emit OnSetGameBanker(ao.id, _gameAddr, false, 3, now, getEventId());
        }
        unLock();
    }
    
    function () public payable {
        if(msg.value > 0) {          
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
    }

}