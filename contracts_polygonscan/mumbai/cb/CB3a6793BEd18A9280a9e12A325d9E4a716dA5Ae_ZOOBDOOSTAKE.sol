/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

pragma solidity ^0.8.9;


// SPDX-License-Identifier: MIT
interface IERC20 {
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

contract ZOOBDOOSTAKE {
    using SafeMath for uint256;

    //Variables
    IERC20 public stakeToken;
    address payable public owner;
    uint256 public totalUniqueStakers;
    uint256 public totalStaked;
    uint256 public minStake;
    uint256 public unstakePenalty;
    uint256 public timeStep;
    uint256 public constant percentDivider = 100000;

    //arrays
    uint256[3] public percentages = [0, 0, 0];
    uint256[3] public APY = [7500,12500,25000];
    uint256[3] public durations = [30 seconds, 90 seconds, 365 seconds];

    
    //structures
    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
    }

    struct User {
        uint256 totalstakeduser;
        uint256 stakecount;
        uint256 claimedstakeTokens;
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

    

    event Withdrawn(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event UnStaked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event UNIQUESTAKERS(address indexed _user);

    // constructor
    constructor() {
        owner = payable(msg.sender);
        stakeToken = IERC20(0xC0fdBA626493dC6b1bA1d79e20171AB2a2295E0C);
        minStake = 50;
        minStake = minStake.mul(10**stakeToken.decimals());
        unstakePenalty = 5;
        setApyToPercentrage();

    }

    // functions


    //writeable
    function stake(uint256 amount, uint256 plan) public {
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
        stakeToken.transferFrom(msg.sender, address(this), amount);
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
        require(block.timestamp > user.stakerecord[count].withdrawTime , "can't withdraw before time");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        stakeToken.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        stakeToken.transfer(
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
    function unstake(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(block.timestamp < user.stakerecord[count].withdrawTime , "can't unstake after time");
        require(
            !user.stakerecord[count].withdrawan,
            " Already completed "
        );
        stakeToken.transfer(
            msg.sender,
            user.stakerecord[count].amount.mul(100 - unstakePenalty).div(100)
        );
        user.claimedstakeTokens += user.stakerecord[count].amount.mul(100 - unstakePenalty).div(100);
        user.stakerecord[count].withdrawan = true;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp);
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function migrateStuckFunds() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function migratelostToken(address lostToken) external onlyOwner {
        IERC20(lostToken).transfer(
            owner,
            IERC20(lostToken).balanceOf(address(this))
        );
    }
    function setminimumtokens(uint256 amount) external onlyOwner {
        minStake = amount;
    }
    function setunstakePenalty(uint256 amount) external onlyOwner {
        unstakePenalty = amount;
    }
    function setStakeToken(IERC20 token) external onlyOwner {
        stakeToken = token;
    }
    function setstakeToken(IERC20 token) external onlyOwner {
        stakeToken = token;
    }
    function setpercentages(uint256 amount1,uint256 amount2,uint256 amount3) external onlyOwner {
        percentages[0] = amount1;
        percentages[1] = amount2;
        percentages[2] = amount3;
    }
    function setAPY(uint256 amount1,uint256 amount2,uint256 amount3) external onlyOwner {
        APY[0] = amount1;
        APY[1] = amount2;
        APY[2] = amount3;
        setApyToPercentrage();
    }
    function setDurations(uint256 amount1,uint256 amount2,uint256 amount3) external onlyOwner {
        durations[0] = amount1;
        durations[1] = amount2;
        durations[2] = amount3;
        setApyToPercentrage();
    }

    //readable
    function APYtoPercentage(uint256 apy, uint256 duration) internal pure returns(uint256){
        return apy.mul(duration).div(365);
    }
    function stakedetails(address add, uint256 count)
        public
        view
        returns (
        // uint256 stakeTime,
        uint256 withdrawTime,
        uint256 amount,
        uint256 bonus,
        uint256 plan,
        bool withdrawan
        )
    {
        return (
            // users[add].stakerecord[count].stakeTime,
            users[add].stakerecord[count].withdrawTime,
            users[add].stakerecord[count].amount,
            users[add].stakerecord[count].bonus,
            users[add].stakerecord[count].plan,
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
    function setApyToPercentrage() internal {
        for(uint256 i ; i < percentages.length;i++){
            percentages[i] = APYtoPercentage(APY[i], durations[i].div(1 seconds));
        }
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