// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
    @title Paywall
    @author jierlich (Jonah Erlich)
    @notice Payments tooling for access to non-tokenized digital assets
            Ex. Article paywall
*/
contract Paywall is Ownable {

    using SafeMath for uint;

    /// @dev counter keeps track of the latest `id` and is used to generate the next one
    uint256 counter;

    /// @dev contractFeeBase is used to calculate the contract's portion of the fee
    uint constant contractFeeBase = 1 ether;
    /// @dev per-ether fee set by contract owner
    uint public contractFee;
    /// @dev Fees paid to the contract that have not yet been withdrawn
    uint public contractFeesAccrued;

    /// @dev The keys of all the following mapping are list `id`s
    /// @dev addressHasAccess can be queried to see if an address has been granted access to an asset
    mapping(uint256 => mapping(address => bool)) public addressHasAccess;
    /// @dev The required amount to pay in msg.value to grant access to the asset
    mapping(uint256 => uint256) public feeAmount;
    /// @dev Fees paid to the asset owner that have not yet been withdrawn
    mapping(uint256 => uint) public pendingWithdrawals;
    /// @dev Checks which address owns `id` asset
    mapping(uint256 => address payable) public owners;

    /// @notice Verifies that this function is being called by the asset's owner
    /// @param _id The asset's identifier
    modifier onlyAssetOwner (uint256 _id) {
        require(owners[_id] == msg.sender, "Only the asset owner can call this function");
        _;
    }

    /// @dev Retrieve this event after creating an asset to retrieve the asset's `id`
    event AssetCreated(uint256 indexed _id, address _owner);

    /// @notice Creates an asset
    /// @param _fee The fee a user must pay to grant access to this asset
    /// @param _owner The owner of an asset, who can withdraw accruedfees and perform administrative actions
    /// @return id of the created asset
    function create(uint256 _fee, address _owner) public returns (uint256) {
        counter += 1;
        feeAmount[counter] = _fee;
        owners[counter] = payable(_owner);
        emit AssetCreated(counter, _owner);
        return counter;
    }

    /// @notice Grants access to a specific asset
    /// @dev `msg.value` must equal `feeAmount[_id]`
    /// @param _id Asset to which an address is granted access
    /// @param _addr Address to which access to an asset is granted
    function grantAccess(uint256 _id, address _addr) public payable {
        require(_id <= counter, 'Asset does not exist');
        require(msg.value == feeAmount[_id], 'Incorrect fee amount');
        require(addressHasAccess[_id][_addr] == false, 'Address already has access');
        uint contractFeeAmount = msg.value.mul(contractFee).div(contractFeeBase);
        uint ownerFeeAmount = msg.value.sub(contractFeeAmount);
        pendingWithdrawals[_id] += ownerFeeAmount;
        contractFeesAccrued += contractFeeAmount;
        addressHasAccess[_id][_addr] = true;
    }

    /// @notice Withdraws funds paid for access to an asset
    /// @param _id Fees from the asset with this `_id` are withdrawn
    function withdraw(uint256 _id) onlyAssetOwner(_id) public {
        require(pendingWithdrawals[_id] > 0, 'No funds to withdraw for this asset');
        address payable assetOwner = owners[_id];
        uint amountToWithdraw = pendingWithdrawals[_id];
        pendingWithdrawals[_id] = 0;
        assetOwner.transfer(amountToWithdraw);
    }

    // Administrative Functions

    /// @notice Change the fee for an asset
    /// @param _id Asset to change
    /// @param _fee New fee for asset
    function changeAssetFee(uint256 _id, uint256 _fee) onlyAssetOwner(_id) public {
        feeAmount[_id] = _fee;
    }

    /// @notice Change the owner for an asset
    /// @param _id Asset to change
    /// @param _owner New owner for asset
    function changeAssetOwner(uint256 _id, address _owner) onlyAssetOwner(_id) public {
        owners[_id] = payable(_owner);
    }

    /// @notice Changes the per-ether fee the contract takes from grantAccess calls
    /// @param _contractFee New value for the contract fee
    function changeContractFee(uint _contractFee) onlyOwner() public {
        contractFee = _contractFee;
    }

    /// @notice Allows the contract owner to withdraw accrued fees
    function contractWithdraw() onlyOwner() public {
        require(contractFeesAccrued > 0, 'No funds to withdraw');
        address payable contractOwner = payable(owner());
        uint withdrawValue = contractFeesAccrued;
        contractFeesAccrued = 0;
        contractOwner.transfer(withdrawValue);
    }

    /// @notice Catches any funds accidentally sent to contract directly
    receive() external payable {
        require(0 == 1, 'Invalid: do not send funds directly to contract');
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}