/**
 *Submitted for verification at Etherscan.io on 2022-01-22
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function withdraw(uint256 _amount) external;
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

contract MaiYuShou is Ownable {
    using SafeMath for uint256;
    address public SwapAddress;
    address public YuShouAddress;
    address public pToken;
    address public Token;
    address public DAI;
    uint256 public BiGNum = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint public unTaxed;

    fallback() external payable {} //允许合约接收eth

    function Initialize(address _SwapAddress, address _YuShouAddress, address _pToken, address _Token, address _DAI) external onlyOwner {
    SwapAddress = _SwapAddress;
    YuShouAddress = _YuShouAddress;
    pToken = _pToken;
    Token = _Token;
    DAI = _DAI;
    }
    
    function approve_first() external onlyOwner {
        IERC20(pToken).approve(YuShouAddress, BiGNum);
        IERC20(Token).approve(SwapAddress, BiGNum);
    }

    function withdraw_Token(address _tokenIn, uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            IERC20(_tokenIn).transfer(msg.sender, IERC20(_tokenIn).balanceOf(address(this))); //0代表全部提款
        } else {
            IERC20(_tokenIn).transfer(msg.sender, _amountOut);
        }
    }
    

    function clain_and_sell(uint256 _amountOutMin) external onlyOwner {
        address[] memory path;
        path[0] = Token;
        path[1] = DAI;
        IUniswapV2Router(YuShouAddress).withdraw(IERC20(pToken).balanceOf(address(this)));
        IUniswapV2Router(SwapAddress).swapExactTokensForTokens(IERC20(Token).balanceOf(address(this)), _amountOutMin, path, address(this), block.timestamp);
    }

}