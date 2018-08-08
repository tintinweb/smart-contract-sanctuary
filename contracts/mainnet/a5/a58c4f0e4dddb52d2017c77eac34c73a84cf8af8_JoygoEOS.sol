pragma solidity ^0.4.18;

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

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ERC223Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223 is ERC223Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Token { 
    function distr(address _to, uint256 _value) public returns (bool);
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
}

contract JoygoEOS is ERC223 {
    
    using SafeMath for uint256;
    address public owner;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    mapping (address => bool) public blacklist;

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    uint256 public totalDistributed;
    uint256 public totalRemaining;
    uint256 public value;
    uint256 public dividend;
    uint256 public divisor;
    uint256 public invitedReward = 1;
    uint256 public inviteReward = 2;
    uint256 public inviteAmountLimit = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LOG_Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
    
    event Distr(address indexed to, uint256 amount);
    event InviteInit(address indexed to, uint256 amount);

    event DistrFinished();
    event DistrStarted();
    
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);
    
    bool public distributionFinished = false;
    bool public inviteFinished = false;

    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier canNotDistr() {
        require(distributionFinished);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function JoygoEOS (string _tokenName, string _tokenSymbol, uint256 _decimalUnits, uint256 _initialAmount, uint256 _totalDistributed, uint256 _value, uint256 _dividend, uint256 _divisor) public {
        require(_decimalUnits != 0);
        require(_initialAmount != 0);
        require(_totalDistributed != 0);
        require(_value != 0);
        require(_dividend != 0);
        require(_divisor != 0);
        
        
        owner = msg.sender;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        totalSupply = _initialAmount;
        totalDistributed = _totalDistributed;
        totalRemaining = totalSupply.sub(totalDistributed);
        value = _value;
        dividend = _dividend;
        divisor = _divisor;
        
        balances[owner] = totalDistributed;
        Transfer(address(0), owner, totalDistributed);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function enableWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function disableWhitelist(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = true;
        }
    }
    
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        DistrFinished();
        return true;
    }
    
    function startDistribution() onlyOwner canNotDistr public returns (bool) {
        distributionFinished = false;
        DistrStarted();
        return true;
    }
    
    function finishInvite() onlyOwner public returns (bool) {
        require(!inviteFinished);
        inviteFinished = true;
        return true;
    }
    
    function startInvite() onlyOwner public returns (bool) {
        require(inviteFinished);
        inviteFinished = false;
        return true;
    }
    
    function changeTotalDistributed(uint256 newTotalDistributed) onlyOwner public {
        totalDistributed = newTotalDistributed;
    }
    
    function changeTotalRemaining(uint256 newTotalRemaining) onlyOwner public {
        totalRemaining = newTotalRemaining;
    }
    
    function changeValue(uint256 newValue) onlyOwner public {
        value = newValue;
    }
    
    function changeTotalSupply(uint256 newTotalSupply) onlyOwner public {
        totalSupply = newTotalSupply;
    }
    
    function changeDecimals(uint256 newDecimals) onlyOwner public {
        decimals = newDecimals;
    }
    
    function changeName(string newName) onlyOwner public {
        name = newName;
    }
    
    function changeSymbol(string newSymbol) onlyOwner public {
        symbol = newSymbol;
    }
    
    function changeDivisor(uint256 newDivisor) onlyOwner public {
        divisor = newDivisor;
    }
    
    function changeDividend(uint256 newDividend) onlyOwner public {
        dividend = newDividend;
    }
    
    function changeInviteReward(uint256 newInviteReward) onlyOwner public {
        inviteReward = newInviteReward;
    }
    
    function changeInvitedReward(uint256 newInvitedReward) onlyOwner public {
        invitedReward = newInvitedReward;
    }
    
    function changInviteAmountLimit(uint256 newInviteAmountLimit) onlyOwner public {
        inviteAmountLimit = newInviteAmountLimit;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Distr(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
        
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function airdrop(address[] addresses) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(value <= totalRemaining);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(value <= totalRemaining);
            distr(addresses[i], value);
        }
	
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function distribution(address[] addresses, uint256 amount) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(amount <= totalRemaining);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(amount <= totalRemaining);
            distr(addresses[i], amount);
        }
	
        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }
    }
    
    function () external payable {
            getTokens();
     }
    
    function getTokens() payable canDistr onlyWhitelist public {
        
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        
        require(value <= totalRemaining);
        
        address investor = msg.sender;
        uint256 toGive = value;
        
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
        value = value.div(dividend).mul(divisor);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return getBalance(_owner);
    }
    
    function getBalance(address _address) constant internal returns (uint256) {
        if (_address !=address(0) && !distributionFinished && !blacklist[_address] && totalDistributed < totalSupply && !inviteFinished) {
            return balances[_address].add(value);
        }
        else {
            return balances[_address];
        }
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount, bytes _data, string _custom_fallback) onlyPayloadSize(2 * 32) public returns (bool success) {
        if(isContract(_to)) {
            require(balanceOf(msg.sender) >= _amount);
            balances[msg.sender] = balanceOf(msg.sender).sub(_amount);
            balances[_to] = balanceOf(_to).add(_amount);
            ContractReceiver receiver = ContractReceiver(_to);
            require(receiver.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _amount, _data));
            
            Transfer(msg.sender, _to, _amount);
            LOG_Transfer(msg.sender, _to, _amount, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _amount, _data);
        }
    }


    function transfer(address _to, uint256 _amount, bytes _data) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));

        if(isContract(_to)) {
            return transferToContract(_to, _amount, _data);
        }
        else {
            return transferToAddress(_to, _amount, _data);
        }
    }

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        
        require(_to != address(0));
        
        bytes memory empty;
        
        if(isContract(_to)) {
            return transferToContract(_to, _amount, empty);
        }
        else {
            if(_amount <= inviteAmountLimit){
                require(invite(msg.sender, _to));
            }
            return transferToAddress(_to, _amount, empty);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        require(invite(_from, _to));
        
        bytes memory empty;
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        LOG_Transfer(_from, _to, _amount, empty);
        return true;
    }
    
    function invite(address _from, address _to) internal returns (bool success) {
        
        if(inviteFinished){
           return true; 
        }

        if(invitedInit(_from) && _from != _to){
            inviteInit(_to);
            return true;
        }
        invitedInit(_to);
        return true;
    }
    
    function inviteInit(address _address) internal returns (bool success) {
        if (!distributionFinished && totalDistributed < totalSupply) {
            
            
            if (value.mul(inviteReward) > totalRemaining) {
                value = totalRemaining;
            }
            require(value.mul(inviteReward) <= totalRemaining);
            
            uint256 toGive = value.mul(inviteReward);
            
            totalDistributed = totalDistributed.add(toGive);
            totalRemaining = totalRemaining.sub(toGive);
            balances[_address] = balances[_address].add(toGive);
            InviteInit(_address, toGive);
            Transfer(address(0), _address, toGive);

            if (toGive > 0) {
                blacklist[_address] = true;
            }

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
            
            value = value.div(dividend).mul(divisor);
            return true;
        }
        return false;
    }
    
    function invitedInit(address _address) internal returns (bool success) {
        if (!distributionFinished && totalDistributed < totalSupply && !blacklist[_address]) {
            
            if (value.mul(invitedReward) > totalRemaining) {
                value = totalRemaining;
            }
            require(value.mul(invitedReward) <= totalRemaining);
            
            uint256 toGive = value.mul(invitedReward);
            
            totalDistributed = totalDistributed.add(toGive);
            totalRemaining = totalRemaining.sub(toGive);
            balances[_address] = balances[_address].add(toGive);
            InviteInit(_address, toGive);
            Transfer(address(0), _address, toGive);

            if (toGive > 0) {
                blacklist[_address] = true;
            }

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
            
            value = value.div(dividend).mul(divisor);
            return true;
        }
        return false;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
    }
    
    function mint(uint256 _value) onlyOwner public {

        address minter = msg.sender;
        balances[minter] = balances[minter].add(_value);
        totalSupply = totalSupply.add(_value);
        Mint(minter, _value);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) payable public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
    
    function isContract(address _addr) private constant returns (bool) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] =  balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        LOG_Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function transferToContract(address _to, uint _value, bytes _data) private returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        LOG_Transfer(msg.sender, _to, _value, _data);
        return true;
    }

}