/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.4.17;

contract simpletokenstruct{
    
    string public name;  //代币名称
    string public simple;  //代币代号
    uint8 public decimals;  //代币小数点位位数
    uint256 public totalSupply;  //代币总发行量
    
    
    function balanceOf(address _owner) public view returns (uint256 balance){   //查看_owner账户的余额，返回余额
        
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){   //给_to地址转账_value，返回操作是否成功
        
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
           //从_from地址给_to地址转账_value，返回操作是否成功
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
          //允许_spender地址来操作_value大小的余额
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
          //用来查询_owner允许_spender使用多少个代币
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //定义了一个事件，暂时不管
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //定义了一个事件，这里暂时不管
    
}

contract simpletoken is simpletokenstruct{
    
    constructor() public{
        name='Tether USD';  //名字为choboco
        simple='USDT';   //代号为GIL
        decimals=19;    //最多一位小数
        totalSupply=10000000;  //总发行量1000
        balanceOf[msg.sender]=totalSupply;  //发布时，发布者拥有所有代币
    }
   
    mapping(address=>uint256) public balanceOf;  //将地址映射为uint，代表账户余额
    mapping(address=>mapping(address=>uint256)) internal approvemapping;
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        
        require(_to != address(0));  //地址不为空
        require(balanceOf[msg.sender]>=_value);  //转账账户余额充足
        require(balanceOf[_to]+_value>=balanceOf[_to]);  //检测是否溢出
        
        balanceOf[msg.sender]-=_value;  //发送者减去数额
        balanceOf[_to]+=_value;  //接受者增加数额
        
        emit Transfer(msg.sender,_to,_value);  //暂时不管
        success = true;
        
    }
    
    
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        
        require(_to != address(0));//地址不为空
        require(balanceOf[_from]>=_value);//转账账户余额充足
        require(approvemapping[_from][msg.sender]>=_value); //这里检测委托人的可操作的金额是否转账金额
        require(balanceOf[_to]+_value>=balanceOf[_to]); //检测是否溢出
        
        balanceOf[_from]-=_value;//发送者减去数额
        balanceOf[_to]+=_value;//接受者增加数额
        
        success = true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        approvemapping[msg.sender][_spender]=_value;  //映射可操作的代币，由调用者（msg.sender）指定_spender操作_value数额的代币
        emit Approval(msg.sender,_spender,_value);  //暂时不管
        success = true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return approvemapping[_owner][_spender];   //查看剩余能调用多少代币
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //暂时不管
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);  //暂时不管
    
}