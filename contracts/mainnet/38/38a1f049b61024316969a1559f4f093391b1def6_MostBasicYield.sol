/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

library SafeMathLib {
  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b, 'Overflow detected');
    return c;
  }

  function minus(uint a, uint b) public pure returns (uint) {
    require(b <= a, 'Underflow detected');
    return a - b;
  }

  function plus(uint a, uint b) public pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b, 'Overflow detected');
    return c;
  }
}


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


contract MostBasicYield {
    using SafeMathLib for uint;

    struct Receipt {
        uint id;
        uint amountDeposited;
        uint timeDeposited;
        uint timeWithdrawn;
        address owner;
    }

    uint[] public tokensPerSecondPerToken;
    uint public maximumDeposit;
    uint public totalDeposits = 0;
    uint[] public rewardsClaimed;
    uint public numReceipts = 0;
    uint public startTime;
    uint public endTime;

    address public management;

    IERC20 public depositToken;
    IERC20[] public rewardTokens;
    mapping (uint => Receipt) public receipts;

    event DepositOccurred(uint indexed id, address indexed owner);
    event WithdrawalOccurred(uint indexed id, address indexed owner);
    event ExcessRewardsWithdrawn();

    constructor(
        uint _startTime,
        uint maxDeposit,
        uint[] memory rewards,
        uint programLengthDays,
        address depositTokenAddress,
        address[] memory rewardTokenAddresses,
        address mgmt)
    {
        tokensPerSecondPerToken = rewards;
        startTime = _startTime > 0 ? _startTime : block.timestamp;
        endTime = startTime.plus(programLengthDays * 1 days);
        depositToken = IERC20(depositTokenAddress);
        require(tokensPerSecondPerToken.length == rewardTokenAddresses.length, 'Rewards and reward token arrays must be same length');

        for (uint i = 0; i < rewardTokenAddresses.length; i++) {
            rewardTokens.push(IERC20(rewardTokenAddresses[i]));
            rewardsClaimed.push(0);
        }

        maximumDeposit = maxDeposit;
        management = mgmt;
    }

    function getRewards(uint receiptId) public view returns (uint[] memory) {
        Receipt memory receipt = receipts[receiptId];
        uint nowish = block.timestamp;
        if (nowish > endTime) {
            nowish = endTime;
        }

        uint secondsDiff = nowish.minus(receipt.timeDeposited);
        uint[] memory rewardsLocal = new uint[](tokensPerSecondPerToken.length);
        for (uint i = 0; i < tokensPerSecondPerToken.length; i++) {
            rewardsLocal[i] = (secondsDiff.times(tokensPerSecondPerToken[i]).times(receipt.amountDeposited)) / 1e18;
        }

        return rewardsLocal;
    }

    function deposit(uint amount) external {
        require(block.timestamp > startTime, 'Cannot deposit before pool start');
        require(block.timestamp < endTime, 'Cannot deposit after pool ends');
        require(totalDeposits < maximumDeposit, 'Maximum deposit already reached');
        if (totalDeposits.plus(amount) > maximumDeposit) {
            amount = maximumDeposit.minus(totalDeposits);
        }
        depositToken.transferFrom(msg.sender, address(this), amount);
        totalDeposits = totalDeposits.plus(amount);

        Receipt storage receipt = receipts[++numReceipts];
        receipt.id = numReceipts;
        receipt.amountDeposited = amount;
        receipt.timeDeposited = block.timestamp;
        receipt.owner = msg.sender;

        emit DepositOccurred(numReceipts, msg.sender);
    }

    function withdraw(uint receiptId) external {
        Receipt storage receipt = receipts[receiptId];
        require(receipt.id == receiptId, 'Can only withdraw real receipts');
        require(receipt.owner == msg.sender || block.timestamp > endTime, 'Can only withdraw your own deposit');
        require(receipt.timeWithdrawn == 0, 'Can only withdraw once per receipt');
        receipt.timeWithdrawn = block.timestamp;
        uint[] memory rewards = getRewards(receiptId);
        totalDeposits = totalDeposits.minus(receipt.amountDeposited);

        for (uint i = 0; i < rewards.length; i++) {
            rewardsClaimed[i] = rewardsClaimed[i].plus(rewards[i]);
            rewardTokens[i].transfer(receipt.owner, rewards[i]);
        }
        depositToken.transfer(receipt.owner, receipt.amountDeposited);
        emit WithdrawalOccurred(receiptId, receipt.owner);
    }

    function withdrawExcessRewards() external {
        require(totalDeposits == 0, 'Cannot withdraw until all deposits are withdrawn');
        require(block.timestamp > endTime, 'Contract must reach maturity');

        for (uint i = 0; i < rewardTokens.length; i++) {
            uint rewards = rewardTokens[i].balanceOf(address(this));
            rewardTokens[i].transfer(management, rewards);
        }

        depositToken.transfer(management, depositToken.balanceOf(address(this)));
        emit ExcessRewardsWithdrawn();
    }
}