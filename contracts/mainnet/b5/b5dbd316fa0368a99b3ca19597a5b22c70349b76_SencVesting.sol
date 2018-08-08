pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// SencTokenSale - SENC Token Sale Contract
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Total tokens 500m
// * Founding Team 10% - 5 tranches of 20% of 50,000,000 in **arrears** every 24 weeks from the activation date.
// * Early Support 20% - 4 tranches of 25% of 100,000,000 in **advance** every 4 weeks from activation date.
// * Pre-sale 20% - 4 tranches of 25% of 100,000,000 in **advance** every 4 weeks from activation date.
//   * To be separated into ~ 28 presale addresses
// ----------------------------------------------------------------------------

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract OperatableBasic {
    function setPrimaryOperator (address addr) public;
    function setSecondaryOperator (address addr) public;
    function isPrimaryOperator(address addr) public view returns (bool);
    function isSecondaryOperator(address addr) public view returns (bool);
}

contract Operatable is Ownable, OperatableBasic {
    address public primaryOperator;
    address public secondaryOperator;

    modifier canOperate() {
        require(msg.sender == primaryOperator || msg.sender == secondaryOperator || msg.sender == owner);
        _;
    }

    function Operatable() public {
        primaryOperator = owner;
        secondaryOperator = owner;
    }

    function setPrimaryOperator (address addr) public onlyOwner {
        primaryOperator = addr;
    }

    function setSecondaryOperator (address addr) public onlyOwner {
        secondaryOperator = addr;
    }

    function isPrimaryOperator(address addr) public view returns (bool) {
        return (addr == primaryOperator);
    }

    function isSecondaryOperator(address addr) public view returns (bool) {
        return (addr == secondaryOperator);
    }
}

contract Salvageable is Operatable {
    // Salvage other tokens that are accidentally sent into this token
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        if (address(oddToken) == address(0)) {
            owner.transfer(amount);
            return;
        }
        oddToken.transfer(owner, amount);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SencTokenConfig {
    string public constant NAME = "Sentinel Chain Token";
    string public constant SYMBOL = "SENC";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 500000000 * DECIMALSFACTOR;
}

contract SencToken is PausableToken, SencTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function SencToken() public {
        paused = true;
    }

    function pause() onlyOwner public {
        revert();
    }

    function unpause() onlyOwner public {
        super.unpause();
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    // Airdrop tokens from bounty wallet to contributors as long as there are enough balance
    function airdrop(address bountyWallet, address[] dests, uint[] values) public onlyOwner returns (uint) {
        require(dests.length == values.length);
        uint i = 0;
        while (i < dests.length && balances[bountyWallet] >= values[i]) {
            this.transferFrom(bountyWallet, dests[i], values[i]);
            i += 1;
        }
        return(i);
    }
}

contract SencVesting is Salvageable {
    using SafeMath for uint;

    SencToken public token;

    bool public started = false;
    uint public startTimestamp;
    uint public totalTokens;

    struct Entry {
        uint tokens;
        bool advance;
        uint periods;
        uint periodLength;
        uint withdrawn;
    }
    mapping (address => Entry) public entries;

    event NewEntry(address indexed beneficiary, uint tokens, bool advance, uint periods, uint periodLength);
    event Withdrawn(address indexed beneficiary, uint withdrawn);

    function SencVesting(SencToken _token) public {
        require(_token != address(0));
        token = _token;
    }

    function addEntryIn4WeekPeriods(address beneficiary, uint tokens, bool advance, uint periods) public onlyOwner {
        addEntry(beneficiary, tokens, advance, periods, 4 * 7 days);
    }
    function addEntryIn24WeekPeriods(address beneficiary, uint tokens, bool advance, uint periods) public onlyOwner {
        addEntry(beneficiary, tokens, advance, periods, 24 * 7 days);
    }
    function addEntryInSecondsPeriods(address beneficiary, uint tokens, bool advance, uint periods, uint secondsPeriod) public onlyOwner {
        addEntry(beneficiary, tokens, advance, periods, secondsPeriod);
    }

    function addEntry(address beneficiary, uint tokens, bool advance, uint periods, uint periodLength) internal {
        require(!started);
        require(beneficiary != address(0));
        require(tokens > 0);
        require(periods > 0);
        require(entries[beneficiary].tokens == 0);
        entries[beneficiary] = Entry({
            tokens: tokens,
            advance: advance,
            periods: periods,
            periodLength: periodLength,
            withdrawn: 0
        });
        totalTokens = totalTokens.add(tokens);
        NewEntry(beneficiary, tokens, advance, periods, periodLength);
    }

    function start() public onlyOwner {
        require(!started);
        require(totalTokens > 0);
        require(totalTokens == token.balanceOf(this));
        started = true;
        startTimestamp = now;
    }

    function vested(address beneficiary, uint time) public view returns (uint) {
        uint result = 0;
        if (startTimestamp > 0 && time >= startTimestamp) {
            Entry memory entry = entries[beneficiary];
            if (entry.tokens > 0) {
                uint periods = time.sub(startTimestamp).div(entry.periodLength);
                if (entry.advance) {
                    periods++;
                }
                if (periods >= entry.periods) {
                    result = entry.tokens;
                } else {
                    result = entry.tokens.mul(periods).div(entry.periods);
                }
            }
        }
        return result;
    }

    function withdrawable(address beneficiary) public view returns (uint) {
        uint result = 0;
        Entry memory entry = entries[beneficiary];
        if (entry.tokens > 0) {
            uint _vested = vested(beneficiary, now);
            result = _vested.sub(entry.withdrawn);
        }
        return result;
    }

    function withdraw() public {
        withdrawInternal(msg.sender);
    }

    function withdrawOnBehalfOf(address beneficiary) public onlyOwner {
        withdrawInternal(beneficiary);
    }

    function withdrawInternal(address beneficiary) internal {
        Entry storage entry = entries[beneficiary];
        require(entry.tokens > 0);
        uint _vested = vested(beneficiary, now);
        uint _withdrawn = entry.withdrawn;
        require(_vested > _withdrawn);
        uint _withdrawable = _vested.sub(_withdrawn);
        entry.withdrawn = _vested;
        require(token.transfer(beneficiary, _withdrawable));
        Withdrawn(beneficiary, _withdrawable);
    }

    function tokens(address beneficiary) public view returns (uint) {
        return entries[beneficiary].tokens;
    }

    function withdrawn(address beneficiary) public view returns (uint) {
        return entries[beneficiary].withdrawn;
    }

    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        // Cannot withdraw SencToken if vesting started
        require(!started || address(oddToken) != address(token));
        super.emergencyERC20Drain(oddToken,amount);
    }
}