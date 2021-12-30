import './safeMath.sol';
import './IERC20.sol';
import './address.sol';
import './pancake.sol';
import './context.sol';

pragma solidity ^0.6.12;
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

    string private constant _name = "FiPi BEDZIE GIT";
    string private constant _symbol = "FiPiGit";
    uint8 private constant _decimals = 9;

     uint256 private _tBurnTotal;
    address payable public _LiquidityReciever;
    address payable public _BurnWallet = payable(0x000000000000000000000000000000000000dEaD);
    address payable public _marketingAddress = payable(0x4B01143107498CBa025Dc13C4283D5f4034016DC);


    //FEES 2% REFLECTION, 2% LP, 2% BURN, 2% LOTTERY POOL, ALL 2%
    uint256 public _taxFee = 2;
    uint256 private _feeMultiplier = 1;

    //LP
    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;
    uint256 public lPThreshold = 5 * 10 ** 4 * 10 ** 9;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    
    function setLPThreshold(uint256 numTokens) external onlyOwner() {
        lPThreshold = numTokens;
    }

    //ANTI_SNIPER FOR LAUNCH
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    bool public antisniperEnabled = true;
    uint256 private gasPriceLimit;
    mapping (address => uint256) private lastTrade;
    bool public tradingPaused = true;

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 100);
        gasPriceLimit = gas * 1 gwei;
    }

    function setAntisniperEnabled(bool _antisniperEnabled) external onlyOwner() {
        antisniperEnabled = _antisniperEnabled;
    }

    function enableTrading() external onlyOwner {
        tradingPaused = false;
    }

    //WHALE-RESTICTION
    uint256 private _maxWalletSizePromile = 20;
    uint256 private _sellMaxTxAmountPromile = 5;
    uint256 public _whaleSellThreshold = 1 * 10 ** 5 * 10**9;

    function setMaxWalletSize(uint256 promile) external onlyOwner() {
        require(promile >= 20); // Cannot set lower than 2%
        _maxWalletSizePromile = promile;
    }

    function setSellMaxTxAmountPromile(uint256 promile) external onlyOwner() {
        require(promile >= 1); // Cannot set lower than 0.1%
        _sellMaxTxAmountPromile = promile;
    }

    
    function setWhaleSellThreshold(uint256 amount) external onlyOwner() {
        require(amount >= _whaleSellThreshold);// Whale threshold can only be increased, we dont want to have a possibility to set tax 16% to everyone
        _whaleSellThreshold = amount;
    }

    function setMarketingAddress(address marketingAddress) external onlyOwner() {
        _marketingAddress = payable(marketingAddress);
    }

    


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
        // pancaketestnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        pancakeRouter = _pancakeRouter;
        gasPriceLimit = 10 * 1 gwei;
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
        require(!_isExcluded[account], "Account is already excluded");
        //max number of excluded accounts is 1000, there is a loop over _excluded, and we dont want to push gas prize to high. it doesnt metter, couse we dont want to exclude any one anyway.
        if(_excluded.length < 1000){
            if (_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        //excluded length is max 1000
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

 
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
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
        //excluded length is max 1000
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


    function isNormalTransfer(address from, address to) private view returns (bool) {
        return 
            to != _BurnWallet
            && to != address(0)
            && from != address(this)
            && _isExcludedFromFee[to] == false
            && _isExcludedFromFee[from] == false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //IF THERE IS NOW LIQUIDITY YET AND ITS OWNER TRANSFER (OR LAUNCH PAD EXCLUDED FROM FEE) TO PANCAKE ITS LISING INIT TRANSACTION AND WE MARK IT 
        if(!_hasLiqBeenAdded && _isExcludedFromFee[from] && to == pancakePair){
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
            _liqAddStamp = block.timestamp;
            swapAndLiquifyEnabled = true;
        }

        if(antisniperEnabled)
        {
            if (!_hasLiqBeenAdded && isNormalTransfer(from, to)){
                revert("Only wallets marked by owner as excluded can transfer at this time."); //launchpads etc
            }
            else if(isNormalTransfer(from, to)){
                //LIMIT GAS PRIZE TO PREVENT SNIPERS
                require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                //THERE IS A POSSIBILITY TO HOLD TRADING AFTER LISTING FOR A WHILE
                require (tradingPaused == false, "Trading not yet enabled.");
                if (from == pancakePair){
                    //CHECK IS NEXT TRANSACTION IS ON THE SAME BLOCK AS LAST TRANSACTION, AND IF SO BLOCK
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                }
                else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= lPThreshold;
        if (overMinTokenBalance && !inSwapAndLiquify && from != pancakePair && swapAndLiquifyEnabled) 
        {
            swapAndLiquify(lPThreshold);
        }
        _feeMultiplier = 1;

        //IF PRIVILIDGED WALLET, NO FEES
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            _feeMultiplier = 0;
        }
        //FIRST THREE BLOCKS AFTER LISTING WE WILL ADD EXTRA FEE FOR SNIPERS
        else if((block.number <= _liqAddBlock + 2) && antisniperEnabled){
            _feeMultiplier = 5;
        }
        //IF SELL ON PANCAKE 
        else if (to == pancakePair) {
            //MAX SELL IS SET INITIALLY TO 0,5% OF TOTAL SUPPLY
            require(amount <= _tTotal.mul(_sellMaxTxAmountPromile).div(1000), "Transfer amount exceeds the sellMaxTxAmount.");

            //ANTI-WHALE TAX IF YOU SELL TOO MUCH IN A DAY, YOU GET TAX x2
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
        //IF IT'S NOT A SELL AND WALLET IS NOT PRIVILIDGED SO THE RECIPENT IS PRIVATE WALLET OF INVESTOR WE CHECK IF WE DONT HAVE TO MUCH 
        else if(to != pancakePair) {
            uint256 contractBalanceRecepient = balanceOf(to);
            uint256 maxWalletSize = _tTotal.mul(_maxWalletSizePromile).div(1000);
            require(contractBalanceRecepient + amount <= maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
        }
        _tokenTransfer(from, to, amount);
        _feeMultiplier = 1;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
       
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

        
        if (tFee > 0) {
            _takeLiquidity(tFee * 2); //HERE COMES TIMES 2 BECAUSE ITS ALSO MARKETING
            _takeBurn(tFee);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, _BurnWallet, tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        // 0,25 is still in TOKENS
        uint256 quater = contractTokenBalance.div(4);
        
        //0,75 will be converted to BNB
        uint256 threeQuaters = contractTokenBalance.sub(quater);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(threeQuaters);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        //now we need 1/3 of this 0,75 swapped and pair with 0,25
        uint256 halfNewBalance = newBalance.div(3);
        addLiquidity(quater, halfNewBalance);
        uint256 leftForMarketing = newBalance.sub(halfNewBalance);

        _marketingAddress.transfer(leftForMarketing);
        emit SwapAndLiquify(threeQuaters, newBalance, quater);

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

    //reciever to LiquidityReciever to generate income for the project when ownership is rennounced
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

    
    //Added function to withdraw leftoever BNB in the contract from addtoLiquidity function
    function withDrawLeftoverBNB() public {
        require(_msgSender() == _LiquidityReciever, "Only the liquidity reciever can use this function!");
        _LiquidityReciever.transfer(address(this).balance);
    }

   
}