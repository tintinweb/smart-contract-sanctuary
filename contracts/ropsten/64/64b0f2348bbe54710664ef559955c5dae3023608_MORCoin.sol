pragma solidity ^0.5.1;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract LockRequestable {
    /// @notice  the count of all invocations of `generateLockId`.
    uint256 public lockRequestCount;
    bool public isLocked = false;

    constructor() public {
        lockRequestCount = 0;
    }
    
    /** @notice  Returns a fresh unique identifier.
      *
      * @dev the generation scheme uses three components.
      * First, the blockhash of the previous block.
      * Second, the deployed address.
      * Third, the next value of the counter.
      * This ensure that identifiers are unique across all contracts
      * following this scheme, and that future identifiers are
      * unpredictable.
      *
      * @return a 32-byte unique identifier.
      */
    function generateLockId() internal returns (bytes32 lockId) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), ++lockRequestCount));
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) view public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
    uint256 _allowance = allowed[_from][msg.sender];
    require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool){
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) view public returns (uint256 remaining){
    return allowed[_owner][_spender];
  }
}

contract ERC20Impl {
    struct PendingPrint {
        address receiver;
        uint256 value;
    }
    mapping(address => bool) blackListMapping;
    mapping (bytes32 => PendingPrint) public pendingPrintMap;
    
    event UpdateBlackListMapping(address indexed _trader, bool _value);
    event IsLocked(bool _isLock);
    event Burn(address indexed _burner, uint _value);
    event PrintingLocked(bytes32 _lockId, address _receiver, uint256 _value);
    event PrintingConfirmed(bytes32 _lockId, address _receiver, uint256 _value);    
}

contract MORCoin is StandardToken, Ownable, LockRequestable, ERC20Impl {
    string  public  constant name = "MOR Coin";
    string  public  constant symbol = "mcoin";
    uint    public  constant decimals = 18;

    // uint    public  saleStartTime;
    // uint    public  saleEndTime;
    // address public  tokenSaleContract;

    modifier onlyWhenTransferEnabled() {
        // if( now <= saleEndTime && now >= saleStartTime ) {
        //     require( msg.sender == tokenSaleContract );
        // }
        require(isLocked == false);
        _;
    }

    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }
    
    modifier notInBlackList(address to) {
        require(blackListMapping[msg.sender] == false);
        require(blackListMapping[to] == false);
        _;
    }

    constructor(uint tokenTotalAmount, address admin) public {
        balances[msg.sender] = tokenTotalAmount;
        totalSupply = tokenTotalAmount;
        emit Transfer(address(0x0), msg.sender, tokenTotalAmount);
        transferOwnership(admin);
    }

    function transfer(address _to, uint _value)
        onlyWhenTransferEnabled()
        notInBlackList(_to)
        validDestination(_to)
        public
        returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        onlyWhenTransferEnabled()
        notInBlackList(_to)
        validDestination(_to)
        public
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value)
        notInBlackList(_spender)
        public
        returns (bool) {
        return super.approve(_spender, _value);
    }

    function burn(uint _value) public
        onlyWhenTransferEnabled()
        notInBlackList(msg.sender)
        returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public
        onlyWhenTransferEnabled()
        notInBlackList(msg.sender)
        returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }
    
    function updateBlackListTrader(address _trader, bool _value) onlyOwner public returns (bool isBlackList) {
        blackListMapping[_trader] = _value;
        emit UpdateBlackListMapping(_trader, _value);
        return _value;
    }
    
    function checkBlackListAddress(address _trader) view public returns (bool isBlackList) {
        return blackListMapping[_trader];
    }
    
    function updateLock(bool _value) onlyOwner public returns (bool) {
        isLocked = _value;
        emit IsLocked(_value);
        return _value;
    }
    
    /** @notice  Requests an increase in the token supply, with the newly created
      * tokens to be added to the balance of the specified account.
      *
      * @dev  Returns a unique lock id associated with the request.
      *
      * @param  _receiver  The receiving address of the print, if confirmed.
      * @param  _value  The number of tokens to add to the total supply and the
      * balance of the receiving address, if confirmed.
      *
      * @return  lockId  A unique identifier for this request.
      */
    function requestPrint(address _receiver, uint256 _value) public returns (bytes32 lockId) {
        require(_receiver != address(0));

        lockId = generateLockId();

        pendingPrintMap[lockId] = PendingPrint({
            receiver: _receiver,
            value: _value
        });

        emit PrintingLocked(lockId, _receiver, _value);
    }

    /** @notice  Confirms a pending increase in the token supply.
      *
      * @dev  When called by the coin owner with a lock id associated with a
      * pending increase, the amount requested to be printed in the print request
      * is printed to the receiving address specified in that same request.
      * NOTE: this function will not execute any print that would overflow the
      * total supply, but it will not revert either.
      *
      * @param  _lockId  The identifier of a pending print request.
      */
    function confirmPrint(bytes32 _lockId) public onlyOwner {
        PendingPrint memory print = pendingPrintMap[_lockId];

        address receiver = print.receiver;
        require (receiver != address(0));
        uint256 value = print.value;

        delete pendingPrintMap[_lockId];

        uint256 newSupply = totalSupply + value;
        if (newSupply >= totalSupply) {
          totalSupply = newSupply;
          balances[receiver] = balances[receiver].add(value);

          emit PrintingConfirmed(_lockId, receiver, value);
          emit Transfer(address(0), receiver, value);
        }
    }
}