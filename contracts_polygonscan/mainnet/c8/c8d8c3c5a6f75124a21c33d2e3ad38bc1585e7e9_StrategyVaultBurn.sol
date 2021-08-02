// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./IDragonLair.sol";
import "./IStakingRewards.sol";
import "./IUniPair.sol";
import "./IUniRouter02.sol";

contract StrategyVaultBurn is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public quickSwapAddress;
    address public constant dragonLairAddress = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address public wantAddress;
    
    address public constant uniRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant dQuickAddress = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address public constant quickAddress = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant wethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant giveAddress = 0x9Bbcda2606e616659b118399A2823E8a392f55DA;
    address public vaultChefAddress;
    address public govAddress;

    uint256 public burnCycle = 6 hours;
    uint256 public lastEarnBlock = block.timestamp;
    uint256 public sharesTotal = 0;

    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address[] public quickToGivePath;

    constructor(
        address _vaultChefAddress,
        address _quickSwapAddress,
        address _wantAddress
    ) public {
        govAddress = msg.sender;
        vaultChefAddress = _vaultChefAddress;
        wantAddress = _wantAddress;
        quickSwapAddress = _quickSwapAddress;
        quickToGivePath = [quickAddress, wethAddress, usdcAddress, giveAddress];

        transferOwnership(vaultChefAddress);
        
        _resetAllowances();
    }
    
    event SetSettings(uint256 _slippageFactor,uint256 _burnCycle);
    
    modifier onlyGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }
    
    function deposit(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {
        // Call must happen before transfer
        uint256 wantLockedBefore = wantLockedTotal();

        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        // Proper deposit amount for tokens with fees, or vaults with deposit fees
        uint256 sharesAdded = _farm();
        if (sharesTotal > 0) {
            sharesAdded = sharesAdded.mul(sharesTotal).div(wantLockedBefore);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        return sharesAdded;
    }

    function _farm() internal returns (uint256) {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (wantAmt == 0) return 0;
        
        uint256 sharesBefore = vaultSharesTotal();
        IStakingRewards(quickSwapAddress).stake(wantAmt);
        uint256 sharesAfter = vaultSharesTotal();
        
        return sharesAfter.sub(sharesBefore);
    }

    function withdraw(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "_wantAmt is 0");
        
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        
        // Check if strategy has tokens from panic
        if (_wantAmt > wantAmt) {
            IStakingRewards(quickSwapAddress).withdraw(_wantAmt.sub(wantAmt));
            wantAmt = IERC20(wantAddress).balanceOf(address(this));
        }

        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (_wantAmt > wantLockedTotal()) {
            _wantAmt = wantLockedTotal();
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal());
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);

        IERC20(wantAddress).safeTransfer(vaultChefAddress, _wantAmt);

        return sharesRemoved;
    }
    
    function earn() external nonReentrant whenNotPaused onlyGov {
        if (block.timestamp > lastEarnBlock.add(burnCycle)) {
            burn();
        } else {
            lair();
        }
    }

    function lair() internal {
        IStakingRewards(quickSwapAddress).getReward();

        uint256 earnedAmt = IERC20(quickAddress).balanceOf(address(this));
        if (earnedAmt > 0) {
            IDragonLair(dragonLairAddress).enter(earnedAmt);
        }
    }

    function burn() internal {
        uint256 lairBalance = IERC20(dQuickAddress).balanceOf(address(this));
        if (lairBalance > 0) {
            IDragonLair(dragonLairAddress).leave(lairBalance);
            
            uint256 earnedAmt = IERC20(quickAddress).balanceOf(address(this));
            if (earnedAmt > 0) {
                _safeSwap(
                    earnedAmt,
                    quickToGivePath,
                    buyBackAddress
                );
            }
        }

        lastEarnBlock = block.timestamp;
    }

    // Emergency!!
    function pause() external onlyGov {
        _pause();
    }

    // False alarm
    function unpause() external onlyGov {
        _unpause();
        _resetAllowances();
    }
    
    function vaultSharesTotal() public view returns (uint256) {
        return IStakingRewards(quickSwapAddress).balanceOf(address(this));
    }
    
    function wantLockedTotal() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this))
            .add(IStakingRewards(quickSwapAddress).balanceOf(address(this)));
    }

    function _resetAllowances() internal {
        IERC20(wantAddress).safeApprove(quickSwapAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            quickSwapAddress,
            uint256(-1)
        );

        IERC20(quickAddress).safeApprove(dragonLairAddress, uint256(0));
        IERC20(quickAddress).safeIncreaseAllowance(
            dragonLairAddress,
            uint256(-1)
        );

        IERC20(quickAddress).safeApprove(uniRouterAddress, uint256(0));
        IERC20(quickAddress).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );
    }

    function resetAllowances() external onlyGov {
        _resetAllowances();
    }

    function panic() external onlyGov {
        _pause();
        IStakingRewards(quickSwapAddress).withdraw(vaultSharesTotal());
    }

    function unpanic() external onlyGov {
        _unpause();
        _farm();
    }
    
    function setSettings(uint256 _slippageFactor,uint256 _burnCycle) external onlyGov {
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");
        slippageFactor = _slippageFactor;
        burnCycle = _burnCycle;

        emit SetSettings(_slippageFactor,_burnCycle);
    }

    function setGov(address _govAddress) external onlyGov {
        govAddress = _govAddress;
    }
    
    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(uniRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(600)
        );
    }
}