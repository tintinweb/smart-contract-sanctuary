pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
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
contract ERNToken is owned {
    using SafeMath for uint256;
    string public constant name = "ERNToken";
    string public constant symbol = "ERN";
    uint public constant decimals = 8;
    uint constant ONETOKEN = 10 ** uint256(decimals);
    uint constant MILLION = 1000000; 
    uint public constant Total_TokenSupply = 1000 * MILLION * ONETOKEN; //1B Final Token Supply
    uint public totalSupply;
    uint public Dev_Supply;
    uint public GrowthPool_Supply;
    uint public Rewards_Supply;                                //to be added 45% Rewards 
    bool public DevSupply_Released = false;                     //Locked 3% Dev Supply
    bool public GrowthPool_Released = false;                    //Locked 2% Growth Pool Supply
    bool public ICO_Finished = false;                           //ICO Status
    uint public ICO_Tier = 0;                                   //ICO Tier (1,2,3,4)
    uint public ICO_Supply = 0;                                 //ICO Supply will change per Tier
    uint public ICO_TokenValue = 0;                             //Token Value will change per ICO Tier
    bool public ICO_AllowPayment;                               //Control Ether Payment when ICO is On
    bool public Token_AllowTransfer = false;                    //Locked Token Holder for transferring ERN
    uint public Collected_Ether;
    uint public Total_SoldToken;
    uint public Total_ICOSupply;
    address public etherWallet = 0x90C5Daf1Ca815aF29b3a79f72565D02bdB706126;
    
    constructor() public {
        totalSupply = 1000 * MILLION * ONETOKEN;                        //1 Billion Total Supply
        Dev_Supply = totalSupply.mul(3).div(100);                       //3% of Supply -> locked until 01/01/2020
        GrowthPool_Supply = totalSupply.mul(2).div(100);                //2% of Supply -> locked until 01/01/2019
        Rewards_Supply = totalSupply.mul(45).div(100);                  //45% of Supply -> use for rewards, bounty, mining, etc
        totalSupply -= Dev_Supply + GrowthPool_Supply + Rewards_Supply; //50% less for initial token supply 
        Total_ICOSupply = totalSupply;                                  //500M ICO supply
        balanceOf[msg.sender] = totalSupply;                            
    }
    
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public whitelist;
    mapping (address => uint256) public PrivateSale_Cap;
    mapping (address => uint256) public PreIco_Cap;
    mapping (address => uint256) public MainIco_Cap;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Whitelisted(address indexed target, bool whitelist);
    event IcoFinished(bool finish);
    
    modifier notLocked{
        require(Token_AllowTransfer == true || msg.sender == owner);
        _;
    }
    modifier buyingToken{
        require(ICO_AllowPayment == true);
        require(msg.sender != owner);
        
        if(ICO_Tier == 1)
        {
            require(whitelist[msg.sender]);
        }
        if(ICO_Tier == 2)                                       
        {
            require(whitelist[msg.sender]);
            require(PrivateSale_Cap[msg.sender] + msg.value <= 5 ether); //private sale -> 5 Eth Limit
        }
        if(ICO_Tier == 3)                                       
        {
            require(whitelist[msg.sender]);
            require(PreIco_Cap[msg.sender] + msg.value <= 15 ether);    //pre-ico -> 15 Eth Limit
        }
        if(ICO_Tier == 4)                                       
        {
            require(whitelist[msg.sender]);
            require(MainIco_Cap[msg.sender] + msg.value <= 15 ether);   //main-ico -> 15 Eth Limit
        }
        _;
    }
    function unlockDevTokenSupply() onlyOwner public {
        require(now > 1577836800);                              //can be unlocked only on 1/1/2020
        require(DevSupply_Released == false);       
        balanceOf[owner] += Dev_Supply;
        totalSupply += Dev_Supply;          
        emit Transfer(0, this, Dev_Supply);
        emit Transfer(this, owner, Dev_Supply);
        Dev_Supply = 0;                                         //clear dev supply -> 0
        DevSupply_Released = true;                              //to avoid next execution
    }
    function unlockGrowthPoolTokenSupply() onlyOwner public {
        require(now > 1546300800);                              //can be unlocked only on 1/1/2019
        require(GrowthPool_Released == false);      
        balanceOf[owner] += GrowthPool_Supply;
        totalSupply += GrowthPool_Supply;
        emit Transfer(0, this, GrowthPool_Supply);
        emit Transfer(this, owner, GrowthPool_Supply);
        GrowthPool_Supply = 0;                                  //clear growthpool supply -> 0
        GrowthPool_Released = true;                             //to avoid next execution
    }
    function sendUnsoldTokenToRewardSupply() onlyOwner public {
        require(ICO_Finished == true);    
        uint totalUnsold = Total_ICOSupply - Total_SoldToken;   //get total unsold token on ICO
        Rewards_Supply += totalUnsold;                          //add to rewards / mineable supply
        Total_SoldToken += totalUnsold;
    }
    function giveReward(address target, uint256 reward) onlyOwner public {
        require(Rewards_Supply >= reward);
        balanceOf[target] += reward;
        totalSupply += reward;
        emit Transfer(0, this, reward);
        emit Transfer(this, target, reward);
        Rewards_Supply -= reward;
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
        uint totalToken = (msg.value.mul(ICO_TokenValue)).div(10 ** 18);
        totalToken = totalToken.mul(ONETOKEN);
        require(ICO_Supply >= totalToken);
        if(ICO_Tier == 2)
        {
            PrivateSale_Cap[msg.sender] += msg.value;
        }
        if(ICO_Tier == 3)
        {
            PreIco_Cap[msg.sender] += msg.value;
        }
        if(ICO_Tier == 4)
        {
            MainIco_Cap[msg.sender] += msg.value;
        }
        ICO_Supply -= totalToken;
        _transfer(owner, msg.sender, totalToken);
        uint256 sendBonus = icoReturnBonus(msg.value);
        if(sendBonus != 0)
        {
            msg.sender.transfer(sendBonus);
        }
        etherWallet.transfer(this.balance);
        Collected_Ether += msg.value - sendBonus;               //divide 18 decimals
        Total_SoldToken += totalToken;                          //divide 8 decimals
    }
    function icoReturnBonus(uint256 amount) internal constant returns (uint256) {
        uint256 bonus = 0;
        if(ICO_Tier == 1)
        {
            bonus = amount.mul(15).div(100);
        }
        if(ICO_Tier == 2)
        {
            bonus = amount.mul(12).div(100);
        }
        if(ICO_Tier == 3)
        {
            bonus = amount.mul(10).div(100);
        }
        if(ICO_Tier == 4)
        {
            bonus = amount.mul(8).div(100);
        }
        return bonus;
    }
    function withdrawEther() onlyOwner public{
        owner.transfer(this.balance);
    }
    function setIcoTier(uint256 newTokenValue) onlyOwner public {
        require(ICO_Finished == false && ICO_Tier < 4);
        ICO_Tier += 1;
        ICO_AllowPayment = true;
        ICO_TokenValue = newTokenValue;
        if(ICO_Tier == 1){
            ICO_Supply = 62500000 * ONETOKEN;               //62.5M supply -> x private sale 
        }
        if(ICO_Tier == 2){
            ICO_Supply = 100 * MILLION * ONETOKEN;          //100M supply -> private sale
        }
        if(ICO_Tier == 3){
            ICO_Supply = 150 * MILLION * ONETOKEN;          //150M supply -> pre-ico
        }
        if(ICO_Tier == 4){
            ICO_Supply = 187500000 * ONETOKEN;              //187.5M supply -> main-ico
        }
    }
    function FinishIco() onlyOwner public {
        require(ICO_Tier >= 4);
        ICO_Supply = 0;
        ICO_Tier = 0;
        ICO_TokenValue = 0;
        ICO_Finished = true;
        ICO_AllowPayment = false;
        emit IcoFinished(true);
    }
    function setWhitelistAddress(address addr, bool status) onlyOwner public {
        whitelist[addr] = status;
        emit Whitelisted(addr, status);
    }
    function setIcoPaymentStatus(bool status) onlyOwner public {
        require(ICO_Finished == false);
        ICO_AllowPayment = status;
    }
    function setTokenTransferStatus(bool status) onlyOwner public {
        require(ICO_Finished == true);
        Token_AllowTransfer = status;
    }
    
}