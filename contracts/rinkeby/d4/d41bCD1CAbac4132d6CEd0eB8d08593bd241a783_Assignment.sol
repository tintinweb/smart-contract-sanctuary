// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Assignment {

    // owner address
    address public owner;

    // stable coin address
    address public stableCoinAddress;

    // WETH address
    address public WETHAddress;

    IERC20 stableCoin;

    // Vendor struct
    struct Vendor {
        address vendorAddress;
        address tokenAddress;
        uint256 fees;
        bool isPresent;
    }

    // Mapping of token address to vendor struct
    mapping (uint256 => Vendor) public vendorMapping;

    // Mapping of received balances
    mapping (address => uint256) public receivedBalances;

    IUniswapV2Router02 public immutable swapRouter;

    uint24 public poolFee = 3000;

    event SomethingHappened();

    constructor(address _stableCoinAddress, address _WETHAddress, IUniswapV2Router02 _swapRouter) {
        stableCoinAddress = _stableCoinAddress;
        WETHAddress = _WETHAddress;
        stableCoin = IERC20(stableCoinAddress);
        swapRouter = _swapRouter;
        owner = msg.sender;
    }

    function placeOrder(
        uint256 orderId,
        uint256 quantity
    ) public {

        // Check if orderid is present
        if (vendorMapping[orderId].isPresent) {
            IERC20 vendorToken = IERC20(vendorMapping[orderId].tokenAddress);
            
            vendorToken.approve(address(this), quantity);
            // Delegated transfer to self from user
            vendorToken.transferFrom(msg.sender, address(this), quantity);
            // TransferHelper.safeTransferFrom(vendorMapping[orderId].tokenAddress, msg.sender, address(this), quantity);
            // Reduce the fees and add to balance
            uint256 fees = (vendorMapping[orderId].fees * quantity)/100;
            uint256 balance = quantity - fees;
            receivedBalances[vendorMapping[orderId].tokenAddress] += fees;

            // Convert balance to equivalent StableCoin and send to vendor
            // TransferHelper.safeApprove(vendorMapping[orderId].tokenAddress, address(swapRouter), balance);
            vendorToken.approve(address(swapRouter), quantity);

            address[] memory path;

            if(vendorMapping[orderId].tokenAddress == WETHAddress) {
                path = new address[](2);
                path[0] = vendorMapping[orderId].tokenAddress;
                path[1] = stableCoinAddress;
            } else {
                path = new address[](3);
                path[0] = vendorMapping[orderId].tokenAddress;
                // path[1] = WETHAddress;
                path[1] = stableCoinAddress;
            }

            emit SomethingHappened();

            swapRouter.swapExactTokensForTokens(balance, 0, path, vendorMapping[orderId].vendorAddress, block.timestamp);

            // ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            //     tokenIn: vendorMapping[orderId].tokenAddress,
            //     tokenOut: stableCoinAddress,
            //     fee: poolFee,
            //     recipient: vendorMapping[orderId].vendorAddress,
            //     deadline: block.timestamp,
            //     amountIn: balance,
            //     amountOutMinimum: 0,
            //     sqrtPriceLimitX96: 0
            // });

            // amountOut = swapRouter.exactInputSingle(params);
        }

    }

    function addVendor(
        uint256 _orderId,
        address _vendorAddress,
        address _tokenAddress,
        uint256 _fees
    ) public {
        require(msg.sender == owner);

        // Check if orderid is present
        require(!vendorMapping[_orderId].isPresent);

        Vendor memory vendor = Vendor(_vendorAddress, _tokenAddress, _fees, true);
        vendorMapping[_orderId] = vendor;
    }

    function withdraw(
        address tokenAddress,
        uint256 balance
    ) public {
        require(msg.sender == owner);

        require(receivedBalances[tokenAddress] >= balance);

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, tokenAddress, balance);

        receivedBalances[tokenAddress] -= balance;
    } 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}