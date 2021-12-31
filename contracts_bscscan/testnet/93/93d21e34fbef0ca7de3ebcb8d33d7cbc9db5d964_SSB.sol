/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUNIFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUNIRouter {
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        authorizations[oldOwner] = false;
        authorizations[newOwner] = true;
        emit Unauthorized(oldOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

interface IBuyFeeOracle {
    function getScale(uint256 denominator) external returns (uint256 scale);
}

interface IBurnLottery {
    function onBurn(address from, uint256 amount) external;
}

interface IAntiSnipe {
    function initialize(address liquidityPair) external;
    function protect(address from, address to, uint256 amount) external returns (bool shouldProtect);
}

contract SSB is Auth, IBEP20 {
    uint256 constant UINT_MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Gupta Bewafa Hai";
    string constant _symbol = "Bewafa";
    uint8 constant _decimals = 7;
    
    IAntiSnipe public protection;
    mapping (address => bool) protect;
    bool public protectionEnabled = true;
    uint256 constant protectionLength = 20;
    
    IBuyFeeOracle oracle;
    IBurnLottery lottery;
    
    mapping (address => uint256) _rOwned;
    mapping (address => uint256) _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromTxLimit;

    uint256 _tTotal = 7700 * 10**9 * (10**_decimals);
    uint256 _rTotal = (UINT_MAX - (UINT_MAX % _tTotal));
    uint256 _tFeeTotal;

    uint256 public _reflectFee = 200;
    uint256 public _taxFee = 1000;
    uint256 public _feeDenominator = 10000;
    uint256 _previousReflectFee = _reflectFee;
    uint256 _previousTaxFee = _taxFee;
    uint256 _previousDenominator = _feeDenominator;

    uint256 public _buybackSplit = 600;
    uint256 public _communitySplit = 300;
    uint256 public _devSplit = 25;
    uint256 public _marketingSplit = 75;
    address payable public _communityFeeReceiver;
    address payable public _devFeeReceiver;
    address payable public _marketingFeeReceiver;

    uint256 buybackMultiplierNumerator = 25;
    uint256 buybackMultiplierDenominator = 10;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;
    
    IUNIRouter router;
    address public pair;
    uint256 public launchBlock;

    uint256 public _maxTxAmount = _tTotal / 2000;
    uint256 public swapBackAmount = _tTotal / 5000;
    bool public swapBackEnabled = true;

    bool swapping;
    modifier swapBack {
        swapping = true;
        _;
        swapping = false;
    }
    
    receive() external payable { }

    constructor (address payable _community, address payable _dev, address payable _marketing) Auth(msg.sender) {
        _communityFeeReceiver = _community;
        _devFeeReceiver = _dev;
        _marketingFeeReceiver = _marketing;
        
        _rOwned[owner] = _rTotal;

        router = IUNIRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IUNIFactory(router.factory()).createPair(address(this), WBNB);

        _isExcludedFromFee[owner] = true;
        _isExcludedFromTxLimit[owner] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner, _tTotal);
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if(account == pair) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _reflect(uint256 rFee, uint256 tReflect) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tReflect;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflect, uint256 tTax) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tReflect, tTax, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tReflect, tTax);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        (uint256 tReflect, uint256 tTax) = calculateFees(tAmount);
        uint256 tTransferAmount = tAmount - tReflect - tTax;
        return (tTransferAmount, tReflect, tTax);
    }

    function _getRValues(uint256 tAmount, uint256 tReflect, uint256 tTax, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tReflect * currentRate;
        uint256 rTax = tTax * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rTax;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }
    
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (_rOwned[pair] > rSupply || _tOwned[pair] > tSupply) return (_rTotal, _tTotal);
        rSupply -= _rOwned[pair];
        tSupply -= _tOwned[pair];
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeTax(uint256 tTax) private {
        uint256 currentRate =  _getRate();
        uint256 rTax = tTax * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rTax;
    }

    function calculateFees(uint256 _amount) private view returns (uint256 tReflect, uint256 tTax) {
        tReflect = _amount * _reflectFee / _feeDenominator;
        tTax = _amount * _taxFee / _feeDenominator;
    }

    function removeAllFee() private {
        if(_reflectFee == 0 && _taxFee == 0) return;

        _previousReflectFee = _reflectFee;
        _previousTaxFee = _taxFee;
        _previousDenominator = _feeDenominator;

        _reflectFee = 0;
        _taxFee = 0;
    }
    
    function scaleBuyFee() private {
        if(_reflectFee == 0 && _taxFee == 0) return;

        _previousReflectFee = _reflectFee;
        _previousTaxFee = _taxFee;
        _previousDenominator = _feeDenominator;
        
        try oracle.getScale(_feeDenominator) returns (
            uint256 scale
        ) {
            if(scale < _feeDenominator){
                _reflectFee = scale * _reflectFee;
                _taxFee = scale * _taxFee;
                _feeDenominator = _feeDenominator * _feeDenominator;
            }
        } catch {}
    }
    
    function scaleSellFee() private {
        if(_reflectFee == 0 && _taxFee == 0) return;
        
        _previousReflectFee = _reflectFee;
        _previousTaxFee = _taxFee;
        _previousDenominator = _feeDenominator;
        
        (uint256 _reflection, uint256 _tax, uint256 _denominator) = getSellFees();
        _reflectFee = _reflection;
        _taxFee = _tax;
        _feeDenominator = _denominator;
    }
    
    function getSellFees() public view returns (uint256 _reflection, uint256 _tax, uint256 _denominator) {
        if(buybackMultiplierTriggeredAt + buybackMultiplierLength <= block.timestamp)
            return (_reflectFee, _taxFee, _feeDenominator);
            
        uint256 remainingTime = buybackMultiplierTriggeredAt + buybackMultiplierLength - block.timestamp;
        
        uint256 reflectionIncrease = (_reflectFee * buybackMultiplierNumerator / buybackMultiplierDenominator) - _reflectFee;
        _reflection = _reflectFee + (reflectionIncrease * remainingTime / buybackMultiplierLength);
        
        uint256 taxIncrease = (_taxFee * buybackMultiplierNumerator / buybackMultiplierDenominator) - _taxFee;
        _tax = _taxFee + (taxIncrease * remainingTime / buybackMultiplierLength);
        
        _denominator = _feeDenominator;
    }

    function restoreAllFee() private {
        _reflectFee = _previousReflectFee;
        _taxFee = _previousTaxFee;
        _feeDenominator = _previousDenominator;
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
        require(amount <= _maxTxAmount || _isExcludedFromTxLimit[from] || _isExcludedFromTxLimit[to], "Transfer amount exceeds the maxTxAmount.");
        require(launchBlock != 0 || from == owner || to == owner, "Token not launched");
        
        if(launchBlock == 0){
            require(from == owner || to == owner, "Token not launched");
            if(to == pair){
                launchBlock = block.number;
            }
        }

        if (
            balanceOf(address(this)) >= swapBackAmount &&
            !swapping &&
            from != pair &&
            swapBackEnabled
        ) {
            swapBackForFee(swapBackAmount);
        }

        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        bool scaleBuy = address(oracle) != address(0) && from == pair;
        bool scaleSell = to == pair;
        
        if(!takeFee){
            removeAllFee();
        }else if(scaleBuy){
            scaleBuyFee();
        }else if(scaleSell){
            scaleSellFee();
        }

        if(from == pair){
            _transferFromExcluded(from, to, amount);
        }else if(to == pair){
            _transferToExcluded(from, to, amount);
        }else{
            _transferStandard(from, to, amount);
        }

        if(!takeFee || scaleBuy || scaleSell) restoreAllFee();
            
        _onTokenTransfer(from,to,amount);
    }

    function swapBackForFee(uint256 tokenAmount) private swapBack {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 amount = address(this).balance - balanceBefore;
        
        uint256 externalFeeSplit = _communitySplit + _devSplit + _marketingSplit;
        if(externalFeeSplit > 0){
            uint256 amountCommunity = _communitySplit * amount / (externalFeeSplit + _buybackSplit);
            if(amountCommunity > 0)
                _communityFeeReceiver.call{value: amountCommunity, gas: 35000}("");
                
            uint256 amountDev = _devSplit * amount / (externalFeeSplit + _buybackSplit);
            if(amountDev > 0)
                _devFeeReceiver.call{value: amountDev, gas: 35000}("");
                
            uint256 amountMarketing = _marketingSplit * amount / (externalFeeSplit + _buybackSplit);
            if(amountMarketing > 0)
                _marketingFeeReceiver.call{value: amountMarketing, gas: 35000}("");
        }
    }
    
    function buyback(uint256 amount, bool triggerMultiplier, uint256 amountOutMin) external authorized swapBack {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            amountOutMin,
            path,
            DEAD,
            block.timestamp
        );
        
        if(triggerMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierTriggered(buybackMultiplierLength);
        }
        
        emit Buyback(amount, triggerMultiplier);
    }
    
    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
        emit BuybackMultiplierCleared();
    }

    function _onTokenTransfer(address sender, address recipient, uint256 amount) private {
        if(recipient == DEAD && address(lottery) != address(0) && !swapping)
            lottery.onBurn(sender, amount);
            
        if(launchBlock > 0 && protectionEnabled){
            if(launchBlock + protectionLength < block.number){
                protectionEnabled = false;
                emit ProtectionDisabled();
            }else{
                try protection.protect(sender, recipient, amount) returns (bool shouldProtect) {
                    if(shouldProtect){
                        protect[recipient] = true;
                        emit Protected(recipient, true);
                    }
                } catch { }
            }
        }
        require(!protect[sender], "Protected");
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tReflect, uint256 tTax) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeTax(tTax);
        _reflect(rFee, tReflect);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tReflect, uint256 tTax) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeTax(tTax);
        _reflect(rFee, tReflect);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tReflect, uint256 tTax) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeTax(tTax);
        _reflect(rFee, tReflect);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function setFees(uint256 _toReflect, uint256 _toTax, uint256 _denominator, uint256 _buyback, uint256 _community, uint256 _dev, uint256 _marketing) external authorized {
        _reflectFee = _toReflect;
        _taxFee = _toTax;
        _feeDenominator = _denominator;
        _buybackSplit = _buyback;
        _communitySplit = _community;
        _devSplit = _dev;
        _marketingSplit = _marketing;
        require(_reflectFee + _taxFee < _feeDenominator / 4);
        emit FeesUpdated(_reflectFee, _taxFee, _buybackSplit, _communitySplit, _devSplit, _marketingSplit);
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator < 3 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
        emit BuybackMultiplierSettingsUpdated(numerator, denominator, length);
    }
    
    function setFeeExcluded(address holder, bool state) external onlyOwner {
        _isExcludedFromFee[holder] = state;
        emit FeeExcludedUpdated(holder, state);
    }
    
    function setExcludedFromTxLimit(address holder, bool state) external onlyOwner {
        _isExcludedFromTxLimit[holder] = state;
        emit TxLimitExcludedUpdated(holder, state);
    }

    function setMaxTxPercent(uint256 amount) external onlyOwner {
        require(amount >= _tTotal / 2000);
        _maxTxAmount = amount;
        emit MaxTxUpdated(amount);
    }

    function setSwapBack(uint256 _amount, bool _enabled) external authorized {
        swapBackAmount = _amount;
        swapBackEnabled = _enabled;
        emit SwapBackUpdated(_amount, _enabled);
    }
    
    function setFeeReceivers(address payable _communityReceiver, address payable _devReceiver, address payable _marketingReceiver) external onlyOwner {
        _communityFeeReceiver = _communityReceiver;
        _devFeeReceiver = _devReceiver;
        _marketingFeeReceiver = _marketingReceiver;
        emit FeeReceiversUpdated(_communityFeeReceiver, _devFeeReceiver, _marketingFeeReceiver);
    }
    
    function setProtection(IAntiSnipe _protection, address liquidityPair) external onlyOwner {
        protection = _protection;
        protection.initialize(liquidityPair);
    }
    
    function clearProtection(address holder) external onlyOwner {
        protect[holder] = false;
        emit Protected(holder, false);
    }
    
    function setLottery(IBurnLottery _lottery) external onlyOwner {
        lottery = _lottery;
        emit LotteryUpdated(_lottery);
    }
    
    function setBuyFeeOracle(IBuyFeeOracle _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }
    
    event Buyback(uint256 amount, bool triggerMultiplier);
    event BuybackMultiplierTriggered(uint256 length);
    event BuybackMultiplierCleared();
    event BuybackMultiplierSettingsUpdated(uint256 numerator, uint256 denominator, uint256 length);
    
    event Protected(address holder, bool state);
    event ProtectionDisabled();
    
    event LotteryUpdated(IBurnLottery newLottery);
    event OracleUpdated(IBuyFeeOracle newOracle);
    
    event SwapBackUpdated(uint256 amount, bool enabled);
    
    event FeesUpdated(uint256 _reflectFee, uint256 _taxFee, uint256 _buybackSplit, uint256 _communitySplit, uint256 _devSplit, uint256 _marketingSplit);
    event FeeReceiversUpdated(address payable _communityFeeReceiver, address payable _devFeeReceiver, address payable _marketingFeeReceiver);
    
    event FeeExcludedUpdated(address holder, bool state);
    event TxLimitExcludedUpdated(address holder, bool state);
    
    event MaxTxUpdated(uint256 amount);
}