/**
 *Submitted for verification at polygonscan.com on 2021-11-10
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
    function skim(address to) external;
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

contract FarmCollateral {

    string public constant name = "Quickswap MATIC USDT";
    string public constant symbol = "WMATICUSDTQUICKDUAL";
    uint8 public constant decimals = 18;  
    address public RELEVANTLP = 0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3;
    address public DualFarm = 0xc0eb5d1316b835F4B584B59f922d9c87cA5053E5;
    uint256 constant ghostImplied = 1000;
    uint256 constant PRECISION = 10**18;
    uint256 constant BABYPRECISION = 10**4;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC on Polygon
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT on Polygon
    address constant dQuick = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address constant Quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address constant QuickRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  //  int256 public latestAnswer = 0;
    address constant OracleHubAddress = 0xe81C9f94C8A9F92150481589E836980146448719; 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
  //  uint256 constant diff0 = 10**(18-(IERC20(WMATIC).decimals()));                // how to generally get token0 distingusihed???
//    uint256 constant diff1 = 10**(18-(IERC20(USDT).decimals()));
      uint256 diff0 = 10**0;
      uint256 diff1 = 10**12;
    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
   uint256 totalSupply_;

    using SafeMath for uint256;


  constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[0x0000000000000000000000000000000000000000] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
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
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
      function _mint(
        address account,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            account != address(0x0)
        );

        totalSupply_ = totalSupply_.add(amount);

        balances[account] =
        balances[account].add(amount);

       
    }
    
     function _burn(
        address account,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            account != address(0x0)
        );

        balances[account] =
        balances[account].sub(amount);

        totalSupply_ =
        totalSupply_.sub(amount);

        

     
    }

     function deposit(
        
        uint256 _amount
        
       )
    external returns (bool) {
        
       IERC20(RELEVANTLP).transferFrom(msg.sender, address(this),_amount);
       _mint(msg.sender,calcToMint(_amount));
       IERC20(RELEVANTLP).approve(DualFarm,_amount);
       DualFarmQuickswap(DualFarm).stake(_amount);
        
        
        return true;
    }
 
     function BountyCompound(address hunter, uint256 minAmount1, uint256 minAmount2, uint256 minLP1, uint256 minLP2) external returns (bool){
        
        
        DualFarmQuickswap(DualFarm).getReward();
        DQuick(dQuick).leave(IERC20(dQuick).balanceOf(address(this)));
        address[] memory path = new address[](2);
        path[0]= Quick;
        path[1]= WMATIC;
        address[] memory path2 = new address[](2);
        path2[0]= WMATIC;
        path2[1]= USDT;
        
        
        
      
        uint256 bounty1 =IERC20(Quick).balanceOf(address(this)).div(101);
        
       
        uint256 bounty2 = IERC20(WMATIC).balanceOf(address(this)).div(101);
        
        
        IERC20(Quick).transfer(hunter,bounty1 );
        IERC20(WMATIC).transfer(hunter, bounty2);
        
        
        IERC20(Quick).approve(QuickRouter,IERC20(Quick).balanceOf(address(this)) );
  
        Uniswap(QuickRouter).swapExactTokensForTokens(IERC20(Quick).balanceOf(address(this)),minAmount1,path,address(this),block.timestamp);
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        Uniswap(QuickRouter).swapExactTokensForTokens(IERC20(WMATIC).balanceOf(address(this)).div(2),minAmount2,path2,address(this),block.timestamp);
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        IERC20(USDT).approve(QuickRouter,IERC20(USDT).balanceOf(address(this)) );
        Uniswap(QuickRouter).addLiquidity(USDT,WMATIC,IERC20(USDT).balanceOf(address(this)),IERC20(WMATIC).balanceOf(address(this)),minLP1,minLP2,address(this),block.timestamp);
        IERC20(RELEVANTLP).approve(DualFarm,IERC20(RELEVANTLP).balanceOf(address(this)));
        DualFarmQuickswap(DualFarm).stake(IERC20(RELEVANTLP).balanceOf(address(this)));
        
        
        
        
        return true;
        
    }
    
     function withdrawLP(
        
        uint256 _amount
        
        
        
       )
    external returns (bool) {
        DualFarmQuickswap(DualFarm).withdraw(calcToWithdraw(_amount));
        IERC20(RELEVANTLP).transfer(msg.sender,IERC20(RELEVANTLP).balanceOf(address(this)));
        _burn(msg.sender,_amount);
        
        
        
        return true;
    }
        
    
    function getImpliedBalance() internal view returns (uint256) {
        
        uint256 totBalance = DualFarmQuickswap(DualFarm).balanceOf(address(this)) ;
        uint256 returnValue = ghostImplied.add(totBalance);
    
    return returnValue;
    
        
    }
    
    

    function calcToMint( uint256 lpSupplyUser) internal view returns (uint256) {
        
        
    uint256 prepInverseRatio = inflatedRatioCalc().mul(totalSupply_.mul(totalSupply_));
    uint256 InverseInflatedRatio = prepInverseRatio.div(getImpliedBalance().mul(getImpliedBalance()));
    uint256 leftTermPartOne = InverseInflatedRatio.mul(getImpliedBalance().add(lpSupplyUser));
    uint256 toMintPrep = leftTermPartOne.sub(totalSupply_.mul(PRECISION));
    uint256 toMint_ = toMintPrep.div(PRECISION);
    
    return toMint_;
        
        
    }
    
function inflatedRatioCalc() internal view returns (uint256){
    
    uint256 inflatedRatioNum = PRECISION.mul(getImpliedBalance());
    uint256 inflatedRatio = inflatedRatioNum.div(totalSupply_);
    
   return inflatedRatio;
}

function calcToWithdraw(uint256 seekWithdrawAmount) internal view returns (uint256){
    
    uint256 inflatedWithdraw = seekWithdrawAmount.mul(inflatedRatioCalc());
    
    uint256 withdrawReturn = inflatedWithdraw.div(PRECISION);
    
    return withdrawReturn;
    
    
}






function latestAnswer() external view returns (int256){

    address oracleWMATIC = Oraclehub(OracleHubAddress).showOracleAddress(WMATIC) ;
    address oracleUSDT = Oraclehub(OracleHubAddress).showOracleAddress(USDT) ;
     
    
    (uint256 Res0, uint256 Res1,) = QuickSwap(RELEVANTLP).getReserves();
    uint256 latestPrice0=  uint256(Chainlink(oracleWMATIC).latestAnswer());
    uint256 latestPrice1=  uint256(Chainlink(oracleUSDT).latestAnswer());
    uint256 chainlinkDiff0 = 10**(18-Chainlink(oracleWMATIC).decimals());
    uint256 chainlinkDiff1 = 10**(18-Chainlink(oracleUSDT).decimals());
    uint256 totalValue = (Res0*diff0*chainlinkDiff0*latestPrice0 )+(Res1*diff1*chainlinkDiff1*latestPrice1 ) ; // careful its 10^36 here so that latestAnswer gets correct rpecision after dividing
    
    uint256 answerPrep = inflatedRatioCalc()*totalValue/(QuickSwap(RELEVANTLP).totalSupply());
    uint256 answerPrep2 = answerPrep.div(PRECISION);
    int256 answer = int256(answerPrep2);
    
    
     
     uint256  ratio = (Res1*diff1)*PRECISION/Res0*diff0;
     uint256  ratioChainLink =  latestPrice0*chainlinkDiff0*PRECISION/(latestPrice1*chainlinkDiff1);
     
     uint256 check = ratio*BABYPRECISION/ratioChainLink;
     
    require (check >9850 && check<10150,"Nice Try");
    
    
    return answer;
}





}






library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
}