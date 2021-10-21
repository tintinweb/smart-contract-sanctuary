pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakeContract {

    using SafeMath for uint256;
    
    IBEP20 public stakeToken;
    IBEP20 public rewardToken;
    address payable public owner;
    uint256 public minStake;
    uint256  public constant percentDivider = 100;
    uint256 [5] public percentages = [50 , 75 , 100 , 150 , 300];
    uint256 [5] public parts = [ 1 , 1 , 2 , 3 , 4];
    uint256 [5][] public partsDuration = [ [30 days , 0 , 0 , 0] , [60 days , 0 , 0 , 0] , [60 days , 30 days , 0 , 0] , [60 days , 60 days , 60 days , 0] , [90 days , 90 days , 90 days , 90 days]];
    uint256 [5][] public partsPercentage = [ [100, 0 , 0 , 0] , [100 , 0 , 0 , 0] , [50  , 50  , 0 , 0] , [50  , 25  , 25  , 0] , [25  , 25  , 25  , 25 ]];

    struct Stake{
        uint256 time;
        uint256 amount;
        uint256 bonus;
        uint256 parts;
        uint256 currentPart;
        uint256 [4] durationsParts;
        uint256 [4] percentageParts;
        bool [4] withdrawan;
    }
    
    struct User{
        uint256 totalstakeduser;
        uint256 stakecount;
        mapping(uint256 => Stake) stakerecord;
    }
    
    mapping(address => User) public users;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Ownable: Not an owner");
        _;
    }
    
    event Staked(address indexed _user, uint256 indexed _amount, uint256 indexed _time);
    
    event UnStaked(address indexed _user, uint256 indexed _amount, uint256 indexed _time);
    
    event Withdrawn(address indexed _user, uint256 indexed _amount, uint256 indexed _time);
    
    constructor() {
        owner = payable(msg.sender);
        rewardToken = IBEP20(0x746176319973b379DAE02495252C20e133A3b409);
        stakeToken = IBEP20(0x746176319973b379DAE02495252C20e133A3b409);
        // minStake = 5000;
        // minStake = minStake.mul(10**stakeToken.decimals());
    }
    
    function stake(uint256 amount,uint256 plan) public{
        require(plan >=0 && plan <6 ,"put valid plan details");
        require(amount >= minStake , "cant deposit need to stake more than minimum amount");
        User storage user = users[msg.sender];
        stakeToken.transferFrom(msg.sender,owner,(amount));
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].time = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
        user.stakerecord[user.stakecount].parts = parts[plan];
        for(uint256 i ; i < 4 ; i++){
            user.stakerecord[user.stakecount].durationsParts[plan] = partsDuration[plan][i];
            user.stakerecord[user.stakecount].percentageParts[plan] = partsPercentage[plan][i];
        }
        
        user.stakecount++;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }
    
    function withdraw(uint256 count) public{
        User storage user = users[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(!user.stakerecord[count].withdrawan[0] || !user.stakerecord[count].withdrawan[1] || !user.stakerecord[count].withdrawan[2] || !user.stakerecord[count].withdrawan[3]," withdraw completed ");
       
        for(uint256 i ; i < user.stakerecord[count].parts ; i++){
            if(block.timestamp >= user.stakerecord[count].time + user.stakerecord[count].durationsParts[i]){
                if(user.stakerecord[count].currentPart <= i+1){
                    user.stakerecord[count].currentPart = i+1;
                }
            }
        }
        for(uint256 i ; i < user.stakerecord[count].currentPart ; i++){
            if(!user.stakerecord[count].withdrawan[i]){
                uint256 send;
                send = user.stakerecord[count].bonus.mul(user.stakerecord[count].percentageParts[i]).div(percentDivider);
                rewardToken.transferFrom(owner,msg.sender,send);
                user.stakerecord[count].withdrawan[i] = true;
                emit Withdrawn(msg.sender, send, block.timestamp);
            }
        }

    }
    
    
    function stakedetails(address add,uint256 count) public view returns(
        uint256 time,
        uint256 amount,
        uint256 bonus,
        uint256 partscount,
        uint256 currentPart){
        
        return(
        users[add].stakerecord[count].time,
        users[add].stakerecord[count].amount,
        users[add].stakerecord[count].bonus,
        users[add].stakerecord[count].parts,
        users[add].stakerecord[count].currentPart
        );
    }
    function stakedetailsArrays(address add,uint256 count) public view returns(
       
        uint256 [4] memory durationsParts,
        uint256 [4] memory percentageParts,
        bool [4] memory withdrawan){
        
        return(
        users[add].stakerecord[count].durationsParts,
        users[add].stakerecord[count].percentageParts,
        users[add].stakerecord[count].withdrawan
        );
    }
    
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractstakeTokenBalance() external view returns(uint256){
        return stakeToken.balanceOf(address(this));
    }
    function getContractrewardTokenBalance() external view returns(uint256){
        return rewardToken.balanceOf(address(this));
    }

    function getCurrentTime() external view returns(uint256){
        return block.timestamp;
    }
    
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    function migrateStuckFunds() external onlyOwner{
        owner.transfer(address(this).balance);
    }
    function migratelostToken (address lostToken) external onlyOwner{
        IBEP20(lostToken).transfer(owner,IBEP20(lostToken).balanceOf(address(this)));
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