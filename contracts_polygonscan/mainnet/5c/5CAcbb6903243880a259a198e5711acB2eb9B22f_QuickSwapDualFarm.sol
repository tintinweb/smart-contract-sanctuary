/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function decimals() external view returns (uint8);
}
interface LP{
    function totalSupply() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
interface DualFarmQuickswap {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function balanceOf(address account) external view returns (uint256);
}

interface DQuick{
    
    function leave(uint256 _dQuickAmount) external;
}

interface QuickSwap{
    
    function totalSupply() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    
}
interface Oraclehub{
    function showOracleAddress(address token) external view returns (address);
}
interface Chainlink{
    
    function decimals() external view returns (uint8);
    function latestTimestamp() external view returns (uint256);
    function latestAnswer() external view returns(int256);
    
}

interface Uniswap{
    
   function addLiquidity(
  address tokenA,
  address tokenB,
  uint amountADesired,
  uint amountBDesired,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external ;

function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
    
    
}

contract QuickSwapDualFarm {

   string public constant name = "Quick-Swap WMATIC/USDT AC";
    string public constant symbol = "QWUSDTAC";
    uint8 public constant decimals = 18;  
    address public RELEVANTLP = 0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3;
    address public DualFarm = 0xc0eb5d1316b835F4B584B59f922d9c87cA5053E5;
   
    uint256 constant PRECISION = 10**18;
    uint256 constant BABYPRECISION = 10**4;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC on Polygon
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT on Polygon
    address constant dQuick = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address constant Quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address constant QuickRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant OracleHubAddress = 0xe81C9f94C8A9F92150481589E836980146448719; 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
      uint256 diff0 = 10**(18-(IERC20(WMATIC).decimals())); 
      uint256 diff1 = 10**(18-(IERC20(USDT).decimals())); 
      uint256 public inverseInterestRatio;
      uint256 public InterestRatio;
      
     uint256 public slippageAutoCompound = 150;
      
    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
   uint256 totalSupply_;
   
    address public masterAddress = msg.sender;
   
   
    address[]  path =[Quick,WMATIC];
    address[] path2=[WMATIC,USDT]; 
  

   


  constructor(uint256 total)  {  
	totalSupply_ = total;
	balances[0x0000000000000000000000000000000000000000] = totalSupply_;
	inverseInterestRatio = 10**18;
	InterestRatio = 10**18;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-(numTokens);
        balances[receiver] = balances[receiver]+(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner]-(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-(numTokens);
        balances[buyer] = balances[buyer]+(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
      function _mint(
        address account,
        uint256 amount
    )
        internal
        
    {
        require(
            account != address(0x0)
        );

        totalSupply_ = totalSupply_+(amount);

        balances[account] =
        balances[account]+(amount);

       
    }
    
     function _burn(
        address account,
        uint256 amount
    )
        internal
        
    {
        require(
            account != address(0x0)
        );

        balances[account] =
        balances[account]-(amount);

        totalSupply_ =
        totalSupply_-(amount);

        

     
    }

 function getBalance(address token) internal view returns (uint256){
     
     uint256 thisBalance = IERC20(token).balanceOf(address(this));
     
     return thisBalance;
 }

 function calcOutputAmount(uint256 inputAmount, address from, address destination, uint256 slippage) internal  view returns(uint256){
    
    address oracleFrom = Oraclehub(OracleHubAddress).showOracleAddress(from);
    address oracleDestination = Oraclehub(OracleHubAddress).showOracleAddress(destination);
    
    uint256 diffFrom = 10**(18-IERC20(from).decimals());
    uint256 diffTo = 10**(18-IERC20(destination).decimals());
    uint256 chainlinkDiffFrom = 10**(18-Chainlink(oracleFrom).decimals());  
    uint256 chainlinkDiffDestination = 10**(18-Chainlink(oracleDestination).decimals());  
    
    
    uint256 evaluateFrom = uint256(Chainlink(oracleFrom).latestAnswer())*chainlinkDiffFrom *inputAmount*diffFrom ;
    uint256 DestinationTokenPrep = (10000-slippage)*evaluateFrom/(uint256(Chainlink(oracleDestination).latestAnswer())*chainlinkDiffDestination ) ;
    uint256 DestinationAmount = DestinationTokenPrep/(BABYPRECISION*diffTo) ;
    
    return DestinationAmount;
    
}


 
 
     function deposit(
        
        uint256 _amount
        
       )
    external returns (bool) {
        
        
        uint256 Result = (inverseInterestRatio*_amount)/PRECISION;
        
       IERC20(RELEVANTLP).transferFrom(msg.sender, address(this),_amount);
       _mint(msg.sender,Result);
       IERC20(RELEVANTLP).approve(DualFarm,_amount);
       DualFarmQuickswap(DualFarm).stake(_amount);
        
        delete Result;
        
        return true;
    }
 
     function BountyCompound(address hunter, bool twoRewards) external returns (bool){
        
        
       DualFarmQuickswap(DualFarm).getReward();
       DQuick(dQuick).leave(IERC20(dQuick).balanceOf(address(this)));
        
       
        
        
        
        uint256 bounty1 = getBalance(Quick)/(101);
        uint256 bounty2 = getBalance(WMATIC)/(101);
        
       
        
        
        
        IERC20(Quick).transfer(hunter,bounty1 );
        
        if (twoRewards == true){
        
        IERC20(WMATIC).transfer(hunter, bounty2);
        }
        
        delete bounty1;
        delete bounty2;
        
        
        
        IERC20(Quick).approve(QuickRouter,IERC20(Quick).balanceOf(address(this)) );
        Uniswap(QuickRouter).swapExactTokensForTokens(IERC20(Quick).balanceOf(address(this)),calcOutputAmount(getBalance(Quick),Quick,WMATIC,slippageAutoCompound),path,address(this),block.timestamp);
        
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        Uniswap(QuickRouter).swapExactTokensForTokens(getBalance(WMATIC)/2,calcOutputAmount(getBalance(WMATIC)/2,WMATIC,USDT,slippageAutoCompound),path2,address(this),block.timestamp);
        
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        IERC20(USDT).approve(QuickRouter,IERC20(USDT).balanceOf(address(this)) );
        
        
        uint256 minLP1USDT = calcOutputAmount(getBalance(USDT),USDT,USDT,slippageAutoCompound) ; 
        uint256 minLP2WMATIC = calcOutputAmount(getBalance(WMATIC),WMATIC,WMATIC,slippageAutoCompound) ;
        
        Uniswap(QuickRouter).addLiquidity(USDT,WMATIC,getBalance(USDT),getBalance(WMATIC),minLP1USDT,minLP2WMATIC,address(this),block.timestamp);
        
        IERC20(RELEVANTLP).approve(DualFarm,IERC20(RELEVANTLP).balanceOf(address(this)));
        DualFarmQuickswap(DualFarm).stake(IERC20(RELEVANTLP).balanceOf(address(this)));
        
        
        InterestRatio = getImpliedBalance()*PRECISION/totalSupply_ ;
        inverseInterestRatio = totalSupply_*PRECISION/getImpliedBalance() ;
        
        
        return true;
        
    }
    
     function withdrawLP(
        
        uint256 _amount
               )
               
    external returns (bool) {
        
          uint256 LPtoWithdraw= (InterestRatio * _amount /PRECISION); 
        
        
        DualFarmQuickswap(DualFarm).withdraw(LPtoWithdraw);
        IERC20(RELEVANTLP).transfer(msg.sender,IERC20(RELEVANTLP).balanceOf(address(this)));
        _burn(msg.sender,_amount);
        
        delete LPtoWithdraw;
        
        
        return true;
    }
        
    
    function getImpliedBalance() internal view returns (uint256) {
          uint256 totBalance = DualFarmQuickswap(DualFarm).balanceOf(address(this)) ;
       
       
    
    return totBalance;
    
        
    }
    


function latestAnswer() external view returns (int256){

    address oracleWMATIC = Oraclehub(OracleHubAddress).showOracleAddress(WMATIC) ;
    address oracleUSDT = Oraclehub(OracleHubAddress).showOracleAddress(USDT) ;
     
    
    (uint256 Res0, uint256 Res1,) = QuickSwap(RELEVANTLP).getReserves();
    uint256 latestPrice0=  uint256(Chainlink(oracleWMATIC).latestAnswer());
    uint256 latestPrice1=  uint256(Chainlink(oracleUSDT).latestAnswer());
    uint256 chainlinkDiff0 = 10**(18-Chainlink(oracleWMATIC).decimals());
    uint256 chainlinkDiff1 = 10**(18-Chainlink(oracleUSDT).decimals());
    uint256 totalValue = (Res0*diff0*chainlinkDiff0*latestPrice0 )+(Res1*diff1*chainlinkDiff1*latestPrice1 ) ; 
    
    uint256 answerPrep = InterestRatio*totalValue/(QuickSwap(RELEVANTLP).totalSupply());
    delete totalValue;
    uint256 answerPrep2 = answerPrep/(PRECISION);
    delete answerPrep;
    int256 answer = int256(answerPrep2);
    
    
     
     uint256  ratio = (Res1*diff1)*PRECISION/(Res0*diff0);
     uint256  ratioChainLink =  latestPrice0*chainlinkDiff0*PRECISION/(latestPrice1*chainlinkDiff1);
    
     uint256 check = ratio*BABYPRECISION/ratioChainLink;
     
    require (check >9850 && check<10150,"Nice Try");
    
    delete ratio;
    delete ratioChainLink;
    delete check;
    delete chainlinkDiff1;
    delete chainlinkDiff0;
    delete latestPrice1;
    delete latestPrice0;
    delete oracleUSDT;
    delete oracleWMATIC;
    delete answerPrep2;
    delete Res0;
    delete Res1;
    
    return answer;
}

function changeSlippage(uint256 amount ) external  onlyMaster returns (bool){
    
    slippageAutoCompound = amount ;
    
    require (amount <300 && amount > 80, "too tight or too loose");
    
    return true;
    
    
}
 modifier onlyMaster() {
        require(
        msg.sender == masterAddress,
            "Not Master"
        );
        _;
    }

 function renounceOwnership()
        external
        onlyMaster
    {
        masterAddress = address(0x0);
    }
    
    function forwardOwnership(
        address payable _newMaster
    )
        external
        onlyMaster
    {
        masterAddress = _newMaster;
    }
        




}