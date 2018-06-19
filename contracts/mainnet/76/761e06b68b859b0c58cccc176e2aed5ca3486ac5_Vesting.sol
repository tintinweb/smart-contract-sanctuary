pragma solidity ^0.4.13;

library safeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
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

contract DBC {

    // MODIFIERS

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract ERC20Interface {

    // EVENTS

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // CONSTANT METHODS

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    // NON-CONSTANT METHODS

    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
}

contract ERC20 is ERC20Interface {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { throw; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { throw; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        // See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263555598
        if (_value > 0) {
            require(allowed[msg.sender][_spender] == 0);
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}

contract Vesting is DBC {
    using safeMath for uint;

    // FIELDS

    // Constructor fields
    ERC20 public MELON_CONTRACT; // Melon as ERC20 contract
    // Methods fields
    uint public totalVestedAmount; // Quantity of vested Melon in total
    uint public vestingStartTime; // Timestamp when vesting is set
    uint public vestingPeriod; // Total vesting period in seconds
    address public beneficiary; // Address of the beneficiary
    uint public withdrawn; // Quantity of Melon withdrawn so far

    // CONSTANT METHODS

    function isBeneficiary() constant returns (bool) { return msg.sender == beneficiary; }
    function isVestingStarted() constant returns (bool) { return vestingStartTime != 0; }

    /// @notice Calculates the quantity of Melon asset that&#39;s currently withdrawable
    /// @return withdrawable Quantity of withdrawable Melon asset
    function calculateWithdrawable() constant returns (uint withdrawable) {
        uint timePassed = now.sub(vestingStartTime);

        if (timePassed < vestingPeriod) {
            uint vested = totalVestedAmount.mul(timePassed).div(vestingPeriod);
            withdrawable = vested.sub(withdrawn);
        } else {
            withdrawable = totalVestedAmount.sub(withdrawn);
        }
    }

    // NON-CONSTANT METHODS

    /// @param ofMelonAsset Address of Melon asset
    function Vesting(address ofMelonAsset) {
        MELON_CONTRACT = ERC20(ofMelonAsset);
    }

    /// @param ofBeneficiary Address of beneficiary
    /// @param ofMelonQuantity Address of Melon asset
    /// @param ofVestingPeriod Vesting period in seconds from vestingStartTime
    function setVesting(address ofBeneficiary, uint ofMelonQuantity, uint ofVestingPeriod)
        pre_cond(!isVestingStarted())
        pre_cond(ofMelonQuantity > 0)
    {
        require(MELON_CONTRACT.transferFrom(msg.sender, this, ofMelonQuantity));
        vestingStartTime = now;
        totalVestedAmount = ofMelonQuantity;
        vestingPeriod = ofVestingPeriod;
        beneficiary = ofBeneficiary;
    }

    /// @notice Withdraw
    function withdraw()
        pre_cond(isBeneficiary())
        pre_cond(isVestingStarted())
    {
        uint withdrawable = calculateWithdrawable();
        withdrawn = withdrawn.add(withdrawable);
        require(MELON_CONTRACT.transfer(beneficiary, withdrawable));
    }

}