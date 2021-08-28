/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/interfaces/IAssetManager.sol

interface IAssetManager {
    function getCategoryLength() external view returns(uint8);
    function getAssetLength() external view returns(uint256);
    function getAssetToken(uint16 index_) external view returns(address);
    function getAssetCategory(uint16 index_) external view returns(uint8);
    function getIndexesByCategory(uint8 category_, uint256 categoryIndex_) external view returns(uint16);
    function getIndexesByCategoryLength(uint8 category_) external view returns(uint256);
}

// File: contracts/interfaces/IMigratable.sol

interface IMigratable {
    function approveMigration(IMigratable migrateTo_) external;
    function onMigration(address who_, uint256 amount_, bytes memory data_) external;
}

// File: contracts/interfaces/IBuyer.sol

interface IBuyer is IMigratable {
    function premiumForGuarantor(uint16 assetIndex_) external view returns(uint256);
    function premiumForSeller(uint16 assetIndex_) external view returns(uint256);
    function weekToUpdate() external view returns(uint256);
    function currentSubscription(uint16 assetIndex_) external view returns(uint256);
    function futureSubscription(uint16 assetIndex_) external view returns(uint256);
    function assetUtilization(uint16 assetIndex_) external view returns(uint256);
    function isUserCovered(address who_) external view returns(bool);
}

// File: contracts/interfaces/IPremiumCalculator.sol

interface IPremiumCalculator {
    function getPremiumRate(uint16 assetIndex_) external view returns(uint256);
}

// File: contracts/interfaces/IRegistry.sol

interface IRegistry {

    function PERCENTAGE_BASE() external pure returns(uint256);
    function UTILIZATION_BASE() external pure returns(uint256);
    function PREMIUM_BASE() external pure returns(uint256);
    function UNIT_PER_SHARE() external pure returns(uint256);

    function buyer() external view returns(address);
    function seller() external view returns(address);
    function guarantor() external view returns(address);
    function staking() external view returns(address);
    function bonus() external view returns(address);

    function tidalToken() external view returns(address);
    function baseToken() external view returns(address);
    function assetManager() external view returns(address);
    function premiumCalculator() external view returns(address);
    function platform() external view returns(address);

    function guarantorPercentage() external view returns(uint256);
    function platformPercentage() external view returns(uint256);

    function depositPaused() external view returns(bool);

    function stakingWithdrawWaitTime() external view returns(uint256);

    function governor() external view returns(address);
    function committee() external view returns(address);

    function trustedForwarder() external view returns(address);
}

// File: contracts/PremiumCalculator.sol

contract PremiumCalculator is IPremiumCalculator, Ownable {

    IRegistry public registry;

    mapping(uint16 => uint256) private premiumRate;

    constructor (IRegistry registry_) public {
        registry = registry_;
    }

    function setPremiumRate(uint16 assetIndex_, uint256 rate_) external onlyOwner {
        premiumRate[assetIndex_] = rate_;
    }

    function getPremiumRate(uint16 assetIndex_) external override view returns(uint256) {
        return premiumRate[assetIndex_];
    }
}