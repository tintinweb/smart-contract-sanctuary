/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Erc20Token {
    
    // 代币全称
    string public name;

    // 代币符号（简称）
    string public symbol;

    // 代币支持的小数位
    uint public decimals;

    // 代币总发行量
    uint256 public totalSupply;

    // 合约拥有者地址
    address owner;

    // 地址余额映射表
    mapping (address => uint256) public balanceOf;

    // 地址授权信息映射表
    mapping (address => mapping (address => uint256)) public allowance;

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed spender, uint256 value);
    
    
    /* 合约构造函数
     * 
     * @param _name         代币全称（名称）
     * @param _symbol       代币符号（简称）
     * @return _decimals    代币小数位
     * @return _totalSupply 代币总发行量
     */
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** _decimals;
        balanceOf[msg.sender] = totalSupply;
    }
    

    /* 转账内部逻辑处理
     * 
     * @param _from         转出地址
     * @param _to           转入地址
     * @param _value        交易金额
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /* 转账逻辑处理
     * 
     * @param _from         转出地址
     * @param _to           转入地址
     * @param _value        交易金额
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /* 代理转账逻辑处理
     * 
     * @param _from         授权处理的地址
     * @param _to           转入地址
     * @param _value        交易金额
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /* 授权逻辑处理
     * 
     * @param _spender         授权处理的地址
     * @param _value           授权处理的金额
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(_spender, _value);
        return true;
    }

}