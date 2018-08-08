// File: contracts/StakeInterface.sol

contract StakeInterface {
  function hasStake(address _address) external view returns (bool);
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

// File: contracts/MainframeStake.sol

contract MainframeStake is Ownable, StakeInterface {
  using SafeMath for uint256;

  ERC20 token;
  uint256 public arrayLimit = 200;
  uint256 public totalDepositBalance;
  uint256 public requiredStake;
  mapping (address => uint256) public balances;

  struct Staker {
    uint256 stakedAmount;
    address stakerAddress;
  }

  mapping (address => Staker) public whitelist; // map of whitelisted addresses for efficient hasStaked check

  constructor(address tokenAddress) public {
    token = ERC20(tokenAddress);
    requiredStake = 1 ether; // ether = 10^18
  }

  /**
  * @dev Staking MFT for a node address
  * @param whitelistAddress representing the address of the node you want to stake for
  */

  function stake(address whitelistAddress) external returns (bool success) {
    require(whitelist[whitelistAddress].stakerAddress == 0x0);

    whitelist[whitelistAddress].stakerAddress = msg.sender;
    whitelist[whitelistAddress].stakedAmount = requiredStake;

    deposit(msg.sender, requiredStake);
    emit Staked(msg.sender, whitelistAddress);
    return true;
  }

  /**
  * @dev Unstake a staked node address, will remove from whitelist and refund stake
  * @param whitelistAddress representing the staked node address
  */

  function unstake(address whitelistAddress) external {
    require(whitelist[whitelistAddress].stakerAddress == msg.sender);

    uint256 stakedAmount = whitelist[whitelistAddress].stakedAmount;
    delete whitelist[whitelistAddress];

    withdraw(msg.sender, stakedAmount);
    emit Unstaked(msg.sender, whitelistAddress);
  }

  /**
  * @dev Deposit stake amount
  * @param fromAddress representing the address to deposit from
  * @param depositAmount representing amount being deposited
  */

  function deposit(address fromAddress, uint256 depositAmount) private returns (bool success) {
    token.transferFrom(fromAddress, this, depositAmount);
    balances[fromAddress] = balances[fromAddress].add(depositAmount);
    totalDepositBalance = totalDepositBalance.add(depositAmount);
    emit Deposit(fromAddress, depositAmount, balances[fromAddress]);
    return true;
  }

  /**
  * @dev Withdraw funds after unstaking
  * @param toAddress representing the stakers address to withdraw to
  * @param withdrawAmount representing stake amount being withdrawn
  */

  function withdraw(address toAddress, uint256 withdrawAmount) private returns (bool success) {
    require(balances[toAddress] >= withdrawAmount);
    token.transfer(toAddress, withdrawAmount);
    balances[toAddress] = balances[toAddress].sub(withdrawAmount);
    totalDepositBalance = totalDepositBalance.sub(withdrawAmount);
    emit Withdrawal(toAddress, withdrawAmount, balances[toAddress]);
    return true;
  }

  function balanceOf(address _address) external view returns (uint256 balance) {
    return balances[_address];
  }

  function totalStaked() external view returns (uint256) {
    return totalDepositBalance;
  }

  function hasStake(address _address) external view returns (bool) {
    return whitelist[_address].stakedAmount > 0;
  }

  function requiredStake() external view returns (uint256) {
    return requiredStake;
  }

  function setRequiredStake(uint256 value) external onlyOwner {
    requiredStake = value;
  }

  function setArrayLimit(uint256 newLimit) external onlyOwner {
    arrayLimit = newLimit;
  }

  function refundBalances(address[] addresses) external onlyOwner {
    require(addresses.length <= arrayLimit);
    for (uint256 i = 0; i < addresses.length; i++) {
      address _address = addresses[i];
      require(balances[_address] > 0);
      token.transfer(_address, balances[_address]);
      totalDepositBalance = totalDepositBalance.sub(balances[_address]);
      emit RefundedBalance(_address, balances[_address]);
      balances[_address] = 0;
    }
  }

  function emergencyERC20Drain(ERC20 _token) external onlyOwner {
    // owner can drain tokens that are sent here by mistake
    uint256 drainAmount;
    if (address(_token) == address(token)) {
      drainAmount = _token.balanceOf(this).sub(totalDepositBalance);
    } else {
      drainAmount = _token.balanceOf(this);
    }
    _token.transfer(owner, drainAmount);
  }

  function destroy() external onlyOwner {
    require(token.balanceOf(this) == 0);
    selfdestruct(owner);
  }

  event Staked(address indexed owner, address whitelistAddress);
  event Unstaked(address indexed owner, address whitelistAddress);
  event Deposit(address indexed _address, uint256 depositAmount, uint256 balance);
  event Withdrawal(address indexed _address, uint256 withdrawAmount, uint256 balance);
  event RefundedBalance(address indexed _address, uint256 refundAmount);
}