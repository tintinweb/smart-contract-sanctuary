pragma solidity ^0.4.26;
 
import './StandardToken.sol';
import './Manager.sol';
contract AdvanceToken is StandardToken,Manager{
    mapping(address => bool) public isfroze;//记录账户是否被冻结
    
    //构造函数，只需把参数传给StandardToken父合约，无需实现体
    constructor(string _name) StandardToken(_name) public{
       
    }
    
    //代币增发
    function addTotalSupply(uint _value) public IsManager returns(bool success) {
        require(totalSupply<=totalSupply+_value);//整数溢出校验
        totalSupply+=_value;
        balanceOf[msg.sender]+=_value;
        emit AdditionTotalSupply(_value);
        return true;
    }
    
    event AdditionTotalSupply(uint _value);//代币增发事件
 
    //代币销毁
    function subTotalSupply(uint _value) public IsManager returns(bool success) {
        require(totalSupply>=totalSupply-_value);
        totalSupply-=_value;
        balanceOf[msg.sender]-=_value;
        emit SubTotalSupply(_value);
        return true;
    }
    
    event SubTotalSupply(uint _value);//代币销毁事件
    
    //冻结函数，同样需要IsManager修饰，只有代笔管理者能操作
    function froze(address _account) IsManager public returns(bool success){
        isfroze[_account]=true;//记录此账户被冻结
        emit Frozen(_account);//触发冻结事件
        return true;
    }
    
     //重写转账函数 
   function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender]>=_value);//判断代币持有者余额要大于转账余额
        require(balanceOf[_to]<=balanceOf[_to]+_value);//溢出判断。
        require(isfroze[msg.sender]==false);//转账之前判断账户是否被冻结
        balanceOf[msg.sender]-=_value;//对代币持有者余额做减法
        balanceOf[_to]+=_value;//目标地址做加法
        emit Transfer(msg.sender,_to,_value);//触发事件
        return true;
  }
    
    //重写授权转账函数
   function transferFrom(address _from, address _to, uint256 _value)public returns (bool success){
        //判断转账人是否有足够余额
        require(balanceOf[_from]>=_value&&allowed[_from][msg.sender]>=_value);
        //整数溢出判断
        require(balanceOf[_to]<=balanceOf[_to]+_value);
        require(isfroze[_from]==false);//转账之前判断授权账户是否被冻结
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
        allowed[_from][msg.sender]-=_value;
        return true;
    }
    
    event Frozen(address _account);
}