// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// TODO dev only
// import "hardhat/console.sol";

/**
 * IcyMembership contract
 * @author @icy_tools
 */
contract IcyMembership is ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  // Events
  event ClaimTrial(address indexed _from);
  event Pay(address indexed _from, uint _value);

  // Enable/disable new/trial members
  bool public isAcceptingNewMemberships = true;
  bool public isAcceptingTrialMemberships = false;

  // 0.0008 ETH
  uint256 public serviceFeePerDay = 800000000000000;

  // Minimum days that can be purchased
  uint8 public minimumServiceDays = 30;

  // Number of days in a trial membership
  uint256 public numberOfTrialMembershipDays = 7;

  // Number of days at which to grant a bonus
  uint256 public bonusIntervalInDays = 300;
  uint256 public bonusDaysGrantedPerInterval = 60;

  mapping(address => uint256) private addressPaidUpTo;
  mapping(address => bool) private addressClaimedTrialMembership;
  mapping(address => bool) private blocklist;

  // Called when contract receives ether
  receive() external payable {
    payForServices();
  }

  function payForServices() public payable {
    require(!blocklist[msg.sender], "Sender not allowed.");
    require(isAcceptingNewMemberships, "Memberships are paused.");

    uint256 minimumServiceFee = serviceFeePerDay.mul(minimumServiceDays);
    require(msg.value >= minimumServiceFee, "Minimum payment not met.");

    // Calculate how many seconds we're buying
    uint256 secondsPerWei = serviceFeePerDay.div(86400);
    uint256 secondsToAdd = msg.value.div(secondsPerWei);
    uint256 daysToAdd = secondsToAdd.div(86400);

    if (bonusDaysGrantedPerInterval > 0 && daysToAdd >= bonusIntervalInDays) {
      secondsToAdd = secondsToAdd.add(daysToAdd.div(bonusIntervalInDays).mul(bonusDaysGrantedPerInterval).mul(86400));
    }

    if (addressPaidUpTo[msg.sender] == 0) {
      addressPaidUpTo[msg.sender] = block.timestamp.add(secondsToAdd);
    } else {
      addressPaidUpTo[msg.sender] = addressPaidUpTo[msg.sender].add(secondsToAdd);
    }

    emit Pay(msg.sender, msg.value);
  }

  function hasActiveMembership(address _addr) external view returns(bool) {
    // get the active address
    // compare active address addressPaidUpTo to current time
    return !isAddressBlocked(_addr) && addressPaidUpTo[_addr] >= block.timestamp;
  }

  // Allows anyone to get the paid up to of an address
  function getAddressPaidUpTo(address _addr) public view returns(uint256) {
    return !isAddressBlocked(_addr) ? addressPaidUpTo[_addr] : 0;
  }

  // Allows anyone to see if an address is on the blocklist
  function isAddressBlocked(address _addr) public view returns(bool) {
    return blocklist[_addr];
  }

  // Allows anyone to claim a trial membership if they haven't already
  function claimTrialMembership() external nonReentrant {
    require(isAcceptingTrialMemberships, "Trials not active.");
    require(!blocklist[msg.sender], "Sender not allowed.");
    require(!addressClaimedTrialMembership[msg.sender], "Trial already claimed.");
    require(addressPaidUpTo[msg.sender] == 0, "Trial not allowed.");

    addressPaidUpTo[msg.sender] = block.timestamp.add(numberOfTrialMembershipDays.mul(86400));
    addressClaimedTrialMembership[msg.sender] = true;

    emit ClaimTrial(msg.sender);
  }

  //
  // ADMIN FUNCTIONS
  //

  // Allows `owner` to add an address to the blocklist
  function addAddressToBlocklist(address _addr) external onlyOwner {
    blocklist[_addr] = true;
  }

  // Allows `owner` to remove an address from the blocklist
  function removeAddressFromBlocklist(address _addr) external onlyOwner {
    delete blocklist[_addr];
  }

  // Allows `owner` to set serviceFeePerDay
  function setBonusIntervalInDays(uint256 _bonusIntervalInDays) external onlyOwner {
    bonusIntervalInDays = _bonusIntervalInDays;
  }

  // Allows `owner` to set serviceFeePerDay
  function setBonusDaysGrantedPerInterval(uint256 _bonusDaysGrantedPerInterval) external onlyOwner {
    bonusDaysGrantedPerInterval = _bonusDaysGrantedPerInterval;
  }

  // Allows `owner` to set address paid up to
  function setAddressPaidUpTo(address _addr, uint256 _paidUpTo) external onlyOwner {
    addressPaidUpTo[_addr] = _paidUpTo;
  }

  // Allows `owner` to set serviceFeePerDay
  function setServiceFeePerDay(uint256 _serviceFeePerDay) external onlyOwner {
    require(_serviceFeePerDay > 0, "serviceFeePerDay cannot be 0");
    serviceFeePerDay = _serviceFeePerDay;
  }

  // Allows `owner` to set minimumServiceDays
  function setMinimumServiceDays(uint8 _minimumServiceDays) external onlyOwner {
    require(_minimumServiceDays > 0, "minimumServiceDays cannot be 0");
    minimumServiceDays = _minimumServiceDays;
  }

  // Allows `owner` to set numberOfTrialMembershipDays
  function setNumberOfTrialMembershipDays(uint8 _numberOfTrialMembershipDays) external onlyOwner {
    require(_numberOfTrialMembershipDays > 0, "numberOfTrialMembershipDays cannot be 0");
    numberOfTrialMembershipDays = _numberOfTrialMembershipDays;
  }

  // Allows `owner` to collect service fees.
  function withdraw(uint256 _amount) external nonReentrant onlyOwner {
    require(_amount <= address(this).balance, "Withdraw less");
    require(_amount > 0, "Withdraw more");

    address owner = _msgSender();
    payable(owner).transfer(_amount);
  }

  // Allows `owner` to toggle if minting is active
  function toggleAcceptingNewMemberships() public onlyOwner {
    isAcceptingNewMemberships = !isAcceptingNewMemberships;
  }

  // Allows `owner` to toggle if minting is active
  function toggleAcceptingTrialMemberships() public onlyOwner {
    isAcceptingTrialMemberships = !isAcceptingTrialMemberships;
  }

  function renounceOwnership() public override view onlyOwner {
    revert("Not allowed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

