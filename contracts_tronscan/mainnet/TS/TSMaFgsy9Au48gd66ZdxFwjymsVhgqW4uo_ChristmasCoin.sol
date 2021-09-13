//SourceUnit: tron.sol

pragma solidity ^0.4.24;
  library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
  }

  contract Ownable {
    address public owner;

    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
      );
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
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0));
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

  }

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
    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }
  }

  contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  }

  contract BasicToken is ERC20Basic, Ownable {
      using SafeMath for uint256;
      mapping(address => uint256) balances;
      bool public transfersEnabledFlag;

      modifier transfersEnabled() {
          require(transfersEnabledFlag);
          _;
      }

      function enableTransfers() public onlyOwner {
        transfersEnabledFlag = true;
      }

      function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
      }

      function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
      }
  }

  contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  }

  contract StandardToken is ERC20, BasicToken {
      mapping(address => mapping(address => uint256)) internal allowed;

      function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
      }

      function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
      }

      function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
      }

      function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }

      function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }
  }
  
  contract MintableToken is StandardToken, Pausable {
      event Mint(address indexed to, uint256 amount);
      event MintFinished();

      bool public mintingFinished = false;

      mapping(address => bool) public minters;

      modifier canMint() {
          require(!mintingFinished);
          _;
      }
      modifier onlyMinters() {
          require(minters[msg.sender] || msg.sender == owner);
          _;
      }

      function addMinter(address _addr) public onlyOwner {
          minters[_addr] = true;
      }

      function deleteMinter(address _addr) public onlyOwner {
          delete minters[_addr];
      }

      function mint(address _to, uint256 _amount)
          public onlyMinters canMint returns (bool)
      {
          require(_to != address(0));
          totalSupply = totalSupply.add(_amount);
          balances[_to] = balances[_to].add(_amount);
          emit Mint(_to, _amount);
          emit Transfer(address(0), _to, _amount);
          return true;
      }

      function finishMinting() public onlyOwner canMint returns (bool) {
          mintingFinished = true;
          emit MintFinished();
          return true;
      }
  }
  /**
   * @title Burnable Token
   * @dev Token that can be irreversibly burned (destroyed).
   */
  contract BurnableToken is MintableToken {
    event Burn(address indexed burner, uint256 value);
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
      _burn(msg.sender, _value);
    }
    function _burn(address _who, uint256 _value) internal {
      require(_value <= balances[_who]);
      // no need to require value <= totalSupply, since that would imply the
      // sender's balance is greater than the totalSupply, which *should* be an assertion failure

      balances[_who] = balances[_who].sub(_value);
      totalSupply = totalSupply.sub(_value);
      emit Burn(_who, _value);
      emit Transfer(_who, address(0), _value);
    }
  }
  /**
   * @title Pausable token
   * @dev StandardToken modified with pausable transfers.
   **/
  contract PausableToken is BurnableToken {

    function transfer(
      address _to,
      uint256 _value
    )
      public
      whenNotPaused
      returns (bool)
    {
      return super.transfer(_to, _value);
    }

    function transferFrom(
      address _from,
      address _to,
      uint256 _value
    )
      public
      whenNotPaused
      returns (bool)
    {
      return super.transferFrom(_from, _to, _value);
    }

    function approve(
      address _spender,
      uint256 _value
    )
      public
      whenNotPaused
      returns (bool)
    {
      return super.approve(_spender, _value);
    }

    function increaseApproval(
      address _spender,
      uint _addedValue
    )
      public
      whenNotPaused
      returns (bool success)
    {
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(
      address _spender,
      uint _subtractedValue
    )
      public
      whenNotPaused
      returns (bool success)
    {
      return super.decreaseApproval(_spender, _subtractedValue);
    }
  }
  /**
   * @title CLPT Token
   *
   * @dev Implementation of CLPT Token based on the basic standard token.
   */
  contract CappedToken is PausableToken {
      uint256 public cap;

      constructor(uint256 _cap) public {
          require(_cap > 0);
          cap = _cap;
      }

      function mint(address _to, uint256 _amount)
          public onlyMinters canMint returns (bool)
      {
          require(totalSupply.add(_amount) <= cap);
          return super.mint(_to, _amount);
      }
  }

  contract ParameterizedToken is CappedToken {
      string public name;
      string public symbol;
      uint256 public decimals;

      constructor(
          string _name,
          string _symbol,
          uint256 _decimals,
          uint256 _capIntPart
      ) public CappedToken(_capIntPart * 10**_decimals) {
          name = _name;
          symbol = _symbol;
          decimals = _decimals;
      }
  }



  contract TronChristmasCoin is ParameterizedToken {
      address private _lock_clpt_addr; // account for reserve
      string public version = '1.0.0';

      event LockAddrModification(
          address  previousLockClptAddr,
          address  newLockClptAddr
      );
      event DepositEvent(address from, address lockClptAddr, uint256 amount, string clptAddr);
      event WithdrawEvent(address lockClptAddr, uint256 amount, address to, string txHash);

      modifier onlyClptLocker() {
          require(msg.sender == _lock_clpt_addr);
          _;
      }
      function setLockAddr(address addr) public onlyOwner returns (bool) {
          require(addr != address(0));
          emit LockAddrModification(_lock_clpt_addr, addr);
          _lock_clpt_addr = addr;

          return true;
      }

      function getLockAddr() public view returns (address) {
          return _lock_clpt_addr;
      }

      // Tron token -> CLPT
      function depositTo(uint256 _value, string clptAddr) public returns (bool) {
          require(bytes(clptAddr).length <= 64);
          require(_lock_clpt_addr != address(0));

          // SafeMath.sub will throw if there is not enough balance.
          transfer(_lock_clpt_addr, _value);
          emit DepositEvent(msg.sender, _lock_clpt_addr, _value, clptAddr);
          return true;
      }

      // CLPT -> tron token
      // txHash -> tx hash on ColaPointChain
      function withdrawTo(
          address _to,
          uint256 _value,
          string txHash
      ) public onlyClptLocker returns (bool) {
          require(bytes(txHash).length <= 128);
          require(_lock_clpt_addr != address(0));
          //require(msg.sender == _lock_ruff_addr);

          transfer(_to, _value);
          emit WithdrawEvent(_lock_clpt_addr, _value, _to, txHash);
          return true;
      }

     constructor(
          string _name,
          string _symbol,
          uint256 _decimals,
          uint256 _capIntPart
      ) public ParameterizedToken(_name, _symbol, _decimals, _capIntPart) {
          _lock_clpt_addr = address(0);
      }
  }
  contract ChristmasCoin is TronChristmasCoin {
      constructor() public TronChristmasCoin("ChristmasCoin", "xmas", 14, 1000000000000) {}
  }