/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.4.20;

 /**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AKSTAKE {
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    
    string public name                                      = "AKSTAKE";
    string public symbol                                    = "AKSTAKE";
	uint256 internal stakePer_                              = 5000000000000000000;
	uint256 public constant _totalsupply        		    = 100 * 10 ** 18;
    uint256 public stakingRequirement                       = 1e18;
    uint256 public stakingTime                              = 604800; // 7 days to seconds
    address public admin                                    = 0x6d21e65e8e7ef61e251d3d320efd9be1177f64ae;
    
   /*================================
    =            DATASETS            =
    ================================*/
    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal stakeBalanceLedger_;
    mapping(address => uint256) internal stakingTime_;
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    // Only admin function
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(admin == _customerAddress);
        _;
    }
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/

    // Transfer all tokens to admin
    function AKSTAKE() public {
        tokenBalanceLedger_[admin]        = _totalsupply;
        Transfer(0, admin, _totalsupply);
    }
    
    function() payable public {
        revert();
    }
    
    // Admin can change ROI percentage
    function changeStakePercent(uint256 stakePercent) onlyAdministrator() public {
        require(stakePercent > 0);
        stakePer_                           = stakePercent;
    }
    
    // Admin can change min staking requirement
    function setStakingRequirement(uint256 _amountOfTokens) onlyAdministrator() public {
        require(_amountOfTokens > 0);
        stakingRequirement                  = _amountOfTokens;
    }
   
    // Total token balance
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    // Stake tokens with 5% ROI
    function stakeTokens(uint256 _amountOfTokens) public returns(bool){
        address _customerAddress            = msg.sender;
        require(_amountOfTokens > stakingRequirement && tokenBalanceLedger_[_customerAddress] > stakingRequirement && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        require(stakingTime_[_customerAddress] == 0);
        stakingTime_[_customerAddress]      = now;
        stakeBalanceLedger_[_customerAddress] = SafeMath.add(stakeBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
    }
    
    // Staking balance with addition of 5% every 7th day
    function stakeTokensBalance(address _customerAddress) public view returns(uint256){
        uint256 timediff                    = SafeMath.sub(now, stakingTime_[_customerAddress]);
        uint256 dayscount                   = SafeMath.div(timediff, stakingTime);
        uint256 roiPercent                  = SafeMath.mul(dayscount, stakePer_);
        uint256 roiTokens                   = SafeMath.percent(stakeBalanceLedger_[_customerAddress],roiPercent,100,18);
        uint256 finalBalance                = SafeMath.add(stakeBalanceLedger_[_customerAddress],roiTokens/1e18);
        return finalBalance;
    }
    
    // Time of staking
    function stakeTokensTime(address _customerAddress) public view returns(uint256){
        return stakingTime_[_customerAddress];
    }
    
    // Release stake tokens with 5% ROI every 7th Day
    function releaseStake() public returns(bool){
        address _customerAddress            = msg.sender;
        require(stakingTime_[_customerAddress] > 0);
        uint256 _amountOfTokens             = stakeBalanceLedger_[_customerAddress];
        uint256 timediff                    = SafeMath.sub(now, stakingTime_[_customerAddress]);
        uint256 dayscount                   = SafeMath.div(timediff, stakingTime);
        uint256 roiPercent                  = SafeMath.mul(dayscount, stakePer_);
        uint256 roiTokens                   = SafeMath.percent(_amountOfTokens,roiPercent,100,18);
        uint256 finalBalance                = SafeMath.add(_amountOfTokens,roiTokens/1e18);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], finalBalance);
        stakeBalanceLedger_[_customerAddress] = 0;
        stakingTime_[_customerAddress]      = 0;
    }
    
}