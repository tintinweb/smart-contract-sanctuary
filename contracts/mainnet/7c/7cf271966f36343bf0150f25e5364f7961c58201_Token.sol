pragma solidity ^0.4.15;

contract Base {
    
    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }

    // *************************************************
    // *          reentrancy handling                  *
    // *************************************************

    uint private bitlocks = 0;
    modifier noReentrancy(uint m) {
        var _locks = bitlocks;
        require(_locks & m <= 0);
        bitlocks |= m;
        _;
        bitlocks = _locks;
    }

    modifier noAnyReentrancy {
        var _locks = bitlocks;
        require(_locks <= 0);
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }

    modifier reentrant { _; }
}

contract Owned {
    address public owner;
    address public newOwner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        newOwner = _newOwner;
    }

    function acceptOwnership() onlyOwner public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    uint256 public totalSupply;
  
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
  
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StandartToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    bool public isStarted = false;
    
    modifier isStartedOnly() {
        require(isStarted);
        _;
    }

    function transfer(address _to, uint256 _value) isStartedOnly public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
  
    function transferFrom(address _from, address _to, uint256 _value) isStartedOnly public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) isStartedOnly public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) isStartedOnly public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) isStartedOnly public returns (bool success) {
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

//Contract belongs to Aridika Corporation OU
//Nominal (initial) cost of one token = 1$

contract Token is Owned, StandartToken {
    string public name = "CRYPTODEPOZIT";
    string public symbol = "DEPO";
    uint public decimals = 0;
    address public constant company = 0xC01aed0F75f117d1f47f9146E41C9A6E0870350e;
    
    function Token() public {
        mint(msg.sender, 10 ** 9);
        mint(company, 10 * 10 ** 6);
        start();
    }

    function () public {
        revert();
    }

    function mint(address _to, uint256 _amount)
        internal
        returns (bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        return true;
    }

    function start()
        internal
        returns (bool)
    {
        isStarted = true;
        return true;
    }
}