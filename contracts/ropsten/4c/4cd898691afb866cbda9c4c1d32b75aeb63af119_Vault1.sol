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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

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
//   function renounceOwnership() public onlyOwner {
//     emit OwnershipRenounced(owner);
//     owner = address(0);
//   }

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
contract Vault1 is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;
  string public name;
  event Released(uint256 amount);
  event Revoked();
  event RegretdToOwner();
  event RegretdToBeneficiary();

  // beneficiary of tokens after they are released
  address public beneficiary;

  mapping (address => uint256) public released;
  uint256 public firstReleaseTime = 1577836800;
  uint256 secondReleaseTime = 1609459200;
  uint256 thirdReleaseTime = 1640995200;
  uint256 fourthReleaseTime = 1672531200;
  uint256 fifthReleaseTime = 1704067200;
  mapping (address => mapping (uint256 => bool)) public hasReleased;
  uint256[5] public allReleaseTime = [firstReleaseTime, secondReleaseTime, thirdReleaseTime, fourthReleaseTime, fifthReleaseTime];
  constructor(
    address _beneficiary,
    string _name
  )
    public
  {
    require(_beneficiary != address(0x0));
    beneficiary = _beneficiary;
    name = _name;
  }
  
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);
    if (now >= firstReleaseTime && now < secondReleaseTime) {
        return hasReleased[token][firstReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= secondReleaseTime && now < thirdReleaseTime) {
        return hasReleased[token][secondReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= thirdReleaseTime && now < fourthReleaseTime) {
        return hasReleased[token][thirdReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= fourthReleaseTime && now < fifthReleaseTime) {
        return hasReleased[token][fourthReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= fifthReleaseTime) {
        return hasReleased[token][fifthReleaseTime] ? 0 : totalBalance.div(5);
    }
    return 0;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public onlyOwner {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);
    updateReleasedState(token);
    emit Released(unreleased);
  }
  
  function updateReleasedState(ERC20Basic token) internal {
    if (now >= firstReleaseTime && now < secondReleaseTime && !hasReleased[token][firstReleaseTime]) {
        hasReleased[token][firstReleaseTime] = true;
    }
    else if (now >= secondReleaseTime && now < thirdReleaseTime && !hasReleased[token][secondReleaseTime]) {
        hasReleased[token][secondReleaseTime] = true;
    }
    else if (now >= thirdReleaseTime && now < fourthReleaseTime && !hasReleased[token][thirdReleaseTime]) {
        hasReleased[token][thirdReleaseTime] = true;
    }
    else if (now >= fourthReleaseTime && now < fifthReleaseTime && !hasReleased[token][fourthReleaseTime]) {
        hasReleased[token][fourthReleaseTime] = true;
    }
    else if (now >= fifthReleaseTime && !hasReleased[token][fifthReleaseTime]) {
        hasReleased[token][fifthReleaseTime] = true;
    }
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    uint256 count = 0;
    require(balance > 0);
    for (uint i=0; i<allReleaseTime.length; i++) {
        if (now >= allReleaseTime[i] && !hasReleased[token][allReleaseTime[i]]) {
            count++;
            hasReleased[token][allReleaseTime[i]] = true;
        }
    }
    uint256 shouldRevoke = balance.add(released[token]);
    shouldRevoke = shouldRevoke.div(5).mul(count);
    released[token] = released[token].add(shouldRevoke);

    token.safeTransfer(owner, shouldRevoke);
    emit Revoked();
  }
  
  function revokableAmount(ERC20Basic token) view public onlyOwner returns(uint256) {
    uint256 balance = token.balanceOf(this);
    uint256 count = 0;
    for (uint i=0; i<allReleaseTime.length; i++) {
        if (now >= allReleaseTime[i] && !hasReleased[token][allReleaseTime[i]]) {
            count++;
        }
    }
    uint256 shouldRevoke = balance.add(released[token]);
    shouldRevoke = shouldRevoke.div(5).mul(count);
    return shouldRevoke;
  }
  
  function regretToOwner(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    token.safeTransfer(owner, balance);
    emit RegretdToOwner();
  }
  
  function regretToBeneficiary(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    token.safeTransfer(beneficiary, balance);
    emit RegretdToBeneficiary();
  }
}