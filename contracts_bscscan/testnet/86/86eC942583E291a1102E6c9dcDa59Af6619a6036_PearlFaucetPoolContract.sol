pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 invested)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 invested) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 invested
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PearlFaucetPoolContract {
    using SafeMath for uint256;
     AggregatorV3Interface public priceFeedbnb;


    address public owner;
    IBEP20 public token;

    uint256 public minInvest = 10 ether;
    uint256 public dailyPercent = 10;
    uint256 public maxPercent = 3650;
    uint256[5] public limits = [10e18, 1000e18, 5000e18, 10000e18, 25000e18];
    uint256[5] public akoyaPercent = [100, 0, 0, 0, 0];
    uint256[5] public freshWaterPercent = [100, 100, 0, 0, 0];
    uint256[5] public tahitainPercent = [100, 100, 70, 0, 0];
    uint256[5] public baroquePercent = [120, 100, 70, 50, 0];
    uint256[5] public southSeaPercent = [120, 100, 70, 50, 30];

    uint256 public constant percentDivider = 1000;
    uint256 public timeStep = 1 days;
    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalNumberOfDeposits;
    uint256 public totalReinvested;

    struct Deposit {
        uint256 invested;
        uint256 withdrawn;
        uint256 startTime;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 activeBonus;
        uint256 withdrawnBonus;
        uint256 reinvested;
        uint256[5] downline;
        uint256[5] downlineIncome;
    }

    mapping(address => User) public users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 invested);
    event Withdrawn(address indexed user, uint256 invested);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 invested
    );
    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner, IBEP20 _token
    ) {
        owner = _owner;
        token = IBEP20(_token);
        priceFeedbnb = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
    }

    function invest(uint256 _tokenAmount, address referrer) public {
        require(_tokenAmount >= minInvest,"amount is less than min amount");

        token.transferFrom(msg.sender, address(this), _tokenAmount);

        User storage user = users[msg.sender];

        if (msg.sender == owner) {
            user.referrer = address(0);
        } else if (user.referrer == address(0)) {
            if (
                (users[referrer].deposits.length == 0 ||
                    referrer == msg.sender) || referrer == address(0)
            ) {
                referrer = owner;
            }

            user.referrer = referrer;

            address upline = user.referrer;
            for (uint256 i = 0; i < akoyaPercent.length; i++) {
                if (upline != address(0)) {
                    users[upline].downline[i]++;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < akoyaPercent.length; i++) {
                if (upline != address(0)) {
                    uint256 invested = 0;
                    if (
                        getUserAmountOfDeposit(upline) >= limits[0] &&
                        getUserAmountOfDeposit(upline) < limits[1]
                    ) {
                        invested = _tokenAmount.mul(akoyaPercent[i]).div(
                            percentDivider
                        );
                        users[upline].activeBonus = users[upline]
                            .activeBonus
                            .add(invested);
                    } else if (
                        getUserAmountOfDeposit(upline) >= limits[1] &&
                        getUserAmountOfDeposit(upline) < limits[2]
                    ) {
                        invested = _tokenAmount.mul(freshWaterPercent[i]).div(
                            percentDivider
                        );
                        users[upline].activeBonus = users[upline]
                            .activeBonus
                            .add(invested);
                    } else if (
                        getUserAmountOfDeposit(upline) >= limits[2] &&
                        getUserAmountOfDeposit(upline) < limits[3]
                    ) {
                        invested = _tokenAmount.mul(tahitainPercent[i]).div(
                            percentDivider
                        );
                        users[upline].activeBonus = users[upline]
                            .activeBonus
                            .add(invested);
                    } else if (
                        getUserAmountOfDeposit(upline) >= limits[3] &&
                        getUserAmountOfDeposit(upline) < limits[4]
                    ) {
                        invested = _tokenAmount.mul(baroquePercent[i]).div(
                            percentDivider
                        );
                        users[upline].activeBonus = users[upline]
                            .activeBonus
                            .add(invested);
                    } else if (getUserAmountOfDeposit(upline) > limits[4]) {
                        invested = _tokenAmount.mul(southSeaPercent[i]).div(
                            percentDivider
                        );
                        users[upline].activeBonus = users[upline]
                            .activeBonus
                            .add(invested);
                    }
                    users[upline].downlineIncome[i] = users[upline]
                        .downlineIncome[i]
                        .add(invested);

                    emit RefBonus(upline, msg.sender, i, invested);

                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            totalUsers = totalUsers.add(1);
        }
        user.deposits.push(Deposit(_tokenAmount, 0, block.timestamp));
        totalInvested = totalInvested.add(_tokenAmount);
        totalNumberOfDeposits = totalNumberOfDeposits.add(1);

        emit NewDeposit(msg.sender, _tokenAmount);
    }
     // to get real time price of bnb
    function getLatestPricebnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedbnb.latestRoundData();
        return uint256(price).div(1e8);
    }


    function withdraw() public {
        User storage user = users[msg.sender];
        require(
            block.timestamp > user.checkpoint + (timeStep),
            "you can only take withdraw once in 24 hours"
        );

        uint256 base = dailyPercent;
        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].withdrawn <
                user.deposits[i].invested.mul(maxPercent).div(percentDivider)
            ) {
                dividends = (
                    user.deposits[i].invested.mul(base).div(percentDivider)
                ).mul(block.timestamp.sub(user.deposits[i].startTime)).div(
                        timeStep
                    );
                user.deposits[i].startTime = block.timestamp;
                if (
                    user.deposits[i].withdrawn.add(dividends) >
                    user.deposits[i].invested.mul(maxPercent).div(
                        percentDivider
                    )
                ) {
                    dividends = (
                        user.deposits[i].invested.mul(maxPercent).div(
                            percentDivider
                        )
                    ).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(
                    dividends
                ); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }
        uint256 referralBonus = getUserActiveReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            users[msg.sender].withdrawnBonus = users[msg.sender]
                .withdrawnBonus
                .add(referralBonus);
            users[msg.sender].activeBonus = 0;
        }

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        user.checkpoint = block.timestamp;
        token.transfer(msg.sender, totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function reinvest(uint256 _value) internal {
        uint256 referralBonus = getUserActiveReferralBonus(msg.sender);
        if (referralBonus > 0) {
            _value = _value.add(referralBonus);
            users[msg.sender].withdrawnBonus = users[msg.sender]
                .withdrawnBonus
                .add(referralBonus);
            users[msg.sender].activeBonus = 0;
        }

        User storage user = users[msg.sender];
        user.deposits.push(Deposit(_value, 0, block.timestamp));
        user.reinvested = user.reinvested.add(_value);
        totalInvested = totalInvested.add(_value);
        totalNumberOfDeposits = totalNumberOfDeposits.add(1);
        totalReinvested = totalReinvested.add(_value);
        emit NewDeposit(msg.sender, _value);
    }

    function reinvestStake() public returns (bool) {
        User storage user = users[msg.sender];
        uint256 base = dailyPercent;
        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].withdrawn <
                user.deposits[i].invested.mul(maxPercent).div(100)
            ) {
                dividends = (
                    user.deposits[i].invested.mul(base).div(percentDivider)
                ).mul(block.timestamp.sub(user.deposits[i].startTime)).div(
                        timeStep
                    );

                user.deposits[i].startTime = block.timestamp;

                if (
                    user.deposits[i].withdrawn.add(dividends) >
                    user.deposits[i].invested.mul(maxPercent).div(
                        percentDivider
                    )
                ) {
                    dividends = (
                        user.deposits[i].invested.mul(maxPercent).div(
                            percentDivider
                        )
                    ).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(
                    dividends
                ); /// changing of storage data
                totalAmount = totalAmount.add(dividends);
            }
        }

        uint256 contractBalance = address(this).balance;

        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        reinvest(totalAmount);

        return true;
    }

    function getUserDividendsWithdrawable(address userAddress)
        public
        view
        returns (uint256 _totalDividends)
    {
        User storage user = users[userAddress];
        uint256 base = dailyPercent;
        uint256 dividends;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].withdrawn <
                user.deposits[i].invested.mul(maxPercent).div(percentDivider)
            ) {
                dividends = (
                    user.deposits[i].invested.mul(base).div(percentDivider)
                ).mul(block.timestamp.sub(user.deposits[i].startTime)).div(
                        timeStep
                    );
                if (
                    user.deposits[i].withdrawn.add(dividends) >
                    user.deposits[i].invested.mul(maxPercent).div(
                        percentDivider
                    )
                ) {
                    dividends = (
                        user.deposits[i].invested.mul(maxPercent).div(
                            percentDivider
                        )
                    ).sub(user.deposits[i].withdrawn);
                }

                _totalDividends = _totalDividends.add(dividends);
            }
        }
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address _referrer)
    {
        _referrer = users[userAddress].referrer;
    }

    function getUserDownlineIncome(address userAddress)
        public
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3,
            uint256 level4,
            uint256 level5
        )
    {
        level1 = users[userAddress].downlineIncome[0];
        level2 = users[userAddress].downlineIncome[1];
        level3 = users[userAddress].downlineIncome[2];
        level4 = users[userAddress].downlineIncome[3];
        level5 = users[userAddress].downlineIncome[4];
    }

    function getUserActiveReferralBonus(address userAddress)
        public
        view
        returns (uint256 _amount)
    {
        _amount = users[userAddress].activeBonus;
    }

    function getUserReferralBonusWithdrawn(address userAddress)
        public
        view
        returns (uint256 _amount)
    {
        _amount = users[userAddress].withdrawnBonus;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _startTime
        )
    {
        User storage user = users[userAddress];

        _invested = user.deposits[index].invested;
        _withdrawn = user.deposits[index].withdrawn;
        _startTime = user.deposits[index].startTime;
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (
            uint256 _downline1,
            uint256 _downline2,
            uint256 _downline3,
            uint256 _downline4,
            uint256 _downline5
        )
    {
        _downline1 = users[userAddress].downline[0];
        _downline2 = users[userAddress].downline[1];
        _downline3 = users[userAddress].downline[2];
        _downline4 = users[userAddress].downline[3];
        _downline5 = users[userAddress].downline[4];
    }

    function getUserNumberOfDeposits(address userAddress)
        public
        view
        returns (uint256 _depositsCount)
    {
        _depositsCount = users[userAddress].deposits.length;
    }

    function getUserAmountOfDeposit(address userAddress)
        public
        view
        returns (uint256 _amount)
    {
        User storage user = users[userAddress];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            _amount = _amount.add(user.deposits[i].invested);
        }
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256 _amount)
    {
        User storage user = users[userAddress];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            _amount = _amount.add(user.deposits[i].withdrawn);
        }
    }

    function getUserTotalReinvested(address userAddress)
        public
        view
        returns (uint256 _amount)
    {
        _amount = users[userAddress].reinvested;
    }

    function isActive(address userAddress, uint256 index)
        public
        view
        returns (bool _state)
    {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (
                user.deposits[index].withdrawn <
                user.deposits[index].invested.mul(maxPercent).div(
                    percentDivider
                )
            ) {
                _state = true;
            } else {
                _state = false;
            }
        }
    }

    function getContractBalance() public view returns (uint256 _tokenBalance) {
        _tokenBalance = address(this).balance;
    }

    function getContractTokenBalance()
        public
        view
        returns (uint256 _bnbBalance)
    {
        _bnbBalance = token.balanceOf(address(this));
    }

    function removeStuckBnb() public {
        payable(owner).transfer(getContractBalance());
    }

    function updateakoyaPercent(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public onlyowner {
        akoyaPercent[0] = a;
        akoyaPercent[1] = b;
        akoyaPercent[2] = c;
        akoyaPercent[3] = d;
        akoyaPercent[4] = e;
    }

    function updateFreshWaterPercent(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public onlyowner {
        freshWaterPercent[0] = a;
        freshWaterPercent[1] = b;
        freshWaterPercent[2] = c;
        freshWaterPercent[3] = d;
        freshWaterPercent[4] = e;
    }

    function updateTahitainPercent(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public onlyowner {
        tahitainPercent[0] = a;
        tahitainPercent[1] = b;
        tahitainPercent[2] = c;
        tahitainPercent[3] = d;
        tahitainPercent[4] = e;
    }

    function updateBaroquePercent(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public onlyowner {
        baroquePercent[0] = a;
        baroquePercent[1] = b;
        baroquePercent[2] = c;
        baroquePercent[3] = d;
        baroquePercent[4] = e;
    }

    function updateSouthSeaPercent(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public onlyowner {
        southSeaPercent[0] = a;
        southSeaPercent[1] = b;
        southSeaPercent[2] = c;
        southSeaPercent[3] = d;
        southSeaPercent[4] = e;
    }

    function updateLimits(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) public onlyowner {
        limits[0] = a;
        limits[1] = b;
        limits[2] = c;
        limits[3] = d;
        limits[4] = e;
    }

    function updateMinInvest(uint256 _amount) public onlyowner {
        minInvest = _amount;
    }

    function updateDailyPercent(uint256 _percent) public onlyowner {
        dailyPercent = _percent;
    }

    function updateMaxPercent(uint256 _percent) public onlyowner {
        maxPercent = _percent;
    }

    function updateOwner(address _owner) public onlyowner {
        owner = _owner;
    }

    function updateToken(IBEP20 _token) public onlyowner {
        token = _token;
    }

    function setTime(uint256 _duration) public onlyowner {
        timeStep = _duration;
    }

    function lastActivity(address _user) public view returns(uint256 _time) {
        uint256 index = users[_user].deposits.length.sub(1);
        _time = users[_user].deposits[index].startTime;
    }

    function updateReferrer(address _newReferrer) public {
        users[msg.sender].referrer = _newReferrer;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}