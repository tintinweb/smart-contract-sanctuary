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
    IBEP20 public Adamantium;
    IBEP20 public Wolverinu;
    address payable public owner;
    uint256 public totalUniqueStakers;
    uint256 public totalStaked;
    uint256 public minStake;
    uint256 public constant percentDivider = 100000;

    //arrays
    uint256[4] public percentages = [500, 1500, 5000, 10000];
    uint256[4] public durations = [15 minutes, 30 minutes, 60 minutes, 90 minutes];

    
    //structures
    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
        bool unstaked;
    }

    struct User {
        uint256 totalstakeduser;
        uint256 stakecount;
        uint256 claimedTokens;
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
        uint256 indexed _Time
    );

    event UnStaked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event Withdrawn(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event ExtenderStake(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event UNIQUESTAKERS(address indexed _user);

    // constructor
    constructor() {
        owner = payable(msg.sender);
        Adamantium = IBEP20(0xF322004264d8A5970eB00746bC93f73c4C4E4f89);
        Wolverinu = IBEP20(0x86834070B4700F7737B079E5fA78694922B5e117);
        minStake = 5;
        minStake = minStake.mul(10**Adamantium.decimals());
    }

    // functions


    //writeable
    function stakeAdamantium(uint256 amount, uint256 plan) public {
        require(plan >= 0 && plan < 4, "put valid plan details");
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
        Adamantium.transferFrom(msg.sender, address(this), amount);
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
        user.stakecount++;
        totalStaked += amount;
        emit Staked(msg.sender, amount, block.timestamp);
    }
    function stakeWolverinu(uint256 amount, uint256 plan) public {
        require(plan >= 0 && plan < 4, "put valid plan details");
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
        Wolverinu.transferFrom(msg.sender, address(this), amount);
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
        user.stakecount++;
        totalStaked += amount;
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function withdrawAdamantium(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(Adamantium.balanceOf(address(this)) >= user.stakerecord[count].amount , "insufficent Contract Balance");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " withdraw completed "
        );
        Adamantium.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        Adamantium.transferFrom(
            owner,
            msg.sender,
            user.stakerecord[count].bonus
        );
        user.claimedTokens += user.stakerecord[count].amount;
        user.claimedTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        emit Withdrawn(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp);
    }
    function withdrawWolverinu(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(Wolverinu.balanceOf(address(this)) >= user.stakerecord[count].amount , "insufficent Contract Balance");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " withdraw completed "
        );
        Wolverinu.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        Wolverinu.transferFrom(
            owner,
            msg.sender,
            user.stakerecord[count].bonus
        );
        user.claimedTokens += user.stakerecord[count].amount;
        user.claimedTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        emit Withdrawn(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp);
    }
    function extendStake(uint256 count,uint256 newplan) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(newplan >= 0 && newplan < 4 ,"Enter Valid Plan");
        require(user.stakerecord[count].plan < newplan, "Can not extend to lower plan");
        
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        user.stakerecord[count].plan = newplan ;
        user.stakerecord[user.stakecount].withdrawTime = user.stakerecord[count].stakeTime.add(durations[user.stakerecord[count].plan]);
        user.stakerecord[user.stakecount].bonus = (user.stakerecord[count].amount.mul(percentages[user.stakerecord[count].plan])).div(percentDivider);
        emit ExtenderStake(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }

    function unstakeAdamantium(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(Adamantium.balanceOf(address(this)) >= user.stakerecord[count].amount , "insufficent Contract Balance");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        Adamantium.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        user.unStakedTokens += user.stakerecord[count].amount;
        user.stakerecord[count].unstaked = true;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }
    function unstakeWolverinu(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(Wolverinu.balanceOf(address(this)) >= user.stakerecord[count].amount , "insufficent Contract Balance");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        Wolverinu.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        user.unStakedTokens += user.stakerecord[count].amount;
        user.stakerecord[count].unstaked = true;
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
        // uint256 stakeTime,
        uint256 withdrawTime,
        uint256 amount,
        uint256 bonus,
        uint256 plan,
        bool withdrawan,
        bool unstaked
        )
    {
        return (
            // users[add].stakerecord[count].stakeTime,
            users[add].stakerecord[count].withdrawTime,
            users[add].stakerecord[count].amount,
            users[add].stakerecord[count].bonus,
            users[add].stakerecord[count].plan,
            users[add].stakerecord[count].withdrawan,
            users[add].stakerecord[count].unstaked
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
            if (!users[add].stakerecord[i].withdrawan) {
                currentstaked += users[add].stakerecord[i].amount;
            }
        }
        return currentstaked;
    }

    function getContractTokenBalanceWolverinu() external view returns (uint256) {
        return Wolverinu.allowance(owner, address(this));
    }

    function getContractTokenBalanceAdamantium() external view returns (uint256) {
        return Adamantium.allowance(owner, address(this));
    }

    function getCurrentwithdrawTime() external view returns (uint256) {
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