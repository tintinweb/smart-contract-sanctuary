pragma solidity ^0.4.24;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
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
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20 token which is being vested
   */
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param _token ERC20 token which is being vested
   */
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param _token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

contract TokenVestingPool is Claimable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // ERC20 token being held
  ERC20Basic public token;

  // Maximum amount of tokens to be distributed
  uint256 public totalFunds;

  // Tokens already distributed
  uint256 public distributedTokens;

  // List of beneficiaries added to the pool
  address[] public beneficiaries;

  // Mapping of beneficiary to TokenVesting contracts addresses
  mapping(address => address[]) public beneficiaryDistributionContracts;

  // Tracks the distribution contracts created by this contract.
  mapping(address => bool) private distributionContracts;

  event BeneficiaryAdded(
    address indexed beneficiary,
    address vesting,
    uint256 amount
  );

  modifier validAddress(address _addr) {
    require(_addr != address(0));
    require(_addr != address(this));
    _;
  }

  /**
   * @notice Contract constructor.
   * @param _token instance of an ERC20 token.
   * @param _totalFunds Maximum amount of tokens to be distributed among
   *        beneficiaries.
   */
  constructor(
    ERC20Basic _token,
    uint256 _totalFunds
  ) public validAddress(_token) {
    require(_totalFunds > 0);

    token = _token;
    totalFunds = _totalFunds;
    distributedTokens = 0;
  }

  /**
   * @notice Assigns a token release point to a beneficiary. A beneficiary can have
   *         many token release points.
   *         Example 1 - Lock-up mode:
   *           contract.addBeneficiary(
   *             `0x123..`,  // Beneficiary
   *             1533847025, // The vesting period starts this day
   *             604800,     // Tokens are released after one week
   *             604800,     // Duration of the release period. In this case, once the cliff
   *                         // period is finished, the beneficiary will receive the tokens.
   *             100         // Amount of tokens to be released
   *           )
   *         Example 2 - Vesting mode:
   *           contract.addBeneficiary(
   *             `0x123..`,  // Beneficiary
   *             1533847025, // The vesting period starts this day
   *             172800,     // Tokens are released after two weeks
   *             345600,     // The release period will start after the cliff period and
   *                         // it will last for two weeks. Tokens will be released uniformly
   *                         // during this period.
   *             100         // Amount of tokens to be released
   *           )
   *
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _amount amount of tokens to be released
   * @return address for the new TokenVesting contract instance.
   */
  function addBeneficiary(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _amount
  ) public onlyOwner validAddress(_beneficiary) returns (address) {
    require(_beneficiary != owner);
    require(_amount > 0);
    require(_duration >= _cliff);

    // Check there are sufficient funds and actual token balance.
    require(SafeMath.sub(totalFunds, distributedTokens) >= _amount);
    require(token.balanceOf(address(this)) >= _amount);

    if (!beneficiaryExists(_beneficiary)) {
      beneficiaries.push(_beneficiary);
    }

    // Bookkepping of distributed tokens
    distributedTokens = distributedTokens.add(_amount);

    address tokenVesting = new TokenVesting(
      _beneficiary,
      _start,
      _cliff,
      _duration,
      false // TokenVesting cannot be revoked
    );

    // Bookkeeping of distributions contracts per beneficiary
    beneficiaryDistributionContracts[_beneficiary].push(tokenVesting);
    distributionContracts[tokenVesting] = true;

    // Assign the tokens to the beneficiary
    token.safeTransfer(tokenVesting, _amount);

    emit BeneficiaryAdded(_beneficiary, tokenVesting, _amount);
    return tokenVesting;
  }

  /**
   * @notice Gets an array of all the distribution contracts for a given beneficiary.
   * @param _beneficiary address of the beneficiary to whom tokens will be transferred.
   * @return List of TokenVesting addresses.
   */
  function getDistributionContracts(
    address _beneficiary
  ) public view validAddress(_beneficiary) returns (address[]) {
    return beneficiaryDistributionContracts[_beneficiary];
  }

  /**
   * @notice Checks if a beneficiary was added to the pool at least once.
   * @param _beneficiary address of the beneficiary to whom tokens will be transferred.
   * @return true if beneficiary exists, false otherwise.
   */
  function beneficiaryExists(
    address _beneficiary
  ) internal view returns (bool) {
    return beneficiaryDistributionContracts[_beneficiary].length > 0;
  }
}