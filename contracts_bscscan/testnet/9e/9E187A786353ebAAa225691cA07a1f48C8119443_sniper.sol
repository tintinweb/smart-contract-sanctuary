/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity 0.6.2;



interface pinksale{
    function contribute() external payable ;
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



interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract sniper{


    address pancakeSwapAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address WBNBAddress =0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; 

    function snipePancakeSwap(address tokenAddress,uint256 amountToBuy,address[] memory walletAddresses,uint256 howManyTransactionToDo,uint256 slippage) public payable{
        IPancakeRouter01 _CONTRACT = IPancakeRouter01(pancakeSwapAddress);
           address[] memory path = new address[](2);
            path[0] = WBNBAddress;
            path[1] = tokenAddress;
            uint256 amountOutMin = 0;

            for(uint j=0; j < howManyTransactionToDo ; j++){
                for(uint i=0;i < walletAddresses.length;i++){
                    if(slippage>0){
                        amountOutMin = _CONTRACT.getAmountsOut(amountToBuy,path)[1]*((100-slippage)/100);              
                    }
                    _CONTRACT.swapExactETHForTokens{value: amountToBuy }(
                        amountOutMin,
                        path,
                        walletAddresses[i], 
                        block.timestamp+100);
                }
            }            
                        
           if(address(this).balance!=0){
               msg.sender.transfer(address(this).balance);
           }
            
    }


    // function pinksalePresale(address presaleAddress,uint256 amountToBuy,address[] memory walletAddresses,uint256 howManyTransactionToDo) public payable {
    //     pinksale _CONTRACT = pinksale(presaleAddress);
    //     for(uint256 j=0;j<howManyTransactionToDo;j++){
    //         for(uint256 i=0;i<walletAddresses.length;i++){
    //             _CONTRACT.contribute{value:amountToBuy}();
    //         }
    //     }
    //     if(address(this).balance!=0){
    //            msg.sender.transfer(address(this).balance);
    //     }
    // }
}