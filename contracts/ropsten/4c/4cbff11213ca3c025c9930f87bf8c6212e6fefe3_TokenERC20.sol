/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.16;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) 
    external; }

contract TokenERC20 {
    string public name;      //定义代币名称的公共变量参数
    string public symbol;    //定义代币符号的公共变量参数
    uint8 public decimals;   //定义小数点后有多少位数的公共变量参数
    uint public totalSupply; //定义代币总发行量的公共变量参数
    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;  
    mapping (address => mapping (address => uint256)) public allowance;
    /* 在区块链上创建事件，用以跟踪信息*/
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);

    /* 根据ERC20标准初始化合约，并且把初始的所有代币都给这合约的创建者*/

    constructor() public {
        decimals = 18;
        name = "SixMonth";
        symbol = "SMH";
        totalSupply = 1000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    /*私有方法从一个帐户发送给另一个帐户代币*/
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);        //避免转帐的地址是0x0
        require(balanceOf[_from] >= _value);//检查发送者是否拥有足够余额
        require(balanceOf[_to] + _value > balanceOf[_to]);//检查是否溢出
        uint previousBalances = balanceOf[_from] + balanceOf[_to];//保存数据用于后面的判断
        balanceOf[_from] -= _value;//从发送者减掉发送额
        balanceOf[_to] += _value;//给接收者加上相同的量
        emit Transfer(_from, _to, _value);//通知任何监听该交易的客户端
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        //判断买、卖双方的数据是否和转换前一致
    }
    /*从主帐户合约调用者发送给别人代币*/
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    /*从某个指定的帐户中，向另一个帐户发送代币*/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    /*设置帐户允许支付的最大金额*/
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    /* 设置帐户允许支付的最大金额*/
    /* 一般在智能合约的时候，避免支付过多，造成风险，加入时间参数，可以在 tokenRecipient 中做其他操作*/

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /*减少代币调用者的余额*/
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    /*删除帐户的余额（含其他帐户）*/
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}