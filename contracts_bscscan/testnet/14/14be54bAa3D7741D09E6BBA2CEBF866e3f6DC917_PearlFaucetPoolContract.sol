/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

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

contract PearlFaucetPoolContract {
    using SafeMath for uint256;

    address public owner;
    IBEP20 public token;

    uint256 public minInvest = 10 ether;
    uint256 public dailyPercent = 10;
    uint256 public maxPercent = 3650;
    uint256[5] public REFERRAL_PERCENTS = [40, 30, 20, 10, 5];
    uint256 public constant percentDivider = 1000;
    uint256 public constant timeStep = 1 minutes;
    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalNumberOfDeposits;

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
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
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

    constructor(address _owner, IBEP20 _token) {
        owner = _owner;
        token = _token;
    }

    function invest(uint256 _tokenAmount, address referrer) public {
        require(_tokenAmount >= minInvest);

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
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    } else if (i == 3) {
                        users[upline].level3 = users[upline].level3.add(1);
                    } else {
                        users[upline].level3 = users[upline].level3.add(1);
                    }

                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 invested = _tokenAmount.mul(REFERRAL_PERCENTS[i]).div(
                        percentDivider
                    );
                    users[upline].activeBonus = users[upline].activeBonus.add(
                        invested
                    );
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

    function withdraw() public {
        User storage user = users[msg.sender];
        require(
            block.timestamp > user.checkpoint + (12 hours),
            "you can only take withdraw once in 12 hours"
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
                    user.deposits[i].invested.mul(maxPercent).div(percentDivider)
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
        user.checkpoint = block.timestamp;
        token.transfer(msg.sender, totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
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
                    user.deposits[i].invested.mul(maxPercent).div(percentDivider)
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
        _downline1 = users[userAddress].level1;
        _downline2 = users[userAddress].level2;
        _downline3 = users[userAddress].level3;
        _downline4 = users[userAddress].level4;
        _downline5 = users[userAddress].level5;
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

    function isActive(address userAddress, uint256 index)
        public
        view
        returns (bool _state)
    {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (
                user.deposits[index].withdrawn <
                user.deposits[index].invested.mul(maxPercent).div(percentDivider)
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

    function getContractTokenBalance() public view returns (uint256 _bnbBalance) {
        _bnbBalance = token.balanceOf(address(this));
    }

    function removeStuckBnb() public {
        payable(owner).transfer(getContractBalance());
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