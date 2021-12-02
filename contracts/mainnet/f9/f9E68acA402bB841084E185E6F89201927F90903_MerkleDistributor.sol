//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
  using SafeMath for uint256;
  address public immutable override token;
  bytes32 public immutable override merkleRoot;
  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  // Opium Bonus
  uint256 public constant MAX_BONUS = 0.999e18;
  uint256 public constant PERCENTAGE_BASE = 1e18;

  uint256 public totalClaims;
  uint256 public initialPoolSize;
  uint256 public currentPoolSize;
  uint256 public bonusSum;
  uint256 public claimed;
  uint256 public percentageIndex;
  uint256 public bonusStart;
  uint256 public bonusEnd;
  uint256 public emergencyTimeout;
  address public emergencyReceiver;

  constructor(
    address token_,
    bytes32 merkleRoot_,
    uint256 _totalClaims,
    uint256 _initialPoolSize,
    uint256 _bonusStart,
    uint256 _bonusEnd,
    uint256 _emergencyTimeout,
    address _emergencyReceiver
  ) {
    token = token_;
    merkleRoot = merkleRoot_;
    // Opium Bonus
    totalClaims = _totalClaims;
    initialPoolSize = _initialPoolSize;
    currentPoolSize = _initialPoolSize;
    percentageIndex = PERCENTAGE_BASE;
    bonusStart = _bonusStart;
    bonusEnd = _bonusEnd;
    emergencyTimeout = _emergencyTimeout;
    emergencyReceiver = _emergencyReceiver;
    require(bonusStart < bonusEnd, "WRONG_BONUS_TIME");
    require(emergencyTimeout > bonusEnd, "WRONG_EMERGENCY_TIMEOUT");
  }

  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");
    require(msg.sender == account, "Only owner can claim");
    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, node),
      "MerkleDistributor: Invalid proof."
    );
    // Mark it claimed and send the token.
    _setClaimed(index);
    uint256 adjustedAmount = _applyAdjustment(amount);
    require(
      IERC20(token).transfer(account, adjustedAmount),
      "MerkleDistributor: Transfer failed."
    );
    emit Claimed(index, account, amount, adjustedAmount);
  }

  function getBonus() public view returns (uint256) {
    // timeRemaining = bonusEnd - now, or 0 if bonus ended
    uint256 timeRemaining =
      block.timestamp > bonusEnd ? 0 : bonusEnd.sub(block.timestamp);
    // bonus = maxBonus * timeRemaining / (bonusEnd - bonusStart)
    return MAX_BONUS.mul(timeRemaining).div(bonusEnd.sub(bonusStart));
  }

  function calculateAdjustedAmount(uint256 amount)
    public
    view
    returns (
      uint256 adjustedAmount,
      uint256 bonus,
      uint256 bonusPart
    )
  {
    // If last claims, return full amount + full bonus
    if (claimed + 1 == totalClaims) {
      return (amount.add(bonusSum), 0, 0);
    }
    // adjustedPercentage = amount / initialPoolSize * percentageIndex
    uint256 adjustedPercentage =
      amount.mul(PERCENTAGE_BASE).div(initialPoolSize).mul(percentageIndex).div(
        PERCENTAGE_BASE
      );
    // bonusPart = adjustedPercentage * bonusSum
    bonusPart = adjustedPercentage.mul(bonusSum).div(PERCENTAGE_BASE);
    // totalToClaim = amount + bonusPart
    uint256 totalToClaim = amount.add(bonusPart);
    // bonus = totalToClaim * getBonus()
    bonus = totalToClaim.mul(getBonus()).div(PERCENTAGE_BASE);
    // adjustedAmount = totalToClaim - bonus
    adjustedAmount = totalToClaim.sub(bonus);
  }

  function _applyAdjustment(uint256 amount) private returns (uint256) {
    (uint256 adjustedAmount, uint256 bonus, uint256 bonusPart) =
      calculateAdjustedAmount(amount);
    // Increment claim index
    claimed += 1;

    // If last claims, return full amount, don't update anything
    if (claimed == totalClaims) {
      return adjustedAmount;
    }
    // newPoolSize = currentPoolSize - amount
    uint256 newPoolSize = currentPoolSize.sub(amount);
    // percentageIndex = percentageIndex * currentPoolSize / newPoolSize
    percentageIndex = percentageIndex
      .mul(currentPoolSize.mul(PERCENTAGE_BASE).div(newPoolSize))
      .div(PERCENTAGE_BASE);
    // currentPoolSize = newPoolSize
    currentPoolSize = newPoolSize;
    // bonusSum = bonusSum - bonusPart + bonus
    bonusSum = bonusSum.sub(bonusPart).add(bonus);
    return adjustedAmount;
  }

  function emergencyWithdrawal() public {
    require(block.timestamp > emergencyTimeout, "TIMEOUT_NOT_EXPIRED");
    IERC20(token).transfer(
      emergencyReceiver,
      IERC20(token).balanceOf(address(this))
    );
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
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
  // Returns the address of the token distributed by this contract.
  function token() external view returns (address);

  // Returns the merkle root of the merkle tree containing account balances available to claim.
  function merkleRoot() external view returns (bytes32);

  // Returns true if the index has been marked claimed.
  function isClaimed(uint256 index) external view returns (bool);

  // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  // This event is triggered whenever a call to #claim succeeds.
  event Claimed(uint256 index, address account, uint256 amount, uint256 adjustedAmount);
}