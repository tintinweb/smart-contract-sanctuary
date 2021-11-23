pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IFinsPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swapFee() external view returns (uint32);
    function devFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
    function setDevFee(uint32) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IFinsRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapFeeReward() external pure returns (address);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

contract YieldOptimizer {
    using SafeMath for uint;

    address constant public PANCAKE_FACTORY_ADDRESS = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address constant public PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant public AUTOSHARK_ROUTER_ADDRESS = 0xB0EeB0632bAB15F120735e5838908378936bd484;

    address constant public CAKE_BNB_TOKEN_ADDRESS = 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
    address constant public AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS = 0xCe39f9c2FffE30E093b54DcEa5bf45C727290985;

    address constant public CAKE_TOKEN_ADDRESS = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address constant public BNB_TOKEN_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant public USDT_TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    address constant public USDT_BNB_TOKEN_ADDRESS = 0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;

    address constant public FINS_TOKEN_ADDRESS = 0x1b219Aca875f8C74c33CFF9fF98f3a9b62fCbff5;
    address constant public FINS_BNB_TOKEN_ADDRESS = 0x14B5a6d26577970953F9E6608d6604e4676Ac5b7;

    address constant public AUTOSHARK_FACTORY_ADDRESS = 0xe759Dd4B9f99392Be64f1050a6A8018f73B53a13;

    address payable immutable private owner;
    IUniswapV2Router02 immutable private pancakeRouter;
    IFinsRouter02 immutable private autosharkRouter;

    constructor(address payable _owner) public {
      require(msg.sender == _owner);
      owner = _owner;
      pancakeRouter = IUniswapV2Router02(PANCAKE_ROUTER_ADDRESS);
      autosharkRouter = IFinsRouter02(AUTOSHARK_ROUTER_ADDRESS);
      approveMyselfForTokens();
    }

    function appendUintToString(string memory inStr, uint v) view public returns (string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function escapeHatch() public {
        require(msg.sender==owner);
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
        uint balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
        tokenApi = IERC20(BNB_TOKEN_ADDRESS);
        balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
        tokenApi = IERC20(USDT_TOKEN_ADDRESS);
        balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
        tokenApi = IERC20(FINS_TOKEN_ADDRESS);
        balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
    }

    function approveMyselfForTokens() private {
      IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
      uint allowance = tokenApi.allowance(address(this), PANCAKE_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000) {
        tokenApi.approve(PANCAKE_ROUTER_ADDRESS, 1000000000000000000000000);
      }
      tokenApi = IERC20(BNB_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(this), PANCAKE_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000) {
        tokenApi.approve(PANCAKE_ROUTER_ADDRESS, 1000000000000000000000000);
      }
      tokenApi = IERC20(USDT_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(this), PANCAKE_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000) {
        tokenApi.approve(PANCAKE_ROUTER_ADDRESS, 1000000000000000000000000);
      }
      tokenApi = IERC20(BNB_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(this), AUTOSHARK_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000) {
        tokenApi.approve(AUTOSHARK_ROUTER_ADDRESS, 1000000000000000000000000);
      }
      tokenApi = IERC20(FINS_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(this), AUTOSHARK_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000) {
        tokenApi.approve(AUTOSHARK_ROUTER_ADDRESS, 1000000000000000000000000);
      }
      tokenApi = IERC20(FINS_BNB_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(this), AUTOSHARK_ROUTER_ADDRESS);
      if (allowance < 1000000000000000000000000) {
        tokenApi.approve(AUTOSHARK_ROUTER_ADDRESS, 1000000000000000000000000);
      }
    }

    function checkIfSenderApprovedMe() view public {
      IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
      uint allowance = tokenApi.allowance(address(msg.sender), address(this));
      require(allowance >= 1e9, "sender needs to approve this contract for cake-token");
      tokenApi = IERC20(FINS_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(msg.sender), address(this));
      require(allowance >= 1e9, "sender needs to approve this contract for fins-token");
      tokenApi = IERC20(FINS_BNB_TOKEN_ADDRESS);
      allowance = tokenApi.allowance(address(msg.sender), address(this));
      require(allowance >= 1e9, "sender needs to approve this contract for fins-token");
    }

    receive () external payable {}

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
      require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
      require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
      uint amountInWithFee = amountIn.mul(997);
      uint numerator = amountInWithFee.mul(reserveOut);
      uint denominator = reserveIn.mul(1000).add(amountInWithFee);
      amountOut = numerator / denominator;
    }

    function swapCakeToBNB(
        uint cakeAmount
    ) external {
        checkIfSenderApprovedMe();

        IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
        tokenApi.transferFrom(msg.sender, payable(address(this)), cakeAmount);

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).getReserves();
        uint bnbAmount = getAmountOut(cakeAmount, reserve0, reserve1);

        address[] memory PATH = new address[](2);
        PATH[0] = address(CAKE_TOKEN_ADDRESS);
        PATH[1] = address(BNB_TOKEN_ADDRESS);

        pancakeRouter.swapExactTokensForETH(
            cakeAmount,
            bnbAmount,
            PATH,
            payable(msg.sender),
            block.timestamp + (1000*60*5)
        )[1];
    }

    function swapFinsToFINSBNB(
      uint finsAmount
    ) external {

      checkIfSenderApprovedMe();

      IERC20 tokenApi = IERC20(FINS_TOKEN_ADDRESS);
      tokenApi.transferFrom(msg.sender, payable(address(this)), finsAmount);
      
      finsAmount = finsAmount/2;

      (uint112 reserve0, uint112 reserve1,) = IFinsPair(FINS_BNB_TOKEN_ADDRESS).getReserves();
      uint bnbAmount = getAmountOut(finsAmount, reserve0, reserve1);

      address[] memory PATH = new address[](2);
      PATH[0] = address(FINS_TOKEN_ADDRESS);
      PATH[1] = address(BNB_TOKEN_ADDRESS);

      uint amountReceived = autosharkRouter.swapExactTokensForETH(
        finsAmount,
        bnbAmount,
        PATH,
        payable(address(this)),
        block.timestamp + (1000*60*5)
      )[1];

      IWETH(BNB_TOKEN_ADDRESS).deposit{value: amountReceived}();

      autosharkRouter.addLiquidity(
        FINS_TOKEN_ADDRESS,
        BNB_TOKEN_ADDRESS,
        finsAmount,
        bnbAmount,
        (finsAmount*995)/1000,
        (bnbAmount*995)/1000,
        payable(msg.sender),
        block.timestamp + (1000*60*10)
      );

    }

    function swapCakeToUSDTBNB(
      uint cakeAmount
    ) external {

        checkIfSenderApprovedMe();

        IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
        tokenApi.transferFrom(msg.sender, payable(address(this)), cakeAmount);

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).getReserves();
        uint bnbAmount = getAmountOut(cakeAmount, reserve0, reserve1);

        address[] memory PATH = new address[](2);
        PATH[0] = address(CAKE_TOKEN_ADDRESS);
        PATH[1] = address(BNB_TOKEN_ADDRESS);

        uint amountBnbReceived = pancakeRouter.swapExactTokensForETH(
            cakeAmount,
            bnbAmount,
            PATH,
            payable(address(this)),
            block.timestamp + (1000*60*5)
        )[1];

        IWETH(BNB_TOKEN_ADDRESS).deposit{value: amountBnbReceived}();

        //take half the BNB and convert to USDT
        amountBnbReceived = amountBnbReceived/2;

        (reserve0, reserve1,) = IUniswapV2Pair(USDT_BNB_TOKEN_ADDRESS).getReserves();
        uint usdtAmount = getAmountOut(amountBnbReceived, reserve1, reserve0);
        PATH[0] = address(BNB_TOKEN_ADDRESS);
        PATH[1] = address(USDT_TOKEN_ADDRESS);

        uint amountUsdtReceived = pancakeRouter.swapExactTokensForTokens(
            amountBnbReceived,
            usdtAmount,
            PATH,
            payable(address(this)),
            block.timestamp + (1000*60*10)
        )[1];

        pancakeRouter.addLiquidity(
            USDT_TOKEN_ADDRESS,
            BNB_TOKEN_ADDRESS,
            amountUsdtReceived,
            amountBnbReceived,
            (amountUsdtReceived*995)/1000,
            (amountBnbReceived*995)/1000,
            payable(msg.sender),
            block.timestamp + (1000*60*15)
        );
    }

    function swapCakeToCAKEBNB(
      uint cakeAmount
    ) external {

      checkIfSenderApprovedMe();

      IERC20 tokenApi = IERC20(CAKE_TOKEN_ADDRESS);
      tokenApi.transferFrom(msg.sender, payable(address(this)), cakeAmount);
      
      cakeAmount = cakeAmount/2;

      (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).getReserves();
      uint bnbAmount = getAmountOut(cakeAmount, reserve0, reserve1);

      address[] memory PATH = new address[](2);
      PATH[0] = address(CAKE_TOKEN_ADDRESS);
      PATH[1] = address(BNB_TOKEN_ADDRESS);

      uint amountReceived = pancakeRouter.swapExactTokensForETH(
        cakeAmount,
        bnbAmount,
        PATH,
        payable(address(this)),
        block.timestamp + (1000*60*5)
      )[1];

      IWETH(BNB_TOKEN_ADDRESS).deposit{value: amountReceived}();

      pancakeRouter.addLiquidity(
        CAKE_TOKEN_ADDRESS,
        BNB_TOKEN_ADDRESS,
        cakeAmount,
        bnbAmount,
        (cakeAmount*995)/1000,
        (bnbAmount*995)/1000,
        payable(msg.sender),
        block.timestamp + (1000*60*10)
      );

    }


    function getSharkAmountOut(address token0, address token1, uint amount0, IFinsPair pair) private view returns (uint pricd) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return getAmountOut(amount0, reserve0, reserve1);
    }
    function getPancakeAmountOut(address token0, address token1, uint amount0, IUniswapV2Pair pair) private view returns (uint pricd) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return getAmountOut(amount0, reserve0, reserve1);
    }

    function startArbitrage(
        address token0, 
        address token1,
        uint amount
    ) external {
        
        if (token0 == IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).token0()) {

            address[] memory PATH = new address[](2);
            PATH[0] = token0;
            PATH[1] = token1;

            // uint sharkAmountOut = getSharkAmountOut(token0, token1, amount, sharkPair);
            // uint pancakeAmountOut = getPancakeAmountOut(token0, token1, amount, pair);

            uint[] memory sharkAmountOut = autosharkRouter.getAmountsOut(amount, PATH);
            uint[] memory pancakeAmountOut = pancakeRouter.getAmountsOut(amount, PATH);

            require(sharkAmountOut.length == 1, 'sharkAmountOut.length is not 1');
            require(pancakeAmountOut.length == 1, 'pancakeAmountOut.length is not 1');
        
            if (sharkAmountOut[0] > pancakeAmountOut[0]) {
                
                // here if the shark returns more output than pancake for the same swap
                // if this is the case, then we want to borrow input token and sell it on shark
                // buy low on pancake, sell high on shark

                // initiate flashloan
                // we are borrowing amount0 in token0`  
                IUniswapV2Pair(CAKE_BNB_TOKEN_ADDRESS).swap(
                    amount, 
                    0,
                    address(this), 
                    bytes('not empty')
                );

            } else {
                // require(false,
                //     string(
                //         abi.encodePacked(
                //             appendUintToString("sharkprice not bigger,shark:", sharkAmountOut[0]),
                //             appendUintToString(",pancake:", pancakeAmountOut[0])
                //         )
                //     )
                // );
                IFinsPair(AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS).swap(
                    amount, 
                    0,
                    address(this), 
                    bytes('not empty')
                );
            }
            

        } else {
            require(false, "token0 is not pair.token0");
        }
    
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    function pancakePairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                PANCAKE_FACTORY_ADDRESS,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
            ))));
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
            ))));
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function FinsCall(
        address _sender, 
        uint _amount0, 
        uint _amount1, 
        bytes calldata _data
    ) external {
        address[] memory path = new address[](2);
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
        
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(
        msg.sender == AUTOSHARK_CAKE_BNB_TOKEN_ADDRESS, 
        'Unauthorized'
        ); 
        require(_amount0 == 0 || _amount1 == 0);

        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;

        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        
        token.approve(PANCAKE_ROUTER_ADDRESS, amountToken);

        uint[] memory amountRequired = getAmountsIn(
            PANCAKE_FACTORY_ADDRESS, 
            amountToken, 
            path
        );

        require(amountRequired.length == 1, 'amountRequired.length is not 1');
        
        uint amountReceived = pancakeRouter.swapExactTokensForTokens(
            amountToken,
            amountRequired[0], 
            path, 
            msg.sender, 
            block.timestamp + (1000*60*10)
        )[1];

        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        otherToken.transfer(msg.sender, amountRequired[0]);
        otherToken.transfer(tx.origin, amountReceived - amountRequired[0]);
    }

    function pancakeCall(
        address _sender, 
        uint _amount0, 
        uint _amount1, 
        bytes calldata _data
    ) external {
        address[] memory path = new address[](2);
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
        
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(
        msg.sender == CAKE_BNB_TOKEN_ADDRESS, 
        'Unauthorized'
        ); 
        require(_amount0 == 0 || _amount1 == 0);

        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;

        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        
        token.approve(AUTOSHARK_ROUTER_ADDRESS, amountToken);

        uint[] memory amountRequired = getAmountsIn(
            AUTOSHARK_FACTORY_ADDRESS, 
            amountToken, 
            path
        );

        require(amountRequired.length == 1, 'amountRequired.length is not 1');
        
        uint amountReceived = autosharkRouter.swapExactTokensForTokens(
            amountToken,
            amountRequired[0], 
            path, 
            msg.sender, 
            block.timestamp + (1000*60*10)
        )[1];

        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        otherToken.transfer(msg.sender, amountRequired[0]);
        otherToken.transfer(tx.origin, amountReceived - amountRequired[0]);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}