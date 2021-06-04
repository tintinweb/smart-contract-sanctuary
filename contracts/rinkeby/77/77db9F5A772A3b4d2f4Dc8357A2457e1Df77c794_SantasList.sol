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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SantasList {
    using SafeMath for uint256;
    struct NiceLister {
        uint256 feesWithdrawn;
        bool valid;
    }

    address[] niceListAddresses;

    mapping(address => NiceLister) public niceList;
    mapping(address => bool) public naughtyList;

    // a twist where you are incentivized to get on the nice list as early as possible
    uint256 public feeAmount = 0.01 ether;
    uint256 public numNiceListers;
    uint256 public totalFeesAccrued;
    address private owner;

    event NewNiceLister(address niceLister, uint256 feePaid);
    event NewNaughtyLister(address naughtyLister);
    event WithdrawFees(address withdrawer, uint256 amount);

    constructor(address[] memory _naughtyList) {
        owner = msg.sender;
        for (uint256 i = 0; i < _naughtyList.length; i++) {
            naughtyList[_naughtyList[i]] = true;
            emit NewNaughtyLister(_naughtyList[i]);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the list owner.");
        _;
    }

    function addToNaughtyList(address _address) external onlyOwner {
        require(
            naughtyList[_address] == false,
            "This address is already on the naughty list."
        );
        require(
            niceList[_address].valid == false,
            "This address is on the nice list."
        );
        require(
            _address != msg.sender,
            "You are not allowed to add yourself to the naughty list."
        );

        naughtyList[_address] = true;
        emit NewNaughtyLister(_address);
    }

    function joinNiceList() external payable {
        require(
            niceList[msg.sender].valid == false,
            "You are already on the nice list."
        );
        require(
            naughtyList[msg.sender] == true,
            "You aren't on the naughty list."
        );
        require(
            msg.value == feeAmount,
            "You must pay the fee amount to get on the nice list."
        );

        niceList[msg.sender] = NiceLister(0, true);
        naughtyList[msg.sender] = false;
        numNiceListers = numNiceListers.add(1);
        feeAmount = 0.01 ether * (numNiceListers.add(1))**2;
        niceListAddresses.push(msg.sender);
        totalFeesAccrued += msg.value;

        emit NewNiceLister(msg.sender, msg.value);
    }

    function withdrawShareOfFees() external payable {
        require(niceList[msg.sender].valid, "You aren't on the nice list.");
        uint256 withdrawableAmount = getWithdrawableAmount();
        require(
            withdrawableAmount > 0,
            "You have already withdrawn your share."
        );
        niceList[msg.sender].feesWithdrawn = niceList[msg.sender]
            .feesWithdrawn
            .add(withdrawableAmount);
        (bool sent, ) = msg.sender.call{value: withdrawableAmount}("");
        require(sent, "Unable to withdraw funds.");
        emit WithdrawFees(msg.sender, withdrawableAmount);
    }

    function ownerWithdrawBounty() external payable onlyOwner {
        uint256 withdrawableAmount = getOwnerWithdrawableAmount();
        require(withdrawableAmount > 0, "You have nothing to withdraw.");
        (bool sent, ) = msg.sender.call{value: withdrawableAmount}("");
        require(sent, "Unable to withdraw funds.");
        emit WithdrawFees(msg.sender, withdrawableAmount);
    }

    function getWithdrawableAmount() public view returns (uint256) {
        return _getWithdrawableAmount(msg.sender);
    }

    function getOwnerWithdrawableAmount() public view returns (uint256) {
        uint256 ownerAmount = totalFeesAccrued;
        for (uint256 i = 0; i < niceListAddresses.length; i++) {
            uint256 niceListWithdrawableAmount =
                _getWithdrawableAmount(niceListAddresses[i]);
            if (niceListWithdrawableAmount > 0) {
                ownerAmount = 0;
                break;
            }
            ownerAmount = ownerAmount.sub(
                niceList[niceListAddresses[i]].feesWithdrawn
            );
        }
        return ownerAmount;
    }

    function _getWithdrawableAmount(address _address)
        internal
        view
        returns (uint256)
    {
        uint256 averageWithdrawalAmount =
            address(this).balance / numNiceListers;
        return
            address(this).balance == 0 ||
                averageWithdrawalAmount < niceList[_address].feesWithdrawn
                ? 0
                : averageWithdrawalAmount.sub(niceList[_address].feesWithdrawn);
    }

    receive() external payable {}
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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