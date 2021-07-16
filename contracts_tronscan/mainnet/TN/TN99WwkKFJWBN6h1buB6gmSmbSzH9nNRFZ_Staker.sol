//SourceUnit: Staking.sol

pragma solidity 0.5.10;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface JustSwap{
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function getExchange(address token) external view returns (address payable);
}

interface Pool{
    function primary() external view returns (address);
}

contract Poolable{
    
    // create a pool 
    address payable internal _POOLADDRESS;
 
    function primary() private view returns (address) {
        return Pool(_POOLADDRESS).primary();
    }
    
    modifier onlyPrimary() {
        require(msg.sender == primary(), "Caller is not primary");
        _;
    }
}

contract Staker is Poolable{
    
    using SafeMath for uint256;
    
    uint constant internal DECIMAL = 10**6;
    uint constant public INF = 33136721748;
    uint public stakingFrom;
    uint public referralUnlockTime;
    uint private _rewardValue = 10**6;
    
    mapping (address => uint256) public  timePooled;
    mapping (address => uint256) public  timePooledReward;
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;
    mapping (address => uint256) private referralEarned;
    mapping (address => uint256) referredTrx;
    mapping (address => uint256) referredCount; 
    mapping (address => bool) alreadyStaked; 
    mapping (address => mapping (address => bool)) referredPair;

    address public nortAddress;
    
    address public FACTORY;
    
    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    
    constructor(address _factory, address payable _poolAddress) public {
        FACTORY = _factory;        
        stakingFrom = 1603305000;
        _POOLADDRESS = _poolAddress;
        referralUnlockTime = 1603564200;
    }
    

    function() external payable {
        address poolAddress = JustSwap(FACTORY).getExchange(nortAddress);
        if(msg.sender != poolAddress){
           stake(msg.sender, address(0));
        }
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(recipient.send(amount), "Address: unable to send value, recipient may have reverted");
    }
    
    //If true, no changes can be made
    function unchangeable() public view returns (bool){
        return _unchangeable;
    }
    
    function rewardValue() public view returns (uint){
        return _rewardValue;
    }
    
    function referralCount(address staker) public view returns (uint){
        return referredCount[staker];
    }
    function referralTrx(address staker) public view returns (uint){
        return referredTrx[staker];
    }
    
    //THE ONLY ADMIN FUNCTIONS vvvv
    //After this is called, no changes can be made
    function makeUnchangeable() public onlyPrimary{
        _unchangeable = true;
    }
    
    //Can only be called once to set token address
    function setTokenAddress(address input) public onlyPrimary{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        nortAddress = input;
    }
    
    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateRewardValue(uint input) public onlyPrimary {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }
    //THE ONLY ADMIN FUNCTIONS ^^^^
    
    function checkCounter(address staker, address ref, uint256 amount) internal {
        if (alreadyStaked[staker]) {
            if (referredPair[staker][ref]) {
                referredTrx[ref] = referredTrx[ref].add(amount);
            }
            return;
        }
        alreadyStaked[staker] = true;
        referredPair[staker][ref] = true;
        referredTrx[ref] = referredTrx[ref].add(amount);
        referredCount[ref] = referredCount[ref].add(1);
    }
  
    function stake(address payable staker, address payable ref) public payable{
        require(staker == tx.origin, "staker should be origin");
        require(stakingFrom <= now, "We are close to enable staking");
        if(ref != address(0)){
            checkCounter(staker, ref, msg.value);
            if (referredPair[staker][ref]) {
                referralEarned[ref] = referralEarned[ref] + ((address(this).balance/10)*DECIMAL)/price();
            }
        }
        else{
            checkCounter(staker, ref, msg.value);
        }

        sendValue(_POOLADDRESS, address(this).balance/2);
        
        address payable poolAddress = JustSwap(FACTORY).getExchange(nortAddress);
        uint trxAmount = poolAddress.balance; //trx in justswap
        uint tokenAmount = ITRC20(nortAddress).balanceOf(poolAddress); //token in justswap
        
        uint toMint = ((address(this).balance.mul(tokenAmount)).div(trxAmount)).add(1);
        ITRC20(nortAddress).mint(address(this), toMint);

        uint poolTokenAmountBefore = ITRC20(poolAddress).balanceOf(address(this));
        uint amountTokenDesired = ITRC20(nortAddress).balanceOf(address(this)).mul(2);
        ITRC20(nortAddress).approve(poolAddress, amountTokenDesired ); //allow pool to get tokens

        JustSwap(poolAddress).addLiquidity.value(address(this).balance)(1, amountTokenDesired, INF);
        
        uint poolTokenAmountAfter = ITRC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);
        
        rewards[staker] = rewards[staker].add(viewRecentRewardTokenAmount(staker));
        timePooled[staker] = now;
        timePooledReward[staker] = now;
        internalTime[staker] = now;
    
        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }

    function withdrawLPTokens() public {
        require(timePooled[msg.sender] + 3 days <= now, "It has not been 3 days since you staked or last withdrawn yet");
        uint256 amount = LPTokenBalance[msg.sender].div(3);
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].sub(amount);
        
        address payable poolAddress = JustSwap(FACTORY).getExchange(nortAddress);
        ITRC20(poolAddress).transfer(msg.sender, amount);
        
        internalTime[msg.sender] = now;
        timePooled[msg.sender] = now;
    }
    
    function withdrawRewardTokens(uint amount) public {
        require(timePooledReward[msg.sender] + 3 days <= now, "It has not been 3 days since you staked or last withdrawn yet");
        rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
        internalTime[msg.sender] = now;
        
        uint removeAmount = trxtimeCalc(amount).div(6);
        rewards[msg.sender] = rewards[msg.sender].sub(removeAmount);
       
        ITRC20(nortAddress).mint(msg.sender, amount);
        timePooledReward[msg.sender] = now;
    }
    
    function withdrawReferralEarned(uint amount) public{
        require(referralUnlockTime <= now, "Referral Will be unlocked after 3 days of staking started");
        referralEarned[msg.sender] = referralEarned[msg.sender].sub(amount);
        ITRC20(nortAddress).mint(msg.sender, amount);
    }
    
    function viewRecentRewardTokenAmount(address who) internal view returns (uint){
        return (viewPooledTrxAmount(who).mul( now.sub(internalTime[who]) ));
    }
    
    function viewRewardTokenAmount(address who) public view returns (uint){
        return earnCalc( rewards[who].add(viewRecentRewardTokenAmount(who))*2 );
    }
    
    function viewLPTokenAmount(address who) public view returns (uint){
        return LPTokenBalance[who];
    }
    
    function viewPooledTrxAmount(address who) public view returns (uint){
      
        address poolAddress = JustSwap(FACTORY).getExchange(nortAddress);
        uint trxAmount = poolAddress.balance; //trx in justswap
        
        return (trxAmount.mul(viewLPTokenAmount(who))).div(ITRC20(poolAddress).totalSupply());
    }
    
    function viewPooledTokenAmount(address who) public view returns (uint){
        
        address poolAddress = JustSwap(FACTORY).getExchange(nortAddress);
        uint tokenAmount = ITRC20(nortAddress).balanceOf(poolAddress); //token in justswap
        
        return (tokenAmount.mul(viewLPTokenAmount(who))).div(ITRC20(poolAddress).totalSupply());
    }
    
    function viewReferralEarned(address who) public view returns (uint){
        return referralEarned[who];
    }
    
    function price() public view returns (uint){
        
        address poolAddress = JustSwap(FACTORY).getExchange(nortAddress);
        
        uint trxAmount = poolAddress.balance; //trx in justswap
        uint tokenAmount = ITRC20(nortAddress).balanceOf(poolAddress); //token in justswap
        
        return (DECIMAL.mul(trxAmount)).div(tokenAmount);
    }

    function earnCalc(uint trxTime) public view returns(uint){
        return ( rewardValue().mul(trxTime)  ) / ( 31557600 * DECIMAL );
    }
    
    function trxtimeCalc(uint nort) internal view returns(uint){
        return ( nort.mul(31557600 * DECIMAL) ).div( rewardValue() );
    }
}