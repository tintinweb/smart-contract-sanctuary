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

contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

contract TokenTimelockPool is Claimable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // ERC20 token being held
  ERC20Basic public token;

  // Timestamp (in seconds) when tokens can be released
  uint256 public releaseDate;

  // Maximum amount of tokens to be distributed
  uint256 public totalFunds;

  // Tokens already distributed
  uint256 public distributedTokens;

  // List of beneficiaries added to the pool
  address[] public beneficiaries;

  // Mapping of beneficiary to TokenTimelock contracts addresses
  mapping(address => address[]) public beneficiaryDistributionContracts;

  event BeneficiaryAdded(
    address indexed beneficiary,
    address timelock,
    uint256 amount
  );
  event Reclaim(uint256 amount);

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
   * @param _releaseDate Timestamp (in seconds) when tokens can be released.
   */
  constructor(
    ERC20Basic _token,
    uint256 _totalFunds,
    uint256 _releaseDate
  ) public validAddress(_token) {
    require(_totalFunds > 0);
    // solium-disable-next-line security/no-block-members
    require(_releaseDate > block.timestamp);

    token = _token;
    totalFunds = _totalFunds;
    distributedTokens = 0;
    releaseDate = _releaseDate;
  }

  /**
   * @notice Adds a beneficiary that will be allowed to extract the tokens after
   *         the release date.
   * @notice Example:
             addBeneficiary(`0x123..`, 100)
             Will create a TokenTimelock instance on which if the `release()` method
             is called after the release date (specified in this contract constructor),
             the amount of tokens (100) will be transferred to the
             beneficiary (`0x123..`).
   * @dev The `msg.sender` must be the owner of the contract.
   * @param _beneficiary Beneficiary that will receive the tokens after the
   * release date.
   * @param _amount of tokens to be released.
   * @return address for the new TokenTimelock contract instance.
   */
  function addBeneficiary(
    address _beneficiary,
    uint256 _amount
  ) public onlyOwner validAddress(_beneficiary) returns (address) {
    require(_beneficiary != owner);
    require(_amount > 0);
    // solium-disable-next-line security/no-block-members
    require(block.timestamp < releaseDate);

    // Check there are sufficient funds and actual token balance.
    require(SafeMath.sub(totalFunds, distributedTokens) >= _amount);
    require(token.balanceOf(address(this)) >= _amount);

    if (!beneficiaryExists(_beneficiary)) {
      beneficiaries.push(_beneficiary);
    }

    // Bookkepping of distributed tokens
    distributedTokens = distributedTokens.add(_amount);

    address tokenTimelock = new TokenTimelock(
      token,
      _beneficiary,
      releaseDate
    );

    // Bookkeeping of distributions contracts per beneficiary
    beneficiaryDistributionContracts[_beneficiary].push(tokenTimelock);

    // Assign the tokens to the beneficiary
    token.safeTransfer(tokenTimelock, _amount);

    emit BeneficiaryAdded(_beneficiary, tokenTimelock, _amount);
    return tokenTimelock;
  }

  /**
   * @notice Transfers the remaining tokens that were not locked for any
   *         beneficiary to the owner of this contract.
   * @dev The `msg.sender` must be the owner of the contract.
   * @return true if tokens were reclaimed successfully, reverts otherwise.
   */
  function reclaim() public onlyOwner returns (bool) {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp > releaseDate);
    uint256 reclaimableAmount = token.balanceOf(address(this));

    token.safeTransfer(owner, reclaimableAmount);
    emit Reclaim(reclaimableAmount);
    return true;
  }

  /**
   * @notice Gets an array of all the distribution contracts for a given beneficiary.
   * @param _beneficiary address of the beneficiary to whom tokens will be transferred.
   * @return List of TokenTimelock addresses.
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