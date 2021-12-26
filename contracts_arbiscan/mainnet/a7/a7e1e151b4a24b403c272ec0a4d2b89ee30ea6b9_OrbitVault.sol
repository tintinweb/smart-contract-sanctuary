pragma solidity 0.7.6;

import "IWETH9.sol";
import "Math.sol";
import "SafeMath.sol";
import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "IUniswapV3MintCallback.sol";
import "IUniswapV3SwapCallback.sol";
import "IUniswapV3Pool.sol";
import "TickMath.sol";
import "LiquidityAmounts.sol";
import "PositionKey.sol";
import "IVault.sol";
import "IOrbitVault.sol";
import "AlphaVault.sol";

contract OrbitVault is 
    IVault,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    ERC20,
    ReentrancyGuard,
    AlphaVault
{   
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address immutable weth;
    bool token0IsWeth;

    constructor(address _pool,
        uint256 _protocolFee,
        uint256 _maxTotalSupply,
        address wethAddress) 

        AlphaVault(_pool,
        _protocolFee,
        _maxTotalSupply) 
        
        {
            weth = wethAddress;
            token0IsWeth = IUniswapV3Pool(_pool).token0() == wethAddress;
        }

    event EthRefund(
        address indexed to,
        uint256 amount
    );

    function depositEth(
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountEthMin,
        address to
    )
        external
        nonReentrant
        payable
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {      
        require(amountTokenDesired > 0 || msg.value > 0, "amountTokenDesired or value");
        require(to != address(0) && to != address(this), "to");

        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount1Min;
        uint256 amount0Min;

        if (token0IsWeth) {
            amount0Desired = msg.value;
            amount1Desired = amountTokenDesired;
            amount0Min = amountEthMin;
            amount1Min = amountTokenMin;
        } else {
            amount0Desired = amountTokenDesired;
            amount1Desired = msg.value;
            amount0Min = amountTokenMin;
            amount1Min = amountEthMin;
        }
        
        // Poke positions so vault's current holdings are up-to-date
        _poke(baseLower, baseUpper);
        _poke(limitLower, limitUpper);

        // Calculate amounts proportional to vault's holdings
        (shares, amount0, amount1) = _calcSharesAndAmounts(amount0Desired, amount1Desired);
        require(shares > 0, "shares");
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Pull in tokens from sender
        IWETH9(weth).deposit{value: (token0IsWeth ? amount0 : amount1) }();
        if (msg.value >  (token0IsWeth ? amount0 : amount1) ) safeTransferETH(msg.sender, msg.value - (token0IsWeth ? amount0 : amount1));
        if (token0IsWeth) {
            token1.safeTransferFrom(msg.sender, address(this), amount1);
        }
        else { 
            token0.safeTransferFrom(msg.sender, address(this), amount0);
        }

        // Mint shares to recipient
        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, amount0, amount1);
        require(totalSupply() <= maxTotalSupply, "maxTotalSupply");
    }

    function withdrawEth(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0) && to != address(this), "to");
        uint256 totalSupply = totalSupply();

        // Burn shares
        _burn(msg.sender, shares);

        // Calculate token amounts proportional to unused balances
        uint256 unusedAmount0 = getBalance0().mul(shares).div(totalSupply);
        uint256 unusedAmount1 = getBalance1().mul(shares).div(totalSupply);

        // Withdraw proportion of liquidity from Uniswap pool
        (uint256 baseAmount0, uint256 baseAmount1) =
            _burnLiquidityShare(baseLower, baseUpper, shares, totalSupply);
        (uint256 limitAmount0, uint256 limitAmount1) =
            _burnLiquidityShare(limitLower, limitUpper, shares, totalSupply);

        // Sum up total amounts owed to recipient
        amount0 = unusedAmount0.add(baseAmount0).add(limitAmount0);
        amount1 = unusedAmount1.add(baseAmount1).add(limitAmount1);
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Push tokens to recipient
        if (token0IsWeth) {
            if (amount1 > 0) token1.safeTransfer(to, amount1);
            if (amount0 > 0) {
                IWETH9(weth).withdraw(amount0);
                safeTransferETH(to, amount0);
            }
        }
        else { 
            if (amount0 > 0) token0.safeTransfer(to, amount0);
            if (amount1 > 0) {
                IWETH9(weth).withdraw(amount1);
                safeTransferETH(to, amount1);
            }
        }

        emit Withdraw(msg.sender, to, shares, amount0, amount1);
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, 'STE');
        emit EthRefund(to, value);
    }

    fallback() external payable {
    }

}