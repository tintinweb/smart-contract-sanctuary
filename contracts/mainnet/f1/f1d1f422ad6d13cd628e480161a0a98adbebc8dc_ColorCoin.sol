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
    
    function balanceOf(address who) public view returns (uint256);
    
    function transfer(address to, uint256 value) public returns (bool);
    
    function allowance(address owner, address spender) public view returns (uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    
    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(address indexed owner,address indexed spender,uint256 value);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ColorCoin is ERC20 {
    
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private allowed;
    
    mapping(address => uint256) private balances;
    
    mapping(address => bool) private lockedAddresses;
    
    address private admin;
    
    address private founder;
    
    bool public isTransferable = false;
    
    string public name;
    
    string public symbol;
    
    uint256 public totalSupply;
    
    uint8 public decimals;
    
    constructor(address _founder, address _admin) public {
        name = "Color Coin";
        symbol = "COL";
        totalSupply = 350000000000000000000000000;
        decimals = 18;
        admin = _admin;
        founder = _founder;
        balances[founder] = totalSupply;
        emit Transfer(0x0, founder, totalSupply);
    }
    
    modifier onlyAdmin {
        require(admin == msg.sender);
        _;
    }
    
    modifier onlyFounder {
        require(founder == msg.sender);
        _;
    }
    
    modifier transferable {
        require(isTransferable);
        _;
    }
    
    modifier notLocked {
        require(!lockedAddresses[msg.sender]);
        _;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) transferable notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) transferable public returns (bool) {
        require(!lockedAddresses[_from]);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) transferable notLocked public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function distribute(address _to, uint256 _value) onlyFounder public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function claimToken(address tokenContract, address _to, uint256 _value) onlyAdmin public returns (bool) {
        require(tokenContract != address(0));
        require(_to != address(0));
        require(_value > 0);
        
        ERC20 token = ERC20(tokenContract);

        return token.transfer(_to, _value);
    }
    
    function lock(address who) onlyAdmin public {
        
        lockedAddresses[who] = true;
    }
    
    function unlock(address who) onlyAdmin public {
        
        lockedAddresses[who] = false;
    }
    
    function isLocked(address who) public view returns(bool) {
        
        return lockedAddresses[who];
    }

    function enableTransfer() onlyAdmin public {
        
        isTransferable = true;
    }
    
    function disableTransfer() onlyAdmin public {
        
        isTransferable = false;
    }
}