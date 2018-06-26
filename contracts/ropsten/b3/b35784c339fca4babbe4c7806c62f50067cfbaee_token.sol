pragma solidity ^0.4.23;

contract Control {
    address public owner;
    bool public pause;

    event PAUSED();
    event STARTED();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier whenPaused {
        require(pause);
        _;
    }

    modifier whenNotPaused {
        require(!pause);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setState(bool _pause) onlyOwner public {
        pause = _pause;
        if (pause) {
            emit PAUSED();
        } else {
            emit STARTED();
        }
    }
    
    constructor() public {
        owner = msg.sender;
    }
}

contract ERC20Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function symbol() public constant returns (string);
    function decimals() public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

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

contract token is Control, ERC20Token {
    using SafeMath for uint256;
    
    uint256 public totalSupply;
    uint256 public forSell;
    uint256 public decimals;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    string public symbol;
    string public name;
    
    constructor(string _name) public {
        owner = 0x60dc10E6b27b6c70B97d1F3370198d076F5A48D8;
        decimals = 18;
        totalSupply = 100000000000 * (10 ** decimals);
        name = _name;
        symbol = _name;
        forSell = 50000000000 * (10 ** decimals);
        balanceOf[owner] = totalSupply.sub(forSell);
        
        emit Transfer(0, owner, balanceOf[owner]);
    }
    
    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address to, uint256 amount) public whenNotPaused returns (bool) {
        allowance[msg.sender][to] = amount;
        
        emit Approval(msg.sender, to , amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(allowance[from][msg.sender] >= amount);
        require(balanceOf[from] >= amount);
        
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balanceOf[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowance[tokenOwner][spender];
    }
    
    function symbol() public constant returns (string) {
        return symbol;
    }
    
    function decimals() public constant returns (uint256){
        return decimals;
    }
    
    function sellToken() payable public {
        require(msg.value >= 1000000000000000);
        require(forSell >= 0);
        uint256 amount = msg.value.mul(100000000);
        forSell = forSell.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        
        owner.transfer(msg.value);
        emit Transfer(0, msg.sender, amount);
    }
    
    function() payable public {
        sellToken();
    }
}