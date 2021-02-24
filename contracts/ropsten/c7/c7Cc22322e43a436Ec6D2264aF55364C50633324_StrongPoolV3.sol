// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/VoteInterface.sol';

contract StrongPoolV3 {
  event MinedFor(address indexed miner, uint256 amount);
  event Mined(address indexed miner, uint256 amount);
  event MinedForVotesOnly(address indexed miner, uint256 amount);
  event UnminedForVotesOnly(address indexed miner, uint256 amount);
  event Unmined(address indexed miner, uint256 amount);
  event Claimed(address indexed miner, uint256 reward);

  using SafeMath for uint256;

  bool public initDone;
  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;
  address public parameterAdmin;
  address payable public feeCollector;

  IERC20 public strongToken;
  VoteInterface public vote;

  mapping(address => uint256) public minerBalance;
  uint256 public totalBalance;
  mapping(address => uint256) public minerBlockLastClaimedOn;

  mapping(address => uint256) public minerVotes;

  uint256 public rewardBalance;

  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;

  uint256 public miningFeeNumerator;
  uint256 public miningFeeDenominator;

  uint256 public unminingFeeNumerator;
  uint256 public unminingFeeDenominator;

  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;

  mapping(address => uint256) public inboundContractIndex;
  address[] public inboundContracts;
  mapping(address => bool) public inboundContractTrusted;

  uint256 public claimingFeeInWei;

  bool public removedTokens;

  function init(
    address voteAddress,
    address strongTokenAddress,
    address adminAddress,
    address superAdminAddress,
    uint256 rewardPerBlockNumeratorValue,
    uint256 rewardPerBlockDenominatorValue,
    uint256 miningFeeNumeratorValue,
    uint256 miningFeeDenominatorValue,
    uint256 unminingFeeNumeratorValue,
    uint256 unminingFeeDenominatorValue,
    uint256 claimingFeeNumeratorValue,
    uint256 claimingFeeDenominatorValue
  ) public {
    require(!initDone, 'init done');
    vote = VoteInterface(voteAddress);
    strongToken = IERC20(strongTokenAddress);
    admin = adminAddress;
    superAdmin = superAdminAddress;
    rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
    miningFeeNumerator = miningFeeNumeratorValue;
    miningFeeDenominator = miningFeeDenominatorValue;
    unminingFeeNumerator = unminingFeeNumeratorValue;
    unminingFeeDenominator = unminingFeeDenominatorValue;
    claimingFeeNumerator = claimingFeeNumeratorValue;
    claimingFeeDenominator = claimingFeeDenominatorValue;
    initDone = true;
  }

  // ADMIN
  // *************************************************************************************
  function updateParameterAdmin(address newParameterAdmin) public {
    require(newParameterAdmin != address(0), 'zero');
    require(msg.sender == superAdmin);
    parameterAdmin = newParameterAdmin;
  }

  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0), 'zero');
    require(msg.sender == superAdmin);
    feeCollector = newFeeCollector;
  }

  function setPendingAdmin(address newPendingAdmin) public {
    require(newPendingAdmin != address(0), 'zero');
    require(msg.sender == admin, 'not admin');
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), 'not pendingAdmin');
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(newPendingSuperAdmin != address(0), 'zero');
    require(msg.sender == superAdmin, 'not superAdmin');
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), 'not pendingSuperAdmin');
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  // INBOUND CONTRACTS
  // *************************************************************************************
  function addInboundContract(address contr) public {
    require(contr != address(0), 'zero');
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    if (inboundContracts.length != 0) {
      uint256 index = inboundContractIndex[contr];
      require(inboundContracts[index] != contr, 'exists');
    }
    uint256 len = inboundContracts.length;
    inboundContractIndex[contr] = len;
    inboundContractTrusted[contr] = true;
    inboundContracts.push(contr);
  }

  function inboundContractTrustStatus(address contr, bool trustStatus) public {
    require(contr != address(0), 'zero');
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    uint256 index = inboundContractIndex[contr];
    require(inboundContracts[index] == contr, 'not exists');
    inboundContractTrusted[contr] = trustStatus;
  }

  // REWARD
  // *************************************************************************************
  function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    rewardPerBlockNumerator = numerator;
    rewardPerBlockDenominator = denominator;
  }

  function deposit(uint256 amount) public {
    require(msg.sender == superAdmin, 'not an admin');
    require(amount > 0, 'zero');
    strongToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance.add(amount);
  }

  function withdraw(address destination, uint256 amount) public {
    require(msg.sender == superAdmin, 'not an admin');
    require(amount > 0, 'zero');
    require(rewardBalance >= amount, 'not enough');
    strongToken.transfer(destination, amount);
    rewardBalance = rewardBalance.sub(amount);
  }

  function removeTokens() public {
    require(!removedTokens, 'already removed');
    require(msg.sender == superAdmin, 'not an admin');
    // removing 2500 STRONG tokens sent in these two txs
    // 0xc6b08964acae1fce264a47cecdb3a47b20cfebfead83f81e06e3e75eda3b7b2d
    // 0xc2a51c14d65f6a370a6888ee92cf7aa35d461100a7a9e8f23db518c4289ef614
    strongToken.transfer(superAdmin, 2500000000000000000000);
    removedTokens = true;
  }

  // FEES
  // *************************************************************************************
  function updateMiningFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    miningFeeNumerator = numerator;
    miningFeeDenominator = denominator;
  }

  function updateUnminingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    unminingFeeNumerator = numerator;
    unminingFeeDenominator = denominator;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  // CORE
  // *************************************************************************************
  function mineForVotesOnly(uint256 amount) public {
    require(amount > 0, 'zero');
    strongToken.transferFrom(msg.sender, address(this), amount);
    minerVotes[msg.sender] = minerVotes[msg.sender].add(amount);
    vote.updateVotes(msg.sender, amount, true);
    emit MinedForVotesOnly(msg.sender, amount);
  }

  function unmineForVotesOnly(uint256 amount) public {
    require(amount > 0, 'zero');
    require(minerVotes[msg.sender] >= amount, 'not enough');
    minerVotes[msg.sender] = minerVotes[msg.sender].sub(amount);
    vote.updateVotes(msg.sender, amount, false);
    strongToken.transfer(msg.sender, amount);
    emit UnminedForVotesOnly(msg.sender, amount);
  }

  function mineFor(address miner, uint256 amount) public {
    require(inboundContractTrusted[msg.sender], 'not trusted');
    require(amount > 0, 'zero');
    strongToken.transferFrom(msg.sender, address(this), amount);
    minerBalance[miner] = minerBalance[miner].add(amount);
    totalBalance = totalBalance.add(amount);
    if (minerBlockLastClaimedOn[miner] == 0) {
      minerBlockLastClaimedOn[miner] = block.number;
    }
    vote.updateVotes(miner, amount, true);
    emit MinedFor(miner, amount);
  }

  function mine(uint256 amount) public payable {
    require(amount > 0, 'zero');
    uint256 fee = amount.mul(miningFeeNumerator).div(miningFeeDenominator);
    require(msg.value == fee, 'invalid fee');
    feeCollector.transfer(msg.value);
    strongToken.transferFrom(msg.sender, address(this), amount);
    if (block.number > minerBlockLastClaimedOn[msg.sender]) {
      uint256 reward = getReward(msg.sender);
      if (reward > 0) {
        minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
        totalBalance = totalBalance.add(reward);
        rewardBalance = rewardBalance.sub(reward);
        vote.updateVotes(msg.sender, reward, true);
        minerBlockLastClaimedOn[msg.sender] = block.number;
      }
    }
    minerBalance[msg.sender] = minerBalance[msg.sender].add(amount);
    totalBalance = totalBalance.add(amount);
    if (minerBlockLastClaimedOn[msg.sender] == 0) {
      minerBlockLastClaimedOn[msg.sender] = block.number;
    }
    vote.updateVotes(msg.sender, amount, true);
    emit Mined(msg.sender, amount);
  }

  function unmine(uint256 amount) public payable {
    require(amount > 0, 'zero');
    uint256 fee = amount.mul(unminingFeeNumerator).div(unminingFeeDenominator);
    require(msg.value == fee, 'invalid fee');
    require(minerBalance[msg.sender] >= amount, 'not enough');
    feeCollector.transfer(msg.value);
    bool unmineAll = (amount == minerBalance[msg.sender]);
    if (block.number > minerBlockLastClaimedOn[msg.sender]) {
      uint256 reward = getReward(msg.sender);
      if (reward > 0) {
        minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
        totalBalance = totalBalance.add(reward);
        rewardBalance = rewardBalance.sub(reward);
        vote.updateVotes(msg.sender, reward, true);
        minerBlockLastClaimedOn[msg.sender] = block.number;
      }
    }
    uint256 amountToUnmine = unmineAll ? minerBalance[msg.sender] : amount;
    minerBalance[msg.sender] = minerBalance[msg.sender].sub(amountToUnmine);
    totalBalance = totalBalance.sub(amountToUnmine);
    strongToken.transfer(msg.sender, amountToUnmine);
    vote.updateVotes(msg.sender, amountToUnmine, false);
    if (minerBalance[msg.sender] == 0) {
      minerBlockLastClaimedOn[msg.sender] = 0;
    }
    emit Unmined(msg.sender, amountToUnmine);
  }

  function claim(uint256 blockNumber) public payable {
    require(blockNumber <= block.number, 'invalid block number');
    require(minerBlockLastClaimedOn[msg.sender] != 0, 'error');
    require(blockNumber > minerBlockLastClaimedOn[msg.sender], 'too soon');
    uint256 reward = getRewardByBlock(msg.sender, blockNumber);
    require(reward > 0, 'no reward');
    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value == fee, 'invalid fee');
    feeCollector.transfer(msg.value);
    minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
    totalBalance = totalBalance.add(reward);
    rewardBalance = rewardBalance.sub(reward);
    minerBlockLastClaimedOn[msg.sender] = blockNumber;
    vote.updateVotes(msg.sender, reward, true);
    emit Claimed(msg.sender, reward);
  }

  function getReward(address miner) public view returns (uint256) {
    if (totalBalance == 0) return 0;
    if (minerBlockLastClaimedOn[miner] == 0) return 0;
    uint256 blockResult = block.number.sub(minerBlockLastClaimedOn[miner]);
    uint256 rewardPerBlockResult = blockResult.mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator);
    return rewardPerBlockResult.mul(minerBalance[miner]).div(totalBalance);
  }

  function getRewardByBlock(address miner, uint256 blockNumber) public view returns (uint256) {
    if (blockNumber > block.number) return 0;
    if (minerBlockLastClaimedOn[miner] == 0) return 0;
    if (blockNumber < minerBlockLastClaimedOn[miner]) return 0;
    if (totalBalance == 0) return 0;
    uint256 blockResult = blockNumber.sub(minerBlockLastClaimedOn[miner]);
    uint256 rewardPerBlockResult = blockResult.mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator);
    return rewardPerBlockResult.mul(minerBalance[miner]).div(totalBalance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface VoteInterface {
  function getPriorProposalVotes(address account, uint256 blockNumber) external view returns (uint96);

  function updateVotes(
    address voter,
    uint256 rawAmount,
    bool adding
  ) external;
}