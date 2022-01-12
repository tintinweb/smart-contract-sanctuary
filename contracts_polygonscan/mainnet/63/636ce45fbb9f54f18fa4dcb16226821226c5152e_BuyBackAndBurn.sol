/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: Upgradeable_0_8

contract Upgradeable_0_8 is Ownable {
    address public implementation;
}

interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        returns (uint256 amountOut);

    function exactOutput(ExactOutputParams calldata params)
        external
        returns (uint256 amountIn);

    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

interface IPriceGetterP125 {
    struct V3Specs {
        address token0;
        address token1;
        address pool;
        uint128 baseAmount;
        uint32 secondsAgo;
        bytes route;
    }

    function worstExecPrice(V3Specs memory specs)
        external
        view
        returns (uint256 quoteAmount);
}

contract BuyBackAndBurn is Upgradeable_0_8 {
    IPriceGetterP125.V3Specs public specsForTWAP;
    uint256 public maxPriceDisagreement; //set value as 100+x% on WEI_PRECISION_PERCENT
    bool public isPaused;
    address public treasuryWallet;
    IPriceGetterP125 public priceGetter;

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant P125 = 0x83000597e8420aD7e9EDD410b2883Df1b83823cF;
    IUniswapV3SwapRouter public constant SWAP_ROUTER =
        IUniswapV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45); //uni v3
    IQuoter public constant QUOTER =
        IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); //uni v3 quote v2
    uint256 public constant WEI_PRECISION_PERCENT = 10**20; //1e18 precision on percentages

    event BuyBack(
        uint256 indexed price,
        uint256 amountIn,
        uint256 amountBought
    );

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused || msg.sender == owner(), "paused");
        _;
    }

    function getDebtTokenAmountOut(uint256 amountIn) public returns (uint256) {
        return QUOTER.quoteExactInput(specsForTWAP.route, amountIn);
    }

    function worstExecPrice() public view returns (uint256) {
        uint256 quoteAmount = priceGetter.worstExecPrice(specsForTWAP);
        return (quoteAmount * maxPriceDisagreement) / WEI_PRECISION_PERCENT;
    }

    function buyBack(uint256 percentage) public checkPause onlyEOA {
        uint256 buyAmount;
        uint256 fullBalance = IERC20Metadata(USDC).balanceOf(address(this));
        uint256 minAmountOut = (worstExecPrice() * fullBalance) / 10**6;
        uint256 balanceUsed;
        uint256 execPrice;
        if (getDebtTokenAmountOut(fullBalance) >= minAmountOut) {
            (execPrice, balanceUsed, buyAmount) = _buyDebtToken(
                WEI_PRECISION_PERCENT
            ); //uses full amount
        } else {
            (execPrice, balanceUsed, buyAmount) = _buyDebtToken(percentage); //uses partial
        }
        emit BuyBack(execPrice, balanceUsed, buyAmount);
    }

    function _buyDebtToken(uint256 percentage)
        internal
        returns (
            uint256 price,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        uint256 bought;
        uint256 balanceUsed = (IERC20Metadata(USDC).balanceOf(address(this)) *
            percentage) / WEI_PRECISION_PERCENT;
        uint256 minAmountOut = (worstExecPrice() * balanceUsed) / 10**6;
        uint256 execPrice = getDebtTokenAmountOut(balanceUsed);
        require(
            minAmountOut / 10**12 >= balanceUsed,
            "worst absolue price is 1:1"
        ); //caps buyback price to $1
        IUniswapV3SwapRouter.ExactInputParams
            memory params = IUniswapV3SwapRouter.ExactInputParams({
                path: specsForTWAP.route,
                recipient: address(this),
                amountIn: balanceUsed,
                amountOutMinimum: minAmountOut
            });
        return (execPrice, balanceUsed, SWAP_ROUTER.exactInput(params));
    }

    // OnlyOwner functions

    function togglePause(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    function sendToTreasury() public onlyOwner {
        IERC20Metadata(P125).transfer(
            treasuryWallet,
            IERC20Metadata(P125).balanceOf(address(this))
        ); //transfers full balance to multisig to be sent to Ethereum and burnt
    }

    function setApproval() public onlyOwner {
        IERC20Metadata(USDC).approve(address(SWAP_ROUTER), 0);
        IERC20Metadata(USDC).approve(address(SWAP_ROUTER), type(uint256).max);
    }

    function setPriceGetter(IPriceGetterP125 _wallet) public onlyOwner {
        priceGetter = _wallet;
    }

    function setTreasuryWallet(address _wallet) public onlyOwner {
        treasuryWallet = _wallet;
    }

    function setMaxPriceDisagreement(uint256 value) public onlyOwner {
        maxPriceDisagreement = value;
    }

    function setTWAPSpecs(IPriceGetterP125.V3Specs memory specs)
        public
        onlyOwner
    {
        specsForTWAP = specs;
    }

    function rescue(IERC20 _token) public onlyOwner {
        _token.transfer(
            msg.sender,
            _token.balanceOf(address(this))
        );
    }
}