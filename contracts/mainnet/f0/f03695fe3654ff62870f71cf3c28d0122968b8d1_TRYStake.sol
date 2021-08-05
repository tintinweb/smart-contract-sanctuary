/**
 *Submitted for verification at Etherscan.io on 2021-01-01
*/

// SPDX-License-Identifier: UNLICENSED
/* TRYstake contract has a 5% withdrawal and deposit fee which distributes to all stakers, It also is rewarded 5% of all UNIswap sell fees.
*/
pragma solidity ^0.6.12;



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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract TRYStake is Owned {
    using SafeMath for uint256;
    
    address public TRY;
    uint256 public totalStakes = 0;
    uint256 stakingFee = 50; // 5%
    uint256 unstakingFee = 50; // 5% 
    uint256 public totalDividends = 0;
    uint256 private scaledRemainder = 0;
    uint256 private scaling = uint256(10) ** 12;
    uint public round = 1;
    
    struct USER{
        uint256 stakedTokens;
        uint256 lastDividends;
        uint256 fromTotalDividend;
        uint round;
        uint256 remainder;
    }
    
    mapping(address => USER) stakers;
    mapping (uint => uint256) public payouts;                   
    
    event STAKED(address staker, uint256 tokens, uint256 stakingFee);
    event UNSTAKED(address staker, uint256 tokens, uint256 unstakingFee);
    event PAYOUT(uint256 round, uint256 tokens, address sender);
    event CLAIMEDREWARD(address staker, uint256 reward);
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        
        return (size > 0);
    }
    
    function STAKE(uint256 tokens) external {
        require(IERC20(TRY).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        require( !(isContract(msg.sender)), 'inValid caller');
        uint256 _stakingFee = 0;
        if(totalStakes > 0)
            _stakingFee= (onePercent(tokens).mul(stakingFee)).div(10); 
        
        if(totalStakes > 0)
            _addPayout(_stakingFee);
            
        uint256 owing = pendingReward(msg.sender);
        stakers[msg.sender].remainder += owing;
        
        stakers[msg.sender].stakedTokens = (tokens.sub(_stakingFee)).add(stakers[msg.sender].stakedTokens);
        stakers[msg.sender].lastDividends = owing;
        stakers[msg.sender].fromTotalDividend= totalDividends;
        stakers[msg.sender].round =  round;
        
        totalStakes = totalStakes.add(tokens.sub(_stakingFee));
        
        emit STAKED(msg.sender, tokens.sub(_stakingFee), _stakingFee);
    }

    function addTRY(address _TRY) public onlyOwner {
        TRY = _TRY;  
    }

    function addStakingfee(uint256 _stakingFee) public onlyOwner {
        require(_stakingFee >= 100, "Cannot set over 10% stakingFee");  
        stakingFee = _stakingFee;  
    }

    function addUnStakingfee(uint256 _unstakingFee) public onlyOwner {
        require(_unstakingFee >= 100, "Cannot set over 10% unstakingFee");
        unstakingFee = _unstakingFee;  
    }
    function ADDFUNDS(uint256 tokens) external {
        require(IERC20(TRY).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        _addPayout(tokens);
    }
    
    function _addPayout(uint256 tokens) private{
        uint256 available = (tokens.mul(scaling)).add(scaledRemainder); 
        uint256 dividendPerToken = available.div(totalStakes);
        scaledRemainder = available.mod(totalStakes);
        
        totalDividends = totalDividends.add(dividendPerToken);
        payouts[round] = payouts[round-1].add(dividendPerToken);
        
        emit PAYOUT(round, tokens, msg.sender);
        round++;
    }

    function CLAIMREWARD() public {
        if(totalDividends > stakers[msg.sender].fromTotalDividend){
            uint256 owing = pendingReward(msg.sender);
        
            owing = owing.add(stakers[msg.sender].remainder);
            stakers[msg.sender].remainder = 0;
        
            require(IERC20(TRY).transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
        
            emit CLAIMEDREWARD(msg.sender, owing);
        
            stakers[msg.sender].lastDividends = owing; 
            stakers[msg.sender].round = round; 
            stakers[msg.sender].fromTotalDividend = totalDividends; 
        }
    }
    
    function pendingReward(address staker) private returns (uint256) {
        uint256 amount =  ((totalDividends.sub(payouts[stakers[staker].round - 1])).mul(stakers[staker].stakedTokens)).div(scaling);
        stakers[staker].remainder += ((totalDividends.sub(payouts[stakers[staker].round - 1])).mul(stakers[staker].stakedTokens)) % scaling ;
        return amount;
    }
    
    function getPendingReward(address staker) public view returns(uint256 _pendingReward) {
        uint256 amount =  ((totalDividends.sub(payouts[stakers[staker].round - 1])).mul(stakers[staker].stakedTokens)).div(scaling);
        amount += ((totalDividends.sub(payouts[stakers[staker].round - 1])).mul(stakers[staker].stakedTokens)) % scaling ;
        return (amount + stakers[staker].remainder);
    }
    
   function WITHDRAW(uint256 tokens) external {
        
        require(stakers[msg.sender].stakedTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        uint256 _unstakingFee = (onePercent(tokens).mul(unstakingFee)).div(10);
        
       uint256 owing = pendingReward(msg.sender);
        stakers[msg.sender].remainder += owing;
                
        require(IERC20(TRY).transfer(msg.sender, tokens.sub(_unstakingFee)), "Error in un-staking tokens");
        
        stakers[msg.sender].stakedTokens = stakers[msg.sender].stakedTokens.sub(tokens);
        stakers[msg.sender].lastDividends = owing;
        stakers[msg.sender].fromTotalDividend= totalDividends;
        stakers[msg.sender].round =  round;
        
        totalStakes = totalStakes.sub(tokens);
        
        if(totalStakes > 0)
            _addPayout(_unstakingFee);
        
        emit UNSTAKED(msg.sender, tokens.sub(_unstakingFee), _unstakingFee);
    }
    
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
   function yourStakedTRY(address staker) external view returns(uint256 stakedTRY){
        return stakers[staker].stakedTokens;
    }
        
     function yourTRYBalance(address user) external view returns(uint256 TRYBalance){
        return IERC20(TRY).balanceOf(user);
    }
}