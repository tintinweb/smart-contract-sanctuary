pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StakeContract {
    using SafeMath for uint256;

    //Variables
    IBEP20 public stakeToken;
    IBEP20 public rewardToken;
    IBEP20 public unstakeToken;
    address payable public owner;
    uint256 public totalUniqueStakers;
    uint256 public totalStaked;
    uint256 public minStake;
    uint256 public constant percentDivider = 100;

    //arrays
    uint256[5] public percentages = [500, 1200, 2000, 4500, 12000];
    uint256[5] public parts = [1, 1, 2, 3, 4];
    uint256[5][] public partsDuration = [
        [30 seconds, 0, 0, 0],
        [60 seconds, 0, 0, 0],
        [60 seconds, 30 seconds, 0, 0],
        [60 seconds, 60 seconds, 60 seconds, 0],
        [90 seconds, 90 seconds, 90 seconds, 90 seconds]
    ];
    uint256[5][] public partsPercentage = [
        [100, 0, 0, 0],
        [100, 0, 0, 0],
        [50, 50, 0, 0],
        [50, 25, 25, 0],
        [25, 25, 25, 25]
    ];
    //structures
    struct Stake {
        uint256 time;
        uint256 amount;
        uint256 bonus;
        uint256 parts;
        uint256 currentPart;
        uint256[4] durationsParts;
        uint256[4] percentageParts;
        bool[4] withdrawan;
        bool completeWithdrawn;
    }

    struct User {
        uint256 totalstakeduser;
        uint256 stakecount;
        uint256 claimedRewardtokens;
        uint256 unStakedTokens;
        mapping(uint256 => Stake) stakerecord;
    }

    //mappings
    mapping(address => User) public users;
    mapping(address => bool) public uniqueStaker;

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: Not an owner");
        _;
    }

    //events
    event Staked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    event UnStaked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    event Withdrawn(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    event UNIQUESTAKERS(address indexed _user);

    // constructor
    constructor() {
        owner = payable(msg.sender);
        rewardToken = IBEP20(0x742511AC832c5FD20c0347d099882d69A944B6A0);
        stakeToken = IBEP20(0x1a71F39Dd5383CE8a7d5b2Db935c0DfCF03EFb9c);
        unstakeToken = IBEP20(0xe1d9257C76411D55E725cBE2badF0995595f168F);
        minStake = 5000;
        minStake = minStake.mul(10**stakeToken.decimals());
    }

    // functions


    //writeable
    function stake(uint256 amount, uint256 plan) public {
        require(plan >= 0 && plan < 6, "put valid plan details");
        require(
            amount >= minStake,
            "cant deposit need to stake more than minimum amount"
        );
        if (!uniqueStaker[msg.sender]) {
            uniqueStaker[msg.sender] = true;
            totalUniqueStakers++;
            emit UNIQUESTAKERS(msg.sender);
        }
        User storage user = users[msg.sender];
        stakeToken.transferFrom(msg.sender, owner, (amount));
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].time = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].bonus = amount
            .mul(percentages[plan])
            .div(percentDivider);
        user.stakerecord[user.stakecount].parts = parts[plan];
        for (uint256 i; i < 4; i++) {
            user.stakerecord[user.stakecount].durationsParts[i] = partsDuration[plan][i];
            user.stakerecord[user.stakecount].percentageParts[i] = partsPercentage[plan][i];
        }

        user.stakecount++;
        totalStaked += amount;
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function withdraw(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].completeWithdrawn,
            " withdraw completed "
        );
        uint256 timecheck = user.stakerecord[count].time;
        for (uint256 i; i < user.stakerecord[count].parts; i++) {
            timecheck += user.stakerecord[count].durationsParts[i];
            if (block.timestamp >= timecheck) {
                if (user.stakerecord[count].currentPart <= i + 1) {
                    user.stakerecord[count].currentPart = i + 1;
                }
            }
        }
        for (uint256 i; i < user.stakerecord[count].currentPart; i++) {
            if (!user.stakerecord[count].withdrawan[i]) {
                uint256 send;
                send = user
                    .stakerecord[count]
                    .bonus
                    .mul(user.stakerecord[count].percentageParts[i])
                    .div(percentDivider);
                rewardToken.transferFrom(owner, msg.sender, send);
                user.stakerecord[count].withdrawan[i] = true;
                user.claimedRewardtokens += send;
                emit Withdrawn(msg.sender, send, block.timestamp);
            }
        }
        if (
            user.stakerecord[count].withdrawan[0] &&
            user.stakerecord[count].withdrawan[1] &&
            user.stakerecord[count].withdrawan[2] &&
            user.stakerecord[count].withdrawan[3]
        ) {
            user.stakerecord[count].completeWithdrawn = true;
        }
        if (
            user.stakerecord[count].withdrawan[
                user.stakerecord[count].parts - 1
            ]
        ) {
            user.stakerecord[count].completeWithdrawn = true;
        }
        if(user.stakerecord[count].completeWithdrawn){
            
            unstakeToken.transferFrom(owner, msg.sender,user.stakerecord[count].amount );
        }
    }

    function unstake(uint256 count) public {
        User storage user = users[msg.sender];
        require(!user.stakerecord[count].completeWithdrawn);
        unstakeToken.transferFrom(
            owner,
            msg.sender,
            user.stakerecord[count].amount
        );
        user.stakerecord[count].completeWithdrawn = true;
        user.stakerecord[count].withdrawan[0] = true;
        user.stakerecord[count].withdrawan[1] = true;
        user.stakerecord[count].withdrawan[2] = true;
        user.stakerecord[count].withdrawan[3] = true;
        user.unStakedTokens += user.stakerecord[count].amount;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function migrateStuckFunds() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function migratelostToken(address lostToken) external onlyOwner {
        IBEP20(lostToken).transfer(
            owner,
            IBEP20(lostToken).balanceOf(address(this))
        );
    }

    //readable
    
    function stakedetails(address add, uint256 count)
        public
        view
        returns (
            uint256 time,
            uint256 amount,
            uint256 bonus,
            uint256 partscount,
            uint256 currentPart,
            bool completeWithdrawn
        )
    {
        return (
            users[add].stakerecord[count].time,
            users[add].stakerecord[count].amount,
            users[add].stakerecord[count].bonus,
            users[add].stakerecord[count].parts,
            users[add].stakerecord[count].currentPart,
            users[add].stakerecord[count].completeWithdrawn
        );
    }

    function stakedetailsArrays(address add, uint256 count)
        public
        view
        returns (
            uint256[4] memory durationsParts,
            uint256[4] memory percentageParts,
            bool[4] memory withdrawan
        )
    {
        return (
            users[add].stakerecord[count].durationsParts,
            users[add].stakerecord[count].percentageParts,
            users[add].stakerecord[count].withdrawan
        );
    }

    function calculateRewards(uint256 amount, uint256 plan)
        external
        view
        returns (uint256)
    {
        return amount.mul(percentages[plan]).div(percentDivider);
    }

    function currentStaked(address add) external view returns (uint256) {
        uint256 currentstaked;
        for (uint256 i; i < users[add].stakecount; i++) {
            if (!users[add].stakerecord[i].completeWithdrawn) {
                currentstaked += users[add].stakerecord[i].amount;
            }
        }
        return currentstaked;
    }

    function nextWithdrawTime(address add, uint256 count)
        external
        view
        returns (uint256)
    {
        uint256 nexttime = users[add].stakerecord[count].time;
        for (uint256 i; i < users[add].stakerecord[count].currentPart; i++) {
            if (!users[add].stakerecord[count].completeWithdrawn) {
                nexttime += users[add].stakerecord[count].durationsParts[i];
            }
        }
        return nexttime;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractstakeTokenBalance() external view returns (uint256) {
        return stakeToken.allowance(owner, address(this));
    }

    function getContractrewardTokenBalance() external view returns (uint256) {
        return rewardToken.allowance(owner, address(this));
    }

    function getContractUnStakeTokenBalance() external view returns (uint256) {
        return unstakeToken.allowance(owner, address(this));
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }
}

//library
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