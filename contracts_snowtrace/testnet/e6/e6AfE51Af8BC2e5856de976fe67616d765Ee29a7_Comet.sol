// SPDX-License-Identifier: XXX ADD VALID LICENSE
pragma solidity ^0.8.0;

import "./CometMath.sol";
import "./CometStorage.sol";
import "./ERC20.sol";

/**
 * @title Compound's Comet Contract
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
contract Comet is CometMath, CometStorage {
    struct AssetInfo {
        address asset;
        uint borrowCollateralFactor;
        uint liquidateCollateralFactor;
        uint supplyCap;
    }

    struct Configuration {
        address governor;
        address pauseGuardian;
        address priceOracle;
        address baseToken;

        uint64 kink;
        uint64 perYearInterestRateSlopeLow;
        uint64 perYearInterestRateSlopeHigh;
        uint64 perYearInterestRateBase;
        uint64 reserveRate;
        uint64 trackingIndexScale;
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        uint104 baseMinForRewards;
        uint104 baseBorrowMin;

        AssetInfo[] assetInfo;
    }

    /// @notice The name of this contract
    string public constant name = "Compound Comet";

    /// @notice The major version of this contract
    string public constant version = "0";

    // XXX we should prob camelCase all these?
    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for allowBySig Authorization
    bytes32 public constant AUTHORIZATION_TYPEHASH = keccak256("Authorization(address owner,address manager,bool isAllowed,uint256 nonce,uint256 expiry)");

    /// @notice The highest valid value for s in an ECDSA signature pair (0 < s < secp256k1n ÷ 2 + 1)
    /// @dev See https://ethereum.github.io/yellowpaper/paper.pdf #307)
    uint public constant MAX_VALID_ECDSA_S = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    /// @notice The number of seconds per year
    /// @dev 365 days * 24 hours * 60 minutes * 60 seconds
    uint64 public constant secondsPerYear = 31_536_000;

    /// @notice The max number of assets this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint public constant maxAssets = 3;

    /// @notice The number of assets this contract actually supports
    uint public immutable numAssets;

    /// @notice Offsets for specific actions in the pause flag bit array
    uint8 public constant pauseSupplyOffset = 0;
    uint8 public constant pauseTransferOffset = 1;
    uint8 public constant pauseWithdrawOffset = 2;
    uint8 public constant pauseAbsorbOffset = 3;
    uint8 public constant pauseBuyOffset = 4;

    /** General configuration constants **/

    /// @notice The admin of the protocol
    address public immutable governor;

    /// @notice The account which may trigger pauses
    address public immutable pauseGuardian;

    /// @notice The address of the price oracle contract
    address public immutable priceOracle;

    /// @notice The address of the base token contract
    address public immutable baseToken;

    /// @notice The point in the supply and borrow rates separating the low interest rate slope and the high interest rate slope (factor)
    uint64 public immutable kink;

    /// @notice Per second interest rate slope applied when utilization is below kink (factor)
    uint64 public immutable perSecondInterestRateSlopeLow;

    /// @notice Per second interest rate slope applied when utilization is above kink (factor)
    uint64 public immutable perSecondInterestRateSlopeHigh;

    /// @notice Per second base interest rate (factor)
    uint64 public immutable perSecondInterestRateBase;

    /// @notice The rate of total interest paid that goes into reserves (factor)
    uint64 public immutable reserveRate;

    /// @notice The scale for base token (must be less than 18 decimals)
    uint64 public immutable baseScale;

    /// @notice The scale for base index (depends on time/rate scales, not base token)
    uint64 public constant baseIndexScale = 1e15;

    /// @notice The scale for factors
    uint64 public constant factorScale = 1e18;

    /// @notice The scale for reward tracking
    uint64 public immutable trackingIndexScale;

    /// @notice The speed at which supply rewards are tracked (in trackingIndexScale)
    uint64 public immutable baseTrackingSupplySpeed;

    /// @notice The speed at which borrow rewards are tracked (in trackingIndexScale)
    uint64 public immutable baseTrackingBorrowSpeed;

    /// @notice The minimum amount of base wei for rewards to accrue
    /// @dev This must be large enough so as to prevent division by base wei from overflowing the 64 bit indices.
    uint104 public immutable baseMinForRewards;

    /// @notice The minimum base amount required to initiate a borrow
    uint104 public immutable baseBorrowMin;

    /**  Collateral asset configuration **/

    address internal immutable asset00;
    address internal immutable asset01;
    address internal immutable asset02;

    uint internal immutable borrowCollateralFactor00;
    uint internal immutable borrowCollateralFactor01;
    uint internal immutable borrowCollateralFactor02;

    uint internal immutable liquidateCollateralFactor00;
    uint internal immutable liquidateCollateralFactor01;
    uint internal immutable liquidateCollateralFactor02;

    uint internal immutable supplyCap00;
    uint internal immutable supplyCap01;
    uint internal immutable supplyCap02;

    /**
     * @notice Construct a new protocol instance
     * @param config The mapping of initial/constant parameters
     **/
    constructor(Configuration memory config) {
        // Sanity checks
        uint decimals = ERC20(config.baseToken).decimals();
        require(decimals <= 18, "base token has too many decimals");
        require(config.baseMinForRewards > 0, "baseMinForRewards should be > 0");
        require(config.assetInfo.length <= maxAssets, "too many asset configs");
        // XXX other sanity checks? for rewards?

        // Copy configuration
        governor = config.governor;
        pauseGuardian = config.pauseGuardian;
        priceOracle = config.priceOracle;
        baseToken = config.baseToken;

        baseScale = uint64(10 ** decimals);
        trackingIndexScale = config.trackingIndexScale;

        baseMinForRewards = config.baseMinForRewards;
        baseTrackingSupplySpeed = config.baseTrackingSupplySpeed;
        baseTrackingBorrowSpeed = config.baseTrackingBorrowSpeed;

        baseBorrowMin = config.baseBorrowMin;

        // Set asset info
        numAssets = config.assetInfo.length;

        asset00 = _getAsset(config.assetInfo, 0).asset;
        asset01 = _getAsset(config.assetInfo, 1).asset;
        asset02 = _getAsset(config.assetInfo, 2).asset;

        borrowCollateralFactor00 = _getAsset(config.assetInfo, 0).borrowCollateralFactor;
        borrowCollateralFactor01 = _getAsset(config.assetInfo, 1).borrowCollateralFactor;
        borrowCollateralFactor02 = _getAsset(config.assetInfo, 2).borrowCollateralFactor;

        liquidateCollateralFactor00 = _getAsset(config.assetInfo, 0).liquidateCollateralFactor;
        liquidateCollateralFactor01 = _getAsset(config.assetInfo, 1).liquidateCollateralFactor;
        liquidateCollateralFactor02 = _getAsset(config.assetInfo, 2).liquidateCollateralFactor;

        supplyCap00 = _getAsset(config.assetInfo, 0).supplyCap;
        supplyCap01 = _getAsset(config.assetInfo, 1).supplyCap;
        supplyCap02 = _getAsset(config.assetInfo, 2).supplyCap;

        // Set interest rate model configs
        kink = config.kink;
        perSecondInterestRateSlopeLow = config.perYearInterestRateSlopeLow / secondsPerYear;
        perSecondInterestRateSlopeHigh = config.perYearInterestRateSlopeHigh / secondsPerYear;
        perSecondInterestRateBase = config.perYearInterestRateBase / secondsPerYear;
        reserveRate = config.reserveRate;

        // Initialize aggregates
        totalsBasic.lastAccrualTime = getNow();
        totalsBasic.baseSupplyIndex = baseIndexScale;
        totalsBasic.baseBorrowIndex = baseIndexScale;
        totalsBasic.trackingSupplyIndex = 0;
        totalsBasic.trackingBorrowIndex = 0;
    }

    /**
     * @dev XXX (dev for internal)
     */
    function _getAsset(AssetInfo[] memory assetInfo, uint i) internal pure returns (AssetInfo memory) {
        if (i < assetInfo.length)
            return assetInfo[i];
        return AssetInfo({
            asset: address(0),
            borrowCollateralFactor: uint256(0),
            liquidateCollateralFactor: uint256(0),
            supplyCap: uint256(0)
        });
    }

    /**
     * @notice Get the i-th asset info, according to the order they were passed in originally
     * @param i The index of the asset info to get
     * @return The asset info object
     */
    function getAssetInfo(uint i) public view returns (AssetInfo memory) {
        require(i < numAssets, "asset info not found");

        if (i == 0) return AssetInfo({asset: asset00, borrowCollateralFactor: borrowCollateralFactor00, liquidateCollateralFactor: liquidateCollateralFactor00, supplyCap: supplyCap00 });
        if (i == 1) return AssetInfo({asset: asset01, borrowCollateralFactor: borrowCollateralFactor01, liquidateCollateralFactor: liquidateCollateralFactor01, supplyCap: supplyCap01 });
        if (i == 2) return AssetInfo({asset: asset02, borrowCollateralFactor: borrowCollateralFactor02, liquidateCollateralFactor: liquidateCollateralFactor02, supplyCap: supplyCap02 });
        revert("absurd");
    }

    /**
     * @notice XXX
     */
    function assets() public view returns (AssetInfo[] memory) {
        AssetInfo[] memory result = new AssetInfo[](numAssets);
        for (uint i = 0; i < numAssets; i++) {
            result[i] = getAssetInfo(i);
        }
        return result;
    }

    /**
     * @notice XXX
     */
    function assetAddresses() public view returns (address[] memory) {
        address[] memory result = new address[](numAssets);
        for (uint i = 0; i < numAssets; i++) {
            result[i] = getAssetInfo(i).asset;
        }
        return result;
    }

    /**
     * @return The current timestamp
     **/
    function getNow() virtual public view returns (uint40) {
        require(block.timestamp < 2**40, "timestamp exceeds size (40 bits)");
        return uint40(block.timestamp);
    }

    /**
     * @notice Accrue interest (and rewards) in base token supply and borrows
     **/
    function accrue() public {
        totalsBasic = accrue(totalsBasic);
    }

    /**
     * @notice Accrue interest (and rewards) in base token supply and borrows
     **/
    function accrue(TotalsBasic memory totals) internal view returns (TotalsBasic memory) {
        uint40 now_ = getNow();
        uint timeElapsed = now_ - totals.lastAccrualTime;
        if (timeElapsed > 0) {
            uint supplyRate = getSupplyRateInternal(totals);
            uint borrowRate = getBorrowRateInternal(totals);
            totals.baseSupplyIndex += safe64(mulFactor(totals.baseSupplyIndex, supplyRate * timeElapsed));
            totals.baseBorrowIndex += safe64(mulFactor(totals.baseBorrowIndex, borrowRate * timeElapsed));
            if (totals.totalSupplyBase >= baseMinForRewards) {
                uint supplySpeed = baseTrackingSupplySpeed;
                totals.trackingSupplyIndex += safe64(divBaseWei(supplySpeed * timeElapsed, totals.totalSupplyBase));
            }
            if (totals.totalBorrowBase >= baseMinForRewards) {
                uint borrowSpeed = baseTrackingBorrowSpeed;
                totals.trackingBorrowIndex += safe64(divBaseWei(borrowSpeed * timeElapsed, totals.totalBorrowBase));
            }
        }
        totals.lastAccrualTime = now_;
        return totals;
    }

    /**
     * @notice Allow or disallow another address to withdraw, or transfer from the sender
     * @param manager The account which will be allowed or disallowed
     * @param isAllowed_ Whether to allow or disallow
     */
    function allow(address manager, bool isAllowed_) external {
        allowInternal(msg.sender, manager, isAllowed_);
    }

    /**
     * @dev Stores the flag marking whether the manager is allowed to act on behalf of owner
     */
    function allowInternal(address owner, address manager, bool isAllowed_) internal {
        isAllowed[owner][manager] = isAllowed_;
    }

    /**
     * @notice Sets authorization status for a manager via signature from signatory
     * @param owner The address that signed the signature
     * @param manager The address to authorize (or rescind authorization from)
     * @param isAllowed_ Whether to authorize or rescind authorization from manager
     * @param nonce The next expected nonce value for the signatory
     * @param expiry Expiration time for the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function allowBySig(
        address owner,
        address manager,
        bool isAllowed_,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(uint256(s) <= MAX_VALID_ECDSA_S, "invalid value: s");
        // v ∈ {27, 28} (source: https://ethereum.github.io/yellowpaper/paper.pdf #308)
        require(v == 27 || v == 28, "invalid value: v");
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(AUTHORIZATION_TYPEHASH, owner, manager, isAllowed_, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(owner == signatory, "signature does not match arguments");
        require(signatory != address(0), "invalid signature");
        require(nonce == userNonce[signatory], "invalid nonce");
        require(block.timestamp < expiry, "signed transaction expired");
        userNonce[signatory]++;
        allowInternal(signatory, manager, isAllowed_);
    }

    /**
     * @notice Determine if the manager has permission to act on behalf of the owner
     * @param owner The owner account
     * @param manager The manager account
     * @return Whether or not the manager has permission
     */
    function hasPermission(address owner, address manager) public view returns (bool) {
        return owner == manager || isAllowed[owner][manager];

    }

    /**
     * @return The current per second supply rate
     */
    function getSupplyRate() public view returns (uint64) {
        return getSupplyRateInternal(totalsBasic);
    }

    /**
     * @dev Calculate current per second supply rate given totals
     */
    function getSupplyRateInternal(TotalsBasic memory totals) internal view returns (uint64) {
        uint utilization = getUtilizationInternal(totals);
        uint reserveScalingFactor = utilization * (factorScale - reserveRate) / factorScale;
        if (utilization <= kink) {
            // (interestRateBase + interestRateSlopeLow * utilization) * utilization * (1 - reserveRate)
            return safe64(mulFactor(reserveScalingFactor, (perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, utilization))));
        } else {
            // (interestRateBase + interestRateSlopeLow * kink + interestRateSlopeHigh * (utilization - kink)) * utilization * (1 - reserveRate)
            return safe64(mulFactor(reserveScalingFactor, (perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, kink) + mulFactor(perSecondInterestRateSlopeHigh, (utilization - kink)))));
        }
    }

    /**
     * @return The current per second borrow rate
     */
    function getBorrowRate() public view returns (uint64) {
        return getBorrowRateInternal(totalsBasic);
    }

    /**
     * @dev Calculate current per second borrow rate given totals
     */
    function getBorrowRateInternal(TotalsBasic memory totals) internal view returns (uint64) {
        uint utilization = getUtilizationInternal(totals);
        if (utilization <= kink) {
            // interestRateBase + interestRateSlopeLow * utilization
            return safe64(perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, utilization));
        } else {
            // interestRateBase + interestRateSlopeLow * kink + interestRateSlopeHigh * (utilization - kink)
            return safe64(perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, kink) + mulFactor(perSecondInterestRateSlopeHigh, (utilization - kink)));
        }
    }

    /**
     * @return The utilization rate of the base asset
     */
    function getUtilization() public view returns (uint) {
        return getUtilizationInternal(totalsBasic);
    }

    /**
     * @dev Calculate utilization rate of the base asset given totals
     */
    function getUtilizationInternal(TotalsBasic memory totals) internal pure returns (uint) {
        uint totalSupply = presentValueSupply(totals, totals.totalSupplyBase);
        uint totalBorrow = presentValueBorrow(totals, totals.totalBorrowBase);
        if (totalSupply == 0) {
            return 0;
        } else {
            return totalBorrow * factorScale / totalSupply;
        }
    }

    /**
     * @return Whether the account is minimally collateralized enough to borrow
     */
    function isBorrowCollateralized(address account) public view returns (bool) {
        return true; // XXX
    }

    /**
     * @dev The positive present supply balance if positive or the negative borrow balance if negative
     */
    function presentValue(TotalsBasic memory totals, int104 principalValue_) internal pure returns (int104) {
        if (principalValue_ >= 0) {
            return signed104(presentValueSupply(totals, unsigned104(principalValue_)));
        } else {
            return -signed104(presentValueBorrow(totals, unsigned104(-principalValue_)));
        }
    }

    /**
     * @dev The principal amount projected forward by the supply index
     */
    function presentValueSupply(TotalsBasic memory totals, uint104 principalValue_) internal pure returns (uint104) {
        return uint104(uint(principalValue_) * totals.baseSupplyIndex / baseIndexScale);
    }

    /**
     * @dev The principal amount projected forward by the borrow index
     */
    function presentValueBorrow(TotalsBasic memory totals, uint104 principalValue_) internal pure returns (uint104) {
        return uint104(uint(principalValue_) * totals.baseBorrowIndex / baseIndexScale);
    }

    /**
     * @dev The positive principal if positive or the negative principal if negative
     */
    function principalValue(TotalsBasic memory totals, int104 presentValue_) internal pure returns (int104) {
        if (presentValue_ >= 0) {
            return signed104(presentValueSupply(totals, unsigned104(presentValue_)));
        } else {
            return -signed104(presentValueBorrow(totals, unsigned104(-presentValue_)));
        }
    }

    /**
     * @dev The present value projected backward by the supply index
     */
    function principalValueSupply(TotalsBasic memory totals, uint104 presentValue_) internal pure returns (uint104) {
        return uint104(uint(presentValue_) * baseIndexScale / totals.baseSupplyIndex);
    }

    /**
     * @dev The present value projected backwrd by the borrow index
     */
    function principalValueBorrow(TotalsBasic memory totals, uint104 presentValue_) internal pure returns (uint104) {
        return uint104(uint(presentValue_) * baseIndexScale / totals.baseBorrowIndex);
    }

    /**
     * @dev The amounts broken into repay and supply amounts, given negative balance
     */
    function repayAndSupplyAmount(int104 balance, uint104 amount) internal pure returns (uint104, uint104) {
        uint104 repayAmount = balance < 0 ? min(unsigned104(-balance), amount) : 0;
        uint104 supplyAmount = amount - repayAmount;
        return (repayAmount, supplyAmount);
    }

    /**
     * @dev The amounts broken into withdraw and borrow amounts, given positive balance
     */
    function withdrawAndBorrowAmount(int104 balance, uint104 amount) internal pure returns (uint104, uint104) {
        uint104 withdrawAmount = balance > 0 ? min(unsigned104(balance), amount) : 0;
        uint104 borrowAmount = amount - withdrawAmount;
        return (withdrawAmount, borrowAmount);
    }

    /**
     * @notice Pauses different actions within Comet
     * @param supplyPaused Boolean for pausing supply actions
     * @param transferPaused Boolean for pausing transfer actions
     * @param withdrawPaused Boolean for pausing withdraw actions
     * @param absorbPaused Boolean for pausing absorb actions
     * @param buyPaused Boolean for pausing buy actions
     */
    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) external {
        require(msg.sender == governor || msg.sender == pauseGuardian, "Unauthorized");

        totalsBasic.pauseFlags =
            uint8(0) |
            (toUInt8(supplyPaused) << pauseSupplyOffset) |
            (toUInt8(transferPaused) << pauseTransferOffset) |
            (toUInt8(withdrawPaused) << pauseWithdrawOffset) |
            (toUInt8(absorbPaused) << pauseAbsorbOffset) |
            (toUInt8(buyPaused) << pauseBuyOffset);
    }

    /**
     * @return Whether or not supply actions are paused
     */
    function isSupplyPaused() public view returns (bool) {
        return toBool(totalsBasic.pauseFlags & (uint8(1) << pauseSupplyOffset));
    }

    /**
     * @return Whether or not transfer actions are paused
     */
    function isTransferPaused() public view returns (bool) {
        return toBool(totalsBasic.pauseFlags & (uint8(1) << pauseTransferOffset));
    }

    /**
     * @return Whether or not withdraw actions are paused
     */
    function isWithdrawPaused() public view returns (bool) {
        return toBool(totalsBasic.pauseFlags & (uint8(1) << pauseWithdrawOffset));
    }

    /**
     * @return Whether or not absorb actions are paused
     */
    function isAbsorbPaused() public view returns (bool) {
        return toBool(totalsBasic.pauseFlags & (uint8(1) << pauseAbsorbOffset));
    }

    /**
     * @return Whether or not buy actions are paused
     */
    function isBuyPaused() public view returns (bool) {
        return toBool(totalsBasic.pauseFlags & (uint8(1) << pauseBuyOffset));
    }

    /**
     * @dev Multiply a number by a factor
     */
    function mulFactor(uint n, uint factor) internal pure returns (uint) {
        return n * factor / factorScale;
    }

    /**
     * @dev Divide a number by an amount of base
     */
    function divBaseWei(uint n, uint baseWei) internal view returns (uint) {
        return n * baseScale / baseWei;
    }

    /**
     * @dev Determine index of asset that matches given address
     */
    function getAssetOffset(address asset) internal view returns (uint8 offset) {
        AssetInfo[] memory _assets = assets();
        for (uint8 i = 0; i < _assets.length; i++) {
            if (asset == _assets[i].asset) {
                return i;
            }
        }
        revert("asset not found");
    }

    /**
     * @dev Whether user has a non-zero balance of an asset, given assetsIn flags
     */
    function isInAsset(uint16 assetsIn, uint8 assetOffset) internal pure returns (bool) {
        return (assetsIn & (uint8(1) << assetOffset) != 0);
    }

    /**
     * @dev Update assetsIn bit vector if user has entered or exited an asset
     */
    function updateAssetsIn(
        address account,
        address asset,
        uint128 initialUserBalance,
        uint128 finalUserBalance
    ) internal {
        uint8 assetOffset = getAssetOffset(asset);
        if (initialUserBalance == 0 && finalUserBalance != 0) {
            // set bit for asset
            userBasic[account].assetsIn |= (uint8(1) << assetOffset);
        } else if (initialUserBalance != 0 && finalUserBalance == 0) {
            // clear bit for asset
            userBasic[account].assetsIn &= ~(uint8(1) << assetOffset);
        }
    }

    /**
     * @dev Write updated balance to store and tracking participation
     */
    function updateBaseBalance(TotalsBasic memory totals, address account, UserBasic memory basic, int104 principalNew) internal {
        int104 principal = basic.principal;
        basic.principal = principalNew;

        if (principal >= 0) {
            uint indexDelta = totals.trackingSupplyIndex - basic.baseTrackingIndex;
            basic.baseTrackingAccrued += safe64(uint104(principal) * indexDelta / baseIndexScale); // XXX decimals
        } else {
            uint indexDelta = totals.trackingBorrowIndex - basic.baseTrackingIndex;
            basic.baseTrackingAccrued += safe64(uint104(-principal) * indexDelta / baseIndexScale); // XXX decimals
        }

        if (principalNew >= 0) {
            basic.baseTrackingIndex = totals.trackingSupplyIndex;
        } else {
            basic.baseTrackingIndex = totals.trackingBorrowIndex;
        }

        userBasic[account] = basic;
    }

    /**
     * @notice Query the current base balance of an account
     * @param account The account whose balance to query
     * @return The present day base balance of the account
     */
    function baseBalanceOf(address account) external view returns (int104) {
        return presentValue(totalsBasic, userBasic[account].principal);
    }

    /**
     * @notice Query the current collateral balance of an account
     * @param account The account whose balance to query
     * @param asset The collateral asset whi
     * @return The collateral balance of the account
     */
    function collateralBalanceOf(address account, address asset) external view returns (uint128) {
        return userCollateral[account][asset].balance;
    }

    /**
     * @dev Safe ERC20 transfer in which returns the actual amount received,
     *  which may be less than `amount` if there is a fee attached to the transfer.
     */
    function doTransferIn(address asset, address from, uint amount) internal returns (uint) {
        // XXX reconsider whether we just reject fee tokens and trust amount
        ERC20 token = ERC20(asset);
        uint balanceBefore = token.balanceOf(address(this));

        bool success = token.transferFrom(from, address(this), amount);
        require(success, "failed to transfer token in");

        uint balanceAfter = token.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    /**
     * @dev Safe ERC20 transfer out
     */
    function doTransferOut(address asset, address to, uint amount) internal {
        bool success = ERC20(asset).transfer(to, amount);
        require(success, "failed to transfer token out");
    }

    /**
     * @notice Supply an amount of asset to the protocol
     * @param asset The asset to supply
     * @param amount The quantity to supply
     */
    function supply(address asset, uint amount) external {
        return supplyInternal(msg.sender, msg.sender, msg.sender, asset, amount);
    }

    /**
     * @notice Supply an amount of asset to dst
     * @param dst The address which will hold the balance
     * @param asset The asset to supply
     * @param amount The quantity to supply
     */
    function supplyTo(address dst, address asset, uint amount) external {
        return supplyInternal(msg.sender, msg.sender, dst, asset, amount);
    }

    /**
     * @notice Supply an amount of asset from `from` to dst, if allowed
     * @param from The supplier address
     * @param dst The address which will hold the balance
     * @param asset The asset to supply
     * @param amount The quantity to supply
     */
    function supplyFrom(address from, address dst, address asset, uint amount) external {
        return supplyInternal(msg.sender, from, dst, asset, amount);
    }

    /**
     * @dev Supply either collateral or base asset, depending on the asset, if operator is allowed
     */
    function supplyInternal(address operator, address from, address dst, address asset, uint amount) internal {
        require(hasPermission(from, operator), "operator not permitted");

        if (asset == baseToken) {
            return supplyBase(from, dst, safe104(amount));
        } else {
            return supplyCollateral(from, dst, asset, safe128(amount));
        }
    }

    /**
     * @dev Supply an amount of base asset from `from` to dst
     */
    function supplyBase(address from, address dst, uint104 amount) internal {
        uint104 actualAmount = safe104(doTransferIn(baseToken, from, amount));

        TotalsBasic memory totals = totalsBasic;
        totals = accrue(totals);

        uint104 totalSupplyBalance = presentValueSupply(totals, totals.totalSupplyBase);
        uint104 totalBorrowBalance = presentValueBorrow(totals, totals.totalBorrowBase);

        UserBasic memory dstUser = userBasic[dst];
        int104 dstBalance = presentValue(totals, dstUser.principal);

        (uint104 repayAmount, uint104 supplyAmount) = repayAndSupplyAmount(dstBalance, actualAmount);

        totalSupplyBalance += supplyAmount;
        totalBorrowBalance -= repayAmount;

        dstBalance += signed104(actualAmount);

        totals.totalSupplyBase = principalValueSupply(totals, totalSupplyBalance);
        totals.totalBorrowBase = principalValueBorrow(totals, totalBorrowBalance);
        totalsBasic = totals;

        updateBaseBalance(totals, dst, dstUser, principalValue(totals, dstBalance));
    }

    /**
     * @dev Supply an amount of collateral asset from `from` to dst
     */
    function supplyCollateral(address from, address dst, address asset, uint128 amount) internal {
        uint128 actualAmount = safe128(doTransferIn(asset, from, amount));

        // XXX reconsider how we do these asset infos / measure gas costs
        AssetInfo memory assetInfo = getAssetInfo(getAssetOffset(asset));
        TotalsCollateral memory totals = totalsCollateral[asset];
        totals.totalSupplyAsset += actualAmount;
        require(totals.totalSupplyAsset <= assetInfo.supplyCap, "supply cap exceeded");

        uint128 dstCollateral = userCollateral[dst][asset].balance;
        uint128 dstCollateralNew = dstCollateral + actualAmount;

        totalsCollateral[asset] = totals;
        userCollateral[dst][asset].balance = dstCollateralNew;

        updateAssetsIn(dst, asset, dstCollateral, dstCollateralNew);
    }

    /**
     * @notice Transfer an amount of asset to dst
     * @param dst The recipient address
     * @param asset The asset to transfer
     * @param amount The quantity to transfer
     */
    function transfer(address dst, address asset, uint amount) external {
        return transferInternal(msg.sender, msg.sender, dst, asset, amount);
    }

    /**
     * @notice Transfer an amount of asset from src to dst, if allowed
     * @param src The sender address
     * @param dst The recipient address
     * @param asset The asset to transfer
     * @param amount The quantity to transfer
     */
    function transferFrom(address src, address dst, address asset, uint amount) external {
        return transferInternal(msg.sender, src, dst, asset, amount);
    }

    /**
     * @dev Transfer either collateral or base asset, depending on the asset, if operator is allowed
     */
    function transferInternal(address operator, address src, address dst, address asset, uint amount) internal {
        require(hasPermission(src, operator), "operator not permitted");

        if (asset == baseToken) {
            return transferBase(src, dst, safe104(amount));
        } else {
            return transferCollateral(src, dst, asset, safe128(amount));
        }
    }

    /**
     * @dev Transfer an amount of base asset from src to dst, borrowing if possible/necessary
     */
    function transferBase(address src, address dst, uint104 amount) internal {
        TotalsBasic memory totals = totalsBasic;
        totals = accrue(totals);
        uint104 totalSupplyBalance = presentValueSupply(totals, totals.totalSupplyBase);
        uint104 totalBorrowBalance = presentValueBorrow(totals, totals.totalBorrowBase);

        UserBasic memory srcUser = userBasic[src];
        UserBasic memory dstUser = userBasic[dst];
        int104 srcBalance = presentValue(totals, srcUser.principal);
        int104 dstBalance = presentValue(totals, dstUser.principal);

        (uint104 withdrawAmount, uint104 borrowAmount) = withdrawAndBorrowAmount(srcBalance, amount);
        (uint104 repayAmount, uint104 supplyAmount) = repayAndSupplyAmount(dstBalance, amount);

        totalSupplyBalance += supplyAmount - withdrawAmount;
        totalBorrowBalance += borrowAmount - repayAmount;

        srcBalance -= signed104(amount);
        dstBalance += signed104(amount);

        totals.totalSupplyBase = principalValueSupply(totals, totalSupplyBalance);
        totals.totalBorrowBase = principalValueBorrow(totals, totalBorrowBalance);
        totalsBasic = totals;

        updateBaseBalance(totals, src, srcUser, principalValue(totals, srcBalance));
        updateBaseBalance(totals, dst, dstUser, principalValue(totals, dstBalance));

        if (srcBalance < 0) {
            require(uint104(-srcBalance) >= baseBorrowMin, "borrow too small");
            require(isBorrowCollateralized(src), "borrow cannot be maintained");
        }
    }

    /**
     * @dev Transfer an amount of collateral asset from src to dst
     */
    function transferCollateral(address src, address dst, address asset, uint128 amount) internal {
        uint128 srcCollateral = userCollateral[src][asset].balance;
        uint128 dstCollateral = userCollateral[dst][asset].balance;
        uint128 srcCollateralNew = srcCollateral - amount;
        uint128 dstCollateralNew = dstCollateral + amount;

        userCollateral[src][asset].balance = srcCollateralNew;
        userCollateral[dst][asset].balance = dstCollateralNew;

        updateAssetsIn(src, asset, srcCollateral, srcCollateralNew);
        updateAssetsIn(dst, asset, dstCollateral, dstCollateralNew);

        // Note: no accrue interest, BorrowCF < LiquidationCF covers small changes
        require(isBorrowCollateralized(src), "borrow would not be maintained");
    }

    /**
     * @notice Withdraw an amount of asset from the protocol
     * @param asset The asset to withdraw
     * @param amount The quantity to withdraw
     */
    function withdraw(address asset, uint amount) external {
        return withdrawInternal(msg.sender, msg.sender, msg.sender, asset, amount);
    }

    /**
     * @notice Withdraw an amount of asset to `to`
     * @param to The recipient address
     * @param asset The asset to withdraw
     * @param amount The quantity to withdraw
     */
    function withdrawTo(address to, address asset, uint amount) external {
        return withdrawInternal(msg.sender, msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraw an amount of asset from src to `to`, if allowed
     * @param src The sender address
     * @param to The recipient address
     * @param asset The asset to withdraw
     * @param amount The quantity to withdraw
     */
    function withdrawFrom(address src, address to, address asset, uint amount) external {
        return withdrawInternal(msg.sender, src, to, asset, amount);
    }

    /**
     * @dev Withdraw either collateral or base asset, depending on the asset, if operator is allowed
     */
    function withdrawInternal(address operator, address src, address to, address asset, uint amount) internal {
        require(hasPermission(src, operator), "operator not permitted");

        if (asset == baseToken) {
            return withdrawBase(src, to, safe104(amount));
        } else {
            return withdrawCollateral(src, to, asset, safe128(amount));
        }
    }

    /**
     * @dev Withdraw an amount of base asset from src to `to`, borrowing if possible/necessary
     */
    function withdrawBase(address src, address to, uint104 amount) internal {
        TotalsBasic memory totals = totalsBasic;
        totals = accrue(totals);
        uint104 totalSupplyBalance = presentValueSupply(totals, totals.totalSupplyBase);
        uint104 totalBorrowBalance = presentValueBorrow(totals, totals.totalBorrowBase);

        UserBasic memory srcUser = userBasic[src];
        int104 srcBalance = presentValue(totals, srcUser.principal);

        (uint104 withdrawAmount, uint104 borrowAmount) = withdrawAndBorrowAmount(srcBalance, amount);

        totalSupplyBalance -= withdrawAmount;
        totalBorrowBalance += borrowAmount;

        srcBalance -= signed104(amount);

        totals.totalSupplyBase = principalValueSupply(totals, totalSupplyBalance);
        totals.totalBorrowBase = principalValueBorrow(totals, totalBorrowBalance);
        totalsBasic = totals;

        updateBaseBalance(totals, src, srcUser, principalValue(totals, srcBalance));

        if (srcBalance < 0) {
            require(uint104(-srcBalance) >= baseBorrowMin, "borrow too small");
            require(isBorrowCollateralized(src), "borrow cannot be maintained");
        }

        doTransferOut(baseToken, to, amount);
    }

    /**
     * @dev Withdraw an amount of collateral asset from src to `to`
     */
    function withdrawCollateral(address src, address to, address asset, uint128 amount) internal {
        TotalsCollateral memory totals = totalsCollateral[asset];
        totals.totalSupplyAsset -= amount;

        uint128 srcCollateral = userCollateral[src][asset].balance;
        uint128 srcCollateralNew = srcCollateral - amount;

        totalsCollateral[asset] = totals;
        userCollateral[src][asset].balance = srcCollateralNew;

        updateAssetsIn(src, asset, srcCollateral, srcCollateralNew);

        // Note: no accrue interest, BorrowCF < LiquidationCF covers small changes
        require(isBorrowCollateralized(src), "borrow would not be maintained");

        doTransferOut(asset, to, amount);
    }

    // TODO: Remove me. Function while waiting for initializer
    // !! NOT FOR REUSE [YES FOR REFUSE] !!
    function XXX_REMOVEME_XXX_initialize() public {
        require(totalsBasic.lastAccrualTime == 0, "already initialized");
        // Initialize aggregates
        totalsBasic.lastAccrualTime = getNow();
        totalsBasic.baseSupplyIndex = baseIndexScale;
        totalsBasic.baseBorrowIndex = baseIndexScale;
        totalsBasic.trackingSupplyIndex = 0;
        totalsBasic.trackingBorrowIndex = 0;
    }
}

// SPDX-License-Identifier: XXX ADD VALID LICENSE
pragma solidity ^0.8.0;

/**
 * @title Compound's Comet Math Contract
 * @dev Pure math functions
 * @author Compound
 */
contract CometMath {
    function min(uint104 a, uint104 b) internal pure returns (uint104) {
        return a < b ? a : b;
    }

    function safe64(uint n) internal pure returns (uint64) {
        require(n <= type(uint64).max, "number exceeds size (64 bits)");
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        require(n <= type(uint104).max, "number exceeds size (104 bits)");
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "number exceeds size (128 bits)");
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        require(n <= uint104(type(int104).max), "number exceeds max int size");
        return int104(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        require(n >= 0, "number is negative");
        return uint104(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}

// SPDX-License-Identifier: XXX ADD VALID LICENSE
pragma solidity ^0.8.0;

/**
 * @title Compound's Comet Storage Interface
 * @dev Versions can enforce append-only storage slots via inheritance.
 * @author Compound
 */
contract CometStorage {
    // 512 bits total = 2 slots
    struct TotalsBasic {
        // 1st slot
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        // 2nd slot
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    /// @notice Aggregate variables tracked for the entire market
    TotalsBasic public totalsBasic;

    /// @notice Aggregate variables tracked for each collateral asset
    mapping(address => TotalsCollateral) public totalsCollateral;

    /// @notice Mapping of users to accounts which may be permitted to manage the user account
    mapping(address => mapping(address => bool)) public isAllowed;

    /// @notice The next expected nonce for an address, for validating authorizations via signature
    mapping(address => uint) public userNonce;

    /// @notice Mapping of users to base principal and other basic data
    mapping(address => UserBasic) public userBasic;

    /// @notice Mapping of users to collateral data per collateral asset
    mapping(address => mapping(address => UserCollateral)) public userCollateral;
}

// SPDX-License-Identifier: XXX ADD VALID LICENSE
pragma solidity ^0.8.0;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}