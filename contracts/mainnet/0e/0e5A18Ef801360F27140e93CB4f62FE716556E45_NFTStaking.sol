// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract NFTStaking {

  bool public active;
  uint256 public startTime;
  uint256 public cutoffTime;
  address public governance;
  IERC20 internal immutable NFTProtocol;
  struct rewardSchedule {
    uint64 days30;
    uint64 days45;
    uint64 days60;
    uint64 days90;
  }
  rewardSchedule public rewardMultiplier = rewardSchedule({
    days30: 2,
    days45: 3,
    days60: 5,
    days90: 10
  });

  mapping(address=>uint256) public userDepositTotal;
  mapping(address=>uint256) public numUserDeposits;
  address[] public allStakingUsers;
  struct userDeposit {
    uint256 amountNFT;
    uint256 depositTime;
  }
  mapping(address=>userDeposit[]) public userDeposits;

  uint256 public totalDeposited;
  uint256 public userFunds;
  uint256 public stakingFunds;
  uint256 public constant maxContractStakingCapacity = 7500000 * 1 ether;
  uint256 public constant userMaxDeposits = 5;
  uint256 public constant totalRewardSupply = 750000 * 1 ether;
  uint256 public constant minStakingAmount = 10000 * 1 ether;
  uint256 public constant maxStakingAmount = 1000000 * 1 ether;

  constructor (address nftAddress) public {
    //NFTProtocol = IERC20(0xB5a9f4270157BeDe68070df7A070525644fc782D); // Kovan
    //NFTProtocol = IERC20(0xcB8d1260F9c92A3A545d409466280fFdD7AF7042); // Mainnet
    NFTProtocol = IERC20(nftAddress);
    governance = msg.sender;
  }

  function deposit(uint256 depositAmount) external {
    require(NFTProtocol.balanceOf(msg.sender) >= depositAmount, "not enough NFT tokens");
    require(active == true, "staking has not begun yet");
    require(depositAmount >= minStakingAmount, "depositAmount too low");
    require(depositAmount <= maxStakingAmount, "depositAmount too high");
    require(numUserDeposits[msg.sender] < userMaxDeposits, "users can only have 5 total deposits");
    require(totalDeposited < maxContractStakingCapacity, "contract staking capacity exceeded");
    require(block.timestamp < cutoffTime, "contract staking deposit time period over");
    if (userDepositTotal[msg.sender] == 0) allStakingUsers.push(msg.sender);
    userDepositTotal[msg.sender] += depositAmount;
    totalDeposited += depositAmount;
    userFunds += depositAmount;
    userDeposits[msg.sender].push(userDeposit({
      amountNFT: depositAmount,
      depositTime: block.timestamp
    }));
    numUserDeposits[msg.sender] = numUserDeposits[msg.sender] + 1;
    NFTProtocol.transferFrom(msg.sender, address(this), depositAmount);
  }

  event WithdrawAll(address userAddress, uint256 principal, uint256 yield, uint256 userFundsRemaining, uint256 stakingFundsRemaining);
  function withdrawAll() public {
    require(active == true, "staking has not begun yet");
    require(userDepositTotal[msg.sender] > 0, "nothing to withdraw");
    uint256 withdrawalAmount = userDepositTotal[msg.sender];
    uint256 userYield = getUserYield(msg.sender);
    userDepositTotal[msg.sender] = 0;
    userFunds -= withdrawalAmount;
    stakingFunds -= userYield;
    for (uint256 i = 0; i < userDeposits[msg.sender].length; i++) {
        delete userDeposits[msg.sender][i];
    }
    NFTProtocol.transfer(msg.sender, withdrawalAmount);
    NFTProtocol.transfer(msg.sender, userYield);
    emit WithdrawAll(msg.sender, withdrawalAmount, userYield, userFunds, stakingFunds);
  }

  event WithdrawPrincipal(address userAddress, uint256 principal, uint256 userFundsRemaining);
  function withdrawPrincipal() public {
    require(active == true, "staking has not begun yet");
    uint256 withdrawalAmount = userDepositTotal[msg.sender];
    userDepositTotal[msg.sender] = 0;
    userFunds -= withdrawalAmount;
    for (uint256 i = 0; i < userDeposits[msg.sender].length; i++) {
        delete userDeposits[msg.sender][i];
    }
    NFTProtocol.transfer(msg.sender, withdrawalAmount);
    emit WithdrawPrincipal(msg.sender, withdrawalAmount, userFunds);
  }

  event StakingBegins(uint256 timestamp, uint256 stakingFunds);
  function beginStaking() external {
    require(msg.sender == governance, "only governance can begin staking");
    require(NFTProtocol.balanceOf(address(this)) == totalRewardSupply, "not enough staking rewards");
    active = true;
    startTime = block.timestamp;
    cutoffTime = startTime + 60 days;
    stakingFunds = totalRewardSupply;
    emit StakingBegins(startTime, stakingFunds);
  }

  function getYieldMultiplier(uint256 daysStaked) public view returns(uint256) {
    if (daysStaked >= 90) return rewardMultiplier.days90;
    if (daysStaked >= 60) return rewardMultiplier.days60;
    if (daysStaked >= 45) return rewardMultiplier.days45;
    if (daysStaked >= 30) return rewardMultiplier.days30;
    return 0;
  }

  function getUserYield(address userAddress) public view returns(uint256) {
    uint256 totalYield;
    for (uint256 i = 0; i < userDeposits[userAddress].length; i++) {
      uint256 daysStaked = (block.timestamp - userDeposits[userAddress][i].depositTime) / 1 days;
      uint256 yieldMultiplier = getYieldMultiplier(daysStaked);
      totalYield += userDeposits[userAddress][i].amountNFT * 1 ether * yieldMultiplier / (1 ether * 100);
    }
    return totalYield;
  }
  
  function getUserDeposits(address userAddress) external view returns(userDeposit[] memory) {
    return userDeposits[userAddress];
  }

}