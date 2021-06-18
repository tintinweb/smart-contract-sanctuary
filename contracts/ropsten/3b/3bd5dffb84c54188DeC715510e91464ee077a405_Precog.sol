/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// File: precog-v2/interfaces/IExchangeRouter.sol

pragma solidity >=0.6.2;

interface IExchangeRouter {
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
    function closeFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
}

// File: future-exchange/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// File: common/interfaces/IERC20Metadata.sol

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: common/interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: future-token/interfaces/IFutureToken.sol

pragma solidity ^0.8.0;

interface IFutureToken {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function expiryDate() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
}

// File: precog-v2/Precog.sol

pragma solidity ^0.8.0;

contract Precog {
    address public usdc;
    address public weth;
    address public tradingService;
    uint256 public fee = 5; // %

    address[] public futureExchanges;
    address[] public exchanges;

    mapping(address => bool) isFutureExchange;
    mapping(address => bool) isExchange;

    mapping(address => uint256) public availableAmount;
    mapping(address => uint256) public investAmount;
    mapping(address => uint256) public profitAmount;

    mapping(address => address) public investExchange;
    mapping(address => address) public investFutureToken;

    constructor(address _usdc, address _weth, address _tradingService) {
        usdc = _usdc;
        weth = _weth;
        tradingService = _tradingService;
    }

    function addFutureExchange(address exchange) external {
        require(!isFutureExchange[exchange], "Already added");
        futureExchanges.push(exchange);
        isFutureExchange[exchange] = true;
    }

    function addExchange(address exchange) external {
        require(!isExchange[exchange], "Already added");
        exchanges.push(exchange);
        isExchange[exchange] = true;
    }

    function futureExchangesCount() external view returns (uint256) {
        return futureExchanges.length;
    }

    function exchangesCount() external view returns (uint256) {
        return exchanges.length;
    }

    function deposit(uint256 amount) external {
        TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), amount);

        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;

        uint256 deadline = block.timestamp + 3600;
        uint256 feeAmount = (amount * fee) / 100;

        (IExchangeRouter exchange, uint256 feeAmountEth) = selectBestPriceExchange(pair, feeAmount);
        if (address(exchange) != address(0)) {
            uint256 allowance = IERC20(usdc).allowance(address(this), address(exchange));
            if (allowance < feeAmount) {
                TransferHelper.safeApprove(usdc, address(exchange), IERC20(usdc).totalSupply());
            }
            exchange.swapExactTokensForETH(feeAmount, feeAmountEth, pair, tradingService, deadline);
        }

        availableAmount[msg.sender] += amount - feeAmount;

        if (isProfitable()) {
            invest();
        }
    }

    function selectBestPriceExchange(address[] memory pair, uint256 amount)
        public
        view
        returns (IExchangeRouter selected, uint256 outAmount)
    {
        outAmount = 0;
        (selected, outAmount) = selectExchange(exchanges, pair, amount, outAmount);
        (selected, outAmount) = selectExchange(futureExchanges, pair, amount, outAmount);
    }

    function selectExchange(
        address[] memory _exchanges,
        address[] memory pair,
        uint256 amount,
        uint256 inAmount
    ) internal view returns (IExchangeRouter selected, uint256 outAmount) {
        outAmount = inAmount;
        for (uint256 i = 0; i < _exchanges.length; i++) {
            IExchangeRouter exchange = IExchangeRouter(exchanges[i]);
            try exchange.getAmountsOut(amount, pair) returns (uint256[] memory outAmounts) {
                if (outAmount < outAmounts[1]) {
                    outAmount = outAmounts[1];
                    selected = exchange;
                }
            } catch {}
        }
    }

    function withdraw(uint256 amount) external {
        //Handle to receive Future Token from user
        address futureToken = investFutureToken[msg.sender];
        TransferHelper.safeTransferFrom(futureToken, msg.sender, address(this), amount);

        //Call closeFuture to Future Exchange contract to swap Future token to USDC
        uint256 deadline = IFutureToken(futureToken).expiryDate();
        address tokenA = IFutureToken(futureToken).token0();
        address tokenB = IFutureToken(futureToken).token1();
        address tokenIn;
        address tokenOut = usdc;
        require(tokenOut == tokenA || tokenOut == tokenB, "Invalid token");
        (tokenIn, tokenOut) = tokenA == tokenOut
            ? (tokenB, tokenA)
            : (tokenA, tokenB);
        address exchangeAddress = investExchange[msg.sender];
        IExchangeRouter exchange = IExchangeRouter(exchangeAddress);
        exchange.closeFuture(tokenIn, tokenOut, deadline, msg.sender, amount);

        //Update user's USDC investment amount and send USDC and profit back to user
        uint256 currentAmount = availableAmount[msg.sender];
        require(amount <= currentAmount, "Exceed available amount");
        TransferHelper.safeTransfer(tokenOut, msg.sender, amount);
        availableAmount[msg.sender] -= amount;
    }

    function isProfitable() public returns (bool) {}

    function invest() public {}
}