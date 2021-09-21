/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

//SPDX-License-Identifier: none
pragma solidity ^0.8.4;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function burn(uint _amount) external;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract GamezillaStaking {
    using SafeMath for uint;
    
    // Variables
    address private owner;
    uint private percent;
    uint private endTime;
    uint private stakedUsers;
    uint public burnPercent;
    address private contractAddr = address(this);
    
    BEP20 token;
    
    struct Stake {
        uint[] amounts;
        uint[] stakedAt;
        uint[] withdrawnRoi;
        bool[] status;
    }
    
    mapping(address => Stake) user;
    mapping(address => bool) public stakeStatus;
    mapping(address => uint) public userStakeNum;
    
    event Staked(address from, uint amount, uint time);
    event OwnershipTransferred(address to);
    event Received(address, uint);
    event Unstaked(address, uint);
    
    // Constructor to set initial values for contract
    constructor() {
        owner = msg.sender;
        percent = 20000;
        endTime = 36500 days;
        burnPercent = 10;
        // token = BEP20(0xc45575efc915ACf2d3a34B3eC099a8699c40744E); // Mainnet BGLG token
        token = BEP20(0xA1dEf3455B10F7567837aE8Bc1036e64F84e4096); // Testnet token
    }
    
    // Modifier 
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Stake function 
    function stake(uint _amount) public {
        address sender = msg.sender;
        
        require(token.balanceOf(sender) >= _amount, "Insufficient balance of user");
        
        user[sender].amounts.push(_amount);
        user[sender].stakedAt.push(block.timestamp);
        user[sender].status.push(true);
        user[sender].withdrawnRoi.push(0);
        userStakeNum[sender] += 1;
        
        if(stakeStatus[sender] != true){
            stakeStatus[sender] == true;
            stakedUsers += 1;
        }
        
        token.transferFrom(sender, contractAddr, _amount);
        emit Staked(sender, _amount, block.timestamp);
    }
    
    // View withdrawable amount 
    function withdrawable(address addr, uint index) public view returns (uint reward) {
        Stake storage stk = user[addr];
        if(stk.status[index] == true){
            uint end = stk.stakedAt[index] + endTime;
            uint since = stk.stakedAt[index];
            uint till = block.timestamp > end ? end : block.timestamp;
            reward = stk.amounts[index].mul(till.sub(since)).mul(percent).div(endTime).div(100);
            reward = reward.sub(stk.withdrawnRoi[index]);
        }
        else{
            reward = 0;
        }
        return reward;
    }
    
    // Withdraw ROI 
    function withdrawRoi(uint index) public {
        address rec = msg.sender;
        Stake storage stk = user[rec];
        require(stk.status[index] == true, "User has not staked or has unstaked");
        uint amount = withdrawable(rec, index);
        uint burnAmt = amount.mul(burnPercent).div(100);
        uint sendAmt = amount.sub(burnAmt);
        
        require(token.balanceOf(contractAddr) >= sendAmt, "Insufficient balance on contract");
        stk.withdrawnRoi[index] = stk.withdrawnRoi[index].add(amount);
        token.transfer(rec, sendAmt);
        token.burn(burnAmt);
    }
    
    // Unstake function 
    function unstake(uint index) public {
        address receiver = msg.sender;
        Stake storage stk = user[receiver];
        require(stk.status[index] == true, "Not staked or already unstaked");
        uint totalAmount = stk.amounts[index].add(withdrawable(receiver, index));
        uint burnAmt = totalAmount.mul(burnPercent).div(100);
        uint sendAmt = totalAmount.sub(burnAmt);
        
        require(token.balanceOf(contractAddr) >= sendAmt, "Insufficient balance on contract");
        token.transfer(receiver, sendAmt);
        token.burn(burnAmt);
        userStakeNum[receiver] -= 1;
        stk.status[index] = false;
        emit Unstaked(receiver, totalAmount);
    }
    
    // Set burnPercent
    // Only owner can call this function
    function setBurnPercent(uint _perc) public onlyOwner {
        burnPercent = _perc;
    }
    
    // View user details
    function details(address addr) public view returns(uint[] memory amount, uint[] memory time, bool[] memory stat) {
        Stake storage stk = user[addr];
        uint length = stk.amounts.length;
        amount = new uint[](length);
        time = new uint[](length);
        stat = new bool[](length);
        
        for(uint i = 0; i < length; i++){
            amount[i] = stk.amounts[i];
            time[i] = stk.stakedAt[i];
            stat[i] = stk.status[i];
        }
        return (amount, time, stat);
    }
    
    // View owner
    function getOwner() public view returns (address) {
        return owner;
    }
    
    
    // View number of user who have staked on this contract
    function getStakedUserCount() public view returns (uint) {
        return stakedUsers;
    }
    
    // Transfer ownership 
    // Only owner can do that
    function ownershipTransfer(address to) public onlyOwner {
        require(to != address(0), "Zero address error");
        owner = to;
        emit OwnershipTransferred(to);
    }
    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) public onlyOwner {
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }
    
    // Owner BNB withdrawal
    function ownerBnbWithdraw(uint amount) public onlyOwner {
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}