import './safeMath.sol';
import './IERC20.sol';
import './address.sol';
import './pancake.sol';
import './context.sol';

pragma solidity ^ 0.6 .12;
// SPDX-License-Identifier: MIT



contract Fipi is Context, IERC20, Ownable {
    using SafeMath
    for uint256;
    using Address
    for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    mapping (address => uint256) private _amountSold;
    mapping (address => uint) private _timeSinceFirstSell;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);

    uint256 private constant _tTotal = 21 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "FipiCoinBeta";
    string private constant _symbol = "Fipi";
    uint8 private constant _decimals = 9;


    //FEES 2% REFLECTION, 2% LP, 2% BURN, 2% LOTTERY POOL, ALL 2%
    uint256 public _taxFee = 2;
    uint256 private _feeMultiplier = 1;

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    function setLiquidity(bool b) external onlyOwner() {
        swapAndLiquifyEnabled = b;
    }

    uint256 private _tBurnTotal;

    uint256 private maxTokensSellToAddtoLiquidity = numTokensSellToAddToLiquidity * 10 ** 2;
    uint256 private numTokensSellToAddToLiquidity = 5 * 10 ** 5 * 10 ** 9;

    address payable public _LiquidityReciever;
    address payable public _BurnWallet = payable(0x000000000000000000000000000000000000dEaD);


    bool public _enableLottery = false;

    function setLottery(bool b) external onlyOwner() {
        _enableLottery = b;
    }

    uint256 private _lotteryPool = 0;

    uint public _lotteryChance = 25;

    function setLotteryChance(uint chance) external onlyOwner() {
        _lotteryChance = chance;
    }

    uint256 public _lotteryThreshold = 1 * 10 ** 5 * 10 ** 9;

    function setLotteryThreshold(uint256 threshold) external onlyOwner() {
        _lotteryThreshold = threshold;
    }

    function setTokensSellToAddToLiquidity(uint256 numTokens) external onlyOwner() {
        numTokensSellToAddToLiquidity = numTokens;
    }

    uint256 public _lotteryMinimumSpend = 1 * 10 ** 3 * 10 ** 9;

    function setLotteryMinimumSpend(uint256 minimumSpend) external onlyOwner() {
        _lotteryMinimumSpend = minimumSpend;
    }

    address public _previousWinner;
    uint256 public _previousWonAmount;
    uint public _previousWinTime;
    uint public _lastRoll;
    uint256 private _nonce;

    uint256 public _whaleSellThreshold = 1 * 10**5 * 10**9;

    function setWhaleSellThreshold(uint256 amount) external onlyOwner() {
        _whaleSellThreshold = amount;
    }

    event LotteryAward(
        address winner,
        uint256 amount,
        uint time
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    event Burn(address BurnWallet, uint256 tokensBurned);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {

        _rOwned[_msgSender()] = _rTotal;
        _LiquidityReciever = payable(_msgSender());

        // mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        pancakeRouter = _pancakeRouter;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcluded[_BurnWallet] = true;
        _excluded.push(_BurnWallet);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns(string memory) {
        return _name;
    }

    function symbol() public pure returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns(uint256) {
        return _tTotal;
    }

    

    function balanceOf(address account) public view override returns(uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    override
    returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns(bool) {
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
    returns(bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account)
    external
    view
    returns(bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns(uint256) {
        return _tFeeTotal;
    }

    function totalBurnFee() external view returns(uint256) {
        return _tBurnTotal;
    }

    function getBurnWallet() external view returns(address) {
        return _BurnWallet;
    }
    
    function previousWonAmount() public view returns(uint256) {
        return _previousWonAmount;
    }

    function lotteryPool() public view returns(uint256) {
        return _lotteryPool;
    }

    //Added some , for the get values since its returning more variables now
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    external
    view
    returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        if (!deductTransferFee) {
            uint256 rAmount = tAmount.mul(currentRate);
            return rAmount;
        } else {
            (uint256 tTransferAmount, ) = _getTValues(tAmount);
            uint256 rTransferAmount = tTransferAmount.mul(currentRate);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
    public
    view
    returns(uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
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

    function getLotteryTokens() public view returns(uint256) {
        return tokenFromReflection(_lotteryPool);
    }

    function calculateLotteryReward() private returns(uint256) {
        // If the transfer is a buy, and the lottery pool is above a certain token threshold, start to award it
        uint256 reward = 0;
        uint256 lotteryTokens = getLotteryTokens();
        if (lotteryTokens >= _lotteryThreshold) {

            _nonce++;
            uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % 1000);
            r = r.add(1);
            _lastRoll = r;

            if (_lastRoll <= _lotteryChance) {
                reward = lotteryTokens;
            }
        }
        return reward;
    }


    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    

    //Added tBurn to function 
    function _getTValues(uint256 tAmount)
    private
    view
    returns(
        uint256,
        uint256
    ) {
        uint256 tFee = tAmount.mul(_taxFee * _feeMultiplier).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFee).sub(tFee).sub(tFee);
        return (tTransferAmount, tFee);
    }



    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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


    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[_BurnWallet] = _rOwned[_BurnWallet].add(rBurn);
        if (_isExcluded[_BurnWallet])
            _tOwned[_BurnWallet] = _tOwned[_BurnWallet].add(tBurn);
        _tBurnTotal = _tBurnTotal.add(tBurn);
    }


    function _takeToLottery(uint256 tLottery) private {
        uint256 currentRate = _getRate();
        uint256 rLottery = tLottery.mul(currentRate);
        _lotteryPool = _lotteryPool.add(rLottery);
    }


    //Added burn fee to remove all fee and restore all fee
    function removeAllFee() private {
        _feeMultiplier = 0;
    }

    function restoreAllFee() private {
        _feeMultiplier = 1;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
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



        if (_enableLottery && amount >= _lotteryMinimumSpend && from == pancakePair) {
            uint256 lotteryReward = calculateLotteryReward();
            if (lotteryReward > 0) {
                if (_isExcluded[to]) {
                    _tOwned[to] = _tOwned[to].add(lotteryReward);
                }
                _rOwned[to] = _rOwned[to].add(_lotteryPool);
                _lotteryPool = 0;
                _previousWinner = to;
                _previousWonAmount = lotteryReward;
                _previousWinTime = block.timestamp;
                emit LotteryAward(to, lotteryReward, block.timestamp);
                emit Transfer(address(this), to, lotteryReward);
            }
        }


        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTokensSellToAddtoLiquidity) {
            contractTokenBalance = maxTokensSellToAddtoLiquidity;
        }

        bool overMinTokenBalance =
            contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee && to == pancakePair) {
            uint timeDiffBetweenNowAndSell = block.timestamp.sub(_timeSinceFirstSell[from]);
            uint256 newTotal = _amountSold[from].add(amount);
            if (timeDiffBetweenNowAndSell > 0 && timeDiffBetweenNowAndSell < 86400 && _timeSinceFirstSell[from] != 0) {
                if (newTotal > _whaleSellThreshold) {
                    _feeMultiplier = 2; 
                }
                _amountSold[from] = newTotal;
            } else if (_timeSinceFirstSell[from] == 0 && newTotal > _whaleSellThreshold) {
                _feeMultiplier = 2;
                _amountSold[from] = newTotal;
            } else {
                _timeSinceFirstSell[from] = block.timestamp;
                _amountSold[from] = amount;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
        _feeMultiplier = 1;
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
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    //Changed reciever to LiquidityReciever to generate income for the project when ownership is rennounced
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH {
            value: ethAmount
        }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _LiquidityReciever,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        (
            
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getTValues(amount);
        
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {

            _tOwned[sender] = _tOwned[sender].sub(amount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {

            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

            _tOwned[sender] = _tOwned[sender].sub(amount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else {

            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        }

        _takeLiquidity(tFee);
        _takeBurn(tFee);
        _reflectFee(rFee, tFee);
        _takeToLottery(tFee);
        if (_taxFee > 0) {
            emit Transfer(sender, _BurnWallet, tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);

        if (!takeFee) restoreAllFee();
    }

    //Added function to withdraw leftoever BNB in the contract from addtoLiquidity function
    function withDrawLeftoverBNB() public {
        require(_msgSender() == _LiquidityReciever, "Only the liquidity reciever can use this function!");
        _LiquidityReciever.transfer(address(this).balance);
    }
}