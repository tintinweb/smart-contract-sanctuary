// SPDX-License-Identifier: WISE

pragma solidity ^0.8.9;

import "./LiquidHelper.sol";
import "./LiquidTransfer.sol";

contract LiquidLocker is LiquidTransfer, LiquidHelper {

    modifier onlyLockerOwner() {
        require(
           msg.sender == globals.lockerOwner,
           'LiquidLocker: INVALID_OWNER'
        );
        _;
    }

    modifier onlyFromFactory() {
        require(
            msg.sender == FACTORY_ADDRESS,
            'LiquidLocker: INVALID_ADDRESS'
        );
        _;
    }

    modifier onlyDuringContributionPhase() {
        require(
            contributionPhase() == true &&
            paymentTimeNotSet() == true,
            'LiquidLocker: NOT_CONTRIBUTION_PHASE'
        );
        _;
    }

    event SingleProvider(
        address indexed singleProvider
    );

    event PaymentMade(
        uint256 paymentAmount
    );

    /**
     * @dev This is a call made by the constructor to set up variables on a new locker.
     * This is essentially equivalent to a constructor, but for our gas saving cloning operation instead.
     * This may also be used in locker-reuse in version 2.
     */
    function initialize(
        uint256[] calldata _tokenId,
        address _tokenAddress,
        address _tokenOwner,
        uint256 _floorAsked,
        uint256 _totalAsked,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        external
        onlyFromFactory
    {
        globals = Globals({
            tokenId: _tokenId,
            lockerOwner: _tokenOwner,
            tokenAddress: _tokenAddress,
            paymentTime: _paymentTime,
            paymentRate: _paymentRate
        });

        floorAsked = _floorAsked;
        totalAsked = _totalAsked;

        if (creationTime > 0) {
            _resetValues();
        }

        creationTime = block.timestamp;
    }

    /**
     * @dev Reset balance variables. Used for locker re-use.
     */
    function _resetValues()
        internal
    {
        claimableBalance = 0;
        remainingBalance = 0;
        penaltiesBalance = 0;
    }

    /**
     * @dev During the contribution phase, the owner can increase the rate they will pay for the loan.
     * The owner can only increase the rate to make the deal better for contributors, he cannot decrease it.
     */
    function increasePaymentRate(
        uint256 _newPaymntRate
    )
        external
        onlyLockerOwner
        onlyDuringContributionPhase
    {
        require(
            _newPaymntRate > globals.paymentRate,
            'LiquidLocker: INVALID_INCREASE'
        );

        globals.paymentRate = _newPaymntRate;
    }

    /**
     * @dev During the contribution phase, the owner can decrease the duration of the loan.
     * The owner can only decrease the loan to a shorter duration, he cannot make it longer once the
     * contribution phase has started.
     */
    function decreasePaymentTime(
        uint256 _newPaymentTime
    )
        external
        onlyLockerOwner
        onlyDuringContributionPhase
    {
        require(
            _newPaymentTime < globals.paymentTime,
            'LiquidLocker: INVALID_DECREASE'
        );

        globals.paymentTime = _newPaymentTime;
    }

    /**
     * @dev Public users can add tokens to the pool to be used for the loan.
     * The contributions for each user along with the total are recorded for splitting funds later.
     * If a user contributes up to the maximum asked on a loan, they will become the sole provider
     * (See _usersIncrease and _reachedTotal for functionality on becoming the sole provider)
     * The sole provider will receive the token instead of the trusted multisig in the case if a liquidation.
     */
    function makeContribution(
        uint256 _tokenAmount,
        address _tokenHolder
    )
        external
        onlyFromFactory
        onlyDuringContributionPhase
        returns (
            uint256 totalIncrease,
            uint256 usersIncrease
        )
    {
        totalIncrease = _totalIncrease(
            _tokenAmount
        );

        usersIncrease = _usersIncrease(
            _tokenHolder,
            _tokenAmount,
            totalIncrease
        );

        _increaseContributions(
            _tokenHolder,
            usersIncrease
        );

        _increaseTotalCollected(
            totalIncrease
        );
    }

    /**
     * @dev Check if this contribution adds enough for the user to become the sole contributor.
     * Make them the sole contributor if so, otherwise return the totalAmount
     */
    function _usersIncrease(
        address _tokenHolder,
        uint256 _tokenAmount,
        uint256 _totalAmount
    )
        internal
        returns (uint256)
    {
        return reachedTotal(_tokenHolder, _tokenAmount)
            ? _reachedTotal(_tokenHolder)
            : _totalAmount;
    }

    /**
     * @dev Calculate whether a contribution go over the maximum asked.
     * If so only allow it to go up to the totalAsked an not over
     */
    function _totalIncrease(
        uint256 _tokenAmount
    )
        internal
        view
        returns (uint256 totalIncrease)
    {
        totalIncrease = totalCollected
            + _tokenAmount < totalAsked
            ? _tokenAmount : totalAsked - totalCollected;
    }

    /**
     * @dev Make the user the singleProvider.
     * Making the user the singleProvider allows all other contributors to claim their funds back.
     * Essentially if you contribute the whole maximum asked on your own you will kick everyone else out
     */
    function _reachedTotal(
        address _tokenHolder
    )
        internal
        returns (uint256 totalReach)
    {
        require(
            singleProvider == ZERO_ADDRESS,
            'LiquidLocker: PROVIDER_EXISTS'
        );

        totalReach =
        totalAsked - contributions[_tokenHolder];

        singleProvider = _tokenHolder;

        emit SingleProvider(
            _tokenHolder
        );
    }

    /**
     * @dev Locker owner calls this once the contribution phase is over to receive the funds for the loan.
     * This can only be done once the floor is reached, and can be done before the end of the contribution phase
     * if the floor is reached early. The owner can also prepay an amount to pay off some of the earnings at enable time.
     * The locker owner owes the earnings linearly until the end, then all of the actual loan plus any penalties are due at the end.
     */
    function enableLocker(
        uint256 _prepayAmount
    )
        external
        onlyLockerOwner
    {
        require(
            belowFloorAsked() == false,
            'LiquidLocker: BELOW_FLOOR'
        );

        require(
            paymentTimeNotSet() == true,
            'LiquidLocker: ENABLED_LOCKER'
        );

        (
            uint256 totalPayback,
            uint256 epochPayback,
            uint256 teamsPayback

        ) = calculatePaybacks(
            totalCollected,
            globals.paymentTime,
            globals.paymentRate
        );

        claimableBalance = claimableBalance
            + _prepayAmount;

        remainingBalance = totalPayback
            - _prepayAmount;

        _safeTransfer(
            PAYMENT_TOKEN,
            globals.lockerOwner,
            totalCollected - _prepayAmount - teamsPayback
        );

        _safeTransfer(
            PAYMENT_TOKEN,
            TRUSTEE_MULTISIG,
            teamsPayback
        );

        nextDueTime = startingTimestamp()
            + _prepayAmount
            / epochPayback;

        emit PaymentMade(
            _prepayAmount
        );
    }

    /**
     * @dev If the floor asked was not reached during contributions, this function will return the nft to the owner
     * and allow all the contributors to claim their funds back.
     */
    function disableLocker()
        external
        onlyLockerOwner
    {
        require(
            belowFloorAsked() == true,
            'LiquidLocker: FLOOR_REACHED'
        );

        _disableLocker();
    }

    /**
     * @dev Internal function that does the work for disableLocker.
     * Once a locker is ownerless contributors are allowed to claim,
     * the owner being set to the zero address is the condition that enables that.
     */
    function _disableLocker()
        internal
    {
        _returnToken();
        _revokeOwner();
    }

    /**
     * @dev There are a couple edge cases with extreme payment rates that cause enableLocker to revert.
     * These are never callable on our UI and doing so would require a manual transaction.
     * This function will disable a locker in this senario, allow contributors to claim their money and transfer the NFT back to the owner.
     * Only the team multisig has permission to do this
     */
    function rescueLocker()
        external
    {
        require(
            msg.sender == TRUSTEE_MULTISIG,
            'LiquidLocker: INVALID_TRUSTEE'
        );

        require(
            timeSince(creationTime) > DEADLINE_TIME,
            'LiquidLocker: NOT_ENOUGHT_TIME'
        );

        require(
            paymentTimeNotSet() == true,
           'LiquidLocker: ALREADY_STARTED'
        );

        _disableLocker();
    }

    /**
     * @dev Allow users to claim funds when a locker is disabled
     */
    function refundDueDisabled(
        address _refundAddress
    )
        external
    {
        require(
            ownerlessLocker() == true ||
            floorNotReached() == true,
            "LiquidLocker: ENABLED_LOCKER"
        );

        uint256 tokenAmount = contributions[_refundAddress];

        _refundTokens(
            tokenAmount,
            _refundAddress
        );

        _decreaseTotalCollected(
            tokenAmount
        );
    }

    /**
     * @dev Allow users to claim funds when a someone kicks them out to become the single provider
     */
    function refundDueSingle(
        address _refundAddress
    )
        external
    {
        require(
            notSingleProvider(_refundAddress) == true,
            'LiquidLocker: INVALID_SENDER'
        );

        _refundTokens(
            contributions[_refundAddress],
            _refundAddress
        );
    }

    /**
     * @dev Someone can add funds to the locker and they will be split among the contributors
     * This does not count as a payment on the loan.
     */
    function donateFunds(
        uint256 _donationAmount
    )
        external
        onlyFromFactory
    {
        unchecked {
            claimableBalance =
            claimableBalance + _donationAmount;
        }
    }

    /**
     * @dev Locker owner can payback funds.
     * Penalties are given if the owner does not pay the earnings linearally over the loan duration.
     * If the owner pays back the earnings, loan amount, and penalties aka fully pays off the loan
     * they will be transfered their nft back
     */
    function payBackFunds(
        uint256 _paymentAmount
    )
        external
        onlyFromFactory
    {
        require(
            missedDeadline() == false,
            'LiquidLocker: TOO_LATE'
        );

        _adjustBalances(
            _paymentAmount,
            _penaltyAmount()
        );

        if (remainingBalance == 0) {

            _disableLocker();
            _revokeDueTime();
            _splitPenalties();

            return;
        }

        uint256 payedTimestamp = nextDueTime;
        uint256 finalTimestamp = paybackTimestamp();

        if (payedTimestamp == finalTimestamp) return;

        uint256 purchasedTime = _paymentAmount
            / calculateEpoch(
                totalCollected,
                globals.paymentTime,
                globals.paymentRate
            );

        require(
            purchasedTime >= SECONDS_IN_DAY,
            "LiquidLocker: Minimum Payoff"
        );

        payedTimestamp = payedTimestamp > block.timestamp
            ? _add(payedTimestamp, purchasedTime)
            : _add(block.timestamp, purchasedTime);

        nextDueTime = payedTimestamp < finalTimestamp
            ? payedTimestamp
            : finalTimestamp;

        emit PaymentMade(
            _paymentAmount
        );
    }

    /**
     * @dev If the owner has missed payments by 7 days this call will transfer the NFT to either the
     * singleProvider address or the trusted multisig to be auctioned
     */
    function liquidateLocker()
        external
    {
        require(
            missedActivate() == true ||
            missedDeadline() == true,
            'LiquidLocker: TOO_EARLY'
        );

        for (uint256 i = 0; i < globals.tokenId.length; i++) {
            _transferNFT(
                address(this),
                liquidateTo(),
                globals.tokenAddress,
                globals.tokenId[i]
            );
        }

        _revokeDueTime();
        _claimPenalties();
    }

    /**
     * @dev Public pure accessor for _getPenaltyAmount
     */
    function penaltyAmount(
        uint256 _totalCollected,
        uint256 _lateDaysAmount
    )
        external
        pure
        returns (uint256)
    {
        return _getPenaltyAmount(
            _totalCollected,
            _lateDaysAmount
        );
    }

    /**
     * @dev calculate how much in penalties the owner has due to late time since last payment
     */
    function _penaltyAmount()
        internal
        view
        returns (uint256)
    {
        return _getPenaltyAmount(
            totalCollected,
            getLateDays()
        );
    }

    /**
     * @dev Calculate penalties. .5% for first 4 days and 1% for each day after the 4th
     */
    function _getPenaltyAmount(
        uint256 _totalCollected,
        uint256 _lateDaysAmount
    )
        private
        pure
        returns (uint256 penalty)
    {
        unchecked {
            penalty = _totalCollected
                * _daysBase(_lateDaysAmount)
                / 200;
        }
    }

    /**
     * @dev Helper for the days math of calcualte penalties.
     * Returns +1 per day before the 4th day and +2 for each day after the 4th day
     */
    function _daysBase(
        uint256 _daysAmount
    )
        internal
        pure
        returns (uint256 res)
    {
        unchecked {
            res = _daysAmount > 4
                ? _daysAmount * 2 - 4
                : _daysAmount;
        }
    }

    /**
     * @dev Helper for the days math of calcualte penalties.
     * Returns +1 per day before the 4th day and +2 for each day after the 4th day
     */
    function getLateDays()
        public
        view
        returns (uint256 late)
    {
        unchecked {
            late = block.timestamp > nextDueTime
                ? (block.timestamp - nextDueTime) / SECONDS_IN_DAY : 0;
        }
    }

    /**
     * @dev Calulate how much the usage fee takes off a payments,
     * and how many tokens are due per second of loan
     * (epochPayback is amount of tokens to extend loan by 1 second. Only need to pay off earnings)
     */
    function calculatePaybacks(
        uint256 _totalValue,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        public
        pure
        returns (
            uint256 totalPayback,
            uint256 epochPayback,
            uint256 teamsPayback
        )
    {
        unchecked {
            totalPayback = (_paymentRate + 100) * _totalValue / 100;
            teamsPayback = (totalPayback - _totalValue) * FEE / 100;
            epochPayback = (totalPayback - _totalValue) / _paymentTime;
        }
    }

    /**
     * @dev Calculate how many sends should be added before the next payoff is due based on payment amount
     */
    function calculateEpoch(
        uint256 _totalValue,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        public
        pure
        returns (uint256 result)
    {
        unchecked {
            result = _totalValue
                * _paymentRate
                / 100
                / _paymentTime;
        }
    }

    /**
     * @dev Claim payed back tokens as a single contributor
     */
    function claimInterestSingle()
        external
    {
        require(
            singleProvider == msg.sender,
            'LiquidLocker: NOT_SINGLE_PROVIDER'
        );

        _claimInterest(
            msg.sender
        );
    }

    /**
     * @dev Claim payed back tokens as with multiple contributors.
     * We need 2 functions because we cannot wipe all the contributions of users before someone became the sole contributor
     */
    function claimInterestPublic()
        external
    {
        require(
            singleProvider == ZERO_ADDRESS,
            'LiquidLocker: SINGLE_PROVIDER_EXISTS'
        );

        _claimInterest(
            msg.sender
        );
    }

    /**
     * @dev Does the internal work of claiming payed back tokens.
     * Amount to claimed is based on share of contributions, and we record what someone has claimed in the
     * compensations mapping
     */
    function _claimInterest(
        address _claimAddress
    )
        internal
    {
        uint256 claimAmount = claimableBalance
            * contributions[_claimAddress]
            / totalCollected;

        _safeTransfer(
            PAYMENT_TOKEN,
            _claimAddress,
            claimAmount - compensations[_claimAddress]
        );

        compensations[_claimAddress] = claimAmount;
    }

    /**
     * @dev Team claims all penalties on liquidation
     */
    function _claimPenalties()
        internal
    {
        if (penaltiesBalance > claimableBalance) return;

        _safeTransfer(
            PAYMENT_TOKEN,
            TRUSTEE_MULTISIG,
            penaltiesBalance
        );

        claimableBalance =
        claimableBalance - penaltiesBalance;

        penaltiesBalance = 0;
    }

    /**
     * @dev Distributes penalties between team and contributors based on team fee ratio.
     * This happens on payoff, while _claimPenalties happens on liquidation
     * Team takes all penalties on liquidation, and 20% on normal pay off
     */
    function _splitPenalties()
        internal
    {
        uint256 teamBalance = penaltiesBalance
            * FEE
            / 100;

        if (teamBalance > claimableBalance) return;

        _safeTransfer(
            PAYMENT_TOKEN,
            TRUSTEE_MULTISIG,
            teamBalance
        );

        claimableBalance =
        claimableBalance - teamBalance;

        penaltiesBalance = 0;
    }

    /**
     * @dev Helper function to add payment tokens and penalty tokens to their internal variables
     * Also calculates remainingBalance due for the owner.
     */
    function _adjustBalances(
        uint256 _paymentTokens,
        uint256 _penaltyTokens
    )
        internal
    {
        claimableBalance += _paymentTokens;
        penaltiesBalance += _penaltyTokens;

        remainingBalance = remainingBalance
            + _penaltyTokens
            - _paymentTokens;
    }

    /**
     * @dev Transfers the NFT or NFTs used for the loan back to the owner
     */
    function _returnToken()
        internal
    {
        for (uint256 i = 0; i < globals.tokenId.length; i++) {
            _transferNFT(
                address(this),
                globals.lockerOwner,
                globals.tokenAddress,
                globals.tokenId[i]
            );
        }
    }

    /**
     * @dev Does the internal reset and transfer for refunding tokens on either condition that refunds are issued
     */
    function _refundTokens(
        uint256 _refundAmount,
        address _refundAddress
    )
        internal
    {
        contributions[_refundAddress] = 0;

        _safeTransfer(
            PAYMENT_TOKEN,
            _refundAddress,
            _refundAmount
        );
    }
}