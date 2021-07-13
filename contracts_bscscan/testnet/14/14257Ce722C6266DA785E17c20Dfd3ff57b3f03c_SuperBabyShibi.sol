pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import './Context.sol';
import './IERC20.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './Address.sol';
import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';

contract SuperBabyShibi is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address FOMO = address(3);
    address payable public marketingAddress;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _addressExists;

    address[] private _addressList;
    address[] private _excluded;
    address[] public waitFomoWinnerList;

    struct Data {
        uint rAmount;
        uint tTransferAmount;
        uint rTransferAmount;
        uint tFee;
        uint tFomo;
        uint tLiquidity;
        uint tMarketing;
    }

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public launchedAt;

    string private _name = "SuperBabyShibi";
    string private _symbol = "SuperBabyShibi";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 50000;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _fomoFee = 40000;
    uint256 private _previousFomoFee = _fomoFee;

    uint256 public _liquidityFee = 30000;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingFee = 20000;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _buyTaxFee = 60000;
    uint256 public _buyFomoFee = 40000;
    uint256 public _buyLiquidityFee = 20000;
    uint256 public _buyMarketingFee = 20000;

    uint256 public _sellTaxFee = 80000;
    uint256 public _sellFomoFee = 60000;
    uint256 public _sellLiquidityFee = 30000;
    uint256 public _sellMarketingFee = 30000;

    uint256 public feeDenominator = 1000000;
    uint256 public minFomoJoinValue = 10;
    //    uint256 public minFomoJoinValue = 5 * 10 ** 18;

    uint256 public lastBuyTime = 1;
    uint256  fomoGameIntervalTime = 1 hours;
    uint256  rewardPercent = 50;
    uint256 fomoWinnerNumber = 10;


    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;


    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    bool inSwap;
    bool public swapEnabled = true;

    uint256 public _maxTxAmount = 5000000 * 10 ** 6 * 10 ** 9;
    uint256 private swapThreshold = 500000 * 10 ** 6 * 10 ** 9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event JoinFomoGame(address to);
    event WinFomo(address winner, uint reward);

    modifier swapping {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;

        address _router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[FOMO] = true;
        isTxLimitExempt[_router] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[FOMO] = true;
        _isExcludedFromFee[_router] = true;

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

    function shouldSwap(address to) internal view returns (bool) {
        return to == uniswapV2Pair
        && !inSwap
        && swapEnabled
        && balanceOf(address(this)) >= swapThreshold;
    }

    function checkTxLimit(address sender, address to, uint256 amount) public {
        if (launchedAt + 3 > block.number) {isBlacklisted[sender] = true;}
        if (block.number > launchedAt + 3) {require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[to]
        , "TX Limit Exceeded");}
    }

    function canJoinFomo(address from, address to, uint amount) private view returns (bool can){
        return fomoPoolBalance() > 0 &&
        from == uniswapV2Pair &&
        to != address(uniswapV2Router) &&
        valueThan(amount, minFomoJoinValue) && !to.isContract();
    }

    function fomoPoolBalance() public view returns (uint){
        return balanceOf(FOMO);
    }

    function valueThan(uint256 amount, uint usdtValue) public view returns (bool can){
        can = false;
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDT;
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        if (amounts.length > 0) {
            can = amounts[amounts.length - 1] >= usdtValue;
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        uint256 rAmount = _getValues(tAmount).rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = _getValues(tAmount).rAmount;
            return rAmount;
        } else {
            uint256 rTransferAmount = _getValues(tAmount).rTransferAmount;
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function setRewardPercent(uint percent) external {
        require(percent >= 0 && percent <= 100, "invalid reward percent");
        rewardPercent = percent;
    }

    function setIsBlacklisted(address[] calldata accounts, bool flag) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBlacklisted[accounts[i]] = flag;
        }
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10 ** 2
        );
    }

    function setFomoWinnerNumber(uint256 _fomoWinnerNumber) external onlyOwner() {
        fomoWinnerNumber = _fomoWinnerNumber;
    }

    function setSwapThreshold(uint256 _swapThreshold) external onlyOwner() {
        swapThreshold = _swapThreshold;
    }

    function setFomoGameIntervalTime(uint256 _fomoGameIntervalTime) external onlyOwner() {
        fomoGameIntervalTime = _fomoGameIntervalTime;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 tFee) private {
        _rTotal = _rTotal.sub(tFee.mul(_getRate()));
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (Data memory) {
        uint currentRate = _getRate();
        Data memory data;
        data.tFee = calculateAnyFee(tAmount, _taxFee);
        data.tFomo = calculateAnyFee(tAmount, _fomoFee);
        data.tLiquidity = calculateAnyFee(tAmount, _liquidityFee);
        data.tMarketing = calculateAnyFee(tAmount, _marketingFee);

        data.tTransferAmount = tAmount.sub(data.tFee).sub(data.tFomo).sub(data.tLiquidity).sub(data.tMarketing);
        data.rAmount = tAmount.mul(currentRate);
        data.rTransferAmount = data.tTransferAmount.mul(currentRate);
        return data;
    }


    function settleFomo() private {
        uint _now = block.timestamp;
        if (lastBuyTime > 0 && _now - lastBuyTime > fomoGameIntervalTime) {
            uint total = getWaitingWinnersTotal();
            address[] memory winners = waitFomoWinnerList;
            uint gameReward = fomoPoolBalance().mul(rewardPercent).div(100);
            for (uint i = 0; i < winners.length; i++) {
                address winner = winners[i];
                uint reward = gameReward.mul(balanceOf(winner)).div(total);
                _tokenTransfer(FOMO, winner, reward, false);
                emit WinFomo(winner, reward);
            }
            delete waitFomoWinnerList;
        }
    }

    function getWaitingWinnersTotal() public view returns (uint){
        uint total = 0;
        address[] memory winners = waitFomoWinnerList;
        for (uint i = 0; i < winners.length; i++) {
            total = total + balanceOf(winners[i]);
        }
        return total;
    }


    function addWaitWinner(address to) private {
        //refresh list
        refreshWaitWinnerList();
        lastBuyTime = block.timestamp;
        waitFomoWinnerList.push(to);
        emit JoinFomoGame(to);
    }

    function refreshWaitWinnerList() private {
        if (waitFomoWinnerList.length >= fomoWinnerNumber) {
            remove(0);
        }
    }

    function remove(uint index) private {
        if (index >= waitFomoWinnerList.length) return;
        for (uint i = index; i < waitFomoWinnerList.length - 1; i++) {
            waitFomoWinnerList[i] = waitFomoWinnerList[i + 1];
        }
        waitFomoWinnerList.pop();
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

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

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeFomo(uint256 tFomo) private {
        uint256 currentRate = _getRate();
        uint256 rFomo = tFomo.mul(currentRate);
        _rOwned[FOMO] = _rOwned[FOMO].add(rFomo);
        if (_isExcluded[FOMO])
            _tOwned[FOMO] = _tOwned[FOMO].add(tFomo);
    }

    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rMarketing);
        if (_isExcluded[marketingAddress])
            _tOwned[marketingAddress] = _tOwned[marketingAddress].add(tMarketing);
    }

    function calculateAnyFee(uint256 _amount, uint256 fee) private view returns (uint256) {
        return _amount.mul(fee).div(feeDenominator);
    }

    function removeAllFee() private {
        if (
            _taxFee == 0 &&
            _fomoFee == 0 &&
            _liquidityFee == 0 &&
            _marketingFee == 0
        ) return;

        _previousTaxFee = _taxFee;
        _previousFomoFee = _fomoFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;

        _taxFee = 0;
        _fomoFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _fomoFee = _previousFomoFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function waitFomoWinnerListLength() public view returns (uint){
        return waitFomoWinnerList.length;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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
        require(!isBlacklisted[from]);
        if (inSwap) {return _tokenTransfer(from, to, amount, false);}

        checkTxLimit(from, to, amount);

        if (shouldSwap(to)) {swapAndLiquify();}

        if (!launched() && to == uniswapV2Pair) {require(balanceOf(from) > 0);
            launch();}

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                removeAllFee();
                _taxFee = _buyTaxFee;
                _fomoFee = _buyFomoFee;
                _liquidityFee = _buyLiquidityFee;
                _marketingFee = _buyMarketingFee;
            }
            // Sell
            if (to == uniswapV2Pair) {
                removeAllFee();
                _taxFee = _sellTaxFee;
                _fomoFee = _sellFomoFee;
                _liquidityFee = _sellLiquidityFee;
                _marketingFee = _sellMarketingFee;
            }
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        settleFomo();
        if (canJoinFomo(from, to, amount)) {
            addWaitWinner(to);
        }
    }

    function addAddress(address adr) private {
        if (adr.isContract() ||
        adr == uniswapV2Pair ||
        adr == address(uniswapV2Router) ||
        adr == address(this) ||
        adr == DEAD ||
            adr == ZERO
        ) return;
        if (_addressExists[adr])
            return;
        _addressExists[adr] = true;
        _addressList.push(adr);
    }

    function swapAndLiquify() private swapping {
        uint contractTokenBalance = swapThreshold;
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
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
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

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

        if (!takeFee)
            restoreAllFee();
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        Data memory data = _getValues(tAmount);
        uint256 rAmount = data.rAmount;
        uint256 tTransferAmount = data.tTransferAmount;
        uint256 rTransferAmount = data.rTransferAmount;
        uint256 tFee = data.tFee;
        uint256 tFomo = data.tFomo;
        uint256 tLiquidity = data.tLiquidity;
        uint256 tMarketing = data.tMarketing;

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeFomo(tFomo);
        _takeMarketing(tMarketing);
        _reflectFee(tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        Data memory data = _getValues(tAmount);
        uint256 rAmount = data.rAmount;
        uint256 tTransferAmount = data.tTransferAmount;
        uint256 rTransferAmount = data.rTransferAmount;
        uint256 tFee = data.tFee;
        uint256 tFomo = data.tFomo;
        uint256 tLiquidity = data.tLiquidity;
        uint256 tMarketing = data.tMarketing;

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeFomo(tFomo);
        _takeMarketing(tMarketing);
        _reflectFee(tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        Data memory data = _getValues(tAmount);
        uint256 rAmount = data.rAmount;
        uint256 tTransferAmount = data.tTransferAmount;
        uint256 rTransferAmount = data.rTransferAmount;
        uint256 tFee = data.tFee;
        uint256 tFomo = data.tFomo;
        uint256 tLiquidity = data.tLiquidity;
        uint256 tMarketing = data.tMarketing;

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeFomo(tFomo);
        _takeMarketing(tMarketing);
        _reflectFee(tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        Data memory data = _getValues(tAmount);
        uint256 rAmount = data.rAmount;
        uint256 tTransferAmount = data.tTransferAmount;
        uint256 rTransferAmount = data.rTransferAmount;
        uint256 tFee = data.tFee;
        uint256 tFomo = data.tFomo;
        uint256 tLiquidity = data.tLiquidity;
        uint256 tMarketing = data.tMarketing;

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeFomo(tFomo);
        _takeMarketing(tMarketing);
        _reflectFee(tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }


}