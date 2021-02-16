/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity >= 0.7.0 <0.8.0;

contract testToken {
    string public constant name = "PayableToken";
    string public constant symbol = "SPT";
    uint8 public constant decimals = 0;
    
    address payable _owner;
    address _this;
    uint256 _totalSupply = 10000;
    uint256 _ethToken = 10;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) approvals;
    
    constructor() {
        _owner = msg.sender;
        _this = address(this);
        balances[_this] = _totalSupply;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can do this!");
        _;
    }
    
    function withdrawCash() public onlyOwner {
        _owner.transfer(address(this).balance);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return approvals[tokenOwner][spender];
    }
    
    function transfer(address to, uint amount) public returns (bool) {
        if(balances[msg.sender] < amount) {
            emit LogMessage("Not enough tokens!");
            return false;
        } else {
            balances[msg.sender] -= amount;
            balances[to] += amount;
            Transfer(msg.sender, to, amount);
            return true;
        }
    }
    
    function buyTokens() public payable returns (bool) {
        uint256 _weiToken = 1000000000000000000 / _ethToken;
        if(msg.value < _weiToken) {
            LogMessage("Not enough ether to buy 1 token!");
            msg.sender.transfer(msg.value);
            return false;
        }
        
        uint256 tokenAmount = msg.value / _weiToken;
        if(balances[_this] < tokenAmount) {
            LogMessage("Not enough tokens to sell!");
            msg.sender.transfer(msg.value);
            return false;
        }
        balances[msg.sender] += tokenAmount;
        balances[_this] -= tokenAmount;
        Transfer(_this, msg.sender, tokenAmount);
        msg.sender.transfer(msg.value - (tokenAmount * _weiToken));
        return true;
    }
    
    function setEthToken(uint256 value) public onlyOwner {
        _ethToken = value;
    }
    
    function tokensLeft() public view returns (uint) {
        return balances[_this];
    }
    
    function ethToken() public view returns (uint256) {
        return _ethToken;
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        approvals[msg.sender][spender] += amount;
        Approval(msg.sender, spender, amount);
        return true;
    }
    
    function remove() onlyOwner public {
        selfdestruct(_owner);
    }
    
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        if(balances[from] < amount || approvals[from][to] < amount) {
            LogMessage("Not enough tokens or current amount of tokens not approval by owner!");
            return false;
        } else {
            balances[from] -= amount;
            balances[to] += amount;
            approvals[from][to] -= amount;
            Transfer(from, to, amount);
            return true;
        }
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _amount);
    event Approval(address indexed _owner, address indexed _spender, uint _amount);
    event LogMessage(string message);
}