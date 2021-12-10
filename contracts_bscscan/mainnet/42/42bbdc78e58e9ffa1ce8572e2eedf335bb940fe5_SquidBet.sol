// SPDX-License-Identifier: Unlicensed

import './ERC20.sol';
import './Ownable.sol';
import './Oracle.sol';
import './Rewards.sol';
import './IERC20.sol';
import './IRouter.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './SafeMath.sol';
import './Address.sol';
// import './Airdrop.sol';


pragma solidity >=0.6.12;

contract SquidBet is Context, IERC20, ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    Oracle oracle;
    Rewards reward;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public MAX_PRESALE_TOKENS = 2000000000 * 10**18;
    uint256 public PRESALE_SOLD_TOKENS = 0;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    mapping (address => bool) private _isIncludedInFee;    

    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _maxSupply = 10000000000 * 10**18;
    uint256 public _pricePerToken = 250000000000000; // 0.00025
    uint256 private _tTotal = _maxSupply;   
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    uint256 private _incremeter = 0;
    
    string private _name = "SquidBet";
    string private _symbol = "SQD";
    uint8 private _decimals = 18;
    uint56 private _maxRand = 1000000;
    
    bool public paused;
    bool public pausedAwards;

    bool public globalTaxEnabled = false;
    bool public taxBuyEnabled = false;
    bool public taxSellEnabled = true;

    uint256 public _maxPoolRewardDivider = 50;

    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 0;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 public _maxTxAmount = 50000000 * 10**18;
    uint256 private numTokensSellToAddToLiquidity = 500 * 10**18;
    
    address payable fundsWallet;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (address oracleAddress, address rewardAddress) {
        oracle = Oracle(oracleAddress);
        reward = Rewards(rewardAddress);
        
        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = tokenFromReflection(_rTotal);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // only tax uniswap transactions
        _isIncludedInFee[address(uniswapV2Pair)] = true;
        _isIncludedInFee[address(uniswapV2Router)] = true;

        //exclude burn address from reflection
        _isExcluded[BURN_ADDRESS] = true;
        
        fundsWallet = payable(msg.sender);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    // fallback() external payable {
    //     totalEthInWei = totalEthInWei + msg.value;
    //     uint256 amount = msg.value * unitsOneEthCanBuy;
    //     require(_rOwned[fundsWallet] >= amount);
    
    //     _rOwned[fundsWallet] = _rOwned[fundsWallet].sub(amount);
    //     _rOwned[msg.sender] = _rOwned[msg.sender].add(amount);
    
    //     emit Transfer(fundsWallet, msg.sender, amount);
    //     fundsWallet.transfer(msg.value);
    // }

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurnt() public view returns (uint256) {
        return balanceOf(BURN_ADDRESS);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        
        //if any account belongs to _isIncludedInFee then charge fee
        if(globalTaxEnabled || ((taxBuyEnabled && _isIncludedInFee[from]) || (taxSellEnabled && _isIncludedInFee[to]))){
            takeFee = true;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rAmountWithFee = rAmount.add(rFee);

        _rOwned[sender] = _rOwned[sender].sub(rAmountWithFee);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).add(rFee);
        _takeTaxFee(tFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
                
        emit Transfer(sender, recipient, tTransferAmount.add(tFee));

        if (_isIncludedInFee[recipient]) {
            emit Transfer(sender, fundsWallet, tFee);
        }

        if (_isIncludedInFee[sender]) {
            uint256 awarded = _awardBuyer(recipient, tTransferAmount);
            emit Transfer(fundsWallet, recipient, awarded);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rAmountWithFee = rAmount.add(rFee);

        _rOwned[sender] = _rOwned[sender].sub(rAmountWithFee);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount).add(tFee);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).add(rFee);
        _takeTaxFee(tFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount.add(tFee));

        if (_isIncludedInFee[recipient]) {
            emit Transfer(sender, fundsWallet, tFee);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tAmountWithFee = tAmount.add(tFee);
        uint256 rAmountWithFee = rAmount.add(rFee);

        _tOwned[sender] = _tOwned[sender].sub(tAmountWithFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmountWithFee);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).add(rFee);
        _takeTaxFee(tFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount.add(tFee));

        if (_isIncludedInFee[recipient]) {
            emit Transfer(sender, fundsWallet, tFee);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tAmountWithFee = tAmount.add(tFee);
        uint256 rAmountWithFee = rAmount.add(rFee);

        _tOwned[sender] = _tOwned[sender].sub(tAmountWithFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmountWithFee);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount).add(tFee);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).add(rFee);
        _takeTaxFee(tFee);    
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount.add(tFee));

        if (_isIncludedInFee[recipient]) {
            emit Transfer(sender, fundsWallet, tFee);
        }
    }
    
    function _transferPresale(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).add(rFee);
        
        emit Transfer(sender, recipient, tTransferAmount.add(tFee));
    }

    // to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        // _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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
    
    function _takeTaxFee(uint256 tTax) private {
        uint256 currentRate =  _getRate();
        uint256 rTax = tTax.mul(currentRate);
        _rOwned[fundsWallet] = _rOwned[fundsWallet].add(rTax);
        if(_isExcluded[fundsWallet])
            _tOwned[fundsWallet] = _tOwned[fundsWallet].add(tTax);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded from reward");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner() {
        require(_isExcluded[account], "Account is already included in reward");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isIncludedInFee[account] = false;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isIncludedInFee[account] = true;
    }

    function isIncludedInFee(address account) public view returns(bool) {
        return _isIncludedInFee[account];
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function removeAllFee() internal {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() internal {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function setGlobalTax(bool _enabled) public onlyOwner {
        globalTaxEnabled = _enabled;
    }

    function setTaxBuy(bool _enabled) public onlyOwner {
        taxBuyEnabled = _enabled;
    }

    function setTaxSell(bool _enabled) public onlyOwner {
        taxSellEnabled = _enabled;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _tTotal += amount;
        _rOwned[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function burnTokens(uint256 tBurn) public onlyOwner {
        address sender = _msgSender();  
        require(sender != address(0), "ERC20: burn from the zero address");

		if (tBurn == 0) return;
		_tBurnTotal = _tBurnTotal.add(tBurn);
		
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[BURN_ADDRESS] = _rOwned[BURN_ADDRESS].add(rBurn);
        if(_isExcluded[BURN_ADDRESS])
            _tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(tBurn);
		emit Transfer(sender, BURN_ADDRESS, tBurn);
    }

    function purchaseTokens() public payable {
        require(!paused, 'Purchasing is currently disabled');
        require(msg.value >= _pricePerToken, "Insufficient payment, you must buy at least 1 token");
        require(msg.value <= MAX_PRESALE_TOKENS, "Over maximum pre-sale");
        require(PRESALE_SOLD_TOKENS <= MAX_PRESALE_TOKENS, "Sold Out!");

        _transferPresale(fundsWallet, payable(_msgSender()), msg.value/_pricePerToken*1000000000000000000);
        
        PRESALE_SOLD_TOKENS += msg.value;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        _pricePerToken = newPrice;
    }
    
    function switchPause() public onlyOwner {
        paused = !paused;
    }

    function switchPausedAwards() public onlyOwner {
        pausedAwards = !pausedAwards;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setLiquidityFee(uint256 amount) public onlyOwner {
        _liquidityFee = amount;
    }

    function setTaxFee(uint256 amount) public onlyOwner {
        _taxFee = amount;
    }
    
    function resetIncrementer() public onlyOwner {
        _incremeter = 0;
    }

    function foundationWithdraw() public onlyOwner{
        fundsWallet.transfer(address(this).balance);
    }
    
    function updateOracleAddress(address oracleAddress) public onlyOwner {
        oracle = Oracle(oracleAddress);
    }
    
    function updateRewardAddress(address rewardAddress) public onlyOwner {
        reward = Rewards(rewardAddress);
    }

    function updateFundsWallet(address payable fundsAddress) public onlyOwner {
        fundsWallet = fundsAddress;
    }
    
    function _getAwardMultiplier(uint256 rand) private view returns(uint256) {
        return reward.getAwardMultiplier(rand);
    }

    function updateMaxPoolRewardDivider(uint256 maxDivider) public onlyOwner {
        _maxPoolRewardDivider = maxDivider;
    }

    function _awardBuyer(address account, uint256 amount) private returns(uint) {
        if (_msgSender() == fundsWallet) return 0;
        if (pausedAwards) return 0;

        uint256 rand = random(_maxRand);
        uint256 multiplier = _getAwardMultiplier(rand);

        if (multiplier == 0) {
            emit TransferReward(fundsWallet, account, 0, multiplier);

            return 0;
        }
        
        uint256 awarded = (uint(multiplier * amount) / uint(_maxRand));

        if (awarded >= _rOwned[fundsWallet].div(_maxPoolRewardDivider)) {
            awarded = (_rOwned[fundsWallet].div(_maxPoolRewardDivider));
        }
        
        uint256 tAward = tokenFromReflection(awarded);
        _tOwned[fundsWallet] = _tOwned[fundsWallet].sub(tAward);
        _rOwned[fundsWallet] = _rOwned[fundsWallet].sub(awarded);
        _rOwned[account] = _rOwned[account].add(awarded);   

        emit TransferReward(fundsWallet, account, awarded, multiplier);

        return awarded;
    }
    
    function random(uint max) public returns(uint) {
        bytes memory source;
        uint oracleRandom = oracle.getRandom();

        _incremeter++;
        
        source = abi.encodePacked(
            oracleRandom,
            _incremeter,
            block.timestamp,
            block.number,
            blockhash(block.number),
            block.difficulty,
            msg.sender
        );

        uint rand = (uint(keccak256(source)).mod(max));

        return rand;
    }
}