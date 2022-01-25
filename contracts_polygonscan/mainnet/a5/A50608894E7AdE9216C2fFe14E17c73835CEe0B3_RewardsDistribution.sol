// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity ^0.8.0;

// Inheritance
import "../utils/Owned.sol";
import "../interfaces/IRewardsDistribution.sol";

// Libraires
import "../libraries/SafeDecimalMath.sol";

// Internal references
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistribution
contract RewardsDistribution is Owned, IRewardsDistribution {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  /**
   * @notice Authorised addresses able to call distributeRewards
   */
  mapping(address => bool) public rewardDistributors;

  /**
   * @notice Address of the Synthetix ProxyERC20
   */
  address public pop;

  /**
   * @notice Address of the FeePoolProxy
   */
  address public treasury;

  /**
   * @notice An array of addresses and amounts to send
   */
  DistributionData[] public override distributions;

  constructor(
    address _owner,
    address _pop,
    address _treasury
  ) public Owned(_owner) {
    pop = _pop;
    treasury = _treasury;
  }

  // ========== EXTERNAL SETTERS ==========

  function setPop(address _pop) external onlyOwner {
    pop = _pop;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function approveRewardDistributor(address _distributor, bool _approved) external onlyOwner {
    emit RewardDistributorUpdated(_distributor, _approved);
    rewardDistributors[_distributor] = _approved;
  }

  // ========== EXTERNAL FUNCTIONS ==========

  /**
   * @notice Adds a Rewards DistributionData struct to the distributions
   * array. Any entries here will be iterated and rewards distributed to
   * each address when tokens are sent to this contract and distributeRewards()
   * is called by the autority.
   * @param destination An address to send rewards tokens too
   * @param amount The amount of rewards tokens to send
   * @param isLocker If the contract is a popLocker which has a slightly different notifyRewardsAmount interface
   */
  function addRewardDistribution(
    address destination,
    uint256 amount,
    bool isLocker
  ) external onlyOwner returns (bool) {
    require(destination != address(0), "Cant add a zero address");
    require(amount != 0, "Cant add a zero amount");

    DistributionData memory rewardsDistribution = DistributionData(destination, amount, isLocker);
    distributions.push(rewardsDistribution);

    emit RewardDistributionAdded(distributions.length - 1, destination, amount, isLocker);
    return true;
  }

  /**
   * @notice Deletes a RewardDistribution from the distributions
   * so it will no longer be included in the call to distributeRewards()
   * @param index The index of the DistributionData to delete
   */
  function removeRewardDistribution(uint256 index) external onlyOwner {
    require(index <= distributions.length - 1, "index out of bounds");

    // shift distributions indexes across
    delete distributions[index];
  }

  /**
   * @notice Edits a RewardDistribution in the distributions array.
   * @param index The index of the DistributionData to edit
   * @param destination The destination address. Send the same address to keep or different address to change it.
   * @param amount The amount of tokens to edit. Send the same number to keep or change the amount of tokens to send.
   * @param isLocker If the contract is a popLocker which has a slightly different notifyRewardsAmount interface
   */
  function editRewardDistribution(
    uint256 index,
    address destination,
    uint256 amount,
    bool isLocker
  ) external onlyOwner returns (bool) {
    require(index <= distributions.length - 1, "index out of bounds");

    distributions[index].destination = destination;
    distributions[index].amount = amount;
    distributions[index].isLocker = isLocker;

    return true;
  }

  function distributeRewards(uint256 amount) external override returns (bool) {
    require(amount > 0, "Nothing to distribute");
    require(rewardDistributors[msg.sender], "not authorized");
    require(pop != address(0), "Pop is not set");
    require(treasury != address(0), "Treasury is not set");
    require(
      IERC20(pop).balanceOf(address(this)) >= amount,
      "RewardsDistribution contract does not have enough tokens to distribute"
    );

    uint256 remainder = amount;

    // Iterate the array of distributions sending the configured amounts
    for (uint256 i = 0; i < distributions.length; i++) {
      if (distributions[i].destination != address(0) || distributions[i].amount != 0) {
        remainder = remainder.sub(distributions[i].amount);

        // Approve the POP
        IERC20(pop).approve(distributions[i].destination, distributions[i].amount);

        // If the contract implements RewardsDistributionRecipient.sol, inform it how many POP its received.
        bytes memory payload;
        if (distributions[i].isLocker) {
          payload = abi.encodeWithSignature("notifyRewardAmount(address,uint256)", pop, distributions[i].amount);
        } else {
          payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", distributions[i].amount);
        }

        // solhint-disable avoid-low-level-calls
        (bool success, ) = distributions[i].destination.call(payload);

        if (!success) {
          // Note: we're ignoring the return value as it will fail for contracts that do not implement RewardsDistributionRecipient.sol
        }
      }
    }

    // After all ditributions have been sent, send the remainder to the RewardsEscrow contract
    IERC20(pop).transfer(treasury, remainder);

    emit RewardsDistributed(amount);
    return true;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Retrieve the length of the distributions array
   */
  function distributionsLength() external view override returns (uint256) {
    return distributions.length;
  }

  /* ========== Events ========== */

  event RewardDistributionAdded(uint256 index, address destination, uint256 amount, bool isLocker);
  event RewardsDistributed(uint256 amount);
  event RewardDistributorUpdated(address indexed distributor, bool approved);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/irewardsdistribution
interface IRewardsDistribution {
  // Structs
  struct DistributionData {
    address destination;
    uint256 amount;
    bool isLocker;
  }

  function distributions(uint256 index)
    external
    view
    returns (
      address destination,
      uint256 amount,
      bool isLocker
    ); // DistributionData

  function distributionsLength() external view returns (uint256);

  // Mutative Functions
  function distributeRewards(uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity ^0.8.0;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
  using SafeMath for uint256;

  /* Number of decimal places in the representations. */
  uint8 public constant decimals = 18;
  uint8 public constant highPrecisionDecimals = 27;

  /* The number representing 1.0. */
  uint256 public constant UNIT = 10**uint256(decimals);

  /* The number representing 1.0 for higher fidelity numbers. */
  uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
  uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint256(highPrecisionDecimals - decimals);

  /**
   * @return Provides an interface to UNIT.
   */
  function unit() external pure returns (uint256) {
    return UNIT;
  }

  /**
   * @return Provides an interface to PRECISE_UNIT.
   */
  function preciseUnit() external pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
  function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    return x.mul(y) / UNIT;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function _multiplyDecimalRound(
    uint256 x,
    uint256 y,
    uint256 precisionUnit
  ) private pure returns (uint256) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
    return _multiplyDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
    return _multiplyDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is a high
   * precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and UNIT must be less than 2**256. As
   * this is an integer division, the result is always rounded down.
   * This helps save on gas. Rounding is more expensive on gas.
   */
  function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
    /* Reintroduce the UNIT factor that will be divided out by y. */
    return x.mul(UNIT).div(y);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function _divideDecimalRound(
    uint256 x,
    uint256 y,
    uint256 precisionUnit
  ) private pure returns (uint256) {
    uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

    if (resultTimesTen % 10 >= 5) {
      resultTimesTen += 10;
    }

    return resultTimesTen / 10;
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
    return _divideDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
    return _divideDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @dev Convert a standard decimal representation to a high precision one.
   */
  function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
    return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
  }

  /**
   * @dev Convert a high precision decimal to a standard decimal representation.
   */
  function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
    uint256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }

  // Computes `a - b`, setting the value to 0 if b > a.
  function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
    return b >= a ? 0 : a - b;
  }

  /* ---------- Utilities ---------- */
  /*
   * Absolute value of the input, returned as a signed number.
   */
  function signedAbs(int256 x) internal pure returns (int256) {
    return x < 0 ? -x : x;
  }

  /*
   * Absolute value of the input, returned as an unsigned number.
   */
  function abs(int256 x) internal pure returns (uint256) {
    return uint256(signedAbs(x));
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
  address public owner;
  address public nominatedOwner;

  constructor(address _owner) {
    require(_owner != address(0), "Owner address cannot be 0");
    owner = _owner;
    emit OwnerChanged(address(0), _owner);
  }

  function nominateNewOwner(address _owner) external onlyOwner {
    nominatedOwner = _owner;
    emit OwnerNominated(_owner);
  }

  function acceptOwnership() external {
    require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
    emit OwnerChanged(owner, nominatedOwner);
    owner = nominatedOwner;
    nominatedOwner = address(0);
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  function _onlyOwner() private view {
    require(msg.sender == owner, "Only the contract owner may perform this action");
  }

  event OwnerNominated(address newOwner);
  event OwnerChanged(address oldOwner, address newOwner);
}