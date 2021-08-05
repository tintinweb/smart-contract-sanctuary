/**
 *Submitted for verification at Etherscan.io on 2020-06-03
*/

pragma solidity ^0.6.7;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint) {
    uint c = add(a,m);
    uint d = sub(c,1);
    return mul(div(d,m),m);
  }
}

  
abstract contract Uniswap2PairContract {
  
  function getReserves() external virtual returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
 
 
      
  }
  
    
  


abstract contract ERC20Token {
  function totalSupply()  public virtual returns (uint);
  function approve(address spender, uint value)  public virtual returns (bool);
  function balanceOf(address owner) public virtual returns (uint);
  function transferFrom (address from, address to, uint value) public virtual returns (bool);
}



contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}


contract UniBOMBLiquidReward is Ownable{
    
    using SafeMath for uint;
    
    uint ONE_MONTH = 60*60*60*24*28;
    uint MAX_MONTHS = 24;
    
    address public LIQUIDITY_TOKEN  = 0xEE89ea23c18410F2b57e7abc6eb24cfcdE4f49B0;
    address public REWARD_TOKEN  = 0xbBB38bE7c6D954320c0297c06Ab3265a950CDF89;

    uint[3] public rewardLevels = [10000,20000,30000];
    uint[3] public poolLevels = [100000000000000000000,1000000000000000000000,10000000000000000000000];
    uint[3] public monthLevels = [3,6,12];
    
    uint[4]  public baseRateLookup = [250,200,150,100];
    
       //poolLevelsIndex   //monthLevelsIndex    //s0(small)[m0,m1,m2..]  //s2 m2   m3    /3=
    uint[4][4]  public multiplierLookup = [[105,110,120,130],[100,105,110,120],[100,100,105,110],[100,100,100,100]];
    
    
      mapping(address => mapping(uint => LiquidityRewardData)) public liquidityRewardData; //address to timestamp to data
    
    uint public allocatedRewards;
    uint public totalUniswapLiquidity;
    uint public unallocatedRewards;
 
    struct LiquidityRewardData {
        uint quantity;
        uint timestamp;
        uint stakeMonths;
        uint reward;
        bool rewardClaimed;
        bool liquidityClaimed;
    }
    
     
    
    fallback()  external payable {
        revert();
    }
    
    
    function setOneMonth(uint input ) public onlyOwner{
       ONE_MONTH = input;
    }
    
    function setRewardLevels(uint[3] memory input ) public onlyOwner{
       rewardLevels = input;
    }
    function setpoolLevels(uint[3] memory input ) public onlyOwner{
       poolLevels = input;
    }
    function setMonthLevels(uint[3] memory input ) public onlyOwner{
       monthLevels = input;
    }
    function setBaseRateLookup(uint[4] memory input ) public onlyOwner{
       baseRateLookup = input;
    }
    function setMultiplierLookup(uint[4][4] memory input ) public onlyOwner{
       multiplierLookup = input;
    }
    function setMaxMonths(uint input ) public onlyOwner{
       MAX_MONTHS = input;
    }
     function getMaxMonths() view public returns(uint){
       return MAX_MONTHS;
    }
    
    
    
    function getAllocatedRewards() view public returns(uint){
        return allocatedRewards;
    }
    
    function getUnallocatedRewards() view public returns(uint){
        return unallocatedRewards;
    }
    
    
      function findOnePercent(uint256 value) public pure returns (uint256)  {
        uint256 roundValue = value.ceil(100);
        uint256 onePercent = roundValue.mul(100).div(10000);
        return onePercent;
    }
    
   
        //(this)must be whitelisted on ubomb
     function topupReward (uint amount)  external {
       require(ERC20Token(REWARD_TOKEN).transferFrom(address(msg.sender), address(this), amount),"tokenXferFail");
       //calc actual deposit amount due to BOMB burn
       uint tokensToBurn = findOnePercent(amount);
       uint actual = amount.sub(tokensToBurn);
       
       unallocatedRewards += actual;
     } 
    
    
  
    
    function calcReward(uint stakeMonths, uint stakeTokens)  public  returns (uint){
        
        (uint tokens, uint eth, uint time) = Uniswap2PairContract(LIQUIDITY_TOKEN).getReserves();
        
        uint liquidity = stakeTokens;

        uint liquidityTotalSupply = ERC20Token(LIQUIDITY_TOKEN).totalSupply();
        
        //uint amountEth = liquidity.mul(eth) / liquidityTotalSupply; // using balances ensures pro-rata distribution
        uint amountTokens = (liquidity.mul(tokens)).div(liquidityTotalSupply); // using balances ensures pro-rata distribution
       
        uint months = stakeMonths;
        uint baseRate = baseRateLookup[getRewardIndex()];
        uint multiplier =  multiplierLookup[getpoolLevelsIndex(eth)][getMonthsIndex(months)];
        
        uint reward = (amountTokens.mul(months).mul(baseRate).mul(multiplier)).div(1000000);
        
        return(reward);
    }
    
   
    
    function getRewardIndex() public view returns (uint) {
        if(unallocatedRewards < rewardLevels[0]){return 3;}
        else if(unallocatedRewards < rewardLevels[1]){return 2;}
        else if(unallocatedRewards < rewardLevels[2]){return 1;}
        else {return 0;}
    }
    
    //baserate
    function getpoolLevelsIndex(uint eth) public view returns (uint) {
     
        if(eth < poolLevels[0] ){return 0;}
        else if(eth <poolLevels[1]){return 1;}
        else if(eth <poolLevels[2]){return 2;}
        else {return 3;}
    }
    
     function getMonthsIndex(uint month) public view returns (uint) {
        
        if(month < monthLevels[0]){return 0;}
        else if(month < monthLevels[1]){return 1;}
        else if(month < monthLevels[2]){return 2;}
        else {return 3;}
        
    }
    
    
    function lockLiquidity(uint idx, uint stakeMonths, uint stakeTokens) external {
    
        //temp hold tokens and ether from sender
        require(stakeMonths <= MAX_MONTHS,"tooManyMonths");
        require(ERC20Token(LIQUIDITY_TOKEN).transferFrom(address(msg.sender), address(this), stakeTokens),"tokenXferFail");
        
        require( (liquidityRewardData[msg.sender][idx].quantity == 0),"previousLiquidityInSlot");
       
        uint reward = calcReward(stakeMonths,stakeTokens);
        
        require( unallocatedRewards >= reward, "notEnoughRewardRemaining");
        
        allocatedRewards += reward;
        unallocatedRewards -= reward;
        totalUniswapLiquidity += stakeTokens;
        
        liquidityRewardData[msg.sender][idx] = LiquidityRewardData(stakeTokens, block.timestamp, stakeMonths, reward,false,false);
     
    }
    
    
    
    function rewardTask(uint idx, uint renewMonths) public {
        
        require(liquidityRewardData[msg.sender][idx].rewardClaimed == false,"RewardClaimedAlready");
        liquidityRewardData[msg.sender][idx].rewardClaimed = true;
        
        uint reward = liquidityRewardData[msg.sender][idx].reward;
        allocatedRewards -= reward;
            
        if( liquidityRewardData[msg.sender][idx].timestamp.add( liquidityRewardData[msg.sender][idx].stakeMonths.mul(ONE_MONTH)) <= block.timestamp){
            
            if(renewMonths > 0 && liquidityRewardData[msg.sender][idx].liquidityClaimed==false){ //claim and renew
                
                uint newReward = calcReward(renewMonths,liquidityRewardData[msg.sender][idx].quantity);
                require(newReward < unallocatedRewards,"NotEnoughRewardsRemaining");
                allocatedRewards += newReward;
                unallocatedRewards -= newReward;
                liquidityRewardData[msg.sender][idx].timestamp = block.timestamp;
                liquidityRewardData[msg.sender][idx].stakeMonths = renewMonths;
                liquidityRewardData[msg.sender][idx].reward = newReward;
                liquidityRewardData[msg.sender][idx].rewardClaimed = false;
            
            }
            ERC20Token(REWARD_TOKEN).approve(address(this),reward);
            ERC20Token(REWARD_TOKEN).transferFrom(address(this), address(msg.sender), reward);
        }
        else{
            unallocatedRewards += reward;
            
        }
        
    }
    
    
    
    
    function unlockLiquidity(uint idx) external { //get liquidity tokens
    
        require(liquidityRewardData[msg.sender][idx].liquidityClaimed == false,"LiquidityAlreadyClaimed");
        
        if(liquidityRewardData[msg.sender][idx].rewardClaimed == false){
            rewardTask(idx,0);
        }
        totalUniswapLiquidity -= liquidityRewardData[msg.sender][idx].quantity;
        ERC20Token(LIQUIDITY_TOKEN).approve(address(this),liquidityRewardData[msg.sender][idx].quantity);
        ERC20Token(LIQUIDITY_TOKEN).transferFrom(address(this),address(msg.sender),liquidityRewardData[msg.sender][idx].quantity);
        liquidityRewardData[msg.sender][idx].quantity = 0;
        liquidityRewardData[msg.sender][idx].liquidityClaimed = true;
        
    }
  

}