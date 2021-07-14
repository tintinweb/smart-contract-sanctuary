/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity ^ 0.8.4;
// SPDX-License-Identifier: MIT

// import './PreSaleBnb.sol';

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

contract HODLStake{
    using SafeMath for uint256;
    IERC20 Token;
    // IERC20 Reward;
    address payable owner;
    uint256 public totalstakeable;
    uint256 public contractendtime;
    uint256 public totalstakedamount;
    uint256 public totalstakers;
    uint256 [4] public tier_pool_weight = [0,10,25,50];
    uint256 [4] public tier_pool_member = [0,0,0,0];
    uint256 [4] public tier_pool_amount = [0,1500,3000,6000];
    struct Stake{
        uint256 time;
        uint256 amount;
    }
    struct User{
        uint256 totalstakeduser;
        uint256 currenttire;
        bool [4] tirein;
        uint256 stakecount;
        bool unstake;
        uint256 unstaketime;
        mapping(uint256 => Stake) stakerecord;
        bool withdrawan;
    }
    mapping (address => User) public Stakers;
    
    modifier onlyowner(){
        require(owner == msg.sender,"not accessable");
        _;
    }
    
    constructor(address _token){
        owner = payable(msg.sender);
        Token = IERC20(_token);
        totalstakeable =  Token.totalSupply();
        contractendtime = block.timestamp + 30 seconds;
        
    }
    function stake(uint256 val) public{
        Token.transferFrom(msg.sender,address(this),val);
        User storage user = Stakers[msg.sender];
        if(!userexits(msg.sender))
        {
            totalstakers++;
            
        }
        user.totalstakeduser+= val;
        totalstakedamount+= val;
        user.stakerecord[user.stakecount].time = block.timestamp;
        user.stakerecord[user.stakecount].amount = val;
        user.stakecount++;
        user.withdrawan = false;
        if(user.totalstakeduser >= tier_pool_amount[1].mul(1e18) && user.totalstakeduser < tier_pool_amount[2].mul(1e18))
        {
            user.currenttire = 1;
            tier_pool_member[user.currenttire] +=1;
            user.tirein[1] = true;
        }else if(user.totalstakeduser >= tier_pool_amount[2].mul(1e18) && user.totalstakeduser < tier_pool_amount[3].mul(1e18))
        {
            checktier(msg.sender,2);
            user.tirein[2] = true;
            user.currenttire = 2;
            tier_pool_member[user.currenttire] +=1; 
        }else if(user.totalstakeduser >= tier_pool_amount[3].mul(1e18))
        {
            checktier(msg.sender,3);
            user.tirein[3] = true;
            user.currenttire = 3;
            tier_pool_member[user.currenttire] +=1; 
        }
        
    }
    // function withdraw() public{
    //     require(contractendtime < block.timestamp,"cannot withdraw before time");
    //     User storage user = Stakers[msg.sender];
    //     require(!user.withdrawan,"withdraw only once");
    //     uint256 [3] memory amount;
    //     amount =  distributioncalculation();
    //     uint256 reward = amount[user.currenttire].div(tier_pool_member[user.currenttire]);
    //     Reward.transfer(msg.sender,reward);
    //     user.withdrawan = true;
        
    // }
    function unstake() public{
        User storage user = Stakers[msg.sender];
        require(!user.withdrawan,"cant unstake already withdrawan");
        require(!user.unstake,"already unstaked" );
        user.unstake = true;
        user.unstaketime = block.timestamp + 3 days;
        
    }
    function withdrawunstake() public{
        User storage user = Stakers[msg.sender];
        require(user.unstaketime < block.timestamp , "you can withdraw after 72 hours of unstaking");
        require(user.unstake,"need to unstake first");
        require(!user.withdrawan,"already withdrawan");
        user.withdrawan = true;
        user.unstake = false;
        Token.transfer(msg.sender,user.totalstakeduser);
        totalstakedamount -= user.totalstakeduser;
        user.totalstakeduser = 0;
        totalstakers--;
    }
    function setweights(uint256 Bronze, uint256 Silver , uint256 Gold) onlyowner() public{
        tier_pool_weight[1] = Bronze;
        tier_pool_weight[2] = Silver;
        tier_pool_weight[3] = Gold;
    }
    function distributioncalculation(uint256 SUPPLY)public view returns(uint256 [4] memory){
        uint256 sum = 0;
        uint256 mul = 0;
        for(uint256 i ;i < 4;i++)
        {
            mul = tier_pool_weight[i].mul(tier_pool_member[i]);
            sum += mul;
        }
        uint256 finals = SUPPLY.div(sum);
        uint256 [4] memory pertire;
        for(uint256 j ; j < 4 ; j++){
            pertire[j] = tier_pool_weight[j].mul(tier_pool_member[j]).mul(finals);
        }
        return pertire;
    }
    function userexits(address user) public view returns(bool success){
        if(Stakers[user].totalstakeduser == 0)
        {
            return false;
        }
        else return true;
    }
    function usertier(address add) public view returns(uint256){
        return Stakers[add].currenttire;
    }
    function checktier(address us,uint256 val) public {
        User storage user = Stakers[us];
        for(uint256 i = 0;i < val ; i++)
        {
            if (user.tirein[i])
            {
                user.tirein[i] = false;
                tier_pool_member[i] -= 1 ;
                
            }
        }
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}