//SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import "ERC20.sol";
import "IERC20.sol";
import "SafeMath.sol";
import "Context.sol";
import "Address.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IPancakeFactory.sol";
import "IPancakePair.sol";
import "IPancakeRouter.sol";
import "Utils.sol";
import "Holdable.sol";

contract Draconite is Context, IERC20, Ownable, Holdable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    //Tokenomics.
    string private constant _name = "Draconite";
    string private constant _symbol = "DCN";
    uint8 private constant _decimals = 15;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 public _maxTxAmount = _tTotal; 
    
    //Trace BNB claimed rewards. 
    mapping(address => uint256) public _userClaimedBNB;
    uint256 public _totalClaimedBNB = 0;
    
    //Trace reinvested token rewards.
    mapping(address => uint256) public _userReinvested;
    uint256 public _totalReinvested = 0;
    
    //Draconite wallets.
    address public _marketingAddress = 0xF123b7c24d122B2Bba509F399e611BA2A3086A8f;
    address public _charityAddress = 0x243685ae6bA5eC3F12e71d5923BeA5fA95bf53BF;
    
    address public immutable BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    
    //Tx fees in %.
    uint256 private _liquidityFee = 5;
    uint256 private _redistributionFee = 5;
    uint256 private _bnbRewardFee = 5;
    uint256 private _prizePoolFee = 2;
    uint256 private _marketingFee = 2;
    uint256 private _charityFee = 1;
    
    uint256 private _previousLiquidityFee;
    uint256 private _previousRedistributionFee;
    uint256 private _previousRewardFee;
    uint256 private _previousPricePoolFee;
    uint256 private _previousMarketingFee;
    uint256 private _previousCharityFee;
    
    //Fee for charity when account redeem reward in BNB.
    uint256 public _rewardPrizePoolFee = 10; //%
    uint256 public _rewardBNBThreshHold = 1 ether;
    
    //Indicator if a tx is a buy tx.
    bool private _buyTx = false;
    
    uint256 private unlockPrizePoolDate;
    uint256 private unlockPrizePoolCycle = 12 weeks;
    
    //Store tokens from each buy tx.
    uint256 private _tTokensFromBuyTxs;
    
    //Total reflected fee.
    uint256 private _tFeeTotal;
    
    //Total reward hard cap from the bnb pool size measured in %.
    uint256 public _rewardHardCap = 10; 
    
    //Reward availability.
    uint256 public _rewardCycleBlock = 1 weeks;
    mapping(address => uint256) public _nextAvailableClaimDate;

    uint256 public _minTokenNumberUpperLimit = _tTotal.mul(2).div(100).div(10); 
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;

    address[] private _excluded;
    
    bool private inPresale = false;
    
    //Swap bool and modifier.
    bool public _swapAndLiquifyEnabled = false; //Should be true in order to add liquidity.
    bool _inSwapAndLiquify = false;
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    //Router and pair.
    IPancakeRouter02 public _pancakeRouter;
    address public _pancakePair;
    
    //Events.
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    event SwapTokenForRewards(uint256 amount);
    event ClaimedBNBReward(address recipient, uint256 bnbReward, uint256 nextAvailableClaimDate, 
        uint256 timestamp);
    event ClaimedBNBReinvestment(address recipient, uint256 bnbReinvested, uint256 tokensReceived, 
        uint256 nextAvailableClaimDate, uint256 timestamp);
    event ExcludeAddressFromRewards(address account);
    event IncludeRewardsForAddress(address account);
    event ExcludeAddressFromFee(address account);
    event IncludeFeeForAddress(address account);
    event ChangeFeePercent(uint256 typeFee, uint256 taxFee, uint256 prevTaxFee);
    event ChangeMaxTxAmount(uint256 txAmount);
    event AddressExcludedFromMaxTxAmount(address account);
    event ChangeMarketingAddress(address account);
    event ChangeCharityAddress(address account);
    event ChangeRewardCycleBlock(uint256 rewardCycleBlock);
    event ChangeRewardHardCap(uint256 rewardHardCap);
    event PrizePoolSentToWinners(address firstwinner, address secondWinner, address thirdWinner, 
        uint256 firstPrize, uint256 secondPrize, uint256 thirdPrize, uint256 unlockPrizePoolDate);

    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _pancakePair = IPancakeFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());
        _pancakeRouter = pancakeRouter;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[_marketingAddress] = true;
        _isExcludedFromMaxTx[_charityAddress] = true;
        _isExcludedFromMaxTx[address(0)] = true;
       
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    /*
        Public functions.
    */
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function circulatingSupply() public view returns (uint256) {
        return uint256(_tTotal)
        .sub(balanceOf(address(0)));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        
        (,,,uint256 rAmount,,) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (,,,uint256 rAmount,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,,,,uint256 rTransferAmount,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function getRewardCycleBlock() public view returns (uint256) {
        return _rewardCycleBlock;
    }

    function calculateBNBReward(address ofAddress) public view returns (uint256) {
        uint256 bnbPool = address(this).balance;
        uint256 bnbReward = calculateReward(ofAddress, circulatingSupply(), bnbPool, getRewardCycleBlock());
        
        if (bnbReward > bnbPool.mul(_rewardHardCap).div(100))
            bnbReward = bnbPool.div(10);
            
        return bnbReward;
    }
    
    function redeemRewards(uint256 perc) isHuman nonReentrant public {
        uint256 timestamp = block.timestamp;
        require(_nextAvailableClaimDate[msg.sender] <= timestamp, 'Error: next available not reached');
        require(balanceOf(msg.sender) >= 0, 'Error: must own Draconite to claim reward');

        uint256 reward = calculateBNBReward(msg.sender);
        uint256 rewardBNB = reward.mul(perc).div(100);
        uint256 rewardReinvest = reward.sub(rewardBNB);
        
        uint256 expectedtoken = 0;
        
        _nextAvailableClaimDate[msg.sender] = timestamp + getRewardCycleBlock();
        
        if (rewardReinvest > 0) {
            //expectedtoken = Utils.getAmountsOut(rewardReinvest, address(_pancakeRouter)); 
            expectedtoken = balanceOf(msg.sender);
            
            Utils.swapBnbForTokens(address(_pancakeRouter), address(this), msg.sender, rewardReinvest);
            
            expectedtoken = balanceOf(msg.sender) - expectedtoken;
            
            _userReinvested[msg.sender] += expectedtoken;
            _totalReinvested = _totalReinvested + expectedtoken;
            
            emit ClaimedBNBReinvestment(msg.sender, rewardReinvest, expectedtoken, _nextAvailableClaimDate[msg.sender], timestamp);
        }
        
        if (rewardBNB > 0) { 
            //Collect 10% tax for price pool from each collected reward if more than threshhold
            if (rewardBNB > _rewardBNBThreshHold){
                uint256 rewardPricePoolFee = rewardBNB.mul(_rewardPrizePoolFee).div(100);
                
                (bool success, ) = address(_marketingAddress).call{ value: rewardPricePoolFee }("");
                require(success, " Error: Cannot send reward");
                
                rewardBNB = rewardBNB.sub(rewardPricePoolFee);
            }
            
            (bool sent,) = address(msg.sender).call{value : rewardBNB}("");
            require(sent, 'Error: Cannot withdraw reward');

            _userClaimedBNB[msg.sender] += rewardBNB;
            _totalClaimedBNB = _totalClaimedBNB.add(rewardBNB);
            
            emit ClaimedBNBReward(msg.sender, rewardBNB, _nextAvailableClaimDate[msg.sender], timestamp);
        }
        
        deleteHoldsForAddress(msg.sender);
        hold(msg.sender, balanceOf(msg.sender));
    }

    /*
        Functions that can be used by the owner of the contract.
    */
    function activateContract() public onlyOwner {
        prepareLaunch();
        
        //Protocol
        setMaxTxPercent(10000);
        setSwapAndLiquifyEnabled(true);
        unlockPrizePoolDate = block.timestamp.add(12 weeks);
        
        //Exclude Owner and Pair addresses from rewards
        excludeFromReward(address(0x652ccCdfaE41bfe346bA1C00a1CebD7b262AafF0));
        excludeFromReward(address(_pancakeRouter));
        
        //Approve contract
        _approve(address(this), address(_pancakeRouter), 2 ** 256 - 1);
    }
    
    function preparePresale() public onlyOwner {
        require (inPresale == false, "Presale is already activated!");
        
        if (_redistributionFee == 0 && _liquidityFee == 0 &&
            _prizePoolFee == 0 && _marketingFee == 0 &&
            _charityFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousRedistributionFee = _redistributionFee;
        _previousPricePoolFee = _prizePoolFee;
        _previousMarketingFee = _marketingFee;
        _previousCharityFee = _charityFee;
      
        _liquidityFee = 0;
        _redistributionFee = 0;
        _prizePoolFee = 0;
        _marketingFee = 0;
        _charityFee = 0;
        
        inPresale = true;
    }
    
    function prepareLaunch() private {
        if (inPresale == true){
            _redistributionFee = _previousRedistributionFee;
            _liquidityFee = _previousLiquidityFee;
            _prizePoolFee = _previousPricePoolFee;
            _marketingFee = _previousMarketingFee;
            _charityFee = _previousCharityFee;
        }
    }

    function changePancakeRouter(address newRouter) public onlyOwner {
        require(newRouter != address(_pancakeRouter), "Draconite: The router already has that address.");
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(newRouter);
        _pancakePair = IPancakeFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());

        _pancakeRouter = pancakeRouter;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        
        emit ExcludeAddressFromRewards(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        
        emit IncludeRewardsForAddress(account);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        
        emit ExcludeAddressFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        
        emit IncludeFeeForAddress(account);
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
        
        emit ChangeMaxTxAmount(_maxTxAmount);
    }   

    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = value;
        
        emit AddressExcludedFromMaxTxAmount(_address);
    }    

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        _swapAndLiquifyEnabled = _enabled;
        
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeMarketingAddress(address payable newAddress) public onlyOwner {
        _marketingAddress = newAddress;
        
        emit ChangeMarketingAddress(_marketingAddress);
    }
    
    function changeCharityAddress(address payable newAddress) public onlyOwner {
        _charityAddress = newAddress;
        
        emit ChangeCharityAddress(_charityAddress);
    }

    function changeRewardCycleBlock(uint256 newcycle) public onlyOwner {
        _rewardCycleBlock = newcycle;
        
        emit ChangeRewardCycleBlock(_rewardCycleBlock);
    }
    
    function migrateToken(address newAddress, uint256 amount) public onlyOwner {
        removeAllFee();
        
        _transferStandard(address(this), newAddress, amount);
        
        restoreAllFee();
    }

    function migrateBnb(address payable newAddress, uint256 amount) public onlyOwner {
        (bool success, ) = address(newAddress).call{ value: amount }("");
        require(success, "Address: unable to send value, charity may have reverted");    
    }
    
    function migrateBusd(address payable newAddress, uint256 amount) public onlyOwner {
        IERC20(BUSD).transfer(newAddress, amount);
    }

    function changeMinTokenNumberUpperLimit(uint256 newValue) public onlyOwner {
        _minTokenNumberUpperLimit = newValue;
    }
    
    function getTokensFromBuyTx() public view onlyOwner returns(uint256){
        return _tTokensFromBuyTxs;
    }
    
    function useTokensFromBuyTx() public onlyOwner {
        require(_tTokensFromBuyTxs > 0, "Not enough stashed tokens.");
        uint256 multiplier = 100;
        
        //Raw fee
        uint256 bnbRewardFee = _bnbRewardFee;
        uint256 prizePoolFee = _prizePoolFee;
        uint256 charityFee = _charityFee;
        
        //Total raw fees
        uint256 totalTxFees = bnbRewardFee.add(prizePoolFee).add(charityFee);
        
        uint256 totalTokensFromTxFees = _tTokensFromBuyTxs;
        
        uint256 percTokensForPrizePool = prizePoolFee.mul(multiplier).div(totalTxFees);
        uint256 percTokensForCharity = charityFee.mul(multiplier).div(totalTxFees);
        
        uint256 initialBalance = address(this).balance;

        Utils.swapTokensForBnb(address(_pancakeRouter), totalTokensFromTxFees);
        
        uint256 swappedBnb = address(this).balance.sub(initialBalance);
        
        //Send fees in busd to the correct addresses
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), address(this), swappedBnb.mul(percTokensForPrizePool).div(100));
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), _charityAddress, swappedBnb.mul(percTokensForCharity).div(100));
        
        _tTokensFromBuyTxs = 0;
    }
    
    function sendPrizePool(address payable firstwinner, address payable secondWinner, address payable thirdWinner) public onlyOwner {
        require(block.timestamp >= unlockPrizePoolDate);
        
        uint256 BUSDBalance = IERC20(BUSD).balanceOf(address(this));
        
        uint256 firstPrize = BUSDBalance.div(2);
        uint256 secondPrize = BUSDBalance.div(4);
        uint256 thirdPrize = BUSDBalance.div(4);
        
        IERC20(BUSD).transfer(firstwinner, firstPrize);
        IERC20(BUSD).transfer(secondWinner, secondPrize);
        IERC20(BUSD).transfer(thirdWinner, thirdPrize);
        
        unlockPrizePoolDate = block.timestamp.add(unlockPrizePoolCycle);
        
        emit PrizePoolSentToWinners(firstwinner, secondWinner, thirdWinner, firstPrize, secondPrize, thirdPrize, unlockPrizePoolDate);
    }

    /*
        Private functions for usage by the contract.
    */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeRefund(uint256 tSumFee) private {
        uint256 currentRate = _getRate();
        uint256 rSumFee = tSumFee.mul(currentRate);
        
        _rOwned[address(this)] = _rOwned[address(this)].add(rSumFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tSumFee);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }
    
    function calculateRedistributionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_redistributionFee).div(
            10 ** 2
        );
    }

    function calculateBnbRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_bnbRewardFee).div(
            10 ** 2
        );
    }

    function calculatePrizePoolFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_prizePoolFee).div(
            10 ** 2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10 ** 2
        );
    }

    function calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(
            10 ** 2
        );
    }
    
    function prepareBuyTx() private {
        if (_redistributionFee == 0 && _liquidityFee == 0 &&_marketingFee == 0) {
            return;
        }
        
        _previousLiquidityFee = _liquidityFee;
        _previousRedistributionFee = _redistributionFee;
        _previousMarketingFee = _marketingFee;
      
        _liquidityFee = 0;
        _redistributionFee = 0;
        _marketingFee = 0;
    }
    
    function afterBuyTx() private {
        _redistributionFee = _previousRedistributionFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }
    
    function removeAllFee() private {
        if (_redistributionFee == 0 && _liquidityFee == 0 &&
            _prizePoolFee == 0 && _marketingFee == 0 &&
            _charityFee == 0 && _bnbRewardFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousRedistributionFee = _redistributionFee;
        _previousPricePoolFee = _prizePoolFee;
        _previousMarketingFee = _marketingFee;
        _previousCharityFee = _charityFee;
        _previousRewardFee = _bnbRewardFee;
      
        _liquidityFee = 0;
        _redistributionFee = 0;
        _bnbRewardFee = 0;
        _prizePoolFee = 0;
        _marketingFee = 0;
        _charityFee = 0;
    }

    function restoreAllFee() private {
        _redistributionFee = _previousRedistributionFee;
        _liquidityFee = _previousLiquidityFee;
        _prizePoolFee = _previousPricePoolFee;
        _marketingFee = _previousMarketingFee;
        _charityFee = _previousCharityFee;
        _bnbRewardFee = _previousRewardFee;
    }
    
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tSumFee, _getRate());
        
        return (tTransferAmount, tFee, tSumFee, rAmount, rTransferAmount, rFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateRedistributionFee(tAmount);
        uint256 tSumFee = calculateLiquidityFee(tAmount).add(calculatePrizePoolFee(tAmount))
            .add(calculateMarketingFee(tAmount)).add(calculateCharityFee(tAmount))
            .add(calculateBnbRewardFee(tAmount));
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tSumFee);
        
        return (tTransferAmount, tFee, tSumFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tSumFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rSumFee = tSumFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rSumFee);
            
        return (rAmount, rTransferAmount, rFee);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function ensureMaxTxAmount(address from, address to, uint256 amount) private view {
        if (
            _isExcludedFromMaxTx[from] == false && 
            _isExcludedFromMaxTx[to] == false
        ) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        ensureMaxTxAmount(from, to, amount);
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool enoughUtilityTokens = contractTokenBalance >= _minTokenNumberUpperLimit;
        
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        if (from != address(_pancakePair)){
            if (
                !_inSwapAndLiquify &&
                _swapAndLiquifyEnabled &&
                enoughUtilityTokens &&
                !(from == address(this) && 
                to == address(_pancakePair)) &&
                !(from == address(this)) && 
                amount > 0
            ) {
                swapAndLiquify(calculateLiquidityFee(amount), calculateBnbRewardFee(amount),
                    calculatePrizePoolFee(amount), calculateMarketingFee(amount), calculateCharityFee(amount));
            }
            _buyTx = false;
        } else {
            _buyTx = true;
        }

        bool takeFee = true;

        //If any account belongs to _isExcludedFromFee account or reflections are disabled then remove the fee 
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        //Make the transfer
        _tokenTransfer(from, to, amount, takeFee);
    }
    
    function swapAndLiquify(uint256 tokensAmountForLiquidity, uint256 tokensAmountToBeSwappedForUserRewards,
        uint256 tokenAmountForPricePool, uint256 tokenAmountForMarketing, uint256 tokenAmountForCharity) private {

        //Add liquidity
        uint256 tokensAmountForLiquidityToBeSwapped = tokensAmountForLiquidity.div(2);
        uint256 tokensAmountToBeSwapped = tokensAmountForLiquidityToBeSwapped.add(tokensAmountToBeSwappedForUserRewards)
            .add(tokenAmountForPricePool).add(tokenAmountForMarketing).add(tokenAmountForCharity);
            
        uint256 initialBalance = address(this).balance;

        Utils.swapTokensForBnb(address(_pancakeRouter), tokensAmountToBeSwapped);
        
        uint256 swappedBnb = address(this).balance.sub(initialBalance);
        
        uint256 bnbToBeAddedToLiquidity = swappedBnb.div(5);
        
        swappedBnb = swappedBnb.sub(bnbToBeAddedToLiquidity);
        
        //Аdd liquidity to pancake
        Utils.addLiquidity(address(_pancakeRouter), tokensAmountForLiquidityToBeSwapped, bnbToBeAddedToLiquidity);
        
        emit SwapAndLiquify(
            tokensAmountForLiquidityToBeSwapped, 
            swappedBnb, 
            tokensAmountForLiquidityToBeSwapped
        );
        
        //Send fees in busd to the correct addresses
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), _marketingAddress, swappedBnb.div(5));
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), _charityAddress, swappedBnb.div(10));
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), address(this), swappedBnb.div(5));
        
        emit SwapTokenForRewards(swappedBnb);
    }
    
    //To receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        } else if (_buyTx) {
            prepareBuyTx();
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if (_nextAvailableClaimDate[recipient] == 0) {
            _nextAvailableClaimDate[recipient] = block.timestamp + getRewardCycleBlock();
        }
            
        if (!takeFee) {
            restoreAllFee();
        } else if (_buyTx) {
            afterBuyTx();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        
        //Set amount for sender and manage staked amounts.
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        //Check for excluded accounts
        withdrawHold(sender, tAmount);
        
        //Set amount for recipient and manage staked amounts.
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //Check for excluded accounts
        hold(recipient, tTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
            
        //Set amount for sender.
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        //Check for excluded accounts
        withdrawHold(sender, tAmount);
        
        //Set amount for recipient.
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        
        //Set amount for sender.
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        //Set amount for recipient.
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //Check for excluded accounts
        hold(recipient, rTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        
        //Set amount for sender.
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        //Set amount for recipient.
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }
}