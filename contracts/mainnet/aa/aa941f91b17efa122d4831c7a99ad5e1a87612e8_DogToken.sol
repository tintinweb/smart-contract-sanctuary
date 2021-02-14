/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity 0.4.24;

contract DogToken {
    //Test LifeCoin
    string public name;
    //token TLC
    string public symbol;
    //token 18
    uint public decimals;

    //转账事件通知
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 创建一个数组存放所有用户的余额
    mapping(address => uint256) public balanceOf;


    /* Constructor */
    constructor (uint256 initialSupply,string tokenName, string tokenSymbol, uint8 decimalUnits) public {
        //初始发币金额(总额要去除小数位数设置的长度)
        balanceOf[msg.sender] = initialSupply;
        name = tokenName;                                 
        symbol = tokenSymbol;                               
        decimals = decimalUnits; 
    }

    //转账操作
    function transfer(address _to,uint256 _value) public {
        //检查转账是否满足条件 1.转出账户余额是否充足 2.转出金额是否大于0 并且是否超出限制
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        //转账通知
        emit Transfer(msg.sender, _to, _value);
    }

}