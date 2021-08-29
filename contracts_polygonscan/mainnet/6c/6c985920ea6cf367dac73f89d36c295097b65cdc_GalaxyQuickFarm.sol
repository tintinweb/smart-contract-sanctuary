// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IStakingRewards.sol";
import "./IGalaxyVaultCash.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";

contract GalaxyQuickFarm is Ownable, ReentrancyGuard, Pausable { 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public quickSwapAddress;    
    address public wantAddress;         
    address public token0Address;       
    address public token1Address;       
    address public earnedAddress;       
    
    address public uniRouterAddress      = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;   
    address public constant usdcAddress  = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;   
    address public constant wmaticAddress= 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;   
    address public constant galaxyAddress= 0x336D8B78AdFA1c415CC3586585FC0F54B66AaD60;   
    address public constant vaultsAddress= 0x23CEffc66f3243aef06279d47c9b6D1C4D2860f4;   
    address public constant burnAddress  = 0x000000000000000000000000000000000000dEaD;   
    address public constant feeAddress   = 0x933a1d5f9Da62b0c69b8770878459Bf8095C7DD0;   
    address public constant rewardAddress= 0xE4B34fc01209549FaAa102892Ed593C8D3e2468F;
    address public masterChefAddress;   
    address public govAddress;          

    uint256 public lastEarnBlock = block.number;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 100;
    uint256 public rewardRate = 200;
    uint256 public buyBackRate = 200;
    uint256 public constant feeMaxTotal = 1000;
    uint256 public constant feeMax = 9900; 

    uint256 public withdrawFeeFactor = 10000; // 0% withdraw fee
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 10000; // 10000 - 9900 = 100 ; tuong duong 0.1% 

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address[] public earnedToWmaticPath = [0x831753DD7087CaC61aB5644b308642cc1c33Dc13,0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270]; // QUICK,MATIC
    address[] public earnedToUsdcPath   = [0x831753DD7087CaC61aB5644b308642cc1c33Dc13,0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174]; // QUICK,USDC  
    address[] public earnedToGalaxyPath = [0x831753DD7087CaC61aB5644b308642cc1c33Dc13,0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,0x336D8B78AdFA1c415CC3586585FC0F54B66AaD60]; // QUICK,MATIC,GALAXY
    address[] public earnedToToken0Path = [0x831753DD7087CaC61aB5644b308642cc1c33Dc13,0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270]; // QUICK,MATIC
    address[] public earnedToToken1Path = [0x831753DD7087CaC61aB5644b308642cc1c33Dc13,0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174]; // QUICK,USDC
    address[] public token0ToEarnedPath = [0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,0x831753DD7087CaC61aB5644b308642cc1c33Dc13]; // MATIC,QUICK
    address[] public token1ToEarnedPath = [0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,0x831753DD7087CaC61aB5644b308642cc1c33Dc13]; // USDC,QUICK

    constructor() public {
        govAddress = msg.sender;
        masterChefAddress = 0xaBC74A62F6cC74410E70e891e9EB6C7F367D2eaA;
        wantAddress       = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
        quickSwapAddress  = 0x6C6920aD61867B86580Ff4AfB517bEc7a499A7Bb;
        earnedAddress     = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
        token0Address     = IUniRouter02(uniRouterAddress).WETH();
        token1Address     = address(galaxyAddress);
        transferOwnership(masterChefAddress);
        _resetAllowances();
    }
    
    event SetSettings(
        uint256 _controllerFee,
        uint256 _rewardRate,
        uint256 _buyBackRate,
        uint256 _withdrawFeeFactor,
        uint256 _slippageFactor,
        address _uniRouterAddress
    );
    
    modifier onlyGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }
    
    function deposit(uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {
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

    function withdraw(uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256) {
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
        
        // Withdraw fee
        uint256 withdrawFee = _wantAmt
            .mul(withdrawFeeFactorMax.sub(withdrawFeeFactor))
            .div(withdrawFeeFactorMax);
        if(withdrawFee > 0) { IERC20(wantAddress).safeTransfer(vaultsAddress, withdrawFee); }    
        
        _wantAmt = _wantAmt.sub(withdrawFee);

        IERC20(wantAddress).safeTransfer(masterChefAddress, _wantAmt);

        return sharesRemoved;
    }

    function earn() external nonReentrant whenNotPaused onlyGov {
        // Harvest farm tokens
        IStakingRewards(quickSwapAddress).getReward();

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAmt > 0) {
            earnedAmt = distributeFees(earnedAmt);
            earnedAmt = distributeRewards(earnedAmt);
            earnedAmt = buyBack(earnedAmt);
    
            if (earnedAddress != token0Address) {
                // Swap half earned to token0
                _safeSwap(
                    earnedAmt.div(2),
                    earnedToWmaticPath,
                    address(this)
                );
            }
    
            if (earnedAddress != token1Address) {
                // Swap half earned to token1
                _safeSwap(
                    earnedAmt.div(2),
                    earnedToGalaxyPath,
                    address(this)
                );
            }
    
            // Get want tokens, ie. add liquidity
            uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
            uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
            if (token0Amt > 0 && token1Amt > 0) {
                IUniRouter02(uniRouterAddress).addLiquidity(
                    token0Address,
                    token1Address,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    now.add(600)
                );
            }
    
            lastEarnBlock = block.number;
    
            _farm();
        }
    }
    
    // To pay for earn function
    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        if (controllerFee > 0) {
            uint256 fee = _earnedAmt.mul(controllerFee).div(feeMax);
    
            _safeSwapWmatic(
                fee,
                earnedToWmaticPath,
                feeAddress
            );
            
            _earnedAmt = _earnedAmt.sub(fee);
        }

        return _earnedAmt;
    }

    function distributeRewards(uint256 _earnedAmt) internal returns (uint256) {
        if (rewardRate > 0) {
            uint256 fee = _earnedAmt.mul(rewardRate).div(feeMax);
    
            uint256 wmaticBefore = IERC20(wmaticAddress).balanceOf(address(this));
            
            _safeSwap(
                fee,
                earnedToWmaticPath,
                address(this)
            );
            
            uint256 wmaticAfter = IERC20(wmaticAddress).balanceOf(address(this)).sub(wmaticBefore);
            
            IGalaxyVaultCash(rewardAddress).depositReward(wmaticAfter);
            
            _earnedAmt = _earnedAmt.sub(fee);
        }

        return _earnedAmt;
    }

    function buyBack(uint256 _earnedAmt) internal returns (uint256) {
        if (buyBackRate > 0) {
            uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(feeMax);
    
            _safeSwap(
                buyBackAmt,
                earnedToGalaxyPath,
                burnAddress
            );

            _earnedAmt = _earnedAmt.sub(buyBackAmt);
        }
        
        return _earnedAmt;
    }
    
    function convertDustToEarned() external nonReentrant whenNotPaused {
        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        if (token0Amt > 0 && token0Address != earnedAddress) {
            // Swap all dust tokens to earned tokens
            _safeSwap(
                token0Amt,
                token0ToEarnedPath,
                address(this)
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token1Amt > 0 && token1Address != earnedAddress) {
            // Swap all dust tokens to earned tokens
            _safeSwap(
                token1Amt,
                token1ToEarnedPath,
                address(this)
            );
        }
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

        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(0));
        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );

        IERC20(token0Address).safeApprove(uniRouterAddress, uint256(0));
        IERC20(token0Address).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );

        IERC20(token1Address).safeApprove(uniRouterAddress, uint256(0));
        IERC20(token1Address).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );
        
        IERC20(usdcAddress).safeApprove(uniRouterAddress, uint256(0));
        IERC20(usdcAddress).safeIncreaseAllowance(
            rewardAddress,
            uint256(-1)
        );
        
        IERC20(usdcAddress).safeApprove(rewardAddress, uint256(0));
        IERC20(usdcAddress).safeIncreaseAllowance(
            rewardAddress,
            uint256(-1)
        );
        
        IERC20(wmaticAddress).safeApprove(rewardAddress, uint256(0));
        IERC20(wmaticAddress).safeIncreaseAllowance(
            rewardAddress,
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
    
    function setSettings(
        uint256 _controllerFee,
        uint256 _rewardRate,
        uint256 _buyBackRate,
        uint256 _withdrawFeeFactor,
        uint256 _slippageFactor,
        address _uniRouterAddress
    ) external onlyGov {
        require(_controllerFee.add(_rewardRate).add(_buyBackRate) <= feeMaxTotal, "Max fee of 10%");
        require(_withdrawFeeFactor >= withdrawFeeFactorLL, "_withdrawFeeFactor too low");
        require(_withdrawFeeFactor <= withdrawFeeFactorMax, "_withdrawFeeFactor too high");
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");
        controllerFee = _controllerFee;
        rewardRate = _rewardRate;
        buyBackRate = _buyBackRate;
        withdrawFeeFactor = _withdrawFeeFactor;
        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouterAddress;

        emit SetSettings(
            _controllerFee,
            _rewardRate,
            _buyBackRate,
            _withdrawFeeFactor,
            _slippageFactor,
            _uniRouterAddress
        );
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
    
    function _safeSwapWmatic(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(uniRouterAddress).swapExactTokensForETH(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(600)
        );
    }
}