/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-02
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

contract MonoFarm is Ownable{
    using SafeMath for uint256;
    ITRC20 public bostincoin;

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

    
    mapping(uint256 => uint256) public allocation;
    mapping(address => uint256[] ) public depositeToken;
    mapping(address => uint256[] ) public lockabledays;
    mapping(address => uint256[] ) public depositetime;   
    mapping(address =>  userInfo) public Users;
    uint256 minimumDeposit = 50E18;
    uint256 private id = 0;
    uint256 time = 1 days;

    constructor(ITRC20 _WORTHWHILE) public {
        bostincoin = _WORTHWHILE;
        allocation[1] = 2;
        allocation[30] = 7;
        allocation[60] = 15;
        allocation[90] = 20;
        allocation[180] = 40;
        allocation[365] = 100;
    }

    function farm(uint256 _amount, uint256 _lockableDays) public 
    {
        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        bostincoin.transferFrom(msg.sender, address(this), _amount);
        depositeToken[msg.sender].push(_amount);
        depositetime[msg.sender].push(uint40(block.timestamp));
        Users[msg.sender].DepositeToken += _amount;
        lockabledays[msg.sender].push(_lockableDays);
        emit Deposite_(msg.sender,address(this),_amount,_lockableDays,block.timestamp);
    }
    
        function pendindRewards(address _add) public view returns(uint256 reward)
    {
        uint256 Reward;
        for(uint256 z=0 ; z< depositeToken[_add].length;z++){
        uint256 lockTime = depositetime[_add][z]+(lockabledays[_add][z]*time);
        if(now > lockTime ){
        reward = (allocation[lockabledays[_add][z]].mul(depositeToken[_add][z]).div(100));
        Reward += reward;
        }
    }
    return Reward;
    }

  
    
    
    function harvest(uint256 [] memory _index) public 
    {
          for(uint256 z=0 ; z< _index.length;z++){
              
        require( Users[msg.sender].DepositeToken > 0, " Deposite not ");
        
        uint256 lockTime =depositetime[msg.sender][_index[z]]+(lockabledays[msg.sender][_index[z]].mul(time));
        if(now > lockTime ){
        uint256 reward = (allocation[lockabledays[msg.sender][_index[z]]].mul(depositeToken[msg.sender][_index[z]]).div(100));
        
        Users[msg.sender].WithdrawAbleReward += reward;
        Users[msg.sender].DepositeToken -= depositeToken[msg.sender][_index[z]];
        Users[msg.sender].WithdrawDepositeAmount += depositeToken[msg.sender][_index[z]];
        depositeToken[msg.sender][_index[z]] = 0;
        lockabledays[msg.sender][_index[z]] = 0;
        depositetime[msg.sender][_index[z]] = 0;
    }
    }
            for(uint256 t=0 ; t< _index.length;t++){
            for(uint256 i = _index[t]; i <  depositeToken[msg.sender].length - 1; i++) 
        {
            depositeToken[msg.sender][i] = depositeToken[msg.sender][i + 1];
            lockabledays[msg.sender][i] = lockabledays[msg.sender][i + 1];
            depositetime[msg.sender][i] = depositetime[msg.sender][i + 1];
        }
          depositeToken[msg.sender].pop();
          lockabledays[msg.sender].pop();
          depositetime[msg.sender].pop();
    }
             uint256 totalwithdrawAmount;
            
             require(Users[msg.sender].WithdrawAbleReward > 0 , "No Balance found" );
             
             totalwithdrawAmount = Users[msg.sender].WithdrawDepositeAmount.add(Users[msg.sender].WithdrawAbleReward);
             bostincoin.transfer(msg.sender,  totalwithdrawAmount);
             Users[msg.sender].WithdrawReward =Users[msg.sender].WithdrawReward.add(Users[msg.sender].WithdrawAbleReward );
             
            //  emit Harvest(Users[msg.sender].WithdrawAbleReward,Users[msg.sender].WithdrawReward,block.timestamp);
             Users[msg.sender].WithdrawAbleReward =0;
             Users[msg.sender].WithdrawDepositeAmount = 0;
         
    }
    
    function UserInfomation(address _add) public view returns(uint256 [] memory , uint256 [] memory,uint256 [] memory){
        return(depositeToken[_add],lockabledays[_add],depositetime[_add]);
    }
 
 
    function emergencyWithdraw(uint256 WORTHWHILEAmount) public onlyOwner {
         bostincoin.transfer(msg.sender, WORTHWHILEAmount);
    }
    function emergencyWithdrawBNB(uint256 Amount) public onlyOwner {
         msg.sender.transfer(Amount);
    }
    
}