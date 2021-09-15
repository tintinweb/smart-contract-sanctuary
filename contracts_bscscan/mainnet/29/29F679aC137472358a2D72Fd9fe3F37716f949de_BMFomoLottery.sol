/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IPancakeRouter01 {
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
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BMFomoLottery{
    IPancakeRouter02 router;
    IBEP20 BurningMoon;
    address BM=0x97c6825e6911578A515B11e25B552Ecd5fE58dbA;
    address owner;
    
    uint256 public MinBuy=10**16;
    uint256 public MaxTimeBetweenBuys=5 minutes;
    uint256 public MinTimeBetweenBuys=30 seconds;
    uint256 public ReductionTimeForeachBuy=1 seconds;
    uint256 public Tax=10;
    address public LastBuyer;
    uint256 public LastBuyTimestamp;
    uint256 public CurrentTimespan=MaxTimeBetweenBuys;
    
    
    constructor()
    {
        router=IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        BurningMoon=IBEP20(BM);
        owner=msg.sender;
    }    
    function SetValues(uint256 minBuy, uint256 maxTimeBetweenBuys, uint256 minTimeBetweenBuys,
    uint256 reductionTimeForeachBuy, uint256 tax) public
    {
        require(msg.sender==owner);
        require(tax<100);
        MinBuy=minBuy;
        MaxTimeBetweenBuys=maxTimeBetweenBuys;
        MinTimeBetweenBuys=minTimeBetweenBuys;
        ReductionTimeForeachBuy=reductionTimeForeachBuy;
        Tax=tax;
    }
    receive() external payable{
        BuyBM();
    }
    function BuyBM() public payable{
        require(msg.value>=MinBuy,"Value needs to be at least MinBuy");
        
        //Buy BM
        address[] memory path = new address[](2);
        path[1] = BM;
        path[0] = router.WETH();
        
        uint256 initialBalance=BurningMoon.balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 newBalance=BurningMoon.balanceOf(address(this))-initialBalance;
        BurningMoon.transfer(msg.sender,newBalance*(100-Tax)/100);
        
        if((block.timestamp>LastBuyTimestamp+CurrentTimespan)&&(LastBuyer!=address(0))){
            CurrentTimespan=MaxTimeBetweenBuys;
            BurningMoon.transfer(LastBuyer,BurningMoon.balanceOf(address(this)));
        } else if((CurrentTimespan-ReductionTimeForeachBuy)<MinTimeBetweenBuys)
            CurrentTimespan=MinTimeBetweenBuys;
        else CurrentTimespan-=ReductionTimeForeachBuy;
        
        LastBuyTimestamp=block.timestamp;
        LastBuyer=msg.sender;
    }
    function getSecondsLeft() public view returns (uint256){
        if(block.timestamp<(LastBuyTimestamp+CurrentTimespan))
            return block.timestamp-(LastBuyTimestamp+CurrentTimespan);
        return 0;
    }
    
    
    
    
    
    
    
    
}