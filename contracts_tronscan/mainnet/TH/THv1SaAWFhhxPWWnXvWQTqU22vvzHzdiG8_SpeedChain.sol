//SourceUnit: SPC.sol

pragma solidity ^0.5.0;


contract ERC20Interface {


  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
}


contract Token is ERC20Interface {

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;

  event Burn(address indexed from, uint256 value);
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]); 
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }

  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, address(this), _extraData);
    return true;
  }

  function burn(uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }


  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(_balances[_from] >= _value);
    require(_value <= _allowed[_from][msg.sender]);
    _balances[_from] -= _value;
    _allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }


  function _transfer(address _from, address _to, uint _value) internal {

    require(_to != address(0x0));

    require(_balances[_from] >= _value);

    require(_balances[_to] + _value > _balances[_to]);

    uint previousBalances = _balances[_from] + _balances[_to];

    _balances[_from] -= _value;

    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);

    assert(_balances[_from] + _balances[_to] == previousBalances);
  }

}

contract SPC is Token {

  address founderOne;
  address founderTwo;
  address payable receiveBalance;
  mapping(address => bool) founderSignature;
  uint8 countSignature = 0;
  constructor(uint256 _initialSupply, address _founderOne, address _founderTwo) public {
    founderOne = _founderOne;
    founderTwo = _founderTwo;
    name = "SPC";
    symbol = "SPC";
    decimals = 6;
    totalSupply = _initialSupply * 10 ** uint256(decimals);
    _balances[msg.sender] = totalSupply * 8 / 10;
    _balances[address(this)] = totalSupply / 5;
  }


  function signature(address payable _receiveAddress) public {
    require(msg.sender == founderOne || msg.sender == founderTwo, "Not have permission");
    require(!founderSignature[msg.sender]);
    countSignature++;
    founderSignature[msg.sender] = true;
    if(countSignature == 2){
      require(_receiveAddress == receiveBalance);
      _receiveAddress.transfer(address(this).balance);
      if(_balances[address(this)] > 0){
        _transfer(address(this),_receiveAddress,_balances[address(this)]);
      }
    } else {
      receiveBalance = _receiveAddress;
    }
  }

  function unSignature() public {
    require(msg.sender == founderOne || msg.sender == founderTwo, "Not have permission");
    require(founderSignature[msg.sender]);
    countSignature = countSignature - 1;
    founderSignature[msg.sender] = false;
  }

  function () external payable {}

}


//SourceUnit: speedchain.sol

pragma solidity ^0.5.0;
import './SPC.sol';

contract SpeedChain {

  address payable owner;
  address payable public tokenAddress;

  struct Member {
    uint8 maxLine;
    address payable ref;
    bool exists;
    uint256 deposit;
    uint256 income;
    uint256 tokenBalance;
    uint256 partner;
  }

  struct Maxtrix {
      mapping(address=>uint256) currentID;
      mapping(uint256=>address payable) idToAddress;
      mapping (address => bool) isReceive;
      mapping (address => uint256) cycle;
      mapping (address => uint256) receive;
      uint256 totalId;
      uint256 payID;
  }
  
  mapping(address=>Member) public members;
  mapping (uint8 => uint256) public lines;
  uint256 public totalTokenBouns;
  SPC token;
  Maxtrix[5] maxtrix;
  constructor(address payable _owner, address payable _tokenAddress) public {
    token = SPC(_tokenAddress);
    tokenAddress = _tokenAddress;
    owner = _owner;
    Member memory user = Member({
        maxLine: 5,
        ref: address(0),
        exists: true,
        deposit: 0,
        income: 0,
        tokenBalance: 0,
        partner: 0
    });

    members[owner] = user;
    lines[1] = 300 trx;
    lines[2] = 3000 trx;
    lines[3] = 30000 trx;
    lines[4] = 300000 trx;
    lines[5] = 3000000 trx;

    for(uint8 i=0; i <5; i++){
      maxtrix[i].totalId = 1;
      maxtrix[i].payID = 1;
      maxtrix[i].currentID[owner] = 1;
      maxtrix[i].idToAddress[1] = owner;
      maxtrix[i].isReceive[owner] = true;
      maxtrix[i].cycle[owner] = 3;
    }

  }
  
  function depositNonRef(uint8 _line) public payable {
      if(!members[msg.sender].exists){
        _addNewUser(msg.sender, address(0));
      }
      _deposit(msg.sender,_line, msg.value);
  }

  function deposit(address payable ref, uint8 _line) public payable {
    require(msg.sender != ref);
    if(!members[msg.sender].exists){
      if(!members[ref].exists){
        ref = address(0);
      }
      _addNewUser(msg.sender, ref);
    }
    _deposit(msg.sender,_line, msg.value);
  } 

  function claimToken() public {
    require(members[msg.sender].exists, "User not exists");
    if(token.balanceOf(address(this)) >= members[msg.sender].tokenBalance){
          token.transfer(msg.sender, members[msg.sender].tokenBalance);
          emit WithdrawToken(msg.sender, members[msg.sender].tokenBalance);
          members[msg.sender].tokenBalance = 0;
    }
  }
  
  function _deposit (address payable _add, uint8 _line, uint256 _value) private {
      require (_line <= members[_add].maxLine);
      require (_value == lines[_line]);
      require (!maxtrix[_line-1].isReceive[_add]);
      members[_add].deposit += msg.value;
      totalTokenBouns += getTokenBouns(msg.value / 2);
      members[_add].tokenBalance += getTokenBouns(msg.value / 2);
      owner.transfer(msg.value / 10);
      tokenAddress.transfer(msg.value / 10);
      _handleMaxtrix(_line-1, _add, _value);
      if(_line == 1 && maxtrix[0].cycle[_add] >= 4 && members[_add].maxLine == 1 && members[_add].partner >= 1){
        members[_add].maxLine = 2;
      }

      if(_line >1 && _line < 5 && maxtrix[_line-1].cycle[_add] >= 2 && members[_add].maxLine == _line){
        members[_add].maxLine = _line+1;
      }

      emit Deposit(msg.sender, msg.value);
  }
  

  function _addNewUser(address payable _add,address payable _ref) private { 
    Member memory user = Member({
        maxLine: 1,
        ref: _ref,
        exists: true,
        deposit: 0,
        income: 0,
        tokenBalance: 0,
        partner: 0
    });
    members[_add] = user;
    if(_ref != address(0)){
      members[_ref].partner += 1;
      if(maxtrix[0].cycle[_ref] >=4 && members[_ref].maxLine == 1){
        members[_ref].maxLine = 2;
      }
    }
    emit NewMember(_add);
  }
  




  function _handleMaxtrix(uint8 _matrix, address payable _add, uint256 _value) private {
    maxtrix[_matrix].idToAddress[maxtrix[_matrix].currentID[_add]] = address(0);
    maxtrix[_matrix].totalId++;
    maxtrix[_matrix].currentID[_add] = maxtrix[_matrix].totalId;
    maxtrix[_matrix].idToAddress[maxtrix[_matrix].totalId] = _add;
    maxtrix[_matrix].isReceive[_add] = true;
    maxtrix[_matrix].cycle[_add] += 1;
    maxtrix[_matrix].receive[_add] = 0;

    if(maxtrix[_matrix].isReceive[members[_add].ref]){
      totalTokenBouns += getTokenBouns(msg.value);
      members[members[_add].ref].tokenBalance += getTokenBouns(msg.value);
      members[_add].ref.transfer(_value * 4 / 10);
      maxtrix[_matrix].receive[members[_add].ref] += _value * 4 / 10;
      members[members[_add].ref].income += _value * 4 / 10;
      if(maxtrix[_matrix].receive[members[_add].ref] == _value * 2){
        maxtrix[_matrix].isReceive[members[_add].ref] = false;
        maxtrix[_matrix].receive[members[_add].ref] = 0;
        emit MaxOut(members[_add].ref,_matrix+1);
      }

      emit DirectReference(members[_add].ref, _add, _value * 4 / 10);

      address payable winner = _findIdRecieve(_matrix);
      winner.transfer(_value * 4 / 10);
      members[winner].income += _value * 4 / 10;
      maxtrix[_matrix].payID = maxtrix[_matrix].currentID[winner];
      maxtrix[_matrix].receive[winner] += _value * 4 / 10;
      if(maxtrix[_matrix].receive[winner] == _value * 2){
        maxtrix[_matrix].isReceive[winner] = false;
        maxtrix[_matrix].receive[winner] = 0;
        emit MaxOut(winner,_matrix+1);
      }
    } else {
      for(uint8 i=0; i < 2; i++){
        address payable winner = _findIdRecieve(_matrix);
        winner.transfer(_value * 4 / 10);
        members[winner].income += _value * 4 / 10;
        maxtrix[_matrix].payID = maxtrix[_matrix].currentID[winner];
        maxtrix[_matrix].receive[winner] += _value * 4 / 10;
        if(maxtrix[_matrix].receive[winner] == _value * 2){
          maxtrix[_matrix].isReceive[winner] = false;
          maxtrix[_matrix].receive[winner] = 0;
          emit MaxOut(winner,_matrix+1);
        }
      }
    }
  }


  function _findIdRecieve(uint8 _matrix) private view returns(address payable){
    bool isFinish;
    address payable result = address(0);
    uint256 currentPaidId = maxtrix[_matrix].payID;
    while(!isFinish && currentPaidId <= maxtrix[_matrix].totalId){
      if(maxtrix[_matrix].isReceive[maxtrix[_matrix].idToAddress[currentPaidId]]){
        result = maxtrix[_matrix].idToAddress[currentPaidId];
        isFinish = true;
      } else {
        currentPaidId++;
      }
    }
    return result;
  }

  function getUserMaxtrix(uint8 _matrix, address _add) public view returns(uint256, bool,uint256, uint256){
    require(0<= _matrix && _matrix <=2);
    uint256 currentId = maxtrix[_matrix].currentID[_add];
    bool isReceive = maxtrix[_matrix].isReceive[_add];
    uint256 cycle = maxtrix[_matrix].cycle[_add];
    uint256 receive = maxtrix[_matrix].receive[_add];
    return (currentId, isReceive, cycle, receive);
  }

  function getMaxtrixData(uint8 _matrix) public view returns(uint256, uint256){
    return (maxtrix[_matrix].payID, maxtrix[_matrix].totalId);
  }

  function getTokenBouns(uint256 _value) private view returns(uint256){
    if(token.balanceOf(address(this)) == 0){
      return 0;
    }

    if(token.balanceOf(address(this)) >= _value){
      return _value;
    } else {
      return token.balanceOf(address(this));
    }
  }

  event NewMember(
    address members
  );

  event MaxOut(
    address indexed user,
    uint8 line
  );

  event Deposit(
    address indexed user,
    uint256 value
  );

  event DirectReference(
    address indexed sponsor,
    address member,
    uint256 value
  );

  event WithdrawToken(
    address indexed user,
    uint256 amount
  );
}