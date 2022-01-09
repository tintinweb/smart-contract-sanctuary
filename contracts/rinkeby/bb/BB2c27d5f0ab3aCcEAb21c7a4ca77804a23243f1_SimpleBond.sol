// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleBond {
  IERC20 public immutable tokenLP;
  IERC20 public immutable tokenRewards;
  uint256 public immutable rewardPourcentage;
  uint256 public immutable vestingBlocks;

  struct Bond {
    uint256 lp;
    uint256 rewards;
    uint256 block;
  }
  mapping(address => Bond[]) public bonds;
  uint256 public totalLP;
  uint256 public totalRewards;

  constructor(
    address _tokenLP,
    address _tokenRewards,
    uint256 _rewardPourcentage,
    uint256 _vestingBlocks
  ) {
    require(_tokenLP != address(0), "Invalid LP token");
    require(_tokenRewards != address(0), "Invalid Reward token");
    require(_rewardPourcentage > 0, "Invalid Reward pourcentage");
    require(_vestingBlocks > 0, "Invalid Vesting blocks number");
    tokenLP = IERC20(_tokenLP);
    tokenRewards = IERC20(_tokenRewards);
    rewardPourcentage = _rewardPourcentage;
    vestingBlocks = _vestingBlocks;
  }

  function deposit(uint256 amount) public returns (Bond memory bond) {
    tokenLP.approve(address(this), amount);
    require(tokenLP.transferFrom(msg.sender, address(this), amount), "LP deposit failed");

    bond.lp = amount;
    totalLP += amount;

    uint256 rewards = ((amount * rewardPourcentage) / 100) * vestingBlocks;
    bond.rewards = rewards;
    totalRewards += rewards;

    bond.block = block.number;

    bonds[msg.sender].push(bond);
  }

  function _bondVesting(Bond memory bond) internal view returns (bool) {
    assert(block.number >= bond.block);
    return (block.number - bond.block) < vestingBlocks;
  }

  function bondVesting(address addr, uint256 index) public view returns (bool) {
    return _bondVesting(bonds[addr][index]);
  }

  function _bondUnlockLP(Bond memory bond) internal view returns (uint256) {
    return _bondVesting(bond) ? 0 : bond.lp;
  }

  function bondUnlockLP(address addr, uint256 index) public view returns (uint256) {
    return _bondUnlockLP(bonds[addr][index]);
  }

  function _bondClaimableRewards(Bond memory bond) internal view returns (uint256) {
    return _bondVesting(bond) ? (bond.rewards * (block.number - bond.block)) / vestingBlocks : bond.rewards;
  }

  function bondClaimableRewards(address addr, uint256 index) public view returns (uint256) {
    return _bondClaimableRewards(bonds[addr][index]);
  }

  function _bondBalancesOf(Bond memory bond)
    public
    view
    returns (
      uint256 balanceLP,
      uint256 balanceRewards,
      uint256 balanceUnlockLP,
      uint256 balanceClaimableRewards
    )
  {
    balanceLP = bond.lp;
    balanceRewards = bond.rewards;
    balanceUnlockLP = _bondUnlockLP(bond);
    balanceClaimableRewards = _bondClaimableRewards(bond);
  }

  function bondBalancesOf(address addr, uint256 index)
    public
    view
    returns (
      uint256 balanceLP,
      uint256 balanceRewards,
      uint256 balanceUnlockLP,
      uint256 balanceClaimableRewards
    )
  {
    return _bondBalancesOf(bonds[addr][index]);
  }

  function balancesOf(address addr)
    public
    view
    returns (
      uint256 balanceLP,
      uint256 balanceRewards,
      uint256 balanceUnlockLP,
      uint256 balanceClaimableRewards
    )
  {
    for (uint256 index = 0; index < bonds[addr].length; index += 1) {
      Bond memory bond = bonds[addr][index];

      balanceLP += bond.lp;
      balanceRewards += bond.rewards;
      balanceUnlockLP += _bondUnlockLP(bond);
      balanceClaimableRewards += _bondClaimableRewards(bond);
    }
  }

  function bondWithdraw(
    address addr,
    uint256 amount,
    uint256 index
  ) internal returns (uint256 withdrawn) {
    Bond storage bond = bonds[addr][index];

    if (_bondVesting(bond) || bond.lp == 0) {
      withdrawn = 0;
    } else {
      withdrawn = (amount <= bond.lp) ? amount : bond.lp;

      totalLP -= withdrawn;
      bond.lp -= withdrawn;
    }
  }

  function bondClaimRewards(
    address addr,
    uint256 amount,
    uint256 index
  ) internal returns (uint256 rewards) {
    Bond storage bond = bonds[addr][index];

    if (_bondVesting(bond) || bond.rewards == 0) {
      rewards = 0;
    } else {
      rewards = (amount <= bond.rewards) ? amount : bond.rewards;

      totalRewards -= rewards;
      bond.rewards -= rewards;
    }
  }

  function withdraw(address addr, uint256 amount) public returns (uint256 withdrawn) {
    for (uint256 index = 0; (index < bonds[addr].length) && (amount > 0); index += 1) {
      uint256 bondWithdrawn = bondWithdraw(addr, amount, index);

      amount -= bondWithdrawn;
      withdrawn += bondWithdrawn;
    }
  }

  function claimRewards(address addr, uint256 amount) public returns (uint256 claimed) {
    for (uint256 index = 0; (index < bonds[addr].length) && (amount > 0); index += 1) {
      uint256 bondRewards = bondClaimRewards(addr, amount, index);

      amount -= bondRewards;
      claimed += bondRewards;
    }
  }
}