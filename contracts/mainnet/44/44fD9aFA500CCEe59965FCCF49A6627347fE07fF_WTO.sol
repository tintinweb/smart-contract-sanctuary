pragma solidity ^0.4.24;

contract ERC223Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract WTO is ERC223Interface, Pausable {
    using SafeMath for uint256;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    
    constructor(string name, string symbol, uint8 decimals, uint256 totalSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
    }
    
    function name() public view returns (string) {
        return _name;
    }
    
    function symbol() public view returns (string) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function freezeAccount(address target, bool freeze) 
    public 
    onlyOwner
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function transfer(address _to, uint256 _value) 
    public
    whenNotPaused
    returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(!frozenAccount[_to]);
        require(!frozenAccount[msg.sender]);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint _value, bytes _data) 
    public
    whenNotPaused
    returns (bool)
    {
        require(_value > 0 );
        require(!frozenAccount[_to]);
        require(!frozenAccount[msg.sender]);
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    function isContract(address _addr) 
    private
    view
    returns (bool is_contract) 
    {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) 
    public
    whenNotPaused
    returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!frozenAccount[_to]);
        require(!frozenAccount[_from]);
        
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) 
    public
    whenNotPaused
    returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) 
    public
    view
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) 
    public
    whenNotPaused
    returns (bool) 
    {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) 
    public
    whenNotPaused
    returns (bool) 
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function distributeAirdrop(address[] addresses, uint256 amount) 
    public
    returns (bool seccess) 
    {
        require(amount > 0);
        require(addresses.length > 0);
        require(!frozenAccount[msg.sender]);
        
        uint256 totalAmount = amount.mul(addresses.length);
        require(balances[msg.sender] >= totalAmount);
        bytes memory empty;
        
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0));
            require(!frozenAccount[addresses[i]]);
            balances[addresses[i]] = balances[addresses[i]].add(amount);
            emit Transfer(msg.sender, addresses[i], amount, empty);
        }
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        
        return true;
    }
    
    function distributeAirdrop(address[] addresses, uint256[] amounts) 
    public returns (bool) {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);
        require(!frozenAccount[msg.sender]);
        
        uint256 totalAmount = 0;
        
        for(uint i = 0; i < addresses.length; i++){
            require(amounts[i] > 0);
            require(addresses[i] != address(0));
            require(!frozenAccount[addresses[i]]);
            
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(balances[msg.sender] >= totalAmount);
        
        bytes memory empty;
        for (i = 0; i < addresses.length; i++) {
            balances[addresses[i]] = balances[addresses[i]].add(amounts[i]);
            emit Transfer(msg.sender, addresses[i], amounts[i], empty);
        }
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        return true;
    }
    
    /**
     * @dev Function to collect tokens from the list of addresses
     */
    function collectTokens(address[] addresses, uint256[] amounts) 
    public
    onlyOwner 
    returns (bool) {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);

        uint256 totalAmount = 0;
        bytes memory empty;
        
        for (uint j = 0; j < addresses.length; j++) {
            require(amounts[j] > 0);
            require(addresses[j] != address(0));
            require(!frozenAccount[addresses[j]]);
                    
            require(balances[addresses[j]] >= amounts[j]);
            balances[addresses[j]] = balances[addresses[j]].sub(amounts[j]);
            totalAmount = totalAmount.add(amounts[j]);
            emit Transfer(addresses[j], msg.sender, amounts[j], empty);
        }
        balances[msg.sender] = balances[msg.sender].add(totalAmount);
        return true;
    }
}