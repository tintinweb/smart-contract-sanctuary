pragma solidity 0.4.19;

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

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract ARITokenAbstract {
    function unlock();
}

contract ARICrowdsale {
    using SafeMath for uint256;
    address owner = msg.sender;

    bool public purchasingAllowed = false;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalContribution = 0;
    uint256 public totalBonusTokensIssued = 0;
    uint    public MINfinney    = 0;
    uint    public MAXfinney    = 100000;
    uint    public AIRDROPBounce    = 1200;
    uint    public ICORatio     = 1440000;
    uint256 public totalSupply = 0;

    address constant public ARI = 0xf8b7b391b7b7330d07a931a332a6620ca1a9f7f2;

    address public ARIWallet = 0x6346D35ceDd5b19c94EB1AbE9b5fbCAd7d95dAad;

    uint256 public rate = ICORatio;

    uint256 public weiRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
        if (!purchasingAllowed) { throw; }
        
        if (msg.value < 1 finney * MINfinney) { return; }
        if (msg.value > 1 finney * MAXfinney) { return; }

    uint256 ARIAmounts = calculateObtained(msg.value);

    weiRaised = weiRaised.add(msg.value);

        require(ERC20Basic(ARI).transfer(beneficiary, ARIAmounts));
        TokenPurchase(msg.sender, beneficiary, msg.value, ARIAmounts);
        forwardFunds();
    }

    function forwardFunds() internal {
        ARIWallet.transfer(msg.value);
    }

    function calculateObtained(uint256 amountEtherInWei) public view returns (uint256) {
        return amountEtherInWei.mul(ICORatio).div(10 ** 6) + AIRDROPBounce * 10 ** 6;
    } 

    function enablePurchasing() {
        if (msg.sender != owner) { throw; }
        purchasingAllowed = true;
    }

    function disablePurchasing() {
        if (msg.sender != owner) { throw; }
        purchasingAllowed = false;
    }

    function changeARIWallet(address _ARIWallet) public returns (bool) {
        require (msg.sender == ARIWallet);
        ARIWallet = _ARIWallet;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       assert(b <= a);
       return a - b;
    }

    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if(msg.data.length < (2 * 32) + 4) { throw; }
        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];
        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) { throw; }
        if (_value == 0) { return false; }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);

    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != owner) { throw; }

        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getStats() constant returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
    }

    function setICOPrice(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        ICORatio = _newPrice;
    }

    function setMINfinney(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        MINfinney = _newPrice;
    }

    function setMAXfinney(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        MAXfinney = _newPrice;
    }

    function setAIRDROPBounce(uint _newPrice)  {
        if (msg.sender != owner) { throw; }
        AIRDROPBounce = _newPrice;
    }

    function withdraw() public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
    }
}