pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IYFLPurchaser.sol";
import "./interfaces/ILinkswapPair.sol";
import "./interfaces/ILinkswapRouter.sol";
import "./interfaces/ILinkswapFactory.sol";

contract YFLPurchaser is IYFLPurchaser, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable governance;
    address public immutable link;
    address public immutable weth;
    address public immutable yfl;
    address public immutable linkSwapRouter;
    uint256 public immutable timeSlip;
    uint256 public immutable maxLenghtEmergencyWithdrawal;
    uint256 public immutable maxLenghtPurchaseYfl;
    uint256 public slipTolerance;

    modifier onlyGovernance() {
        require(msg.sender == governance, "YFLPurchaser: FORBIDDEN");
        _;
    }

    constructor(
        address _governance,
        address _link,
        address _weth,
        address _yfl,
        address _linkSwapRouter,
        uint256 _timeSlip,
        uint256 _maxLenghtEmergencyWithdrawal,
        uint256 _maxLenghtPurchaseYfl,
        uint256 _slipTolerance
    ) public {
        require(
            _governance != address(0) &&
                _link != address(0) &&
                _weth != address(0) &&
                _yfl != address(0) &&
                _linkSwapRouter != address(0) &&
                _timeSlip > 0 &&
                _maxLenghtEmergencyWithdrawal > 0 &&
                _maxLenghtPurchaseYfl > 0 &&
                _slipTolerance > 0,
            "YFLPurchaser: ZERO_ADDRESS"
        );
        governance = _governance;
        link = _link;
        weth = _weth;
        yfl = _yfl;
        linkSwapRouter = _linkSwapRouter;
        timeSlip = _timeSlip;
        maxLenghtPurchaseYfl = _maxLenghtPurchaseYfl;
        maxLenghtEmergencyWithdrawal = _maxLenghtEmergencyWithdrawal;
        slipTolerance = _slipTolerance;
    }

    function setSlipTolerance(uint256 tol) external onlyGovernance {
        slipTolerance = tol;
    }

    // transfers all tokens back to governance address
    function emergencyWithdraw(address[] calldata tokens) external onlyGovernance {
        uint256 size = tokens.length;
        require(maxLenghtEmergencyWithdrawal >= size, "YFL: EXCEEDED_MAX_TOKEN_ARRAY_SIZE");
        for (uint256 i = 0; i < size; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransfer(governance, token.balanceOf(address(this)));
        }
    }

    // Redeems all LPs passed in tokens collection and converts all underlying assets to YFL
    function purchaseYfl(address[] calldata tokens) external override onlyGovernance nonReentrant {
        uint256 size = tokens.length;
        require(maxLenghtEmergencyWithdrawal >= size, "YFL: EXCEEDED_MAX_TOKEN_ARRAY_SIZE");

        for (uint256 i = 0; i < tokens.length; i++) {
            address token0 = ILinkswapPair(tokens[i]).token0();
            address token1 = ILinkswapPair(tokens[i]).token1();
            uint256 amount = ILinkswapPair(tokens[i]).balanceOf(address(this));
            
            require(token0 == link || token0 == weth || token1 == link || token1 == weth, "YFLPurchaser: INVALID_TOKEN");
            require(amount > 0, "YFLPurchaser: ZERO_LIQUIDITY");
            
            ILinkswapPair(tokens[i]).approve(tokens[i], amount);
            ILinkswapPair(tokens[i]).approve(linkSwapRouter, amount);

            uint256 token0BalanceLp = IERC20(token0).balanceOf(tokens[i]);
            uint256 token1BalanceLp = IERC20(token1).balanceOf(tokens[i]);
            uint256 totalSupply = ILinkswapPair(tokens[i]).totalSupply();
            uint256 naive0 = amount.mul(token0BalanceLp).div(totalSupply);
            uint256 naive1 = amount.mul(token1BalanceLp).div(totalSupply);

            ILinkswapRouter(linkSwapRouter).removeLiquidity(
                token1,
                token0,
                amount,
                naive1,
                naive0,
                address(this),
                now.add(timeSlip)
            );
            
            // If one of the underlying assets on LP is YFL carry on, no need to convert YFL back to WETH or LINK
            if(token1 == yfl || token0 == yfl) continue;

            // If not YFL convert tokens that are not link to link and not weth to weth
            if(token0 == link || token0 == weth) _convert(token1, token0, tokens[i]); else _convert(token0, token1, tokens[i]);   
        }

        address factory = ILinkswapRouter(linkSwapRouter).factory();

        if(IERC20(link).balanceOf(address(this)) > 0) _convert(link, yfl, ILinkswapFactory(factory).getPair(link, yfl));

        if(IERC20(weth).balanceOf(address(this)) > 0) _convert(weth, yfl, ILinkswapFactory(factory).getPair(weth, yfl));

        IERC20 yflToken = IERC20(yfl);
        yflToken.safeTransfer(governance, yflToken.balanceOf(address(this)));
    }

    function _convert(address token0, address token1, address lp) private {
        require(lp != address(0), "YFLPurchaser: LP_NOT_FOUND");
        uint256 balance0 = IERC20(token0).balanceOf(address(this));

        if (balance0 > 0){
            require(IERC20(token0).balanceOf(lp) > balance0.mul(slipTolerance), "YFLPurchaser: LIQUIDITY_TOO_LOW");
            IERC20(token0).approve(linkSwapRouter, balance0);
            address[] memory path = new address[](2);
            path[0] = token0;
            path[1] = token1;
            ILinkswapRouter(linkSwapRouter).swapExactTokensForTokens(
                balance0,
                0, // is optimal returns according to uniswap v2 router code base
                path,
                address(this),
                now.add(timeSlip)
            );
        }
    }
}