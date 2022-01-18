/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
}
interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}
interface IWETHGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;
}
interface IWrap { 
    function withdraw(uint amount) external;
}
/// @title Flippening Bridge
/// @author Pranay Reddy
/// @notice A bridge that helps use BTC on Ethereum's DeFi
/// @dev This is just a simulation contract. Don't use in production.
contract FlippeningBridgeV2{
    IGatewayRegistry public immutable registry; // Ren VM Gateway registry contract
    IUniswapV2Router02 public immutable swapRouter; // Uniswap V3 Swaprouter contract
    IWETHGateway public immutable wethGateway; // AAVE native ETH deposit contract
    IWrap public immutable WETHContract; // The WETH Contract for wrap or unwraps
    IERC20 public immutable WBTCContract; // The WBTC Contract for approvals

    address public constant BTC = 0x0A9ADD98C076448CBcFAcf5E457DA12ddbEF4A8f; // renBTC 
    address public constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // WETH
    uint24 public constant poolFee = 3000; // Uniswap pool fees

    address public currentLendingPool = 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe; // Default lendingpool
    address private owner = address(0);

    bool internal locked = false;

    event Deposit(address indexed user, uint256 indexed amount, uint256 blockNumber);
    event WithdrawBTC(address indexed user, uint256 indexed amount, uint256 blockNumber);
    event SwapToETH(address indexed user, uint256 indexed ethAmount);
    event WithdrawETH(address indexed user, uint256 indexed ethAmount, uint256 blockNumber);
    event DepositToAave(address indexed user, uint256 indexed ethAmount, uint256 blockNumber);

    constructor(IGatewayRegistry _registry, IUniswapV2Router02 _swapRouter, IWETHGateway _wethgateway, IWrap _wethaddress, IERC20 _wbtcaddress) {
        registry = _registry;
        swapRouter = _swapRouter;
        wethGateway = _wethgateway;
        owner = msg.sender;
        WETHContract = _wethaddress;
        WBTCContract = _wbtcaddress;
    }

    /// @notice Changes the current AAVE lending pool address
    /// @dev Using modifier is the correct way
    /// @param newLendingPool The address of new lending pool
    function changeLendingPoolAddress(address newLendingPool) external {
        require(msg.sender == owner, "Only owner can change");
        currentLendingPool = newLendingPool;
    }

    function swapToETH(uint amountMinted) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = BTC;
        path[1] = WETH9;
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(amountMinted, 0, path, address(this), block.timestamp);
        return amounts[amounts.length - 1];
    }

    // Below are testing functions used by Owner 
    function unwrapWETHToOwner(uint amount) external {
        require(msg.sender == owner, "Only owner can test");
        WETHContract.withdraw(amount);
        (bool success, ) = owner.call{value:amount}("");
        require(success, "Transfer Failed, reverting");
    }
    function unwrapWETHToContract(uint amount) external {
        require(msg.sender == owner, "Only owner can test");
        WETHContract.withdraw(amount);
    }
    function stakeOnAaveOwner() external{
        require(msg.sender == owner, "Only owner can test");
        uint256 ethOut = IERC20(WETH9).balanceOf(owner);
        WETHContract.withdraw(ethOut);
        wethGateway.depositETH{value : ethOut}(currentLendingPool, msg.sender, 0);
    }
    function swapToETHOwner(uint amountIn) external returns (uint) {
        require(msg.sender == owner, "Only owner can test");
        address[] memory path = new address[](2);
        path[0] = BTC;
        path[1] = WETH9;
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
        return amounts[amounts.length - 1];
    
    }

    /// @notice Unwrap WETH of user in this contract
    /// @dev Typed interface must be used to have type safety
    /// @param amount Amount of WETH to unwrap
    function unwrapWETH(uint amount) internal
    {
       WETHContract.withdraw(amount);
    }

    /// @notice Bridge BTC and withdraw renBTC
    /// @param _msg User Message payload
    /// @param recipient Destination address user supplied
    function receiveWrappedBTC(bytes calldata _msg, address recipient, uint256 _amount,bytes32 _nHash,bytes calldata _sig) external
    {
        bytes32 payloadHash = keccak256(abi.encode(_msg, recipient));
        uint256 amountMinted = registry.getGatewayBySymbol("BTC").mint(payloadHash, _amount, _nHash, _sig);
        emit Deposit(recipient, amountMinted, block.number);
        bool success = registry.getTokenBySymbol("BTC").transfer(recipient, amountMinted);
        require(success);
        emit WithdrawBTC(recipient, amountMinted, block.number);
    }
    
    function approveBTC() external {
        require(msg.sender == owner, "Only owner can call approve");
        WBTCContract.approve(address(swapRouter), (2 ** 256) - 1);
    }
    /// @notice Bridge BTC and swap renBTC, then receive ETH
    /// @dev Low level allowance calls can be prevented
    /// @param _msg User Message payload
    /// @param recipient Destination address user supplied
    function receiveETH(bytes calldata _msg, address recipient, uint256 _amount,bytes32 _nHash,bytes calldata _sig) external
    {
        bytes32 payloadHash = keccak256(abi.encode(_msg, recipient));
        uint256 amountMinted = registry.getGatewayBySymbol("BTC").mint(payloadHash, _amount, _nHash, _sig);
        emit Deposit(recipient, amountMinted, block.number);

        uint ethOut = swapToETH(amountMinted);
        unwrapWETH(ethOut);
        require(!locked, "Re entrancy not allowed");
        locked = true;
        (bool success, ) = recipient.call{value : ethOut}("");
        require(success, "Transfer failed, reverting.");
        locked = false;
        emit WithdrawETH(recipient, ethOut, block.number);
    }

    /// @notice Bridge BTC and swap renBTC for ETH, stake on AAVE on behalf of user
    /// @dev Low level allowance calls can be prevented
    /// @param _msg User Message payload
    /// @param recipient Destination address user supplied
    function stakeOnAave(bytes calldata _msg, address recipient, uint256 _amount,bytes32 _nHash,bytes calldata _sig) external
    {
        bytes32 payloadHash = keccak256(abi.encode(_msg, recipient));
        uint256 amountMinted = registry.getGatewayBySymbol("BTC").mint(payloadHash, _amount, _nHash, _sig);
        emit Deposit(recipient, amountMinted, block.number);

        uint ethOut = swapToETH(amountMinted);
        unwrapWETH(ethOut);
        wethGateway.depositETH{value : ethOut}(currentLendingPool, msg.sender, 0);
        emit DepositToAave(recipient, ethOut, block.number);
    }
}