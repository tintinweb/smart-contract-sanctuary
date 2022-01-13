// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1100000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "TokenT";
    string private _symbol = "TKN";
    uint8 private _decimals = 9;

    uint256 B_taxFee = 2;
    uint256 S_taxFee = 2;
    uint256 W_taxFee = 2;
    uint256 _taxFee; //main
    uint256 _previousTaxFee = _taxFee;

    uint256 B_Marketing = 2;
    uint256 S_Marketing = 2;
    uint256 W_Marketing = 2;
    uint256 _Marketing; //main
    uint256 _previousMarketingFee = _Marketing;

    uint256 B_ServiceFee = 2;
    uint256 S_ServiceFee = 2;
    uint256 W_ServiceFee = 2;
    uint256 _ServiceFee; //main
    uint256 _previousServiceFee = _ServiceFee;

    uint256 B_liquidityFee = 2;
    uint256 S_liquidityFee = 2;
    uint256 W_liquidityFee = 2;
    uint256 _liquidityFee; //main
    uint256 _previousLiquidityFee = _liquidityFee;

    uint256 B_BurnFee = 2;
    uint256 S_BurnFee = 2;
    uint256 W_BurnFee = 2;
    uint256 _BurnFee; //main
    uint256 _previousBurnFee = _BurnFee;
    bool takeFee;

    address public MarketingAdd = 0x2199ffcf8903d3395240Eb772Caeb0990562b37B;
    address public ServiceAdd = 0xedDd6173C9E3511e1d881275A5e1489A56583B84;
    address private Dead = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 500000000000 * 10**9;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event Purchase(address indexed to, uint256 amount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[owner()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
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

    function setMarketingAdd(address addr) external onlyOwner {
        MarketingAdd = addr;
    }

    function setLiquidityFeePercent_Buy(
        uint256 liquidityFee,
        uint256 service,
        uint256 Marketing,
        uint256 burnFee,
        uint256 taxFee
    ) external onlyOwner {
        B_ServiceFee = service;
        B_Marketing = Marketing;
        B_BurnFee = burnFee;
        B_taxFee = taxFee;
        B_liquidityFee = liquidityFee;
    }

    function setSellFees(
        uint256 liquidityFee,
        uint256 service,
        uint256 Marketing,
        uint256 burnFee,
        uint256 taxFee
    ) external onlyOwner {
        S_liquidityFee = liquidityFee;
        S_ServiceFee = service;
        S_Marketing = Marketing;
        S_taxFee = taxFee;
        S_BurnFee = burnFee;
    }

    function setNormalFees(
        uint256 liquidityFee,
        uint256 service,
        uint256 Marketing,
        uint256 burnFee,
        uint256 taxFee
    ) external onlyOwner {
        W_liquidityFee = liquidityFee;
        W_ServiceFee = service;
        W_BurnFee = burnFee;
        W_taxFee = taxFee;
        W_Marketing = Marketing;
    }

    function setRouter(address router) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Brain: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "Brain: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxTx(uint256 maxTx) external onlyOwner {
        _maxTxAmount = maxTx;
    }

    function num2Add2LP(uint256 num2Add2Liquidity) external onlyOwner {
        numTokensSellToAddToLiquidity = num2Add2Liquidity;
    }

    //to recieve ETH from uniswapV2Router when swaping

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    struct tValues {
        uint256 tFee;
        uint256 tMarketing;
        uint256 tLiquidity;
        uint256 tburn;
        uint256 tservice;
        uint256 tTransferAmount;
    }

    tValues TV;

    struct rValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
    }

    rValues RV;

    function _getValues(uint256 tAmount)
        private
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        _getTValues(tAmount);
        _getRValues(tAmount, _getRate());
        return (
            RV.rAmount,
            RV.rTransferAmount,
            RV.rFee,
            TV.tTransferAmount,
            TV.tFee,
            TV.tMarketing,
            TV.tLiquidity,
            TV.tburn,
            TV.tservice
        );
    }

    function _getTValues(uint256 tAmount) private {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tService = calculateServiceFee(tAmount);
        uint256 tTransferAmount = tFee
            .sub(tMarketing)
            .sub(tLiquidity)
            .sub(tBurn)
            .sub(tService);
        tValues memory m = tValues(
            tFee,
            tMarketing,
            tLiquidity,
            tBurn,
            tService,
            tTransferAmount
        );
        TV = m;
    }

    function _getRValues(uint256 tAmount, uint256 currentRate) private {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = TV.tFee.mul(currentRate);
        uint256 rMarketing = TV.tMarketing.mul(currentRate);
        uint256 rLiquidity = TV.tLiquidity.mul(currentRate);
        uint256 rBurn = TV.tburn.mul(currentRate).add(
            TV.tservice.mul(currentRate)
        );
        uint256 rTransferAmount = rAmount
            .sub(rFee)
            .sub(rMarketing)
            .sub(rLiquidity)
            .sub(rBurn);
        rValues memory m = rValues(rAmount, rTransferAmount, rFee);
        RV = m;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
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

    function _Cal(
        uint256 Marketing,
        uint256 service,
        uint256 burn
    ) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = Marketing.mul(currentRate);
        uint256 rService = service.mul(currentRate);
        uint256 rBurn = burn.mul(currentRate);
        _rOwned[MarketingAdd] = _rOwned[MarketingAdd].add(rMarketing);
        _rOwned[ServiceAdd] = _rOwned[ServiceAdd].add(rService);
        _rOwned[Dead] = _rOwned[Dead].add(rBurn);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_Marketing).div(10**2);
    }

    function calculateServiceFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_ServiceFee).div(10**2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_BurnFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (
            _taxFee == 0 &&
            _Marketing == 0 &&
            _liquidityFee == 0 &&
            _ServiceFee == 0 &&
            _BurnFee == 0
        ) return;

        _previousTaxFee = _taxFee;
        _previousMarketingFee = _Marketing;
        _previousServiceFee = _ServiceFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _BurnFee;

        _taxFee = 0;
        _Marketing = 0;
        _ServiceFee = 0;
        _liquidityFee = 0;
        _BurnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _Marketing = _previousMarketingFee;
        _ServiceFee = _previousServiceFee;
        _liquidityFee = _previousLiquidityFee;
        _BurnFee = _previousBurnFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        if (automatedMarketMakerPairs[to]) {
            //on sell
            _taxFee = S_taxFee;
            _BurnFee = S_BurnFee;
            _Marketing = S_Marketing;
            _ServiceFee = S_ServiceFee;
            _liquidityFee = S_liquidityFee;
        } else if (automatedMarketMakerPairs[from]) {
            //on buy
            _taxFee = B_taxFee;
            _BurnFee = B_BurnFee;
            _Marketing = B_Marketing;
            _ServiceFee = B_ServiceFee;
            _liquidityFee = B_liquidityFee;
        } else {
            _taxFee = W_taxFee;
            _BurnFee = W_BurnFee;
            _Marketing = W_Marketing;
            _ServiceFee = W_ServiceFee;
            _liquidityFee = W_liquidityFee;
        }
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
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
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFees
    ) private {
        if (!takeFees) removeAllFee();

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
        if (!takeFees) restoreAllFee();
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tMarketing,
            uint256 tLiquidity,
            uint256 tburn,
            uint256 tservice
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _Cal(tMarketing, tservice, tburn);
        _reflectFee(rFee, tFee);
        if (tMarketing > 0) {
            emit Transfer(sender, MarketingAdd, tMarketing);
        }
        if (tservice > 0) emit Transfer(sender, ServiceAdd, tservice);
        if (tburn > 0) emit Transfer(sender, Dead, tburn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tMarketing,
            uint256 tLiquidity,
            uint256 tburn,
            uint256 tservice
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _Cal(tMarketing, tservice, tburn);
        _reflectFee(rFee, tFee);
        if (tMarketing > 0) {
            emit Transfer(sender, MarketingAdd, tMarketing);
        }
        if (tservice > 0) emit Transfer(sender, ServiceAdd, tservice);
        if (tburn > 0) emit Transfer(sender, Dead, tburn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tMarketing,
            uint256 tLiquidity,
            uint256 tburn,
            uint256 tservice
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _Cal(tMarketing, tservice, tburn);
        _reflectFee(rFee, tFee);
        if (tMarketing > 0) {
            emit Transfer(sender, MarketingAdd, tMarketing);
        }
        if (tservice > 0) emit Transfer(sender, ServiceAdd, tservice);
        if (tburn > 0) emit Transfer(sender, Dead, tburn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tMarketing,
            uint256 tLiquidity,
            uint256 tburn,
            uint256 tservice
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _Cal(tMarketing, tservice, tburn);
        _reflectFee(rFee, tFee);
        if (tMarketing > 0) {
            emit Transfer(sender, MarketingAdd, tMarketing);
        }
        if (tservice > 0) emit Transfer(sender, ServiceAdd, tservice);
        if (tburn > 0) emit Transfer(sender, Dead, tburn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function test(uint256 T) public {
        if (T == 1) {
            B_taxFee = 3;
            B_Marketing = 3;
            B_ServiceFee = 3;
            B_liquidityFee = 3;
            B_BurnFee = 3;
        } else if (T == 2) {
            S_taxFee = 1;
            S_Marketing = 1;
            S_ServiceFee = 1;
            S_liquidityFee = 1;
            S_BurnFee = 1;
        } else {
            W_taxFee = 2;
            W_ServiceFee = 2;
            W_liquidityFee = 2;
            W_BurnFee = 2;
            W_Marketing = 2;
        }
    }
}