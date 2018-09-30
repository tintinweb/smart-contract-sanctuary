pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7b091e1618143b49">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    // solium-disable-next-line security/no-send
    assert(owner.send(address(this).balance));
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

// File: contracts/RTELockingVault.sol

/**
 * @title RTELockingVault
 * @dev For RTE token holders to lock up their tokens for incentives
 */
contract RTELockingVault is HasNoEther, CanReclaimToken {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  ERC20 public token;

  bool public vaultUnlocked;

  uint256 public cap;

  uint256 public minimumDeposit;

  uint256 public tokensDeposited;

  uint256 public interestRate;

  uint256 public vaultDepositDeadlineTime;

  uint256 public vaultUnlockTime;

  uint256 public vaultLockDays;

  address public rewardWallet;

  mapping(address => uint256) public lockedBalances;

  /**
   * @dev Locked tokens event
   * @param _investor Investor address
   * @param _value Tokens locked
   */
  event TokenLocked(address _investor, uint256 _value);

  /**
   * @dev Withdrawal event
   * @param _investor Investor address
   * @param _value Tokens withdrawn
   */
  event TokenWithdrawal(address _investor, uint256 _value);

  constructor (
    ERC20 _token,
    uint256 _cap,
    uint256 _minimumDeposit,
    uint256 _interestRate,
    uint256 _vaultDepositDeadlineTime,
    uint256 _vaultUnlockTime,
    uint256 _vaultLockDays,
    address _rewardWallet
  )
    public
  {
    require(_vaultDepositDeadlineTime > now);
    require(_vaultDepositDeadlineTime < _vaultUnlockTime);

    vaultUnlocked = false;

    token = _token;
    cap = _cap;
    minimumDeposit = _minimumDeposit;
    interestRate = _interestRate;
    vaultDepositDeadlineTime = _vaultDepositDeadlineTime;
    vaultUnlockTime = _vaultUnlockTime;
    vaultLockDays = _vaultLockDays;
    rewardWallet = _rewardWallet;
  }

  /**
   * @dev Deposit and lock tokens
   * @param _amount Amount of tokens to transfer and lock
   */
  function lockToken(uint256 _amount) public {
    require(_amount >= minimumDeposit);
    require(now < vaultDepositDeadlineTime);
    require(tokensDeposited.add(_amount) <= cap);

    token.safeTransferFrom(msg.sender, address(this), _amount);

    lockedBalances[msg.sender] = lockedBalances[msg.sender].add(_amount);

    tokensDeposited = tokensDeposited.add(_amount);

    emit TokenLocked(msg.sender, _amount);
  }

  /**
   * @dev Withdraw locked tokens
   */
  function withdrawToken() public {
    require(vaultUnlocked);

    uint256 interestAmount = (interestRate.mul(lockedBalances[msg.sender]).div(36500)).mul(vaultLockDays);

    uint256 withdrawAmount = (lockedBalances[msg.sender]).add(interestAmount);
    require(withdrawAmount > 0);

    lockedBalances[msg.sender] = 0;

    token.safeTransfer(msg.sender, withdrawAmount);

    emit TokenWithdrawal(msg.sender, withdrawAmount);
  }

  /**
   * @dev Force Withdraw locked tokens
   */
  function forceWithdrawToken(address _forceAddress) public onlyOwner {
    require(vaultUnlocked);

    uint256 interestAmount = (interestRate.mul(lockedBalances[_forceAddress]).div(36500)).mul(vaultLockDays);

    uint256 withdrawAmount = (lockedBalances[_forceAddress]).add(interestAmount);
    require(withdrawAmount > 0);

    lockedBalances[_forceAddress] = 0;

    token.safeTransfer(_forceAddress, withdrawAmount);

    emit TokenWithdrawal(_forceAddress, withdrawAmount);
  }

  /**
   * @dev Irreversibly finalizes and unlocks the vault - only owner of contract can call this
   */
  function finalizeVault() public onlyOwner {
    require(!vaultUnlocked);
    require(now >= vaultUnlockTime);

    vaultUnlocked = true;

    uint256 bonusTokens = ((tokensDeposited.mul(interestRate)).div(36500)).mul(vaultLockDays);

    token.safeTransferFrom(rewardWallet, address(this), bonusTokens);
  }
}