/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
// NovaSwap™, by Nova Network Inc.
// https://www.novanetwork.io/

pragma solidity ^0.8.0;

// ERC-20 Interface
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

// NovaSwap Router Interface
interface NovaSwapRouter {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function swapExactTokensForTokens(

    // Amount of tokens being sent.
    uint256 amountIn,
    // Minimum amount of tokens coming out of the transaction.
    uint256 amountOutMin,
    // List of token addresses being traded.  This is necessary to calculate quantities.
    address[] calldata path,
    // Address that will receive the output tokens.
    address to,
    // Trade deadline time-out.
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

// NovaSwap Pair Interface
interface NovaSwapPair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

// NovaSwap Factory Interface
interface NovaSwapFactory {
  function getPair(address token0, address token1) external returns (address);
}

contract novaSwapContract {

    // Set the address of the UniswapV2 router.
    address private constant NOVA_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    // Wrapped native token address. This is necessary because sometimes it might be more
    // efficient to trade with the wrapped version of the native token, eg. WRAPPED, WRAPPED, WFTM.
    address private constant WRAPPED = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    address private constant ADMIN_ADDR = 0x499FbD6C82C7C5D42731B3E9C06bEeFdC494C852;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;


    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    function sendFee(address _tokenIn, uint256 amount) private returns (uint256) {
        // check the amount to send fee
        require(amount >= 100, "No enough amount");

        uint256 feeAmount = amount / 100;

        bool feeSendResult = IERC20(_tokenIn).transfer(ADMIN_ADDR, feeAmount);

        if (feeSendResult) {
            return feeAmount;
        } else {
            return 0;
        }
    }
    // This swap function is used to trade from one token to another.
    // The inputs are self explainatory.
    // tokenIn = the token address you want to trade out of.
    // tokenOut = the token address you want as the output of this trade.
    // amountIn = the amount of tokens you are sending in.
    // amountOutMin = the minimum amount of tokens you want out of the trade.
    // to = the address you want the tokens to be sent to.
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    )
        nonReentrant
        external
    {
        require(_amountIn >= 100, "No enough amount");
        // First we need to transfer the amount in tokens from the msg.sender to this contract.
        // This contract will then have the amount of in tokens to be traded.
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        // Next we need to allow the Uniswap V2 router to spend the token we just sent to this contract.
        // By calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract.
        IERC20(_tokenIn).approve(NOVA_ROUTER, _amountIn);
        
        // send fee
        uint fee = sendFee(_tokenIn, _amountIn);

        uint256 amountIn = _amountIn - fee;

        // Path is an array of addresses.
        // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
        // The 'if' statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
        address[] memory path;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
        }

        // // Then, we will call swapExactTokensForTokens.
        // // For the deadline we will pass in block.timestamp.
        // // The deadline is the latest time the trade is valid for.
        NovaSwapRouter(NOVA_ROUTER).swapExactTokensForTokens(amountIn, _amountOutMin, path, _to, block.timestamp);
    }

       // This function will return the minimum amount from a swap.
       // Input the 3 parameters below and it will return the minimum amount out.
       // This is needed for the swap function above.
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        // Path is an array of addresses.
        // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
        // The if statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
        address[] memory path;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = NovaSwapRouter(NOVA_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];
    }
}