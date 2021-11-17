/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.4.22 <0.9.0;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
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

interface IcurveGauge {
    function claim_rewards() external;
    function claim_rewards(address receiver) external ;
    function deposit(uint256 _value, address _addr,bool _claim_rewards) external ;
    function withdraw (uint256 _value, bool _claim_rewards)  external ;
    function withdraw(uint256 amount) external;
    function deposit(uint256 value) external;
    function balanceOf(address account) external view returns (uint256) ;
    function last_claim() external view returns (uint256);
    
}

interface IcurveReserves{
    
   function balances(uint256 i) external view returns (uint256);
   function add_liquidity(uint256[3] calldata _amounts , uint256 _min_mint_amount , bool _use_underlying) external ; 
   function remove_liquidity(uint256 _amount , uint256[3] calldata _min_amounts, bool _use_underlying) external;

    
}

interface ICurveLP{
    function totalSupply() external view returns (uint256);
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
    
function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external;

    
}

contract curveAm3 {

    string public constant name = "Curve Am3 Autocompound";
    string public constant symbol = "CrvAm3AC";
    uint8 public constant decimals = 18;  
    address public RELEVANTLP =  0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c; // gaugeCurveLP
    
   
    uint256 constant PRECISION = 10**18;
    uint256 constant BABYPRECISION = 10**4;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC on Polygon
    address constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // ETH on Polygon
    address constant CRV = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant crvSwapperReserves = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    address constant SushiswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address constant originalCurveLP = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;
   
    uint256 public slippageAutoCompound = 150;
     
    address constant OracleHubAddress = 0xe81C9f94C8A9F92150481589E836980146448719; 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

      uint256 diff0 = 10**(18-(IERC20(DAI).decimals())); 
      uint256 diff1 = 10**(18-(IERC20(USDC).decimals())); 
      uint256 diff2 = 10**(18-(IERC20(USDT).decimals())); 
      uint256 public Result ;
     
      uint256 public withdrawReturn;
      uint256 public returnValue;
      uint256 public inverseInterestRatio;
      uint256 public InterestRatio;
      
    
      address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
      address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
      address public  oracleDAI = Oraclehub(OracleHubAddress).showOracleAddress(DAI) ;
      address public  oracleUSDC = Oraclehub(OracleHubAddress).showOracleAddress(USDC) ;
      address public oracleUSDT =  Oraclehub(OracleHubAddress).showOracleAddress(USDT);

     
      uint256[3] Balances;
     
      
    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    mapping(address => uint256) lastClaim;
    
    uint256 totalSupply_;

    address[]  path =[CRV,ETH,WMATIC];
    address[] path2 =[WMATIC,ETH,USDC];


  constructor(uint256 total) {  
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
       

        balances[account] =
        balances[account]-(amount);

        totalSupply_ =
        totalSupply_-(amount);

        

     
    }

     function deposit(
        
        uint256 _amount
        
       )
    external returns (bool) {
        
       Result = (inverseInterestRatio*_amount)/PRECISION;
       
       
       IERC20(originalCurveLP).transferFrom(msg.sender, address(this),_amount);
       _mint(msg.sender,Result);
       
       delete Result;
       
       IERC20(originalCurveLP).approve(RELEVANTLP,_amount);
       IcurveGauge(RELEVANTLP).deposit(IERC20(originalCurveLP).balanceOf(address(this)));
        
        return true;
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

function calcLPOutPut(address token,  uint256 slippage) internal view  returns (uint256){
    
    uint256 diffToken = 10**(18-IERC20(token).decimals());
    
   address oracleToken = Oraclehub(OracleHubAddress).showOracleAddress(token);
    
    uint256 chainlinkDiffToken = 10**(18-Chainlink(oracleToken).decimals());  
    uint256 getInputValue = getBalance(token) *uint256(Chainlink(oracleToken).latestAnswer())*chainlinkDiffToken*diffToken/PRECISION ;
    
    uint256 getOutputValuePrep = (10000-slippage)*getInputValue/(uint256(Chainlink(address(this)).latestAnswer()) );
    uint256 getOutputValuePrep2 = getOutputValuePrep/(BABYPRECISION*diffToken);
    uint256 getOutputValue  = (getOutputValuePrep2*inverseInterestRatio)/PRECISION;
    
    return getOutputValue;
}
 
 
  function getBalance(address token) internal view returns (uint256){
     
     uint256 thisBalance = IERC20(token).balanceOf(address(this));
     
     return thisBalance;
 }
 
 
 
     function BountyCompound(address hunter,bool twoRewards ) external returns (bool){
         
       require(lastClaim[address(this)] < IcurveGauge(RELEVANTLP).last_claim(), "not yet");
        
       IcurveGauge(RELEVANTLP).withdraw(IERC20(RELEVANTLP).balanceOf(address(this)),false);
    
       IERC20(originalCurveLP).approve(RELEVANTLP,IERC20(originalCurveLP).balanceOf(address(this)));
       IcurveGauge(RELEVANTLP).deposit(IERC20(originalCurveLP).balanceOf(address(this)), address(this), true);
      
       lastClaim[address(this)]=block.timestamp;

       
        
        
      
        uint256 bounty1 = getBalance(WMATIC)/101;
        uint256  bounty2 = getBalance(CRV)/101;
        
        
         IERC20(CRV).transfer(hunter,bounty1 );
         
         if (twoRewards == true){
             
              IERC20(WMATIC).transfer(hunter, bounty2);
             
         }
         
        
        
        delete bounty1;
        delete bounty2;
        
        IERC20(CRV).approve(SushiswapRouter,IERC20(CRV).balanceOf(address(this)) );
        Uniswap(SushiswapRouter).swapExactTokensForTokens(IERC20(CRV).balanceOf(address(this)),calcOutputAmount(getBalance(CRV),CRV,WMATIC,slippageAutoCompound),path,address(this),block.timestamp);
        
        IERC20(WMATIC).approve(SushiswapRouter,IERC20(WMATIC).balanceOf(address(this)) );
        Uniswap(SushiswapRouter).swapExactTokensForTokens(IERC20(WMATIC).balanceOf(address(this)),calcOutputAmount(getBalance(WMATIC),WMATIC,USDC,slippageAutoCompound),path2,address(this),block.timestamp);
        
        Balances=  [IERC20(DAI).balanceOf(address(this)),IERC20(USDC).balanceOf(address(this)),IERC20(USDT).balanceOf(address(this))];
       
        
       
        IERC20(USDC).approve(crvSwapperReserves,IERC20(USDC).balanceOf(address(this)));
        IcurveReserves(crvSwapperReserves).add_liquidity(Balances,calcLPOutPut(USDC,slippageAutoCompound),true);
        
        IERC20(originalCurveLP).approve(RELEVANTLP,IERC20(originalCurveLP).balanceOf(address(this)));
        IcurveGauge(RELEVANTLP).deposit(IERC20(originalCurveLP).balanceOf(address(this)));
        
     
        InterestRatio = IERC20(RELEVANTLP).balanceOf(address(this))*PRECISION/totalSupply_ ;
        
        inverseInterestRatio = totalSupply_*PRECISION/IERC20(RELEVANTLP).balanceOf(address(this)) ;
        
         
     
        
        
        return true;
        
    }
    

    
    
       function withdrawLP(
        
        uint256 _amount
        
        
        
       )
    external returns (bool) {
        
      
        uint256 LPtoWithdraw= (InterestRatio * _amount /PRECISION); 
        IcurveGauge(RELEVANTLP).withdraw(LPtoWithdraw);
        IERC20(originalCurveLP).transfer(msg.sender,LPtoWithdraw);
        
        delete LPtoWithdraw;
        
        _burn(msg.sender,_amount);
        
        
        
        return true;
    }
        


function latestAnswer() external view returns (int256){

    

    uint256[3] memory Reserves;
    uint256[3] memory Prices;
     

    Reserves=[IcurveReserves(crvSwapperReserves).balances(0), IcurveReserves(crvSwapperReserves).balances(1) ,  IcurveReserves(crvSwapperReserves).balances(2) ];
    
    Prices= [uint256(Chainlink(oracleDAI).latestAnswer()),uint256(Chainlink(oracleUSDC).latestAnswer()),uint256(Chainlink(oracleUSDT).latestAnswer())];
   
    (uint256 chainlinkDiff0,uint256 chainlinkDiff1,uint256 chainlinkDiff2) = (10**(18-Chainlink(oracleDAI).decimals()),10**(18-Chainlink(oracleUSDC).decimals()),10**(18-Chainlink(oracleUSDT).decimals()));
   
    
    uint256 totalValue = (Reserves[0]*diff0*chainlinkDiff0*Prices[0] )+(Reserves[1]*diff1*chainlinkDiff1*Prices[1] )+(Reserves[2]*diff2*chainlinkDiff2*Prices[2] ) ; // careful its 10^36 here so that latestAnswer gets correct rpecision after dividing
   
    uint256 totalValueAdjusted = InterestRatio*totalValue/PRECISION  ;
   
    delete totalValue;
   
   
    uint256 totalSply = (ICurveLP(originalCurveLP).totalSupply());
   

    int256 answer = int256(totalValueAdjusted/totalSply);
    
    delete totalValueAdjusted;
    delete totalSply;
    
    compareAlgorithmFoulCheck();
    
    
    return answer;
}


function compareAlgorithmFoulCheck() internal view returns(bool){
    
     uint256 a = IcurveReserves(crvSwapperReserves).balances(0)*diff0;
     uint256 b = IcurveReserves(crvSwapperReserves).balances(1)*diff1;
     uint256 c = IcurveReserves(crvSwapperReserves).balances(2)*diff2;
    
  
   uint256 check1 = a*BABYPRECISION/b;
   uint256 check2 = a*BABYPRECISION/c; 
   uint256 check3=  b*BABYPRECISION/c;
   
        
        
         require (check1 >4000 && check1<25000,"Nice Try");
         require (check2 >4000 && check2<25000,"Nice Try");
         require (check2 >4000 && check3<25000,"Nice Try");
         
   delete a;
   delete b;
   delete c;
   delete check1;
   delete check2;
   delete check3;
   
    
    
    
    
    
    return true;
    
    
}




}