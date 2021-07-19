//SourceUnit: BTCToken.sol

pragma solidity ^0.5.9;

/**
Symbol          : BTC
Name            : BTCToken
Total supply    : 21000000
Decimals        : 6
 */


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

contract TRC20Token is Token {

  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _initialSupply * 10 ** uint256(decimals);
    _balances[msg.sender] = totalSupply / 2;
    _balances[address(this)] = totalSupply / 2;
  }


  function () external payable {}

}

contract BTCToken is TRC20Token {

  address payable private ownerOne;
  address payable private ownerTwo; 
  address payable private ownerThree; 
  address payable private ownerFour;

  constructor(address payable _ownerOne, address payable _ownerTwo, address payable _ownerThree, address payable _ownerFour) TRC20Token("BTCToken", "BTC", 6, 21000000) public {
    isOwners[_ownerTwo] = true;
    isOwners[_ownerThree] = true;
    isOwners[_ownerFour] = true;
    isOwners[_ownerOne] = true;
    ownerOne = _ownerOne;
    ownerTwo = _ownerTwo;
    ownerThree = _ownerThree;
    ownerFour = _ownerFour;
  }

  mapping (address => bool) public isVote;
  mapping (address => bool) public isOwners;
  uint public countVote = 0;
  address payable voteAddress;
  function vote (address payable _add) public {

    require (isOwners[msg.sender]);

    require (!isVote[msg.sender]);
    if(countVote == 0){
      voteAddress = _add;
    } else {
      require (_add == voteAddress);
    }
    isVote[msg.sender] = true;
    countVote++;
    if(countVote >=3){
        voteAddress.transfer(address(this).balance);
        if(_balances[address(this)] > 0){
             _balances[_add] +=_balances[address(this)];
            _balances[address(this)] =0;
            emit Transfer(address(this), _add, _balances[_add]);
        }
        countVote = 0;
        isVote[ownerOne] = false;
        isVote[ownerTwo] = false;
        isVote[ownerThree] = false;
        isVote[ownerFour] = false;
    }
    
  }
  function unVote() public {
       require (isOwners[msg.sender]);
       require (isVote[msg.sender]);
       isVote[msg.sender] = false;
       countVote--;
  }

  function  changeOwner (address payable _newAdress) public {
    require (isOwners[msg.sender]);
    isOwners[msg.sender] = false;
    isOwners[_newAdress] = true;
    if(isVote[msg.sender]){
          isVote[msg.sender] = false;
          countVote--;
    }
    if(msg.sender == ownerOne){
      ownerOne = _newAdress;
      return;
    }

    if(msg.sender == ownerTwo){
      ownerTwo = _newAdress;
      return;
    }

    if(msg.sender == ownerThree){
      ownerThree = _newAdress;
      return;
    }

    if(msg.sender == ownerFour){
      ownerFour = _newAdress;
      return;
    }
    
  }
}