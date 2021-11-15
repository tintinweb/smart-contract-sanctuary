// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/Bank/IfxKeeperPool.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/IERC20.sol";

contract fxKeeperPool is IfxKeeperPool, IValidator, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for int256;

    uint256 public constant SCALE_FACTOR = 1e9;
    uint256 public constant DECIMAL_PRECISION = 1e9;

    address public comptroller;
    mapping(address => Pool) internal pools;

    modifier validFxToken(address token) {
        require(Comptroller().isFxTokenValid(token), "IF");
        _;
    }

    constructor(address _comptroller) {
        comptroller = _comptroller;
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
        _checkInitialisePool(fxToken);
        // Transfer token and add to total stake.
        require(
            IERC20(fxToken).allowance(msg.sender, address(this)) >= amount,
            "fxKeeperPool: fxToken ERC20 allowance not met"
        );
        // Transfer token and increase total deposits.
        IERC20(fxToken).transferFrom(msg.sender, address(this), amount);
        pools[fxToken].totalDeposits = pools[fxToken].totalDeposits.add(amount);
        // Update deposit data.
        Deposit storage deposit = pools[fxToken].deposits[msg.sender];
        uint256 staked = balanceOfStake(msg.sender, fxToken);
        uint256 newDeposit = staked.add(amount);
        _updateDeposit(msg.sender, newDeposit, fxToken);
        // Withdraw existing collateral rewards.
        _withdrawCollateralRewardFrom(msg.sender, fxToken);
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
        if (amount > stakedAmount) amount = stakedAmount;
        // Subtract total staked amount for pool and send tokens to depositor.
        assert(pools[fxToken].totalDeposits >= amount);
        IERC20(fxToken).transfer(msg.sender, amount);
        pools[fxToken].totalDeposits = pools[fxToken].totalDeposits.sub(amount);
        // Update deposit.
        uint256 newDeposit = stakedAmount.sub(amount);
        _updateDeposit(msg.sender, newDeposit, fxToken);
        // Withdraw existing collateral rewards.
        _withdrawCollateralRewardFrom(msg.sender, fxToken);
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
        // Withdraw all coll`ateral rewards.
        (
            address[] memory collateralTokens,
            uint256[] memory collateralAmounts
        ) = balanceOfRewards(account, fxToken);
        assert(collateralTokens.length > 0);
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            if (collateralAmounts[i] == 0) continue;
            IERC20(collateralTokens[i]).transfer(account, collateralAmounts[i]);
        }
        // Update deposit.
        uint256 stake = balanceOfStake(account, fxToken);
        _updateDeposit(account, stake, fxToken);
    }

    /**
     * @notice retrieves account's current staked amount in pool
     * @dev O(N) operation where N is the number of rounds deposited by account
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
        collateralTypes = Comptroller().getAllCollateralTypes();
        collateralAmounts = new uint256[](collateralTypes.length);
        for (uint256 i = 0; i < collateralTypes.length; i++) {
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
        uint256 stake = balanceOfStake(account, fxToken);
        share = stake.mul(1 ether).div(total);
    }

    /**
     * @notice returns the amount of tokens required to use towards CR increase
     * @dev formula: [tokens] = ([debt]*[ratio]-[collateral])/([ratio]-1)
     * @param crTargetPercent resulting percentage for vault CR after purchase
     * @param debt the vault debt in Ether
     * @param collateral the vault collateral in ether
     */
    function tokensRequiredForCrIncrease(
        uint256 crTargetPercent,
        uint256 debt,
        uint256 collateral
    ) public pure override returns (uint256 amount) {
        uint256 nominator = debt.mul(crTargetPercent).sub(collateral.mul(100));
        uint256 denominator = crTargetPercent.sub(100);
        return nominator.div(denominator);
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
        ) = buyCollateral(account, fxToken);
        // Update pool state with new debt and collateral values.
        absorbDebt(fxAmount, collateralTypes, collateralAmounts, fxToken);
    }

    function buyCollateral(address account, address fxToken)
        private
        returns (
            uint256 fxAmount,
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        )
    {
        uint256 debt = VaultLibrary().getDebtAsEth(account, fxToken);
        uint256 collateral =
            VaultLibrary().getTotalCollateralBalanceAsEth(account, fxToken);
        uint256 minimumCr =
            VaultLibrary().getVaultMinimumRatio(account, fxToken);
        // TODO: Increase CR by liquidation fee then withdraw from vault to pool (HP-148)
        fxAmount = tokensRequiredForCrIncrease(minimumCr, debt, collateral);
        // Require enough staked fxTokens.
        require(pools[fxToken].totalDeposits >= fxAmount, "Not enough staked");
        // Liquidate vault.
        IERC20(fxToken).approve(comptroller, fxAmount);
        (collateralAmounts, collateralTypes) = Comptroller().buyCollateral(
            fxAmount,
            fxToken,
            account,
            block.timestamp
        );
        // Update pool collateral balances.
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            if (collateralAmounts[i] == 0) continue;
            pools[fxToken].collateralBalances[collateralTypes[i]] = pools[
                fxToken
            ]
                .collateralBalances[collateralTypes[i]]
                .add(collateralAmounts[i]);
        }
    }

    function absorbDebt(
        uint256 debt,
        address[] memory collateralTypes,
        uint256[] memory collateralAmounts,
        address fxToken
    ) private {
        if (pools[fxToken].totalDeposits == 0 || debt == 0) return;
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
        for (uint256 i = 0; i < collateralTypes.length; i++) {
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
        address[] memory collateralTypes =
            Comptroller().getAllCollateralTypes();
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            depositSnapshot.collateralToSum[collateralTypes[i]] = poolSnapshot
                .collateralToSum[collateralTypes[i]];
        }
    }

    function _checkInitialisePool(address fxToken) private {
        if (pools[fxToken].snapshot.P != 0) return;
        pools[fxToken].snapshot.P = DECIMAL_PRECISION;
    }

    /**
     * @notice updates the Comptroller contract
     * @param _comptroller new comptroller address
     */
    function setComptroller(address _comptroller) external override onlyOwner {
        comptroller = _comptroller;
    }

    function Comptroller() private view returns (IComptroller) {
        return IComptroller(comptroller);
    }

    function VaultLibrary() private view returns (IVaultLibrary) {
        return IVaultLibrary(Comptroller().vaultLibrary());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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

    function vaultLibrary() external view returns (address);

    function setOracle(address fxToken, address oracle) external;

    function isFxTokenValid(address fxToken) external view returns (bool);
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
pragma solidity ^0.7.6;
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

    event Liquidate(address indexed account, address indexed token);

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

    function tokensRequiredForCrIncrease(
        uint256 crTargetPercent,
        uint256 debt,
        uint256 collateral
    ) external pure returns (uint256 amount);

    function liquidate(address account, address fxToken) external;

    function setComptroller(address comptroller) external;
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

    function getVaultMinimumRatio(address account, address fxToken)
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <=0.7.6;

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

