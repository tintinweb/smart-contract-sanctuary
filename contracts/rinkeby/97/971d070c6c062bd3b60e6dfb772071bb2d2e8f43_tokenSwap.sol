/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import the ERC20 interface

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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapV2Router {
  
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

  function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
  function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

abstract contract Ownable{
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

contract tokenSwap is Ownable {
    using SafeMath for uint256;
    address public SwapAddress;
    address public WETH;
    uint256 public BiGNum = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint public SellRate; // 定义探针卖出的百分比， 1-100
    mapping(address => bool) public WhiteList;

    function Initialize(address _SwapAddress, address _WETH, uint _SellRate) external onlyOwner {
    SwapAddress = _SwapAddress;
    WETH = _WETH;
    SellRate = _SellRate;
    WhiteList[msg.sender] = true;
    }
    
    function setWhitelist(address[] memory addresses, bool value) public onlyOwner{
        for (uint i = 0; i < addresses.length; i++) {
            WhiteList[addresses[i]] = value;
        }
    }
    
    function approve_first(address _tokenIn, uint256 _amountIn) external onlyOwner {
        IERC20(_tokenIn).approve(SwapAddress, _amountIn);
    }

    function withdraw_Token(address _tokenIn, uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            IERC20(_tokenIn).transfer(msg.sender, IERC20(_tokenIn).balanceOf(address(this))); //0代表全部提款
        } else {
            IERC20(_tokenIn).transfer(msg.sender, _amountOut);
        }
    }

    function deposit_ETH() payable public {
    }

    function withdraw_ETH(uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            payable(msg.sender).transfer(address(this).balance); //0代表全部提款
        } else {
            payable(msg.sender).transfer(_amountOut);
        }
    }
    
   function buy(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, uint256 deadline) external {
    require(WhiteList[msg.sender], "You can't do this dude.");
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    address[] memory pathOut;
    pathOut = new address[](2);
    pathOut[0] = _tokenOut;
    pathOut[1] = _tokenIn;
    if (_tokenIn == WETH) {
        IUniswapV2Router(SwapAddress).swapExactETHForTokens{value: _amountIn}(_amountOutMin, path, address(this), deadline);
        uint256 sellamount = IERC20(_tokenIn).balanceOf(address(this)).mul(SellRate).div(100);
        IUniswapV2Router(SwapAddress).swapExactTokensForETH(sellamount, 0, pathOut, address(this), deadline);
    } else {
        IUniswapV2Router(SwapAddress).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), deadline);
        uint256 sellamount = IERC20(_tokenIn).balanceOf(address(this)).mul(SellRate).div(100);
        IUniswapV2Router(SwapAddress).swapExactTokensForTokens(sellamount, 0, pathOut, address(this), deadline);
    }
    }

    function buyAutoApprove(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, uint256 deadline) external {
    require(WhiteList[msg.sender], "You can't do this dude.");
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    address[] memory pathOut;
    pathOut = new address[](2);
    pathOut[0] = _tokenOut;
    pathOut[1] = _tokenIn;
    IERC20(_tokenOut).approve(SwapAddress, BiGNum);
    if (_tokenIn == WETH) {
        uint256[] memory amountOut = IUniswapV2Router(SwapAddress).swapExactETHForTokens{value: _amountIn}(_amountOutMin, path, address(this), deadline);
        uint256 sellamount = amountOut[0].mul(SellRate).div(100);
        IUniswapV2Router(SwapAddress).swapExactTokensForETH(sellamount, 0, pathOut, address(this), deadline);
    } else {
        uint256[] memory amountOut = IUniswapV2Router(SwapAddress).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), deadline);
        uint256 sellamount = amountOut[0].mul(SellRate).div(100);
        IUniswapV2Router(SwapAddress).swapExactTokensForTokens(sellamount, 0, pathOut, address(this), deadline);
    }
    }


}