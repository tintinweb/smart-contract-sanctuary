/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: @openzeppelin/contracts/utils/Context.sol

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
abstract contract Ownable is Context {
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

// File: contracts/Registry.sol

contract Registry is Ownable, IRegistry {

    // The base of percentage.
    uint256 public override constant PERCENTAGE_BASE = 100;

    // The base of utilization.
    uint256 public override constant UTILIZATION_BASE = 1e6;

    // The base of premium rate and accWeeklyCost
    uint256 public override constant PREMIUM_BASE = 1e6;

    // For improving precision of bonusPerShare.
    uint256 public override constant UNIT_PER_SHARE = 1e18;

    address public override buyer;
    address public override seller;
    address public override guarantor;
    address public override staking;
    address public override bonus;

    address public override tidalToken;
    address public override baseToken;
    address public override assetManager;
    address public override premiumCalculator;
    address public override platform;  // Fees go here.

    uint256 public override guarantorPercentage = 5;  // 5%
    uint256 public override platformPercentage = 5;  // 5%

    uint256 public override stakingWithdrawWaitTime = 14 days;

    bool public override depositPaused = false;

    address public override governor;
    address public override committee;

    address public override trustedForwarder;

    function setBuyer(address buyer_) external onlyOwner {
        require(buyer == address(0), "Can set only once");
        buyer = buyer_;
    }

    function setSeller(address seller_) external onlyOwner {
        require(seller == address(0), "Can set only once");
        seller = seller_;
    }

    function setGuarantor(address guarantor_) external onlyOwner {
        require(guarantor == address(0), "Can set only once");
        guarantor = guarantor_;
    }

    // Upgradable, in case we want to change staking pool.
    function setStaking(address staking_) external onlyOwner {
        staking = staking_;
    }

    // Upgradable, in case we want to change mining algorithm.
    function setBonus(address bonus_) external onlyOwner {
        bonus = bonus_;
    }

    function setTidalToken(address tidalToken_) external onlyOwner {
        require(tidalToken == address(0), "Can set only once");
        tidalToken = tidalToken_;
    }

    function setBaseToken(address baseToken_) external onlyOwner {
        require(baseToken == address(0), "Can set only once");
        baseToken = baseToken_;
    }

    function setAssetManager(address assetManager_) external onlyOwner {
        require(assetManager == address(0), "Can set only once");
        assetManager = assetManager_;
    }

    // Upgradable, in case we want to change premium formula.
    function setPremiumCalculator(address premiumCalculator_) external onlyOwner {
        premiumCalculator = premiumCalculator_;
    }

    // Upgradable.
    function setPlatform(address platform_) external onlyOwner {
        platform = platform_;
    }

    // Upgradable.
    function setGuarantorPercentage(uint256 percentage_) external onlyOwner {
        require(percentage_ < PERCENTAGE_BASE, "Invalid input");
        guarantorPercentage = percentage_;
    }

    // Upgradable.
    function setPlatformPercentage(uint256 percentage_) external onlyOwner {
        require(percentage_ < PERCENTAGE_BASE, "Invalid input");
        platformPercentage = percentage_;
    }

    // Upgradable.
    function setStakingWithdrawWaitTime(uint256 stakingWithdrawWaitTime_) external onlyOwner {
        stakingWithdrawWaitTime = stakingWithdrawWaitTime_;
    }

    // Upgradable.
    function setDepositPaused(bool paused_) external onlyOwner {
        depositPaused = paused_;
    }

    // Upgradable.
    function setGovernor(address governor_) external onlyOwner {
        governor = governor_;
    }

    // Upgradable.
    function setCommittee(address committee_) external onlyOwner {
        committee = committee_;
    }

    // Upgradable.
    function setTrustedForwarder(address trustedForwarder_) external onlyOwner {
        trustedForwarder = trustedForwarder_;
    }
}