// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/IValidator.sol";

// Comment this out for production, it's a debug tool
// import "hardhat/console.sol";

contract VaultLibrary is IVaultLibrary, IValidator, Ownable {
    using SafeMath for uint256;

    address private comptroller;
    address private treasury;

    constructor(address _comptroller, address _treasury) {
        comptroller = _comptroller;
        treasury = _treasury;
    }

    function setContracts(address _comptroller, address _treasury)
        external
        override
        onlyOwner
    {
        comptroller = _comptroller;
        treasury = _treasury;
    }

    function doesMeetRatio(
        address account,
        address fxToken,
        CollateralRatioType crt
    ) external view override returns (bool) {
        uint256 targetRatio = 0;
        if (
            crt == CollateralRatioType.Minting ||
            crt == CollateralRatioType.Redeem
        ) {
            targetRatio = getMinimumRatio(account, fxToken);
        } else if (crt == CollateralRatioType.Liquidation) {
            targetRatio = Comptroller().getTokenDetails(fxToken).liquidateCR;
        }
        uint256 currentRatio = getCurrentRatio(account, fxToken);
        return currentRatio != 0 && currentRatio >= targetRatio;
    }

    function getCollateralRequiredAsEth(
        uint256 assetAmount,
        address fxToken,
        CollateralRatioType crt
    ) external view override returns (uint256 requiredCollateral) {
        requiredCollateral = 0;
    }

    /**
     * Calculates the minimum collateral required for a given amount and ratio
     * @param tokenAmount the amount of the token desired
     * @param ratio the minting collateral ratio
     * @param unitPrice the price of the token in ETH
     * @return minimum the minimum collateral required for the ratio
     */
    function getMinimumCollateral(
        uint256 tokenAmount,
        uint256 ratio,
        uint256 unitPrice
    ) public pure override returns (uint256 minimum) {
        minimum = unitPrice.mul(tokenAmount).mul(ratio).div(1 ether).div(100);
    }

    /**
     * @notice Calculates the vault's current ratio
     * @param account the user to fetch the ratio for
     * @param fxToken the vault to check
     * @return ratio the current vault ratio percent; zero if no debt
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
        ratio = collateral.mul(100).div(debtAsEth);
    }

    function getDebtAsEth(address account, address fxToken)
        public
        view
        override
        returns (uint256 debt)
    {
        return
            Treasury()
                .getDebt(account, fxToken)
                .mul(Comptroller().getTokenPrice(fxToken))
                .div(1 ether);
    }

    /**
     * @notice returns the total vault amount of collateral converted to ETH
     * @param account the account to check
     * @param fxToken the vault to check
     * @return balance the total vault collateral balance as ETH
     */
    function getTotalCollateralBalanceAsEth(address account, address fxToken)
        public
        view
        override
        returns (uint256 balance)
    {
        ITreasury treasury = Treasury();
        IComptroller comptroller = Comptroller();
        address[] memory collateralTokens = comptroller.getAllCollateralTypes();
        balance = 0;
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 collateralAsEth =
                treasury
                    .getCollateralBalance(account, collateralTokens[i], fxToken)
                    .mul(comptroller.getTokenPrice(collateralTokens[i]))
                    .div(1 ether);
            balance = balance.add(collateralAsEth);
        }
    }

    /**
     * @notice Calculates the amount of free collateral in ETH that a vault has. It will convert collateral other than ETH into ETH first.
     * @param account the user to fetch the free collateral balance for
     * @param fxToken the vault to check
     * @return free the amount of free collateral
     */
    function getFreeCollateralAsEth(address account, address fxToken)
        public
        view
        override
        returns (uint256)
    {
        uint256 currentCollateral =
            getTotalCollateralBalanceAsEth(account, fxToken);
        if (currentCollateral == 0) return 0;
        uint256 collateralRequired =
            getDebtAsEth(account, fxToken)
                .mul(getMinimumRatio(account, fxToken))
                .div(100);
        if (currentCollateral <= collateralRequired) return 0;
        return currentCollateral.sub(collateralRequired);
    }

    /**
     * @notice Returns an array of collateral tokens and amounts that meet the input amount in ETH
     * @param account the owner of the vault
     * @param fxToken the fxToken contained in the vault
     * @return collateralTypes array of collateral addresses
     * @return collateralAmounts array of collateral amounts
     * @return metAmount whether the requested amount exists in the vault
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
        IComptroller comptroller = Comptroller();
        collateralTypes = getCollateralTypesSortedByLiquidationRank();
        collateralAmounts = new uint256[](collateralTypes.length);
        uint256 currentEthAmount = 0;
        // Loop through all sorted vault collateral types,
        // convert to ETH until it matches amount value.
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            uint256 collateral =
                Treasury().getCollateralBalance(
                    account,
                    collateralTypes[i],
                    fxToken
                );
            uint256 collateralUnitPrice =
                comptroller.getTokenPrice(collateralTypes[i]);
            uint256 collateralAsEth =
                collateralUnitPrice.mul(collateral).div(1 ether);
            if (currentEthAmount.add(collateralAsEth) < amountEth) {
                // Add entire collateral amount.
                collateralAmounts[i] = collateral;
                currentEthAmount = currentEthAmount.add(collateralAsEth);
                continue;
            }
            // Add missing amount to fill amount required.
            uint256 delta = amountEth.sub(currentEthAmount);
            collateralAmounts[i] = delta.mul(1 ether).div(collateralUnitPrice);
            currentEthAmount = currentEthAmount.add(delta);
            break;
        }
        metAmount = currentEthAmount == amountEth;
    }

    /**
     * @notice calculates interest since last interest charge from current debt
     * @param user vault owner
     * @param fxToken the vault to calculate interest for
     * @return interest the amount of interest outstanding in ETH.
     */
    function calculateInterest(address user, address fxToken)
        public
        view
        override
        returns (uint256 interest)
    {
        uint256 timeElapsed =
            block.timestamp.sub(
                Treasury().getInterestLastUpdateDate(user, fxToken)
            );
        uint256 weightedInterestRate = getInterestRate(user, fxToken);
        interest = Treasury()
            .getDebt(user, fxToken)
            .mul(weightedInterestRate)
            .mul(timeElapsed)
            .div(365 days)
            .div(1000);
        return interest;
    }

    /**
     * @notice calculates vault's weighted interest rate
     * @param user vault owner
     * @param fxToken the vault to calculate interest for
     * @return interest rate perMille
     */
    function getInterestRate(address user, address fxToken)
        public
        view
        override
        returns (uint256)
    {
        address[] memory collateralTokens =
            Comptroller().getAllCollateralTypes();
        uint256 totalCollateralAsEth =
            getTotalCollateralBalanceAsEth(user, fxToken);
        if (totalCollateralAsEth == 0) return 0;
        uint256 weightedInterestRate = 0;
        // Compute weighted interest rate based on collateral tokens.
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 collateralAsEth =
                Treasury()
                    .getCollateralBalance(user, collateralTokens[i], fxToken)
                    .mul(Comptroller().getTokenPrice(collateralTokens[i]))
                    .div(1 ether);
            weightedInterestRate = weightedInterestRate.add(
                Treasury()
                    .interestRate(collateralTokens[i])
                    .mul(collateralAsEth)
                    .div(totalCollateralAsEth)
            );
        }
        return weightedInterestRate;
    }

    /**
     * @notice Calculates the weighted minting vault ratio.
     * @param account the vault owner
     * @param fxToken the vault to check
     * @return ratio the wighted minting ratio; zero if vault has no collateral
     */
    function getMinimumRatio(address account, address fxToken)
        public
        view
        override
        returns (uint256 ratio)
    {
        ratio = 0;
        address[] memory collateralTypes =
            Comptroller().getAllCollateralTypes();
        uint256[] memory shares = getCollateralShares(account, fxToken);
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            ratio = ratio.add(
                Comptroller()
                    .getCollateralDetails(collateralTypes[i])
                    .mintCR
                    .mul(100)
                    .mul(shares[i])
                    .div(1 ether)
            );
        }
        // Return the ratio as a percentage.
        ratio = ratio.div(100);
    }

    /**
     * @notice returns the vault's weighted liquidation fee based on collateral
     * @dev returns an ether-ratio; the liquidation fee ratio is assumed to be per ten-thousand
     * @param account the vault owner
     * @param fxToken the vault to check
     */
    function getLiquidationFee(address account, address fxToken)
        public
        view
        override
        returns (uint256 fee)
    {
        fee = 0;
        address[] memory collateralTypes =
            Comptroller().getAllCollateralTypes();
        uint256[] memory shares = getCollateralShares(account, fxToken);
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            fee = fee.add(
                Comptroller()
                    .getCollateralDetails(collateralTypes[i])
                    .liquidationFee
                    .mul(shares[i])
                    .div(10000)
            );
        }
    }

    /**
     * @notice returns a share value per collateral type (1 ether = 100%)
     * @param account the vault owner
     * @param fxToken the vault to check
     */
    function getCollateralShares(address account, address fxToken)
        public
        view
        override
        returns (uint256[] memory shares)
    {
        address[] memory collateralTypes =
            Comptroller().getAllCollateralTypes();
        shares = new uint256[](collateralTypes.length);
        uint256 totalBalanceEth =
            getTotalCollateralBalanceAsEth(account, fxToken);
        if (totalBalanceEth == 0) return shares;
        uint256 balance = 0;
        uint256 balanceEth = 0;
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            balance = Treasury().getCollateralBalance(
                account,
                collateralTypes[i],
                fxToken
            );
            balanceEth = Comptroller()
                .getTokenPrice(collateralTypes[i])
                .mul(balance)
                .div(1 ether);
            shares[i] = balanceEth.mul(1 ether).div(totalBalanceEth);
        }
    }

    /**
     * @notice returns the amount of tokens required to use towards CR increase
     * @dev formula: [tokens] = ([debt]*[ratio]-[collateral])/([ratio]-1)
     * @param crTarget per-thousand ratio for vault CR after purchase
     * @param debt the vault debt in Ether
     * @param collateral the vault collateral in ether
     */
    function tokensRequiredForCrIncrease(
        uint256 crTarget,
        uint256 debt,
        uint256 collateral
    ) public pure override returns (uint256 amount) {
        uint256 nominator = debt.mul(crTarget).sub(collateral.mul(1000));
        uint256 denominator = crTarget.sub(1000);
        return nominator.div(denominator);
    }

    /**
     * @notice Returns a sorted array of Comptroller collateral type addresses by their liquidation rank.
     */
    function getCollateralTypesSortedByLiquidationRank()
        public
        view
        override
        returns (address[] memory sortedCollateralTypes)
    {
        IComptroller comptroller = Comptroller();
        address[] memory unsortedCollateralTypes =
            comptroller.getAllCollateralTypes();
        // Get collateral liquidation ranks.
        uint256[] memory unsortedRanks =
            new uint256[](unsortedCollateralTypes.length);
        for (uint256 i = 0; i < unsortedRanks.length; i++) {
            unsortedRanks[i] = comptroller
                .getCollateralDetails(unsortedCollateralTypes[i])
                .liquidationRank;
        }
        // Sort ranks -- copy array.
        uint256[] memory sortedRanks = new uint256[](unsortedRanks.length);
        for (uint256 i = 0; i < sortedRanks.length; i++) {
            sortedRanks[i] = unsortedRanks[i];
        }
        quickSort(sortedRanks, 0, int256(sortedRanks.length - 1));
        // Map unsorted index to sorted index.
        uint256[] memory toUnsortedIndex =
            new uint256[](unsortedCollateralTypes.length);
        for (uint256 i = 0; i < sortedRanks.length; i++) {
            for (uint256 j = 0; j < unsortedRanks.length; j++) {
                if (unsortedRanks[j] != sortedRanks[i]) continue;
                toUnsortedIndex[i] = j;
                break;
            }
        }
        sortedCollateralTypes = new address[](unsortedCollateralTypes.length);
        for (uint256 i = 0; i < unsortedCollateralTypes.length; i++) {
            // i is sorted, j is unsorted.
            uint256 j = toUnsortedIndex[i];
            sortedCollateralTypes[i] = unsortedCollateralTypes[j];
        }
    }

    /**
     * @notice returns the allowed amount of tokens that can be used to buy collateral from a vault
     * @param token the vault's fxToken
     * @param from user address to buy collateral from
     */
    function getAllowedBuyCollateralFromTokenAmount(
        uint256 amount,
        address token,
        address from
    ) external view override returns (uint256 allowedAmount) {
        uint256 minimumCr = getMinimumRatio(from, token);
        uint256 debt = getDebtAsEth(from, token);
        uint256 collateral = getTotalCollateralBalanceAsEth(from, token);
        // Vault CR must be below the max. for buying collateral.
        require(collateral.mul(100).div(debt) < minimumCr, "CR");
        uint256 liquidationFee = getLiquidationFee(from, token);
        uint256 liquidationFeeEther =
            liquidationFee.mul(collateral).div(1 ether);
        uint256 theoreticalCollateralAmount =
            debt
                .add(liquidationFeeEther)
                .mul(minimumCr.mul(1 ether).div(100).add(liquidationFee))
                .div(1 ether);
        uint256 maxCr = theoreticalCollateralAmount.mul(1000).div(debt);
        allowedAmount = tokensRequiredForCrIncrease(maxCr, debt, collateral);
        // Allowed amount calculated in Ether, convert to forex value.
        uint256 tokenPrice = Comptroller().getTokenPrice(token);
        allowedAmount = allowedAmount.mul(1 ether).div(tokenPrice);
    }

    /**
     * @notice Quick sort algorithm implementation (ascending order).
     * @param array the array to sort
     * @param left leftmost index of the array to sort from
     * @param right rightmost index of the array to sort to
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

    function Comptroller() private view returns (IComptroller) {
        return IComptroller(comptroller);
    }

    function Treasury() private view returns (ITreasury) {
        return ITreasury(treasury);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IVaultLibrary {
    enum CollateralRatioType {Minting, Redeem, Liquidation}

    function setContracts(address comptroller, address treasury) external;

    function doesMeetRatio(
        address account,
        address fxToken,
        CollateralRatioType crt
    ) external view returns (bool);

    function getCollateralRequiredAsEth(
        uint256 assetAmount,
        address fxToken,
        CollateralRatioType crt
    ) external view returns (uint256);

    function getFreeCollateralAsEth(address account, address fxToken)
        external
        view
        returns (uint256);

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

    function calculateInterest(address user, address fxToken)
        external
        view
        returns (uint256 interest);

    function getInterestRate(address user, address fxToken)
        external
        view
        returns (uint256);

    function getLiquidationFee(address account, address fxToken)
        external
        view
        returns (uint256 fee);

    function getCollateralShares(address account, address fxToken)
        external
        view
        returns (uint256[] memory shares);

    function tokensRequiredForCrIncrease(
        uint256 crTarget,
        uint256 debt,
        uint256 collateral
    ) external pure returns (uint256 amount);

    function getCollateralTypesSortedByLiquidationRank()
        external
        view
        returns (address[] memory sortedCollateralTypes);

    function getAllowedBuyCollateralFromTokenAmount(
        uint256 amount,
        address token,
        address from
    ) external view returns (uint256 allowedAmount);

    function quickSort(
        uint256[] memory array,
        int256 left,
        int256 right
    ) external pure;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IComptroller {
    // Structs
    struct TokenData {
        uint256 liquidateCR;
        uint256 rewardRatio;
    }
    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationRank;
        uint256 stabilityFee;
        uint256 liquidationFee;
    }
    // Events
    event MintToken(
        uint256 tokenRate,
        uint256 amountMinted,
        address indexed token
    );
    event BurnToken(uint256 amountBurned, address indexed token);
    event Redeem(
        address from,
        address token,
        uint256 tokenAmount,
        uint256[] collateralAmounts,
        address[] collateralTypes
    );

    // Mint with ETH as collateral
    function mintWithEth(
        uint256 tokenAmountDesired,
        address fxToken,
        uint256 deadline
    ) external payable;

    // Mint with ERC20 as collateral
    function mint(
        uint256 amountDesired,
        address fxToken,
        address collateralToken,
        address to,
        uint256 deadline
    ) external;

    function mintWithoutCollateral(
        uint256 tokenAmountDesired,
        address token,
        uint256 deadline
    ) external;

    // Burn to withdraw collateral
    function burn(
        uint256 amount,
        address token,
        uint256 deadline
    ) external;

    // Buy collateral with fxTokens
    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline
    )
        external
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes
        );

    // Add/Update/Remove a token
    function setFxToken(
        address token,
        uint256 _liquidateCR,
        uint256 rewardRatio
    ) external;

    // Update tokens
    function removeFxToken(address token) external;

    function setCollateralToken(
        address _token,
        uint256 _mintCR,
        uint256 _liquidationRank,
        uint256 _stabilityFee,
        uint256 _liquidationFee
    ) external;

    function removeCollateralToken(address token) external;

    // Getters
    function getTokenPrice(address token) external view returns (uint256 quote);

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getAllFxTokens() external view returns (address[] memory tokens);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function getTokenDetails(address token)
        external
        view
        returns (TokenData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function vaultLibrary() external view returns (address);

    function setOracle(address fxToken, address oracle) external;

    function isFxTokenValid(address fxToken) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITreasury {
    // Structs
    struct Vault {
        uint256 debt;
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 issuanceDelta; // Used for charging interest
    }
    // Events
    event UpdateDebt(address indexed account, address indexed fxToken);
    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    // State changing functions
    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

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

    function withdrawAnyCollateral(
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

    function updateVaultInterest(address user, address fxToken) external;

    // Variable setters
    function setContracts(address comptroller, address vaultLibrary) external;

    function setRewardToken(address token, bytes32 which) external;

    function setCollateralInterestRate(address collateral, uint256 ratePerMille)
        external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    // Getters
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

    function interestRate(address collateral)
        external
        view
        returns (uint256 rate);

    function getInterestLastUpdateDate(address account, address fxToken)
        external
        view
        returns (uint256 date);

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

