import './SafeMath.sol';
import './IER20.sol';
import './IUniswapV2Factory.sol';
import './Context.sol';
import './Ownable.sol';

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

//  BabyMusk Token Summary
//  3% tax to fund donations 
//  3% tax to support marketing and token growth
//  Please note, donation and marketing wallets can be adjusted as need for the success of this token
contract BabyMusk is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private constant MAX = ~uint256(0);

    // contract info
    uint8 private _decimals = 9;
    string private _name = "BabyMusk";
    string private _symbol = "BBMUSK";
    uint256 private _tTotal = 1000 * 10**9 * 10**uint256(_decimals);

    // % to holders
    uint256 public _defaultTaxFee = 6;
    uint256 public _taxFee = _defaultTaxFee;
    uint256 private _previousTaxFee = _taxFee;

    // % to swap & send to marketing wallet
    uint256 public _marketingFee4Sellers = 3;
    uint256 public _defaultMarketingFee = 0;
    uint256 public _marketingFee = _defaultMarketingFee;
    uint256 private _previousMarketingFee = _marketingFee;

    // % to swap & send to donation wallet
    uint256 public _donationFee4Sellers = 3;
    uint256 public _defaultDonationFee = 0;
    uint256 public _donationFee = _defaultDonationFee;
    uint256 private _previousDonationFee = _donationFee;

    uint256 public _maxTxAmount = _tTotal.div(1).div(100);
    uint256 public _numTokensToExchangeForMarketing = _tTotal.div(50).div(100);
    uint256 private _tFeeTotal;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
        
    bool public _feesOnSellersAndBuyers = true;
    bool private _inSwapAndSend;
    bool public _swapAndSendEnabled = true;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable _uniswapV2Pair;
    address payable public _marketingWallet = payable(0xe5a0E58478fc6F8236A63f4716D601dec293E812);         // marketing wallet
    address payable public _donationWallet = payable(0x838CB573Ef7C8307F60E485f56c4a625445dB6aE);          // donation wallet
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
            (uint256 rAmount,,,,,,) = getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _marketingFee == 0 && _donationFee == 0) {
            return;
        }

        _previousTaxFee = _taxFee;
        _previousMarketingFee = _marketingFee;
        _previousDonationFee = _donationFee;

        _taxFee = 0;
        _marketingFee = 0;
        _donationFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
        _donationFee = _previousDonationFee;
    }

    //To recieve ETH when swaping
    receive() external payable {}

    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDonation) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, tMarketing, tDonation, getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketing, tDonation);
    }

    function getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tDonation = calculateDonationFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tMarketing).sub(tDonation);
        return (tTransferAmount, tFee, tMarketing, tDonation);
    }

    function getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketing, uint256 tDonation, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rDonation = tDonation.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rMarketing).sub(rDonation);
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

    function takeDonation(uint256 tDonation) private {
        uint256 currentRate =  getRate();
        uint256 rDonation = tDonation.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rDonation);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tDonation);
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

    function calculateDonationFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_donationFee).div(
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

        _tokenTransfer(from,to,amount,takeFee);
    }

    function setFees(address recipient) private {
        _taxFee = _defaultTaxFee;
        _marketingFee = _defaultMarketingFee;
        _donationFee = _defaultDonationFee;
        if (recipient == _uniswapV2Pair) {  // This is a sell because it was from Uniswap
            _marketingFee = _marketingFee4Sellers;
            _donationFee = _donationFee4Sellers;
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
            //Split the balance across the wallets based on fee %
            uint256 totalFeeUnits = _marketingFee.add(_donationFee);
            uint256 amountPerUnit = contractETHBalance.div(totalFeeUnits);
            uint256 marketingETHBalance = amountPerUnit.mul(_marketingFee);
            uint256 donationETHBalance = amountPerUnit.mul(_donationFee);

            if (amountPerUnit >= 1){
                _marketingWallet.transfer(marketingETHBalance);
                _donationWallet.transfer(donationETHBalance);
            }
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDonation) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        takeDonation(tDonation);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDonation) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        takeDonation(tDonation);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDonation) = getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        takeDonation(tDonation);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tDonation) = getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeMarketing(tMarketing);
        takeDonation(tDonation);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setDefaultMarketingFee(uint256 marketingFee) external onlyOwner() {
        _defaultMarketingFee = marketingFee;
    }

    function setMarketingFee4Sellers(uint256 marketingFee4Sellers) external onlyOwner() {
        _marketingFee4Sellers = marketingFee4Sellers;
    }

    function setDonationFee4Sellers(uint256 donationFee4Sellers) external onlyOwner() {
        _donationFee4Sellers = donationFee4Sellers;
    }

    function setFeesOnSellersAndBuyers(bool _enabled) public onlyOwner() {
        _feesOnSellersAndBuyers = _enabled;
    }

    function setSwapAndSendEnabled(bool _enabled) public onlyOwner() {
        _swapAndSendEnabled = _enabled;
        emit SwapAndSendEnabledUpdated(_enabled);
    }

    function setNumTokensToExchangeForMarketing(uint256 numTokensToExchangeForMarketing) public onlyOwner() {
        _numTokensToExchangeForMarketing = numTokensToExchangeForMarketing;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner() {
        _marketingWallet = wallet;
    }

    function setDonationWallet(address payable wallet) external onlyOwner() {
        _donationWallet = wallet;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }
}