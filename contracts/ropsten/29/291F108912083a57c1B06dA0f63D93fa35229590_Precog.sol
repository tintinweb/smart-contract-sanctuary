/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// File: interfaces/IExchangeRouter.sol

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

// File: ../future-exchange/libraries/TransferHelper.sol

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

// File: ../future-token/interfaces/IFutureToken.sol

pragma solidity ^0.8.0;

interface IFutureToken {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function expiryDate() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
}

// File: ../future-token/interfaces/IFutureTokenFactory.sol

pragma solidity ^0.8.0;

interface IFutureTokenFactory {
    function exchange() external view returns (address);

    event futureTokenCreated(
        address indexed token0,
        address indexed token1,
        address futureTokenAddress,
        uint256 i
    );

    function getFutureToken(
        address tokenA,
        address tokenB,
        uint256 deadline
    ) external view returns (address futureTokenAddress);

    function allFutureTokens(
        uint256 index
    ) external view returns (address futureTokenAddress);

    function createFutureToken(
        address tokenA,
        address tokenB,
        uint256 deadlint
    ) external returns (address futureTokenAddress);

    function mintFuture(
        address tokenA,
        address tokenB,
        uint256 deadline,
        address to,
        uint256 amount
    ) external;

    function burnFuture(
        address tokenA,
        address tokenB,
        uint256 deadline,
        uint256 amount
    ) external;

    function transferFromFuture(
        address tokenA,
        address tokenB,
        uint256 deadline,
        address to,
        uint256 amount
    ) external;
}

// File: ../common/interfaces/IERC20Metadata.sol

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: ../common/interfaces/IERC20.sol

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

// File: ../common/interfaces/IOwnable.sol

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

// File: Precog.sol

pragma solidity ^0.8.0;

contract Precog {
    address public usdc;
    address public weth;
    address public tradingService;

    uint256 public constant feeDeposit = 5e18; // 5 USDC
    uint256 public constant feeWithdraw = 5; // 5 %

    address[] public futureExchanges;
    address[] public exchanges;

    mapping(address => bool) isFutureExchange;
    mapping(address => bool) isExchange;

    mapping(address => uint256) public availableAmount;
    mapping(address => uint256) public investAmount;
    mapping(address => uint256) public tradingAmount;
    mapping(address => uint256) public profitAmount;

    event Deposit(address indexed user, uint256 amount, uint256 fee, uint256 indexed timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 indexed timestamp);

    constructor(address _usdc, address _weth, address _tradingService) {
        usdc = _usdc;
        weth = _weth;
        tradingService = _tradingService;
    }

    function addFutureExchange(address exchange) external {
        require(!isFutureExchange[exchange], "Already added");
        futureExchanges.push(exchange);
        isFutureExchange[exchange] = true;
        TransferHelper.safeApprove(usdc, address(exchange), type(uint256).max);
    }

    function addExchange(address exchange) external {
        require(!isExchange[exchange], "Already added");
        exchanges.push(exchange);
        isExchange[exchange] = true;
        TransferHelper.safeApprove(usdc, address(exchange), type(uint256).max);
    }

    function futureExchangesCount() external view returns (uint256) {
        return futureExchanges.length;
    }

    function exchangesCount() external view returns (uint256) {
        return exchanges.length;
    }

    function deposit(uint256 amount) external {
        require(amount > feeDeposit, "Deposit amount not enough: <= 5 USDC");
        TransferHelper.safeTransferFrom(usdc, msg.sender, address(this), amount);

        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;

        uint256 deadline = block.timestamp + 3600;

        (IExchangeRouter exchange, uint256 feeDepositEth) = _selectBestPriceExchange(pair, feeDeposit);
        if (address(exchange) != address(0)) {
            exchange.swapExactTokensForETH(feeDeposit, feeDepositEth, pair, tradingService, deadline);
        }

        availableAmount[msg.sender] += amount - feeDeposit;

        emit Deposit(msg.sender, amount, feeDeposit, block.timestamp);

        if (isProfitable()) {
            invest();
        }
    }

    function _selectBestPriceExchange(address[] memory pair, uint256 amount)
        internal
        view
        returns (IExchangeRouter selected, uint256 outAmount)
    {
        outAmount = 0;
        (selected, outAmount) = _selectExchange(exchanges, pair, amount, outAmount);
        (selected, outAmount) = _selectExchange(futureExchanges, pair, amount, outAmount);
    }

    function _selectExchange(
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
        require(amount <= availableAmount[msg.sender], "Withdraw amount exceed available amount");

        uint256 fee = amount * feeWithdraw / 100;
        uint256 transferAmount = amount - fee;
        TransferHelper.safeTransfer(usdc, msg.sender, transferAmount);

        availableAmount[msg.sender] -= amount;

        emit Withdraw(msg.sender, amount, fee, block.timestamp);
    }

    function withdrawLiquidate(address futureToken) external {
        uint256 amount = _liquidate(futureToken);

        //Update user's USDC investment amount and send USDC and profit back to user
        require(amount <= tradingAmount[msg.sender], "Withdraw amount exceed available amount");

        uint256 fee = amount * feeWithdraw / 100;
        uint256 transferAmount = amount - fee;
        TransferHelper.safeTransfer(usdc, msg.sender, transferAmount);

        tradingAmount[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount, fee, block.timestamp);
    }

    function reinvest(address futureToken) external {
        uint256 amount = _liquidate(futureToken);

        //Update user's USDC investment amount and send USDC and profit back to user
        require(amount <= tradingAmount[msg.sender], "Reinvest amount exceed available amount");
        tradingAmount[msg.sender] -= amount;
    }

    function _liquidate(address futureToken) internal returns(uint256 amount) {
        amount = IERC20(futureToken).balanceOf(msg.sender);

        //Check if future token is valid
        address tokenA = IFutureToken(futureToken).token0();
        address tokenB = IFutureToken(futureToken).token1();
        require(tokenA == usdc || tokenB == usdc, "Invalid token");

        //Retrieve future token from user
        TransferHelper.safeTransferFrom(futureToken, msg.sender, address(this), amount);

        address tokenInvest = tokenA == usdc ? tokenB : tokenA;
        uint256 deadline = IFutureToken(futureToken).expiryDate();

        //Call closeFuture to Future Exchange contract to swap Future token to USDC
        address futureFactory = IOwnable(futureToken).owner();
        address exchange = IFutureTokenFactory(futureFactory).exchange();
        IExchangeRouter(exchange).closeFuture(tokenInvest, usdc, deadline, msg.sender, amount);
    }

    function isProfitable() public returns (bool) {}

    function invest() public {}
}