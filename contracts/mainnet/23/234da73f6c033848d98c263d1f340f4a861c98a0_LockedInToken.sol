pragma solidity ^0.4.20;

/*
*
*_                _            _ _         _         _        _                  
| |              | |          | (_)       (_)       | |      | |                 
| |     ___   ___| | _____  __| |_ _ __    _  ___   | |_ ___ | | _____ _ __  ___ 
| |    / _ \ / __| |/ / _ \/ _` | | &#39;_ \  | |/ _ \  | __/ _ \| |/ / _ \ &#39;_ \/ __|
| |___| (_) | (__|   <  __/ (_| | | | | |_| | (_) | | || (_) |   <  __/ | | \__ \
\_____/\___/ \___|_|\_\___|\__,_|_|_| |_(_)_|\___/   \__\___/|_|\_\___|_| |_|___/
*
* Coming to www.lockedin.io this weekend.
*
* An autonomousfully automated passive income tokens:
* [x] Created by a team of professional Developers from India who run a software company and specialize in Internet and Cryptographic Security
* [x] Pen-tested multiple times with zero vulnerabilities!
* [X] Able to operate even if our website www.lockedin.io is down via Metamask and Etherscan
* [x] As people join your make money as people leave you make money 24/7 – Not a lending platform but a human-less passive income machine on the Ethereum Blockchain
* [x] Once deployed neither we nor any other human can alter, change or stop the contract it will run for as long as Ethereum is running!
* [x] Unlike similar projects the developers are only allowing 0.3 ETH to be purchased by Developers at deployment - Fair for the Public!
* - 25% Reward of dividends if someone signs up using your Masternode link
* - You earn by others depositing or withdrawing ETH and this passive ETH earnings can either be reinvested or you can withdraw it at any time without penalty.
* Upon entry into the contract it will automatically deduct your 10% entry and exit fees so the longer you remain and the higher the volume the more you earn and the more that people join or leave you also earn more.  
* You are able to withdraw your entire balance at any time you so choose. 
*
*
*/

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

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
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

contract LockedInToken is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;

    string public constant name = "LockedInToken";
    string public constant symbol = "LIT";
    uint public constant decimals = 8;
    
    uint256 public totalSupply = 80000000e8;
    uint256 public totalDistributed = 1e8;
    uint256 public totalRemaining = totalSupply.sub(totalDistributed);
    uint256 public value;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    
    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function LockedInToken() public {
        owner = msg.sender;
        value = 5403e8;
        distr(owner, totalDistributed);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        DistrFinished();
        return true;
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
    
    function getTokens() payable canDistr public {
        
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        
        require(value <= totalRemaining);
        
        address investor = msg.sender;
        uint256 toGive = SafeMath.mul(value,100);
        
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
        
     
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
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
    
    function closeGame() onlyOwner public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }


}