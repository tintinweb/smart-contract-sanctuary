pragma solidity ^0.4.20;

interface ERC20Token {

    function totalSupply() constant external returns (uint256 supply);

    function balanceOf(address _owner) constant external returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Token{
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) { revert(); }
        
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) { revert(); }
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() constant external returns (uint256 supply){
        return totalSupply;
    }
}

contract DIUToken is Token{
    address owner = msg.sender;
    bool private paused = false;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet;

    uint256 public ethRaised;
    uint256 public tokenFunded;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    modifier whenNotPause{
        require(!paused);
        _;
    }

    function DIUToken() {
        balances[msg.sender] = 100000000 * 1000000000000000000;
        totalSupply = 100000000 * 1000000000000000000;
        name = "D!U";
        decimals = 18;
        symbol = "D!U";
        unitsOneEthCanBuy = 100;
        fundsWallet = msg.sender;
        tokenFunded = 0;
        ethRaised = 0;
        paused = false;
    }

    function() payable whenNotPause{
        if (msg.value >= 10 finney){
            totalEthInWei = totalEthInWei + msg.value;
            uint256 amount = msg.value * unitsOneEthCanBuy;
            if (balances[fundsWallet] < amount) {
                return;
            }
            
            ethRaised = ethRaised + msg.value;
            tokenFunded = tokenFunded + amount + ethRaised;
    
            balances[fundsWallet] = balances[fundsWallet] - amount - ethRaised;
            balances[msg.sender] = balances[msg.sender] + amount + ethRaised;
    
            Transfer(fundsWallet, msg.sender, amount);
        }
        
        fundsWallet.transfer(msg.value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            revert();
        }

        return true;
    }
    
    function pauseContract(bool) external onlyOwner{
        paused = true;
    }
    
    function unpauseContract(bool) external onlyOwner{
        paused = false;
    }
    
    function getStats() external constant returns (uint256, uint256, bool) {
        return (ethRaised, tokenFunded, paused);
    }

}