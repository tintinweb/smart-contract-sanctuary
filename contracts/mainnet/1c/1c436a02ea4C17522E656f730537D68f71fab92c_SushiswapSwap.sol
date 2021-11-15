// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token1() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
}

interface Sushiswap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract SushiswapSwap {
    address public weth;
    address public sushiswap;
    IERC20 public outputToken;
    address public swapOutputDestinationAddress;
    address public swapController;
    address public pairAddress;
    uint256 public maxSlippagePercentageBasisPoints;

    event SwapForMinimum(uint256 wethAmount, uint256 minOutputTokenAmount);

    constructor(
        address _outputTokenAddress,
        address _swapOutputDestinationAddress,
        address _swapController,
        address _pairAddress,
        address _wethAddress,
        address _sushiswapAddress,
        uint256 _maxSlippagePercentageBasisPoints
    ) {
        outputToken = IERC20(_outputTokenAddress);
        swapOutputDestinationAddress = _swapOutputDestinationAddress;
        swapController = _swapController;
        pairAddress = _pairAddress;
        weth = _wethAddress;
        sushiswap = _sushiswapAddress;
        IERC20(weth).approve(_sushiswapAddress, type(uint256).max);
        maxSlippagePercentageBasisPoints = _maxSlippagePercentageBasisPoints;
    }

    modifier onlySwapController() {
        require(msg.sender == swapController, "Only swapController may call this function.");
        _;
    }

    function swap() public {
        uint256 minimumAcceptableBuyAmount = getMinAcceptableBuyAmount();

        IWETH(weth).deposit{value: address(this).balance}();
        uint256 amountIn = IERC20(weth).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(outputToken);

        emit SwapForMinimum(amountIn, minimumAcceptableBuyAmount);

        Sushiswap(sushiswap).swapExactTokensForTokens(
            amountIn,
            minimumAcceptableBuyAmount,
            path,
            swapOutputDestinationAddress,
            block.timestamp
        );
    }

    function getMinAcceptableBuyAmount() public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint Res0, uint Res1,) = pair.getReserves();
        uint res0 = Res0*(10**18);
        uint256 price = address(this).balance / (res0/Res1);
        uint256 minimumAcceptableBuy = ((price * (10000 - maxSlippagePercentageBasisPoints))*(10**18)) / 10000;
        return minimumAcceptableBuy;
    }

    function setMaxSlippagePercentageBasisPoints(uint256 _maxSlippagePercentageBasisPoints) public onlySwapController {
        require(_maxSlippagePercentageBasisPoints > 0, "_maxSlippagePercentageBasisPoints must be more than zero");
        maxSlippagePercentageBasisPoints = _maxSlippagePercentageBasisPoints;
    }

    receive() external payable {}

    // Failure case fallback functions below

    function fallbackSwap(uint256 _amountOutMin) public onlySwapController {
        IWETH(weth).deposit{value: address(this).balance}();
        uint256 amountIn = IERC20(weth).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(outputToken);

        emit SwapForMinimum(amountIn, _amountOutMin);

        Sushiswap(sushiswap).swapExactTokensForTokens(
            amountIn,
            _amountOutMin,
            path,
            swapOutputDestinationAddress,
            block.timestamp
        );
    }

    function emergencyExit() public onlySwapController {
        (bool success, ) = swapController.call{value: address(this).balance}("");
        require(success, "Emergency exit failed.");
    }

    function emergencyExitToEndpoint(address endpoint) public onlySwapController {
        (bool success, ) = endpoint.call{value: address(this).balance}("");
        require(success, "Emergency exit to endpoint failed.");
    }

}

