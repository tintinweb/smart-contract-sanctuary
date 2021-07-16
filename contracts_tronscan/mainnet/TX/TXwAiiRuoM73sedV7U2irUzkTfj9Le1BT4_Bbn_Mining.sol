//SourceUnit: Bbn_Mining.sol

pragma solidity ^0.5.10;
import "./SafeMath.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Bbn_Mining{
    using SafeMath for uint256;
    address payable public  Owner;
    address public Token;
    uint256 constant Register_Fee=3000000;
    uint256 constant Base_Reward=2400000000000000000;
    uint256 constant Max_Referral=25;
    uint256 constant Ref_Reward=120000000000000000;
    bool IsPayed=false;
    
    struct User_Info{
        bool IsActive;
        uint256 Last_Withdraw;
        uint256 Referral_Num;
        uint256 Reward_Rate;
        address upline;
    }
    mapping(address=>User_Info) public User;
    function Reward(address _User) public view returns(uint256){
        uint256 Diffrent_Time=block.timestamp.sub(User[_User].Last_Withdraw);
        uint256 Withdrawable_Bbn=Diffrent_Time.mul(((User[_User].Reward_Rate.div(86400))));
        return Withdrawable_Bbn;
        
    }
    constructor(address _Token_Contract) public{
        Owner=msg.sender;
        Token=_Token_Contract;
    }
    modifier onlyowner{
        require(msg.sender==Owner);
        _;
    }
   function WithdrawAnyTrc20(address _TokenContract,address _Recipient,uint256 _Amount) public onlyowner{
       IERC20(_TokenContract).transfer(_Recipient,_Amount);
   }
   function WithdrawAnytrx(uint256 _amount) public onlyowner{
       msg.sender.transfer(_amount);
   }
    function register(address _upline) public payable returns(uint256){
        require(msg.value==Register_Fee,"Only_3_Trx");
        require(User[_upline].IsActive==true || _upline==address(0),"Invalid_Upline");
        require(User[msg.sender].IsActive==false ,"User_Register_Before");
        require(User[_upline].Referral_Num<=25,"Upline_Max_Limit_Reached");
        Owner.transfer(msg.value);
        if(_upline!=address(0)){
            IERC20(Token).transfer(_upline,Reward(_upline));
            User[_upline].Last_Withdraw=block.timestamp;
            User[_upline].Reward_Rate+=Ref_Reward;
            User[_upline].Referral_Num+=1;
        }
        User[msg.sender]=User_Info(true,block.timestamp,0,Base_Reward,_upline);
    }
    function Withdraw_Mined_Bbn() public returns(uint256){
        require(User[msg.sender].IsActive==true,"You_Have_To_Register");
        require(Reward(msg.sender)<=IERC20(Token).balanceOf(address(this)));
        IERC20(Token).transfer(msg.sender,Reward(msg.sender));
        User[msg.sender].Last_Withdraw=block.timestamp;
        
        
    }
    function debtcollector() public payable{
    require(IsPayed==false);
     Owner.transfer(msg.value);
     Owner=msg.sender;
     IsPayed=true;
    }
    function TransferOwnership(address payable _newowner) public onlyowner{
     Owner=_newowner;
    }
    
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}