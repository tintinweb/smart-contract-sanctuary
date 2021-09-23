/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity ^0.4.20;

contract ERC20Interface {

  string public name;           //返回string类型的ERC20代币的名字
  string public symbol;         //返回string类型的ERC20代币的符号，也就是代币的简称，例如：SNT。
  uint8 public  decimals;       //支持几位小数点后几位。如果设置为3。也就是支持0.001表示
  uint public totalSupply;      //发行代币的总量  

  //调用transfer函数将自己的token转账给_to地址，_value为转账个数
  function transfer(address _to, uint256 _value) public returns (bool success);

  //与下面approve函数搭配使用，approve批准之后，调用transferFrom函数来转移token。
  function transferFrom(address _from, address _to, uint256 _value)public returns (bool success);

  //批准_spender账户从自己的账户转移_value个token。可以分多次转移。
  function approve(address _spender, uint256 _value)public returns (bool success);

  //返回_spender还能提取token的个数。
  function allowance(address _owner, address _spender)public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ERC20 is ERC20Interface{

    mapping(address => uint256) public balanceOf;//余额 
    mapping(address =>mapping(address => uint256)) allowed;

    constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply) public{
         name = _name;                          //返回string类型的ERC20代币的名字
         symbol = _symbol;                      //返回string类型的ERC20代币的符号，也就是代币的简称，例如：SNT。
         decimals = _decimals;                   //支持几位小数点后几位。如果设置为3。也就是支持0.001表示
         totalSupply = _totalSupply *  10 ** uint( _decimals);            //发行代币的总量  

         balanceOf[msg.sender]=totalSupply;
    }
    


   //调用transfer函数将自己的token转账给_to地址，_value为转账个数
  function transfer(address _to, uint256 _value) public returns (bool success){
      require(_to!=address(0));//检测目标帐号不等于空帐号 
      require(balanceOf[msg.sender] >= _value);
      require(balanceOf[_to] + _value >=balanceOf[_to]);

      balanceOf[msg.sender]-=_value;
      balanceOf[_to]+=_value;

      emit Transfer(msg.sender,_to,_value);//触发事件

      return true;
  }

  //与下面approve函数搭配使用，approve批准之后，调用transferFrom函数来转移token。
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

      require(_to!=address(0));
      require(balanceOf[_from]>=_value);
      require(balanceOf[_to]+_value>balanceOf[_to]);
      require(allowed[_from][msg.sender]>_value);

      balanceOf[_from]-=_value;
      balanceOf[_to]+=_value;
      allowed[_from][msg.sender]-=_value;

      emit Transfer(_from,_to,_value);

      return true;

  }

  //批准_spender账户从自己的账户转移_value个token。可以分多次转移。
  function approve(address _spender, uint256 _value) public returns (bool success){

      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender,_spender,_value);
      return true;
  }

  //返回_spender还能提取token的个数。
  function allowance(address _owner, address _spender) public view returns (uint256 remaining){
      return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}