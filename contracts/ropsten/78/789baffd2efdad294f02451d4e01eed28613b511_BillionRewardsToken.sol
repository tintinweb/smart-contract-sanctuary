pragma solidity ^0.4.16;
contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract BillionRewardsToken is owned {
    string public constant name = &quot;BillionRewardsToken&quot;;
    string public constant symbol = &quot;BILREW&quot;;
    uint public constant decimals = 8;
    uint constant ONETOKEN = 10 ** uint(decimals);
    uint constant MILLION = 1000000; 
    uint public totalSupply;
    uint public Devs_Supply;
    uint public Bounty_Supply;
    bool public Dev_TokenReleased = false;                     
    uint public Token_ExchangeValue;                             
    bool public Accept_Payment;
    bool public Token_Unlocked = false;
    uint public Eth_Collected;
    uint public Sold_Token;
    address public etherWallet = 0x90C5Daf1Ca815aF29b3a79f72565D02bdB706126;
    constructor() public {
        Token_ExchangeValue = 1999995 * ONETOKEN;
        totalSupply = 550000 * MILLION * ONETOKEN;                        
        Devs_Supply = 10000 * MILLION * ONETOKEN;                       
        Bounty_Supply = 40000 * MILLION * ONETOKEN;               
        totalSupply -= Devs_Supply + Bounty_Supply; 
        balanceOf[msg.sender] = totalSupply;                            
    }
    
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public selfdrop_cap;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    modifier notLocked{
        require(Token_Unlocked == true || msg.sender == owner);
        _;
    }
    modifier buyingToken{
        require(Accept_Payment == true);
        require(msg.sender != owner);
        require(selfdrop_cap[msg.sender] + msg.value <= .1 ether);
        _;
    }
    function unlockDevSupply() onlyOwner public {
        require(now > 1609459200);                              
        require(Dev_TokenReleased == false);       
        balanceOf[owner] += Devs_Supply;
        totalSupply += Devs_Supply;          
        emit Transfer(0, this, Devs_Supply);
        emit Transfer(this, owner, Devs_Supply);
        Devs_Supply = 0;                                         
        Dev_TokenReleased = true; 
    }
    function use_bounty_token(address target, uint256 reward) onlyOwner public {
        require(Bounty_Supply >= reward);
        balanceOf[target] += reward;
        totalSupply += reward;
        emit Transfer(0, this, reward);
        emit Transfer(this, target, reward);
        Bounty_Supply -= reward;
    }
    function mint(address target, uint256 token) onlyOwner public {
        balanceOf[target] += token;
        totalSupply += token;
        emit Transfer(0, this, token);
        emit Transfer(this, target, token);
    }
    function _transferToken(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) notLocked public {
        _transferToken(msg.sender, _to, _value);
    }
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                 
        emit Burn(msg.sender, _value);
        return true;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value); 
        require (balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    function() payable buyingToken public {
        require(msg.value > 0 ether);
        uint sendToken = (msg.value / .01 ether) * Token_ExchangeValue;
        selfdrop_cap[msg.sender] += msg.value;
        _transfer(owner, msg.sender, sendToken);
        uint returnBonus = computeReturnBonus(msg.value);
        if(returnBonus != 0)
        {
            msg.sender.transfer(returnBonus);
        }
        //etherWallet.transfer(this.balance);
        Eth_Collected += msg.value - returnBonus;
        Sold_Token += sendToken;          
    }
    function computeReturnBonus(uint256 amount) internal constant returns (uint256) {
        uint256 bonus = 0;
        if(amount >= .01 ether && amount < .025 ether)
        {
            bonus = (amount * 10) / 100;
        }
        else if(amount >= .025 ether && amount < .05 ether)
        {
            bonus = (amount * 25) / 100;
        }
        else  if(amount >= .05 ether && amount < .1 ether)
        {
            bonus = (amount * 50) / 100;
        }
        else if (amount >= .1 ether)
        {
            bonus = (amount * 70) / 100;
        }
        return bonus;
    }
    function withdrawEth() onlyOwner public{
        owner.transfer(this.balance);
    }
    
    function setAcceptPayment(bool status) onlyOwner public {
        Accept_Payment = status;
    }
    function setTokenTransfer(bool status) onlyOwner public {
        Token_Unlocked = status;
    }
    
}