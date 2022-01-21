/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

pragma solidity ^0.4.25;
library SafeMath {
   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { 
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b); 
        return c;
    } 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {     
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a); 
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
interface IERC20{
      function totalSupply() external view returns(uint256);//查询token总数量
      function balanceof(address tokenOwner)external view returns(uint256 balance);//查询address=>token数量
      function addowance(address tokenOwenr,address spender)external view returns(uint256 remaining);//查询tokenOwenr=>spender授权使用剩余的token数量
      function approve(address spender,uint tokens) external returns(bool rema);//msg.sender授权给spender=>token数量
      function transfer(address to,uint256 tokens)external returns(bool success);//从msg.sender=>token数量给to
      function transefrFrom(address from,address to,uint256 tokens)external returns(bool success);//mas.sender将from给自己授权的token转给to
      event Transfer(address indexed from,address indexed to, uint256 tokens);
      event Approval(address indexed owner,address indexed spender, uint256 tokens);
}
contract Erc20 is IERC20{
using SafeMath for uint256;
  //_balance[msg.sender].sub(tokens)=SafeMath.sub(_balance[msg.sender],tokens)
 string public constant name="hello token";
 uint8 public constant decimals=18;
 string public constant symbol="HHT";
 uint256 internal _totalSupply;//token数量
 address owner;
  mapping(address=>uint256) _balance;//记录address数量
  mapping(address=>mapping(address=>uint256)) _approve;//记录授权信息



 event Transfer(address indexed from,address indexed to, uint256 tokens);
  event Approval(address indexed owner,address indexed spender, uint256 tokens);

constructor() public{
  owner=msg.sender;
  _balance[owner]=10000;
  emit Transfer( address(0),owner,10000);
}

  //查询所有token数量
  function totalSupply() public view returns(uint256){
      return _totalSupply;
  }
  //查询address=>uint256数量
  function balanceof(address tokenOwner)public view returns(uint256 balance){
      return _balance[tokenOwner];
  }
  //从msg.sender转token给to
  function transfer(address to,uint256 tokens)public returns(bool success){
      _balance[msg.sender]=SafeMath.sub(_balance[msg.sender],tokens);
      _balance[to]=SafeMath.add(_balance[to],tokens);


      return true;
  }
  //msg.sender授权某一个地址可以使用自己的token数量
  function approve(address spender,uint tokens) public returns(bool rema){
      _approve[msg.sender][spender]=tokens;
      emit Approval(msg.sender,spender,tokens);
       return true;
  }
  //查询tokenOwenr授权给spender的tokens还剩多少
  function addowance(address tokenOwenr,address spender)public view returns(uint256 remaining){
      return  _approve[tokenOwenr][spender];
  }
  function transefrFrom(address from,address to,uint256 tokens)external returns(bool success){
      _approve[from][msg.sender]= _approve[from][msg.sender].sub(tokens);
      _balance[from]=_balance[from].sub(tokens);
      _balance[to]= _balance[to].add(tokens);
      emit Transfer(from,to,tokens);
      return true;
  }
  

}