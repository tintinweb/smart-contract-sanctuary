/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

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

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

contract KRYPTstake {
    using SafeMath for uint256;
    IERC20 public stakeToken;

    address payable public owner;

    uint256 public totalStakedToken;
    uint256 public totalUnStakedToken;
    uint256 public totalWithdrawanToken;
    uint256 public totalClaimedRewardToken;
    uint256 public totalStakers;
    uint256 public unstakePercentage;
    uint256 public unstakeDeductionPercentage;
    uint256 public percentDivider;
    uint256 public minimumStakeToken;

    uint256[4] public Duration = [30 days, 60 days, 90 days, 180 days];
    uint256[4] public Bonus = [25, 83, 150, 400];

    struct Stake {
        uint256 withdrawtime;
        uint256 staketime;
        uint256 amount;
        uint256 reward;
        uint256 persecondreward;
        bool withdrawan;
        bool unstaked;
    }

    struct User {
        uint256 totalStakedTokenUser;
        uint256 totalWithdrawanTokenUser;
        uint256 totalUnStakedTokenUser;
        uint256 totalClaimedRewardTokenUser;
        uint256 stakeCount;
        bool alreadyExists;
    }

    mapping(address => User) public Stakers;
    mapping(uint256 => address) public StakersID;
    mapping(address => mapping(uint256 => Stake)) public stakersRecord;

    event STAKE(address Staker, uint256 amount);
    event UNSTAKE(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);

    modifier onlyowner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    constructor(address payable _owner, address token) {
        owner = _owner;
        stakeToken = IERC20(token);
        unstakePercentage = 980;
        unstakeDeductionPercentage = 20;
        percentDivider = 1000;
        minimumStakeToken = 10000e9;
    }

    function stake(uint256 amount, uint256 timeperiod) public {
        require(timeperiod >= 0 && timeperiod <= 3, "Invalid Time Period");
        require(amount >= minimumStakeToken, "stake more than minimum amount");

        if (!Stakers[msg.sender].alreadyExists) {
            Stakers[msg.sender].alreadyExists = true;
            StakersID[totalStakers] = msg.sender;
            totalStakers++;
        }

        stakeToken.transferFrom(msg.sender, address(this), amount);

        uint256 index = Stakers[msg.sender].stakeCount;
        Stakers[msg.sender].totalStakedTokenUser = Stakers[msg.sender]
            .totalStakedTokenUser
            .add(amount);
        totalStakedToken = totalStakedToken.add(amount);
        stakersRecord[msg.sender][index].withdrawtime = block.timestamp.add(
            Duration[timeperiod]
        );
        stakersRecord[msg.sender][index].staketime = block.timestamp;
        stakersRecord[msg.sender][index].amount = amount;
        stakersRecord[msg.sender][index].reward = amount
            .mul(Bonus[timeperiod])
            .div(percentDivider);
        stakersRecord[msg.sender][index].persecondreward = stakersRecord[
            msg.sender
        ][index].reward.div(Duration[timeperiod]);
        Stakers[msg.sender].stakeCount++;

        emit STAKE(msg.sender, amount);
    }

    function unstake(uint256 index) public {
        require(
            !stakersRecord[msg.sender][index].withdrawan,
            "already withdrawan"
        );
        require(!stakersRecord[msg.sender][index].unstaked, "already unstaked");
        require(
            stakersRecord[msg.sender][index].withdrawtime > block.timestamp,
            "cannot unstake after stake duration"
        );

        stakersRecord[msg.sender][index].unstaked = true;
        stakeToken.transfer(
            msg.sender,
            (stakersRecord[msg.sender][index].amount)
                .mul(unstakePercentage)
                .div(percentDivider)
        );
        stakeToken.transfer(
            owner,
            (stakersRecord[msg.sender][index].amount)
                .mul(unstakeDeductionPercentage)
                .div(percentDivider)
        );
        totalUnStakedToken = totalUnStakedToken.add(
            stakersRecord[msg.sender][index].amount
        );
        Stakers[msg.sender].totalUnStakedTokenUser = Stakers[msg.sender]
            .totalUnStakedTokenUser
            .add(stakersRecord[msg.sender][index].amount);

        emit UNSTAKE(
            msg.sender,
            stakersRecord[msg.sender][index].amount.mul(unstakePercentage).div(
                percentDivider
            )
        );
    }

    function withdraw(uint256 index) public {
        require(
            !stakersRecord[msg.sender][index].withdrawan,
            "already withdrawan"
        );
        require(!stakersRecord[msg.sender][index].unstaked, "already unstaked");
        require(
            stakersRecord[msg.sender][index].withdrawtime < block.timestamp,
            "cannot withdraw before stake duration"
        );

        stakersRecord[msg.sender][index].withdrawan = true;
        stakeToken.transfer(
            msg.sender,
            stakersRecord[msg.sender][index].amount
        );
        stakeToken.transferFrom(
            owner,
            msg.sender,
            stakersRecord[msg.sender][index].reward
        );
        totalWithdrawanToken = totalWithdrawanToken.add(
            stakersRecord[msg.sender][index].amount
        );
        totalClaimedRewardToken = totalClaimedRewardToken.add(
            stakersRecord[msg.sender][index].reward
        );
        Stakers[msg.sender].totalWithdrawanTokenUser = Stakers[msg.sender]
            .totalWithdrawanTokenUser
            .add(stakersRecord[msg.sender][index].amount);
        Stakers[msg.sender].totalClaimedRewardTokenUser = Stakers[msg.sender]
            .totalClaimedRewardTokenUser
            .add(stakersRecord[msg.sender][index].reward);

        emit WITHDRAW(
            msg.sender,
            stakersRecord[msg.sender][index].reward.add(
                stakersRecord[msg.sender][index].amount
            )
        );
    }

    function SetUnStakePercentages(
        uint256 _unstakePercent,
        uint256 _deductionPercent
    ) external onlyowner {
        unstakePercentage = _unstakePercent;
        unstakeDeductionPercentage = _deductionPercent;
    }

    function SetStakeLimits(uint256 _min) external onlyowner {
        minimumStakeToken = _min;
    }

    function SetStakeDuration(
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    ) external onlyowner {
        Duration[0] = first;
        Duration[1] = second;
        Duration[2] = third;
        Duration[3] = fourth;
    }

    function changeOwnership(address payable _owner)
        public
        onlyowner
        returns (bool)
    {
        owner = _owner;

        return true;
    }

    function SetStakeBonus(
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    ) external onlyowner {
        Bonus[0] = first;
        Bonus[1] = second;
        Bonus[2] = third;
        Bonus[3] = fourth;
    }

    function realtimeReward(address user) public view returns (uint256) {
        uint256 ret;
        for (uint256 i; i < Stakers[user].stakeCount; i++) {
            if (
                !stakersRecord[user][i].withdrawan &&
                !stakersRecord[user][i].unstaked
            ) {
                uint256 val;
                val = block.timestamp - stakersRecord[user][i].staketime;
                val = val.mul(stakersRecord[user][i].persecondreward);
                if (val < stakersRecord[user][i].reward) {
                    ret += val;
                } else {
                    ret += stakersRecord[user][i].reward;
                }
            }
        }
        return ret;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}