// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BEP20Preset.sol";
import "./InterfaceHelper.sol";
import "./LibraryHelper.sol";
import "./Milano.sol";

contract RocketGalaxy is BEP20Preset {
    
    using SafeMath for uint256;

    ISwapV2Router02 public swapRouter;

    address public swapPair;
    address public projectWallet = 0xb417f4d37c2C487267D44268DD5e963e197B041b;
    address public burnWallet = 0xac8191aaA97fcccAe080155A15e050a7bdBC1940;

    Milano public milano;

    uint256 public maxTransactionAmount;
    uint256 public maxHoldingAmount;

    uint256 public projectFee = 4;
    uint256 public liquidityFee = 3;
    uint256 public reflectionFee = 2;
    uint256 public burnFee = 1;

    uint256 public gasForProcessing = 300000;
    uint256 public restrictionPeriod = 24 hours;

    bool public tradingEnabled = false;
    bool public swappingEnabled = true;
    bool private processingFees;

    struct Sell {
	    uint256 time;
        uint256 amount;
    }

    mapping (address => uint256) public accountLastPeriodSellVolume;
    mapping (address => Sell[]) public accountSells;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromPeriodLimit;
    mapping (address => bool) private _isExcludedFromMaxTxLimit;
    mapping (address => bool) private _isExcludedFromMaxHoldLimit;

    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    constructor () BEP20Preset("Rocket Galaxy", "RGALAXY$", 18) {
        milano = new Milano();

        updateSwapRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        //0x10ED43C718714eb63d5aA57B78B54704E256024E
        milano.excludeFromReflections(address(0));
        milano.excludeFromReflections(address(this));
        milano.excludeFromReflections(address(milano));

	    excludeFromAllLimits(owner(), true);
	    excludeFromAllLimits(address(0), true);
	    excludeFromAllLimits(address(this), true);
	    excludeFromAllLimits(address(milano), true);
	    excludeFromAllLimits(projectWallet, true);
	    excludeFromAllLimits(burnWallet, true);

        // internal function in BEP20.sol, cannot be called ever again
        _mint(owner(), 10**8 * 10**18);
        maxTransactionAmount = totalSupply().div(100);
        maxHoldingAmount = totalSupply().div(100);
    }

    function updateSwapRouter(address newAddress) public onlyOwner {
        require(newAddress != address(swapRouter), "$RGALAXY Swap Router already has that address");
        emit UpdateSwapRouter(newAddress, address(swapRouter));
        swapRouter = ISwapV2Router02(newAddress);
        address _swapPair = ISwapV2Factory(swapRouter.factory()).createPair(address(this), swapRouter.WETH());
        swapPair = _swapPair;

        milano.excludeFromReflections(address(swapRouter));
        milano.excludeFromReflections(swapPair);

        excludeFromAllLimits(newAddress, true);

        _isExcludedFromPeriodLimit[swapPair] = true;
        _isExcludedFromMaxHoldLimit[swapPair] = true;
    }

    receive() external payable { }

    function excludeFromAllLimits(address account, bool enable) public onlyOwner {
        _isExcludedFromFees[account] = enable;
        _isExcludedFromMaxTxLimit[account] = enable;
        _isExcludedFromPeriodLimit[account] = enable;
        _isExcludedFromMaxHoldLimit[account] = enable;
        canTransferBeforeTradingIsEnabled[account] = enable;
    }

    function getAccountPeriodSellVolume(address account) public returns(uint256) {
        uint256 offset;
        uint256 newVolume = accountLastPeriodSellVolume[account];

        for (uint256 i = 0; i < accountSells[account].length; i++) {
            if (block.timestamp.sub(accountSells[account][i].time) <= restrictionPeriod) {
                break;
            }
            if (newVolume > 0) {
                newVolume = newVolume.sub(accountSells[account][i].amount);
                offset++;
            }
        }

        if (offset > 0) {
            _removeAccSells(account, offset);
        }
        if (accountLastPeriodSellVolume[account] != newVolume) {
            emit UpdateAccountLastPeriodSellVolume(accountLastPeriodSellVolume[account], newVolume);
            accountLastPeriodSellVolume[account] = newVolume;
        }
        return newVolume;
    }

    function _removeAccSells(address account, uint256 offset) private {
        for (uint256 i = 0; i < accountSells[account].length-offset; i++) {
            accountSells[account][i] = accountSells[account][i+offset];
        }
        for (uint256 i = 0; i < offset; i++) {
            accountSells[account].pop();
        }
    }

    function getAccountSells(address account, uint256 i) public view returns (uint256, uint256) {
        return (accountSells[account][i].time, accountSells[account][i].amount);
    }

    function setFees(uint256 _projectFee, uint256 _liquidityFee, uint256 _reflectionFee, uint256 _burnFee) external onlyOwner {
        uint256 totalFees = _projectFee + _liquidityFee + _reflectionFee + _burnFee;
        require(totalFees <= 20, "$RGALAXY Too much fees");
        projectFee = _projectFee;
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
	    burnFee = _burnFee;
        emit SetFees(projectFee, liquidityFee, reflectionFee, burnFee);
    }

    function setWallet(address newProjectWallet) external onlyOwner {
        emit UpdateWallet(projectWallet, newProjectWallet);
        projectWallet = newProjectWallet;
    }

    function updateMilano(address newAddress) public onlyOwner {
        require(newAddress != address(milano), "$RGALAXY Milano already has that address");

        Milano newMilano = Milano(payable(newAddress));

        require(newMilano.owner() == address(this), "$RGALAXY Milano must be owned by $RGALAXY contract");

        newMilano.excludeFromReflections(address(this));
	    newMilano.excludeFromReflections(address(newMilano));
        newMilano.excludeFromReflections(address(swapRouter));

        emit UpdateMilano(newAddress, address(milano));
        milano = newMilano;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        milano.updateClaimWait(claimWait);
    }

    function updateMinimumTokenBalanceForReflections(uint256 newTokenBalance) external onlyOwner {
        milano.updateMinimumTokenBalanceForReflections(newTokenBalance);
    }

    function getClaimWait() external view returns(uint256) {
        return milano.claimWait();
    }

    function getTotalReflectionsDistributed() external view returns (uint256) {
        return milano.totalReflectionsDistributed();
    }

    function claim() external {
        milano.processAccount(payable(msg.sender), false);
    }
    
    function setSwapEnabled(bool enable) external onlyOwner {
        swappingEnabled = enable;
        emit UpdateSwappingStatus(enable);
    }

    function setTradingEnabled(bool enable) external onlyOwner {
        tradingEnabled = enable;
        emit UpdateTradingStatus(enable);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
	    if(amount <= 0){
	        return;
	    }

        if (!_isExcludedFromMaxHoldLimit[to]) {
            require(balanceOf(to).add(amount) <= maxHoldingAmount, "$RGALAXY Exceeded max holding limit!");
        }

        if (!_isExcludedFromPeriodLimit[from]) {
            require(getAccountPeriodSellVolume(from).add(amount) <= balanceOf(from).div(2), "$RGALAXY Exceeded max sell volume limit!");
        }

        if(!tradingEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "$RGALAXY This account cannot send tokens until trading is enabled");
        }

        if(!processingFees && tradingEnabled && !_isExcludedFromMaxTxLimit[from] && !_isExcludedFromMaxTxLimit[to]) {
            require(amount <= maxTransactionAmount, "$RGALAXY Transfer amount exceeds maxTransactionAmount");
        }

        if (!_isExcludedFromPeriodLimit[from]) {
            accountLastPeriodSellVolume[from] = accountLastPeriodSellVolume[from].add(amount);
            Sell memory sell;
            sell.amount = amount;
            sell.time = block.timestamp;
            accountSells[from].push(sell);
            emit AddLastPeriodSellInfo(sell.time, sell.amount);
        }

        bool takeFee = tradingEnabled && !processingFees && !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
        if(takeFee) {
            uint256 forProject = amount.mul(projectFee).div(100);
            uint256 forLiquidity = amount.mul(liquidityFee).div(100);
            uint256 forReflections = amount.mul(reflectionFee).div(100);
            uint256 forBurn = amount.mul(burnFee).div(100);
            uint256 fees = forProject.add(forLiquidity).add(forReflections).add(forBurn);
            
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
            
            if(tradingEnabled && !processingFees && swappingEnabled && msg.sender != swapPair) {
                processingFees = true;
                processFees(fees);
                processingFees = false;
            }
        }

        super._transfer(from, to, amount);

        try milano.setBalance(payable(from), balanceOf(from)) {} catch {}
        try milano.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!processingFees) {
            uint256 gas = gasForProcessing;
            try milano.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit MilanosTrip(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } catch {
                emit ErrorInProcess(msg.sender);
            }
        }
    }

    function processFees(uint256 tokens) private {
        uint256 totalFee = projectFee.add(liquidityFee).add(reflectionFee).add(burnFee);
        uint256 tokensForLiquidity = tokens.mul(reflectionFee.div(2)).div(totalFee);
        
        swapTokensForBNB(tokens.sub(tokensForLiquidity));
        
        uint256 balance = address(this).balance;
        uint256 forBNBTotal = liquidityFee.div(2).add(reflectionFee).add(projectFee);
        uint256 forProject = balance.mul(projectFee).div(forBNBTotal);
        uint256 forLiquidity = balance.mul(liquidityFee.div(2)).div(forBNBTotal);
        uint256 forReflections = balance.sub(forProject).sub(forLiquidity);

        emit CalculatedBNBForEachRecipient(forProject, forLiquidity, forReflections);

        //add to project wallet
        (bool success,) = address(projectWallet).call{value: forProject}("");
        if(success) {
            emit SwapAndSendTo(projectFee, forProject, "Project");
        }
        
        //add reflections to Milano
        (success,) = address(milano).call{value: forReflections}("");
        if(success) {
            emit SwapAndSendTo(reflectionFee, forReflections, "Reflections");
        }
        
        //add to liquidity pool
        _addLiquidity(tokensForLiquidity, forLiquidity);
        
        //add to dead wallet (burn)
        uint256 tokensForBurn = tokens.mul(burnFee).div(totalFee);
        burn(tokensForBurn);
    }
    
    function swapTokensForBNB(uint256 tokenAmount) private {
        emit StartSwapTokensForBNB(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit FinishSwapTokensForBNB(address(this).balance);
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

}