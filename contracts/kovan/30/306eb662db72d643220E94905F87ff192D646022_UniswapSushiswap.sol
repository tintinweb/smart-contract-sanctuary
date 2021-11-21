/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.5.0;

interface IUniswapV2Router01 {
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.5.0;

contract IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity ^0.5.0;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address owner) external view returns(uint);
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

contract UniswapSushiswap {
    
    IUniswapV2Router02 uniswap;
    IUniswapV2Router02 sushiswap;
    
    IWeth weth;
    IERC20 dai;
    IERC20 bat;
    
    address payable private owner;
    
    constructor() public {
      uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      sushiswap = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
      
      owner = msg.sender;
      
      weth = IWeth(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
      dai = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
      bat = IERC20(0x482dC9bB08111CB875109B075A40881E48aE02Cd);
    }
    
    function setAddresses(address _dai, address _bat) public onlyOwner {
        dai = IERC20(_dai);
        bat = IERC20(_bat);
    }
    
    function swap(uint256 _amount, bool _isUni) public onlyOwner {
        if(_isUni){
            uni(_amount, false);
            require(sushi(bat.balanceOf(address(this)), true) > _amount, 'did not profit');
        }else{
            sushi(_amount, false);
            require(uni(bat.balanceOf(address(this)), true) > _amount, 'did not profit');
        }
    }
    
    function withDraw(address coin, uint256 _amount) public onlyOwner {
        IERC20(coin).transfer(msg.sender, _amount);
    }
    
    function sushi(uint256 _amount, bool isSell) public onlyOwner returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(bat);
        if(isSell){
            bat.approve(address(sushiswap), _amount);
            path[0] = address(bat);
            path[1] = address(dai);
        }else{
            dai.approve(address(sushiswap), _amount);
        }
        return swap(_amount, path, sushiswap);
    }
    
    function uni(uint256 _amount, bool isSell) public onlyOwner returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(bat);
        if(isSell){
            bat.approve(address(uniswap), _amount);
            path[0] = address(bat);
            path[1] = address(dai);
        }else{
            dai.approve(address(uniswap), _amount);
        }
        return swap(_amount, path, uniswap);
    }
    
    event Log(uint[] am);
    
    function swap(uint256 _amount, address[] memory path, IUniswapV2Router02 router) private returns(uint256) {
        uint[] memory minOuts = router.getAmountsOut(_amount, path); 
        uint outDai = router.swapExactTokensForTokens(
            _amount, 
            minOuts[1], 
            path, 
            address(this), 
            now
        )[1];
        return outDai;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    
    function() external payable {}
}