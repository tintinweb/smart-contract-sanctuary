pragma solidity ^0.4.24;


/**
 * @title ERC20TokenInterface
 * @dev Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}
/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract Admined { //This token contract is administered
    address public admin; //Admin address is public

    /**
    * @dev Contract constructor, define initial administrator
    */
    constructor() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit AdminedEvent(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    //All admin actions have a log for public review
    event TransferAdminship(address newAdminister);
    event AdminedEvent(address administer);

}

contract LockableToken is Admined {

    event LockStatus(address _target, uint _timeStamp);

    mapping (address => uint) internal locked; //public need to be reviewed
    bool internal globalLock = true;

    /**
    * @notice _target - address you want to lock until _timeStamp - unix time
    */
    function setLocked(address _target, uint _timeStamp) public onlyAdmin returns (bool) {
        locked[_target]=_timeStamp;
        emit LockStatus(_target, _timeStamp);
        return true;
    }

    /**
    * @notice function allows admin to unlock tokens on _target address
    */
    function unLock(address _target) public onlyAdmin returns (bool) {
        locked[_target] = 0;
        return true;
    }

    /**
    * Allow admin to unlock everything
    */
    function AllUnLock() public onlyAdmin returns (bool) {
        globalLock = false;
        return true;
    }

    /**
    * Allow admin to lock everything
    */
    function AllLock() public onlyAdmin returns (bool) {
        globalLock = true;
        return true;
    }

    /**
    * Return state of globalLock
    */
    function isGlobalLock() public view returns (bool) {
        return globalLock;
    }

    /**
    * @notice Getter returns false if tokens are available and true if
    *               unavailable
    */
    function isLocked(address _target) public view returns (bool) {
        if(locked[_target] > now){
            return true;
        } else {
            return false;
        }
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is LockableToken {
  event Pause();
  event Unpause();

  bool public paused = false;

  constructor() internal {
    emit Unpause();
  }

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
   function pause() onlyAdmin whenNotPaused public {
     paused = true;
     emit Pause();
   }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyAdmin whenPaused public {
    paused = false;
    emit Unpause();
  }
}
/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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

/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is ERC20TokenInterface,  Admined, Pausable { //Standard definition of an ERC20Token
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances
    mapping (address => bool) frozen; //A mapping of all frozen status

    /**
    * @dev Get the balance of an specified address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

    /**
    * @dev transfer token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(frozen[msg.sender]==false);
        if (globalLock == true) {
            require(locked[msg.sender] <= now, &#39;Tokens locked as single&#39;);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev transfer token from an address to another specified address using allowance
    * @param _from The address where token comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(frozen[_from]==false);
        if (globalLock == true) {
            require(locked[msg.sender] <= now, &#39;Tokens locked as single&#39;);
        }
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Assign allowance to an specified address to use the owner balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Frozen account.
    * @param _target The address to being frozen.
    * @param _flag The frozen status to set.
    */
    function setFrozen(address _target,bool _flag) onlyAdmin whenNotPaused public {
        frozen[_target]=_flag;
        emit FrozenStatus(_target,_flag);
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenStatus(address _target,bool _flag);

}
/**
* @title ERC20 Token minimal interface for external tokens handle
*/
contract Token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

/**
* @title AXEL Token
* @notice AXEL Token creation.
* @dev ERC20 Token compliant
*/
contract AxelToken is ERC20Token {

    string public name = &#39;AXEL-AIRDROP&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;AXEL&#39;;
    string public version = &#39;1&#39;;

    /**
    * @notice token contructor.  250000000
    */
    constructor() public {
        //totalSupply = 50000000000 * 10 ** uint256(decimals); //50.000.000.000 tokens initial supply;
        totalSupply = 56601700 * 10 ** uint256(decimals); //50.000.000.000 tokens initial supply;
        balances[msg.sender] = totalSupply;
        emit Transfer(0, msg.sender, totalSupply);
    }

    /**
    * @notice Function to claim any token stuck on contract
    */
    function externalTokensRecovery(Token _address) onlyAdmin public {
        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin
    }

    /**
      Allow transfers of tokens in groups of addresses
    */
    function sendBatches(address[] _addrs, uint256[] tokensValue) onlyAdmin public {
      require(_addrs.length == tokensValue.length);
      for(uint256 i = 0; i < _addrs.length; i++) {
        require(transfer(_addrs[i], tokensValue[i]));
        require(setLocked(_addrs[i], 1561766400)); // Locked for 06/29/2019
      }
    }

    /**
      Allow the admin to burn tokens
    */
    function burn(uint256 _value) onlyAdmin whenNotPaused public {
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      totalSupply = totalSupply.sub(_value);

      emit Burn(msg.sender, _value);
      emit Transfer(msg.sender, address(0), _value);
    }

    /**
    * @notice this contract will revert on direct non-function calls, also it&#39;s not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

    event Burn(address indexed burner, uint256 value);
}