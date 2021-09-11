//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract EulerStaking is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 pendingRewards;
    uint256 lastClaim;
    bool exists;
  }

  struct GetUserInfo {
    uint256 amount;
    uint256 pendingRewards;
    uint256 withdrawAvaliable;
    uint256 eulerPerBlock;
    uint256 tvl;
  }

  struct PoolInfo {
    uint256 lastRewardBlock;
    uint256 accEulerPerShare;
    uint256 depositedAmount;
    uint256 rewardsAmount;
    uint256 lockupDuration;
  }

  uint256 public initialLockupDuration = 30 days;
  uint256 public constant maxFee = 10000;

  IERC20 public euler;
  uint256 public eulerTxFee = 100;
  uint256 public eulerPerBlock = uint256(1 ether);
  uint256 public minDepositAmount = 0;
  uint256 public maxDepositAmount = type(uint256).max;

  PoolInfo public poolInfo;
  mapping(address => UserInfo) public userInfo;
  address[] private users;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event SetEulerPerBlock(address indexed user, uint256 newEulerPerBlock);
  event SetMinDepositAmount(address indexed user, uint256 newMinDepositAmount);
  event SetMaxDepositAmount(address indexed user, uint256 newMaxDepositAmount);
  event SetEulerTxFee(address indexed user, uint256 newEulerTxFee);
  event SetLockupDuration(address indexed user, uint256 newLockupDuration);
  event StartStaking(address indexed user, uint256 startBlock);
  event SetEulerToken(address indexed user,address token);

  function addPool(uint256 _lockupDuration) internal {
    poolInfo = PoolInfo({
        lastRewardBlock: 0,
        accEulerPerShare: 0,
        depositedAmount: 0,
        rewardsAmount: 0,
        lockupDuration: _lockupDuration
    });
  }

  function setEulerToken(IERC20 _euler) external onlyOwner {
    require(address(_euler) != address(0), "Token address can't be zero");
    require(address(euler) == address(0), "Token already set!");
    euler = _euler;
    addPool(initialLockupDuration);
    emit SetEulerToken(msg.sender, address(_euler));
  }

  function startStaking(uint256 startBlock) external onlyOwner {
    require(
        poolInfo.lockupDuration == initialLockupDuration && poolInfo.lastRewardBlock == 0,
        "Staking already started"
    );

    poolInfo.lastRewardBlock = startBlock;
    emit StartStaking(msg.sender, startBlock);
  }

  function setLockupDuration(uint256 _lockupDuration) external onlyOwner {
    poolInfo.lockupDuration = _lockupDuration;
    emit SetLockupDuration(msg.sender, _lockupDuration);
  }

  function setEulerPerBlock(uint256 _eulerPerBlock) external onlyOwner {
    require(_eulerPerBlock > 0, "EULER per block should be greater than 0!");

    updatePool();
    eulerPerBlock = _eulerPerBlock;
    emit SetEulerPerBlock(msg.sender, _eulerPerBlock);
  }

  function setMinDepositAmount(uint256 _amount) external onlyOwner {
    require(_amount > 0, "invalid value");

    minDepositAmount = _amount;
    emit SetMinDepositAmount(msg.sender, _amount);
  }

  function setMaxDepositAmount(uint256 _amount) external onlyOwner {
    require(
      _amount > minDepositAmount,
      "invalid value, should be greater than mininum amount"
    );

    maxDepositAmount = _amount;
    emit SetMaxDepositAmount(msg.sender, _amount);
  }

  function setEulerTxFee(uint256 _fee) external onlyOwner {
    require(_fee < 10000, "invalid fee");

    eulerTxFee = _fee;
    emit SetEulerTxFee(msg.sender, _fee);
  }

  function pendingRewards(address _user) private view returns (uint256) {
    require(
      poolInfo.lastRewardBlock > 0 &&
        block.number >= poolInfo.lastRewardBlock,
      "Staking not yet started"
    );
    UserInfo storage user = userInfo[_user];
    uint256 accEulerPerShare = poolInfo.accEulerPerShare;
    uint256 depositedAmount = poolInfo.depositedAmount;
    if (block.number > poolInfo.lastRewardBlock && depositedAmount != 0) {

      uint256 multiplier = block.number.sub(poolInfo.lastRewardBlock);
      uint256 eulerReward = multiplier.mul(eulerPerBlock);

      accEulerPerShare = accEulerPerShare.add(
        eulerReward.mul(1e12).div(depositedAmount)
      );
    }
    return
      user.amount.mul(accEulerPerShare).div(1e12).sub(user.rewardDebt).add(
        user.pendingRewards
      );
  }

  function getUserInfo(address _user)
    public
    view
    returns (GetUserInfo memory) {

        UserInfo storage user = userInfo[_user];

        GetUserInfo memory userAux;

        userAux.amount = user.amount;

        userAux.withdrawAvaliable = 0;

        if(user.lastClaim > 0) {

            userAux.withdrawAvaliable = user.lastClaim + poolInfo.lockupDuration;
        }

        userAux.eulerPerBlock = eulerPerBlock;

        userAux.tvl = poolInfo.depositedAmount;

        userAux.pendingRewards = pendingRewards(_user);

        return userAux;
  }

  function getTotalUsers() external view
    returns (uint256) {

    return users.length;
  }

  function getUserInfoByPosition(uint256 position) external view
    returns (GetUserInfo memory) {

        require(position < users.length, 'The position is not less than the size of users');

        address user = users[position];

        return getUserInfo(user);
  }

  function updatePool() internal {
    require(
      poolInfo.lastRewardBlock > 0 &&
        block.number >= poolInfo.lastRewardBlock,
      "Staking not yet started"
    );

    if (block.number <= poolInfo.lastRewardBlock) {
      return;
    }
    uint256 depositedAmount = poolInfo.depositedAmount;
    if (poolInfo.depositedAmount == 0) {
      poolInfo.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = block.number.sub(poolInfo.lastRewardBlock);
    uint256 eulerReward = multiplier.mul(eulerPerBlock);

    poolInfo.rewardsAmount = poolInfo.rewardsAmount.add(eulerReward);
    poolInfo.accEulerPerShare = poolInfo.accEulerPerShare.add(
      eulerReward.mul(1e12).div(depositedAmount)
    );
    poolInfo.lastRewardBlock = block.number;
  }

  function deposit(uint256 amount) external {

    UserInfo storage user = userInfo[msg.sender];

    uint256 sumAmount = amount + user.amount;

    require(
      sumAmount >= minDepositAmount && sumAmount < maxDepositAmount,
      "invalid deposit amount"
    );

    updatePool();
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(poolInfo.accEulerPerShare).div(1e12).sub(
        user.rewardDebt
      );
      if (pending > 0) {
        user.pendingRewards = user.pendingRewards.add(pending);
      }
    }
    if (amount > 0) {
      euler.safeTransferFrom(address(msg.sender), address(this), amount);
      // Lost 1% fee from transaction
      amount = amount.sub(amount.mul(eulerTxFee).div(maxFee));
      user.amount = user.amount.add(amount);
      poolInfo.depositedAmount = poolInfo.depositedAmount.add(amount);
    }
    user.rewardDebt = user.amount.mul(poolInfo.accEulerPerShare).div(1e12);
    user.lastClaim = block.timestamp;

    if(!user.exists) {
        users.push(msg.sender);
        user.exists = true;
    }

    emit Deposit(msg.sender, amount);
  }

  function withdraw(uint256 amount) public {
    UserInfo storage user = userInfo[msg.sender];
    require(
      block.timestamp > user.lastClaim + poolInfo.lockupDuration,
      "You cannot withdraw yet!"
    );
    require(amount > 0, "The amount to withdraw cannot be zero!");
    require(user.amount >= amount, "Withdrawing more than you have!");
    updatePool();
    uint256 pending = user.amount.mul(poolInfo.accEulerPerShare).div(1e12).sub(
      user.rewardDebt
    );
    if (pending > 0) {
      user.pendingRewards = user.pendingRewards.add(pending);
    }
    if (amount > 0) {
      euler.safeTransfer(address(msg.sender), amount);
      user.amount = user.amount.sub(amount);
      poolInfo.depositedAmount = poolInfo.depositedAmount.sub(amount);
    }
    user.rewardDebt = user.amount.mul(poolInfo.accEulerPerShare).div(1e12);
    emit Withdraw(msg.sender, amount);

    if(user.amount == 0) {

        user.exists = false;

        removeUser(msg.sender);
    }
  }

  function withdrawAll() external {
    UserInfo storage user = userInfo[msg.sender];

    withdraw(user.amount);
  }

  function claim() external {
    UserInfo storage user = userInfo[msg.sender];
    updatePool();
    uint256 pending = user.amount.mul(poolInfo.accEulerPerShare).div(1e12).sub(
      user.rewardDebt
    );
    if (pending > 0 || user.pendingRewards > 0) {
      user.pendingRewards = user.pendingRewards.add(pending);
      uint256 claimedAmount = safeEulerTransfer(
        msg.sender,
        user.pendingRewards
      );
      emit Claim(msg.sender, claimedAmount);
      user.pendingRewards = user.pendingRewards.sub(claimedAmount);
      user.lastClaim = block.timestamp;
      poolInfo.rewardsAmount = poolInfo.rewardsAmount.sub(claimedAmount);
    }
    user.rewardDebt = user.amount.mul(poolInfo.accEulerPerShare).div(1e12);
  }

  function removeUser(address user) internal {

    uint index = find(user);

    for (uint i = index; i < users.length - 1; i++) {

        users[i] = users[i + 1];
    }

    users.pop();
  }

  function find(address user) internal view returns(uint)  {

    uint i = 0;

    while (users[i] != user) i++;

    return i;
  }

  function safeEulerTransfer(
    address to,
    uint256 amount
  ) internal returns (uint256) {
    uint256 _bal = euler.balanceOf(address(this));
    if (amount > poolInfo.rewardsAmount) amount = poolInfo.rewardsAmount;
    if (amount > _bal) amount = _bal;
    euler.safeTransfer(to, amount);
    return amount;
  }
}