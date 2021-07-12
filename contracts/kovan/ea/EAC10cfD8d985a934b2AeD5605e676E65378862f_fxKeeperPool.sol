// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/Bank/ILiquidator.sol";
import "../interfaces/Bank/IHandle.sol";
import "../interfaces/Bank/IHandleComponent.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/Bank/IfxKeeperPool.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/IERC20.sol";

contract fxKeeperPool is
    IfxKeeperPool,
    IValidator,
    Initializable,
    UUPSUpgradeable,
    IHandleComponent,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeMath for int256;

    uint256 public constant SCALE_FACTOR = 1e9;
    uint256 public constant DECIMAL_PRECISION = 1e9;

    IHandle private handle;
    ILiquidator private liquidator;
    ITreasury private treasury;
    IVaultLibrary private vaultLibrary;

    mapping(address => Pool) internal pools;

    modifier validFxToken(address token) {
        require(handle.isFxTokenValid(token), "IF");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setHandleContract(address _handle) public override onlyOwner {
        handle = IHandle(_handle);
        treasury = ITreasury(handle.treasury());
        liquidator = ILiquidator(handle.liquidator());
        vaultLibrary = IVaultLibrary(handle.vaultLibrary());
    }

    function handleAddress() public view override returns (address) {
        return address(handle);
    }

    /**
     * @notice stake fxToken
     * @param amount amount to stake
     * @param fxToken pool token address
     */
    function stake(uint256 amount, address fxToken)
        external
        override
        validFxToken(fxToken)
        nonReentrant
    {
        // Transfer token and add to total stake.
        require(
            IERC20(fxToken).allowance(msg.sender, address(this)) >= amount,
            "fxKeeperPool: fxToken ERC20 allowance not met"
        );
        // Withdraw current rewards.
        Deposit storage deposit = pools[fxToken].deposits[msg.sender];
        if (deposit.snapshot.P > 0) {
            // TODO: This will result in two _updateDeposit calls by the end of this function. Optimise this by creating new function that only performs the ERC20 transfer to be used in all unstake, withdrawCollateralReward and here.
            _withdrawCollateralRewardFrom(msg.sender, fxToken);
        }
        _checkInitialisePool(fxToken);
        // Transfer token and increase total deposits.
        IERC20(fxToken).transferFrom(msg.sender, address(this), amount);
        pools[fxToken].totalDeposits = pools[fxToken].totalDeposits.add(amount);
        // Update deposit data.
        uint256 staked = balanceOfStake(msg.sender, fxToken);
        uint256 newDeposit = staked.add(amount);
        _updateDeposit(msg.sender, newDeposit, fxToken);
        // Withdraw existing collateral rewards.
        emit Stake(msg.sender, fxToken, amount);
    }

    /**
     * @notice unstake fxToken
     * @param amount amount to unstake
     * @param fxToken pool token address
     */
    function unstake(uint256 amount, address fxToken)
        external
        override
        validFxToken(fxToken)
        nonReentrant
    {
        // Get staked amount.
        uint256 stakedAmount = balanceOfStake(msg.sender, fxToken);
        // Limit requested unstake amount to maximum available.
        if (amount > stakedAmount) amount = stakedAmount;
        require(amount > 0, "IA");
        // Withdraw existing collateral rewards before proceeding.
        _withdrawCollateralRewardFrom(msg.sender, fxToken);
        // Subtract total staked amount for pool and send tokens to depositor.
        assert(pools[fxToken].totalDeposits >= amount);
        IERC20(fxToken).transfer(msg.sender, amount);
        pools[fxToken].totalDeposits = pools[fxToken].totalDeposits.sub(amount);
        // Update deposit.
        uint256 newDeposit = stakedAmount.sub(amount);
        _updateDeposit(msg.sender, newDeposit, fxToken);
        emit Unstake(msg.sender, fxToken, amount);
    }

    /**
     * @notice withdraws all collateral rewards from pool
     * @param fxToken pool token address to withdraw rewards for
     */
    function withdrawCollateralReward(address fxToken)
        external
        override
        validFxToken(fxToken)
        nonReentrant
    {
        _withdrawCollateralRewardFrom(msg.sender, fxToken);
    }

    function _withdrawCollateralRewardFrom(address account, address fxToken)
        private
    {
        if (pools[fxToken].snapshot.P == 0) return;
        // Withdraw all collateral rewards.
        (
            address[] memory collateralTokens,
            uint256[] memory collateralAmounts
        ) = balanceOfRewards(account, fxToken);
        assert(collateralTokens.length > 0);

        uint256 j = collateralTokens.length;
        for (uint256 i = 0; i < j; i++) {
            if (collateralAmounts[i] == 0) continue;
            IERC20(collateralTokens[i]).transfer(account, collateralAmounts[i]);
            // Update total collateral balance.
            pools[fxToken].collateralBalances[collateralTokens[i]] = pools[
                fxToken
            ]
                .collateralBalances[collateralTokens[i]]
                .sub(collateralAmounts[i]);
        }
        // Update deposit.
        uint256 stake = balanceOfStake(account, fxToken);
        _updateDeposit(account, stake, fxToken);
        emit Withdraw(account, fxToken);
    }

    /**
     * @notice retrieves account's current staked amount in pool
     * @param account address to fetch balance from
     * @param fxToken pool token address
     */
    function balanceOfStake(address account, address fxToken)
        public
        view
        override
        validFxToken(fxToken)
        returns (uint256 amount)
    {
        // Return zero if pool was not initialised.
        if (pools[fxToken].snapshot.P == 0) return 0;
        amount = pools[fxToken].deposits[account].amount;
        if (amount == 0) return 0;
        Snapshot storage dSnapshot = pools[fxToken].deposits[account].snapshot;
        Snapshot storage pSnapshot = pools[fxToken].snapshot;
        if (dSnapshot.epoch < pSnapshot.epoch) return 0;
        uint256 scaleDiff = pSnapshot.scale.sub(dSnapshot.scale);
        if (scaleDiff == 0) {
            amount = amount.mul(pSnapshot.P).div(dSnapshot.P);
        } else if (scaleDiff == 1) {
            amount = amount.mul(pSnapshot.P).div(dSnapshot.P).div(SCALE_FACTOR);
        } else {
            amount = 0;
        }
    }

    /**
     * @notice retrieves account's current reward amount in pool
     * @param account address to fetch rewards from
     * @param fxToken pool token address
     */
    function balanceOfRewards(address account, address fxToken)
        public
        view
        override
        validFxToken(fxToken)
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        )
    {
        Pool storage pool = pools[fxToken];
        uint256 depositAmount = pool.deposits[account].amount;
        Snapshot storage snapshot = pool.deposits[account].snapshot;
        // User never deposited if P is zero.
        if (snapshot.P == 0) {
            collateralTypes = new address[](0);
            collateralAmounts = new uint256[](0);
            return (collateralTypes, collateralAmounts);
        }
        collateralTypes = handle.getAllCollateralTypes();
        uint256 j = collateralTypes.length;
        collateralAmounts = new uint256[](j);

        for (uint256 i = 0; i < j; i++) {
            uint256 firstPortion =
                pool.epochToScaleToCollateralToSum[snapshot.epoch][
                    snapshot.scale
                ][collateralTypes[i]]
                    .sub(snapshot.collateralToSum[collateralTypes[i]]);
            uint256 secondPortion =
                pool.epochToScaleToCollateralToSum[snapshot.epoch][
                    snapshot.scale.add(1)
                ][collateralTypes[i]]
                    .div(SCALE_FACTOR);
            collateralAmounts[i] = depositAmount
                .mul(firstPortion.add(secondPortion))
                .div(snapshot.P)
                .div(DECIMAL_PRECISION);
        }
    }

    /**
     * @notice retrieves current stake share for account
     * @dev 18-digit ratio (1e18 = 100% of shares)
     * @param account address to fetch share from
     * @param fxToken pool token address
     */
    function shareOf(address account, address fxToken)
        public
        view
        override
        validFxToken(fxToken)
        returns (uint256 share)
    {
        uint256 total = pools[fxToken].totalDeposits;
        if (total == 0) return 0;
        uint256 _stake = balanceOfStake(account, fxToken);
        share = _stake.mul(1 ether).div(total);
    }

    /**
     * @notice attempt to liquidate vault
     * @param account address to perform liquidation on
     * @param fxToken vault's fxToken address
     */
    function liquidate(address account, address fxToken)
        external
        override
        validFxToken(fxToken)
        nonReentrant
    {
        // Purchase collateral to restore vault's CR.
        (
            uint256 fxAmount,
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        ) = executeLiquidation(account, fxToken);
        // Update pool state with new debt and collateral values.
        absorbDebt(fxAmount, collateralTypes, collateralAmounts, fxToken);
        emit Liquidate(account, fxToken, fxAmount);
    }

    /**
     * @notice executes a liquidation using pool fxTokens.
               reverts if pool does not have enough fxTokens to fund liquidation.
     * @param account address to perform liquidation on
     * @param fxToken vault's fxToken address
     */
    function executeLiquidation(address account, address fxToken)
        private
        returns (
            uint256 fxAmount,
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        )
    {
        IERC20(fxToken).approve(address(liquidator), fxAmount);
        (fxAmount, collateralTypes, collateralAmounts) = liquidator.liquidate(
            account,
            fxToken
        );
    }

    function absorbDebt(
        uint256 debt,
        address[] memory collateralTypes,
        uint256[] memory collateralAmounts,
        address fxToken
    ) private {
        if (pools[fxToken].totalDeposits == 0 || debt == 0) return;
        // Increase pool collateral balances.
        uint256 l = collateralTypes.length;
        for (uint256 i = 0; i < l; i++) {
            if (collateralAmounts[i] == 0) continue;
            pools[fxToken].collateralBalances[collateralTypes[i]] = pools[
                fxToken
            ]
                .collateralBalances[collateralTypes[i]]
                .add(collateralAmounts[i]);
        }
        _updateFxLossPerUnitStaked(
            debt,
            collateralTypes,
            collateralAmounts,
            fxToken
        );
        _updateCollateralGainSums(collateralTypes, collateralAmounts, fxToken);
        _updateSnapshotValues(debt, fxToken);
        pools[fxToken].totalDeposits = pools[fxToken].totalDeposits.sub(debt);
    }

    /**
     * @notice updates the fxLossPerUnitStaked property in the pool struct
     * @param debtToAbsorb the debt being absorbed by the pool
     * @param fxToken token address to get the pool from
     */
    function _updateFxLossPerUnitStaked(
        uint256 debtToAbsorb,
        address[] memory collateralTypes,
        uint256[] memory collateralAmounts,
        address fxToken
    ) private {
        Pool storage pool = pools[fxToken];
        assert(debtToAbsorb <= pool.totalDeposits);
        if (debtToAbsorb == pool.totalDeposits) {
            // Emptying pool.
            pool.fxLossPerUnitStaked = DECIMAL_PRECISION;
            pool.lastErrorFxLossPerUnitStaked = 0;
        } else {
            // Get numerator accounting for last error.
            uint256 lossNumerator =
                debtToAbsorb.mul(DECIMAL_PRECISION).sub(
                    pool.lastErrorFxLossPerUnitStaked
                );
            // Add one to have a larger fx loss ratio error to favour the pool.
            pool.fxLossPerUnitStaked = lossNumerator
                .div(pool.totalDeposits)
                .add(1);
            // Update error value.
            pool.lastErrorFxLossPerUnitStaked = pool
                .fxLossPerUnitStaked
                .mul(pool.totalDeposits)
                .sub(lossNumerator);
        }
    }

    /**
     * @notice updates the collateral gain ratios and sums to be used for withdrawal
     * @param collateralTypes collateral received type array
     * @param collateralAmounts collateral received amount array
     */
    function _updateCollateralGainSums(
        address[] memory collateralTypes,
        uint256[] memory collateralAmounts,
        address fxToken
    ) private {
        Pool storage pool = pools[fxToken];
        // Update collateral gain ratios.
        uint256 gainPerUnitStaked = 0;
        uint256 j = collateralTypes.length;
        for (uint256 i = 0; i < j; i++) {
            // Calculate gain numerator.
            uint256 gainNumerator =
                collateralAmounts[i].mul(DECIMAL_PRECISION).add(
                    pool.lastErrorCollateralGainRatio[collateralTypes[i]]
                );
            // Set gain per unit staked.
            gainPerUnitStaked = gainNumerator.div(pool.totalDeposits);
            // Update error for this collateral type.
            pool.lastErrorCollateralGainRatio[
                collateralTypes[i]
            ] = gainNumerator.sub(gainPerUnitStaked.mul(pool.totalDeposits));
            uint256 currentS =
                pool.epochToScaleToCollateralToSum[pool.snapshot.epoch][
                    pool.snapshot.scale
                ][collateralTypes[i]];
            uint256 marginalGain = gainPerUnitStaked.mul(pool.snapshot.P);
            // Update S.
            uint256 newS = currentS.add(marginalGain);
            pool.epochToScaleToCollateralToSum[pool.snapshot.epoch][
                pool.snapshot.scale
            ][collateralTypes[i]] = newS;
        }
    }

    /**
     * @notice updates the fxLossPerUnitStaked property in the pool struct
     * @param fxLossPerUnitStaked the ratio of fx loss per unit staked
     * @param fxToken token address to get the pool from
     */
    function _updateSnapshotValues(uint256 fxLossPerUnitStaked, address fxToken)
        private
    {
        Pool storage pool = pools[fxToken];
        assert(pool.fxLossPerUnitStaked <= DECIMAL_PRECISION);
        uint256 currentP = pool.snapshot.P;
        uint256 newP;
        // Factor by which to change all deposits.
        uint256 newProductFactor =
            DECIMAL_PRECISION.sub(pool.fxLossPerUnitStaked);
        if (newProductFactor == 0) {
            // Emptied pool.
            pool.snapshot.epoch = pool.snapshot.epoch.add(1);
            pool.snapshot.scale = 0;
            newP = DECIMAL_PRECISION;
        } else if (
            currentP.mul(newProductFactor).div(DECIMAL_PRECISION) < SCALE_FACTOR
        ) {
            // Update scale due to P value.
            newP = currentP.mul(newProductFactor).mul(SCALE_FACTOR).div(
                DECIMAL_PRECISION
            );
            pool.snapshot.scale = pool.snapshot.scale.add(1);
        } else {
            newP = currentP.mul(newProductFactor).div(DECIMAL_PRECISION);
        }
        assert(newP > 0);
        pool.snapshot.P = newP;
    }

    function _updateDeposit(
        address account,
        uint256 amount,
        address fxToken
    ) private {
        pools[fxToken].deposits[account].amount = amount;
        if (amount == 0) {
            delete pools[fxToken].deposits[account];
            return;
        }
        // Update deposit snapshot.
        Snapshot storage poolSnapshot = pools[fxToken].snapshot;
        Snapshot storage depositSnapshot =
            pools[fxToken].deposits[account].snapshot;
        depositSnapshot.P = poolSnapshot.P;
        depositSnapshot.scale = poolSnapshot.scale;
        depositSnapshot.epoch = poolSnapshot.epoch;
        address[] memory collateralTypes = handle.getAllCollateralTypes();

        uint256 j = collateralTypes.length;
        for (uint256 i = 0; i < j; i++) {
            depositSnapshot.collateralToSum[collateralTypes[i]] = poolSnapshot
                .collateralToSum[collateralTypes[i]];
        }
    }

    function _checkInitialisePool(address fxToken) private {
        if (pools[fxToken].snapshot.P != 0) return;
        pools[fxToken].snapshot.P = DECIMAL_PRECISION;
    }

    function getPoolCollateralBalance(address fxToken, address collateral)
        external
        view
        override
        returns (uint256 amount)
    {
        return pools[fxToken].collateralBalances[collateral];
    }

    function getPoolTotalDeposit(address fxToken)
        external
        view
        override
        returns (uint256 amount)
    {
        return pools[fxToken].totalDeposits;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ILiquidator {
    event Redeem(
        address from,
        address token,
        uint256 tokenAmount,
        uint256[] collateralAmounts,
        address[] collateralTypes
    );

    event Liquidate(
        address from,
        address token,
        uint256 tokenAmount,
        uint256[] collateralAmounts,
        address[] collateralTypes
    );

    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline
    )
        external
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes,
            uint256 etherAmount
        );

    function buyCollateralFromManyVaults(
        uint256 amount,
        address token,
        address[] memory from,
        uint256 deadline
    )
        external
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes,
            uint256 etherAmount
        );

    function getLiquidationRatio(address account, address fxToken)
        external
        view
        returns (uint256);

    function liquidate(address account, address fxToken)
        external
        returns (
            uint256 fxAmount,
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        );

    function tokensRequiredForCrIncrease(
        uint256 crTarget,
        uint256 debt,
        uint256 collateral,
        uint256 returnRatio
    ) external pure returns (uint256 amount);

    function getAllowedBuyCollateralFromTokenAmount(
        uint256 amount,
        address token,
        address from
    ) external view returns (uint256 allowedAmount, bool isLiquidation);

    function crScalar() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IHandle {
    struct Vault {
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 debt;
        // TODO: Remove this or change to something relevant e.g. lastCompoundDate (?)
        uint256 interestLastUpdateDate;
        // Collateral token address => R0
        mapping(address => uint256) R0;
    }

    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationFee;
        uint256 interestRate;
    }

    event UpdateDebt(address indexed account, address indexed fxToken);

    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    event ConfigureCollateralToken(address indexed collateralToken);

    event ConfigureFxToken(address indexed fxToken);

    function setCollateralUpperBoundPCT(uint256 ratio) external;

    function setFxToken(address token) external;

    function removeFxToken(address token) external;

    function setCollateralToken(
        address token,
        uint256 mintCR,
        uint256 liquidationFee,
        uint256 interestRatePerMille
    ) external;

    function removeCollateralToken(address token) external;

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getAllFxTokens() external view returns (address[] memory tokens);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function comptroller() external view returns (address);

    function vaultLibrary() external view returns (address);

    function fxKeeperPool() external view returns (address);

    function pct() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (address);

    function pctCollateralUpperBound() external view returns (uint256);

    function isFxTokenValid(address fxToken) external view returns (bool);

    function isCollateralValid(address collateral) external view returns (bool);

    function collateralTokens(uint256 i) external view returns (address);

    function setComponents(address[] memory components) external;

    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function updateCollateralBalance(
        address account,
        uint256 amount,
        address fxToken,
        address collateralToken,
        bool increase
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 depositFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getPrincipalDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function getCollateralR0(
        address account,
        address fxToken,
        address collateral
    ) external view returns (uint256 R0);

    function getTokenPrice(address token) external view returns (uint256 quote);

    function setOracle(address fxToken, address oracle) external;

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);

    function depositFeePerMille() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IHandleComponent {
    function setHandleContract(address hanlde) external;

    function handleAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITreasury {
    function depositCollateral(
        address account,
        uint256 depositAmount,
        address collateralType,
        address fxToken
    ) external;

    function depositCollateralETH(address account, address fxToken)
        external
        payable;

    function withdrawCollateral(
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralETH(
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralFrom(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function forceWithdrawCollateral(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function forceWithdrawAnyCollateral(
        address from,
        address to,
        uint256 amount,
        address fxToken
    )
        external
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        );

    function requestFundsPCT(address token, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IValidator {
    modifier dueBy(uint256 date) {
        require(block.timestamp <= date, "Transaction has exceeded deadline");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid Address");
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IfxKeeperPool {
    struct Pool {
        mapping(address => Deposit) deposits;
        mapping(address => uint256) collateralBalances;
        mapping(uint256 => mapping(uint256 => mapping(address => uint256))) epochToScaleToCollateralToSum;
        uint256 totalDeposits;
        Snapshot snapshot;
        // Forex token loss per unit staked data.
        uint256 fxLossPerUnitStaked;
        uint256 lastErrorFxLossPerUnitStaked;
        mapping(address => uint256) lastErrorCollateralGainRatio;
    }

    struct Snapshot {
        mapping(address => uint256) collateralToSum;
        uint256 P;
        uint256 scale;
        uint256 epoch;
    }

    struct Deposit {
        uint256 amount;
        Snapshot snapshot;
    }

    event Liquidate(
        address indexed account,
        address indexed token,
        uint256 tokenAmount
    );

    event Stake(address indexed account, address indexed token, uint256 amount);

    event Unstake(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event Withdraw(address indexed account, address indexed token);

    function stake(uint256 amount, address fxToken) external;

    function unstake(uint256 amount, address fxToken) external;

    function withdrawCollateralReward(address fxToken) external;

    function balanceOfStake(address account, address fxToken)
        external
        view
        returns (uint256 amount);

    function balanceOfRewards(address account, address fxToken)
        external
        view
        returns (
            address[] memory collateralTokens,
            uint256[] memory collateralAmounts
        );

    function shareOf(address account, address fxToken)
        external
        view
        returns (uint256 share);

    function liquidate(address account, address fxToken) external;

    function getPoolCollateralBalance(address fxToken, address collateral)
        external
        view
        returns (uint256 amount);

    function getPoolTotalDeposit(address fxToken)
        external
        view
        returns (uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultLibrary {
    function doesMeetRatio(address account, address fxToken)
        external
        view
        returns (bool);

    function getFreeCollateralAsEth(address account, address fxToken)
        external
        view
        returns (uint256);

    function getFreeCollateralAsEthFromMinimumRatio(
        address account,
        address fxToken,
        uint256 minimumRatio
    ) external view returns (uint256);

    function getMinimumRatio(address account, address fxToken)
        external
        view
        returns (uint256 ratio);

    function getMinimumCollateral(
        uint256 tokenAmount,
        uint256 ratio,
        uint256 unitPrice
    ) external view returns (uint256 minimum);

    function getDebtAsEth(address account, address fxToken)
        external
        view
        returns (uint256 debt);

    function getTotalCollateralBalanceAsEth(address account, address fxToken)
        external
        view
        returns (uint256 balance);

    function getCurrentRatio(address account, address fxToken)
        external
        view
        returns (uint256 ratio);

    function getCollateralForAmount(
        address account,
        address fxToken,
        uint256 amountEth
    )
        external
        view
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts,
            bool metAmount
        );

    function calculateInterest(address account, address fxToken)
        external
        view
        returns (uint256 interest);

    function getInterestRate(address account, address fxToken)
        external
        view
        returns (uint256 rate);

    function getInterestDeltaR(address account, address fxToken)
        external
        view
        returns (uint256 dR);

    function getLiquidationFee(address account, address fxToken)
        external
        view
        returns (uint256 fee);

    function getCollateralShares(address account, address fxToken)
        external
        view
        returns (uint256[] memory shares);

    function getCollateralTypesSortedByLiquidationRank()
        external
        view
        returns (address[] memory sortedCollateralTypes);

    function getNewMinimumRatio(
        address account,
        address fxToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralQuote,
        bool isDeposit
    ) external view returns (uint256 ratio, uint256 newCollateralAsEther);

    function canMint(
        address account,
        address fxToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 tokenAmount,
        uint256 fxQuote,
        uint256 collateralQuote
    ) external view returns (bool);

    function quickSort(
        uint256[] memory array,
        int256 left,
        int256 right
    ) external pure;

    function getTokenUnit(address token) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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
  },
  "libraries": {}
}