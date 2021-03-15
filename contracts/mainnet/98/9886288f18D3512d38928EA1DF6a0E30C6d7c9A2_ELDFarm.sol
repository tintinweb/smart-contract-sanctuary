/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath mul error");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath div error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub error");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath add error");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath mod error");
    return a % b;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    function totalSupply() public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ILPToken is IERC20 {
  function getReserves() public returns (uint112, uint112, uint32);
}

contract ELDFarm {
  using SafeMath for uint;

  IERC20 constant eldToken = IERC20(0xf0C6521b1F8ad9C33a99Aaf056F6C6247A3862BA);
  ILPToken constant lpToken = ILPToken(0x54d5230d16033eb03ffbaB29FCc09Ac54Df6F812);

  uint constant blockPerDay = 5760;

  address admin;
  uint eldPrice = 9230; // decimal 6

  struct UserInfo {
    uint usdtAmount;
    uint lpTokenAmount;
    uint lastRewardBlock;
  }

  mapping(address => UserInfo) public userInfo;
  event Deposit(address indexed user, uint lpTokenAmount, uint usdtAmount);
  event Withdraw(address indexed user, uint lpTokenAmount);
  event Reward(address indexed user, uint eldAmount);
  event EmergencyWithdraw(address indexed user, uint lpTokenAmount);

  modifier onlyAdmin() {
    require(msg.sender == admin, 'onlyAdmin');
    _;
  }

  constructor() public {
    admin = msg.sender;
  }

  function setELDPrice(uint _price) external onlyAdmin {
    eldPrice = _price;
  }

  function deposit(uint _lpTokenAmount) external {
    require(_lpTokenAmount > 0, 'Invalid amount');
    require(lpToken.transferFrom(msg.sender, address(this), _lpTokenAmount), 'You are not approve lpToken to this contract');
    UserInfo storage user = userInfo[msg.sender];
    if (user.usdtAmount > 0 && block.number > user.lastRewardBlock) {
      uint rewardedBlock = block.number - user.lastRewardBlock;
      user.lastRewardBlock = block.number;
      uint pendingRewardBalance = getPendingReward(rewardedBlock, user.usdtAmount);
      safeELDTransfer(msg.sender, pendingRewardBalance);
      emit Reward(msg.sender, pendingRewardBalance);
    } else {
      user.lastRewardBlock = block.number;
    }
    user.lpTokenAmount = user.lpTokenAmount.add(_lpTokenAmount);
    uint usdtAmount = getUSDTFromLPToken(_lpTokenAmount);
    user.usdtAmount = user.usdtAmount.add(usdtAmount);
    emit Deposit(msg.sender, _lpTokenAmount, usdtAmount);
  }

  function withdraw() external {
    UserInfo storage user = userInfo[msg.sender];
    require (user.lpTokenAmount > 0, 'You have no farming');
    if (user.usdtAmount > 0 && block.number > user.lastRewardBlock) {
      uint rewardedBlock = block.number - user.lastRewardBlock;
      user.lastRewardBlock = block.number;
      uint userUsdtAmount = user.usdtAmount;
      user.usdtAmount = 0;
      uint userLPTokenAmount = user.lpTokenAmount;
      user.lpTokenAmount = 0;
      uint pendingRewardBalance = getPendingReward(rewardedBlock, userUsdtAmount);
      safeELDTransfer(msg.sender, pendingRewardBalance);
      safeLPTokenTransfer(msg.sender, userLPTokenAmount);
      emit Reward(msg.sender, pendingRewardBalance);
      emit Withdraw(msg.sender, userLPTokenAmount);
    }
  }

  function reward() public {
    UserInfo storage user = userInfo[msg.sender];
    require (user.lpTokenAmount > 0, 'You have no farming');
    if (user.usdtAmount > 0 && block.number > user.lastRewardBlock) {
      uint rewardedBlock = block.number - user.lastRewardBlock;
      user.lastRewardBlock = block.number;
      uint pendingRewardBalance = getPendingReward(rewardedBlock, user.usdtAmount);
      safeELDTransfer(msg.sender, pendingRewardBalance);
      emit Reward(msg.sender, pendingRewardBalance);
    }
  }

  function safeELDTransfer(address _to, uint256 _amount) internal {
    uint256 eldBalance = eldToken.balanceOf(address(this));
    require(eldBalance > 0, 'Contract is insufficient balance');
    if (_amount > eldBalance) {
      eldToken.transfer(_to, eldBalance);
    } else {
      eldToken.transfer(_to, _amount);
    }
  }

  function safeLPTokenTransfer(address _to, uint256 _amount) internal {
    uint256 lpBalance = lpToken.balanceOf(address(this));
    require(lpBalance > 0, 'Contract is insufficient balance');
    if (_amount > lpBalance) {
      lpToken.transfer(_to, lpBalance);
    } else {
      lpToken.transfer(_to, _amount);
    }
  }

  function getUSDTFromLPToken(uint _lpTokenAmount) public returns (uint) {
    uint totalSupply = lpToken.totalSupply();
    uint112 reserveUSDT;
    uint112 _reserveELD;
    uint32 _no;
    (reserveUSDT, _reserveELD, _no) = lpToken.getReserves();
    return _lpTokenAmount * uint(reserveUSDT) / totalSupply;
  }

  function getPendingReward(uint _rewardedBlock, uint _usdtAmount) public view returns (uint) {
    return _rewardedBlock * _usdtAmount * 1e12 / eldPrice * 1e6 * 5 / 1e3 / blockPerDay;
  }

  function emergencyWithdraw() public {
    UserInfo storage user = userInfo[msg.sender];
    require (user.lpTokenAmount > 0, 'You have no farming');
    user.lastRewardBlock = block.number;
    user.usdtAmount = 0;
    uint userLPTokenAmount = user.lpTokenAmount;
    user.lpTokenAmount = 0;
    safeLPTokenTransfer(msg.sender, userLPTokenAmount);
    emit EmergencyWithdraw(msg.sender, user.lpTokenAmount);
  }
}