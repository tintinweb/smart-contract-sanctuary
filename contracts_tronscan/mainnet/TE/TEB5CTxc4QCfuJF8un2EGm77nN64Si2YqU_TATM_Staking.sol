//SourceUnit: TATM_Staking&Rewards.sol

pragma solidity >=0.4.23 <0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
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
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface TokenContract {
   function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external  returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract  TATM_Staking{
   using SafeMath for uint256;
   address owner;
   address tokenContract;

   address tokenContractAddress;

   mapping(address => uint256) joined;
   mapping(address => uint256) timeToUnfreeze;
   mapping(address => uint256) totalStaked;
   uint256 public freezeTimer = 2629743;  // Epoch counter for 30 days
   uint256 public daysElapsed = 7;
   uint256 public interest = 1;
   mapping(address => uint256) withdrawable;
   mapping(address => uint256) withdrawn;

   event Staked(address addr, uint256 amount, uint256 stakingTime);
   event UnStaked(address addr, uint256 amount, uint256 unstakingTime);
   event Withdraw(address addr, uint256 amount);

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(address _tokenContractAddress) public {
        tokenContractAddress = _tokenContractAddress;
        owner = msg.sender;
    }

    function stake(uint256 value) public returns(bool success) {
        address self = address(this);
        if (totalStaked[msg.sender] > 0){
           if (claimStakingReward()){
               withdrawable[msg.sender] = 0;
           }
       }
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        // requires approving before in ui.
        totalStaked[msg.sender] = totalStaked[msg.sender].add(value);
        joined[msg.sender] = block.timestamp;
        timeToUnfreeze[msg.sender] = block.timestamp.add(freezeTimer);

        tokencontract.transferFrom(msg.sender,self,value);

        emit Staked(msg.sender,value,block.timestamp);
        return true;
    }

    function unStake() public returns(bool success){
        if(timeDone(msg.sender)){
        require(totalStaked[msg.sender] > 0);
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        tokencontract.transfer(msg.sender,totalStaked[msg.sender]);
        totalStaked[msg.sender] = 0;
        return true;
        }
    }

    function timeDone(address addr) public view returns(bool success){
         require(timeToUnfreeze[addr]>0);
         if(block.timestamp>timeToUnfreeze[addr])
            return true;
         else
            return false;
     }

     function joinedTime(address addr) public view returns(uint256 time){
         require(joined[addr]>0);
         return joined[addr];
     }

     function timeRemaining(address addr) public view returns(uint256 time){
         require(timeToUnfreeze[addr]>0);
         return timeToUnfreeze[addr].sub(block.timestamp);
     }

     function claimStakingReward() public returns(bool success){
        require(totalStaked[msg.sender] > 0);
        require(joined[msg.sender] > 0);
        uint256 balance = getBalance(msg.sender);
        if (balance > 0){
            withdrawable[msg.sender] = withdrawable[msg.sender].add(balance);
            withdrawn[msg.sender] = withdrawn[msg.sender].add(balance);
            TokenContract tokencontract = TokenContract(tokenContractAddress);
            tokencontract.transfer(msg.sender,balance);
			emit Withdraw(msg.sender, balance);
            return true;
        }
         else {
            return false;
        }
     }

     function getBalance(address addr) public view returns (uint256) {
        if(joined[addr]>0)
        {
            uint256 daysCount = now.sub(joined[addr]).div(1 days); // how many hours since joined
            uint256 percent = totalStaked[addr].mul(interest).div(100); // how much to return, step = 3 is 3% return
            uint256 difference = percent.mul(daysCount).div(daysElapsed); //  minuteselapse control the time for example 1 day to receive above interest
            uint256 balance = difference.sub(withdrawable[addr]); // calculate how much can withdraw now

            return balance;
        }else{
            return 0;
        }
    }

    function checkTATMRewards() public view returns (uint256) {
        return getBalance(msg.sender);
    }

    function rewardsWithdrawn(address staker) public view returns (uint256) {
        return withdrawn[staker];
    }

    function checkInvestments(address addr) public view returns (uint256) {
        return totalStaked[addr];
    }

    function changeInterest(uint256 _newInterest) public onlyOwner {
        require(_newInterest > 0, "should be a valid interest");
        interest = _newInterest;
    }

    function changeFreezeTime(uint256 _newFreezeTimer) public onlyOwner {
        require(_newFreezeTimer > 0, "should be a valid free time amount");
        freezeTimer = _newFreezeTimer;
    }

    function changeDaysElapsed(uint256 _newDaysElapsed) public onlyOwner {
        require(_newDaysElapsed > 0, "should be a valid days");
        daysElapsed = _newDaysElapsed;
    }
}