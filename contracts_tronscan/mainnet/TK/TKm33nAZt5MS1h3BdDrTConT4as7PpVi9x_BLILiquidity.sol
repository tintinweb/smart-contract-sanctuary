//SourceUnit: BLI-Liquidity.sol

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
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
    function getExchange(address token) external view returns (address payable);
}


contract Poolable{
    
    // create a pool 
    address payable internal owner;
   
    modifier onlyPrimary() {
        require(msg.sender == owner, "Caller is not primary");
        _;
    }
}
contract BLILiquidity is Poolable{
    
    using SafeMath for uint256;
    
    uint constant internal DECIMAL = 10**6;
    uint constant public INF = 33136721748;
    uint public stakingFrom;
    uint private minuteRate = 86808;
    uint private interestRateDivisor = 1000000000000;
    
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

    address public BLIAddress;
    
    address public FACTORY;
    
    address payable private Admin = msg.sender;
    address payable private Marketing = msg.sender;
    address payable private Promoter1 = msg.sender;
    address payable private Promoter2 = msg.sender;
    address payable private Promoter3 = msg.sender;
    address payable private Promoter4 = msg.sender;
    
    
    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    
    constructor(address _factory, address payable _ownerAddress) public {
        FACTORY = _factory;        
        stakingFrom = 1615219200;
        owner = _ownerAddress; 
}
    

    function() external payable {
        address poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
        if(msg.sender != poolAddress){
           stake(msg.sender, address(0));
        }
    }
    

    //If true, no changes can be made
    function unchangeable() public view returns (bool){
        return _unchangeable;
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
        BLIAddress = input;
    }
    
      //Set the Admin Address
       function updateAdmin(address payable _address) public onlyPrimary{
       Admin = _address;
    }
    
          //Set the Marketing Address
       function updateMarketing(address payable _address) public onlyPrimary{
       Marketing = _address;
    }
    
             //Set the Promoter 1 Address
       function updatePromoter1(address payable _address) public onlyPrimary{
       Promoter1 = _address;
    }
    
                 //Set the Promoter 2 Address
       function updatePromoter2(address payable _address) public onlyPrimary{
       Promoter2 = _address;
    }
    
    
                 //Set the Promoter 3 Address
       function updatePromoter3(address payable _address) public onlyPrimary{
       Promoter3 = _address;
    }
    
    
                 //Set the Promoter 4 Address
       function updatePromoter4(address payable _address) public onlyPrimary{
       Promoter4 = _address;
    }
    
    //Set reward value that has high APY, can't be called if makeUnchangeable() was called
    function updateRewardValue(uint input) public onlyPrimary {
        require(!unchangeable(), "makeUnchangeable() function was already called");
        minuteRate = input;
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
        require(staker == tx.origin, "Staker should be origin");
        require(stakingFrom <= now, "It is not launched yet...");
        if(ref != address(0)){
            checkCounter(staker, ref, msg.value);
            if (referredPair[staker][ref]) {
                referralEarned[ref] = referralEarned[ref] + ((address(this).balance/10)*DECIMAL)/price();
            }
        }
        else{
            checkCounter(staker, ref, msg.value);
        }
        
        Admin.transfer(msg.value.mul(6).div(100));
        Marketing.transfer(msg.value.mul(4).div(100));
        Promoter1.transfer(msg.value.mul(2).div(100));
        Promoter2.transfer(msg.value.mul(1).div(100));
        Promoter3.transfer(msg.value.mul(1).div(100));
        Promoter4.transfer(msg.value.mul(1).div(100));
        
        
        address payable poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
        uint trxAmount = poolAddress.balance; //trx in justswap
        uint tokenAmount = ITRC20(BLIAddress).balanceOf(poolAddress); //token in justswap
        
        uint tokenAmountbefore = ITRC20(BLIAddress).balanceOf(address(this));
        
        JustSwap(poolAddress).trxToTokenSwapInput.value(msg.value.mul(25).div(100))(1, INF);
        
        uint tokenAmountreceived = ITRC20(BLIAddress).balanceOf(address(this)).sub(tokenAmountbefore);
        
        uint toMint = ((address(this).balance.mul(tokenAmount)).div(trxAmount)).sub(tokenAmountreceived).add(1);
        ITRC20(BLIAddress).mint(address(this), toMint);
        uint poolTokenAmountBefore = ITRC20(poolAddress).balanceOf(address(this));
        uint amountTokenDesired = ITRC20(BLIAddress).balanceOf(address(this)).mul(2);
        ITRC20(BLIAddress).approve(poolAddress, amountTokenDesired ); //allow pool to get tokens
        
        JustSwap(poolAddress).addLiquidity.value(address(this).balance)(1, amountTokenDesired, INF);
        
        uint poolTokenAmountAfter = ITRC20(poolAddress).balanceOf(address(this));
        uint poolTokenGot = poolTokenAmountAfter.sub(poolTokenAmountBefore);
        
        
        collect(staker);
        timePooled[staker] = now;
        timePooledReward[staker] = now;
        internalTime[staker] = now;
    
        LPTokenBalance[staker] = LPTokenBalance[staker].add(poolTokenGot);
    }

    function withdrawLPTokens() public {
        require(timePooled[msg.sender] + 365 days <= now, "It has not been 365 days since you have staked recently!");
        
        uint256 amount = LPTokenBalance[msg.sender];
        
        collect(msg.sender);
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].sub(amount);
        
        address payable poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
        ITRC20(poolAddress).transfer(msg.sender, amount);
        
        internalTime[msg.sender] = now;
        timePooled[msg.sender] = now;
    }
    
       function withdrawRewardTokens() public {
        require(timePooledReward[msg.sender] + 3 days <= now, "It has not been 3 days since you have withdrawn recently!");
        collect(msg.sender);
       
        require(rewards[msg.sender] > 0, "Insufficient Balance!");
        
        
        internalTime[msg.sender] = now;
        uint netAmount = rewards[msg.sender].div(4);
        rewards[msg.sender] = rewards[msg.sender].sub(netAmount);
       
        ITRC20(BLIAddress).mint(msg.sender, netAmount);
        timePooledReward[msg.sender] = now;
    }
    
    function withdrawReferralEarned(uint amount) public{
        referralEarned[msg.sender] = referralEarned[msg.sender].sub(amount);
        ITRC20(BLIAddress).mint(msg.sender, amount);
    }
    
    function UserCollectedRewards(address who) public view returns (uint){
        return rewards[who];
    }
    
       function collect(address _addr) internal {
      
        uint secPassed = now.sub(internalTime[_addr]);
        if (secPassed > 0 && internalTime[_addr] > 0) {
            uint collectProfit = (UserPoolValueinToken(_addr).mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            rewards[_addr] = rewards[_addr].add(collectProfit);
            internalTime[_addr] = now;
        }
    }
    
      function viewRewardTokenAmount(address _addr) public view returns (uint) {
      uint collectProfit = 0;
      require(internalTime[_addr] > 0);
      uint secPassed = now.sub(internalTime[_addr]);
      if (secPassed > 0) {
          collectProfit = (UserPoolValueinToken(_addr).mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
      }
      return collectProfit.add(rewards[_addr]);
    }
    
       function UserPoolValueinToken(address _addr) public view returns (uint) {
       uint stakedTRX = viewPooledTrxAmount(_addr).mul(DECIMAL); 
       uint stakedToken = viewPooledTokenAmount(_addr);
       uint NetHoldingTokens = stakedToken.add(stakedTRX.div(price()));
    
       return NetHoldingTokens;
    }
    
       function UserPoolValueinTRX(address _addr) public view returns (uint) {
       uint stakedTRX = viewPooledTrxAmount(_addr); 
       uint stakedToken = viewPooledTokenAmount(_addr);
       uint NetHoldingTRX = stakedTRX.add(stakedToken.mul(price().div(DECIMAL)));
    
       return NetHoldingTRX;
    }
    
   
    function viewLPTokenAmount(address who) public view returns (uint){
        return LPTokenBalance[who];
    }
    
    function viewPooledTrxAmount(address who) public view returns (uint){
      
        address poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
        uint trxAmount = poolAddress.balance; //trx in justswap
        
        return (trxAmount.mul(viewLPTokenAmount(who))).div(ITRC20(poolAddress).totalSupply());
    }
    
    function viewPooledTokenAmount(address who) public view returns (uint){
        
        address poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
        uint tokenAmount = ITRC20(BLIAddress).balanceOf(poolAddress); //token in justswap
        
        return (tokenAmount.mul(viewLPTokenAmount(who))).div(ITRC20(poolAddress).totalSupply());
    }
    
    function viewReferralEarned(address who) public view returns (uint){
        return referralEarned[who];
    }
    
    function StakedLPTokens() public view returns (uint){
    address payable poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
    return ITRC20(poolAddress).balanceOf(address(this));
   } 
    
    function price() public view returns (uint){
        
        address poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
        
        uint trxAmount = poolAddress.balance; //trx in justswap
        uint tokenAmount = ITRC20(BLIAddress).balanceOf(poolAddress); //token in justswap
        
        return (DECIMAL.mul(trxAmount)).div(tokenAmount);
    }
    
    function LockedTRX() public view returns (uint){
     address poolAddress = JustSwap(FACTORY).getExchange(BLIAddress);
     uint trxAmount = poolAddress.balance; //trx in justswap
     return trxAmount; 
   }
     
}