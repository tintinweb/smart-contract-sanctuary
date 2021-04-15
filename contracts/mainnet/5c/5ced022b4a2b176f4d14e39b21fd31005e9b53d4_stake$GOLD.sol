/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;



abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------


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
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    
    function calculateFeesBeforeSend(
        address sender,
        address recipient,
        uint256 amount
    ) external view returns (uint256, uint256);
    
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface regreward {
    function distributeAll() external;
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole is Owned  {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

   constructor () {
        _addWhitelistAdmin(msg.sender);
    }
    
    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }
    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    } 

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}
contract stake$GOLD is Owned, ReentrancyGuard, WhitelistAdminRole {
    using SafeMath for uint256;
    
    address public $GOLD   = 0xf1b8762a7fa8C244e36F7234EDF40cFaE24394e3;
    address public fETH   = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public regrewardContract;
    
    uint256 public totalStakes = 0;
    bool public perform = false; //if true then distribution of rewards from the pool to stakers via the withdraw function is enabled
    uint256 public txFee = 0; // $GOLD has 2% TX fee, deduct this fee from total stake to not break math
    uint256 public txFee1 = 11; // fETH has 1% TX fee, 0.1% was also added this fee from total stake to not break math
    
    uint256 public totalDividends = 0;
    uint256 private scaledRemainder = 0;
    uint256 private scaling = uint256(10) ** 12;
    uint public round = 1;
 
    mapping(address => uint) public farmTime; // period that your sake it locked to keep it for farming
    uint public lock = 0; // no locktime
    
    struct USER{
        uint256 stakedTokens;
        uint256 lastDividends;
        uint256 fromTotalDividend;
        uint round;
        uint256 remainder;
    }
    
    address[] internal stakeholders;
    mapping(address => USER) stakers;
    mapping (uint => uint256) public payouts;                   // keeps record of each payout
    
    event STAKED(address staker, uint256 tokens);
    event EARNED(address staker, uint256 tokens);
    event UNSTAKED(address staker, uint256 tokens);
    event PAYOUT(uint256 round, uint256 tokens, address sender);
    event CLAIMEDREWARD(address staker, uint256 reward);
    
    
    function isStakeholder(address _address)
       public
       view
       returns(bool)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true);
       }
       return (false);
   }
   
   function addStakeholder(address _stakeholder)
       public
   {
       (bool _isStakeholder) = isStakeholder(_stakeholder);
       if(!_isStakeholder) {
           stakeholders.push(_stakeholder);
           farmTime[msg.sender] =  block.timestamp;
       }
   }
   
   // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE(uint256 tokens) external nonReentrant { 
        require(IERC20($GOLD).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user for locking");
        
            uint256 transferTxFee = (onePercent(tokens).mul(txFee)).div(10);
            uint256 tokensToStake = (tokens.sub(transferTxFee));
        
            
            // add pending rewards to remainder to be claimed by user later, if there is any existing stake
            uint256 owing = pendingReward(msg.sender);
            stakers[msg.sender].remainder += owing;
            
            stakers[msg.sender].stakedTokens = tokensToStake.add(stakers[msg.sender].stakedTokens);
            stakers[msg.sender].lastDividends = owing;
            stakers[msg.sender].fromTotalDividend= totalDividends;
            stakers[msg.sender].round =  round;
            
            
            totalStakes = totalStakes.add(tokensToStake);
            
            addStakeholder(msg.sender);
            
            emit STAKED(msg.sender, tokens);
        
    }
    
    // ------------------------------------------------------------------------
    // Owners can send the funds to be distributed to stakers using this function
    // @param tokens number of tokens to distribute
    // ------------------------------------------------------------------------
    function ADDFUNDS(uint256 tokens) external onlyWhitelistAdmin{ //can only be called by regrewardContract
        uint256 transferTxFee = (onePercent(tokens).mul(txFee1)).div(10);
        uint256 tokens_ = (tokens.sub(transferTxFee));
        
        _addPayout(tokens_);
    }
    
    function ADDFUNDS1(uint256 tokens) external{
        require(IERC20(fETH).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        uint256 transferTxFee = (onePercent(tokens).mul(txFee1)).div(10);
        uint256 tokens_ = (tokens.sub(transferTxFee));
        
        _addPayout(tokens_);
    }
    
    
    
    
    function DisributeTxFunds() external { // Distribute tx fees collected for conversion into rewards
        
        uint256 transferToAmount = (IERC20($GOLD).balanceOf(address(this))).sub(totalStakes);
        require(IERC20($GOLD).transfer(address(owner), transferToAmount), "Error in un-staking tokens");
    }
    
    
    // ------------------------------------------------------------------------
    // Private function to register payouts
    // ------------------------------------------------------------------------
    function _addPayout(uint256 tokens_) private{
        // divide the funds among the currently staked tokens
        // scale the deposit and add the previous remainder
        uint256 available = (tokens_.mul(scaling)).add(scaledRemainder); 
        uint256 dividendPerToken = available.div(totalStakes);
        scaledRemainder = available.mod(totalStakes);
        
        totalDividends = totalDividends.add(dividendPerToken);
        payouts[round] = payouts[round - 1].add(dividendPerToken);
        
        emit PAYOUT(round, tokens_, msg.sender);
        round++;
    }
    
    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public nonReentrant{
        
        if(totalDividends > stakers[msg.sender].fromTotalDividend){
            uint256 owing = pendingReward(msg.sender);
        
            owing = owing.add(stakers[msg.sender].remainder);
            stakers[msg.sender].remainder = 0;
        
            require(IERC20(fETH).transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
        
            emit CLAIMEDREWARD(msg.sender, owing);
        
            stakers[msg.sender].lastDividends = owing; // unscaled
            stakers[msg.sender].round = round; // update the round
            stakers[msg.sender].fromTotalDividend = totalDividends; // scaled
        }
    }
    
    // ------------------------------------------------------------------------
    // Get the pending rewards of the staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------    
    function pendingReward(address staker) private returns (uint256) {
        require(staker != address(0), "ERC20: sending to the zero address");
        
        uint stakersRound = stakers[staker].round;
        uint256 amount =  ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)).div(scaling);
        stakers[staker].remainder += ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)) % scaling ;
        return amount;
    }
    
    function getPendingReward(address staker) public view returns(uint256 _pendingReward) {
        require(staker != address(0), "ERC20: sending to the zero address");
         uint stakersRound = stakers[staker].round;
         
        uint256 amount =  ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)).div(scaling);
        amount += ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)) % scaling ;
        return (amount.add(stakers[staker].remainder));
    }
    
    // ------------------------------------------------------------------------
    // Stakers can un stake the staked tokens using this function
    // @param tokens the number of tokens to withdraw
    // ------------------------------------------------------------------------
    function WITHDRAW(uint256 tokens) external nonReentrant{
        require(stakers[msg.sender].stakedTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        totalStakes = totalStakes.sub(tokens);
        
        // add pending rewards to remainder to be claimed by user later, if there is any existing stake
        uint256 owing = pendingReward(msg.sender);
        stakers[msg.sender].remainder += owing;
                
        stakers[msg.sender].stakedTokens = stakers[msg.sender].stakedTokens.sub(tokens);
        stakers[msg.sender].lastDividends = owing;
        stakers[msg.sender].fromTotalDividend= totalDividends;
        stakers[msg.sender].round =  round;
        
        
        require(IERC20($GOLD).transfer(msg.sender, tokens), "Error in un-staking tokens");
        emit UNSTAKED(msg.sender, tokens);
        
        if(perform==true) {
        regreward(regrewardContract).distributeAll();
        }
    }
    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the number of tokens staked by a staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------
    function yourStaked$GOLD(address staker) public view returns(uint256 staked$GOLD){
        require(staker != address(0), "ERC20: sending to the zero address");
        
        return stakers[staker].stakedTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the $GOLD balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function your$GOLDBalance(address user) external view returns(uint256 $GOLDBalance){
        require(user != address(0), "ERC20: sending to the zero address");
        return IERC20($GOLD).balanceOf(user);
    }
    
    function emergencySaveLostTokens(address _token) public onlyOwner {
        require(IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this))), "Error in retrieving tokens");
        owner.transfer(address(this).balance);
    }
    
    function changeregrewardContract(address _regrewardContract) external onlyOwner{
        require(address(_regrewardContract) != address(0), "setting 0 to contract");
        regrewardContract = _regrewardContract;
    }
   
   function changePerform(bool _bool) external onlyOwner{
        perform = _bool;
    }
}