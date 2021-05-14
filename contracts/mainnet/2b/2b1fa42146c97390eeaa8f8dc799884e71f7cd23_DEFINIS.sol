/**
 *Submitted for verification at Etherscan.io on 2021-05-14
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

contract OwnableHKDD {
    
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
    mapping(address => uint256) balances;
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 _value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 _value);
}

contract StandardERC20 is ERC20Interface {
    
     function allowance(address owner, address spender) public view returns (uint256);
     function transferFrom(address from, address to, uint256 _value) public returns (bool);
     function approve(address spender, uint256 _value) public returns (bool sucess);
     
     event Approval(address indexed owner, address indexed spender, uint256 _value);
}

contract BasicHKDD is OwnableHKDD, ERC20Interface {
    
    using SafeMath for uint256;
    
    mapping(address => uint256) public balances;
}


contract StandardHKDD is BasicHKDD, StandardERC20 {
    
    
    mapping(address => uint256) balances;
}

contract Pausable is OwnableHKDD {
    
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

contract BlackList is OwnableHKDD, ERC20Interface {
    
    function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }
    
    function getOwner() public view returns (address) {
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


contract DEFINIS is Pausable, StandardHKDD, BlackList {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
     
   constructor(address payable _wallet, address _token) public {
       
      
       
        wallet = _wallet;
        token = _token;
        owner = msg.sender;
        name = "DEFINIS";
        symbol = "HKDD";
        decimals = 18;
        _totalSupply = 2000000000000000000000000;
        
        balances[owner] = _totalSupply;
    }
    
    address payable wallet;
    address token;
    
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        
      require(!isBlackListed[msg.sender]);
      
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      emit Transfer(msg.sender, _to, _value);
      return true;
    }
    

    function mint(address _to, uint256 _value) public onlyOwner {
        require(msg.sender == owner);
        require(_totalSupply + _value > _totalSupply);
        require(balances[owner] + _value > balances[owner]);
        
        balances[_to] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        }
        
    function burn(address _to, uint256 _value) public onlyOwner {
        require(msg.sender == owner);
        require(_totalSupply >= _value);
        require(balances[owner] >= _value);
        
        _totalSupply -= _value;
        balances[_to] -= _value;
        emit Transfer(_to, address(0), _value);
    }
    

    function totalSupply() public view returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
       require(!isBlackListed[msg.sender]);
       allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
       return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
    require(!isBlackListed[msg.sender]);    
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}