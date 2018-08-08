pragma solidity ^0.4.11;

contract CyberyTokenSale {
    address public owner;  
    bool public purchasingAllowed = false;
    uint256 public totalContribution = 0;
    uint256 public totalSupply = 0;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    function name() constant returns (string) { return "Cybery Token"; }
    function symbol() constant returns (string) { return "CYB"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { 
        return balances[_owner]; 
    }

    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Math operations with safety checks that throw on error
    //returns the difference of a minus b, asserts if the subtraction results in a negative number
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    //returns the sum of a and b, asserts if the calculation overflows
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function CyberyTokenSale() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // start sale
    function enablePurchasing() onlyOwner {
        purchasingAllowed = true;
    }

    // end sale
    function disablePurchasing() onlyOwner {
        purchasingAllowed = false;
    }

    // send coins
    // throws on any error rather then return a false flag to minimize user errors
    function transfer(address _to, uint256 _value) validAddress(_to) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // an account/contract attempts to get the coins
    // throws on any error rather then return a false flag to minimize user errors
    function transferFrom(address _from, address _to, uint256 _value) validAddress(_from) returns (bool success) {
        require(_to != 0x0);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    // allow another account/contract to spend some coins on your behalf
    // also, to minimize the risk of the approve/transferFrom attack vector,
    // approve has to be called twice in 2 separate transactions - 
    // once to change the allowance to 0 and secondly to change it to the new allowance value
    function approve(address _spender, uint256 _value) validAddress(_spender) returns (bool success) {
        // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // function to check the amount of tokens than an owner allowed to a spender.
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    // fallback function can be used to buy tokens
    function () payable validAddress(msg.sender) {
        require(msg.value > 0);
        assert(purchasingAllowed);
        owner.transfer(msg.value); // send ether to the fund collection wallet
        totalContribution = safeAdd(totalContribution, msg.value);
        uint256 tokensIssued = (msg.value * 100);  
        //if (msg.value >= 10 finney) { tokensIssued += totalContribution; }
        totalSupply = safeAdd(totalSupply, tokensIssued);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokensIssued);
        balances[owner] = safeAdd(balances[owner], tokensIssued); // 50% in project
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function getStats() returns (uint256, uint256, bool) {
        return (totalContribution, totalSupply, purchasingAllowed);
    }
}