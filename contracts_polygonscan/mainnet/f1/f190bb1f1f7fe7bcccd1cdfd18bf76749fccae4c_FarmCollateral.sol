/**
 *Submitted for verification at polygonscan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.4.22 <0.9.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    
    
    
}

contract FarmCollateral {

    string public constant name = "Quickswap MATIC USDT";
    string public constant symbol = "ACFWMATICUSDT";
    uint8 public constant decimals = 18;  
    address public RELEVANTLP = 0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3;
    address public DualFarm = 0xc0eb5d1316b835F4B584B59f922d9c87cA5053E5;
    uint256 constant ghostImplied = 1000;
    uint256 constant PRECISION = 10**18;
    uint256 constant PRECISIONSQ = 10**36;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC on Polygon
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT on Polygon
    address constant dQuick = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address constant Quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address constant QuickRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    mapping(address => address) oracle;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


  constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
//	oracle[tokenA] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // oracle WMATIC
//	oracle[tokenB] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // oracle USDT
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

//function assignOracle(address token, address oracle){
    
 //   oracle[token] = oracle;
    
 //   return true;
    
    
// }





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
    
    
    function BountyCompound_one() external returns (bool){
        
        DualFarmQuickswap(DualFarm).getReward();
        return true;
    }
    
    
    
    function BountyCompound_two() external returns (bool){
        
         DQuick(dQuick).leave(IERC20(dQuick).balanceOf(address(this)));
         return true;
    }
    
    function BountyCompound_three(address hunter) external returns (bool){
        
  //      address[] memory path = new address[](2);
  //      path[0]= Quick;
   //     path[1]= WMATIC;
   //     address[] memory path3 = new address[](2);
    //    path3[1]= WMATIC;
  //      path3[2]= USDT;
        
        
   //     uint256 bounty1Inflated = IERC20(Quick).balanceOf(address(this)).mul(10**18);
   //     uint256 bounty1Prep = bounty1Inflated.div(1001);
   //     uint256 bounty1 = bounty1Prep.div(10**17);
        
   //     uint256 bounty2Inflated = IERC20(WMATIC).balanceOf(address(this)).mul(10**18);
   //     uint256 bounty2Prep = bounty2Inflated.div(1001);
   //     uint256 bounty2 = bounty2Prep.div(10**17);
        
        
        IERC20(Quick).transfer(hunter,IERC20(Quick).balanceOf(address(this)).div(1001) );
        IERC20(WMATIC).transfer(hunter, IERC20(WMATIC).balanceOf(address(this)).div(1001));
        
        return true;
        
        
    }
    
    function BountyCompound_four() external returns (bool){
     
     
      IERC20(Quick).approve(QuickRouter,IERC20(Quick).balanceOf(address(this)) );
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
         address[] memory path = new address[](2);
        path[0]= Quick;
        path[1]= WMATIC;
        
        
        
        Uniswap(QuickRouter).swapExactTokensForTokens(IERC20(Quick).balanceOf(address(this)),0,path,address(this),block.timestamp);
        
        return true;
     
        
    }
    
    
    function getHalf(uint256 input) internal pure returns (uint){
        
        uint value = input.div(2);
    return   value;
        
    }
    
    
    
    function BountyCompound_five() external returns (bool){
        
          address[] memory path3 = new address[](2);
        path3[0]= WMATIC;
        path3[1]= USDT;
        
        uint256 balanceMatic= IERC20(WMATIC).balanceOf(address(this));
        uint desiredValue= getHalf(balanceMatic);
        
       
        
         IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        Uniswap(QuickRouter).swapExactTokensForTokens(desiredValue,0,path3,address(this),block.timestamp);
        return true;
    }
    
    function BountyCompound_six() external returns (bool) {
        
         IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        IERC20(USDT).approve(QuickRouter,IERC20(USDT).balanceOf(address(this)) );
        
        
        Uniswap(QuickRouter).addLiquidity(USDT,WMATIC,IERC20(USDT).balanceOf(address(this)),IERC20(WMATIC).balanceOf(address(this)),0,0,address(this),block.timestamp);
        return true;
    }
    
    function BountyCompound_seven() external returns (bool){
        
        IERC20(RELEVANTLP).approve(DualFarm,IERC20(RELEVANTLP).balanceOf(address(this)));
        DualFarmQuickswap(DualFarm).stake(IERC20(RELEVANTLP).balanceOf(address(this)));
        return true;
    }
    
    
    
    
    
    function BountyCompound(address hunter) external returns (bool){
        
        
        DualFarmQuickswap(DualFarm).getReward();
        DQuick(dQuick).leave(IERC20(dQuick).balanceOf(address(this)));
        address[] memory path = new address[](2);
        path[0]= Quick;
        path[1]= WMATIC;
        address[] memory path3 = new address[](2);
        path3[0]= WMATIC;
        path3[1]= USDT;
        
        
        uint256 bounty1Inflated = IERC20(Quick).balanceOf(address(this)).mul(10**18);
        uint256 bounty1Prep = bounty1Inflated.div(1001);
        uint256 bounty1 = bounty1Prep.div(10**17);
        
        uint256 bounty2Inflated = IERC20(WMATIC).balanceOf(address(this)).mul(10**18);
        uint256 bounty2Prep = bounty2Inflated.div(1001);
        uint256 bounty2 = bounty2Prep.div(10**17);
        
        
        IERC20(Quick).transfer(hunter,bounty1 );
        IERC20(WMATIC).transfer(hunter, bounty2);
        
        
        IERC20(Quick).approve(QuickRouter,IERC20(Quick).balanceOf(address(this)) );
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        
        uint256 fakebalance = IERC20(WMATIC).balanceOf(address(this)).mul(10**18);
        uint256 testbalance = fakebalance.div(2);
        uint256 maticBalance = testbalance.div(10**18);
        
        
        Uniswap(QuickRouter).swapExactTokensForTokens(IERC20(Quick).balanceOf(address(this)),0,path,address(this),block.timestamp);
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        Uniswap(QuickRouter).swapExactTokensForTokens(maticBalance,1,path3,address(this),block.timestamp);
        IERC20(WMATIC).approve(QuickRouter,IERC20(WMATIC).balanceOf(address(this)) );
        IERC20(USDT).approve(QuickRouter,IERC20(USDT).balanceOf(address(this)) );
        
        
        Uniswap(QuickRouter).addLiquidity(USDT,WMATIC,IERC20(USDT).balanceOf(address(this)),IERC20(WMATIC).balanceOf(address(this)),0,0,address(this),block.timestamp);
        IERC20(RELEVANTLP).approve(DualFarm,IERC20(RELEVANTLP).balanceOf(address(this)));
        DualFarmQuickswap(DualFarm).stake(IERC20(RELEVANTLP).balanceOf(address(this)));
        
        
        
        
        
        
        return true;
        
    }
    
     function withdrawLP(
        
        uint256 _amount
        
        
        
       )
    external returns (bool) {
        DualFarmQuickswap(DualFarm).withdraw(calcToWithdraw(_amount));
        IERC20(RELEVANTLP).transfer(msg.sender,calcToWithdraw(_amount));
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





//function getChainlinkPrice(address oracle){
    
    
 //   uint256 price = Chainlink(oracle).latestAnswer();
   
    
    
 //   return price ;
    
//}

//function getDecimal(address token){
    
  //  return Chainlink(token).decimals();
//}

//function updateOracle(){
    
 //   return 
//}

//function getNaiveLpPprice(address token0, address token1){
    
    
  //  uint256 token0Value = getChainlinkPrice(oracle[token0]).mul(QuickSwap(RELEVANTLP).getReserves()[0]);
  //  uint256 token1Value = getChainlinkPrice(oracle[token1]).mul(QuickSwap(RELEVANTLP).getReserves()[1]);
    
 //   if (decimals[token0] == decimals[token1]) {
     
 //    uint256 precAdjusted = decimals[token0]+
     
        
  //  }
 //   }
    
 //   lpTotalValue
//}
    
    
    
    
//}

//function getNaiveDerivativeLpPrice(){

    
//}
    
}








    
// }

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