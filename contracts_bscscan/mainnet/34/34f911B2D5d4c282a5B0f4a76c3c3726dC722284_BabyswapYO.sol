pragma solidity ^0.6.12;

library SafeMath {

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IBabyPair {
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

interface IBabyRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

interface IBabyRouter02 is IBabyRouter01 {
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

contract BabyswapYO {

    using SafeMath for uint256;

    address private constant BABY_ROUTER_ADDRESS = 0x325E343f1dE602396E256B67eFd1F61C3A6B38Bd;
    address private constant BABY_TOKEN_ADDRESS = 0x53E562b9B7E5E94b81f10e96Ee70Ad06df3D2657;
    address private constant BNB_TOKEN_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant USDT_TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDT_BNB_TOKEN_ADDRESS = 0x04580ce6dEE076354e96fED53cb839DE9eFb5f3f;
    address private constant BABY_BNB_TOKEN_ADDRESS = 0x36aE10A4d16311959b607eE98Bc4a8A653A33b1F;

    IBabyRouter02 private constant router = IBabyRouter02(BABY_ROUTER_ADDRESS);

    address payable private immutable owner;

    receive() external payable {}

    constructor(address payable _owner) public {
        require(msg.sender == _owner);
        owner = _owner;
        approveRouterToSpendMyTokens();
    }
    
    function approveToken(address token) internal {
        IERC20 tokenApi = IERC20(token);
        uint256 allowance = tokenApi.allowance(address(this), BABY_ROUTER_ADDRESS);
        if (allowance < 1e27) {
            tokenApi.approve(BABY_ROUTER_ADDRESS, 1e27);
        }
    }

    function approveRouterToSpendMyTokens() internal {
        approveToken(BNB_TOKEN_ADDRESS);
        approveToken(USDT_TOKEN_ADDRESS);
        approveToken(BABY_TOKEN_ADDRESS);
        approveToken(USDT_BNB_TOKEN_ADDRESS);
        approveToken(BABY_BNB_TOKEN_ADDRESS);
    }

    function transferTokensTo(address tokenAddress, address to) internal {
        IERC20 tokenApi = IERC20(tokenAddress);
        uint balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(to, balance);
        }
    }

    function escapeHatch() external {
        require(msg.sender == owner);
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        transferTokensTo(BNB_TOKEN_ADDRESS, owner);
        transferTokensTo(USDT_TOKEN_ADDRESS, owner);
        transferTokensTo(BABY_TOKEN_ADDRESS, owner);
        transferTokensTo(USDT_BNB_TOKEN_ADDRESS, owner);
        transferTokensTo(BABY_BNB_TOKEN_ADDRESS, owner);
    }

    function _unwrapBnb() internal returns (uint balance) {
        IERC20 tokenApi = IERC20(BNB_TOKEN_ADDRESS);
        balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
          IWETH(BNB_TOKEN_ADDRESS).withdraw(balance);
        }
        return balance;
    }

    function getAmountOut(uint amountIn, address pairAddress, address[] memory path) internal view returns (uint amountOut) {
        IBabyPair pair = IBabyPair(pairAddress);
        (uint reserve0, uint reserve1,) = pair.getReserves();
        amountOut = (path[0] == pair.token0()) 
            ? router.getAmountOut(amountIn, reserve0, reserve1) 
            : router.getAmountOut(amountIn, reserve1, reserve0);
        return amountOut;
    }

    function _addLiquidity_X_BNB(address xTokenAddress, uint xAmount, uint bnbAmount, address to) internal {
        router.addLiquidity(
            xTokenAddress,
            BNB_TOKEN_ADDRESS,
            xAmount,
            bnbAmount,
            (xAmount*997)/1000,
            (bnbAmount*997)/1000,
            payable(to),
            block.timestamp + (1000*60*10)
        );
        transferTokensTo(xTokenAddress, to);
        uint balance = _unwrapBnb();
        if (balance > 0) {
            payable(to).transfer(balance);
        }
    }

    function swap_BNB_to_BABY_BNB() external payable {
        require(msg.value >= 1e16, 'bnb too small, 0.01 is min');
        _swap_BNB_to_BABY_BNB(msg.value, msg.sender);
    }

    function _swap_BNB_to_BABY_BNB(uint amount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = BNB_TOKEN_ADDRESS;
        path[1] = BABY_TOKEN_ADDRESS;
        uint bnbAmount = amount/2;
        uint amountOut = getAmountOut(bnbAmount, BABY_BNB_TOKEN_ADDRESS, path);
        uint babyAmount = router.swapExactETHForTokens{value: bnbAmount}(
            (amountOut*999)/1000,
            path,
            payable(address(this)),
            block.timestamp + (1000*60*10)
        )[1];
        IWETH(BNB_TOKEN_ADDRESS).deposit{value: address(this).balance}();
        _addLiquidity_X_BNB(BABY_TOKEN_ADDRESS, babyAmount, bnbAmount, to);
    }

    function _swap_BNB_to_USDT_BNB(uint amount, address to) internal {
        require(amount >= 1e16, 'bnb too small, 0.01 is min');
        address[] memory path = new address[](2);
        path[0] = BNB_TOKEN_ADDRESS;
        path[1] = USDT_TOKEN_ADDRESS;
        uint bnbAmount = amount/2;
        uint amountOut = getAmountOut(bnbAmount, USDT_BNB_TOKEN_ADDRESS, path);
        uint usdtAmount = router.swapExactETHForTokens{value: bnbAmount}(
            (amountOut*999)/1000,
            path,
            payable(address(this)),
            block.timestamp + (1000*60*5)
        )[1];
        IWETH(BNB_TOKEN_ADDRESS).deposit{value: address(this).balance}();
        _addLiquidity_X_BNB(USDT_TOKEN_ADDRESS, usdtAmount, bnbAmount, to);
    }

    function swap_BNB_to_USDT_BNB() external payable {
        _swap_BNB_to_USDT_BNB(msg.value, msg.sender);
    }

    function transferFromSender(address tokenAddress, uint amount, address sender) internal returns (uint _amount) {
        IERC20 tokenApi = IERC20(tokenAddress);
        if (amount == 0) {
            _amount = tokenApi.balanceOf(sender);
        } else {
            _amount = amount;
        }
        require(_amount > 0, "transferFromSender:0token");
        tokenApi.transferFrom(sender, payable(address(this)), _amount);
        return _amount;
    }

    function _swap_BABY_to_BNB(uint babyAmount, address to) internal returns (uint amountReceived) {
        address[] memory path = new address[](2);
        path[0] = address(BABY_TOKEN_ADDRESS);
        path[1] = address(BNB_TOKEN_ADDRESS);
        uint amountOut = getAmountOut(babyAmount, BABY_BNB_TOKEN_ADDRESS, path);
        return router.swapExactTokensForETH(
            babyAmount,
            (amountOut*999)/1000,
            path,
            payable(to),
            block.timestamp + (1000 * 60 * 5)
        )[1];
    }

    function _swap_USDT_to_BNB(uint usdtAmount, address to) internal returns (uint amountReceived) {
        address[] memory path = new address[](2);
        path[0] = USDT_TOKEN_ADDRESS;
        path[1] = BNB_TOKEN_ADDRESS;
        uint amountOut = getAmountOut(usdtAmount, USDT_BNB_TOKEN_ADDRESS, path);
        return router.swapExactTokensForETH(
            usdtAmount,
            (amountOut*999)/1000,
            path,
            payable(to),
            block.timestamp + (1000 * 60 * 5)
        )[1];
    }

    function _swap_BNB_to_USDT(uint bnbAmount, address to) internal returns (uint amountReceived) {
        address[] memory path = new address[](2);
        path[0] = BNB_TOKEN_ADDRESS;
        path[1] = USDT_TOKEN_ADDRESS;
        uint amountOut = getAmountOut(bnbAmount, USDT_BNB_TOKEN_ADDRESS, path);
        return router.swapExactETHForTokens{value: bnbAmount}(
            (amountOut*999)/1000,
            path,
            payable(to),
            block.timestamp + (1000*60*5)
        )[1];
    }
    
    function swap_BABY_to_USDT_BNB() external {
        uint babyAmount = transferFromSender(BABY_TOKEN_ADDRESS, 0, msg.sender);
        uint bnbAmount = _swap_BABY_to_BNB(babyAmount, address(this));
        bnbAmount = bnbAmount/2;
        uint usdtAmount = _swap_BNB_to_USDT(bnbAmount, address(this));
        IWETH(BNB_TOKEN_ADDRESS).deposit{value: address(this).balance}();
        _addLiquidity_X_BNB(USDT_TOKEN_ADDRESS, usdtAmount, bnbAmount, msg.sender);
    }

    function swap_BABY_to_BABY_BNB() external {
        uint babyAmount = transferFromSender(BABY_TOKEN_ADDRESS, 0, msg.sender);
        uint bnbAmount = _swap_BABY_to_BNB(babyAmount/2, address(this));
        require(address(this).balance >= bnbAmount, "fail: balance >= bnbAmount");
        IWETH(BNB_TOKEN_ADDRESS).deposit{value: address(this).balance}();
        _addLiquidity_X_BNB(BABY_TOKEN_ADDRESS, babyAmount/2, bnbAmount, msg.sender);
    }

    function getLiquidityAmountOut(address xToken, address pairAddress, uint liquidity) internal view returns (uint xAmountOut, uint bnbAmountOut) {
        uint totalSupply = IERC20(pairAddress).totalSupply();
        xAmountOut = liquidity.mul(IERC20(xToken).balanceOf(pairAddress)) / totalSupply;
        bnbAmountOut = liquidity.mul(IERC20(BNB_TOKEN_ADDRESS).balanceOf(pairAddress)) / totalSupply;
        return (xAmountOut, bnbAmountOut);
    }

    function swap_USDT_BNB_to_BABY_BNB() external {
        (uint usdtAmountOut, uint bnbAmountOut) = _removeLiquidity_X_BNB(USDT_TOKEN_ADDRESS, USDT_BNB_TOKEN_ADDRESS, msg.sender);
        uint usdtBalance = IERC20(USDT_TOKEN_ADDRESS).balanceOf(address(this));
        require(
           usdtBalance >= (usdtAmountOut*997)/1000,
          "after_removeLiquidity:usdt-balance-low"
        );
        require(
          IERC20(BNB_TOKEN_ADDRESS).balanceOf(address(this)) >= (bnbAmountOut*997)/1000,
          "after_removeLiquidity:bnb-balance-low"
        );
        _unwrapBnb();
        require(
          address(this).balance >= (bnbAmountOut*997)/1000,
          "after_unwrapBnb:bnb-balance-low"
        );
        bnbAmountOut = _swap_USDT_to_BNB(usdtBalance, address(this));
        require(IERC20(USDT_TOKEN_ADDRESS).balanceOf(address(this)) == 0, "usdt not 0 after swap to bnb");
        require(address(this).balance >= bnbAmountOut, "bnbAmountOut not correct after swap to bnb");
        _swap_BNB_to_BABY_BNB(address(this).balance, msg.sender);
    }

    function _removeLiquidity_X_BNB(address xTokenAddress, address pairAddress, address sender) internal returns (uint xAmountOut, uint bnbAmountOut) {
        uint xBnbAmount = transferFromSender(pairAddress, 0, sender);
        xBnbAmount = IERC20(pairAddress).balanceOf(address(this));
        require(xBnbAmount > 0, "contract-0xBnb");
        (xAmountOut, bnbAmountOut) = getLiquidityAmountOut(xTokenAddress, pairAddress, xBnbAmount);
        (xAmountOut, bnbAmountOut) = router.removeLiquidity(
            xTokenAddress,
            BNB_TOKEN_ADDRESS,
            xBnbAmount,
            (xAmountOut*997)/1000,
            (bnbAmountOut*997)/1000,
            payable(address(this)),
            block.timestamp + (1000*60*5)
        );
        return (xAmountOut, bnbAmountOut);
    }

    function swap_BABY_BNB_to_USDT_BNB() external {
        (uint babyAmountOut, uint bnbAmountOut) = _removeLiquidity_X_BNB(BABY_TOKEN_ADDRESS, BABY_BNB_TOKEN_ADDRESS, msg.sender);
        uint babyBalance = IERC20(BABY_TOKEN_ADDRESS).balanceOf(address(this));
        require(
           babyBalance >= (babyAmountOut*997)/1000,
          "after_removeLiquidity:usdt-balance-low"
        );
        require(
          IERC20(BNB_TOKEN_ADDRESS).balanceOf(address(this)) >= (bnbAmountOut*997)/1000,
          "after_removeLiquidity:bnb-balance-low"
        );
        _unwrapBnb();
        require(
          address(this).balance >= (bnbAmountOut*997)/1000,
          "after_unwrapBnb:bnb-balance-low"
        );
        _swap_BABY_to_BNB(babyBalance, address(this));
        require(IERC20(BABY_TOKEN_ADDRESS).balanceOf(address(this)) == 0, "baby not 0 after swap to bnb");
        _swap_BNB_to_USDT_BNB(address(this).balance, msg.sender);
    }

}