import './SafeMath.sol';
import './IER20.sol';
import './IUniswapV2Factory.sol';
import './Context.sol';
import './Ownable.sol';

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

//  BabyPicasso Token Summary
//  2% reflections - buys and sells
//  4% marketing and app dev wallet
contract BabyPicasso is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private constant MAX = ~uint256(0);

    // contract info
    uint8 private _decimals = 9;
    string private _name = "Baby Picasso";
    string private _symbol = "PCASSO";
    uint256 private _tTotal = 1000 * 10**9 * 10**uint256(_decimals);

    // % to holders
    uint256 private _defaultTaxFee = 2;
    uint256 private _taxFee = _defaultTaxFee;
    uint256 private _previousTaxFee = _taxFee;

    // % to swap & send to marketing wallet
    uint256 private _marketingFee4Sellers = 4;
    uint256 private _defaultMarketingFee = 0;
    uint256 private _marketingFee = _defaultMarketingFee;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 private _maxTxAmount = _tTotal.div(1).div(100);
    uint256 private _numTokensToExchangeForMarketing = _tTotal.div(100).div(100);
    uint256 private _tFeeTotal;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
        
    bool private _feesOnSellersAndBuyers = true;
    bool private _inSwapAndSend;
    bool private _swapAndSendEnabled = true;

    IUniswapV2Router02 private immutable uniswapV2Router;
    address private immutable _uniswapV2Pair;
    address payable private _marketingWallet = payable(0xe5a0E58478fc6F8236A63f4716D601dec293E812);
    address[] private _excluded;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    event SwapAndSendEnabledUpdated(bool enabled);

    modifier lockTheSwap {
        _inSwapAndSend = true;
        _;
        _inSwapAndSend = false;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uniswap pair for this new token
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        if (_isExcluded[account]) {
            return _tOwned[account];
        }
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) private {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) private {
        require(_isExcluded[account], "Account is already excluded");
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

    function excludeFromFee(address account) private {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) private {
        _isExcludedFromFee[account] = false;
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _marketingFee == 0) {
            return;
        }

        _previousTaxFee = _taxFee;
        _previousMarketingFee = _marketingFee;

        _taxFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
    }

    //To recieve ETH when swaping
    receive() external payable {}

    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, tMarketing, getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketing);
    }

    function getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tMarketing);
        return (tTransferAmount, tFee, tMarketing);
    }

    function getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
                return (_rTotal, _tTotal);
            }
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }
        return (rSupply, tSupply);
    }

    function takeMarketing(uint256 tMarketing) private {
        uint256 currentRate =  getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
        }
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _numTokensToExchangeForMarketing;

        if(contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        if (overMinTokenBalance 
            && !_inSwapAndSend 
            && from != _uniswapV2Pair 
            && _swapAndSendEnabled) {
            swapAndSend(contractTokenBalance);
        }

        if(_feesOnSellersAndBuyers) {
            setFees(to);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        tokenTransfer(from,to,amount,takeFee);
    }

    function setFees(address recipient) private {
        _taxFee = _defaultTaxFee;
        _marketingFee = _defaultMarketingFee;
        if (recipient == _uniswapV2Pair) {  // This is a sell because it was from Uniswap
            _marketingFee = _marketingFee4Sellers;
        }
    }

    function swapAndSend(uint256 contractTokenBalance) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), contractTokenBalance);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractETHBalance = address(this).balance;

        if(contractETHBalance > 0) {
            _marketingWallet.transfer(contractETHBalance);
        }
    }

    function tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            transferBothExcluded(sender, recipient, amount);
        } else {
            transferStandard(sender, recipient, amount);
        }

        if(!takeFee) {
            restoreAllFee();
        }
    }

    function transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing) = getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setDefaultMarketingFee(uint256 marketingFee) private {
        _defaultMarketingFee = marketingFee;
    }

    function setMarketingFee4Sellers(uint256 marketingFee4Sellers) private {
        _marketingFee4Sellers = marketingFee4Sellers;
    }

    function setFeesOnSellersAndBuyers(bool _enabled) private {
        _feesOnSellersAndBuyers = _enabled;
    }

    function setSwapAndSendEnabled(bool _enabled) private {
        _swapAndSendEnabled = _enabled;
        emit SwapAndSendEnabledUpdated(_enabled);
    }

    function setNumTokensToExchangeForMarketing(uint256 numTokensToExchangeForMarketing) private {
        _numTokensToExchangeForMarketing = numTokensToExchangeForMarketing;
    }

    function setMarketingWallet(address payable wallet) private {
        _marketingWallet = wallet;
    }

    function setMaxTxAmount(uint256 maxTxAmount) private {
        _maxTxAmount = maxTxAmount;
    }
}