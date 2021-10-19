//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Tournament.sol";
import "../interfaces/ITournamentFactory.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title TournamentFactory
contract TournamentFactory is ITournamentFactory, Ownable {
    using SafeMath for uint256;

    uint256 public taxPercent;

    constructor(uint256 _taxPercent) {
        _setTaxPercent(_taxPercent);
    }

    /// @inheritdoc ITournamentFactory
    function generateTournament(string memory _tournamentId)
        external
        payable
        override
    {
        require(msg.value > 0, "pool cannot be zero");

        uint256 _tax = uint256(msg.value).mul(taxPercent).div(100).div(100);
        uint256 _pool = uint256(msg.value).sub(_tax);

        Tournament instance = new Tournament(
            _tournamentId,
            _pool,
            _tax,
            owner(),
            msg.sender
        );

        (bool sent, ) = payable(address(instance)).call{value: msg.value}("");
        require(sent, "sending pool amt. failed");

        emit NewTournament(_tournamentId, _pool, _tax, address(instance));
    }

    /// @inheritdoc ITournamentFactory
    function updateTaxPercent(uint256 _taxPercent) external override onlyOwner {
        _setTaxPercent(_taxPercent);
        emit TaxUpdated(taxPercent);
    }

    /**
     * @notice internal helper to set tax percentage
     * @param _taxPercent tax percentage to set state with
     */
    function _setTaxPercent(uint256 _taxPercent) internal {
        taxPercent = _taxPercent;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/ITournament.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Tournament
contract Tournament is ITournament {
    using SafeMath for uint256;

    string public tournamentId;

    uint256 public pool;
    uint256 public tax;
    uint256 public totalAvailPrize;

    address public admin;
    address public organizer;

    mapping(address => uint256) public availPrize;

    bool public hasEnabledPrizeDisbursal;

    constructor(
        string memory _tournamentId,
        uint256 _pool,
        uint256 _tax,
        address _admin,
        address _organizer
    ) {
        tournamentId = _tournamentId;
        pool = _pool;
        tax = _tax;

        _setAdmin(_admin);
        _setOrganizer(_organizer);
    }

    /// @notice to correctly receive eth
    receive() external payable {
        require(msg.value == pool.add(tax), "Not enough pool amount sent");
    }

    /// @inheritdoc ITournament
    function getTournamentDetails()
        external
        view
        override
        returns (
            string memory,
            uint256,
            uint256,
            address,
            bool
        )
    {
        return (
            tournamentId,
            pool,
            totalAvailPrize,
            organizer,
            hasEnabledPrizeDisbursal
        );
    }

    /// @inheritdoc ITournament
    function setPlayersToAvailPrize(address _user, uint256 _prizeAmount)
        external
        override
        onlyAdmin
    {
        require(hasEnabledPrizeDisbursal, "prize disbursal not enabled");
        require(_user != address(0), "null address");
        require(
            totalAvailPrize.add(_prizeAmount) <= pool,
            "totalAvailPrize exceeded pool"
        );

        availPrize[_user] += _prizeAmount;
        totalAvailPrize += _prizeAmount;
    }

    /// @inheritdoc ITournament
    function enablePrizeDisbursal() external override onlyOrganizer {
        (bool sent, ) = payable(admin).call{value: tax}("");
        require(sent, "tax payment failed");
        tax = 0;

        hasEnabledPrizeDisbursal = true;

        emit PrizeDisbursal(hasEnabledPrizeDisbursal);
    }

    /// @inheritdoc ITournament
    function redeemPrize() external override {
        require(totalAvailPrize >= pool - 1000, "tournament not complete");
        require(availPrize[msg.sender] > 0, "not eligible to redeem");

        (bool sent, ) = payable(msg.sender).call{value: availPrize[msg.sender]}(
            ""
        );
        require(sent, "prize redeem failed");

        pool -= availPrize[msg.sender];
        availPrize[msg.sender] = 0;
    }

    /// @inheritdoc ITournament
    function refundPool() external override onlyAdmin {
        require(!hasEnabledPrizeDisbursal, "prize disbursal already enabled");

        (bool sent, ) = payable(organizer).call{value: pool + tax}("");
        require(sent, "pool refund failed");

        pool = 0;
        tax = 0;
    }

    /// @inheritdoc ITournament
    function transferAdmin(address _admin) external override onlyAdmin {
        _setAdmin(_admin);
        emit NewAdmin(admin);
    }

    /// @inheritdoc ITournament
    function transferOrganizer(address _organizer)
        external
        override
        onlyOrganizer
    {
        _setOrganizer(_organizer);
        emit NewOrganizer(organizer);
    }

    /**
     * @notice helper to set admin address
     * @param _admin address of new admin
     */
    function _setAdmin(address _admin) internal {
        admin = _admin;
    }

    /**
     * @notice helper to set organizer address
     * @param _organizer address of new organizer
     */
    function _setOrganizer(address _organizer) internal {
        organizer = _organizer;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "unauthorized: requires admin");
        _;
    }

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "unauthorized: requires organizer");
        _;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ITournamentFactory
 * @notice Manages creation of new Tournament contracts, and manages tax calculations
 */
interface ITournamentFactory {
    /// @notice Emits metadata and deployment details of newly created contracts.
    event NewTournament(
        string tournamentId,
        uint256 pool,
        uint256 tax,
        address contractAddress
    );
    /// @notice Emits info about changes in tax percentage
    event TaxUpdated(uint256 taxPercent);

    /**
     * @notice updates tax percentage to take a share from tournament pools
     * @param _taxPercent new tax percentage to update with
     */
    function updateTaxPercent(uint256 _taxPercent) external;

    /// ------ USER FUNCTIONS  ------ ///

    /**
     * @notice creates a new tournament
     * @param _tournamentId ID of tournament from db, to be linked to contract
     */
    function generateTournament(string memory _tournamentId) external payable;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ITournament
 * @notice Manages tournament data, and payment flows, with pool and share distribution
 */
interface ITournament {
    /// emits info when prize disbursal is enabled by tournament organizer
    event PrizeDisbursal(bool enabled);
    /// emits info when admin is updated
    event NewAdmin(address admin);
    /// emits info when organizer is updated
    event NewOrganizer(address organizer);

    /// ------ ADMIN FUNCTIONS  ------ ///

    /**
     * @notice to transfer the admin address
     */
    function transferAdmin(address _admin) external;

    /**
     * @notice admin function to refund pool prize to tournament organizers in case of discrepencies
     */
    function refundPool() external;

    /**
     * @notice sets prize thats reedemable for a player
     * @param _user address of user to set prize for
     * @param _prizeAmount the prize amount to set to user
     */
    function setPlayersToAvailPrize(address _user, uint256 _prizeAmount)
        external;

    /// ------ ORGANIZER FUNCTIONS  ------ ///

    /**
     @notice to transfer the organizer address
     */
    function transferOrganizer(address _organizer) external;

    /**
     * @notice enable disbursal of prizes to distribute rewards to players
     */
    function enablePrizeDisbursal() external;

    /// ------ USER FUNCTIONS  ------ ///

    /**
     * @notice view function to retrieve tournament details
     * @return tournamentId id of tournament
     * @return pool total pool prize amount
     * @return totalAvailPrize total avail prizes set to users
     * @return organizer address of tournament organizer
     * @return hasEnabledPrizeDisbursal state of prize disbursal
     */
    function getTournamentDetails()
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            address,
            bool
        );

    /**
     * @notice for users to redeem their prizes on tournament completion
     */
    function redeemPrize() external;
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