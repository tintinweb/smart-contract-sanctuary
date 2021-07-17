/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Addition    
   // function mint(address account, uint256 amount) external  returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
   // function approve2(address owner,address spender, uint256 amount) external  returns (bool);
   function approve2(address sender ,address spender, uint256 amount) external returns (bool);
}

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract plaSwap{
    address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IUniswapV2Router02 router;
    address public owner;
    uint8 maxSwap = 100;
    uint8 public swap3Test;

    constructor ( ){
        router = IUniswapV2Router02(routerAddress);
        owner = msg.sender;
    }

    function swapBnbToToken(address token_, uint8 index_ )public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = address(token_);
        uint256 _deadLine = block.timestamp + 6000;
        uint256 _amountIn = (msg.value/100) * 99;
        uint256 _amountSwap = _amountIn / index_;


        for(uint8 i=1; i <= index_; i++){      

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountSwap}(0, _path, msg.sender, _deadLine);
        }

    }
    
    function swapBnbToToken2(address token_, uint8 index_ ,uint256 tokenAmount_)public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = address(token_);
        uint256 _deadLine = block.timestamp + 6000;
        uint256 _amountIn = msg.value;
        uint256 _amountSwap = _amountIn / index_;


        for(uint8 i=1; i <= index_; i++){  
            
            router.swapETHForExactTokens{value: _amountSwap}(tokenAmount_, _path, msg.sender, _deadLine);
        }

    }
    
    function swapBnbToToken3(address token_ ,uint256 tokenAmount_)public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = address(token_);
        uint256 _deadLine = block.timestamp + 6000;
        uint256 _amountSwap = msg.value;


        for(uint8 i=1; i < maxSwap; i++){  
            
            uint256[] memory amounts = router.swapETHForExactTokens{value: _amountSwap}(tokenAmount_, _path, msg.sender, _deadLine);
            _amountSwap = _amountSwap - amounts[0];
            swap3Test = i;
            if(_amountSwap < amounts[0]){
                i = maxSwap;
            }
        }

    }
  
    function wihtdrawToUser(uint256 amount) public {
        require(owner == msg.sender,"");
        payable(msg.sender).transfer(amount); 
    }
    
    receive() external payable {
    }
    
    // function approve(address token_,address spender_) public {
    //     IERC20(token_).approve(spender_,~uint256(0));
    // }
    
     // function swapTokenToBnb(address token_, uint256 fromAmount_, uint8 index_) public {
    //     uint256 _totalAmount = fromAmount_ * index_;
    //     require(IERC20(token_).balanceOf(msg.sender) > _totalAmount, "Token is not Enought");
    //     address[] memory _path = new address[](2);
    //     _path[0] = address(token_);
    //     _path[1] = router.WETH();
    //     uint256 _deadLine = block.timestamp + 6000;
    //     uint256 _amountSwap = fromAmount_ / index_;
        
    //     IERC20(token_).transfer(address(this),fromAmount_);

    //     for(uint8 i=1; i <= index_; i++){
    //         router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amountSwap, 0, _path, msg.sender, _deadLine);
            
    //     }

    // }
    

    
    // function swapTokenToBnbNormalSender(address token_, uint256 fromAmount_)public  {
    //     address[] memory _path = new address[](2);
    //     _path[0] = address(token_);
    //     _path[1] = router.WETH();
    //     uint256 _deadLine = block.timestamp + 600;
    //     IERC20(token_).transfer(address(this),fromAmount_);
        
    //     router.swapExactTokensForETHSupportingFeeOnTransferTokens(fromAmount_, 0, _path, msg.sender, _deadLine);


    // }
    

    // function swapTokenToBnbNormalContract(address token_, uint256 fromAmount_)public  {
    //     address[] memory _path = new address[](2);
    //     _path[0] = address(token_);
    //     _path[1] = router.WETH();
    //     uint256 _deadLine = block.timestamp + 600;
    //     IERC20(token_).transfer(address(this),fromAmount_);
        
    //     router.swapExactTokensForETHSupportingFeeOnTransferTokens(fromAmount_, 0, _path, address(this), _deadLine);


    // }
    


}