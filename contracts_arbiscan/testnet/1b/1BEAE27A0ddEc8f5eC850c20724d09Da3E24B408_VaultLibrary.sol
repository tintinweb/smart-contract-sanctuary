// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/Bank/IHandle.sol";
import "../interfaces/Bank/IHandleComponent.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/Bank/IInterest.sol";

/**
 * @dev Provides read-only functions to calculate vault data such as the
        collateral ratio, the equivalent ETH value of collateral/debt at
        the current exchange rates, weighted fees, etc.
 */
contract VaultLibrary is
    IVaultLibrary,
    IValidator,
    Initializable,
    IHandleComponent,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    /** @dev The Handle contract interface */
    IHandle private handle;
    /** @dev The Treasury contract interface */
    ITreasury private treasury;
    /** @dev The Comptroller contract interface */
    IComptroller private comptroller;
    /** @dev The Interest contract interface */
    IInterest private interest;

    /** @dev Proxy initialisation function */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev Setter for Handle contract reference
     * @param _handle The Handle contract address
     */
    function setHandleContract(address _handle) public override onlyOwner {
        handle = IHandle(_handle);
        comptroller = IComptroller(handle.comptroller());
        treasury = ITreasury(handle.treasury());
        interest = IInterest(handle.interest());
    }

    /** @dev Getter for Handle contract address */
    function handleAddress() public view override returns (address) {
        return address(handle);
    }

    /**
     * @dev Returns whether the vault's current CR meets the minimum ratio.
     * @param account The vault account
     * @param fxToken The vault fxToken
     */
    function doesMeetRatio(address account, address fxToken)
        external
        view
        override
        returns (bool)
    {
        uint256 targetRatio = getMinimumRatio(account, fxToken);
        uint256 currentRatio = getCurrentRatio(account, fxToken);
        return currentRatio != 0 && currentRatio >= targetRatio;
    }

    /**
     * @dev Calculates the minimum collateral required for a given
            amount and ratio.
     * @param tokenAmount The amount of the token desired
     * @param ratio The minting collateral ratio with 18 decimals of precision
     * @param unitPrice The price of the token in ETH
     * @return minimum The minimum collateral required for the ratio
     */
    function getMinimumCollateral(
        uint256 tokenAmount,
        uint256 ratio,
        uint256 unitPrice
    ) public pure override returns (uint256 minimum) {
        require(ratio >= 1 ether, "CR");
        minimum = unitPrice.mul(tokenAmount).mul(ratio).div(1 ether).div(
            1 ether
        );
    }

    /**
     * @dev Calculates the vault's current ratio
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return ratio The current vault ratio percent; zero if no debt
     */
    function getCurrentRatio(address account, address fxToken)
        public
        view
        override
        returns (uint256 ratio)
    {
        uint256 debtAsEth = getDebtAsEth(account, fxToken);
        if (debtAsEth == 0) return 0;
        uint256 collateral = getTotalCollateralBalanceAsEth(account, fxToken);
        ratio = collateral.mul(1 ether).div(debtAsEth);
    }

    /**
     * @dev Returns the vault debt as ETH using the current exchange rate.
     * @param account The vault account
     * @param fxToken The vault fxToken
     */
    function getDebtAsEth(address account, address fxToken)
        public
        view
        override
        returns (uint256 debt)
    {
        return
            handle
                .getDebt(account, fxToken)
                .mul(handle.getTokenPrice(fxToken))
                .div(1 ether);
    }

    /**
     * @dev Returns the total vault amount of collateral converted to ETH
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return balance The total vault collateral balance as ETH
     */
    function getTotalCollateralBalanceAsEth(address account, address fxToken)
        public
        view
        override
        returns (uint256 balance)
    {
        address[] memory collateralTokens = handle.getAllCollateralTypes();
        balance = 0;
        uint256 j = collateralTokens.length;
        for (uint256 i = 0; i < j; i++) {
            uint256 collateralAsEth =
                handle
                    .getCollateralBalance(account, collateralTokens[i], fxToken)
                    .mul(handle.getTokenPrice(collateralTokens[i]))
                    .div(getTokenUnit(collateralTokens[i]));
            balance = balance.add(collateralAsEth);
        }
    }

    /**
     * @dev Calculates the amount of free collateral in ETH that a vault has.
            It will convert collateral other than ETH into ETH first.
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return free The amount of free collateral
     */
    function getFreeCollateralAsEth(address account, address fxToken)
        public
        view
        override
        returns (uint256)
    {
        return
            getFreeCollateralAsEthFromMinimumRatio(
                account,
                fxToken,
                getMinimumRatio(account, fxToken)
            );
    }

    /**
     * @dev Same as getFreeCollateralAsEth, but accepts any minimum ratio.
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return free The amount of free collateral
     */
    function getFreeCollateralAsEthFromMinimumRatio(
        address account,
        address fxToken,
        uint256 minimumRatio
    ) public view override returns (uint256) {
        uint256 currentCollateral =
            getTotalCollateralBalanceAsEth(account, fxToken);
        if (currentCollateral == 0) return 0;
        uint256 collateralRequired =
            getDebtAsEth(account, fxToken).mul(minimumRatio).div(1 ether);
        if (currentCollateral <= collateralRequired) return 0;
        return currentCollateral.sub(collateralRequired);
    }

    /**
     * @dev Returns an array of collateral tokens and amounts that meet the input amount in ETH
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return collateralTypes An array of collateral addresses
     * @return collateralAmounts An array of collateral amounts
     * @return metAmount Whether the requested amount exists in the vault
     */
    function getCollateralForAmount(
        address account,
        address fxToken,
        uint256 amountEth
    )
        external
        view
        override
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts,
            bool metAmount
        )
    {
        collateralTypes = getCollateralTypesSortedByLiquidationRank();
        uint256 j = collateralTypes.length;
        collateralAmounts = new uint256[](j);
        uint256 currentEthAmount = 0;
        // Loop through all sorted vault collateral types,
        // convert to ETH until it matches amount value.
        for (uint256 i = 0; i < j; i++) {
            uint256 collateral =
                handle.getCollateralBalance(
                    account,
                    collateralTypes[i],
                    fxToken
                );
            if (collateral == 0) continue;
            uint256 collateralUnitPrice =
                handle.getTokenPrice(collateralTypes[i]);
            uint256 collateralAsEth =
                collateralUnitPrice.mul(collateral).div(
                    getTokenUnit(collateralTypes[i])
                );
            if (currentEthAmount.add(collateralAsEth) < amountEth) {
                // Add entire collateral amount.
                collateralAmounts[i] = collateral;
                currentEthAmount = currentEthAmount.add(collateralAsEth);
                continue;
            }
            // Add missing amount to fill amount required.
            uint256 delta = amountEth.sub(currentEthAmount);
            // Convert the amount from 18 decimals to the collateral's decimals.
            collateralAmounts[i] = getDecimalsAmount(
                delta.mul(1 ether).div(collateralUnitPrice),
                18,
                IERC20(collateralTypes[i]).decimals()
            );
            currentEthAmount = currentEthAmount.add(delta);
            break;
        }
        metAmount = currentEthAmount == amountEth;
    }

    /**
     * @dev Converts a value from one decimal count to another. Note that if
            reducing the amount of decimals some data and precision may be lost.
     * @param amount The current value to be transformed
     * @param fromDecimals The current amount of decimals in the value
     * @param toDecimals The final desired amount of decimals for the value 
     */
    function getDecimalsAmount(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) public pure override returns (uint256) {
        if (fromDecimals == toDecimals) return amount;
        int256 delta = int256(int8(fromDecimals) - int8(toDecimals));
        uint256 udelta;
        if (delta > 0) {
            // fromDecimals > toDecimals. Scale amount down.
            udelta = uint256(delta);
            amount = amount.div(10**udelta);
        } else {
            // fromDecimals < toDecimals. Scale amount up.
            udelta = uint256(-delta);
            amount = amount.mul(10**udelta);
        }
        return amount;
    }

    /**
     * @dev Calculates the vault interest using the R value for the current block
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return The amount of interest outstanding in ETH.
     */
    function calculateInterest(address account, address fxToken)
        public
        view
        override
        returns (uint256)
    {
        uint256 dR = getInterestDeltaR(account, fxToken);
        return handle.getPrincipalDebt(account, fxToken).mul(dR).div(1 ether);
    }

    /**
     * @dev Calculates vault's weighted interest rate
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return rate The interest rate with 1 decimal (perMille)
     */
    function getInterestRate(address account, address fxToken)
        public
        view
        override
        returns (uint256 rate)
    {
        rate = 0;
        address[] memory collateralTokens = handle.getAllCollateralTypes();
        uint256 j = collateralTokens.length;
        uint256[] memory shares = getCollateralShares(account, fxToken);
        for (uint256 i = 0; i < j; i++) {
            rate = rate.add(
                handle
                    .getCollateralDetails(collateralTokens[i])
                    .interestRate
                    .mul(shares[i])
                    .div(1 ether)
            );
        }
    }

    /**
     * @dev Calculates vault's weighted delta cumulative interest rate
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return dR The delta cumulative interest rate with 18 decimals
     */
    function getInterestDeltaR(address account, address fxToken)
        public
        view
        override
        returns (uint256 dR)
    {
        (uint256[] memory R, address[] memory collateralTokens) =
            interest.getCurrentR();
        dR = 0;
        // Compute weighted interest rate based on collateral tokens.
        uint256 j = collateralTokens.length;
        uint256 R0;
        uint256[] memory shares = getCollateralShares(account, fxToken);
        for (uint256 i = 0; i < j; i++) {
            R0 = handle.getCollateralR0(account, fxToken, collateralTokens[i]);
            dR = dR.add(R[i].sub(R0).mul(shares[i]).div(1 ether));
        }
    }

    /**
     * @dev Calculates the weighted minting vault ratio. Ratio with 18 decimals.
     * @param account The vault account
     * @param fxToken The vault fxToken
     * @return ratio The wighted minting ratio; zero if vault has no collateral
     */
    function getMinimumRatio(address account, address fxToken)
        public
        view
        override
        returns (uint256 ratio)
    {
        address[] memory collateralTypes = handle.getAllCollateralTypes();
        uint256[] memory shares = getCollateralShares(account, fxToken);
        uint256 j = collateralTypes.length;
        for (uint256 i = 0; i < j; i++) {
            ratio = ratio.add(
                handle
                    .getCollateralDetails(collateralTypes[i])
                    .mintCR
                    .mul(100)
                    .mul(shares[i])
            );
        }
        // Normalise the value. Return a value with 18 decimals.
        ratio = ratio.div(10_000);
    }

    /**
     * @dev Returns the vault's weighted liquidation fee based on collateral.
            Returns a ratio with 18 decimals.
     * @param account The vault account
     * @param fxToken The vault fxToken
     */
    function getLiquidationFee(address account, address fxToken)
        public
        view
        override
        returns (uint256 fee)
    {
        fee = 0;
        address[] memory collateralTypes = handle.getAllCollateralTypes();
        uint256[] memory shares = getCollateralShares(account, fxToken);
        uint256 j = collateralTypes.length;
        for (uint256 i = 0; i < j; i++) {
            fee = fee.add(
                handle
                    .getCollateralDetails(collateralTypes[i])
                    .liquidationFee
                    .mul(shares[i])
                // Since the liquidation fee has 2 decimals, the value
                // is divided by 10000 here after being multiplied by
                // the collateral share which has 18 decimals.
                    .div(10000)
            );
        }
    }

    /**
     * @dev Returns a share value per collateral type (1 ether = 100%)
     * @param account The vault account
     * @param fxToken The vault fxToken
     */
    function getCollateralShares(address account, address fxToken)
        public
        view
        override
        returns (uint256[] memory shares)
    {
        address[] memory collateralTypes = handle.getAllCollateralTypes();
        uint256 j = collateralTypes.length;
        shares = new uint256[](j);
        uint256 totalBalanceEth =
            getTotalCollateralBalanceAsEth(account, fxToken);
        if (totalBalanceEth == 0) return shares;
        uint256 balance = 0;
        uint256 balanceEth = 0;
        for (uint256 i = 0; i < j; i++) {
            balance = handle.getCollateralBalance(
                account,
                collateralTypes[i],
                fxToken
            );
            balanceEth = handle
                .getTokenPrice(collateralTypes[i])
                .mul(balance)
                .div(getTokenUnit(collateralTypes[i]));
            shares[i] = balanceEth.mul(1 ether).div(totalBalanceEth);
        }
    }

    /**
     * @dev Returns a sorted array of Comptroller collateral type addresses by
            their liquidation rank, which is derived by the collateral's
            minting ratio.
     */
    function getCollateralTypesSortedByLiquidationRank()
        public
        view
        override
        returns (address[] memory sortedCollateralTypes)
    {
        address[] memory unsortedCollateralTypes =
            handle.getAllCollateralTypes();
        // Get collateral liquidation ranks.
        uint256 m = unsortedCollateralTypes.length;
        uint256[] memory unsortedRanks = new uint256[](m);
        for (uint256 i = 0; i < m; i++) {
            // The rank is simply the minting ratio.
            unsortedRanks[i] = handle
                .getCollateralDetails(unsortedCollateralTypes[i])
                .mintCR;
        }
        // Sort ranks; copy array.
        uint256[] memory sortedRanks = new uint256[](m);
        for (uint256 i = 0; i < m; i++) {
            sortedRanks[i] = unsortedRanks[i];
        }
        // Quicksort (ascending order).
        quickSort(sortedRanks, 0, int256(sortedRanks.length - 1));
        // Map unsorted index to sorted index.
        uint256[] memory toUnsortedIndex = new uint256[](m);
        // List of unsorted indices already used, if two or more collaterals
        // have the same mint CR -- if this is not used, an overlap will occur.
        // This stores the index + 1 since the default is zero.
        uint256[] memory jUsed = new uint256[](m);
        // i is the sorted index.
        for (uint256 i = 0; i < m; i++) {
            // j is the unsorted index.
            for (uint256 j = 0; j < m; j++) {
                if (unsortedRanks[j] != sortedRanks[i]) continue;
                bool isDuplicateJ;
                // k is used for finding duplicate indices.
                for (uint256 k = 0; k < m; k++) {
                    if (j + 1 == jUsed[k]) isDuplicateJ = true;
                }
                if (isDuplicateJ) continue;
                toUnsortedIndex[i] = j;
                jUsed[i] = j + 1;
                break;
            }
        }
        sortedCollateralTypes = new address[](m);
        for (uint256 i = 0; i < m; i++) {
            // i is sorted, j is unsorted.
            uint256 n = toUnsortedIndex[i];
            // The ascending order array must be reversed now so that it's descending.
            // Descending order index.
            uint256 iDescending = m - i - 1;
            sortedCollateralTypes[iDescending] = unsortedCollateralTypes[n];
        }
    }

    /**
     * @dev Returns the new minimum vault ratio due to a collateral deposit
            or withdraw. Used for checking the CR is valid before performing
            an operation.
     * @param account The account that owns the vault
     * @param fxToken The vault fxToken
     * @param collateralToken The collateral address
     * @param collateralAmount The collateral amount
     * @param collateralQuote The collateral unit price in ETH
     * @param isDeposit Whether depositing or withdrawing the input collateral
     */
    function getNewMinimumRatio(
        address account,
        address fxToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 collateralQuote,
        bool isDeposit
    )
        public
        view
        override
        returns (uint256 ratio, uint256 newCollateralAsEther)
    {
        uint256 currentMinRatio = getMinimumRatio(account, fxToken);
        uint256 vaultCollateral =
            getTotalCollateralBalanceAsEth(account, fxToken);
        // Calculate new vault collateral from deposit amount.
        newCollateralAsEther = isDeposit
            ? vaultCollateral.add(
                collateralQuote.mul(collateralAmount).div(
                    getTokenUnit(collateralToken)
                )
            )
            : vaultCollateral.sub(
                collateralQuote.mul(collateralAmount).div(
                    getTokenUnit(collateralToken)
                )
            );
        uint256 depositCollateralMintCR =
            handle.getCollateralDetails(collateralToken).mintCR;
        if (currentMinRatio == 0) {
            ratio = depositCollateralMintCR.mul(1 ether).div(100);
            return (ratio, newCollateralAsEther);
        }
        /* Ratio for the current share of minimum collateral ratio due
        to the deposit amount (i.e. if vault holds $50 and the new
        deposit is $50, this value is 50% expressed as 0.5 ether).
           For a withdrawal, the value is going to be >100% since
        collateral is removed. */
        uint256 oldCollateralMintRatio =
            vaultCollateral.mul(1 ether).div(newCollateralAsEther);
        // Start calculating new minimum ratio using the CR ratio above.
        ratio = currentMinRatio.mul(oldCollateralMintRatio).div(1 ether);
        // Finish calculating the ratio depending on whether it's a deposit
        // or withdrawal to prevent an underflow on withdrawal.
        assert(
            (oldCollateralMintRatio <= 1 ether && isDeposit) ||
                (oldCollateralMintRatio >= 1 ether && !isDeposit)
        );
        ratio = isDeposit
            ? ratio.add(
                depositCollateralMintCR
                    .mul(uint256(1 ether).sub(oldCollateralMintRatio))
                    .div(1 ether)
            )
            : ratio.sub(
                depositCollateralMintCR
                    .mul(oldCollateralMintRatio.sub(1 ether))
                    .div(1 ether)
            );
    }

    /**
     * @dev Returns whether the resulting state is valid for a vault about to
            mint fxTokens.
     * @param account The vault account.
     * @param fxToken The vault fxToken.
     * @param collateralToken The collateral token to deposit when minting.
     * @param collateralAmount The amount of collateral to deposit.
     * @param tokenAmount The amount of tokens to mint.
     * @param fxQuote The fxToken unit price in ETH.
     * @param collateralQuote The collateral token unit price in ETH.
     */
    function canMint(
        address account,
        address fxToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 tokenAmount,
        uint256 fxQuote,
        uint256 collateralQuote
    ) external view override returns (bool) {
        (uint256 minimumRatio, uint256 collateral) =
            getNewMinimumRatio(
                account,
                fxToken,
                collateralToken,
                collateralAmount,
                collateralQuote,
                true
            );

        // Check the vault ratio is correct
        return (collateral >=
            // Calculate token value as ETH.
            tokenAmount
                .mul(fxQuote)
                .div(1 ether)
            // Add existing debt as ETH.
                .add(getDebtAsEth(account, fxToken))
            // Multiply by the minimum ratio -- collateral must be greater than
            // or equal to this value so that the collateral ratio is valid.
                .mul(minimumRatio)
                .div(1 ether));
    }

    /**
     * @dev Quick sort algorithm implementation (ascending order).
     * @param array The array to sort
     * @param left The leftmost index of the array to sort from
     * @param right The rightmost index of the array to sort to
     */
    function quickSort(
        uint256[] memory array,
        int256 left,
        int256 right
    ) public pure override {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = array[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (array[uint256(i)] < pivot) i++;
            while (pivot < array[uint256(j)]) j--;
            if (i <= j) {
                (array[uint256(i)], array[uint256(j)]) = (
                    array[uint256(j)],
                    array[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(array, left, j);
        if (i < right) quickSort(array, i, right);
    }

    /**
     * @dev Returns an unit value for any ERC20 that implements decimals.
     * @param token The token address
     */
    function getTokenUnit(address token)
        public
        view
        override
        returns (uint256)
    {
        uint256 decimals = IERC20(token).decimals();
        return 10**decimals;
    }

    /** @dev Protected UUPS upgrade authorization function */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
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
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
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
pragma abicoder v2;

interface IComptroller {
    event MintToken(
        uint256 tokenRate,
        uint256 amountMinted,
        address indexed token
    );

    event BurnToken(uint256 amountBurned, address indexed token);

    function mintWithEth(
        uint256 tokenAmountDesired,
        address fxToken,
        uint256 deadline,
        address referral
    ) external payable;

    function mint(
        uint256 amountDesired,
        address fxToken,
        address collateralToken,
        uint256 collateralAmount,
        uint256 deadline,
        address referral
    ) external;

    function mintWithoutCollateral(
        uint256 tokenAmountDesired,
        address token,
        uint256 deadline,
        address referral
    ) external;

    function burn(
        uint256 amount,
        address token,
        uint256 deadline
    ) external;

    function setMinimumMintingAmount(uint256 amount) external;

    function minimumMintingAmount() external view returns (uint256);
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

    event ConfigureFxToken(address indexed fxToken, bool removed);

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

    function forex() external view returns (address);

    function rewards() external view returns (address);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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