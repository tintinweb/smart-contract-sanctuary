// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OmaxxLibrary.sol";

contract OmaxxPlatform is Ownable {

    using OmaxxPlatformLibrary for *;

    // this variable store the last company ID
    uint256 public companyIDTracker = 0;
    uint256 public minFundRaiseRequired = 500e18;

    address private omaxxEscrowContract;


    modifier onlyEscrowContract {
        require(msg.sender == omaxxEscrowContract, "OmaxxPlatform: only escrow contract allowed");
        _;
    }

    // mapping to assign the id for each company while registering
    mapping(uint256 => OmaxxPlatformLibrary.Company) public registeredCompanies;

    mapping(uint256 => bool) public isCompanyAlloted;


    /**
    @dev this function will set the omaxx escrow contract for this contract calls
    @param _omaxxEscrow omaxxEscrow Contract address
     */
    function setOmaxxEscrowContract(address _omaxxEscrow) public onlyOwner {
        require(_omaxxEscrow != address(0x0), "OmaxxPlatform: null address");
        omaxxEscrowContract = _omaxxEscrow;
    }


    /**
    @dev this function will be called publicaly by the company that is going to register
    @param _companyDetails information about the company registration
    */
    function registerCompany(OmaxxPlatformLibrary.Company memory _companyDetails) public {
        
        uint256 newCompanyID = companyIDTracker + 1;

        require(_companyDetails.companyOwner != address(0x0), "OmaxxPlatform: null address");
        require(_companyDetails.fundRaiseGoal > minFundRaiseRequired, "OmaxxPlatform: too low for fund raising");
        require(_companyDetails.maxSupply >= _companyDetails.fundRaiseGoal, "OmaxxPlatform: supply error");
        require(_companyDetails.decimal > 0, "OmaxxPlatform: decimals error");
        require(_companyDetails.companyTokenContract == address(0x0), "OmaxxPlatform: contract address error");
        require(_companyDetails.investedAmount == 0, "OmaxxPlatform: contract address error");

        registeredCompanies[newCompanyID] = OmaxxPlatformLibrary.Company(
            _companyDetails.companyOwner,
            _companyDetails.companyName,
            _companyDetails.fundRaiseDeadline,
            _companyDetails.fundRaiseGoal,
            0,
            _companyDetails.tokenName,
            _companyDetails.tokenSymbol,
            _companyDetails.decimal,
            _companyDetails.maxSupply,
            false,
            address(0x0),
            OmaxxPlatformLibrary.CompanyStatus.Registered
        );

        isCompanyAlloted[newCompanyID] = true;
        companyIDTracker++;

    }

    function updateCompanyDetails(uint256 _companyId, uint256 _investedAmount, bool _isFundRaiseCompleted,OmaxxPlatformLibrary.CompanyStatus _companyStatus) external onlyEscrowContract {

       registeredCompanies[_companyId].investedAmount = _investedAmount;
       registeredCompanies[_companyId].isFundRaiseCompleted = _isFundRaiseCompleted;
       registeredCompanies[_companyId].companystatus = _companyStatus;

    }

    function updateCompanyTokenAddress(uint256 _companyId, address _companyTokenDeployed) external onlyEscrowContract {

       registeredCompanies[_companyId].companyTokenContract = _companyTokenDeployed;

    }

    /**
    @dev this function will set the minFundRaisedRequired only by the admin
    @param _minFund value required for the min fund raising for each company
     */
    function setMinFundRaiseRequired(uint _minFund) public onlyOwner {
        require(_minFund > 0, "OmaxxPlatform: minfund error");
        minFundRaiseRequired = _minFund;
    }

    function getCompanyDetails(uint256 _companyId) external view returns (OmaxxPlatformLibrary.Company memory) {
        return registeredCompanies[_companyId];
    }

    function isRegisteredCompany(uint256 _companyId) external view returns(bool) {
        return isCompanyAlloted[_companyId];
    }

    function getcompanyIDTracker() external view returns(uint256) {
        return companyIDTracker;
    } 


    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library OmaxxPlatformLibrary {
    using SafeMath for uint256;

    enum CompanyStatus {
        Registered,
        FundGoalCompleted,
        TokenCreated
    }

    struct Investor {
        // address of the investor
        address investor;
        // investment amount raised for the company
        uint256 investedAmount;
        // claimed token flag for the investor
        bool isClaimedToken;
        // refund invested amount flaf for the investor
        bool isRefundedInvestment;
        // invested token address
        address investedTokenAddress; // @dev note: stable coin only
    }

    struct Company {
        // company owner/representative address
        address companyOwner;
        // name of the company
        string companyName;
        // end time for the company
        uint256 fundRaiseDeadline;
        // amount of dollars in stable currency
        uint256 fundRaiseGoal;
        // invested amount by the investors
        uint256 investedAmount;
        // name of the company token
        string tokenName;
        // symbol of the company token
        string tokenSymbol;
        // decimals for the fractionalizing token
        uint8 decimal;
        // maximum supply for the company token
        uint256 maxSupply;
        // flag for the fund raise completed or not
        bool isFundRaiseCompleted;
        // address of the token contract after successful completion of goal
        address companyTokenContract;
        // current status of the company
        CompanyStatus companystatus;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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