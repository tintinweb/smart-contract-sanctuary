// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";

import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./Context.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IStrategy.sol";

interface IQuickSwapFarm {

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function earned(address account) external view returns (uint256);

  function getReward() external;

}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ITreasury {
    function notifyExternalReward(uint256 _amount) external;
}

contract PolyStrategyQuickSwap is Ownable, ReentrancyGuard, Pausable, IStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public farmContractAddress; // address of farm, eg, PCS, Thugs etc.
     address public wantAddress;
    address public earnedAddress;
    mapping(address => mapping(address => address[])) public paths;

    address public operator;
    address public timelock;
    bool public notPublic = false; // allow public to call earn() function

    uint256 public lastEarnBlock = 0;
    uint256 public override wantLockedTotal = 0;
   
    event Withdraw(uint256 amount);
    event Earned(address earnedAddress, uint256 earnedAmt);
    event InCaseTokensGetStuck(address tokenAddress, uint256 tokenAmt, address receiver);
    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    constructor(
        address _controller,
        address _farmContractAddress,
        address _wantAddress,
        address _earnedAddress,
        address _timelockAddress
    ) public {
        operator = msg.sender;

        wantAddress = _wantAddress;

        farmContractAddress = _farmContractAddress;
        timelock = _timelockAddress;
        earnedAddress = _earnedAddress;

        transferOwnership(_controller);
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Strategy: caller is not the operator");
        _;
    }

    modifier onlyTimelock() {
        require(timelock == msg.sender, "Strategy: caller is not timelock");
        _;
    }
    
    function fetchDepositFee() override external pure returns (uint256) {
        return 0;
    }

    function isAuthorised(address _account) public view returns (bool) {
        return (_account == operator)  || (_account == timelock);
    }

    // Receives new deposits from user
    function deposit(uint256 _wantAmt) override public onlyOwner whenNotPaused returns (uint256) {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        _farm();

        wantLockedTotal = wantLockedTotal.add(_wantAmt);

 
        return _wantAmt;
    }

    function farm() public nonReentrant {
        _farm();
    }

    function _farm() internal {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);
        IQuickSwapFarm(farmContractAddress).stake(wantAmt);

    }

    function withdraw(uint256 _wantAmt) override public onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "Strategy: !_wantAmt");

        IQuickSwapFarm(farmContractAddress).withdraw(_wantAmt);
   
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

  
        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        IERC20(wantAddress).safeTransfer(address(msg.sender), _wantAmt);

        emit Withdraw(_wantAmt);

        return _wantAmt;
    }

    function earn() public override whenNotPaused {
        require(!notPublic || isAuthorised(msg.sender), "Strategy: !authorized");

        // Harvest farm tokens
        IQuickSwapFarm(farmContractAddress).getReward();
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (earnedAmt>0)
        {
            IERC20(earnedAddress).safeTransfer(operator, earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function pendingHarvest() public view returns (uint256) {
        uint256 _earnedBal = IERC20(earnedAddress).balanceOf(address(this));
        return IQuickSwapFarm(farmContractAddress).earned(address(this)).add(_earnedBal);
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyTimelock {
        _unpause();
    }

    function setOperator(address _operator) external onlyTimelock {
        operator = _operator;
    }

    function setNotPublic(bool _notPublic) external onlyOperator {
        notPublic = _notPublic;
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) override external onlyTimelock {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
        emit InCaseTokensGetStuck(_token, _amount, _to);
    }

    function setTimelock(address _timelock) external onlyTimelock {
        timelock = _timelock;
    }
}