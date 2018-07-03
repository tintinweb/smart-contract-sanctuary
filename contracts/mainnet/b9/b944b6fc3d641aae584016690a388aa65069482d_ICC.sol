pragma solidity ^0.4.20;

contract ICCTOKEN
{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ICC is ICCTOKEN
{

  mapping (address => uint256) public balanceOf;

  mapping (address => mapping (address => uint256)) internal allowed;

  //init
  constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply) public
  {
     name = _name;
     symbol = _symbol;
     decimals = _decimals;
     totalSupply = _totalSupply;
     balanceOf[msg.sender] = _totalSupply;
  }
  
  function transfer(address _to, uint256 _value) public returns (bool success)
  {
      require(_to != address(0));
      require(balanceOf[msg.sender] >= _value);
      require(balanceOf[_to] + _value >= balanceOf[_to]);


      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;

      emit Transfer(msg.sender,_to,_value);
      
      success = true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
  {
      require(_to != address(0));
      require(balanceOf[_from] >= _value);
      require(allowed[_from][msg.sender] >= _value);
      require(balanceOf[_to] + _value >= balanceOf[_to]);

      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;

      emit Transfer(_from,_to,_value);
      
      success = true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success)
  {
     allowed[msg.sender][_spender] = _value;

     emit Approval(msg.sender,_spender,_value);


     success = true;
  }

  function allowance(address _owner, address _spender) public returns (uint256 remaining)
  {
     return allowed[_owner][_spender];
  }

}