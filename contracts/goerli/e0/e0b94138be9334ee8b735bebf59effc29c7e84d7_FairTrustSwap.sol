pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

// FAIR Token Swap

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract FairTrustSwap is Context, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    IERC20 public FAIR;
    IERC20 public TRUST;
    bool public swapEnabled;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public treasury;
    uint256 public swapDeadline;
    uint256 public swapStart;
    uint256 public swapStartDecrease;
    
    uint256 public fairSwapped = 0;
    uint256 public trustDistributed = 0;
    
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    event Swapped(address investor, uint256 amount, uint256 received);

    constructor(address _FAIR, address _TRUST, address _treasury) {
        // PancakeSwap v1
        uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        
        FAIR = IERC20(_FAIR);
        TRUST = IERC20(_TRUST);
        treasury = _treasury;
        
        swapEnabled = true;
        
        swapStart = 1624406400; // Jun 23 2021 00:00:00 GMT+0000
        swapStartDecrease = swapStart + 14 days;
        swapDeadline = 1638230400; // Nov 30 2021 00:00:00 GMT+0000
    }
    
    function setSwapStart(uint256 timestamp) external onlyOwner() {
        swapStart = timestamp;
    }
    function setSwapStartDecrease(uint256 timestamp) external onlyOwner() {
        swapStartDecrease = timestamp;
    }
    function setSwapDeadline(uint256 timestamp) external onlyOwner() {
        swapDeadline = timestamp;
    }

    function setNewToken(address _newToken) external onlyOwner {
        TRUST = IERC20(_newToken);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    modifier noContract() {
        require(
            Address.isContract(_msgSender()) == false,
            "Contracts are not allowed to interact with this contract"
        );
        _;
    }

    modifier canSwap() {
        require(block.timestamp >= swapStart, "Swap hasn't started yet");
        require(block.timestamp <= swapDeadline, "Swap has ended");
        require(swapEnabled == true, "Swap has been disabled");
        _;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }
    
    function burnRemainingUnclaimedTokens() external {
        require(
            isDeadlineReached() == true,
            "Deadline to swap tokens has not been reached"
        );
        TRUST.safeTransfer(
            burnAddress,
            TRUST.balanceOf(address(this))
        );
    }

    function isDeadlineReached() public view returns (bool) {
        return block.timestamp > swapDeadline;
    }
    
    function getTrustBalance() public view returns (uint256) {
        return TRUST.balanceOf(address(this));
    }
    
    function getFairBalance() public view returns (uint256) {
        return FAIR.balanceOf(address(this));
    }
    
    function getSwapRatio() public view returns (uint256) {
        uint256 swapRatio = 0;
        if(block.timestamp >= swapStart && block.timestamp <= swapStartDecrease) {
            swapRatio = 105;
        }
        if(block.timestamp > swapStartDecrease && block.timestamp <= swapDeadline) {
            uint256 totalTimeDiff = swapDeadline - swapStartDecrease;
            uint256 timeDiff = swapDeadline - block.timestamp;
            swapRatio = 20 + timeDiff.mul(85).div(totalTimeDiff);
        }
        return swapRatio;
    }

    function performSwap() external noContract nonReentrant canSwap {
        uint256 amount = FAIR.balanceOf(_msgSender());
        require(amount > 0, "You do not have FAIR tokens to swap");
        uint256 swapRatio = getSwapRatio();
        uint256 swapAmount = amount.mul(swapRatio).div(100);
        require(swapAmount > 0, "swapAmount is 0");
        require(TRUST.balanceOf(address(this)) >= swapAmount, "Not enough TRUST in contract");
        FAIR.safeTransferFrom(_msgSender(), address(this), amount);
        TRUST.safeTransfer(_msgSender(), swapAmount);
        fairSwapped += amount;
        trustDistributed += swapAmount;
        emit Swapped(_msgSender(), amount, swapAmount);
    }

    function swapTokensForEth() external onlyOwner() {
        uint256 tokenAmount = FAIR.balanceOf(address(this));
        require(tokenAmount > 0, "No FAIR remaining");
        require(treasury != address(0), "Treasury address must be set");
        address[] memory path = new address[](2);
        path[0] = address(FAIR);
        path[1] = uniswapV2Router.WETH();

        FAIR.approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            treasury,
            block.timestamp
        );
    }

    receive() external payable {
        revert();
    }

    // Function to allow owner to salvage BEP20 tokens sent to this contract (by mistake)
    function transferAnyBEP20Tokens(address _tokenAddr, uint _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddr);
        require(treasury != address(0), "Treasury address must be set");
        token.safeTransfer(treasury, _amount);
    }
}

// FUShappy