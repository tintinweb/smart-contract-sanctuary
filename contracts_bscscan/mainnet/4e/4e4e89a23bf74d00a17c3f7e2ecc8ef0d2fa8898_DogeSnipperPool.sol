/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "./TransferHelper.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value)
        external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

contract DogeSnipperPool  {

    using SafeMath for uint256;
    mapping(uint => address[]) private voterList; // List of dogecoin voters.
    
    uint256 private sessionExpireTokenLimit = 100000000000 * (10**9);  // Pot limit for tokens
    uint256 private voteAmount = 1000000000 * (10**9);  //  Charges per vote 
    uint private voteSessionID = 1;   // session ID
    address private _burnTokenWallet;   // burn wallet address for 40% tokens
    uint private startSession;   // session start time
    uint private SessionExpireTime = 3 days;   // Session time configuration.
    address public _owner; 
    address public lastWinner; // last winner user address

    mapping(uint => address) public getWinner;
    mapping(uint => uint256) public getWinnerAmount;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    IERC20 token = IERC20(0xA908417Aa4d77C60A3359dF7545B5A589118786f); // interface of sonofdoge token
   
    constructor (address burnTokenWallet, address owner){
     _burnTokenWallet = burnTokenWallet;
     _owner = owner;
    }

    // getting burn wallet
    function getBurnTokenWallet() view public returns(address) {
        return _burnTokenWallet;
    }  

    // session expire time
    function getSessionExpireTime() view public returns (uint) {
        return SessionExpireTime;
    }

    // getting expire token limit of voting 
    function getSessionExpireTokenLimit() view public returns (uint) {
        return sessionExpireTokenLimit;
    }

    // getting per vot price
    function getVotePrice() view public returns (uint){
        return voteAmount;
    }


    // Update wallet for burn tokens
    function updateBurnTokenWallet(address _wallet) onlyOwner public {
         _burnTokenWallet = _wallet;
    }

    // Update sesssion expire time
    function updateSessionExpireTime(uint newtime) onlyOwner public {
        SessionExpireTime = newtime;
    }

    // upodate session expire token limit
    function updateSessionExpireTokenLimit(uint256 _token) onlyOwner public {
        sessionExpireTokenLimit = _token;
    }

    // change per vot price in sonofdoge
    function updateVotePrice(uint256 _token) onlyOwner public {
        voteAmount = _token;
    }


    // change contract owner address for manage permission
    function changeOnwer(address newOwner) onlyOwner public {
        _owner = newOwner;
    }



    // Using this function for new vote, it's payable function in sonofdoge.
    function newVote(uint256 tokenAmount) public  {
        
        require(tokenAmount <= uint256(IERC20(token).allowance(msg.sender,address(this))) , "Insufficient allowance");
        require(uint256(tokenAmount) <= uint256(IERC20(token).balanceOf(msg.sender)), "Insufficient Token Balance" );
        require(uint256(tokenAmount) >= uint256(voteAmount), "Insufficient Token Amount For Vote" );

        IERC20(token).transferFrom(msg.sender,address(this),tokenAmount);
        if(voterList[voteSessionID].length == 0 && voteSessionID == 1){
            startSession = block.timestamp;
        }
        voterList[voteSessionID].push(msg.sender);        
    }
    
    // This function using for find random user for lottery 
    function randomnumber() view private returns (uint){
        uint MaxNumber = voterList[voteSessionID].length;
        uint random = uint(keccak256(abi.encode(block.timestamp))) % MaxNumber;
        return  random;
    }
  

    // session expire after time limit
    function voteDeclared()  public  onlyOwner returns(address newWinner,uint256 wonAmount) {
        uint256 poolTokenBalance = IERC20(token).balanceOf(address(this));
        if((sessionExpireTokenLimit > poolTokenBalance) && (uint(block.timestamp).sub(uint(startSession)) < uint(SessionExpireTime))) revert("Not eligible for lottery");
       
       address winner = voterList[voteSessionID][randomnumber()];
       uint256 winnerAmount;
       
       if(poolTokenBalance > 0){
        winnerAmount = ((poolTokenBalance).mul(60)).div(100);
        IERC20(token).transfer(winner,winnerAmount);
        IERC20(token).transfer(_burnTokenWallet,((poolTokenBalance).mul(40)).div(100));
       }
        lastWinner = winner; // update winner
        
        getWinner[voteSessionID] = winner;
        getWinnerAmount[voteSessionID] = winnerAmount;

        voteSessionID++;
        startSession = block.timestamp;
        return (winner,winnerAmount);
        
    } 
}



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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}