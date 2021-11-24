// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IPancakeRouter {
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ATEST {
  using SafeMath for uint256;

  IPancakeRouter private router;
  address private constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  address public liquidityPool = 0x872a6bBb513a0AA390d25D0AA1A3011b389E4BB2;
  address public apesAddress = 0xaA9757e593690F4E4eD72298D5bF88491bb71a86;

  modifier onlyOwner() {
      require(owner() == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  constructor() {
      router = IPancakeRouter(routerAddress);
  }

  function owner() public view virtual returns (address) {
      return 0x27F9523afe7e869a842A6942C72D91c34269B603;
  }

  function getPrice() public view returns(uint) {
    (uint reserve0, uint reserve1,) = IPancakePair(liquidityPool).getReserves();
    uint amountIn = router.getAmountIn(1000000000, reserve1, reserve0);
    return amountIn;
  }

  function buy() public payable {
    uint256 modulo = msg.value % getPrice();
    uint256 usedAmount = msg.value - modulo;
    uint256 numTokens = usedAmount * 10**9 / getPrice();

    require(IERC20(apesAddress).balanceOf(address(this)) >= numTokens, "No more token to fulfill this request.");

    (bool sent) = IERC20(apesAddress).transfer(msg.sender, numTokens);
    require(sent, "Failed to transfer token to user");
    //emit BuyTokens(msg.sender, usedAmount, numTokens);

    //soldTokens += numTokens;
    payable(msg.sender).transfer(modulo);

    IERC20(apesAddress).approve(routerAddress, usedAmount);
    router.addLiquidityETH{value: usedAmount}(apesAddress, usedAmount, 0, 0, owner(), block.timestamp);
  }

  function swapAndLiquify(uint256 _toLiquidity) public payable onlyOwner {
      uint256 half = _toLiquidity.div(2);
      uint256 otherHalf = _toLiquidity.sub(half);

      IERC20(apesAddress).approve(routerAddress, half);
      address[] memory path = new address[](2);
      path[0] = apesAddress;
      path[1] = router.WETH();
      router.swapExactTokensForETHSupportingFeeOnTransferTokens(half, 0, path, address(this), block.timestamp);

      uint256 ethBalance = address(this).balance;

      IERC20(apesAddress).approve(routerAddress, otherHalf);
      router.addLiquidityETH{value: ethBalance}(apesAddress, otherHalf, 0, 0, owner(), block.timestamp);
      // emit SwapAndLiquify(half, ethBalance, otherHalf);
  }

  receive() external payable virtual {
    buy();
  }


}