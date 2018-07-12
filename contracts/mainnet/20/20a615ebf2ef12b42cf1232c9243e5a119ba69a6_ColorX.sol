pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
          return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;   
    }
    
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    
    function name() public view returns (string);
    
    function symbol() public view returns (string);
    
    function totalSupply() public view returns (uint256);
    
    function decimals() public view returns (uint8);
    
    function balanceOf(address who) public view returns (uint256);
    
    function transfer(address to, uint256 value) public returns (bool);
    
    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    
    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(address indexed owner,address indexed spender,uint256 value);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ColorX is ERC20 {
    
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private allowed;
    
    mapping(address => uint256) private balances;
    
    mapping(address => bool) private lockedAddresses;
    
    bool private transferable = true;
    
    address private manager_;
    
    string private name_;
    
    string private symbol_;
    
    uint256 private totalSupply_;
    
    uint8 private decimals_;
    
    constructor(string name, string symbol, uint256 totalSupply, uint8 decimals, address founder, address manager) public {
        name_ = name;
        symbol_ = symbol;
        totalSupply_ = totalSupply;
        decimals_ = decimals;
        manager_ = manager;
        balances[founder] = totalSupply;
        emit Transfer(0x0, founder, totalSupply);
    }
    
    modifier onlyManager {
        assert(manager_ == msg.sender);
        _;
    }
    
    modifier canTransfer {
        assert(transferable);
        _;
    }
    
    modifier notLocked {
        assert(!lockedAddresses[msg.sender]);
        _;
    }
    
    function name() public view returns (string) {
        return name_;
    }
    
    function symbol() public view returns (string) {
        return symbol_;
    }
    
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) canTransfer notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) canTransfer notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) canTransfer notLocked public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function lock(address who) onlyManager public returns(bool) {
        
        lockedAddresses[who] = true;
        
        return true;
    }
    
    function unlock(address who) onlyManager public returns(bool) {
        
        lockedAddresses[who] = false;
        
        return true;
    }
    
    function isLocked(address who) public view returns(bool) {
        
        return lockedAddresses[who];
    }

    function enableTransfer() onlyManager public returns(bool) {
        
        transferable = true;
        
        return true;
    }
    
    function disableTransfer() onlyManager public returns(bool) {
        
        transferable = false;
        
        return true;
    }
    
    function isTransferable() public view returns(bool) {
        
        return transferable;
    }
}