/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.5.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract OwnableHKDT {
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    
    uint256 public _totalSupply;
    string public name;
    mapping(address => uint256) public balances;
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract StandardERC20 is ERC20Interface {
    
     function allowance(address owner, address spender) public view returns (uint256);
     function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
     function approve(address spender, uint256 tokens) public returns (bool success);
     
     event Approval(address indexed owner, address indexed spender, uint256 tokens);
}

contract BasicHARBOUR is OwnableHKDT, ERC20Interface {
    
    using SafeMath for uint256;
    
    mapping(address => uint256) public balances;
}


contract StandardHARBOUR is BasicHARBOUR, StandardERC20 {
    
    
    mapping(address => uint256) public balances;
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        
      balances[msg.sender] = balances[msg.sender].sub(tokens);
      balances[to] = balances[to].add(tokens);
      emit Transfer(msg.sender, to, tokens);
      return true;
    }
}

contract Pausable is OwnableHKDT {
    
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
        emit Pause();
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract BlackList is OwnableHKDT, ERC20Interface {
    
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }
    
    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
    
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    
    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);
    
    event AddedBlackList(address _user);
    
    event RemovedBlackList(address _user);
    
}


contract TESTHARBOURx is Pausable, StandardHARBOUR, BlackList {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
   // uint256 public _initialSupply;
    
    address public minter;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
     
   constructor(address payable _wallet, address _token) public {
       
      
       
        wallet = _wallet;
        token = _token;
        owner = msg.sender;
        minter = msg.sender;
        name = "HARBOURX2";
        symbol = "HRX2";
        decimals = 18;
        _totalSupply = 2000000;
        
        balances[owner] = _totalSupply;
    }
    
    address payable wallet;
    address public token;
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool sucess) {
        require(!isBlackListed[msg.sender]);
        return transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool sucess) {
        
         require(!isBlackListed[_from]);
         balances[_from] = balances[msg.sender].sub(_value);
         allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
         balances[_to] = balances[_to].add(_value);
         return transferFrom(_from, _to, _value);
    }
    
    function mint(address owner, uint256 amount) public onlyOwner {
        require(msg.sender == minter);
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);
        
        balances[owner] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
        }
        
    function burn(address owner, uint256 amount) public onlyOwner {
        require(msg.sender == owner);
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);
        
        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    

    function totalSupply() public view returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(!isBlackListed[msg.sender]);
        allowed[msg.sender][spender] = tokens;
        return approve(spender, tokens);
        emit Approval(msg.sender, spender, tokens);
    }
}