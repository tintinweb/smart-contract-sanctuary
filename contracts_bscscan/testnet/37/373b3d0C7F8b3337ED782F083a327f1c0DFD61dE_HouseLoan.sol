// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface XToken {
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface XNFT {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract HouseLoan {
  using SafeMath for uint256;

  address public borrower;
  address  public lender;

  uint256 public immutable amount = 300_000e18;
  uint256 public houseNFT;
  // 0 unsigned
  // 1 signed
  // 2 finished
  uint256 public status = 0;
  uint256 public startAt;
  uint256 public immutable periods = 3;
  uint256 public immutable intervalPeriod = 60; // seconds
  uint256 public immutable interestPeriod = 1000e18;
  uint256 public immutable overdueInterestPerDay = 2e18;
  uint256 public payedPeriods = 0;
  uint256 public immutable maxOverdueDays = 300; // seconds

  bool public borrowerSigned = false;
  bool public lenderSigned = false;

  uint8 private requestId = 0;
  bool private sun = false;
  address private oracleAddr;

  XToken xtoken;
  XNFT xnft;

  constructor(address _borrower, address _lender, address _xtoken, address _xnft, uint256 _houseNFT, address oracleAddr_) {
    borrower = _borrower;
    lender = _lender;
    houseNFT = _houseNFT;
    xtoken = XToken(_xtoken);
    xnft = XNFT(_xnft);
    oracleAddr = oracleAddr_;
  }

  modifier onlyBorrower() {
    require(msg.sender == borrower, "sender is not a borrower");
    _;
  }

  modifier onlyLender() {
    require(msg.sender == lender, "sender is not a lender");
    _;
  }

  function borrowerSign() onlyBorrower public {
    require(!borrowerSigned && !lenderSigned);
    require(xnft.ownerOf(houseNFT) == address(this), "NFT owner is not HouseLoan contract");

    borrowerSigned = true;
  }

  function lenderSign() onlyLender public {
    require(borrowerSigned && !lenderSigned);
    require(xnft.ownerOf(houseNFT) == address(this), "NFT owner is not HouseLoan contract");

    lenderSigned = true;
    xtoken.transferFrom(lender, borrower, amount);

    startAt = block.timestamp;
    status = 1;
  }

  function repayment() onlyBorrower public { // one by one
    require(status == 1, "status is not signed");

    uint256 actualDays_ = block.timestamp - startAt;
    uint256 expectDays_ = (payedPeriods + 1) * intervalPeriod;

    require(actualDays_ >= expectDays_, "not the repayment date"); // can't repay in advance

    uint256 repayAmount = amount/periods;

    if (!sun) {
      repayAmount += (interestPeriod + (actualDays_ - expectDays_) * overdueInterestPerDay);
    }

    xtoken.transferFrom(borrower, lender, repayAmount);

    payedPeriods += 1;

    if (payedPeriods == periods) {
      status = 2; // end
    }
  }

  function mortgage() onlyLender public {
    require(status == 1, "status is not signed");

    uint256 actualDays_ = block.timestamp - startAt;
    uint256 expectDays_ = (payedPeriods + 1) * intervalPeriod;

    require(actualDays_ > expectDays_ + maxOverdueDays, "the maximum overdue days have not been reached");

    xnft.transferFrom(address(this), lender, houseNFT);

    status = 2; // end
  }

  event RequestOracle(uint256 date, uint256 requestId);

  function requestOracle() onlyBorrower public returns (uint8) {
    emit RequestOracle(startAt+10, block.number);

    return 1;
  }

  function updateSun(uint256 requestId_) public {
    require(msg.sender == oracleAddr);
    require(requestId_ != 0 && requestId_ == requestId, "invalid request id");

    sun = true;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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