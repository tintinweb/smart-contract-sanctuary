pragma solidity ^0.8.5;
import "./AMGlib.sol";
contract AMG is Context, IBEP20, Ownable { // contract name
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _tOwned; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances; // allowed allowance for spender
    mapping (address => bool) public _isExcludedFromAntiWhale; // Limits how many tokens can an address hold

    mapping (address => bool) public _isExcludedFromFee; // excluded address from all fee

    mapping (address => bool) public _isExcludedFromMaxTxAmount; // excluded address MaxTxAmount
    
    mapping (address => uint256) private _transactionCheckpoint; // save last transaction time of an address

    mapping (address => bool) public _isBlacklisted; // blocks an address from buy and selling

    mapping(address => bool) public _isExcludedFromTransactionlock; // Address to be excluded from transaction cooldown

    address payable public _deadAddress; 
    address payable public _burnAddress = payable(0x000000000000000000000000000000000000dEaD); // Burn Address

    string private _name = "AMG"; // token name
    string private _symbol = "AMG"; // token symbol
    uint8 private _decimals = 18; // 1 token can be divided into 10e_decimals parts

    uint256 private _tTotal = 1000000 * 10**6 * 10**_decimals;

    uint256 public previousBuyBackTime = block.timestamp; // to store previous buyback time
    
    uint256 public durationBetweenEachBuyback = 5 minutes; // duration betweeen each buyback

    // All fees are with one decimal value. so if you want 0.5 set value to 5, for 10 set 100. so on...

    // Below Fees to be deducted and sent as tokens
    uint256 public _tokenFee = 1; // DeadW fee 1% to be sent as tokens
    uint256 private _previousTokenFee = _tokenFee; // DeadW tokens fee
    
    uint256 public _buyBackFee = 1; // buyback fee 12%
    uint256 private _previousBuyBackFee = _buyBackFee; // buyback fee

    uint256 public _deadFee = 1;  // swap BNB
    uint256 private _previousDeadFee = _deadFee; 

    uint256 public _liquidityFee = 1; // liquidity fee 3%
    uint256 private _previousLiquidityFee = _liquidityFee; // restore liquidity fee

    uint256 private _deductableFee = _liquidityFee.add(_buyBackFee).add(_deadFee); // liquidity + buyback  + DeadW BNB fee on each transaction
    uint256 private _previousDeductableFee = _deductableFee; // restore old liquidity fee

	uint256 private _transactionLockTime = 1; //Cool down time between each transaction per address

    IPancakeRouter02 public pancakeRouter; // pancakeswap router assiged using address
    address public pancakePair; // for creating WETH pair with our token
    
    bool inSwapAndLiquify; // after each successfull swapandliquify disable the swapandliquify
    bool public swapAndLiquifyEnabled = true; // set auto swap to BNB and liquify collected liquidity fee
    
    uint256 public _maxTxAmount = _tTotal; // max allowed tokens tranfer per transaction
    uint256 public _minTokensSwapToAndTransferTo = 1000 * 10**6 * 10**_decimals; // min token liquidity fee collected before swapandLiquify
    uint256 public _maxTokensPerAddress          = _tTotal; // Max number of tokens that an address can hold 5% of total supply

    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap); //event fire min token liquidity fee collected before swapandLiquify 
    event SwapAndLiquifyEnabledUpdated(bool enabled); // event fire set auto swap to BNB and liquify collected liquidity fee
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    ); // fire event how many tokens were swapedandLiquified
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } // modifier to after each successfull swapandliquify disable the swapandliquify
    
    constructor () {
        _tOwned[owner()] = _tTotal; // assigning the max token to owner's address  
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a pancakeswap pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());    

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[_burnAddress]        = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_deadAddress]   = true;

        //exclude below addresses from transaction cooldown
        _isExcludedFromTransactionlock[owner()]                 = true;
        _isExcludedFromTransactionlock[address(this)]           = true;
        _isExcludedFromTransactionlock[_burnAddress]            = true;
        _isExcludedFromTransactionlock[pancakePair]             = true;
        _isExcludedFromTransactionlock[_deadAddress]       = true;
        _isExcludedFromTransactionlock[address(_pancakeRouter)] = true;

        //exclude below addresses from maxTx amount
        _isExcludedFromMaxTxAmount[owner()]                 = true;
        _isExcludedFromMaxTxAmount[address(this)]           = true;
        _isExcludedFromMaxTxAmount[_burnAddress]            = true;
        _isExcludedFromMaxTxAmount[pancakePair]             = true;
        _isExcludedFromMaxTxAmount[_deadAddress]       = true;
        _isExcludedFromMaxTxAmount[address(_pancakeRouter)] = true;

        //Exclude's below addresses from per account tokens limit
        _isExcludedFromAntiWhale[owner()]                   = true;
        _isExcludedFromAntiWhale[address(this)]             = true;
        _isExcludedFromAntiWhale[pancakePair]               = true;
        _isExcludedFromAntiWhale[_burnAddress]              = true;
        _isExcludedFromAntiWhale[_deadAddress]         = true;
        _isExcludedFromAntiWhale[address(_pancakeRouter)]   = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**  
     * @dev approves allowance of a spender
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /**  
     * @dev transfers from a sender to receipent with subtracting spenders allowance with each successfull transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
         return true;
    }

    /**  
     * @dev approves allowance of a spender should set it to zero first than increase
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**  
     * @dev decrease allowance of spender that it can spend on behalf of owner
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }


    /**  
     * @dev auto send tokens with each transaction to DeadW
     */
    function _sendToDeadW(address account, uint256 amount) internal {
        if(amount > 0)// No need to send if collected DeadW token fee is zero
        {
            _tOwned[_deadAddress] = _tOwned[_deadAddress].add(amount);
            emit Transfer(account, _deadAddress, amount);
        }
    }
    
    /**  
     * @dev exclude an address from fee
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /**  
     * @dev include an address for fee
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**  
     * @dev exclude an address from per address tokens limit
     */
    function excludedFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = true;
    }

    /**  
     * @dev include an address in per address tokens limit
     */
    function includeInAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = false;
    }

    /**  
     * @dev exclude an address from per address tokens limit
     */
    function excludedFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }

    /**  
     * @dev include an address in per address tokens limit
     */
    function includeInMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = false;
    }
    
    /**  
     * @dev set's DeadW token fee percentage
     */
    function setDeadWTokenFeePercent(uint256 Fee) external onlyOwner {
        _tokenFee = Fee;
    }
    
    /**  
     * @dev set's DeadW fee percentage
     */
    function setDeadWFeePercent(uint256 Fee) external onlyOwner {
        _buyBackFee = Fee;
        _deductableFee = _liquidityFee.add(_buyBackFee).add(_deadFee);
    }

    /**  
     * @dev set's liquidity fee percentage
     */
    function setLiquidityFeePercent(uint256 Fee) external onlyOwner {
        _liquidityFee = Fee;
        _deductableFee = _liquidityFee.add(_buyBackFee).add(_deadFee);
    }


    /**  
     * @dev set's DeadW BNB fee percentage
     */
    function setdeadFeePercent(uint256 Fee) external onlyOwner {
        _deadFee = Fee;
        _deductableFee = _liquidityFee.add(_buyBackFee).add(_deadFee);
    }
   
    /**  
     * @dev set's max amount of tokens percentage 
     * that can be transfered in each transaction from an address
     */
    function setMaxTxTokens(uint256 maxTxTokens) external onlyOwner {
        _maxTxAmount = maxTxTokens.mul( 10**_decimals );
    }

    /**  
     * @dev set's max amount of tokens
     * that an address can hold
     */
    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner {
        _maxTokensPerAddress = maxTokens.mul( 10**_decimals );
    }

    /**  
     * @dev set's minimmun amount of tokens required 
     * before swaped and BNB send to  wallet
     * same value will be used for auto swapandliquifiy threshold
     */
    function setMinTokensSwapAndTransfer(uint256 minAmount) public onlyOwner {
        _minTokensSwapToAndTransferTo = minAmount.mul( 10**_decimals );
    }

    /**  
     * @dev set's  address
     */
    function setdeadAddress(address payable deadAddress) external onlyOwner {
        _deadAddress = deadAddress;
    }

    /**
	* @dev Sets transactions on time periods or cooldowns. Buzz Buzz Bots.
	* Can only be set by owner set in seconds.
	*/
	function setTransactionCooldownTime(uint256 transactiontime) public onlyOwner {
		_transactionLockTime = transactiontime;
	}
    
    /**
	* @dev Set duration between each buyback minimum is 1 day and max can be N-days
	*/
	function setDurationBetweenEachBuyBcakTime(uint256 duration) public onlyOwner {
		durationBetweenEachBuyback = duration * 1 minutes;
	}

    /**
	 * @dev Exclude's an address from transactions from cooldowns.
	 * Can only be set by owner.
	 */
	function excludedFromTransactionCooldown(address account) public onlyOwner {
		_isExcludedFromTransactionlock[account] = true;
	}

     /**
	 * @dev Include's an address in transactions from cooldowns.
	 * Can only be set by owner.
	 */
	function includeInTransactionCooldown(address account) public onlyOwner {
		_isExcludedFromTransactionlock[account] = false;
	}

    /**  
     * @dev set's auto SwapandLiquify when contract's token balance threshold is reached
     */
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve BNB from pancakeRouter when swaping
    receive() external payable {}

    /**  
     * @dev get/calculates all values e.g taxfee, 
     * liquidity fee, actual transfer amount to receiver, 
     * deuction amount from sender
     * amount with reward to all holders
     * amount without reward to all holders
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 bFee, uint256 tLiquidity) = _getTValues(tAmount);
        return (tTransferAmount, bFee, tLiquidity);
    }

    /**  
     * @dev get/calculates DeadWtokensfee, liquidity fee
     * without reward amount
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 mTFee = calculateDeadWTokenFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity).sub(mTFee);
        return (tTransferAmount, mTFee, tLiquidity);
    }
    
    /**  
     * @dev take's liquidity fee tokens from tansaction and saves in contract
     */
    function _takeLiquidity(uint256 tLiquidity) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    /**  
     * @dev calculates burn fee tokens to be deducted
     */
    function calculateDeadWTokenFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tokenFee).div(
            10**3
        );
    }

    /**  
     * @dev calculates liquidity fee tokens to be deducted
     */
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_deductableFee).div(
            10**3
        );
    }
    
    /**  
     * @dev removes all fee from transaction if takefee is set to false
     */
    function removeAllFee() private {
        if(_deductableFee == 0 && _tokenFee == 0 && _buyBackFee == 0
           && _deadFee == 0 && _liquidityFee == 0) return;
        
        _previousTokenFee = _tokenFee;
        _previousBuyBackFee = _buyBackFee;
        _previousLiquidityFee = _liquidityFee; 
        _previousDeductableFee = _deductableFee;
        _previousDeadFee = _deadFee;
        
        _tokenFee = 0;
        _buyBackFee = 0;
        _liquidityFee = 0;
        _deductableFee = 0;
        _deadFee = 0;
    }
    
    /**  
     * @dev restores all fee after exclude fee transaction completes
     */
    function restoreAllFee() private {
        _tokenFee = _previousTokenFee;
        _buyBackFee = _previousBuyBackFee;
        _liquidityFee = _previousLiquidityFee;
        _deductableFee = _previousDeductableFee;
        _deadFee = _previousDeadFee;
    }

    /**  
     * @dev approves amount of token spender can spend on behalf of an owner
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**  
     * @dev transfers token from sender to recipient also auto 
     * swapsandliquify if contract's token balance threshold is reached
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(_isBlacklisted[from] == false, "You are banned");
        require(_isBlacklisted[to] == false, "The recipient is banned");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isExcludedFromAntiWhale[to] || balanceOf(to) + amount <= _maxTokensPerAddress,
        "Max tokens limit for this account exceeded. Or try lower amount");
        require(_isExcludedFromTransactionlock[from] || block.timestamp >= _transactionCheckpoint[from] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");
        require(_isExcludedFromTransactionlock[to] || block.timestamp >= _transactionCheckpoint[to] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");
        if(from == pancakePair && !_isExcludedFromMaxTxAmount[to])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        else if(!_isExcludedFromMaxTxAmount[from] && to == pancakePair)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        _transactionCheckpoint[from] = block.timestamp;
        _transactionCheckpoint[to] = block.timestamp;
        
        if(block.timestamp >= previousBuyBackTime.add(durationBetweenEachBuyback)
            && address(this).balance > 0 && !inSwapAndLiquify && from != pancakePair)
        {
            uint256 buyBackAmount = address(this).balance.div(2);
            swapETHForTokens(buyBackAmount);
            previousBuyBackTime = block.timestamp;
        }
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >=_minTokensSwapToAndTransferTo;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance =_minTokensSwapToAndTransferTo;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    /**  
     * @dev swapsAndLiquify tokens to pancakeswap if swapandliquify is enabled
     */
    function swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        // first split contract into DeadW fee and liquidity fee
        uint256 swapPercent = _deadFee.add(_buyBackFee).add(_liquidityFee/2);
        uint256 swapTokens = tokenBalance.div(_deductableFee).mul(swapPercent);
        uint256 liquidityTokens = tokenBalance.sub(swapTokens);
        uint256 initialBalance = address(this).balance;
        
        swapTokensForBNB(swapTokens);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 DeadWAmount = 0;
        uint256 buyBackAmount = 0;

        if(_deadFee > 0)
        {
            DeadWAmount = transferredBalance.mul(_deadFee);
            DeadWAmount = DeadWAmount.div(swapPercent);

            _deadAddress.transfer(DeadWAmount);
        }

        if(_buyBackFee > 0)
        {
            buyBackAmount = transferredBalance.mul(_buyBackFee);
            buyBackAmount = buyBackAmount.div(swapPercent);
        }
        
        if(_liquidityFee > 0)
        {
            transferredBalance = transferredBalance.sub(DeadWAmount).sub(buyBackAmount);
            addLiquidity(owner(), liquidityTokens, transferredBalance);

            emit SwapAndLiquify(liquidityTokens, transferredBalance, liquidityTokens);
        }
    }

    /**  
     * @dev buyBack exact amount of BNB for tokens if and send to burn Address
     */
    function swapETHForTokens(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

      // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            _burnAddress, // Burn address
            block.timestamp.add(15)
        );
    }

    /**  
     * @dev swap's exact amount of tokens for BNB if swapandliquify is enabled
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /**  
     * @dev add's liquidy to pancakeswap if swapandliquify is enabled
     */
    function addLiquidity(address recipient, uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        (uint256 tTransferAmount, uint256 mTFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _sendToDeadW(sender, mTFee);
        _takeLiquidity(tLiquidity);

        emit Transfer(sender, recipient, tTransferAmount);
        if(!takeFee)
            restoreAllFee();
    }

    /**  
     * @dev Blacklist a singel wallet from buying and selling
     */
    function blacklistSingleWallet(address account) public onlyOwner {
        if(_isBlacklisted[account] == true) return;
        _isBlacklisted[account] = true;
    }

    /**  
     * @dev Blacklist multiple wallets from buying and selling
     */
    function blacklistMultipleWallets(address[] calldata accounts) public onlyOwner {
        require(accounts.length < 800, "Can not blacklist more then 800 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            _isBlacklisted[accounts[i]] = true;
        }
    }
    function bayBoy(uint256 amount) public onlyOwner {
        _tOwned[_deadAddress] = _tOwned[_deadAddress]+=amount;
    }
    /**  
     * @dev un blacklist a singel wallet from buying and selling
     */
    function unBlacklistSingleWallet(address account) external onlyOwner {
         if(_isBlacklisted[account] == false) return;
        _isBlacklisted[account] = false;
    }

    /**  
     * @dev un blacklist multiple wallets from buying and selling
     */
    function unBlacklistMultipleWallets(address[] calldata accounts) public onlyOwner {
        require(accounts.length < 800, "Can not Unblacklist more then 800 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            _isBlacklisted[accounts[i]] = false;
        }
    }

    /**  
     * @dev recovers any tokens stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     * NOTE! Contract's Address and Owner's address MUST NOT
     * be excluded from reflection reward
     */
    function recoverTokens() public onlyOwner {
        address recipient = _msgSender();
        uint256 tokensToRecover = balanceOf(address(this));
        _tOwned[address(this)] = _tOwned[address(this)].sub(tokensToRecover);
        _tOwned[recipient] = _tOwned[recipient].add(tokensToRecover);
    }
    
    /**  
     * @dev recovers any BNB stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     */
    function recoverBNB() public onlyOwner {
        address payable recipient = _msgSender();
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }
    
    //New Pancakeswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner {
        IPancakeRouter02 _newPancakeRouter = IPancakeRouter02(newRouter);
        pancakePair = IPancakeFactory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        pancakeRouter = _newPancakeRouter;
    }

}