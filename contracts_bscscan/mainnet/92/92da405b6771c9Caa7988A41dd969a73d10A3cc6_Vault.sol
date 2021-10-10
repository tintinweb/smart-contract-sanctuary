//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IDistributor.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrantGuard.sol";

/** 
 * Contract: Vault
 * Author: DeFi Mark (Markymark)
 * 
 *  This Contract Awards Surge Tokens to holders
 *  weighed by how much Vault is held. 
 *  If A User Holds Over 0.01% of Supply They Can Specify
 *  Their Preferred Reward Token
 * 
 *  Transfer Fee:  5%
 *  Buy Fee:       5%
 *  Sell Fee:     30%
 * 
 *  Buys/Transfers Directly Deletes Tokens From Fees
 * 
 *  Sell Fees Go Toward:
 *  83% SurgeBTC Distribution
 *  9% SafeVault+ETHVault Buy+Burn
 *  4% Burn
 *  4% Marketing
 */
contract Vault is IERC20, ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    // token data
    string constant _name = "Vault";
    string constant _symbol = "VAULT";
    uint8 constant _decimals = 9;
    
    // 1 Trillion Max Supply
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(100); // 1% or 10 Billion
    
    // balances
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    // Token Lock Structure
    struct TokenLock {
        bool isLocked;
        uint256 startTime;
        uint256 duration;
        uint256 nTokens;
    }
    
    // permissions
    struct Permissions {
        bool isFeeExempt;
        bool isTxLimitExempt;
        bool isDividendExempt;
        bool isLiquidityPool;
    }
    // user -> permissions
    mapping (address => Permissions) permissions;
    
    // Token Lockers
    mapping (address => TokenLock) tokenLockers;
    
    // fees
    uint256 public burnFee = 125;
    uint256 public reflectionFee = 2750;
    uint256 public marketingFee = 125;
    // total fees
    uint256 totalFeeSells = 3000;
    uint256 totalFeeBuys = 500;
    uint256 totalFeeTransfers = 500;
    uint256 constant feeDenominator = 10000;
    
    // Marketing Funds Receiver
    address public marketingFeeReceiver = 0xC618FDbDd2254f37a44882bD53fD7FB91163A9A7;
    // CA which buys/burns ETHVault+SafeVault
    address public burner = 0x7b09C924c31437725ABcA4261849e60AC52b8E91;
    
    // Pancakeswap V2 Router
    IUniswapV2Router02 router;
    address private pair;

    // gas for distributor
    IDistributor public distributor;
    uint256 distributorGas = 1000000;
    
    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(2000); // 800,000,000 tokens
    
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 2000;
    bool inSwap;

    // false to stop the burn
    bool public burnEnabled = true;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    // Uniswap Router V2
    address private _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // ownership
    address public _owner;
    modifier onlyOwner(){require(msg.sender == _owner, 'OnlyOwner'); _;}
    
    // Token -> BNB
    address[] path;
    // BNB -> Token
    address[] buyPath;
    
    // swapper info
    bool swapperEnabled;
    bool public _manualSwapperDisabled;

    // initialize some stuff
    constructor ( address payable _distributor
    ) {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> Vault
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // our dividend Distributor
        distributor = IDistributor(_distributor);
        // exempt deployer and contract from fees
        permissions[msg.sender].isFeeExempt = true;
        permissions[address(this)].isFeeExempt = true;
        // exempt important addresses from TX limit
        permissions[msg.sender].isTxLimitExempt = true;
        permissions[marketingFeeReceiver].isTxLimitExempt = true;
        permissions[address(this)].isTxLimitExempt = true;
        // exempt important addresses from receiving Rewards
        permissions[pair].isDividendExempt = true;
        permissions[address(router)].isDividendExempt = true;
        permissions[address(this)].isDividendExempt = true;
        // declare LP as Liquidity Pool
        permissions[pair].isLiquidityPool = true;
        permissions[address(router)].isLiquidityPool = true;
        swapperEnabled = true;
        // approve router of total supply
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        // token path
        path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = address(this);
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {
        if (msg.sender == address(this) || msg.sender == address(router) || _manualSwapperDisabled) return;
        if (swapperEnabled) {
            try router.swapExactETHForTokens{value: msg.value}(
                0,
                buyPath,
                msg.sender,
                block.timestamp.add(30)
            ) {} catch {revert('Failure On Token Purchase');}
        }
    }

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
    
    /** Approves Router and Pair For Updating Total Supply */
    function internalApprove() private {
        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
        // update thresholds
        if (canChangeSwapThreshold) {
            swapThreshold = _totalSupply.div(swapThresholdPercentOfCirculatingSupply);
            _maxTxAmount = _totalSupply.div(100);
        }
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
    
    ////////////////////////////////////
    /////    INTERNAL FUNCTIONS    /////
    ////////////////////////////////////
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: Invalid Transfer");
        require(amount > 0, "Zero Amount");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || permissions[sender].isTxLimitExempt, "TX Limit");
        // For Time-Locking Developer Tokens
        if (tokenLockers[sender].isLocked) {
            if (tokenLockers[sender].startTime + tokenLockers[sender].duration > block.number) {
                tokenLockers[sender].nTokens = tokenLockers[sender].nTokens.sub(amount, 'Exceeds Token Lock Allowance');
            } else {
                delete tokenLockers[sender];
            }
        }
        // whether transfer succeeded
        bool success;
        // amount of tokens received by recipient
        uint256 amountReceived;
        // if we're in swap perform a basic transfer
        if(inSwap){
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
            emit Transfer(sender, recipient, amountReceived);
            return success;
        }
        
        // limit gas consumption by splitting up operations
        if(shouldSwapBack()) {
            swapBack();
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
        } else {
            (amountReceived, success) = handleTransferBody(sender, recipient, amount);
            try distributor.process(distributorGas) {} catch {}
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return success;
    }
    
    /** Takes Associated Fees and sets holders' new Share for the Vault Distributor */
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256, bool) {
        // subtract balance from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        // amount receiver should receive
        uint256 amountReceived = (permissions[sender].isFeeExempt || permissions[recipient].isFeeExempt) ? amount : takeFee(sender, recipient, amount);
        // add amount to recipient
        _balances[recipient] = _balances[recipient].add(amountReceived);
        // set shares for distributors
        if(!permissions[sender].isDividendExempt){ 
            distributor.setShare(sender, _balances[sender]);
        }
        if(!permissions[recipient].isDividendExempt){ 
            distributor.setShare(recipient, _balances[recipient]);
        }
        // return the amount received by receiver
        return (amountReceived, true);
    }
    
    /** Takes Fee and Stores in contract Or Deletes From Circulation */
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 tFee = permissions[receiver].isLiquidityPool ? totalFeeSells : permissions[sender].isLiquidityPool ? totalFeeBuys : totalFeeTransfers;
        uint256 feeAmount = amount.mul(tFee).div(feeDenominator);
        if (permissions[receiver].isLiquidityPool || !burnEnabled) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            // fee event
            emit Transfer(sender, address(this), feeAmount);
        } else {
            // update Total Supply
            _totalSupply = _totalSupply.sub(feeAmount);
            // approve Router for total supply
            internalApprove();
            // fee event
            emit Transfer(sender, address(0), feeAmount);
        }
        return amount.sub(feeAmount);
    }
    
    /** True if we should swap from Vault => BNB */
    function shouldSwapBack() internal view returns (bool) {
        return !permissions[msg.sender].isLiquidityPool
        && !inSwap
        && swapEnabled
        && _balances[address(this)] > swapThreshold;
    }
    
    /**
     *  Swaps Vault for BNB if threshold is reached and the swap is enabled
     *  Burns percent of Vault in Contract, delivers percent to marketing
     *  Swaps The Rest For BNB
     */
    function swapBack() private swapping {
        // tokens allocated to burning
        uint256 burnAmount = swapThreshold.mul(burnFee).div(totalFeeSells);
        // burn tokens
        burnTokens(burnAmount);
        // tokens allocated to marketing
        uint256 marketingTokens = swapThreshold.mul(marketingFee).div(totalFeeSells);
        // send tokens to marketing wallet
        if (marketingTokens > 0) {
            _balances[address(this)] = _balances[address(this)].sub(marketingTokens);
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(marketingTokens);
            if (!permissions[marketingFeeReceiver].isDividendExempt) {
                distributor.setShare(marketingFeeReceiver, _balances[marketingFeeReceiver]);
            }
            emit Transfer(address(this), marketingFeeReceiver, marketingTokens);
        }
        // disable receive
        swapperEnabled = false;
        // how many are left to swap with
        uint256 swapAmount = swapThreshold.sub(burnAmount).sub(marketingTokens);
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp.add(30)
        ) {} catch{return;}
        
        // enable receive
        swapperEnabled = true;
        // fuel distributor
        fuelDistributorAndBurner();
        // Tell The Blockchain
        emit SwappedBack(swapAmount, burnAmount, marketingTokens);
    }

    /** Removes Tokens From Circulation */
    function burnTokens(uint256 tokenAmount) private returns (bool) {
        if (!burnEnabled || tokenAmount == 0) {
            return false;
        }
        // update balance of contract
        _balances[address(this)] = _balances[address(this)].sub(tokenAmount);
        // update Total Supply
        _totalSupply = _totalSupply.sub(tokenAmount);
        // approve Router for total supply
        internalApprove();
        // emit Transfer to Blockchain
        emit Transfer(address(this), address(0), tokenAmount);
        return true;
    }
    
    /** Deposits BNB To Distributor And Burner*/
    function fuelDistributorAndBurner() private returns (bool) {
        // allocate percentage to buy/burn ETHVault+SafeVault
        uint256 forBurning = address(this).balance.div(10);
        uint256 forDistribution = address(this).balance.sub(forBurning);
        bool succ; bool succTwo;
        // send bnb to distributor
        (succ,) = payable(address(distributor)).call{value: forDistribution}("");
        (succTwo,) = payable(address(burner)).call{value: forBurning}("");
        emit FueledContracts(forBurning, forDistribution);
        return succ && succTwo;
    }
    
    ////////////////////////////////////
    /////    EXTERNAL FUNCTIONS    /////
    ////////////////////////////////////
    
    
    /** Deletes the portion of holdings from sender */
    function deleteBag(uint256 nTokens) external nonReentrant returns(bool){
        // make sure you are burning enough tokens
        require(nTokens > 0 && _balances[msg.sender] >= nTokens, 'Insufficient Balance');
        // remove tokens from sender
        _balances[msg.sender] = _balances[msg.sender].sub(nTokens);
        // remove tokens from total supply
        _totalSupply = _totalSupply.sub(nTokens);
        // set share to be new balance
        if (!permissions[msg.sender].isDividendExempt) {
            distributor.setShare(msg.sender, _balances[msg.sender]);
        }
        // approve Router for the new total supply
        internalApprove();
        // tell blockchain
        emit Transfer(msg.sender, address(0), nTokens);
        return true;
    }
    
    
    
    ////////////////////////////////////
    /////      READ FUNCTIONS      /////
    ////////////////////////////////////
    
    
    
    /** Is Holder Exempt From Fees */
    function getIsFeeExempt(address holder) public view returns (bool) {
        return permissions[holder].isFeeExempt;
    }
    
    /** Is Holder Exempt From Dividends */
    function getIsDividendExempt(address holder) public view returns (bool) {
        return permissions[holder].isDividendExempt;
    }
    
    /** Is Holder Exempt From Transaction Limit */
    function getIsTxLimitExempt(address holder) public view returns (bool) {
        return permissions[holder].isTxLimitExempt;
    }
    
    /** True If Tokens Are Locked For Target, False If Unlocked */
    function isTokenLocked(address target) external view returns (bool) {
        return tokenLockers[target].isLocked;
    }

    /** Time In Blocks Until Tokens Unlock For Target User */    
    function timeLeftUntilTokensUnlock(address target) public view returns (uint256) {
        if (tokenLockers[target].isLocked) {
            uint256 endTime = tokenLockers[target].startTime.add(tokenLockers[target].duration);
            if (endTime <= block.number) return 0;
            return endTime.sub(block.number);
        } else {
            return 0;
        }
    }
    
    /** Number Of Tokens A Locked Wallet Has Left To Spend Before Time Expires */
    function nTokensLeftToSpendForLockedWallet(address wallet) external view returns (uint256) {
        return tokenLockers[wallet].nTokens;
    }
    
    
    ////////////////////////////////////
    /////     OWNER FUNCTIONS      /////
    ////////////////////////////////////
    

    /** Sets Various Fees */
    function setFees(uint256 _burnFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _buyFee, uint256 _transferFee) external onlyOwner {
        burnFee = _burnFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSells = _burnFee.add(_reflectionFee).add(_marketingFee);
        totalFeeBuys = _buyFee;
        totalFeeTransfers = _transferFee;
        require(_buyFee <= feeDenominator/2);
        require(totalFeeSells <= feeDenominator/2);
        require(_transferFee <= feeDenominator/2);
        emit UpdateFees(_buyFee, totalFeeSells, _transferFee, _burnFee, _reflectionFee);
    }
    
    /** Set Exemption For Holder */
    function setExemptions(address holder, bool feeExempt, bool txLimitExempt, bool _isLiquidityPool) external onlyOwner {
        require(holder != address(0));
        permissions[holder].isFeeExempt = feeExempt;
        permissions[holder].isTxLimitExempt = txLimitExempt;
        permissions[holder].isLiquidityPool = _isLiquidityPool;
        emit SetExemptions(holder, feeExempt, txLimitExempt, _isLiquidityPool);
    }
    
    /** Set Holder To Be Exempt From Dividends */
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        permissions[holder].isDividendExempt = exempt;
        if(exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    /** Set Settings related to Swaps */
    function setSwapBackSettings(bool _swapEnabled, uint256 _swapThreshold, bool _canChangeSwapThreshold, uint256 _percentOfCirculatingSupply, bool _burnEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapThreshold = _swapThreshold;
        canChangeSwapThreshold = _canChangeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = _percentOfCirculatingSupply;
        burnEnabled = _burnEnabled;
        emit UpdateSwapBackSettings(_swapEnabled, _swapThreshold, _canChangeSwapThreshold, _burnEnabled);
    }

    /** Should We Transfer To Marketing */
    function setMarketingFundReceiver(address _marketingFeeReceiver) external onlyOwner {
        require(_marketingFeeReceiver != address(0), 'Invalid Address');
        permissions[marketingFeeReceiver].isTxLimitExempt = false;
        marketingFeeReceiver = _marketingFeeReceiver;
        permissions[_marketingFeeReceiver].isTxLimitExempt = true;
        emit UpdateTransferToMarketing(_marketingFeeReceiver);
    }
    
    /** Updates Burner Contract */
    function setVaultBurnerContract(address newVaultBurner) external onlyOwner {
        burner = newVaultBurner;
        emit UpdateVaultBurner(newVaultBurner);
    }
    
    /** Disables or Enables the swapping mechanism inside of BTCVault */
    function setManualSwapperDisabled(bool manualSwapperDisabled) external onlyOwner {
        _manualSwapperDisabled = manualSwapperDisabled;
        emit UpdatedManualSwapperDisabled(manualSwapperDisabled);
    }
    
    /** Updates Gas Required For Redistribution */
    function setDistributorGas(uint256 newGas) external onlyOwner {
        require(newGas >= 10**5 && newGas <= 10**7, 'Out Of Range');
        distributorGas = newGas;
        emit UpdatedDistributorGas(newGas);
    }
    
    /** Updates The Pancakeswap Router */
    function setDexRouter(address nRouter) external onlyOwner{
        require(nRouter != _dexRouter && nRouter != address(0), 'Invalid Address');
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
        address _newPair = IUniswapV2Factory(router.factory())
            .createPair(address(this), router.WETH());
        pair = _newPair;
        permissions[_newPair].isLiquidityPool = true;
        permissions[_newPair].isDividendExempt = true;
        path[1] = router.WETH();
        internalApprove();
        emit UpdatePancakeswapRouter(nRouter);
    }

    /** Set Address For Surge Distributor */
    function setDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != address(distributor) && newDistributor != address(0), 'Invalid Address');
        distributor = IDistributor(payable(newDistributor));
        emit SwappedDistributor(newDistributor);
    }

    /** Lock Tokens For A User Over A Set Amount of Time */
    function lockTokens(address target, uint256 lockDurationInBlocks, uint256 tokenAllowance) external onlyOwner {
        require(lockDurationInBlocks <= 10512000, 'Invalid Duration');
        require(timeLeftUntilTokensUnlock(target) <= 100, 'Not Time');
        tokenLockers[target] = TokenLock({
            isLocked:true,
            startTime:block.number,
            duration:lockDurationInBlocks,
            nTokens:tokenAllowance
        });
        emit TokensLockedForWallet(target, lockDurationInBlocks, tokenAllowance);
    }
    
    /** Transfers Ownership of Vault Contract */
    function transferOwnership(address newOwner) external onlyOwner {
        require(_owner != newOwner);
        _owner = newOwner;
        emit TransferOwnership(newOwner);
    }

    
    ////////////////////////////////////
    //////        EVENTS          //////
    ////////////////////////////////////
    
    
    event TransferOwnership(address newOwner);
    event UpdatedDistributorGas(uint256 newGas);
    event SwappedDistributor(address newDistributor);
    event UpdateVaultBurner(address newVaultBurner);
    event UpdatedManualSwapperDisabled(bool disabled);
    event FueledContracts(uint256 bnbForBurning, uint256 bnbForReflections);
    event SetExemptions(address holder, bool feeExempt, bool txLimitExempt, bool isLiquidityPool);
    event SwappedBack(uint256 tokensSwapped, uint256 amountBurned, uint256 marketingTokens);
    event UpdateTransferToMarketing(address fundReceiver);
    event UpdateSwapBackSettings(bool swapEnabled, uint256 swapThreshold, bool canChangeSwapThreshold, bool burnEnabled);
    event UpdatePancakeswapRouter(address newRouter);
    event TokensLockedForWallet(address wallet, uint256 duration, uint256 allowanceToSpend);
    event UpdateFees(uint256 buyFee, uint256 sellFee, uint256 transferFee, uint256 burnFee, uint256 reflectionFee);
    
}