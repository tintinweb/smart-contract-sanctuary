/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.16;
interface TokenRecipient{
    function receiveApproval(address _from,uint256 _value,address _token,bytes _extraData) public;
}
//声明

contract TokenErc20{
    string public name;//名字
    string public symbol;//符号
    uint8 public decimals = 8;//小数
    uint256 public totalSupply;//总量
    mapping(address => uint256) public balanceOf;//地址对应余额
    mapping(address => mapping(address => uint256)) public allowance;//地址对应限额
    
    event transfer(address indexed from,address indexed to,uint256 value);//交易事件记录在区块上
    event burn(address indexed from,uint256 value);//燃烧事件记录在区块上
    //传入参数初始总量,代币名称,代币符号.
    function TokenErc20(uint256 initialSupply,string tokenName,string tokenSymbol) public{
        totalSupply = initialSupply * 10 ** uint256(decimals);
        //总量等于初始总量*10 **小数的次方
        balanceOf[msg.sender] = totalSupply;
        //调用者地址地址为总量
        name = tokenName;
        
        symbol = tokenSymbol;
    }
    //交易函数
    function _transfer(address _from, address _to, uint _value) internal{
        require(_to != 0x0);
        //判断目标地址不等于0
        require(balanceOf[_from] >= _value);
        //判断发送地址的金额大于等于发送金额
        require(balanceOf[_to] + _value > balanceOf[_to]);
        //判断目标地址的金额+发送金额大于目标地址的原始金额
        uint priviousBalances = balanceOf[_from] + balanceOf[_to];
        //发送地址的金额+目标地址的金额赋值给以前的金额
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        transfer(_from,_to,_value);
        //发送地址扣除金额,目标地址加上金额,交易.
        assert(balanceOf[_from] + balanceOf[_to] ==priviousBalances);
        //检查发送地址+目标地址的金额是否等于原金额
    }
    //判断交易函数是否为真
    function transfer1(address _to, uint256 _value) public returns(bool){
        _transfer(msg.sender, _to, _value);//调用交易函数,感觉是多余的
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        //传送金额需要小于等于
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender,uint256 _value)public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function approveAnd(address _spender, uint256 _value, bytes _extraData)public returns(bool success){
        TokenRecipient spender = TokenRecipient(_spender);
        if(approve(_spender, _value)){
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn1(uint256 _value) public returns(bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value)public returns(bool success){
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        burn(_from, _value);
        return true;
    }
}