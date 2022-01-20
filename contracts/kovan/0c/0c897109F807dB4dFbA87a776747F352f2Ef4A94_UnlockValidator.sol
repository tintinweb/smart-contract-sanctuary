// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../interfaces/tokens/validator/IUnlockValidator.sol";

contract UnlockValidator is IUnlockValidator, Ownable {
    /* ========== STATE VARIABLES ========== */

    // Mapping of blocked unlock accounts
    mapping(address => bool) private _isInvalidated;

    /* ========== VIEWS ========== */

    function isValid(
        address user,
        uint256,
        IUSDV.LockTypes
    ) external view override returns (bool) {
        return !_isInvalidated[user];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /*
     * @dev Sets an address as invalidated
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function invalidate(address _account) external onlyOwner {
        require(
            !_isInvalidated[_account],
            "UnlockValidator::invalidate: Already Invalid"
        );
        _isInvalidated[_account] = true;
        emit Invalidate(_account);
    }

    /*
     * @dev Removes invalidation from an address
     *
     * Requirements:
     * - Only existing owner can call this function.
     **/
    function validate(address _account) external onlyOwner {
        require(
            _isInvalidated[_account],
            "UnlockValidator::validate: Already Valid"
        );
        _isInvalidated[_account] = false;
        emit Validate(_account);
    }
}

// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "../IUSDV.sol";

interface IUnlockValidator {
    function isValid(
        address user,
        uint256 amount,
        IUSDV.LockTypes lockType
    ) external view returns (bool);

    event Invalidate(address account);
    event Validate(address account);
}

// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

interface IUSDV {
    /* ========== ENUMS ========== */

    enum LockTypes {
        USDV,
        VADER
    }

    /* ========== STRUCTS ========== */

    struct Lock {
        LockTypes token;
        uint256 amount;
        uint256 release;
    }

    /* ========== FUNCTIONS ========== */

    function mint(
        address account,
        uint256 vAmount,
        uint256 uAmount,
        uint256 exchangeFee,
        uint256 window
    ) external returns (uint256);

    function burn(
        address account,
        uint256 uAmount,
        uint256 vAmount,
        uint256 exchangeFee,
        uint256 window
    ) external returns (uint256);

    /* ========== EVENTS ========== */

    event ExchangeFeeChanged(uint256 previousExchangeFee, uint256 exchangeFee);
    event DailyLimitChanged(uint256 previousDailyLimit, uint256 dailyLimit);
    event LockClaimed(
        address user,
        LockTypes lockType,
        uint256 lockAmount,
        uint256 lockRelease
    );
    event LockCreated(
        address user,
        LockTypes lockType,
        uint256 lockAmount,
        uint256 lockRelease
    );
    event ValidatorSet(address previous, address current);
    event GuardianSet(address previous, address current);
    event LockStatusSet(bool status);
    event MinterSet(address minter);
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