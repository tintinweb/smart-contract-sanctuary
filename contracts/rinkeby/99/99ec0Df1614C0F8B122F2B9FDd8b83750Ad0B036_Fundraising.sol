pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract Fundraising {
    using SafeMath for uint256;

    struct Fundraise {
        address fundraiser;
        address beneficiary;
        uint256 fundraiseGoal;
        uint256 fundraiseStartTime;
        uint256 fundraiseDeadline;
        string fundraiseAgenda;
        uint256 amountFunded;
    }

    event Donation(address indexed donator, uint256 indexed fundraiseId, uint256 donationAmount);
    event FundraiseCreated(address indexed fundraiser, address indexed beneficiary, uint256 fundraiseGoal, uint256 fundraiseDeadline, uint256 indexed fundraiseId, string fundraiseAgenda);
    event BeneficiaryChanged(uint256 indexed fundraiseId, address indexed newBeneficiary);
    event FundraiseComplete(uint256 indexed fundraiseId, address indexed beneficiary);
    event DonationClaimed(uint256 indexed fundraiseId, address indexed claimer, uint256 claimAmount);

    Fundraise[] allFundraises;

    mapping(address => uint256[]) fundraiserToFundraise;
    mapping(address => uint256[]) donatorToFundraise;
    mapping(uint256 => mapping(address => uint256)) donatorToDonation;

    function getFundraise(uint256 fundraiseId) external view returns(Fundraise memory) {
        return allFundraises[fundraiseId];
    }

    modifier onlyFundraiser(uint256 fundraiseId) {
        Fundraise memory fundraise = allFundraises[fundraiseId];
        require(msg.sender == fundraise.fundraiser, "Only Fundraiser is allowed");
        _;
    }

    modifier onlyBeneficiary(uint256 fundraiseId) {
        Fundraise memory fundraise = allFundraises[fundraiseId];
        require(msg.sender == fundraise.beneficiary, "Only beneficiary is allowed");
        _;
    }

    modifier afterDeadline(uint256 fundraiseId) {
        Fundraise memory fundraise = allFundraises[fundraiseId];
        require(block.timestamp > fundraise.fundraiseDeadline, "Fundraise is still ongoing");
        _;
    }

    function donate(uint256 fundraiseId) external payable {
        Fundraise storage fundraise = allFundraises[fundraiseId];
        require(fundraise.fundraiseDeadline > block.timestamp, "Fundraise is not accepting anymore donations");        
        require(fundraise.fundraiseGoal.sub(fundraise.amountFunded).sub(msg.value) >= 0, "Fundraise is complete no more donations accepted");
        fundraise.amountFunded = fundraise.amountFunded.add(msg.value); // increase amountFunded to Donation
        donatorToDonation[fundraiseId][msg.sender] = donatorToDonation[fundraiseId][msg.sender].add(msg.value);
        donatorToFundraise[msg.sender].push(fundraiseId); // if a person donates 2 times then 2 id's are added.
        emit Donation(msg.sender, fundraiseId, msg.value);
    }

    function createFundraise(address beneficiary, uint256 fundraiseGoal, string memory fundraiseAgenda, uint256 fundraiseDeadline) external {
        Fundraise memory fundraise = Fundraise(msg.sender, beneficiary, fundraiseGoal, block.timestamp, fundraiseDeadline, fundraiseAgenda, 0);
        allFundraises.push(fundraise);
        uint256 fundraiseId = allFundraises.length - 1;
        fundraiserToFundraise[msg.sender].push(fundraiseId);
        emit FundraiseCreated(msg.sender, beneficiary, fundraiseGoal, fundraiseDeadline, fundraiseId, fundraiseAgenda);
    } 

    function getBeneficiary(uint256 fundraiseId) external view returns(address) {
        Fundraise memory fundraise = allFundraises[fundraiseId];
        return fundraise.beneficiary;
    }

    function setBeneficiary(uint256 fundraiseId, address newBeneficiary) onlyFundraiser(fundraiseId) external {
        Fundraise storage fundraise = allFundraises[fundraiseId];
        fundraise.beneficiary = newBeneficiary;
        emit BeneficiaryChanged(fundraiseId, newBeneficiary);
    }

    function getDonationAmount(uint256 fundraiseId) external view returns(uint256) {
        return donatorToDonation[fundraiseId][msg.sender];
    }

    function claimFundraised(uint256 fundraiseId) onlyBeneficiary(fundraiseId) afterDeadline(fundraiseId) external {
        Fundraise storage fundraise = allFundraises[fundraiseId];
        require(fundraise.fundraiseGoal.sub(fundraise.amountFunded) == 0, "Fundraise was a failure cannot claim funds");
        payable(fundraise.beneficiary).transfer(fundraise.fundraiseGoal);
        fundraise.fundraiseGoal = fundraise.fundraiseGoal.sub(fundraise.amountFunded);
        emit FundraiseComplete(fundraiseId, fundraise.beneficiary);
    }

    function claimDonation(uint256 fundraiseId) afterDeadline(fundraiseId) external {
        Fundraise storage fundraise = allFundraises[fundraiseId];
        uint256 donationAmount = donatorToDonation[fundraiseId][msg.sender];
        require(donationAmount > 0, "No Donation made");
        require(fundraise.fundraiseGoal.sub(fundraise.amountFunded) > 0, "Fundraise was a success cannot claim donation");
        payable(msg.sender).transfer(donationAmount);
        fundraise.amountFunded = fundraise.amountFunded.sub(donationAmount);
        donatorToDonation[fundraiseId][msg.sender] = 0;
        emit DonationClaimed(fundraiseId, msg.sender, donationAmount);
    }
    
    function getAmountFunded(uint256 fundraiseId) external view returns(uint256) {
        Fundraise memory fundraise = allFundraises[fundraiseId];
        return fundraise.amountFunded;
    }

    function getFundraises() external view returns(uint256[] memory) {
        return fundraiserToFundraise[msg.sender];
    }

    function getDonations() external view returns(uint256[] memory) {
        return donatorToFundraise[msg.sender];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}