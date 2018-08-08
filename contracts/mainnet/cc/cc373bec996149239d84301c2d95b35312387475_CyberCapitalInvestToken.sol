pragma solidity ^0.4.13;

/**
 * @title SafeMath
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 * @title Ownable
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Haltable
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 */
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

    // called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner {
        halted = true;
    }

    // called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }
}

/**
 * @title ERC20
 * ERC20 interface
 */
contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value);
    function transferFrom(address _from, address _to, uint _value);
    function approve(address _spender, uint _value);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title StandardToken
 * Standard ERC20-compliant token
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * fix for ERC20 short address attack
     */
    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) {
        /**
         * Allowed amount should be first set to 0
         * by calling approve(_spender, 0) in order to avoid this:
         * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
         */
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract CyberCapitalInvestToken is StandardToken {
    string public name = "Cyber Capital Invest Token";
    string public symbol = "CCI";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 250000000 * 1 ether;

    /**
     * All tokens are allocated to creator.
     */
    function CyberCapitalInvestToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}