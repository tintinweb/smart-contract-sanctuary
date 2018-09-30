pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/TokenLocker.sol

contract TokenLocker is Ownable {
    
  mapping(address => uint256) public balance;
  mapping(address => uint256) public expireLockTimestamp;

  event LogRelease(address indexed holder, uint256 expireLockTimestamp, uint256 amount);
  event LogWithdraw(address from, address indexed token, uint amount);

  ERC20 public token;
    
  constructor(
    address[] _holders,
    uint256[] _amounts,
    uint256[] _expireLockTimestamps,
    ERC20 _token
  ) public {
    // revert if token address = 0
    require(address(_token) != 0, "Token address == 0");
    // revert if holders array is empty
    require(_holders.length != 0, "Holders array empty");
    // revert if amount array is empty
    require(_amounts.length != 0, "Amounts array empty");
    // revert if unlockTimeStamps array is empty
    require(_expireLockTimestamps.length != 0, "Expire timestamp array empty");
    // revert if holders array shorter or longer than amounts array
    require(_holders.length == _amounts.length, "Holders array length != amounts array length");
    // revert if amounts array shorter or longer than unlockTimeStamps array
    require(_amounts.length == _expireLockTimestamps.length, "Amounts array length != expire timestamp array length");
    
    token = _token;
    
    for(uint i = 0; i < _holders.length; i++) {
      // revert if one of the holders address is 0
      require(_holders[i] != 0, "Holder address == 0");
      // revert if one of the amounts is 0
      require(_amounts[i] != 0, "Amount to lock == 0");
      // revert if one of the expiration date is not in the future
      require(_expireLockTimestamps[i] > block.timestamp, "Expire timestamp == 0");
      balance[_holders[i]] = _amounts[i];
      expireLockTimestamp[_holders[i]] = _expireLockTimestamps[i];
    }
  }

  function release(address _to)
    internal
    returns(bool)
  {
    // revert if to = 0
    require(_to != 0, "Address _to == 0");
    // revert if the expire lock timestamp is not met
    require(block.timestamp >= expireLockTimestamp[_to], "Expire timestamp not met");
    uint256 amount = balance[_to];
    // revert if the claimer holder does not have any balance assigned
    require(amount != 0, "Amount == 0");
    uint256 contractTokenBalance = token.balanceOf(this);
    // revert if the token contract balance is >= to the total amount to be distributed
    require(contractTokenBalance >= amount, "Locker token balance < amount to release");
    balance[_to] = 0;
    token.transfer(_to, amount);
    emit LogRelease(_to, block.timestamp, amount);
    return true;
  }

  function withdraw(address _to, ERC20 _token)
    public
    onlyOwner
    returns(bool)
  {
    // revert if the passed token is 0
    require(address(_token) != 0, "Dropped token address == 0");
    // revert if owner attempt to withdraw the locked tokens
    require(_token != token, "Dropped token address == locked token address");
    // revert if recipient = 0
    require(_to != 0, "_to address == 0");
    uint256 airdroppedTokenAmount = _token.balanceOf(this);
    require(
      airdroppedTokenAmount > 0, "Locker dropped token balance == 0"); // revert if contract does not have any balance of the required token
    _token.transfer(_to, airdroppedTokenAmount);
    emit LogWithdraw(msg.sender, _token, airdroppedTokenAmount);
    return true;
  }

  function() public {
    release(msg.sender);
  }
}