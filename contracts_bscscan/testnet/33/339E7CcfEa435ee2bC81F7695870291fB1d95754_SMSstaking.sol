/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

pragma solidity 0.5.10;


interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor() internal {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract SMSstaking is Ownable{
    using SafeMath for uint256;
    ITRC20 public SMS;

    struct userInfo {
        uint256 DepositeToken;
        uint256 lastUpdated;
        uint256 lockableDays;
        uint256 WithdrawReward;
        uint256 WithdrawAbleReward;
        uint256 totalreward;
        uint256 depositeTime;
        address upline;
        uint256 referrals;
        uint256 rewarddays;
        uint256 depositestatus;
        uint256 Time_to_next_withraw;
        uint256 upline_Reward;
    }
    
    mapping(uint256 => uint256) public allocation;
    mapping(address => userInfo) public users;
    uint256 minimumDeposit = 100E18;
    uint256 Depositwithoutlocking = 200E18;
    uint256 public TimeToGetReward = 1 minutes;
    uint256 public OwnerFee;
    uint256 public total_users = 1;
    uint256 public Meximum_reward_withraw;
    uint256 public time_to_next_withraw;
    uint256 public Total_Stake_SMS;
    uint256 public Total_Upline_Earned;

    constructor(ITRC20 _SMS) public {
        SMS = _SMS;
        allocation[15] = 30;
        allocation[30] = 36;
        allocation[60] = 48;
        allocation[120] = 60;
        allocation[240] = 72;
        allocation[365] = 96;
        allocation[0] = 24;
        
    }




    function _setUpline(address _addr, address  _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != _owner && (users[_upline].depositeTime > 0 || _upline == _owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;


            total_users++;

        }
    }

      function _chakUpline( address _upline) public view returns(bool){
        if(users[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != _owner && (users[_upline].depositeTime > 0 || _upline == _owner)) {

            return true;  

        }
    }

    function Deposite(uint256 _amount, uint256 _lockableDays,address _upline) public 
    {
        _setUpline(msg.sender,_upline);
        userInfo storage user = users[msg.sender];
        require(user.DepositeToken == 0, "Muliple Deposite not allowed");
        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        
         if(total_users >= 2){
            uint256 referralone = _amount*5/100;
        SMS.transfer(_upline,referralone);
        users[_upline].upline_Reward += referralone;
        Total_Upline_Earned += referralone;
        }
        address  upline2 = users[_upline].upline;
        uint256 referraltwo = _amount*25/1000;
        if(total_users >= 3){
        SMS.transfer(upline2,referraltwo);
        users[upline2].upline_Reward += referraltwo;
        Total_Upline_Earned += referraltwo;
        }
        address  upline3 = users[upline2].upline;
        uint256 referralthree = _amount*5/1000;
        if(total_users >= 4){
        SMS.transfer(upline3,referralthree);
        users[upline3].upline_Reward += referralthree;
        Total_Upline_Earned += referralthree;
        }
        
        SMS.transferFrom(msg.sender, address(this), _amount);
        user.DepositeToken = _amount;
        user.lastUpdated = uint40(block.timestamp)+ TimeToGetReward;
        user.depositeTime = uint40(block.timestamp);
        user.lockableDays = _lockableDays;
        user.depositestatus = 1;
        Total_Stake_SMS += _amount;
    }
    function Deposite_WithoutLocking(uint256 _amount) public 
    {
        userInfo storage user = users[msg.sender];
        require(user.DepositeToken == 0, "Muliple Deposite not allowed");
        require(_amount >= Depositwithoutlocking, "Invalid amount");
        SMS.transferFrom(msg.sender, address(this), _amount);
        user.DepositeToken = _amount;
        user.lastUpdated = uint40(block.timestamp)+ TimeToGetReward;
        user.depositeTime = uint40(block.timestamp);
        Total_Stake_SMS += _amount;
        user.depositestatus = 1;
    }


    function Rewards() public returns(uint256)
    {
        userInfo storage user = users[msg.sender];
        require( user.depositestatus > 0, " Deposite not ");
        uint256 daysreward;
        uint256 perday = ((allocation[user.lockableDays].mul(1E18))).div(365);
        uint256 testTime = uint40(block.timestamp.sub(user.depositeTime));
        uint256 lockTime = user.depositeTime+(user.lockableDays*60);
        if(now > lockTime && user.lockableDays > 0){

        daysreward = (user.lockableDays.mul(perday).div(100)).mul(user.DepositeToken).div(1E18);
        user.totalreward = user.totalreward.add(daysreward.sub(user.totalreward));
        user.WithdrawAbleReward =user.totalreward.sub(user.WithdrawReward);
        user.depositestatus = 0;
        }
        else if (now > user.lastUpdated){
            user.rewarddays = uint256(testTime/ TimeToGetReward);
        daysreward = (user.rewarddays.mul(perday).div(100)).mul(user.DepositeToken).div(1E18);
        user.totalreward = user.totalreward.add(daysreward.sub(user.totalreward));
        user.lastUpdated += TimeToGetReward;
        user.WithdrawAbleReward =user.totalreward.sub(user.WithdrawReward);
        
        }
        
        return user.WithdrawAbleReward;
        
    }
    

    function WithdrawReward(uint256 _amount) public {
        userInfo storage user = users[msg.sender];
        
        require(user.WithdrawAbleReward >= _amount , "No Reward Balance found" );
        require(_amount <=  Meximum_reward_withraw , "Meximum 10 sms withdraw" );
         require(now >  user.Time_to_next_withraw , " withdraw next day" );
            SMS.transfer(msg.sender, _amount);
            
             user.WithdrawReward =user.WithdrawReward.add(user.WithdrawAbleReward);
             user.WithdrawAbleReward = 0;
             user.Time_to_next_withraw =uint40(block.timestamp) + time_to_next_withraw;
    }
    
    
     function Withdraw_Staking_Amount() public {
         
        userInfo storage user = users[msg.sender];
        require(OwnerFee > 0 , "Set OwnerFee" );
        require(Rewards() == 0 , "get your reward first" );
        require(user.DepositeToken > 0 , "No deposite Balance found" );
        require(user.WithdrawAbleReward  == 0 , "Withdraw your Reward first" );
        require(now > user.lockableDays * TimeToGetReward , "withdraw not Allowing" );
        uint256 ownerfee = (OwnerFee*user.DepositeToken/100).div(1E18);
        uint256 withdrawableAmount = user.DepositeToken.sub(ownerfee);
        SMS.transfer(msg.sender,withdrawableAmount);
        user.DepositeToken = 0;
        user.WithdrawReward = 0;
        user.depositeTime  = 0;
        user.lastUpdated  = 0;
        user.lockableDays   = 0;
        user.rewarddays  = 0;
        user.totalreward   = 0;
        user.rewarddays  = 0;
    }

 
     // EMERGENCY ONLY onlyOwner.
     
    function SetOwnerfee(uint256 _amount) public onlyOwner{
        OwnerFee = _amount;
    }
    
    function Meximum_Reward_Withraw(uint256 _amount) public onlyOwner{
        Meximum_reward_withraw = _amount;
    }
    function Time_To_Next_Withraw(uint256 _time) public onlyOwner{
        time_to_next_withraw = _time;
    }
    
    function SetLocking_Percentage (uint256 _day,uint256 _percentage) public onlyOwner{
        allocation[_day] = _percentage;
    }
    
    function emergencyWithdraw(uint256 SMSAmount) public onlyOwner {
         SMS.transfer(msg.sender, SMSAmount);
    }
    function emergencyWithdrawBNB(uint256 Amount) public onlyOwner {
         msg.sender.transfer(Amount);
    }
    function check_Balance() public view returns(uint256){
        return address(this).balance;
    }
    
}