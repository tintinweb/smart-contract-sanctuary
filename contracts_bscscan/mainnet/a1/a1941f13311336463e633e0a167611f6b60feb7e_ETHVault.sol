//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SurgeDistributor.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapRouter02.sol";
import "./VaultDistributor.sol";

/** 
 * Contract: ETHVault 
 * 
 *  This Contract Awards Surge Ethereum Daily to holders, weighted by how much you hold
 *  Surge's Shakeweight Burn Wallet Gains 2% of the Distribution (contributing to asynchronous burning)
 *  This is due to the fact that we sent 2% of the supply to SurgeETH's Contract on Launch
 *  
 *  Transfer Fee:  5%
 *  Buy Fee:       5%
 *  Sell Fee:     30%
 * 
 *  Fees Go Toward:
 *  20% Surge Ethereum Distribution
 *  3% SafeVault Distribution
 *  6% Burn
 *  1% Marketing
 */
contract ETHVault is IERC20, Context, Ownable {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    
    // our vault distributor    
    VaultDistributor public vaultDistributor;

    // token data
    string constant _name = "ETHVault";
    string constant _symbol = "ETHVAULT";
    uint8 constant _decimals = 9;
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(100); // 1% or 10 Billion
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    // exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    // fees
    uint256 public burnFee = 600;
    uint256 public reflectionFee = 2300;
    uint256 public marketingFee = 100;
    uint256 public SETHAmount = 2000;
    // total fees
    uint256 totalFeeSells = 3000;
    uint256 totalFeeBuys = 500;
    uint256 feeDenominator = 10000;
    // Marketing Funds Receiver
    address public marketingFeeReceiver = 0x7b85A2623A772fb49aC6243C9c5aF39C309F83c6;
    // gas limit for purchasing SETH
    uint256 public sethGAS = 300000;
    uint256 public vaultGAS = 500000;
    uint256 public minimumToDistribute = 5 * 10**18;
    // Pancakeswap V2 Router
    IUniswapV2Router02 router;
    address public pair;
    bool public allowTransferToMarketing = true;
    // gas for distributor
    SurgeDistributor public distributor;
    uint256 distributorGas = 500000;
    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(1000); // 0.1% = 1 Billion
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 1000;
    bool inSwap;
    bool isDistributing;
    // false to stop the burn
    bool burnEnabled = true;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier distributing() { isDistributing = true; _; isDistributing = false; }
    // Uniswap Router V2
    address private _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // initialize some stuff
    constructor (
    ) {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> Vault
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // our dividend Distributor
        distributor = new SurgeDistributor(_dexRouter);
        // our vault distributor
        vaultDistributor = new VaultDistributor(_dexRouter);
        // exempt deployer and contract from fees
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        // exempt important addresses from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(distributor)] = true;
        isTxLimitExempt[address(vaultDistributor)] = true;
        isTxLimitExempt[address(this)] = true;
        // exempt this important addresses  from receiving ETH Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        // approve router of total supply
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function internalApprove(address spender, uint256 amount) internal returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        // whether transfer succeeded
        bool success;
        // if we're in swap perform a basic transfer
        if(inSwap || isDistributing){ 
            (, success) = handleTransferBody(sender, recipient, amount); 
            return success;
        }
        // amount of tokens received by recipient
        uint256 amountReceived;
        // limit gas consumption by splitting up operations
        if(shouldSwapBack()) { 
            swapBack();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else if (shouldReflectAndDistribute()) {
            reflectAndDistribute();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else {
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
            try distributor.process(distributorGas) {} catch {}
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return success;
    }
    
    /** Takes Associated Fees and sets holders' new Share for the Safemoon Distributor */
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256, bool) {
        // subtract balance from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // amount receiver should receive
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        // add amount to recipient
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // set shares for distributors
        if(!isDividendExempt[sender]){ 
            distributor.setShare(sender, _balances[sender]);
            vaultDistributor.setShare(sender, _balances[sender]);
        }
        if(!isDividendExempt[recipient]){ 
            distributor.setShare(recipient, _balances[recipient]);
            vaultDistributor.setShare(recipient, _balances[recipient]);
        }
        // return the amount received by receiver
        return (amountReceived, true);
    }

    /** False if sender is Fee Exempt, True if not */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    /** Takes Proper Fee (5% buys / transfers, 30% on sells) and stores in contract */
    function takeFee(address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        return amount.sub(feeAmount);
    }
    
    /** True if we should swap from Vault => BNB */
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    
    /**
     *  Swaps ETHVault for BNB if threshold is reached and the swap is enabled
     *  Burns 20% of ETHVault in Contract
     *  Swaps The Rest For BNB
     */
    function swapBack() private swapping {
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        // tokens allocated to burning
        uint256 burnAmount = swapThreshold.mul(burnFee).div(totalFeeSells);
        // burn tokens
        burnTokens(burnAmount);
        // how many are left to swap with
        uint256 swapAmount = swapThreshold.sub(burnAmount);
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{return;}
        
        // Tell The Blockchain
        emit SwappedBack(swapAmount, burnAmount);
    }
    
    function shouldReflectAndDistribute() private view returns(bool) {
        return msg.sender != pair
        && !isDistributing
        && swapEnabled
        && address(this).balance >= minimumToDistribute;
    }
    
    function reflectAndDistribute() private distributing {
        
        bool success; bool successTwo; bool successful;
        // allocate bnb
        uint256 amountBNBMarketing = address(this).balance.mul(marketingFee).div(totalFeeSells);
        uint256 amountBNBReflection = address(this).balance.sub(amountBNBMarketing);
        // amount for ETHSurge
        uint256 ethSurgeAMT = amountBNBReflection.mul(SETHAmount).div(reflectionFee);
        // amount for SafeVault
        uint256 safeVaultAMT = amountBNBReflection.sub(ethSurgeAMT);
        // fund distributors
        (success,) = payable(address(distributor)).call{value: ethSurgeAMT, gas: sethGAS}("");
        (successTwo,) = payable(address(vaultDistributor)).call{value: safeVaultAMT, gas: vaultGAS}("");
        // transfer to marketing
        if (allowTransferToMarketing) {
            (successful,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 26000}("");
        }
        emit FundDistributors(ethSurgeAMT, safeVaultAMT, amountBNBMarketing);
    }

    /** Removes Tokens From Circulation */
    function burnTokens(uint256 tokenAmount) private returns (bool) {
        if (!burnEnabled) {
            return false;
        }
        // update balance of contract
        _balances[address(this)] = _balances[address(this)].sub(tokenAmount, 'cannot burn this amount');
        // update Total Supply
        _totalSupply = _totalSupply.sub(tokenAmount, 'total supply cannot be negative');
        // approve PCS Router for total supply
        internalApprove(_dexRouter, _totalSupply);
        // approve initial liquidity pair for total supply
        internalApprove(address(pair), _totalSupply);
        // change Swap Threshold if we should
        if (canChangeSwapThreshold) {
            swapThreshold = _totalSupply.div(swapThresholdPercentOfCirculatingSupply);
        }
        // emit Transfer to Blockchain
        emit Transfer(address(this), address(0), tokenAmount);
        return true;
    }
   
    /** Claim Your Vault Rewards Early */
    function claimVaultDividend() external returns (bool) {
        vaultDistributor.manuallyClaimVault(msg.sender);
        return true;
    }
    
    /** Claim Your SETH Rewards Manually */
    function claimSETHDividend() external returns (bool) {
        distributor.claimSETHDividend(msg.sender);
        return true;
    }
    
    /** Claim Your Vault Rewards Early */
    function getUnpaidVaultEarnings() public view returns (uint256) {
        return vaultDistributor.getUnpaidEarnings(msg.sender);
    }
    
    /** Claim Your SETH Rewards Manually */
    function getUnpaidSETHEarnings() public view returns (uint256) {
        return distributor.getUnpaidEarnings(msg.sender);
    }

    /** Manually Depsoits To The Surge or Vault Contract */
    function manuallyDeposit(bool depositSurge) external returns (bool){
        if (depositSurge) {
            distributor.deposit();
        } else {
            vaultDistributor.deposit();
        }
        return true;
    }
    
    /** Is Holder Exempt From Fees */
    function getIsFeeExempt(address holder) public view returns (bool) {
        return isFeeExempt[holder];
    }
    
    /** Is Holder Exempt From SETH Dividends */
    function getIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }
    
    /** Is Holder Exempt From Transaction Limit */
    function getIsTxLimitExempt(address holder) public view returns (bool) {
        return isTxLimitExempt[holder];
    }
        
    /** Get Fees for Buying or Selling */
    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling){ return totalFeeSells; }
        return totalFeeBuys;
    }
    
    /** Sets Various Fees */
    function setFees(uint256 _burnFee, uint256 _sethFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _buyFee) external onlyOwner {
        burnFee = _burnFee;
        SETHAmount = _sethFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSells = _burnFee.add(_reflectionFee).add(_marketingFee);
        totalFeeBuys = _buyFee;
        require(_buyFee <= 1000);
        require(totalFeeSells < feeDenominator/2);
        require(_sethFee > 0 && _sethFee <= _reflectionFee);
    }
    
    /** Set Exemption For Holder */
    function setIsFeeAndTXLimitExempt(address holder, bool feeExempt, bool txLimitExempt) external onlyOwner {
        require(holder != address(0));
        isFeeExempt[holder] = feeExempt;
        isTxLimitExempt[holder] = txLimitExempt;
    }
    
    /** Set Holder To Be Exempt From SETH Dividends */
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt) {
            distributor.setShare(holder, 0);
            vaultDistributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
            vaultDistributor.setShare(holder, _balances[holder]);
        }
    }
    
    /** Set Settings related to Swaps */
    function setSwapBackSettings(bool _swapEnabled, uint256 _swapThreshold, bool _canChangeSwapThreshold, uint256 _percentOfCirculatingSupply, bool _burnEnabled, uint256 _minimumBNBToDistribute) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
        canChangeSwapThreshold = _canChangeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = _percentOfCirculatingSupply;
        burnEnabled = _burnEnabled;
        minimumToDistribute = _minimumBNBToDistribute;
    }

    /** Set Criteria For Surge Distributor */
    function setSURGEDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToSurgeThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToSurgeThreshold);
    }

    /** Set Criteria For Vault Distributor */
    function setVAULTDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToSafeVaultThreshold) external onlyOwner {
        vaultDistributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToSafeVaultThreshold);
    }

    /** Should We Transfer To Marketing */
    function setAllowTransferToMarketing(bool _canSendToMarketing, address _marketingFeeReceiver, uint256 _vaultGAS) external onlyOwner {
        allowTransferToMarketing = _canSendToMarketing;
        marketingFeeReceiver = _marketingFeeReceiver;
        vaultGAS = _vaultGAS;
    }
    
    /** Updates The Pancakeswap Router */
    function setDexRouter(address nRouter) external onlyOwner{
        require(nRouter != _dexRouter);
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
        address _uniswapV2Pair = IUniswapV2Factory(router.factory())
            .createPair(address(this), router.WETH());
        pair = _uniswapV2Pair;
        vaultDistributor.updatePancakeRouterAddress(nRouter);
        distributor.updatePancakeRouterAddress(nRouter);
    }

    /** Set Address For Surge Distributor */
    function setSurgeDistributor(address payable surgeDispo) external onlyOwner {
        require(surgeDispo != address(distributor), 'Distributor already has this address');
        distributor = SurgeDistributor(surgeDispo);
        emit SwappedDistributor(true, surgeDispo);
    }

    /** Set Address For Vault Distributor */
    function setVaultDistributor(address payable vaultDispo) external onlyOwner {
        require(vaultDispo != address(vaultDistributor));
        vaultDistributor = VaultDistributor(vaultDispo);
        emit SwappedDistributor(false, vaultDispo);
    }

    /** Sets the amount of gas needed to purchase SETH */
    function setSETHGAS(uint256 _transferToSethGas, uint256 _sethGasLimit, uint256 _distributorGas) external onlyOwner {
        sethGAS = _transferToSethGas;
        distributor.setSETHGAS(_sethGasLimit);
        distributorGas = _distributorGas;
        require(_distributorGas < 1800000 && _transferToSethGas < 1800000 && _transferToSethGas >= _sethGasLimit);
    }
    
    /** Swaps SETH and SafeVault Addresses in case of migration */
    function setTokenAddresses(address nSETH, address nSafeVault) external onlyOwner {
        distributor.setSETHAddress(nSETH);
        vaultDistributor.setSafeVaultAddress(nSafeVault);
        emit SwappedTokenAddresses(nSETH, nSafeVault);
    }
    
    /** Deletes the entire bag from sender */
    function deleteBag(uint256 nTokens) external returns(bool){
        // make sure you are burning enough tokens
        require(nTokens > 0);
        // if the balance is greater than zero
        require(_balances[msg.sender] >= nTokens, 'user does not own enough tokens');
        // remove tokens from sender
        _balances[msg.sender] = _balances[msg.sender].sub(nTokens, 'cannot have negative tokens');
        // remove tokens from total supply
        _totalSupply = _totalSupply.sub(nTokens, 'total supply cannot be negative');
        // approve PCS Router for the new total supply
        internalApprove(_dexRouter, _totalSupply);
        // approve initial liquidity pair for total supply
        internalApprove(address(pair), _totalSupply);
        // tell blockchain
        emit Transfer(msg.sender, address(0), nTokens);
        return true;
    }

    // Events
    event SwappedDistributor(bool surgeDistributor, address newDistributor);
    event VaultBuyBackAndBurn(uint256 amountBNB);
    event SwappedBack(uint256 tokensSwapped, uint256 amountBurned);
    event SwappedTokenAddresses(address newSETH, address newSafeVault);
    event FundDistributors(uint256 ethAmount, uint256 vaultAmount, uint256 marketingAmount);
}