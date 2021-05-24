/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.4.16 <0.9.0;


abstract contract Token{

    //token的总量
    uint256 public totalSupply;

    //_owner拥有的数量
    function balanceOf(address _owner) public view virtual returns(uint256 balance);

    //从发送者owner前往to的数量
    function allowance(address _owner,address _spender) virtual public view returns(uint256 remaining);

    //从from前往yo的数量，配合approve使用
    function transfer(address _to,uint256 _value) virtual public returns(bool success);

    //消息发送账户设置_spender能从发送账户转出的数量
    function approve(address _spender,uint256 value) virtual public returns(bool success);

    //获取_spender可以从owner转出的数量
    function transferFrom(address _from,address _to,uint256 _value) virtual public returns(bool sucess);

    //定义转账事件
    event Transfer(address indexed _from,address indexed _to,uint256 _value);

    //定义approve事件
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
}


contract StandardToken is Token{
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256))  allowed;
    //查询余额
    function balanceOf(address _owner) override public view returns(uint256 balance){
        return balances[_owner];
    }

    //允许_spender从_owner中转出的数量
    function allowance(address _owner,address _spender) override public view returns(uint256 remaining){
        return allowed[_owner][_spender];
    }

    function transfer(address _to,uint256 _value) override public returns (bool success){
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //授权账户_spender可以从消息发送者账户转出的数量
    function approve(address _spender,uint256 _value) override public returns(bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) override public returns(bool success){
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}


contract TestToken is StandardToken{
    string public name;
    uint8 public decimals;
    string public symbol;
    function testToken() public{
        balances[msg.sender] = 100000000;
        totalSupply = 10000000000;
        name = "testToken";
        decimals = 8;
        symbol = "robin";
    }
}