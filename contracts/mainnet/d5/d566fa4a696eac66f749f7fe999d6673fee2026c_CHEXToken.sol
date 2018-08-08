pragma solidity ^0.4.16;
/**
 * Overflow aware uint math functions.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Token
 * @dev Adds token security measures
 */
contract Token is ERC20 { using SafeMath for uint;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

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

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

/**
 *  @title CHEX Token
 *  @dev ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 */
contract CHEXToken is Token { using SafeMath for uint;

    string public constant name = "CHEX Token";
    string public constant symbol = "CHX";
    uint public constant decimals = 18;
    uint public startBlock; //crowdsale start block
    uint public endBlock; //crowdsale end block

    address public founder;
    
    uint public tokenCap = 1000000000 * 10**decimals; // 1b tokens, each divided to up to 10^decimals units.
    uint public crowdsaleAllocation = tokenCap; //100% of token supply allocated for crowdsale
    uint public crowdsaleSupply = 0;

    uint public transferLockup = 5760; //no transfers until ~1 day after crowdsale ends
    bool public frozen = false;  //in case of emergency, freeze purchase of tokens

    uint public etherRaised = 0; //for reporting direct ether amount raised

    uint public constant MIN_ETHER = 1 finney; //minimum ether required to buy tokens

    function CHEXToken(address founderInput, uint startBlockInput, uint endBlockInput) {
        founder = founderInput;
        startBlock = startBlockInput;
        endBlock = endBlockInput;
    }

    function() payable {
        buy(msg.sender);
    }

    function price() constant returns(uint) {
        if (block.number < startBlock) return 42007;
        if (block.number >= startBlock && block.number <= endBlock) {
            uint percentRemaining = pct((endBlock - block.number), (endBlock - startBlock), 3);
            return 21000 + 21 * percentRemaining;
        }
        return 21000;
    }

    function buy(address recipient) payable {
        if (frozen) revert();
        if (recipient == 0x0) revert();
        if (msg.value < MIN_ETHER) revert();

        uint tokens = msg.value.mul(price());
        uint nextTotal = totalSupply.add(tokens);

        if (nextTotal > tokenCap) revert();
        
        balances[recipient] = balances[recipient].add(tokens);

        totalSupply = nextTotal;

        if (block.number <= endBlock) {
            crowdsaleSupply = nextTotal;
            etherRaised = etherRaised.add(msg.value);
        }

        Transfer(0, recipient, tokens);
    }

    /*
    * TRANSFER LOCK
    */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (block.number <= endBlock + transferLockup && msg.sender != founder) return false;
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (block.number <= endBlock + transferLockup && msg.sender != founder) return false;
        return super.transferFrom(_from, _to, _value);
    }

    function pct(uint numerator, uint denominator, uint precision) internal returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /*
    * FOR AUTHORIZED USE ONLY
    */
    modifier onlyInternal {
        require(msg.sender == founder);
        _;
    }

    function freeze() onlyInternal {
        frozen = true;
    }

    function unfreeze() onlyInternal {
        frozen = false;
    }

    function withdrawFunds() onlyInternal {
		if (this.balance == 0) revert();

		founder.transfer(this.balance);
	}

    function changeFounder(address _newAddress) onlyInternal {
        if (msg.sender != founder) revert();
        if (_newAddress == 0x0) revert();
        

		founder = _newAddress;
	}

}