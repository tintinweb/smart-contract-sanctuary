// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';

import './interfaces/IAlitaPair.sol';
import './interfaces/IAlitaRouter02.sol';
import './interfaces/IZap.sol';
import './interfaces/ISafeSwapBNB.sol';

import './libraries/Math.sol';

contract Zap is IZap, Ownable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notLpToken;
    mapping(address => address) private routePairAddresses;
    mapping(bytes32 => address) private directRoutePairAddresses;
    address[] public tokens;
    address public safeSwapBNB;

    IAlitaRouter02 public ROUTER;
    address public wbnb;

    bool public isPaused = true;

    bool private _initialized = false;

	 /* ========== EVENT ========== */
	event TransferLeftOverToken(address token, address reciever, uint amount);
	event TransferLeftOverBNB(address reciever, uint amount);

    event ZapInBNB(address toToken, uint zapAmount, uint receiveAmount);
    event ZapInBEP20(address fromToken, address toToken, uint zapAmount, uint receiveAmount);

    event ZapOutBNB(address lpToken, address token, uint lpTokenAmount, uint tokenAmount , uint bnbAmount);
    event ZapOutBEP20(address lpToken, address token0, address token1, uint lpTokenAmount, uint token0Amount , uint token1Amount);

    /* ========== MODIFIER ========== */

    modifier notPaused() {
        require(isPaused == false, 'Zap: Contract is temporarily paused for upgrade');
        _;
    }

    /* ========== INITIALIZER ========== */

    constructor(address _router, address _wbnb) public {
        ROUTER = IAlitaRouter02(_router);
        wbnb = _wbnb;
    }
    
    /*
    * Receive BNB sent to this contract
    */
    receive() external payable {}

    /*
     * initialize the addrees list of BEP20 token (not LP token)
     */
    function initialize(address ali, address usdt, address busd, address eth, address btcb , address baby, address raca, address beta) onlyOwner public {
        require(!_initialized, 'Contract is already initialized');

        setNotLpToken(wbnb);
        setNotLpToken(ali);
        setNotLpToken(usdt);
        setNotLpToken(busd);
        setNotLpToken(eth);
        setNotLpToken(btcb);
        setNotLpToken(baby);
        setNotLpToken(raca);
        setNotLpToken(beta);

        setRoutePairAddress(usdt, busd);

        setDirectRoutePairAddress(keccak256(abi.encodePacked(ali, eth)), eth);
        setDirectRoutePairAddress(keccak256(abi.encodePacked(ali, usdt)), usdt);
        setDirectRoutePairAddress(keccak256(abi.encodePacked(ali, busd)), busd);
        setDirectRoutePairAddress(keccak256(abi.encodePacked(usdt, busd)), busd);

        isPaused = false;
        _initialized = true;
    }

    /* ========== View Functions ========== */
    
    function getIsLpToken(address token) external override view returns (bool) {
        return !notLpToken[token];
    }
    
    function getRouter() external view override returns (IAlitaRouter02) {
        return ROUTER;
    }

    function getWBNB() external view override returns (address) {
        return wbnb;
    }
    function isLpToken(address token) public view returns (bool) {
        return !notLpToken[token];
    }

    function routePair(address token) external override view returns (address) {
        return routePairAddresses[token];
    }

    function directRoutePair(bytes32 key) external override view returns (address) {
        return directRoutePairAddresses[key];
    }

    function getRoutePath(address fromToken, address toToken) external override view returns (address[] memory path) {
        return routePath(fromToken, toToken);
    }

    function getEstimatedLpToken(address fromToken, uint fromTokenAmount, address toToken) external view returns (uint liquidity) {
        if(isLpToken(toToken)) {
            IAlitaPair pair = IAlitaPair(toToken);
            address token0 = pair.token0();
            address token1 = pair.token1();
            uint totalSupply = pair.totalSupply();
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            if(fromToken == token0 || fromToken == token1) {
                uint halfFromTokenAmount = fromTokenAmount.div(2);
                address otherToken = fromToken == token0 ? token1 : token0;
                uint otherTokenReserve = fromToken == token0 ? reserve1 : reserve0;
                uint fromTokenReserve = fromToken == token0 ? reserve0 : reserve1;
                uint otherTokenAmount = getPoolAddedAmount(fromToken, otherToken, halfFromTokenAmount);
                liquidity = calculateLiquidity(halfFromTokenAmount, otherTokenAmount, fromTokenReserve, otherTokenReserve, totalSupply);
            } else {
                uint wbnbAmount = fromToken != wbnb ? getPoolAddedAmount(fromToken, wbnb, fromTokenAmount) : fromTokenAmount;
                uint halfWbnbAmount = wbnbAmount.div(2);
                uint amount0 = token0 != wbnb ? getPoolAddedAmount(wbnb, token0, halfWbnbAmount): halfWbnbAmount;
                uint amount1 = token1 != wbnb ? getPoolAddedAmount(wbnb, token1, halfWbnbAmount): halfWbnbAmount;
                liquidity = calculateLiquidity(amount0, amount1, reserve0, reserve1, totalSupply);
            } 
        } else {
            liquidity = getPoolAddedAmount(fromToken, toToken, fromTokenAmount);
        }

    }

    function calculateLiquidity(uint amount0, uint amount1, uint reserve0, uint reserve1, uint totalSupply) private pure returns (uint liquidity) {
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(10**3);
        } else {
            liquidity = Math.min(amount0.mul(totalSupply).div(reserve0), amount1.mul(totalSupply).div(reserve1));
        }
    }
    
    function getPoolAddedAmount(address fromToken, address toToken, uint swapAmount) public view returns (uint amount) {
        address[] memory path = routePath(fromToken, toToken);
        amount = ROUTER.getAmountsOut(swapAmount, path)[path.length - 1];
    }

    /* ========== External Functions ========== */

    function zapInToken(address fromToken, uint amount, address toToken) external override notPaused {
        uint fromTokenBalanceBefore = IBEP20(fromToken).balanceOf(address(this));

        IBEP20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(fromToken);

        uint liquidity;
        
        if (isLpToken(toToken)) {
            IAlitaPair pair = IAlitaPair(toToken);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (fromToken == token0 || fromToken == token1) {
                address otherToken = fromToken == token0 ? token1 : token0;
                _approveTokenIfNeeded(otherToken);
                uint otherTokenBalanceBefore = IBEP20(otherToken).balanceOf(address(this));

                liquidity = _swapAndAddLiquidity(fromToken, otherToken, amount, msg.sender);

                uint fromTokenBalanceAfter = IBEP20(fromToken).balanceOf(address(this));
                if (fromTokenBalanceAfter > 0 && fromTokenBalanceAfter > fromTokenBalanceBefore) {
                    _transferLeftOverToken(fromToken, msg.sender, fromTokenBalanceAfter.sub(fromTokenBalanceBefore));
                }

                uint otherTokenBalanceAfter = IBEP20(otherToken).balanceOf(address(this));
                if(otherTokenBalanceAfter > 0 && otherTokenBalanceAfter > otherTokenBalanceBefore) {
                    _transferLeftOverToken(otherToken, msg.sender, otherTokenBalanceAfter.sub(otherTokenBalanceBefore));
                }

            } else {
                uint bnbBalanceBefore = address(this).balance;
                uint bnbAmount = fromToken == wbnb? _safeSwapToBNB(amount) : _swapTokenForBNB(fromToken, amount, address(this));
                liquidity = _swapBNBToLpToken(toToken, bnbAmount, msg.sender, bnbBalanceBefore);
            }
        } else {
            _swap(fromToken, amount, toToken, msg.sender);
        }
        emit ZapInBEP20(fromToken, toToken, amount , liquidity);
    }

    function zapIn(address toToken) external payable override notPaused {
        uint bnbBalanceBefore = address(this).balance.sub(msg.value);
        uint liquidity = _swapBNBToLpToken(toToken, msg.value, msg.sender, bnbBalanceBefore);
        emit ZapInBNB(toToken, msg.value , liquidity);
    }

    function zapOut(address fromToken, uint amount) external override notPaused {
        IBEP20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(fromToken);

        if (!isLpToken(fromToken)) {
            _swapTokenForBNB(fromToken, amount, msg.sender);
        } else {
            IAlitaPair pair = IAlitaPair(fromToken);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == wbnb || token1 == wbnb) {
                address token = token0 != wbnb ? token0 : token1;
                (uint amountToken, uint amountETH) = ROUTER.removeLiquidityETH(token, amount, 0, 0, msg.sender, block.timestamp);
                emit ZapOutBNB(fromToken, token, amount, amountToken, amountETH);
            } else {
                (uint amountA, uint amountB) =  ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
                emit ZapOutBEP20(fromToken, token0, token1, amount, amountA , amountB);
            }
        }
    }

    /* ========== Private Functions ========== */

    /* 
    * Swap to other token in the pair. After that it will add liquidity.
    * Used for case: zap A -> A-B or B -> A-B (fromToken is in the pair)
    * This function to avoid CompilerError: Stack too deep, try removing local variables on Solidity 
    */
    function _swapAndAddLiquidity(address fromToken, address otherToken, uint amount, address receiver) private returns (uint liquidity) {
        uint sellAmount = amount.div(2);
        uint otherAmount = _swap(fromToken, sellAmount, otherToken, address(this));
        ( , , liquidity) = ROUTER.addLiquidity(fromToken, otherToken, amount.sub(sellAmount), otherAmount, 0, 0, receiver, block.timestamp, 0);
    }

    function _transferLeftOverToken(address token, address receiver, uint amount) private {
        require(receiver != address(0), 'Zap: receiver must not be zero address');
        uint currentBalance = IBEP20(token).balanceOf(address(this));
        require(currentBalance >= amount, 'Zap: not enough balance');
        IBEP20(token).safeTransfer(receiver, amount);
		emit TransferLeftOverToken(token, receiver, amount);
    }

    function _transferLeftOverBNB(address receiver, uint amount) private {
        require(receiver != address(0), 'Zap: receiver must not be zero address');
        uint currentBalance = address(this).balance;
        require(currentBalance >= amount, 'Zap: not enough balance');
        payable(receiver).transfer(amount);
		emit TransferLeftOverBNB(receiver, amount);
    }

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(-1));
        }
    }

    function _swapBNBToLpToken(address lpToken, uint amount, address receiver, uint bnbBalanceBefore) private returns(uint liquidity) {
        if (!isLpToken(lpToken)) {
            _swapBNBForToken(lpToken, amount, receiver);
        } else {
            IAlitaPair pair = IAlitaPair(lpToken);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == wbnb || token1 == wbnb) {
                address token = token0 == wbnb ? token1 : token0;
                liquidity = _addLiquidityBNB(token, amount, receiver, bnbBalanceBefore);
            } else {
				liquidity = _addLiquidity(token0, token1, amount, receiver);
            }
        }
    }

	/* 
    * Swap to LP token. The LP token is paired with BNB
    * This function to avoid CompilerError: Stack too deep, try removing local variables on Solidity 
    */
	function _addLiquidityBNB(address token, uint amount, address receiver, uint bnbBalanceBefore) private returns(uint liquidity) {
        uint tokenBalanceBefore = IBEP20(token).balanceOf(address(this));

        uint swapValue = amount.div(2);
        uint tokenAmount = _swapBNBForToken(token, swapValue, address(this));
        _approveTokenIfNeeded(token);

        (,, liquidity) = ROUTER.addLiquidityETH{value: amount.sub(swapValue)}(token, tokenAmount, 0, 0, receiver, block.timestamp, 0);

        uint tokenBalanceAfter = IBEP20(token).balanceOf(address(this));
        uint bnbBalanceAfter = address(this).balance;

        if (tokenBalanceAfter > 0 && tokenBalanceAfter > tokenBalanceBefore) {
            _transferLeftOverToken(token, msg.sender, tokenBalanceAfter.sub(tokenBalanceBefore));
        }
        if(bnbBalanceAfter > 0 && bnbBalanceAfter > bnbBalanceBefore) {
            _transferLeftOverBNB(receiver, bnbBalanceAfter.sub(bnbBalanceBefore));
        }
	}

    /* 
    * Swap to LP token. The LP token is not paired with BNB
    * This function to avoid CompilerError: Stack too deep, try removing local variables on Solidity 
    */
    function _addLiquidity(address token0, address token1, uint amount, address receiver) private returns (uint liquidity) {
        uint token0BalanceBefore = IBEP20(token0).balanceOf(address(this));
        uint token1BalanceBefore = IBEP20(token1).balanceOf(address(this));

		uint swapValue = amount.div(2);
        uint token0Amount = _swapBNBForToken(token0, swapValue, address(this));
        uint token1Amount = _swapBNBForToken(token1, amount.sub(swapValue), address(this));

        _approveTokenIfNeeded(token0);
        _approveTokenIfNeeded(token1);

        (,, liquidity) = ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp, 0);

        uint token0BalanceAfter = IBEP20(token0).balanceOf(address(this));
        uint token1BalanceAfter = IBEP20(token1).balanceOf(address(this));

        if (token0BalanceAfter > 0 && token0BalanceAfter > token0BalanceBefore) {
            _transferLeftOverToken(token0, msg.sender, token0BalanceAfter.sub(token0BalanceBefore));
        }
        if (token1BalanceAfter > 0 && token1BalanceAfter > token1BalanceBefore) {
            _transferLeftOverToken(token1, msg.sender, token1BalanceAfter.sub(token1BalanceBefore));
        }
    }

    function _swapBNBForToken(address token, uint value, address receiver) private returns (uint) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = wbnb;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = wbnb;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{value: value}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForBNB(address token, uint amount, address receiver) private returns (uint) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = wbnb;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = wbnb;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }
    
    function routePath(address fromToken, address toToken) private view returns (address[] memory path) {
        address intermediate = directRoutePairAddresses[keccak256(abi.encodePacked(fromToken, toToken))];

        if (intermediate == address(0)) {
            intermediate = directRoutePairAddresses[keccak256(abi.encodePacked(toToken, fromToken))];
        }

        if (intermediate == address(0)) {
            intermediate = routePairAddresses[fromToken];
        }

        if (intermediate == address(0)) {
            intermediate = routePairAddresses[toToken];
        }

        if (intermediate != address(0) && (fromToken == wbnb || toToken == wbnb)) {
            path = new address[](3);
            path[0] = fromToken;
            path[1] = intermediate;
            path[2] = toToken;
        } else if (intermediate != address(0) && (fromToken == intermediate || toToken == intermediate)) {
            path = new address[](2);
            path[0] = fromToken;
            path[1] = toToken;
        } else if (intermediate != address(0) && routePairAddresses[fromToken] == routePairAddresses[toToken]) {
            path = new address[](3);
            path[0] = fromToken;
            path[1] = intermediate;
            path[2] = toToken;
        } else if (
            routePairAddresses[fromToken] != address(0) &&
            routePairAddresses[toToken] != address(0) &&
            routePairAddresses[fromToken] != routePairAddresses[toToken]
        ) {
            path = new address[](5);
            path[0] = fromToken;
            path[1] = routePairAddresses[fromToken];
            path[2] = wbnb;
            path[3] = routePairAddresses[toToken];
            path[4] = toToken;
        } else if (intermediate != address(0) && routePairAddresses[fromToken] != address(0)) {
            path = new address[](4);
            path[0] = fromToken;
            path[1] = intermediate;
            path[2] = wbnb;
            path[3] = toToken;
        } else if (intermediate != address(0) && routePairAddresses[toToken] != address(0)) {
            path = new address[](4);
            path[0] = fromToken;
            path[1] = wbnb;
            path[2] = intermediate;
            path[3] = toToken;
        } else if (fromToken == wbnb || toToken == wbnb) {
            path = new address[](2);
            path[0] = fromToken;
            path[1] = toToken;
        } else {
            path = new address[](3);
            path[0] = fromToken;
            path[1] = wbnb;
            path[2] = toToken;
        }
    }

    function _swap(address fromToken, uint amount, address toToken, address receiver) private returns (uint) {
        address[] memory path = routePath(fromToken, toToken);
        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _safeSwapToBNB(uint amount) private returns (uint) {
        require(IBEP20(wbnb).balanceOf(address(this)) >= amount, 'Zap: Not enough WBNB balance');
        require(safeSwapBNB != address(0), 'Zap: safeSwapBNB is not set');
        uint beforeBNB = address(this).balance;
        ISafeSwapBNB(safeSwapBNB).withdraw(amount);
        return (address(this).balance).sub(beforeBNB);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function saveLeftOverToken(address token, address receiver, uint amount) public onlyOwner {
        _transferLeftOverToken(token, receiver, amount);
    }

    function saveLeftOverBNB(address receiver, uint amount) public onlyOwner {
        _transferLeftOverBNB(receiver, amount);
    }

    function setIsPaused(bool paused) public onlyOwner {
        isPaused = paused;
    }

    function setRoutePairAddress(address asset, address route) public onlyOwner {
        routePairAddresses[asset] = route;
    }

    function setDirectRoutePairAddress(bytes32 key, address route) public onlyOwner {
        directRoutePairAddresses[key] = route;
    }

    function setNotLpToken(address token) public onlyOwner {
        bool needPush = notLpToken[token] == false;
        notLpToken[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint i) external onlyOwner {
        address token = tokens[i];
        notLpToken[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep() external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint amount = IBEP20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForBNB(token, amount, owner());
            }
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IBEP20(token).safeTransfer(owner(), IBEP20(token).balanceOf(address(this)));
    }

    function setSafeSwapBNB(address _safeSwapBNB) external onlyOwner {
        safeSwapBNB = _safeSwapBNB;
        IBEP20(wbnb).approve(_safeSwapBNB, uint(-1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ISafeSwapBNB {
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './IAlitaRouter02.sol';

interface IZap {
    function zapOut(address fromToken, uint amount) external;
    function zapIn(address toToken) external payable;
    function zapInToken(address fromToken, uint amount, address toToken) external;
    function getIsLpToken(address token) external view returns (bool);
    function getRouter() external view returns (IAlitaRouter02);
    function routePair(address token) external view returns (address);
    function directRoutePair(bytes32 key) external view returns (address);
    function getWBNB() external view returns (address);
    function getRoutePath(address fromToken, address toToken) external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IAlitaRouter01.sol';

interface IAlitaRouter02 is IAlitaRouter01 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IAlitaPair {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IAlitaRouter01 {
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
        uint deadline,
        uint startingSwapTime
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint startingSwapTime
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}