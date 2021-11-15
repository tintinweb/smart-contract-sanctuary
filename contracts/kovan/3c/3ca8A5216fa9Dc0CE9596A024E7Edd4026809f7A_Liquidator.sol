// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/Bank/ILiquidator.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/Bank/IfxToken.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/Bank/IHandle.sol";
import "../interfaces/Bank/IHandleComponent.sol";
import "../interfaces/Bank/IInterest.sol";
import "../interfaces/Bank/IfxKeeperPool.sol";
import "../interfaces/Bank/IReferral.sol";

/**
 * @dev Implements vault redemptions and liquidations.
 */
contract Liquidator is
    ILiquidator,
    IValidator,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IHandleComponent,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;

    /** @dev The Handle contract interface */
    IHandle private handle;
    /** @dev The Treasury contract interface */
    ITreasury private treasury;
    /** @dev The VaultLibrary contract interface */
    IVaultLibrary private vaultLibrary;

    /** @dev Percent of the minimum CR over 100% to liquidate the target vault
             to. e.g. a value of 10 liquidated the vault to 110% of the
             minimum CR. */
    uint256 public override crScalar;
    /** @dev Threshold of Keeper Pools' ETH staked amount at which only
             the KeeperPool is allowed to perform liquidations. */
    uint256 public override keeperPoolThreshold;
    /** @dev Ratio of liquidation fee to be applied on redemptions. */
    uint256 public override redemptionFeeRatio;
    /** @dev Protocol ratio for redemption fees. */
    uint256 public override protocolRedemptionFeeRatio;

    modifier validFxToken(address token) {
        require(handle.isFxTokenValid(token), "IF");
        _;
    }

    /** @dev Proxy initialisation function */
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Setter for Handle contract reference
     * @param _handle The Handle contract address
     */
    function setHandleContract(address _handle) public override onlyOwner {
        handle = IHandle(_handle);
        treasury = ITreasury(handle.treasury());
        vaultLibrary = IVaultLibrary(handle.vaultLibrary());
    }

    /**
     * @dev Setter for the safety post-liquidation CR scalar.
     * @param value The value to set crScalar to.
     */
    function setCrScalar(uint256 value) external override onlyOwner {
        crScalar = value;
    }

    /**
     * @dev Setter for the keeper pool threshold.
     * @param amount The amount of ETH to set the keeper pool threshold to.
     */
    function setKeeperPoolThreshold(uint256 amount)
        external
        override
        onlyOwner
    {
        keeperPoolThreshold = amount;
    }

    /**
     * @dev Setter for the redemption fee ratio.
     * @param ratio The ratio to set the redemptionFeeRatio to.
     */
    function setRedemptionFeeRatio(uint256 ratio) external override onlyOwner {
        require(ratio <= 1 ether, "0<R<=1");
        redemptionFeeRatio = ratio;
    }

    /**
     * @dev Setter for the protocol redemption fee ratio.
     * @param ratio The ratio to set the protocolRedemptionFeeRatio to.
     */
    function setProtocolRedemptionFeeRatio(uint256 ratio)
        external
        override
        onlyOwner
    {
        require(ratio <= 1 ether, "0<R<=1");
        protocolRedemptionFeeRatio = ratio;
    }

    /** @dev Getter for Handle contract address */
    function handleAddress() public view override returns (address) {
        return address(handle);
    }

    /**
     * @dev Buy collateral from a vault at a 1:1 asset/collateral price ratio.
            Token must have been pre-approved for transfer with input amount.
     * @param amount The amount of fxTokens to redeem with
     * @param token The fxToken to buy collateral with
     * @param from The account to purchase from
     * @param deadline The deadline for the transaction
     * @param referral The referral account
     */
    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline,
        address referral
    )
        external
        override
        dueBy(deadline)
        validFxToken(token)
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes,
            uint256 etherAmount
        )
    {
        IReferral(handle.referral()).setReferral(msg.sender, referral);
        return _buyCollateral(amount, token, from);
    }

    /**
     * @dev Buys collateral from multiple vaults until request is fulfilled.
            Token must have been pre-approved for transfer with input amount
     * @param amount The amount of fxTokens to redeem with
     * @param token The fxToken to buy collateral with
     * @param from The array of accounts to purchase from
     * @param deadline The deadline for the transaction
     */
    function buyCollateralFromManyVaults(
        uint256 amount,
        address token,
        address[] memory from,
        uint256 deadline,
        address referral
    )
        external
        override
        dueBy(deadline)
        validFxToken(token)
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes,
            uint256 etherAmount
        )
    {
        IReferral(handle.referral()).setReferral(msg.sender, referral);
        collateralTypes = handle.getAllCollateralTypes();
        collateralAmounts = new uint256[](collateralTypes.length);
        etherAmount = 0;
        // Working array to bypass stack becoming too deep.
        // 0 = tokenPrice
        // 1 = etherAmountLeft
        // 2 = loop iteration ether amount received from buyCollateral
        // 3 = from.length
        uint256[] memory a = new uint256[](4);
        a[0] = handle.getTokenPrice(token);
        a[1] = amount.mul(a[0]).div(vaultLibrary.getTokenUnit(token));
        a[2] = 0;
        a[3] = from.length;
        // Loop iteration amounts received.
        uint256[] memory amounts;
        for (uint256 i = 0; i < a[3]; i++) {
            {
                address[] memory ct;
                uint256 eAmount;
                (amounts, ct, eAmount) = _buyCollateral(amount, token, from[i]);
                a[2] = eAmount;
            }
            // Add to main amounts array.
            for (uint256 j = 0; j < collateralTypes.length; j++) {
                collateralAmounts[j] = collateralAmounts[j].add(amounts[j]);
            }
            a[1] = a[2] > a[1] ? 0 : a[1].sub(a[2]);
            etherAmount = etherAmount.add(a[2]);
            if (a[1] == 0) break;
            {
                amount = a[1].mul(1 ether).div(a[0]);
            }
        }
    }

    /**
     * @dev Buys collateral from a vault (AKA redemption/liquidation).
     * @param amount The amount of fxTokens to use for the collateral purchase.
     * @param token The fxToken to purchase with.
     * @param from The vault account to purchase from.
     */
    function _buyCollateral(
        uint256 amount,
        address token,
        address from
    )
        private
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes,
            uint256 etherAmount
        )
    {
        bool isLiquidation;
        {
            // Sender must have enough balance.
            require(IfxToken(token).balanceOf(msg.sender) >= amount, "IA");
            uint256 allowedAmount;
            (
                allowedAmount,
                isLiquidation
            ) = getAllowedBuyCollateralFromTokenAmount(token, from);
            require(allowedAmount > 0, "IA");
            if (amount > allowedAmount) amount = allowedAmount;
            // Vault must have a debt >= amount.
            require(handle.getDebt(from, token) >= amount, "IA");
        }
        // Calculate the amount in ETH excluding fees.
        etherAmount = handle.getTokenPrice(token).mul(amount).div(1 ether);
        if (!isLiquidation) {
            // Calculate and send protocol fees.
            // Ether amount of redemption fees for both user and protocol.
            uint256 redemptionFee =
                etherAmount
                    .mul(vaultLibrary.getLiquidationFee(from, token))
                    .mul(redemptionFeeRatio)
                    .div(1e36); // (1 ether)^2
            // The fee cannot be over 100%.
            require(redemptionFee <= etherAmount, "0<R<=1");
            if (redemptionFee > 0 && protocolRedemptionFeeRatio > 0) {
                // Withdraw protocol fees.
                treasury.forceWithdrawAnyCollateral(
                    from,
                    handle.FeeRecipient(),
                    redemptionFee.mul(protocolRedemptionFeeRatio).div(1 ether),
                    token,
                    true
                );
            }
            // Update ether amount with user's cut of redemption fees.
            etherAmount = etherAmount.add(
                redemptionFee
                    .mul(uint256(1 ether).sub(protocolRedemptionFeeRatio))
                    .div(1 ether)
            );
        }
        {
            // Vault must have enough collateral accounting for redemption fee.
            bool metAmount = false;
            (collateralTypes, collateralAmounts, metAmount) = vaultLibrary
                .getCollateralForAmount(from, token, etherAmount);
            require(metAmount, "CA");
            // Burn token.
            IfxToken(token).burn(msg.sender, amount);
            // Reduce vault debt and withdraw collateral to user.
            handle.updateDebtPosition(from, amount, token, false);
        }
        // Withdraw collateral for redemption.
        uint256 j = collateralTypes.length;
        for (uint256 i = 0; i < j; i++) {
            if (collateralAmounts[i] == 0) continue;
            treasury.forceWithdrawCollateral(
                from,
                collateralTypes[i],
                msg.sender,
                collateralAmounts[i],
                token
            );
        }
        if (isLiquidation) {
            emit Liquidate(
                from,
                token,
                amount,
                collateralAmounts,
                collateralTypes
            );
        } else {
            emit Redeem(
                from,
                token,
                amount,
                collateralAmounts,
                collateralTypes
            );
        }
    }

    /**
     * @dev Calculates the liquidation trigger collateral ratio.
            Ratio with 18 decimals.
     * @param account The vault account.
     * @param fxToken The vault fxToken.
     * @return ratio The trigger CR for liquidation.
     */
    function getLiquidationRatio(address account, address fxToken)
        public
        view
        override
        returns (uint256 ratio)
    {
        ratio = vaultLibrary.getMinimumRatio(account, fxToken).mul(80).div(100);
        uint256 min = uint256(1 ether).mul(110).div(100);
        if (ratio < min) ratio = min;
    }

    /**
     * @dev Attempts to liquidate the target vault.
     * @param account The vault account.
     * @param fxToken The vault fxToken.
     */
    function liquidate(address account, address fxToken)
        external
        override
        validFxToken(fxToken)
        nonReentrant
        returns (
            uint256 fxAmount,
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        )
    {
        uint256 tokenPrice = handle.getTokenPrice(fxToken);
        ensurePoolThreshold(fxToken, tokenPrice);
        uint256 debt = vaultLibrary.getDebtAsEth(account, fxToken);
        uint256 collateral =
            vaultLibrary.getTotalCollateralBalanceAsEth(account, fxToken);
        // Require that the vault CR is under or at the liquidation trigger.
        validateLiquidation(account, fxToken, debt, collateral);
        uint256 feeRatio = vaultLibrary.getLiquidationFee(account, fxToken);
        // Ensure threshold and msg.sender are valid.
        fxAmount = getLiquidationFxAmount(
            account,
            fxToken,
            debt,
            collateral,
            feeRatio,
            tokenPrice
        );
        // Liquidate vault.
        (collateralTypes, collateralAmounts) = executeLiquidation(
            account,
            fxToken,
            fxAmount,
            tokenPrice
        );
        // Withdraw fees.
        collateralAmounts = withdrawFees(
            account,
            fxToken,
            feeRatio,
            tokenPrice,
            fxAmount,
            collateralTypes
        );
    }

    /**
     * @dev Reverts the transaction if the target vault cannot be liquidated.
     * @param account The vault account.
     * @param fxToken The vault fxToken.
     * @param debt The vault debt.
     * @param collateral The vault collateral in the same currency as the debt.
     */
    function validateLiquidation(
        address account,
        address fxToken,
        uint256 debt,
        uint256 collateral
    ) private view {
        uint256 cr = collateral.mul(1 ether).div(debt);
        require(
            cr <= getLiquidationRatio(account, fxToken) && cr >= 1 ether,
            "CR"
        );
    }

    /**
     * @dev Calculates the required amount of fxTokens to successfully
            liquidate a vault to an acceptable CR. 
     * @param account The vault account.
     * @param fxToken The vault fxToken.
     * @param debt The vault debt.
     * @param collateral The vault collateral in the same currency as the debt.
     * @param feeRatio The ratio of purchased asset value to purchasing value.
     * @param tokenPrice The fxToken unit price in ETH. 
     */
    function getLiquidationFxAmount(
        address account,
        address fxToken,
        uint256 debt,
        uint256 collateral,
        uint256 feeRatio,
        uint256 tokenPrice
    ) private view returns (uint256 fxAmount) {
        // Scale the minimum CR by the crScalar value.
        uint256 finalCr =
            vaultLibrary
                .getMinimumRatio(account, fxToken)
                .mul(crScalar.add(100))
                .div(100);
        // The max fee is the overcollateralisation % of the vault.
        uint256 maxFee = (collateral.mul(1 ether).div(debt)).sub(1 ether);
        if (feeRatio > maxFee) feeRatio = maxFee;
        // Get fxAmount to be used in liquidation.
        // Inputs are in Ether, therefore result is converted
        // back to the fxToken currency.
        fxAmount = tokensRequiredForCrIncrease(
            finalCr,
            debt,
            collateral,
            uint256(1 ether).add(feeRatio)
        )
            .mul(1 ether)
            .div(tokenPrice);
        require(
            IERC20(fxToken).balanceOf(msg.sender) >= fxAmount,
            "Liquidator: insufficient balance"
        );
    }

    /**
     * @dev Executes a liquidation and asserts that the value purchased
            is correct.
     * @param account The vault account.
     * @param fxToken The vault fxToken.
     * @param fxAmount The amount of fxTokens to liquidate with.
     * @param tokenPrice The fxToken unit price in ETH.
     */
    function executeLiquidation(
        address account,
        address fxToken,
        uint256 fxAmount,
        uint256 tokenPrice
    )
        private
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        )
    {
        uint256 etherAmountPurchased;
        (
            collateralAmounts,
            collateralTypes,
            etherAmountPurchased
        ) = _buyCollateral(fxAmount, fxToken, account);
        // Assert that the amount purchased is correct.
        // i.e. allowed fxAmount must match with the input fxAmount.
        assert(etherAmountPurchased == fxAmount.mul(tokenPrice).div(1 ether));
    }

    /**
     * @dev Withdraws liquidation fees to the sender.
     * @param fxToken The vault fxToken.
     * @param feeRatio The ratio of the purchased asset value to the
                        purchasing asset value.
     * @param tokenPrice The unit price of the fxToken in ETH.
     * @param fxAmount The amount of fxTokens to withdraw as ETH for the fees.
     * @param collateralTypes The array of supported protocol collateral.
     */
    function withdrawFees(
        address account,
        address fxToken,
        uint256 feeRatio,
        uint256 tokenPrice,
        uint256 fxAmount,
        address[] memory collateralTypes
    ) private returns (uint256[] memory collateralAmounts) {
        address[] memory withdrawnCollateralTypes;
        // Convert fxAmount to the ETH profit.
        fxAmount = fxAmount.mul(feeRatio).div(1 ether).mul(tokenPrice).div(
            1 ether
        );
        // Both _buyCollateral and Treasury.forceWithdrawAnyCollateral
        // use the full list of ordered collateral types,
        // therefore the result from the function below can simply be
        // assigned to the return collateralAmounts
        // instead of looping collateralTypes and withdrawnCollateralTypes
        // to ensure the types match for the collateralAmounts array.
        (withdrawnCollateralTypes, collateralAmounts) = treasury
            .forceWithdrawAnyCollateral(
            account,
            msg.sender,
            fxAmount,
            fxToken,
            false
        );
    }

    /**
     * @dev returns the allowed amount of tokens that can be used to buy collateral from a vault
     * @param token The vault fxToken
     * @param from The vault account
     */
    function getAllowedBuyCollateralFromTokenAmount(address token, address from)
        public
        view
        override
        returns (uint256 allowedAmount, bool isLiquidation)
    {
        uint256 minimumCr = vaultLibrary.getMinimumRatio(from, token);
        uint256 debt = vaultLibrary.getDebtAsEth(from, token);
        uint256 collateral =
            vaultLibrary.getTotalCollateralBalanceAsEth(from, token);
        // Vault CR must be below the max. for buying collateral.
        uint256 cr = collateral.mul(1 ether).div(debt);
        require(cr < minimumCr, "CR");
        // Liquidation ROI ratio (from fxToken value to purchased collateral value)
        uint256 returnRatio = 1 ether;
        isLiquidation = cr <= getLiquidationRatio(from, token);
        // Apply liquidation modifiers to allowable amount if liquidating.
        if (isLiquidation) {
            // Turn minimum CR into target CR for liquidations
            // by accounting for safety CR scalar.
            minimumCr = minimumCr.mul(crScalar.add(100)).div(100);
            // Add vault liquidation fee to ROI ratio.
            // The max fee allowed is the overcollateralisation % of the vault.
            uint256 fee = vaultLibrary.getLiquidationFee(from, token);
            returnRatio = fee <= cr.sub(1 ether)
                ? returnRatio.add(fee) // Charge fee under the max.
                : cr; // Charge max. fee (equal to CR).
        }
        allowedAmount = tokensRequiredForCrIncrease(
            minimumCr,
            debt,
            collateral,
            returnRatio
        );
        // Allowed amount calculated in Ether, convert to forex value.
        uint256 tokenPrice = handle.getTokenPrice(token);
        allowedAmount = allowedAmount.mul(1 ether).div(tokenPrice);
    }

    /**
     * @dev Returns the amount of tokens required to use towards CR increase.
            Formula: [tokens] = ([debt]*[ratio]-[collateral])/([ratio]-1)
     * @param crTarget The per-thousand ratio for vault CR after purchase.
     * @param debt The vault debt in ETH
     * @param collateral The vault collateral in ETH
     */
    function tokensRequiredForCrIncrease(
        uint256 crTarget,
        uint256 debt,
        uint256 collateral,
        uint256 returnRatio
    ) public pure override returns (uint256 amount) {
        require(crTarget > 1 ether, "Invalid target CR");
        require(debt < collateral, "Invalid vault CR");
        require(returnRatio < crTarget, "RR >= CR");
        uint256 nominator = debt.mul(crTarget).sub(collateral.mul(1 ether));
        uint256 denominator = crTarget.sub(returnRatio);
        return nominator.div(denominator);
    }

    /**
     * @dev Ensures that the staked amount in the target fxKeeperPool is
               greater than the threshold if the sender is not the keeper pool.
     * @param fxToken The pool fxToken
     * @param tokenPrice The fxToken unit price in ETH.
     */
    function ensurePoolThreshold(address fxToken, uint256 tokenPrice) private {
        address keeperPool = handle.fxKeeperPool();
        if (msg.sender == keeperPool) return;
        // Staked value in ETH.
        uint256 staked =
            IfxKeeperPool(keeperPool)
                .getPoolTotalDeposit(fxToken)
                .mul(tokenPrice)
                .div(1 ether);
        require(staked <= keeperPoolThreshold, "NW");
    }

    /** @dev Protected UUPS upgrade authorization function */
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

    function setCrScalar(uint256 value) external;

    function setKeeperPoolThreshold(uint256 amount) external;

    function setRedemptionFeeRatio(uint256 ratio) external;

    function setProtocolRedemptionFeeRatio(uint256 ratio) external;

    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline,
        address referral
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
        uint256 deadline,
        address referral
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

    function getAllowedBuyCollateralFromTokenAmount(address token, address from)
        external
        view
        returns (uint256 allowedAmount, bool isLiquidation);

    function crScalar() external view returns (uint256);

    function keeperPoolThreshold() external view returns (uint256);

    function redemptionFeeRatio() external view returns (uint256);

    function protocolRedemptionFeeRatio() external view returns (uint256);
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

    function getDecimalsAmount(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) external pure returns (uint256);

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

interface ITreasury {
    function depositCollateral(
        address account,
        uint256 depositAmount,
        address collateralType,
        address fxToken,
        address referral
    ) external;

    function depositCollateralETH(
        address account,
        address fxToken,
        address referral
    ) external payable;

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
        address fxToken,
        bool requireFullAmount
    )
        external
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        );

    function requestFundsPCT(address token, uint256 amount) external;

    function setMaximumTotalDepositAllowed(uint256 value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IfxToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
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

interface IHandle {
    struct Vault {
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 debt;
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

    function setPaused(bool value) external;

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

    function referral() external view returns (address);

    function pctCollateralUpperBound() external view returns (uint256);

    function isFxTokenValid(address fxToken) external view returns (bool);

    function isCollateralValid(address collateral) external view returns (bool);

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

    function isPaused() external view returns (bool);
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
pragma abicoder v2;

interface IInterest {
    struct ExternalAssetData {
        bytes32 makerDaoCollateralIlk;
    }

    function setCollateralExternalAssetData(
        address collateral,
        bytes32 makerDaoCollateralIlk
    ) external;

    function unsetCollateralExternalAssetData(address collateral) external;

    function setMaxExternalSourceInterest(uint256 interestPerMille) external;

    function charge() external;

    function getCurrentR()
        external
        view
        returns (uint256[] memory R, address[] memory collateralTokens);

    function setDataSource(address source) external;

    function tryUpdateRates() external;

    function updateRates() external;

    function fetchRate(address token) external view returns (uint256);
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
        uint256 P;
        uint256 scale;
        uint256 epoch;
    }

    struct Deposit {
        uint256 amount;
        Snapshot snapshot;
        mapping(address => uint256) collateralToSum;
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

    function stake(
        uint256 amount,
        address fxToken,
        address referral
    ) external;

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

    function setProtocolFee(uint256 ratio) external;

    function protocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IReferral {
    function setReferral(address userAccount, address referralAccount) external;

    function getReferral(address userAccount) external view returns (address);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

