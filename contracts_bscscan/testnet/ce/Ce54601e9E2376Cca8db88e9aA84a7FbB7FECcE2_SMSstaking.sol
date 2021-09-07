/**
 *Submitted for verification at BscScan.com on 2021-09-06
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
        uint256 Time_to_next_withraw;
        uint256 upline_Reward;
        uint256 withrawableDepositeAmount;
    }
        struct UserInfo {
        uint256 lastUpdated;
        uint256 lockableDays;
        uint256 WithdrawReward;
        uint256 WithdrawAbleReward;
        uint256 totalreward;
        uint256 depositeTime;
        uint256 rewarddays;
        uint256 Time_to_next_withraw;
        uint256 withrawableDepositeAmount;
        uint256 withoutlockingamount;
    }
    
    mapping(uint256 => uint256) public allocation;
    mapping(address => mapping(uint256 => userInfo)) private users;
    mapping(address => mapping(uint256 => UserInfo)) private withoutlocking;
    mapping(address =>  userInfo) public Users;
    mapping(address =>  UserInfo) public UsersWithoutlocking;
    uint256 minimumDeposit = 100E18;
    uint256 Depositwithoutlocking = 200E18;
    uint256 public TimeToGetReward = 1 minutes;
    uint256 public OwnerFee;
    uint256 public total_users = 1;
    uint256 private Meximum_reward_withraw = 10 ether;
    uint256 private time_to_next_withraw = 1 days;
    uint256 public Total_Stake_SMS;
    uint256 public Total_Upline_Earned;
    uint256 [] deposit;
    uint256 private id = 0;

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
     event Deposite_(address indexed upline, uint256 amount, uint256 day,uint256 time);
     event Deposite_Without_Locking( uint256 amount, uint256 day,uint256 time);
     event Reward( uint256 reward, uint256 WithdrawAbleReward,uint256 WithdrawReward);
     event Withdraw_Reward(address  user, uint256 amount,uint256 time);
     event Withdraw_Staking(address  user, uint256 amount,uint256 time,uint256 owerfee);




    function _setUpline(address _addr, address  _upline) private {
        if(Users[_addr].upline == address(0) && _upline != _addr && _addr != _owner && (Users[_upline].depositeTime > 0 || _upline == _owner)) {
            Users[_addr].upline = _upline;
            Users[_upline].referrals++;
            total_users++;
        }
    }

      function _chakUpline( address _upline) public view returns(bool){
        if(Users[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != _owner && (Users[_upline].depositeTime > 0 || _upline == _owner)) {

            return true;  

        }
    }

    function Deposite(uint256 _amount, uint256 _lockableDays,address _upline) public 
    {
        _setUpline(msg.sender,_upline);
        userInfo storage user = users[msg.sender][id];

        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        
         if(total_users >= 2){
            uint256 referralone = _amount*5/100;
        SMS.transfer(_upline,referralone);
        Users[_upline].upline_Reward += referralone;
        Total_Upline_Earned += referralone;
        }
        address  upline2 = Users[_upline].upline;
        uint256 referraltwo = _amount*25/1000;
        if(total_users >= 3){
        SMS.transfer(upline2,referraltwo);
        Users[upline2].upline_Reward += referraltwo;
        Total_Upline_Earned += referraltwo;
        }
        address  upline3 = Users[upline2].upline;
        uint256 referralthree = _amount*5/1000;
        if(total_users >= 4){
        SMS.transfer(upline3,referralthree);
        Users[upline3].upline_Reward += referralthree;
        Total_Upline_Earned += referralthree;
        }
        
        SMS.transferFrom(msg.sender, address(this), _amount);
        user.DepositeToken = _amount;
        user.lastUpdated = uint40(block.timestamp)+ TimeToGetReward;
        user.depositeTime = uint40(block.timestamp);
        Users[msg.sender].depositeTime = uint40(block.timestamp);
        Users[msg.sender].DepositeToken += _amount;
        user.lockableDays = _lockableDays;
        Total_Stake_SMS += _amount;
        deposit.push(id);
        id++;
        
        emit Deposite_(_upline,_amount,_lockableDays,uint40(block.timestamp));
        
    }
    
    function Deposite_WithoutLocking(uint256 _amount) public 
    {
        UserInfo storage user = withoutlocking[msg.sender][id];
        require(_amount >= Depositwithoutlocking, "Invalid amount");

        SMS.transferFrom(msg.sender, address(this), _amount);
        user.lastUpdated = uint40(block.timestamp)+ TimeToGetReward;
        user.depositeTime = uint40(block.timestamp);
        user.lockableDays = 0;
        user.withoutlockingamount = _amount;
        user.withrawableDepositeAmount = _amount;
        UsersWithoutlocking[msg.sender].withoutlockingamount +=_amount;
        Total_Stake_SMS += _amount;
        deposit.push(id);
        id++;
        emit Deposite_Without_Locking(_amount,0,uint40(block.timestamp));
    }


    function Rewards() public returns(uint256)
    {
        for(uint256 z=0 ; z< deposit.length;z++){
        userInfo storage user = users[msg.sender][z];
        require( Users[msg.sender].DepositeToken > 0, " Deposite not ");
        uint256 daysreward;
        uint256 perday = ((allocation[user.lockableDays].mul(1E18))).div(365);
        uint256 testTime = uint40(block.timestamp.sub(user.depositeTime));
        uint256 lockTime = user.depositeTime+(user.lockableDays*60);
        if(now > lockTime && user.lockableDays > 0 && user.DepositeToken > 0){
        daysreward = (user.lockableDays.mul(perday).div(100)).mul(user.DepositeToken).div(1E18);
        Users[msg.sender].totalreward += daysreward.sub(user.totalreward);
        user.totalreward += daysreward.sub(user.totalreward);
        Users[msg.sender].withrawableDepositeAmount += user.DepositeToken; 
        Users[msg.sender].WithdrawAbleReward += Users[msg.sender].totalreward.sub(Users[msg.sender].WithdrawReward);
        user.DepositeToken = 0;
        }
        else if (now > user.lastUpdated && user.DepositeToken > 0){
            user.rewarddays = uint256(testTime/ TimeToGetReward);
        daysreward = (user.rewarddays.mul(perday).div(100)).mul(user.DepositeToken).div(1E18);
        Users[msg.sender].totalreward += daysreward.sub(user.totalreward);
        user.totalreward += daysreward.sub(user.totalreward);
        user.lastUpdated += TimeToGetReward;
         Users[msg.sender].WithdrawAbleReward = Users[msg.sender].totalreward.sub(Users[msg.sender].WithdrawReward);
        }
        }
        return Users[msg.sender].WithdrawAbleReward;
    }
    
        function Reward_without_locking() public returns(uint256)
    {
        for(uint256 x=0 ; x < deposit.length;x++){
        UserInfo storage user = withoutlocking[msg.sender][x];
        require( UsersWithoutlocking[msg.sender].withoutlockingamount  > 0, " Deposite not ");
        uint256 daysreward;
        uint256 perday = ((allocation[0].mul(1E18))).div(365);
        uint256 testTime = uint40(block.timestamp.sub(user.depositeTime));

         if (now > user.lastUpdated &&  user.withoutlockingamount > 0){
            user.rewarddays = uint256(testTime/ TimeToGetReward);
        daysreward = (user.rewarddays.mul(perday).div(100)).mul(user.withoutlockingamount).div(1E18);
        UsersWithoutlocking[msg.sender].totalreward += daysreward.sub(user.totalreward);
        user.totalreward += daysreward.sub(user.totalreward);
        user.lastUpdated += TimeToGetReward;
         UsersWithoutlocking[msg.sender].WithdrawAbleReward = UsersWithoutlocking[msg.sender].totalreward.sub(UsersWithoutlocking[msg.sender].WithdrawReward);
        }
        }
        return UsersWithoutlocking[msg.sender].WithdrawAbleReward;
    }

    function check_reward(uint256 _days,uint256 _amount) public view returns(uint256){
        uint256 perday = ((allocation[_days].mul(1E18))).div(365);
        uint256 _reward = (_days.mul(perday).div(100)).mul(_amount).div(1E18);
        return _reward;
    }

    function WithdrawReward(uint256 _amount) public {
        userInfo storage user = Users[msg.sender];
            require(user.WithdrawAbleReward > 0 , "No Reward Balance found" );
            require(_amount >=  Meximum_reward_withraw , "Minimum 10 sms withdraw" );
            require(now >  user.Time_to_next_withraw , " withdraw next day" );
            SMS.transfer(msg.sender, _amount);
             user.WithdrawReward =user.WithdrawReward.add(_amount);
             user.WithdrawAbleReward = user.WithdrawAbleReward.sub(_amount);
             user.Time_to_next_withraw =uint40(block.timestamp) + time_to_next_withraw;
             emit Withdraw_Reward(msg.sender,_amount,uint40(block.timestamp));
    }

    function WithdrawReward_withlocking(uint256 _amount) public {
        UserInfo storage user = UsersWithoutlocking[msg.sender];
            require(user.WithdrawAbleReward > 0 , "No Reward Balance found" );
            require(_amount >=  Meximum_reward_withraw , "Minimum 10 sms withdraw" );
            require(now >  user.Time_to_next_withraw , " withdraw next day" );
            SMS.transfer(msg.sender, _amount);
             user.WithdrawReward =user.WithdrawReward.add(_amount);
             user.WithdrawAbleReward = user.WithdrawAbleReward.sub(_amount);
             user.Time_to_next_withraw =uint40(block.timestamp) + time_to_next_withraw;
             emit Withdraw_Reward(msg.sender,_amount,uint40(block.timestamp));
    }    
    
    
     function Withdraw_Staking_Amount() public {
         
        userInfo storage user = Users[msg.sender];
        require(OwnerFee > 0 , "Set OwnerFee" );
        require(Users[msg.sender].withrawableDepositeAmount > 0 , "No deposite Balance found" );
        require(user.WithdrawAbleReward  == 0 , "Withdraw your Reward first" );
        uint256 ownerfee = (OwnerFee*Users[msg.sender].withrawableDepositeAmount/100).div(1E18);
        uint256 withdrawableAmount = user.DepositeToken.sub(ownerfee);
        SMS.transfer(msg.sender,withdrawableAmount);
        Users[msg.sender].DepositeToken=Users[msg.sender].DepositeToken.sub(Users[msg.sender].withrawableDepositeAmount);
        Users[msg.sender].withrawableDepositeAmount = 0;
        emit Withdraw_Staking(msg.sender,withdrawableAmount,uint40(block.timestamp),ownerfee);
     }

        function Withdraw_without_Staking_Amount() public {
         
        UserInfo storage user = UsersWithoutlocking[msg.sender];
        require(OwnerFee > 0 , "Set OwnerFee" );
        require(UsersWithoutlocking[msg.sender].withoutlockingamount > 0 , "No deposite Balance found" );
        require(user.WithdrawAbleReward  == 0 , "Withdraw your Reward first" );
        uint256 ownerfee = (OwnerFee*UsersWithoutlocking[msg.sender].withoutlockingamount/100).div(1E18);
        uint256 withdrawableAmount = UsersWithoutlocking[msg.sender].withoutlockingamount.sub(ownerfee);
        SMS.transfer(msg.sender,withdrawableAmount);
        UsersWithoutlocking[msg.sender].withoutlockingamount = 0;
        removeamount();
        emit Withdraw_Staking(msg.sender,withdrawableAmount,uint40(block.timestamp),ownerfee);
    }
    
    
            function removeamount() private 
    {
        for(uint256 x=0 ; x < deposit.length;x++){
        UserInfo storage user = withoutlocking[msg.sender][x];
         user.withoutlockingamount=0;
        }
    }
   
 
     // EMERGENCY ONLY onlyOwner.
    function SetOwnerfee(uint256 _amount) public onlyOwner{
        OwnerFee = _amount;
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