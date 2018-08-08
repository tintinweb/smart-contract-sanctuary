pragma solidity ^0.4.12;
/**
 * Overflow aware uint math functions.
 */
contract SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function pct(uint numerator, uint denominator, uint precision) internal returns(uint quotient) {
    uint _numerator = numerator * 10 ** (precision+1);
    uint _quotient = ((_numerator / denominator) + 5) / 10;
    return (_quotient);
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

/**
 * ERC 20 token
 */
contract Token is SafeMath {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = sub(balances[msg.sender], _value);
            balances[_to] = add(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = add(balances[_to], _value);
            balances[_from] = sub(balances[_from], _value);
            allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    // A vulernability of the approve method in the ERC20 standard was identified by
    // Mikhail Vladimirov and Dmitry Khovratovich here:
    // https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
    // It&#39;s better to use this method which is not susceptible to over-withdrawing by the approvee.
    /// @param _spender The address to approve
    /// @param _currentValue The previous value approved, which can be retrieved with allowance(msg.sender, _spender)
    /// @param _newValue The new value to approve, this will replace the _currentValue
    /// @return bool Whether the approval was a success (see ERC20&#39;s `approve`)
    function compareAndApprove(address _spender, uint256 _currentValue, uint256 _newValue) public returns(bool) {
        if (allowed[msg.sender][_spender] != _currentValue) {
            return false;
        }
            return approve(_spender, _newValue);
    }
}

contract CHEXToken is Token {

    string public constant name = "CHEX Token";
    string public constant symbol = "CHX";
    uint public constant decimals = 18;
    uint public startBlock; //crowdsale start block
    uint public endBlock; //crowdsale end block

    address public founder;
    address public owner;
    
    uint public totalSupply = 2000000000 * 10**decimals; // 2b tokens, each divided to up to 10^decimals units.
    
    uint public totalTokens = 0;
    uint public presaleSupply = 0;
    uint public presaleEtherRaised = 0;

    event Buy(address indexed recipient, uint eth, uint chx);

    uint public presaleAllocation = totalSupply / 2; //50% of token supply allocated for crowdsale
    uint public strategicAllocation = totalSupply / 4; //25% of token supply allocated post-crowdsale for strategic supply
    uint public reserveAllocation = totalSupply / 4; //25% of token supply allocated post-crowdsale for internal
    bool public strategicAllocated = false;
    bool public reserveAllocated = false;

    uint public transferLockup = 172800; //no transfers until 30 days after crowdsale begins (assumes 100 day crowdsale)
    uint public reserveLockup = 241920; //first wave of reserve locked until 42 days after sale is over

    uint public reserveWave = 0; //increments each time 10% of reserve is allocated, to a max of 10
    uint public reserveWaveTokens = reserveAllocation / 10; //10% of reserve will be released on each wave
    uint public reserveWaveLockup = 172800; //30 day intervals before subsequent wave of reserve tokens can be released

    uint public constant MIN_ETHER = 1 finney;

    enum TokenSaleState {
        Initial,    //contract initialized, bonus token
        Presale,    //limited time crowdsale
        Live,       //default price
        Frozen      //prevent sale of tokens
    }

    TokenSaleState public _saleState = TokenSaleState.Initial;

    function CHEXToken(address founderInput, address ownerInput, uint startBlockInput, uint endBlockInput) {
        founder = founderInput;
        owner = ownerInput;
        startBlock = startBlockInput;
        endBlock = endBlockInput;
        
        updateTokenSaleState();
    }

    function price() constant returns(uint) {
        if (_saleState == TokenSaleState.Initial) return 12002;
        if (_saleState == TokenSaleState.Presale) {
            uint percentRemaining = pct((endBlock - block.number), (endBlock - startBlock), 3);
            return 6000 + 6 * percentRemaining;
        }
        return 6000;
    }

    function() payable {
        buy(msg.sender);
    }

    function buy(address recipient) payable {
        if (recipient == 0x0) throw;
        if (msg.value < MIN_ETHER) throw;
        if (_saleState == TokenSaleState.Frozen) throw;
        
        updateTokenSaleState();

        uint tokens = mul(msg.value, price());
        uint nextTotal = add(totalTokens, tokens);
        uint nextPresaleTotal = add(presaleSupply, tokens);

        if (nextTotal >= totalSupply) throw;
        if (nextPresaleTotal >= presaleAllocation) throw;
        
        balances[recipient] = add(balances[recipient], tokens);
        presaleSupply = nextPresaleTotal;
        totalTokens = nextTotal;

        if (_saleState == TokenSaleState.Initial || _saleState == TokenSaleState.Presale) {
            presaleEtherRaised = add(presaleEtherRaised, msg.value);
        }

        founder.transfer(msg.value);
        
        Transfer(0, recipient, tokens);
        Buy(recipient, msg.value, tokens);
    }

    function updateTokenSaleState () {
        if (_saleState == TokenSaleState.Frozen) return;

        if (_saleState == TokenSaleState.Live && block.number > endBlock) return;
        
        if (_saleState == TokenSaleState.Initial && block.number >= startBlock) {
            _saleState = TokenSaleState.Presale;
        }
        
        if (_saleState == TokenSaleState.Presale && block.number > endBlock) {
            _saleState = TokenSaleState.Live;
        }
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (block.number <= startBlock + transferLockup && msg.sender != founder && msg.sender != owner) throw;
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (block.number <= startBlock + transferLockup && msg.sender != founder && msg.sender != owner) throw;
        return super.transferFrom(_from, _to, _value);
    }

    modifier onlyInternal {
        require(msg.sender == owner || msg.sender == founder);
        _;
    }

    function allocateStrategicTokens() onlyInternal {
        if (strategicAllocated) throw;

        balances[owner] = add(balances[owner], strategicAllocation);
        totalTokens = add(totalTokens, strategicAllocation);

        strategicAllocated = true;

        Transfer(0, owner, strategicAllocation);
    }

    function allocateReserveTokens() onlyInternal {
        if (block.number <= endBlock + reserveLockup + (reserveWaveLockup * reserveWave)) throw;
        if (reserveAllocated) throw;

        balances[founder] = add(balances[founder], reserveWaveTokens);
        totalTokens = add(totalTokens, reserveWaveTokens);

        reserveWave++;
        if (reserveWave >= 10) {
            reserveAllocated = true;
        }

        Transfer(0, founder, reserveWaveTokens);
    }

    function freeze() onlyInternal {
        _saleState = TokenSaleState.Frozen;
    }

    function unfreeze() onlyInternal {
        _saleState = TokenSaleState.Presale;
        updateTokenSaleState();
    }

}