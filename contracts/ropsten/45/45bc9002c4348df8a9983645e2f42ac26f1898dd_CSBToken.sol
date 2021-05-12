/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.4.25;

contract ERC20Interface {

    string public constant name = "测试币";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 18;
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    function totalSupply() public constant returns (uint);
    //获取账tokenOwner拥有token的数量 
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    //从消息发送者账户中往_to账户转数量为_value的token（就是从创建合约账户往to账户转数量tokens的token）
    function transfer(address to, uint tokens) public returns (bool success);
    //消息发送账户设置账户spender能从发送账户中转出数量为tokens的token
    function approve(address spender, uint tokens) public returns (bool success);
    //从账户from中往账户to转数量为tokens的token，与approve方法配合使用
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    //发生转账时必须要触发的事件（执行转账后将最新数据实时刷新给前端） 
    event Transfer(address indexed from, address indexed to, uint tokens);
    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件（执行转账后将最新数据实时刷新给前端）
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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


contract CSBToken is ERC20Interface, SafeMath {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowanceOf;

   constructor(string _tokenName,string _tokenSymbol,uint8 _tokenDecimals,uint256 _tokenTotalSupply) public payable {
      name = _tokenName;// token名称
      symbol = _tokenSymbol;// token简称
      decimals = _tokenDecimals;// 小数位数
      totalSupply = _tokenTotalSupply * 10 ** uint256(decimals);// 设置初始总量
      balanceOf[msg.sender] = totalSupply;// 初始token数量给予消息发送者
   }

    function _transfer(address _from, address _to, uint _value) internal {
       require(_to != 0x0);
       require(balanceOf[_from] >= _value);
       require(balanceOf[_to] + _value > balanceOf[_to]);
       uint previousBalances = balanceOf[_from] + balanceOf[_to];
       balanceOf[_from] -= _value;//从_from账户中减去token数量_value
       balanceOf[_to] += _value;//往接收账户增加token数量_value
       assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
       emit Transfer(_from, _to, _value);//打印日志
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
       _transfer(msg.sender, _to, _value);
       return true;
   }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(allowanceOf[_from][msg.sender] >= _value);
       allowanceOf[_from][msg.sender] -= _value;
       _transfer(_from, _to, _value);
       return true;
   }

    function approve(address _spender, uint256 _value) public returns (bool success) {
       allowanceOf[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
       return true;
   }

   function allowance(address _owner, address _spender) view public returns (uint remaining){
     return allowanceOf[_owner][_spender];
   }

  function totalSupply() public constant returns (uint totalsupply){
      return totalSupply;
  }

  function balanceOf(address tokenOwner) public constant returns(uint balance){
      return balanceOf[tokenOwner];
  }

}