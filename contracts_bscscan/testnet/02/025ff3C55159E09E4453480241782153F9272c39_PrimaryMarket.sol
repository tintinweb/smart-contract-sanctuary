// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./SafeDecimalMath.sol";

import "./IPrimaryMarket.sol";
import "./IFund.sol";
import "./ITrancheIndex.sol";

contract PrimaryMarket is IPrimaryMarket, ReentrancyGuard, ITrancheIndex, Ownable {
    event Created(address indexed account, uint256 underlying);
    event Redeemed(address indexed account, uint256 shares);
    event Split(address indexed account, uint256 inM, uint256 outA, uint256 outB);
    event Merged(address indexed account, uint256 outM, uint256 inA, uint256 inB);
    event Claimed(address indexed account, uint256 createdShares, uint256 redeemedUnderlying);
    event Settled(
        uint256 indexed day,
        uint256 sharesToMint,
        uint256 sharesToBurn,
        uint256 creationUnderlying,
        uint256 redemptionUnderlying,
        uint256 fee
    );

    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Creation and redemption of a single account.
    /// @param day Day of the last creation or redemption request.
    /// @param creatingUnderlying Underlying that will be used for creation at the end of this day.
    /// @param redeemingShares Shares that will be redeemed at the end of this day.
    /// @param createdShares Shares already created in previous days.
    /// @param redeemedUnderlying Underlying already redeemed in previous days.
    /// @param version Rebalance version before the end of this trading day.
    struct CreationRedemption {
        uint256 day;
        uint256 creatingUnderlying;
        uint256 redeemingShares;
        uint256 createdShares;
        uint256 redeemedUnderlying;
        uint256 version;
    }

    uint256 private constant MAX_REDEMPTION_FEE_RATE = 0.01e18;
    uint256 private constant MAX_SPLIT_FEE_RATE = 0.01e18;
    uint256 private constant MAX_MERGE_FEE_RATE = 0.01e18;

    uint256 public immutable guardedLaunchStart;
    uint256 public guardedLaunchTotalCap;
    uint256 public guardedLaunchIndividualCap;
    mapping(address => uint256) public guardedLaunchCreations;

    IFund public fund;

    uint256 public redemptionFeeRate;
    uint256 public splitFeeRate;
    uint256 public mergeFeeRate;
    uint256 public minCreationUnderlying;

    mapping(address => CreationRedemption) private _creationRedemptions;

    uint256 public currentDay;
    uint256 public currentCreatingUnderlying;
    uint256 public currentRedeemingShares;
    uint256 public currentFeeInShares;

    mapping(uint256 => uint256) private _historicalCreationRate;
    mapping(uint256 => uint256) private _historicalRedemptionRate;

    constructor(
        address fund_,
        uint256 guardedLaunchStart_,
        uint256 redemptionFeeRate_,
        uint256 splitFeeRate_,
        uint256 mergeFeeRate_,
        uint256 minCreationUnderlying_
    ) public Ownable() {
        require(redemptionFeeRate_ <= MAX_REDEMPTION_FEE_RATE, "Exceed max redemption fee rate");
        require(splitFeeRate_ <= MAX_SPLIT_FEE_RATE, "Exceed max split fee rate");
        require(mergeFeeRate_ <= MAX_MERGE_FEE_RATE, "Exceed max merge fee rate");
        fund = IFund(fund_);
        guardedLaunchStart = guardedLaunchStart_;
        redemptionFeeRate = redemptionFeeRate_;
        splitFeeRate = splitFeeRate_;
        mergeFeeRate = mergeFeeRate_;
        minCreationUnderlying = minCreationUnderlying_;
        currentDay = fund.currentDay();
    }

    function creationRedemptionOf(address account)
        external
        view
        returns (CreationRedemption memory)
    {
        return _currentCreationRedemption(account);
    }

    function create(uint256 underlying) external nonReentrant onlyActive {
        require(underlying >= minCreationUnderlying, "Min amount");
        IERC20(fund.tokenUnderlying()).safeTransferFrom(msg.sender, address(this), underlying);

        CreationRedemption memory cr = _currentCreationRedemption(msg.sender);
        cr.creatingUnderlying = cr.creatingUnderlying.add(underlying);
        _updateCreationRedemption(msg.sender, cr);

        currentCreatingUnderlying = currentCreatingUnderlying.add(underlying);

        if (block.timestamp < guardedLaunchStart + 4 weeks) {
            guardedLaunchCreations[msg.sender] = guardedLaunchCreations[msg.sender].add(underlying);
            require(
                IERC20(fund.tokenUnderlying()).balanceOf(address(fund)).add(
                    currentCreatingUnderlying
                ) <= guardedLaunchTotalCap,
                "Guarded launch: exceed total cap"
            );
            require(
                guardedLaunchCreations[msg.sender] <= guardedLaunchIndividualCap,
                "Guarded launch: exceed individual cap"
            );
        }

        emit Created(msg.sender, underlying);
    }

    function redeem(uint256 shares) external onlyActive {
        require(shares != 0, "Zero shares");
        // Use burn and mint to simulate a transfer, so that we don't need a special transferFrom()
        fund.burn(TRANCHE_M, msg.sender, shares);
        fund.mint(TRANCHE_M, address(this), shares);

        CreationRedemption memory cr = _currentCreationRedemption(msg.sender);
        cr.redeemingShares = cr.redeemingShares.add(shares);
        _updateCreationRedemption(msg.sender, cr);

        currentRedeemingShares = currentRedeemingShares.add(shares);
        emit Redeemed(msg.sender, shares);
    }

    function claim(address account)
        external
        override
        nonReentrant
        returns (uint256 createdShares, uint256 redeemedUnderlying)
    {
        CreationRedemption memory cr = _currentCreationRedemption(account);
        createdShares = cr.createdShares;
        redeemedUnderlying = cr.redeemedUnderlying;

        if (createdShares > 0) {
            IERC20(fund.tokenM()).safeTransfer(account, createdShares);
            cr.createdShares = 0;
        }
        if (redeemedUnderlying > 0) {
            IERC20(fund.tokenUnderlying()).safeTransfer(account, redeemedUnderlying);
            cr.redeemedUnderlying = 0;
        }
        _updateCreationRedemption(account, cr);

        emit Claimed(account, createdShares, redeemedUnderlying);
    }

    function split(uint256 inM) external onlyActive {
        require(
            block.timestamp >= guardedLaunchStart + 2 weeks,
            "Guarded launch: split not ready yet"
        );
        (uint256 weightA, uint256 weightB) = fund.trancheWeights();
        // Charge splitting fee and round it to a multiple of (weightA + weightB)
        uint256 unit = inM.sub(inM.multiplyDecimal(splitFeeRate)) / (weightA + weightB);
        require(unit > 0, "Too little to split");
        uint256 inMAfterFee = unit * (weightA + weightB);
        uint256 outA = unit * weightA;
        uint256 outB = inMAfterFee - outA;
        uint256 feeM = inM - inMAfterFee;

        fund.burn(TRANCHE_M, msg.sender, inM);
        fund.mint(TRANCHE_A, msg.sender, outA);
        fund.mint(TRANCHE_B, msg.sender, outB);
        fund.mint(TRANCHE_M, address(this), feeM);

        currentFeeInShares = currentFeeInShares.add(feeM);
        emit Split(msg.sender, inM, outA, outB);
    }

    function merge(uint256 inA) external onlyActive {
        (uint256 weightA, uint256 weightB) = fund.trancheWeights();
        // Round to tranche weights
        uint256 unit = inA / weightA;
        require(unit > 0, "Too little to merge");
        // Keep unmergable Token A unchanged.
        inA = unit * weightA;
        uint256 inB = unit.mul(weightB);
        uint256 outMBeforeFee = inA.add(inB);
        uint256 feeM = outMBeforeFee.multiplyDecimal(mergeFeeRate);
        uint256 outM = outMBeforeFee.sub(feeM);

        fund.burn(TRANCHE_A, msg.sender, inA);
        fund.burn(TRANCHE_B, msg.sender, inB);
        fund.mint(TRANCHE_M, msg.sender, outM);
        fund.mint(TRANCHE_M, address(this), feeM);

        currentFeeInShares = currentFeeInShares.add(feeM);
        emit Merged(msg.sender, outM, inA, inB);
    }

    /// @notice Settle ongoing creations and redemptions and also split and merge fees.
    ///
    ///         Creations and redemptions are settled according to the current shares and
    ///         underlying assets in the fund. Split and merge fee charged as Token M are also
    ///         redeemed at the same rate (without redemption fee).
    ///
    ///         This function does not mint or burn shares, nor transfer underlying assets.
    ///         It returns the following changes that should be done by the fund:
    ///
    ///         1. Mint or burn net shares (creations v.s. redemptions + split/merge fee).
    ///         2. Transfer underlying to or from this contract (creations v.s. redemptions).
    ///         3. Transfer fee in underlying assets to the governance address.
    ///
    ///         This function can only be called from the Fund contract. It should be called
    ///         after protocol fee is collected and before rebalance is triggered for the same
    ///         trading day.
    /// @param day The trading day to settle
    /// @param fundTotalShares Total shares of the fund (as if all Token A and B are merged)
    /// @param fundUnderlying Underlying assets in the fund
    /// @param underlyingPrice Price of the underlying assets at the end of the trading day
    /// @param previousNav NAV of Token M of the previous trading day
    /// @return sharesToMint Amount of Token M to mint for creations
    /// @return sharesToBurn Amount of Token M to burn for redemptions and split/merge fee
    /// @return creationUnderlying Underlying assets received for creations (including creation fee)
    /// @return redemptionUnderlying Underlying assets to be redeemed (excluding redemption fee)
    /// @return fee Total fee in underlying assets for the fund to transfer to the governance address,
    ///         inlucding creation fee, redemption fee and split/merge fee
    function settle(
        uint256 day,
        uint256 fundTotalShares,
        uint256 fundUnderlying,
        uint256 underlyingPrice,
        uint256 previousNav
    )
        external
        override
        nonReentrant
        onlyFund
        returns (
            uint256 sharesToMint,
            uint256 sharesToBurn,
            uint256 creationUnderlying,
            uint256 redemptionUnderlying,
            uint256 fee
        )
    {
        require(day >= currentDay, "Already settled");

        // Creation
        creationUnderlying = currentCreatingUnderlying;
        if (creationUnderlying > 0) {
            if (fundUnderlying > 0) {
                sharesToMint = creationUnderlying.mul(fundTotalShares).div(fundUnderlying);
            } else {
                // NAV is rounded down. Computing creations using NAV results in rounded up shares,
                // which is unfair to existing share holders. We only do that when there are
                // no shares before.
                require(
                    fundTotalShares == 0,
                    "Cannot create shares for fund with shares but no underlying"
                );
                require(previousNav > 0, "Cannot create shares at zero NAV");
                sharesToMint = creationUnderlying
                    .mul(underlyingPrice)
                    .mul(fund.underlyingDecimalMultiplier())
                    .div(previousNav);
            }
            _historicalCreationRate[day] = sharesToMint.divideDecimal(creationUnderlying);
        }

        // Redemption
        sharesToBurn = currentRedeemingShares;
        if (sharesToBurn > 0) {
            uint256 underlying = sharesToBurn.mul(fundUnderlying).div(fundTotalShares);
            uint256 redemptionFee = underlying.multiplyDecimal(redemptionFeeRate);
            redemptionUnderlying = underlying.sub(redemptionFee);
            _historicalRedemptionRate[day] = redemptionUnderlying.divideDecimal(sharesToBurn);
            fee = redemptionFee;
        }

        // Redeem split and merge fee
        uint256 feeInShares = currentFeeInShares;
        if (feeInShares > 0) {
            sharesToBurn = sharesToBurn.add(feeInShares);
            fee = fee.add(feeInShares.mul(fundUnderlying).div(fundTotalShares));
        }

        // Approve the fund to take underlying if creation is more than redemption.
        // Instead of directly transfering underlying to the fund, this implementation
        // makes testing much easier.
        if (creationUnderlying > redemptionUnderlying) {
            IERC20(fund.tokenUnderlying()).safeApprove(
                address(fund),
                creationUnderlying - redemptionUnderlying
            );
        }

        // This loop should never execute, because this function is called by Fund
        // for every day. We fill the gap just in case that something goes wrong in Fund.
        for (uint256 t = currentDay; t < day; t += 1 days) {
            _historicalCreationRate[t] = _historicalCreationRate[day];
            _historicalRedemptionRate[t] = _historicalRedemptionRate[day];
        }

        currentDay = day + 1 days;
        currentCreatingUnderlying = 0;
        currentRedeemingShares = 0;
        currentFeeInShares = 0;
        emit Settled(
            day,
            sharesToMint,
            sharesToBurn,
            creationUnderlying,
            redemptionUnderlying,
            fee
        );
    }

    function updateGuardedLaunchCap(uint256 newTotalCap, uint256 newIndividualCap)
        external
        onlyOwner
    {
        guardedLaunchTotalCap = newTotalCap;
        guardedLaunchIndividualCap = newIndividualCap;
    }

    function updateRedemptionFeeRate(uint256 newRedemptionFeeRate) external onlyOwner {
        require(newRedemptionFeeRate <= MAX_REDEMPTION_FEE_RATE, "Exceed max redemption fee rate");
        redemptionFeeRate = newRedemptionFeeRate;
    }

    function updateSplitFeeRate(uint256 newSplitFeeRate) external onlyOwner {
        require(newSplitFeeRate <= MAX_SPLIT_FEE_RATE, "Exceed max split fee rate");
        splitFeeRate = newSplitFeeRate;
    }

    function updateMergeFeeRate(uint256 newMergeFeeRate) external onlyOwner {
        require(newMergeFeeRate <= MAX_MERGE_FEE_RATE, "Exceed max merge fee rate");
        mergeFeeRate = newMergeFeeRate;
    }

    function updateMinCreationUnderlying(uint256 newMinCreationUnderlying) external onlyOwner {
        minCreationUnderlying = newMinCreationUnderlying;
    }

    function _currentCreationRedemption(address account)
        private
        view
        returns (CreationRedemption memory cr)
    {
        cr = _creationRedemptions[account];
        uint256 oldDay = cr.day;
        if (oldDay < currentDay) {
            if (cr.creatingUnderlying > 0) {
                cr.createdShares = cr.createdShares.add(
                    cr.creatingUnderlying.multiplyDecimal(_historicalCreationRate[oldDay])
                );
                cr.creatingUnderlying = 0;
            }
            uint256 rebalanceSize = fund.getRebalanceSize();
            if (cr.version < rebalanceSize) {
                if (cr.createdShares > 0) {
                    (cr.createdShares, , ) = fund.batchRebalance(
                        cr.createdShares,
                        0,
                        0,
                        cr.version,
                        rebalanceSize
                    );
                }
                cr.version = rebalanceSize;
            }
            if (cr.redeemingShares > 0) {
                cr.redeemedUnderlying = cr.redeemedUnderlying.add(
                    cr.redeemingShares.multiplyDecimal(_historicalRedemptionRate[oldDay])
                );
                cr.redeemingShares = 0;
            }
            cr.day = currentDay;
        }
    }

    function _updateCreationRedemption(address account, CreationRedemption memory cr) private {
        CreationRedemption storage old = _creationRedemptions[account];
        if (old.day != cr.day) {
            old.day = cr.day;
        }
        if (old.creatingUnderlying != cr.creatingUnderlying) {
            old.creatingUnderlying = cr.creatingUnderlying;
        }
        if (old.redeemingShares != cr.redeemingShares) {
            old.redeemingShares = cr.redeemingShares;
        }
        if (old.createdShares != cr.createdShares) {
            old.createdShares = cr.createdShares;
        }
        if (old.redeemedUnderlying != cr.redeemedUnderlying) {
            old.redeemedUnderlying = cr.redeemedUnderlying;
        }
        if (old.version != cr.version) {
            old.version = cr.version;
        }
    }

    modifier onlyActive() {
        require(fund.isPrimaryMarketActive(address(this), block.timestamp), "Only when active");
        _;
    }

    modifier onlyFund() {
        require(msg.sender == address(fund), "Only fund");
        _;
    }
}