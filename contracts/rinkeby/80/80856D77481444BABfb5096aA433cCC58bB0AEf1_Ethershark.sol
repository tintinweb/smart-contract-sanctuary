// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Ethershark {
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
    uint8[5] private _DIRECT_REFERRAL_BONUS = [5, 1, 1, 1, 1];
    uint8[5] private _ROI_MATCHING_BONUS = [10, 2, 2, 2, 2];
    uint8[3] private _DAILY_POOL_AWARD_PERCENTAGE = [50, 30, 20];
    uint8 private constant _PASSIVE_ROI_PERCENT = 5;
    uint8 private constant _LEADERBOARD_LENGTH = 3;
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
        require(
            newOwner != address(0x0),
            "Ownable: new owner is the zero address"
        );
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
            msg.value % 100000000000000000 == 0,
            "Amount must be in multiple of 0.1 ETH."
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
        investor.incomeLimitLeft -= amount;
        updateState(amount);

        _safeTransfer(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.directReferralIncome);
    }

    function withdrawROIMatchingIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.roiReferralIncome;

        investor.roiReferralIncome = 0;
        investor.incomeLimitLeft -= amount;
        updateState(amount);

        _safeTransfer(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.ROIMatchingIncome);
    }

    function withdrawTopInvestorIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.topInvestorIncome;

        investor.topInvestorIncome = 0;
        investor.incomeLimitLeft -= amount;
        updateState(amount);

        _safeTransfer(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.topInvestorIncome);
    }

    function withdrawTopSponsorIncome() external {
        Investor storage investor = investors[msg.sender];
        uint256 amount = investor.topSponsorIncome;

        investor.topSponsorIncome = 0;
        investor.incomeLimitLeft -= amount;
        updateState(amount);

        _safeTransfer(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.topSponsorIncome);
    }

    function withdrawSuperIncome(uint256 _amount) external {
        Investor storage investor = investors[msg.sender];
        require(_amount <= investor.superIncome, "Insufficient Income");

        investor.superIncome -= _amount;
        updateState(_amount);

        _safeTransfer(payable(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount, WithdrawTypes.superIncome);
    }

    function withdrawBonuses() external {
        _withdrawBonuses();
    }

    function withdrawAll() external {
        _withdrawROIIncome();
        _withdrawBonuses();
    }

    function rewardSuperBonus(address _investor, uint256 _amount)
        external
        payable
        onlyOwner
    {
        investors[_investor].superIncome += _amount;
    }

    function distributeDailyRewards() external {
        require(
            block.timestamp > _lastDistributionTime + _POOL_TIME,
            "Waith until next round."
        );

        uint256 prize;
        uint256 reward = (_rewardPool * 5) / 200;
        uint256 round = (_lastDistributionTime - _START) / _POOL_TIME;
        uint256 placeInTopInvestors;
        uint256 placeInTopSponsors;
        address[] memory roundInvestors = _roundInvestors[round];
        uint256 length = roundInvestors.length;
        bool isInTopSposorsList;
        Leaderboard[_LEADERBOARD_LENGTH] memory topInvestors;
        Leaderboard[_LEADERBOARD_LENGTH] memory topSponsors;

        for (uint256 i = 0; i < length; i++) {
            Investor memory investor = investors[roundInvestors[i]];
            uint256 directVolume =
                _referrerRoundVolume[round][investor.referrer];
            placeInTopInvestors = 0;
            placeInTopSponsors = 0;
            isInTopSposorsList = false;

            if (directVolume > topSponsors[_LEADERBOARD_LENGTH - 1].amt) {
                for (uint256 j = 0; j < _LEADERBOARD_LENGTH; j++) {
                    if (investor.referrer == topSponsors[j].addr)
                        isInTopSposorsList = true;
                }

                if (!isInTopSposorsList) {
                    if (directVolume <= topSponsors[0].amt) {
                        for (uint256 j = _LEADERBOARD_LENGTH - 1; j > 0; j--) {
                            if (
                                topSponsors[j].amt < directVolume &&
                                directVolume <= topSponsors[j - 1].amt
                            ) placeInTopSponsors = j;
                        }
                    }

                    for (
                        uint256 j = _LEADERBOARD_LENGTH - 1;
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

            if (investor.amount <= topInvestors[_LEADERBOARD_LENGTH - 1].amt) {
                _roundInvestors[round][i] = address(0x0);
            } else {
                if (investor.amount <= topInvestors[0].amt) {
                    for (uint256 j = _LEADERBOARD_LENGTH - 1; j > 0; j--) {
                        if (
                            topInvestors[j].amt < investor.amount &&
                            investor.amount <= topInvestors[j - 1].amt
                        ) placeInTopInvestors = j;
                    }
                }

                for (
                    uint256 j = _LEADERBOARD_LENGTH - 1;
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

        for (uint256 index = 0; index < _LEADERBOARD_LENGTH; index++) {
            prize = (reward * _DAILY_POOL_AWARD_PERCENTAGE[index]) / 100;
            investors[topInvestors[index].addr].topInvestorIncome += prize;
            investors[topSponsors[index].addr].topSponsorIncome += prize;
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

        _rewardPool -= reward * 2;
        _lastDistributionTime += _POOL_TIME;
    }

    function owner() public view returns (address) {
        return _owner;
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

    function updateState(uint256 _amount) internal {
        _totalWithdrawn += _amount;
        _rewardPool += (_amount * 5) / 100;
    }

    function _calculateDailyROI(address _investor)
        private
        view
        returns (uint256 income)
    {
        income = ((block.timestamp - investors[_investor].lastSettledTime) / _PASSIVE_ROI_INTERVAL) * investors[_investor].amount * _PASSIVE_ROI_PERCENT / _DIVIDER / 1440;

        if (investors[_investor].incomeLimitLeft < income) {
            income = investors[_investor].incomeLimitLeft;
        }
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
        investor.incomeLimitLeft = (investor.amount * _MAX_ROI) / 100;

        emit Investment(owner_, owner_, 0, investor.amount);
    }

    function _getCurrentRound() private view returns (uint256 round) {
        round = (block.timestamp - _START) / _POOL_TIME;
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
            investor.superIncome += (_amount * 5) / 200;
            investors[investor.referrer].superIncome += (_amount * 5) / 200;
        }

        investor.lastSettledTime = block.timestamp;
        investor.amount = _amount;
        investor.incomeLimitLeft = (_amount * _MAX_ROI) / 100;
        _roundInvestors[_round].push(_investor);
        _referrerRoundVolume[_round][investor.referrer] += _amount;

        _setDirectReferralCommissions(_investor, _amount, 0, investor.referrer);

        _totalInvested += _amount;
        _rewardPool += (_amount * 5) / 100;

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
        if (referrer == _owner || index == 5) {
            return;
        }

        if (investors[referrer].directPartners > index) {
            investors[referrer].directReferralIncome +=
                (_amount * _DIRECT_REFERRAL_BONUS[index]) /
                100;
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

        while (referrer != _owner && index != 5) {
            investors[referrer].roiReferralIncome +=
                (_amount * _ROI_MATCHING_BONUS[index]) /
                100;

            index++;
            referrer = investors[referrer].referrer;
        }
    }

    function _withdrawROIIncome() private {
        uint256 amount = _calculateDailyROI(msg.sender);

        Investor storage investor = investors[msg.sender];

        investor.lastSettledTime =
            block.timestamp -
            ((block.timestamp - investor.lastSettledTime) %
                _PASSIVE_ROI_INTERVAL);
        investor.incomeLimitLeft -= amount;
        updateState(amount);

        _setROIMatchingBonus(msg.sender, amount);

        _safeTransfer(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.ROIIncome);
    }

    function _withdrawBonuses() private {
        Investor storage investor = investors[msg.sender];
        uint256 amount =
            investor.directReferralIncome +
                investor.roiReferralIncome +
                investor.topInvestorIncome +
                investor.topSponsorIncome;

        investor.directReferralIncome = 0;
        investor.roiReferralIncome = 0;
        investor.topInvestorIncome = 0;
        investor.topSponsorIncome = 0;
        if (investor.incomeLimitLeft < amount) {
            amount = investor.incomeLimitLeft;
        }
        investor.incomeLimitLeft -= amount;
        investor.superIncome = 0;
        amount += investor.superIncome;
        updateState(amount);

        _safeTransfer(payable(msg.sender), amount);
        emit Withdraw(msg.sender, amount, WithdrawTypes.allBonuses);
    }
}