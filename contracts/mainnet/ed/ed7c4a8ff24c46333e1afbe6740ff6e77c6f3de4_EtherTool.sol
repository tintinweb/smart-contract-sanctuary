pragma solidity ^0.4.18;

//https://github.com/OpenZeppelin/zeppelin-solIdity/blob/master/contracts/math/SafeMath.sol
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
    // assert(b > 0); // SolIdity automatically throws when divIding by 0
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


contract EtherTool { 
    using   SafeMath for uint256;     

    function EtherTool()  public {
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

    mapping (address => uint256) public userEtherOf;    
    
    function depositEther() public payable {
        if (msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);  
        }
    }
    
    function withdrawEther() public  returns(bool _result) {                  
        return _withdrawEther(msg.sender);
    }
    
    function withdrawEtherTo(address _user) public returns(bool _result) {     
        return _withdrawEther(_user);
    }

    function _withdrawEther(address _to) internal returns(bool _result) {     
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

    event OnTransfer(address indexed _sender, address indexed _to, bool indexed _done, uint256 _amount, uint _eventTime, uint eventId);

    function batchTransfer1(address[] _tos, uint256 _amount) public payable returns (uint256 _doneNum){
        lock();
        if(msg.value > 0) {          
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
        require(_amount > 0);
        require(_tos.length > 0);

        _doneNum = 0;
        for(uint i = 0; i < _tos.length; i++){
            bool done = false;
            address to = _tos[i];
            if(to != 0x0 && userEtherOf[msg.sender] >= _amount){
                userEtherOf[msg.sender] = userEtherOf[msg.sender].sub(_amount);
                to.transfer(_amount);                                            
                _doneNum = _doneNum.add(1);
                done = true;
            }
            emit OnTransfer(msg.sender, to, done, _amount, now, getEventId());
        }
        unLock();
    }

    function batchTransfer2(address[] _tos, uint256[] _amounts) public payable returns (uint256 _doneNum){
        lock();
        if(msg.value > 0) {          
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
        require(_amounts.length > 0);
        require(_tos.length > 0);
        require(_tos.length == _amounts.length);

        _doneNum = 0;
        for(uint i = 0; i < _tos.length; i++){
            bool done = false;
            address to = _tos[i];
            uint256 amount = _amounts[i]; 
            if((to != 0x0) && (amount > 0) && (userEtherOf[msg.sender] >= amount)){
                userEtherOf[msg.sender] = userEtherOf[msg.sender].sub(amount);
                to.transfer(amount);                                            
                _doneNum = _doneNum.add(1);
                done = true;
            }
            emit OnTransfer(msg.sender, to, done, amount, now, getEventId());
        }
        unLock();
    }
        
    function uint8ToString(uint8 v) private pure returns (string)
    {
        uint maxlength = 8;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1];
        }
        string memory str = string(s);
        return str;
    }

    function getBytes32() public view returns (bytes32 _result){
        _result = keccak256(now, block.blockhash(block.number - 1));
    }

    function getHash1(uint8[5]  _winWhiteBall, uint8 _winRedBall, bytes32 _nonce) public pure returns (bytes32 _result){
        _result =  keccak256(_winWhiteBall, _winRedBall, _nonce);
    }

    function getHash2(address _user, bytes32 _nonce) public pure returns (bytes32 _result){
        _result =  keccak256(_user, _nonce);
    }

    function () public payable {                                    //function depositEther() public payable 
        if(msg.value > 0) {          
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
    }

}