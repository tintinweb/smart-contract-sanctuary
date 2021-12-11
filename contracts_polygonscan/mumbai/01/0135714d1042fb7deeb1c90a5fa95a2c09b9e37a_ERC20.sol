// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

import "./Owner.sol";
import "./ERC20Interface.sol";



contract ERC20 is ERC20Interface, Owner{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) public frozenAccount;
    
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);


    
    constructor() {
        symbol = "GY";
        name = "GRC";
        decimals = 18;
        _totalSupply = 100000000 * 10**uint256(decimals);
        balances[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint256 tokens) public returns (bool success) {

        // 检验是否为冻结账户 
        require(!frozenAccount[owner]);
        require(!frozenAccount[to]);

        // 检验接收者地址是否合法
        require(to != address(0));

        // 检验发送者账户余额是否足够
        require(balances[owner] >= tokens);

        // 检验是否会发生溢出
        require(balances[to] + tokens >= balances[to]);



        // 扣除发送者账户余额
        balances[owner] -= tokens;

        // 增加接收者账户余额
        balances[to] += tokens;



        // 触发相应的事件
        emit Transfer(owner, to, tokens);
        return true;

    }
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[owner][spender] = tokens;
        emit Approval(owner, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // 检验是否为冻结账户 
        require(!frozenAccount[from]);
        require(!frozenAccount[to]);
        
        // 检验地址是否合法
        require(to != address(0) && from != address(0));

        // 检验发送者账户余额是否足够
        require(balances[from] >= tokens);

        // 检验操作的金额是否是被允许的
        require(allowed[from][owner] <= tokens);

        // 检验是否会发生溢出
        require(balances[to] + tokens >= balances[to]);

        balances[from] -= tokens;
        allowed[from][owner] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    
    //代币增发
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }
    
    //管理者代币销毁
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balances[owner] >= _value);
        balances[owner] -= _value;
        _totalSupply -= _value;
        emit Burn(owner, _value);
        return true;
    }
    
    
    //用户代币销毁 
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][owner]);
        balances[_from] -= _value;
        allowed[_from][owner] -= _value;
        _totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    
    //冻结账户代币 
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    //空投代币 
    function AirDrop(address[] memory _recipients, uint _values) onlyOwner public returns (bool) {
        require(_recipients.length > 0);

        for(uint j = 0; j < _recipients.length; j++){
            emit Transfer(owner, _recipients[j], _values);
        }

        return true;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    //代币兑换 买 
    function buy() payable public {
        uint amount = msg.value / buyPrice;
        emit Transfer(address(this), owner, amount);
    }
    //代币兑换 卖 
    function sell(uint256 amount) public {
        require(address(this).balance >= amount * sellPrice);
        emit Transfer(owner, address(this), amount);
        //owner.transfer(amount * sellPrice);
    }

}