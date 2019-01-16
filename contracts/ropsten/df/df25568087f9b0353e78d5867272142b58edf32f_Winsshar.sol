pragma solidity 0.4.16;

contract SafeMath{

  

  function safeMul(uint256 a, uint256 b) internal returns (uint256){
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256){
    
    return a / b;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256){
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256){
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  
  modifier onlyPayloadSize(uint numWords){
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }

}

contract Token{ 
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

}


contract StandardToken is Token, SafeMath{



    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool success){
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }

    
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success){
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) onlyPayloadSize(3) returns (bool success){
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}

contract Winsshar is StandardToken {

    string public name = "Winsshar";
    string public symbol = "WSR";
    uint256 public decimals = 6;
    uint256 public maxSupply = 100000000000000000;
    uint256 public totalSupply = 1000000000000000;
    uint256 public administrativeSupply = 20000000000000;
    address owner;
    address admin;

    mapping (uint256 => address) public downloaders;
    uint256 public numberOfDownloaders;

    function Winsshar (address administrativeAddress) {
        numberOfDownloaders=0;
        owner = msg.sender;
        balances[owner] = totalSupply;
        admin = administrativeAddress;
        balances[administrativeAddress] = administrativeSupply;
    }

    modifier checkNumberOfDownloaders {
        require(numberOfDownloaders <= 1000000);
        _;

    }

    modifier checkOwner {
      require(owner == msg.sender);
      _;
    }

     modifier checkAdmin {
      require(admin == msg.sender);
      _;
    }

    function giveReward(address awardee) public checkNumberOfDownloaders checkOwner {
        require(awardee != address(0));
        numberOfDownloaders++;
        downloaders[numberOfDownloaders]=awardee;
        transfer(awardee,10);

    }

    function transferDuringIntialOffer(address to, uint256 tokens) public checkNumberOfDownloaders {
        require(tokens <= 2000);
        transfer(to,tokens);
    }

    function administrativePayouts(address to, uint tokens) public checkAdmin {
        require(to != address(0));
        transfer(to,tokens);
    }

    function ownership(address newOwner) public checkOwner {
        owner = newOwner;
        balances[owner] = balances[msg.sender];
        balances[msg.sender] = 0;
    }


    function mintTokens(uint256 addSupply) public checkOwner {
        require(maxSupply-administrativeSupply >= totalSupply+addSupply);
        totalSupply = safeAdd(totalSupply,addSupply);
        balances[owner] = safeAdd(balances[owner],addSupply);

    }

    function burnTokens(uint256 subSupply) public checkOwner{
        require(totalSupply-subSupply >= 0);
        totalSupply = safeSub(totalSupply,subSupply);
        balances[owner] = safeSub(balances[owner],subSupply);

    }

    function() payable {
        require(tx.origin == msg.sender);

    }

}