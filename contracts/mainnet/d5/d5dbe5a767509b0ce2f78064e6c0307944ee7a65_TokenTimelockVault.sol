pragma solidity ^0.4.24;


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
}








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



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
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


contract Lockable is Ownable {

    bool public isLocked = false;

    event Locked();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function lock() onlyOwner public {
        require(!isLocked);

        emit Locked();

        isLocked = true;
    }

    modifier notLocked() {
        require(!isLocked);
        _;
    }
}

contract TokenTimelockVault is Ownable, Lockable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event Invested(address owner, uint balance);
    event Released(uint256 amount);

    mapping(address => TimeEnvoy) internal owners;

    struct TimeEnvoy {
        address owner;
        uint releaseTime;
        uint balance;
        bool released;
    }

    function addOwners(address[] _owners, uint[] _releaseTimes, uint[] _balances) public onlyOwner notLocked {
        require(_owners.length > 0);
        require(_owners.length == _releaseTimes.length);
        require(_owners.length == _balances.length);
        for (uint i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = TimeEnvoy({
                owner : _owners[i],
                releaseTime : _releaseTimes[i],
                balance : _balances[i],
                released : false});
            emit Invested(_owners[i], _balances[i]);
        }
    }

    function addOwner(address _owner, uint _releaseTime, uint _balance) public onlyOwner notLocked {
        owners[owner] = TimeEnvoy({
            owner : _owner,
            releaseTime : _releaseTime,
            balance : _balance,
            released : false});

        emit Invested(_owner, _balance);
    }

    function release(ERC20Basic token, address _owner) public {
        TimeEnvoy storage owner = owners[_owner];
        require(!owner.released);

        uint256 unreleased = releasableAmount(_owner);

        require(unreleased > 0);

        owner.released = true;
        token.safeTransfer(owner.owner, owner.balance);

        emit Released(unreleased);
    }

    function releasableAmount(address _owner) public view returns (uint256){
        if (_owner == address(0)) {
            return 0;
        }
        TimeEnvoy storage owner = owners[_owner];
        if (owner.released) {
            return 0;
        } else if (block.timestamp >= owner.releaseTime) {
            return owner.balance;
        } else {
            return 0;
        }
    }

    function ownedBalance(address _owner) public view returns (uint256){
        TimeEnvoy storage owner = owners[_owner];
        return owner.balance;
    }
}