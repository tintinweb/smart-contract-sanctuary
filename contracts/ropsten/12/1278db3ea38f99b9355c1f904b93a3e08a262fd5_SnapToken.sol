/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

//ERC20 token std. interface
interface ERC20Interface{
    
    //functions
    function totalSupply() external view returns(uint256);//10000
    // function balanceOf(address tokenOwner) external view returns(uint256);//10
    // function allowance(address tokenOwner, address spender) external view returns(uint256);
    function transfer(address to, uint256 tokens) external returns(bool suceess);
    function approve(address spender, uint token) external returns(bool sucesss);//t/f
    function transferFrom(address from, address to, uint256 tokens) external returns(bool success);
    
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

//ERC20 token

contract SnapToken is ERC20Interface{
    
  string  public name;
  string  public symbol;
  uint256 TotalSupply;
  
  mapping(address => uint256) public BalanceOf;
  mapping(address => mapping(address => uint256)) public Allowance;
    
  constructor(){
      name        = "SNAP Token";
      symbol      = "STC";
      TotalSupply =10000;
      BalanceOf[msg.sender]=TotalSupply;
  }
  
  function transfer(address _to, uint256 _value) public override returns(bool sucesss){
      require(BalanceOf[msg.sender] >= _value, "please enter valid amount");
      BalanceOf[msg.sender] -= _value;
      BalanceOf[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
  }
  
  function approve(address _spender, uint256 _value) public override returns(bool sucesss){
      Allowance[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public override returns(bool success){
      require(_value <= BalanceOf[_from],"please enter valid amount");
      require(_value <= Allowance[_from][msg.sender],"please enter amount less than Allowance");
      Allowance[_from][msg.sender] -=_value;
      BalanceOf[_from] -= _value;
      BalanceOf[_to]   += _value;
      emit Transfer(_from, _to, _value);
      return true;
  }
  
  function totalSupply() public view override returns(uint256) {
      return TotalSupply - BalanceOf[address(0)]; //reduce from dead address => burned tokens
  } 

}