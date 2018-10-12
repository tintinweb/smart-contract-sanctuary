pragma solidity ^0.4.22;

// GetPaid Token Project Updated

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
    function distr(address _to, uint256 _value) external returns (bool);
    function totalSupply() constant external returns (uint256 supply);
    function balanceOf(address _owner) constant external returns (uint256 balance);
}

contract GetPaidToken is ERC20 {

  
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;

    string public constant name = "GetPaid";
    string public constant symbol = "GPaid";
    uint public constant decimals = 18;
    
    uint256 public totalSupply = 30000000000e18;
    
    uint256 public totalDistributed = 0;

    uint256 public totalValue = 0;
    
    uint256 public totalRemaining = totalSupply.sub(totalDistributed);
    
    uint256 public value = 200000e18;

    uint256 public tokensPerEth = 20000000e18;

    uint256 public constant minContribution = 1 ether / 100; // 0.01 Eth

    uint256 public constant maxTotalValue = 15000000000e18;



    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event Distr0(address indexed to, uint256 amount);
    event DistrFinished();
    event ZeroEthFinished();

    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event TokensPerEthUpdated(uint _tokensPerEth);
    
    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;

    bool public zeroDistrFinished = false;
    

    modifier canDistr() {
        require(!distributionFinished);
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
    
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function finishZeroDistribution() onlyOwner canDistr public returns (bool) {
        zeroDistrFinished = true;
        emit ZeroEthFinished();
        return true;
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }

    function distr0(address _to, uint256 _amount) canDistr private returns (bool) {
        require( totalValue < maxTotalValue );
        totalDistributed = totalDistributed.add(_amount);
        totalValue = totalValue.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
        
        if (totalValue >= maxTotalValue) {
            zeroDistrFinished = true;
        }
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    function () external payable {
        getTokens();
     }

    function getTokens() payable canDistr public {
        
        address investor = msg.sender;
        uint256 toGive = value;
        uint256 tokens = 0;
        tokens = tokensPerEth.mul(msg.value) / 1 ether;
        uint256 bonusFourth = 0;
        uint256 bonusHalf = 0;
        uint256 bonusTwentyFive = 0;
        uint256 bonusFifty = 0;
        uint256 bonusOneHundred = 0;
        bonusFourth = tokens / 4;
        bonusHalf = tokens / 2;
        bonusTwentyFive = tokens.add(bonusFourth);
        bonusFifty = tokens.add(bonusHalf);
        bonusOneHundred = tokens.add(tokens);
        

        if (msg.value == 0 ether) {
            require( blacklist[investor] == false );
            require( totalValue <= maxTotalValue );
            distr0(investor, toGive);
            blacklist[investor] = true;

            if (totalValue >= maxTotalValue) {
                zeroDistrFinished = true;
            }
        } 
        
        if (msg.value > 0 ether && msg.value < 0.1 ether ) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, tokens);

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }

        if (msg.value == 0.1 ether ) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, bonusTwentyFive);

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }

        if (msg.value > 0.1 ether && msg.value < 0.5 ether ) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, bonusTwentyFive);
    
            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }

        if (msg.value == 0.5 ether ) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, bonusFifty);

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }

        if (msg.value > 0.5 ether && msg.value < 1 ether ) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, bonusFifty);
    
            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }

        if (msg.value == 1 ether) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, bonusOneHundred);

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }

        if (msg.value > 1 ether) {
            blacklist[investor] = false;
            require( msg.value >= minContribution );
            require( msg.value > 0 );
            distr(investor, bonusOneHundred);

            if (totalDistributed >= totalSupply) {
                distributionFinished = true;
            }
        }
    }

    function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( totalDistributed < totalSupply );
        
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        //log
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }

    function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}