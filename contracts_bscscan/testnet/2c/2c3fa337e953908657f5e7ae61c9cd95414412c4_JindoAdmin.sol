/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity ^0.6.12;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);


    
    function transfer(address recipient, uint256 amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
function createInitialPair(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external   returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
         address token0,
        address token1,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
         address token0,
        address token1,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin,  address token0,
        address token1 , address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin,  address token0,
        address token1, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract JindoAdmin{
    using SafeMath for uint;
    struct PairInfo{
        address _tokenA;
        address _tokenB;
        uint _amountADesired;
        uint _amountBDesired;
        uint _amountAMin;
        uint _amountBMin;
        address _to;
        address _poolCreator;
        uint _deadline;
    }
          uint[] public pairs; 
          mapping(address=>bool) public adminList;

          modifier  onlyAdmin(address user){
              require(adminList[user],"Error: JindoAdmin: Only Admin can call this function");
              _;
          }
        function updateAdmin(address user, bool rights)public onlyAdmin(msg.sender){
            adminList[user]=rights;
        }
    
    uint public counter;
    IPancakeRouter02 public  router;
    mapping(uint=>PairInfo)public idToPair;
    
    constructor(address _router)public{
        router=IPancakeRouter02(_router);
        adminList[msg.sender]=true;
    }
    function updateRouter(address _router)public{
        router=IPancakeRouter02(_router);
    }
     function registrationRequest(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual  returns (uint amountA, uint amountB, uint liquidity) {
PairInfo memory pair= PairInfo( tokenA,tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to,msg.sender, deadline);
   idToPair[counter]= pair;
   pairs.push(counter);
   getpairedCcoins(counter);
   counter++;
    }
    function getpairedCcoins(uint id)public{
         PairInfo memory pair= idToPair[id];
        IERC20(pair._tokenA).transferFrom(pair._poolCreator,address(this),pair._amountADesired);
            IERC20(pair._tokenB).transferFrom(pair._poolCreator,address(this),pair._amountBDesired);

    }
    function approve(uint id) public returns (uint amountA, uint amountB, uint liquidity){
    PairInfo memory pair= idToPair[id];
    IERC20(pair._tokenA).approve(address(router),pair._amountADesired);
    IERC20(pair._tokenB).approve(address(router),pair._amountBDesired);
    
    // uint preTransferBalanceA= IERC20(pair._tokenA).balanceOf(address(this));
    // uint preTransferBalanceB= IERC20(pair._tokenB).balanceOf(address(this));
    
    uint deadline=block.timestamp + 1 days;
    router.createInitialPair(pair._tokenA,pair._tokenB,pair._amountADesired,pair._amountBDesired,pair._amountAMin,pair._amountBMin,pair._to,deadline);
   /*
    uint postTransferBalanceA= IERC20(pair._tokenA).balanceOf(address(this));
    uint postTransferBalanceB= IERC20(pair._tokenB).balanceOf(address(this));
    uint transferredA= preTransferBalanceA.sub(postTransferBalanceA);
    uint transferredB= preTransferBalanceB.sub(postTransferBalanceB);
    uint differenceA= pair._amountADesired.sub(transferredA);
    uint differenceB= pair._amountBDesired.sub(transferredB);
    
    
    
    IERC20(pair._tokenA).transfer(pair._poolCreator,differenceA);
   IERC20(pair._tokenB).transfer(pair._poolCreator,differenceB);
*/
   delete idToPair[id];
  delete pairs[id];
    
}
function reject(uint id) public{
    PairInfo memory pair= idToPair[id];
    uint refundTokenA= pair._amountADesired;
    uint refundTokenB= pair._amountBDesired;
     address receiver =pair._poolCreator;
    
    IERC20(pair._tokenA).transfer(receiver,refundTokenA);
   IERC20(pair._tokenB).transfer(receiver,refundTokenB);
   delete idToPair[id];
  delete pairs[id];
    
}
}