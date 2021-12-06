/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

/*  
    Trolls Token t.me/TelegramOfTrolls
    The internet is full of trolls, and in the realm of crypto,
    the population is especially concentrated.
    Come visit us at t.me/TrollsOfTelegram and see what type of troll you are
    and get rewarded with Ethereum from the special wallet for those most active
    in telegram and/or the ones who exhibit the best troll repellent. 

    🏵$TROLLS🏵 Launch Dec 6, 2021
    Total Supply: 3,750,000,000
    Max Txn: 3% (122,500,000)
    Max Wallet: 5%
    💎10% Tax featuring an Auto LP and the TROLL TAX to feed the trolls of Telegram. 
     
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract Trolls is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Trolls";
    string private constant _symbol = "TROLLS";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _tTotal = 3750 * 1e6 * 10e9; // 3,750,000,000
    uint256 public _priceImpact = 2;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _maxWalletAmount;
    uint256 private _maxSellAmountETH = 5 * 1e9; // 5 ETH
    uint256 private _minBuyETH = 0; //1 * 1e7; // 0.01 ETH
    uint256 private _minSellETH = 0; //1 * 1e7; // 0.01 ETH

    // fees
    uint256 public _liquidityFee = 40; // divided by 1000
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _marketingFee = 40; // divided by 1000
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 public _trollFee = 10; // divided by 1000
    uint256 private _previousTrollFee = _trollFee;
    uint256 private _cardsFee = 10; // divided by 1000
    uint256 private _previousCardsFee = _cardsFee;
    uint256 public _burnFee = 0; // divided by 1000
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 private _marketingPercent = 750;
    uint256 private _trollPercent = 125;
    uint256 private _cardsPercent = 125;

    struct FeeBreakdown {
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tTroll;
        uint256 tCards;
        uint256 tBurn;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0xae54351e641C1E24efa98B56612B0f97aE4C53F6);
    address payable private _trollAddress = payable(0x2008FbC22476fE372A8a449a832CEa4e3b517B1c);
    address payable private _cards;
    address payable constant private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    address private presaleRouter;
    address private presaleAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _maxTxAmount;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private presale = true;
    bool private pairSwapped = false;
    bool public _priceImpactSellLimitEnabled = false;
    bool public _ETHsellLimitEnabled = false;

    event EndedPresale(bool presale);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _trollPercent, uint256 _cardsPercent);
    event FeesUpdated(uint256 _marketingFee, uint256 _liquidityFee, uint256 _trollFee, uint256 _cardsFee, uint256 _burnFee);
    event PriceImpactUpdated(uint256 _priceImpact);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(address cards) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply
        _maxWalletAmount = _tTotal.div(1); // 100%
        _priceImpact = 100;
        cards = _cards;
        
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function airdrop(address[] memory airdropWallets, uint256[] memory amounts) external onlyOwner returns (bool){
        require(airdropWallets.length < 200, "Can only airdrop 200 wallets per txn due to gas limits"); // allows for airdrop
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 amount = amounts[i];
            _transfer(msg.sender, wallet, amount);
        }
        return true;
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeAllFee() private {
        if (_marketingFee == 0 && _liquidityFee == 0 && _trollFee == 0 && _cardsFee == 0 && _burnFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTrollFee = _trollFee;
        _previousCardsFee = _cardsFee;
        _previousBurnFee = _burnFee;
        
        _marketingFee = 0;
        _liquidityFee = 0;
        _trollFee = 0;
        _cardsFee = 0;
        _burnFee = 0;
    }

    function setBotFee() private {
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTrollFee = _trollFee;
        _previousCardsFee = _cardsFee;
        _previousBurnFee = _burnFee;
        
        _marketingFee = 200;
        _liquidityFee = 300;
        _trollFee = 18;
        _cardsFee = 100;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _trollFee = _previousTrollFee;
        _cardsFee = _previousCardsFee;
        _burnFee = _previousBurnFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // calculate price based on pair reserves
    function getTokenPriceETH(uint256 amount) external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//Trolls
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//eth
        
        require(token0.decimals() != 0, "ERR: decimals cannot be zero");
        
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token1());//Trolls
            token1 = IERC20Extented(IUniswapV2Pair(uniswapV2Pair).token0());//eth
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }

        uint res1 = Res1*(10**token0.decimals());
        return((amount*res1)/(Res0*(10**token0.decimals()))); // return amount of token1 needed to buy token0
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (from != owner() && to != owner() && !presale && from != address(this) && to != address(this)) {
            require(tradingOpen);
            if (from != presaleRouter && from != presaleAddress) {
                require(amount <= _maxTxAmount);
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys

                if (block.timestamp <= _firstBlock.add(_botBlocks) && from != presaleRouter && from != presaleAddress) {
                    bots[to] = true;
                }
                
                uint256 ethAmount = this.getTokenPriceETH(amount);
                
                require(ethAmount >= _minBuyETH, "you must buy at least min ETH worth of token");
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
            }
            
            if (!inSwap && from != uniswapV2Pair) { //sells, transfers
                require(!bots[from] && !bots[to]);
                
                uint256 ethAmount = this.getTokenPriceETH(amount);
                
                require(ethAmount >= _minSellETH, "you must sell at least the min ETH worth of token");

                if (_ETHsellLimitEnabled) {
                    require(ethAmount <= _maxSellAmountETH, 'you cannot sell more than the max ETH amount per transaction');
                }
                
                else if (_priceImpactSellLimitEnabled) {
                    require(amount <= balanceOf(uniswapV2Pair).mul(_priceImpact).div(100)); // price impact limit
                }
                
                if(to != uniswapV2Pair) {
                    require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                }

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > 0) {
                    swapAndLiquify(contractTokenBalance);     
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || presale ) {
            takeFee = false;
        }

        else if (bots[from] || bots[to]) {
            setBotFee();
            takeFee = true;
        }

        if (presale) {
            require(from == owner() || from == presaleRouter || from == presaleAddress);
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
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
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLPamount = _liquidityFee.mul(contractTokenBalance).div(_marketingFee.add(_trollFee).add(_cardsFee).add(_liquidityFee));

        // split the contract balance into halves
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(otherHalf); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);
        
        addLiquidity(half, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        _trollAddress.transfer(amount.mul(_trollPercent).div(1000));
        _cards.transfer(amount.mul(_cardsPercent).div(1000));
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(1000));
    }

    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function manualSwap() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        _transferStandard(sender, recipient, amount);
        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        FeeBreakdown memory fees;
        fees.tMarketing = amount.mul(_marketingFee).div(1000);
        fees.tLiquidity = amount.mul(_liquidityFee).div(1000);
        fees.tTroll = amount.mul(_trollFee).div(1000);
        fees.tCards = amount.mul(_cardsFee).div(1000);
        fees.tBurn = amount.mul(_burnFee).div(1000);
        
        fees.tAmount = amount.sub(fees.tMarketing).sub(fees.tLiquidity).sub(fees.tTroll).sub(fees.tCards).sub(fees.tBurn);
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tMarketing.add(fees.tLiquidity).add(fees.tTroll).add(fees.tCards));
        _balances[_burnAddress] = _balances[_burnAddress].add(fees.tBurn);
        
        emit Transfer(sender, recipient, fees.tAmount);
    }
    
    receive() external payable {}

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount > _tTotal.div(10000), "Amount must be greater than 0.01% of supply");
        require(maxTxAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        require(maxWalletAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 trollFee, uint256 cardsFee, uint256 burnFee) external onlyOwner() {
        uint256 totalFee = marketingFee.add(liquidityFee).add(trollFee).add(cardsFee).add(burnFee);
        require(totalFee.div(10) < 50, "Sum of fees must be less than 50");

        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _trollFee = trollFee;
        _cardsFee = cardsFee;
        _burnFee = burnFee;
        
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTrollFee = _trollFee;
        _previousCardsFee = _cardsFee;
        _previousBurnFee = _burnFee;
        
        uint256 totalETHfees = _marketingFee.add(_trollFee).add(_cardsFee);
        
        _trollPercent = (_trollFee.mul(1000)).div(totalETHfees);
        _cardsPercent = (_cardsFee.mul(1000)).div(totalETHfees);
        
        emit FeesUpdated(_marketingFee, _liquidityFee, _trollFee, _cardsFee, _burnFee);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function endPresale(uint256 botBlocks) external onlyOwner() {
        require(presale == true, "presale already ended");
        presale = false;
        openTrading(botBlocks);
        emit EndedPresale(presale);
    }

    function updatePairSwapped(bool swapped) external onlyOwner() {
        pairSwapped = swapped;
    }
    
    function updateMinBuySellETH(uint256 minBuyETH, uint256 minSellETH) external onlyOwner() {
        require(minBuyETH <= 1e7, "cant make the limit higher than 0.1 ETH");
        require(minSellETH <= 1e7, "cant make the limit higher than 0.1 ETH");
        _minBuyETH = minBuyETH;
        _minSellETH = minSellETH;
    }
    
    function updateMaxSellAmountETH(uint256 maxSellETH) external onlyOwner() {
        require(maxSellETH >= 1e9, "cant make the limit lower than 1 ETH");
        _maxSellAmountETH = maxSellETH;
    }
    
    function updateCards(address payable cards) external onlyOwner() {
        _cards = cards;
    }
    
    function updateTrollAddress(address payable trollAddress) external onlyOwner() {
        _trollAddress = trollAddress;
    }
    
    function enableETHsellLimit() external onlyOwner() {
        require(_ETHsellLimitEnabled == false, "already enabled");
        _ETHsellLimitEnabled = true;
        _priceImpactSellLimitEnabled = false;
    }
    
    function disableETHsellLimit() external onlyOwner() {
        require(_ETHsellLimitEnabled == true, "already disabled");
        _ETHsellLimitEnabled = false;
    }
    
    function enablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == false, "already enabled");
        _priceImpactSellLimitEnabled = true;
        _ETHsellLimitEnabled = false;
    }
    
    function disablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == true, "already disabled");
        _priceImpactSellLimitEnabled = false;
    }
}