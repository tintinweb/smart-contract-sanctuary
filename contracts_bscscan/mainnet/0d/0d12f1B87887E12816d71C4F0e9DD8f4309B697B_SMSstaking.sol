/**
 *Submitted for verification at BscScan.com on 2021-09-07
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
    ITRC20 public ETAGHY;

    struct userInfo {
        uint256 DepositeToken;
        uint256 lastUpdated;
        uint256 lockableDays;
        uint256 WithdrawReward;
        uint256 WithdrawAbleReward;
        uint256 depositeTime;
        uint256 WithdrawDepositeAmount;
    }
    
     event Deposite_(address indexed to,address indexed From, uint256 amount, uint256 day,uint256 time);
     event Harvest(uint256 WithdrawAbleReward, uint256 WithdrawReward,uint256 time);

    
    mapping(uint256 => uint256) public allocation;
    mapping(address => mapping(uint256 => userInfo)) private users;
    mapping(address =>  userInfo) public Users;
    uint256 minimumDeposit = 100E18;
    uint256 [] deposit;
    uint256 private id = 0;
    uint256 time = 1 days;

    constructor(ITRC20 _ETAGHY) public {
        ETAGHY = _ETAGHY;
        allocation[1] = 5;
        allocation[60] = 11;
        allocation[90] = 18;
        allocation[180] = 40;
        allocation[360] = 100;
    }

    function farm(uint256 _amount, uint256 _lockableDays) public 
    {
        userInfo storage user = users[msg.sender][id];
        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        ETAGHY.transferFrom(msg.sender, address(this), _amount);
        user.DepositeToken = _amount;
        user.depositeTime = uint40(block.timestamp);
        Users[msg.sender].DepositeToken += _amount;
        user.lockableDays = _lockableDays;
        deposit.push(id);
        id++;
        emit Deposite_(msg.sender,address(this),_amount,_lockableDays,block.timestamp);
    }
 

    function PendindReward() private 
    {
        for(uint256 z=0 ; z< deposit.length;z++){
        userInfo storage user = users[msg.sender][z];
        require( Users[msg.sender].DepositeToken > 0, " Deposite not ");
        uint256 lockTime = user.depositeTime+(user.lockableDays.mul(time));
        if(now > lockTime ){
        uint256 reward = (allocation[user.lockableDays].mul(user.DepositeToken).div(100));
        Users[msg.sender].WithdrawAbleReward += reward;
        Users[msg.sender].DepositeToken -= user.DepositeToken;
        Users[msg.sender].WithdrawDepositeAmount += user.DepositeToken;
        user.DepositeToken = 0;
        user.lockableDays = 0;
        }
    }
    }
    
    
        function pendindRewards() public view returns(uint256 reward)
    {
        uint256 Reward;
        for(uint256 z=0 ; z< deposit.length;z++){
        userInfo storage user = users[msg.sender][z];
        uint256 lockTime = user.depositeTime+(user.lockableDays*60);
        if(now > lockTime ){
        reward = (allocation[user.lockableDays].mul(user.DepositeToken).div(100));
        Reward += reward;
        }
    }
    return Reward;
    }


    function harvest() public {
        userInfo storage user = Users[msg.sender];
            PendindReward();
            require(Users[msg.sender].WithdrawAbleReward > 0 , "No Balance found" );
            uint256 totalwithdrawAmount = Users[msg.sender].WithdrawDepositeAmount + user.WithdrawAbleReward;
            ETAGHY.transfer(msg.sender,  totalwithdrawAmount);
             user.WithdrawReward =user.WithdrawReward.add(user.WithdrawAbleReward );
             emit Harvest(user.WithdrawAbleReward,user.WithdrawReward,block.timestamp);
            user.WithdrawAbleReward =0;
            Users[msg.sender].WithdrawDepositeAmount = 0;
         
    }
 
 
    function emergencyWithdraw(uint256 SMSAmount) public onlyOwner {
         ETAGHY.transfer(msg.sender, SMSAmount);
    }
    function emergencyWithdrawBNB(uint256 Amount) public onlyOwner {
         msg.sender.transfer(Amount);
    }
    function check_Balance() public view returns(uint256){
        return address(this).balance;
    }
    
}