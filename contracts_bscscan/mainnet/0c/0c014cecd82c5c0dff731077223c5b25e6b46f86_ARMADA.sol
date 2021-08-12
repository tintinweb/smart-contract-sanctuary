//SPDX-License-Identifier: MIT

/**
 *                                                                 
 *  A HYPER-DEFLATIONARY, BUYBACK POWERED CRYPTOCURRENCY
 *  
 *  https://armadacrypto.com
 *  https://t.me/armadatoken
 */
 
pragma solidity ^0.8.6;

import "./Utils.sol";
import "./SafeMath.sol";
import "./DepreciatingFees.sol";

contract ARMADA is IERC20Metadata, DepreciatingFees, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address public marketingAddress = 0x6D07c5Bd49042e160A57B198d7afF472aA3b1F69; // Marketing Address
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    string constant _name = "Armada";
    string constant _symbol = "AMRD";
    uint8 constant _decimals = 18;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _totalSupply = 1000000000000 * 10**18;
    uint256 internal _reflectedSupply = (MAX - (MAX % _totalSupply));
    
    uint256 public buyBackFee = 12;
    uint256 public rfiFee = 2;
    uint256 public marketingFee = 2;
    uint256 public antiDumpFee = 3;
    
    uint256 private collectedFeeTotal;
    uint256 internal constant FEES_DIVISOR = 10**8;
    
    uint256 public maxTxAmount = _totalSupply / 1000; // 0.5% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply
    
    bool public autoBuyBackEnabled = true;
    uint256 public autoBuybackAmount = 1 * 10**18;
    bool public takeFeeEnabled = true;
    bool public isInPresale = false;
    
    uint256 public marketingDivisor = marketingFee;
    
    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 200000 * (10**18);
    
    IPancakeV2Router public router;
    address public pair;
    
    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;
    
    event UpdatePancakeswapRouter(address indexed newAddress, address indexed oldAddress);
    event BuyBackEnabledUpdated(bool enabled);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    constructor () {
        _reflectedBalances[owner()] = _reflectedSupply;
        
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        router = _newPancakeRouter;
        
        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
        
        // exclude the pair address from rewards - we don't want to redistribute
        _exclude(pair);
        _exclude(deadAddress);
        
        _approve(owner(), address(router), ~uint256(0));
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    
    receive() external payable { }
    
    uint256 buyBackFee_ = buyBackFee * reductionDivisor;
    uint256 rfiFee_ = rfiFee * reductionDivisor;
    uint256 marketingFee_ = marketingFee * reductionDivisor;
    uint256 antiDumpFee_ = antiDumpFee * reductionDivisor;
    
    uint256 baseTotalFees = buyBackFee_.add(rfiFee_).add(marketingFee_);
    uint256 baseSellerTotalFees = baseTotalFees.add(antiDumpFee_);
    
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256){
        if (_isExcludedFromRewards[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
        }
        
    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
        
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
        }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }
        
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
        
    function burn(uint256 amount) external {

        address sender = _msgSender();
        require(sender != address(0), "ERC20: burn from the zero address");
        require(sender != address(deadAddress), "ERC20: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(reflectedAmount);
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens( sender, amount, reflectedAmount );
    }
    
    /**
     * @dev "Soft" burns the specified amount of tokens by sending them 
     * to the burn address
     */
    function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */ 
        _reflectedBalances[deadAddress] = _reflectedBalances[deadAddress].add(rBurn);
        if (_isExcludedFromRewards[deadAddress])
            _balances[deadAddress] = _balances[deadAddress].add(tBurn);

        /**
         * @dev Emit the event so that the burn address balance is updated (on bscscan)
         */
        emit Transfer(sender, deadAddress, tBurn);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }
    
     /**
     * @dev Calculates and returns the reflected amount for the given amount with or without 
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, bool isBuying) external view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        uint256 feesSum;
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            feesSum = isBuying ? baseTotalFees : baseSellerTotalFees;
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, feesSum);
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }
    
    function _exclude(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function setExcludedFromFee(address account, bool value) external onlyOwner { _isExcludedFromFee[account] = value; }
    function isExcludedFromFee(address account) public view returns(bool) { return _isExcludedFromFee[account]; }
    
    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = _totalSupply;

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply)
            return (_reflectedSupply, _totalSupply);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(_totalSupply)) return (_reflectedSupply, _totalSupply);
        return (rSupply, tSupply);
    }
    
    
    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`. 
     * 
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        
        collectedFeeTotal = collectedFeeTotal.add(tFee);
    }
    
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return swapTokensAtAmount;
    }
    
    function getAutoBuybackAmount() public view returns (uint256) {
        return autoBuybackAmount;
    }
    
    function totalCollectedFees() public view returns (uint256) {
        return collectedFeeTotal;
    }
    
    function prepareForPreSale() external onlyOwner {
        takeFeeEnabled = false;
        isInPresale = true;
        buyBackFee = 0;
        marketingFee = 0;
        rfiFee = 0;
        maxTxAmount = 1000000000000 * (10**18);
        maxWalletBalance = 1000000000000 * (10**18);
    }
    
    function afterPreSale() external onlyOwner {
        takeFeeEnabled = true;
        isInPresale = false;
        buyBackFee = 12;
        marketingFee = 2;
        rfiFee = 2;
        maxTxAmount = 40142 * (10**18);
        maxWalletBalance = 4014201 * (10**18);
    }
    
    function setBuyBackEnabled(bool _enabled) external onlyOwner {
        autoBuyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function triggerBuyBack(uint256 amount) public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(!swapping, "ARMADA: A swapping process is currently running, wait till that is complete");
        require(contractBalance >= amount, "ARMADA: Insufficient Funds");
    
        buyBackTokens(amount.div(100));
    }
    
    function updateWalletMax(uint256 _walletMax) external onlyOwner {
        maxWalletBalance = _walletMax * (10**18);
    }
    
    function updateTransactionMax(uint256 _txMax) external onlyOwner {
        maxTxAmount = _txMax * (10**18);
    }
    
    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= 10, "Marketing Fee must be between 0 and 10");
        marketingFee = newFee;
    }
    
    function updateBuyBackFee(uint8 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= 20, "Buy Back Fee must be between 0 and 10");
        buyBackFee = newFee;
    }
    
    function updateRfiFee(uint8 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RFI Fee must be between 0 and 10");
        rfiFee = newFee;
    }
    
    function setMarketingDivisor(uint256 divisor) external onlyOwner() {
        marketingDivisor = divisor;
    }
    
    function updateRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(router), "The router already has that address");
        router = IPancakeV2Router(newAddress);
        emit UpdatePancakeswapRouter(newAddress, address(router));
    }
    
    function withdrawLeftOverBNB(address payable recipient) external onlyOwner {
        uint256 withdrawableBalance = address(this).balance;
        require(recipient != address(0), "Cannot withdraw the BNB balance to the zero address");
        require(withdrawableBalance > 0, "The BNB balance must be greater than 0");

        // prevent re-entrancy attacks
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }
    
    function setFeeHolder(address _userAddress) internal {
        addFeeHolder(
            _userAddress, 
            rfiFee_, 
            buyBackFee_, 
            marketingFee_, 
            antiDumpFee_, 
            block.timestamp, 
            block.timestamp + updateFeeTime
            ); 
    }
    
    function _getUserFees (address _userAddress, bool feeReduction) 
    internal view returns (uint256, uint256, uint256, uint256, uint256) {
        
        // The reduced fee is what the user will actually pay
        // the default for first transaction
        uint256 reduceRfiFee = rfiFee_;
        uint256 reduceMarketingFee = marketingFee_;
        uint256 reduceBuyBackFee = buyBackFee_;
        uint256 reduceAntiDumpFee = antiDumpFee_;
        uint256 estimatedAccruedFees = reductionPerSec; // default
        address __userAddress = _userAddress;
        bool _feeReduction = feeReduction;
        
        if(_feeReduction) {
            (uint256 _estimatedRfiFee, uint256 _estimatedBuyBackFee, 
            uint256 _estimatedMarketingFee, uint256 _estimatedAntiDumpFee, 
            uint256 _estimatedAccruedFees) = getEstimatedFee(__userAddress);
            
            if(_feeReduction && block.timestamp >= fees[__userAddress].nextReductionTime) {
               // If it's not the first transaction then subtract accrued Fees
                reduceRfiFee = _estimatedRfiFee;
                reduceMarketingFee = _estimatedMarketingFee;
                reduceBuyBackFee = _estimatedBuyBackFee;
                reduceAntiDumpFee = _estimatedAntiDumpFee;
                estimatedAccruedFees = _estimatedAccruedFees;
            }
            
        }
        
        return (
            reduceRfiFee,
            reduceMarketingFee,
            reduceBuyBackFee,
            reduceAntiDumpFee,
            estimatedAccruedFees
            );
    }
    
    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        collectedFeeTotal = collectedFeeTotal.add(tAmount);
    }
    
    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee, bool feeReduction) private {
       
        
        (uint256 reduceRfiFee, uint256 reduceMarketingFee, uint256 reduceBuyBackFee, 
        uint256 reduceAntiDumpFee, uint256 estimatedAccruedFees) = _getUserFees(msg.sender, feeReduction);
        
         uint256 sumOfFees = reduceRfiFee.add(reduceMarketingFee).add(reduceBuyBackFee);
         bool selling = false;
         
        if(recipient == pair) {
            sumOfFees = sumOfFees.add(reduceAntiDumpFee);
            selling = true;
        }
        
        if(feeReduction) {
            // Adjust the Fee struct to reflect the new transaction
            reAdjustFees(msg.sender, estimatedAccruedFees, reduceRfiFee, reduceMarketingFee, reduceBuyBackFee, reduceAntiDumpFee);
        }
       
       
        if ( !takeFee ){ sumOfFees = 0; }
        
        processReflectedBal(sender, recipient, amount, sumOfFees, selling, reduceRfiFee, reduceMarketingFee, reduceBuyBackFee, reduceAntiDumpFee);
       
    }
    
    function processReflectedBal (address sender, address recipient, uint256 amount, uint256 sumOfFees, bool selling, 
    uint256 reduceRfiFee, uint256 reduceMarketingFee, uint256 reduceBuyBackFee, uint256 reduceAntiDumpFee) internal {
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);
        bool _selling = selling;
         
        theReflection(sender, recipient, rAmount, rTransferAmount, tAmount, tTransferAmount); 
        
        _takeFees(amount, 
        currentRate, 
        sumOfFees, 
        reduceRfiFee, 
        reduceMarketingFee, reduceBuyBackFee, reduceAntiDumpFee, 
        _selling);
        emit Transfer(sender, recipient, tTransferAmount);    
    }
    
    function theReflection(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount) private {
            
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);
        
        /**
         * Update the true/nominal balances for excluded accounts
         */        
        if (_isExcludedFromRewards[sender]) { _balances[sender] = _balances[sender].sub(tAmount); }
        if (_isExcludedFromRewards[recipient] ) { _balances[recipient] = _balances[recipient].add(tTransferAmount); }
    }
    
    
    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees, uint256 reduceRfiFee, 
    uint256 reduceMarketingFee, uint256 reduceBuyBackFee, uint256 reduceAntiDumpFee, bool selling) private {
        if ( sumOfFees > 0 && !isInPresale ){
            _redistribute( amount, currentRate, reduceRfiFee);  // redistribute to holders
            _takeFee( amount, currentRate, reduceBuyBackFee, address(this)); // buy back fee
            _takeFee( amount, currentRate, reduceMarketingFee, address(this)); // Marketing fee
            
            if(selling) {
                _takeFee( amount, currentRate, reduceAntiDumpFee, address(this));
                }
        }
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(sender != address(deadAddress), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (
            sender != address(router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFee[recipient] && //no max for those excluded from fees
            !_isExcludedFromFee[sender] 
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }
        
        if ( maxWalletBalance > 0 && !_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender] && recipient != address(pair) ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }
            
         // indicates whether or not feee should be deducted from the transfer
        bool _isTakeFee = takeFeeEnabled;
        if ( isInPresale ){ _isTakeFee = false; }
        
         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { 
            _isTakeFee = false; 
        }
        
         bool feeReduction = true;
        // create a new fee holder
        if(!isFeeHolder(msg.sender) && !_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender]) {
           setFeeHolder(msg.sender); // create a new fee holder
           feeReduction = false;
        }
        
        _beforeTokenTransfer();
        _transferTokens(sender, recipient, amount, _isTakeFee, feeReduction );
        
    }
    
    function _beforeTokenTransfer() private {
        // also adjust fees - add later
        
        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap && swapEnabled) {
                swapping = true;
                swapTokens(contractTokenBalance);
                swapping = false;
            }
            uint256 buyBackBalance = address(this).balance;
            // auto buy back
            if(autoBuyBackEnabled && buyBackBalance >= autoBuybackAmount && !swapping) {
                buyBackBalance = autoBuybackAmount;
                
                buyBackTokens(buyBackBalance.div(100));
            }
        }
    }
    
    function swapTokens(uint256 contractTokenBalance) private {
       
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        //Send to Marketing address
        transferToAddressBNB(payable(marketingAddress), transferredBalance.div(10**2).mul(marketingDivisor));
        
    }
    
    function buyBackTokens(uint256 amount) private {
    	if (amount > 0) {
    	    swapBNBForTokens(amount);
	    }
    }
    
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

      // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp
        );
        
        emit SwapETHForTokens(amount, path);
    }
    
    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
}