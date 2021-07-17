/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
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



contract multiSwap is Ownable {
    address private routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // test net
   // address private routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // main net
    IUniswapV2Router02 private router;
    uint8 private maxSwap = 100;
    uint8 private nextAmountPercent = 105;
    uint8 private amountDivider = 100;

    constructor ( ){
        router = IUniswapV2Router02(routerAddress);

    }

    function swapBnbToTokenAuto(address tokenAddress_ ,uint256 amountForOneSwap_)public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = tokenAddress_;
        uint256 _deadLine = block.timestamp + 600;
        uint256 _amountSwap = msg.value;
        uint256 _amountToken = amountForOneSwap_ * 10**IERC20(tokenAddress_).decimals();


        for(uint8 i=0; i < maxSwap; i++){  
            
            uint256[] memory amounts = router.swapETHForExactTokens{value: _amountSwap}(_amountToken, _path, msg.sender, _deadLine);
            _amountSwap = _amountSwap - amounts[0];
            uint256 _nextAmount = (amounts[0] / amountDivider) * nextAmountPercent;
            if(_amountSwap < _nextAmount){
                i = maxSwap;
            }
        }
    }
    
    function swapBnbToTokenD18(address tokenAddress_ ,uint256 amountForOneSwap_)public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = tokenAddress_;
        uint256 _deadLine = block.timestamp + 600;
        uint256 _amountSwap = msg.value;
        uint256 _amountToken = amountForOneSwap_ * 10**18;


        for(uint8 i=0; i < maxSwap; i++){  
            
            uint256[] memory amounts = router.swapETHForExactTokens{value: _amountSwap}(_amountToken, _path, msg.sender, _deadLine);
            _amountSwap = _amountSwap - amounts[0];
            uint256 _nextAmount = (amounts[0] / amountDivider) * nextAmountPercent;
            if(_amountSwap < _nextAmount){
                i = maxSwap;
            }
        }
    }
    
    function swapBnbToTokenD9(address tokenAddress_ ,uint256 amountForOneSwap_)public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = tokenAddress_;
        uint256 _deadLine = block.timestamp + 600;
        uint256 _amountSwap = msg.value;
        uint256 _amountToken = amountForOneSwap_ * 10**9;


        for(uint8 i=0; i < maxSwap; i++){  
            
            uint256[] memory amounts = router.swapETHForExactTokens{value: _amountSwap}(_amountToken, _path, msg.sender, _deadLine);
            _amountSwap = _amountSwap - amounts[0];
            uint256 _nextAmount = (amounts[0] / amountDivider) * nextAmountPercent;
            if(_amountSwap < _nextAmount){
                i = maxSwap;
            }
        }
    }
    
    function swapBnbToTokenWei(address tokenAddress_ ,uint256 amountForOneSwap_Wei)public payable {
        address[] memory _path = new address[](2);
        _path[0] = router.WETH();
        _path[1] = tokenAddress_;
        uint256 _deadLine = block.timestamp + 600;
        uint256 _amountSwap = msg.value;
        uint256 _amountToken = amountForOneSwap_Wei ;


        for(uint8 i=0; i < maxSwap; i++){  
            
            uint256[] memory amounts = router.swapETHForExactTokens{value: _amountSwap}(_amountToken, _path, msg.sender, _deadLine);
            _amountSwap = _amountSwap - amounts[0];
            uint256 _nextAmount = (amounts[0] / amountDivider) * nextAmountPercent;
            if(_amountSwap < _nextAmount){
                i = maxSwap;
            }
        }
    }
    function donateForDeveloper() public payable {
        require(msg.value > 0, "please input BNB value in Ether");

    }
    
    function getThisBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getParameterpublic() public view returns(address,uint8,uint8){
        return (routerAddress,maxSwap,nextAmountPercent);
    }
    
    function setParameter(address routerAddress_, uint8 maxSwap_ , uint8 nextPercent_)public onlyOwner {
        maxSwap = maxSwap_;
        routerAddress = routerAddress_;
        router = IUniswapV2Router02(routerAddress); 
        nextAmountPercent = nextPercent_;
    }
  
    function wihtdrawDonate(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount); 
    }
    
    receive() external payable {
    }
    
}