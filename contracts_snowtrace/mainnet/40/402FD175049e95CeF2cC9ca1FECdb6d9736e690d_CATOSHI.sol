/**
 *Submitted for verification at snowtrace.io on 2022-01-05
*/

/*
1% Auto LP
1% Marketing
1% team
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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IJoeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter02  {
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

        function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);


}


abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract CATOSHI is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    string private constant _name = "CATOSHI";
    string private constant _symbol = "CATS";
    uint8 private constant _decimals = 18;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _tTotal = 6000000 * 10**18; // 6 million
    uint256 public _priceImpact = 2;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _maxWalletAmount;
    uint256 private _maxSellAmountAVAX = 50000000000000000000; // 50 AVAX
    uint256 private _minBuyAVAX = 0; //10000000000000000; // 0.01 AVAX
    uint256 private _minSellAVAX = 0; //10000000000000000; // 0.01 AVAX

    // fees
    uint256 public _liquidityFee = 1; // divided by 100
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _marketingFee = 1; // divided by 100
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 public _teamFee = 1; // divided by 100
    uint256 private _previousTeamFee = _teamFee;

    
    uint256 private _marketingPercent = 50;
    uint256 private _teamPercent = 50;

    struct FeeBreakdown {
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tTeam;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0xD0C15a69193711590977f77A7E4385b512e9ab7F);
    address payable private _teamAddress = payable(0x192d80DD06586FFB66465Fa3F7B3e326b9Bf7DCC);
    address private presaleRouter;
    address private presaleAddress;
    IJoeRouter02 private joeRouter;
    address public joePair;
    uint256 private _maxTxAmount;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private presale = true;
    bool private pairSwapped = false;
    bool public _priceImpactSellLimitEnabled = false;
    bool public _AVAXsellLimitEnabled = false;
    uint256 public _minTokenBeforeSwap = 1000 * 10**18;

    
    address public bridge;

    event EndedPresale(bool presale);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _teamPercent);
    event FeesUpdated(uint256 _marketingFee, uint256 _liquidityFee, uint256 _teamFee);
    event PriceImpactUpdated(uint256 _priceImpact);
    event ExcludedFromFees(address account);
    event IncludedInFees(address account);
    event MaxWalletAmountUpdated(uint256 amount);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(address _bridge) {
        IJoeRouter02 _joeRouter = IJoeRouter02(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);//avax testnet 0x3A5Ec4E77f1779901FA91dCD9e5Ad2418415f77e ; 0x5db0735cf88F85E78ed742215090c465979B5006
        joeRouter = _joeRouter;
        _approve(address(this), address(joeRouter), _tTotal);
        joePair = IJoeFactory(_joeRouter.factory()).createPair(address(this), _joeRouter.WAVAX());
        IERC20(joePair).approve(address(joeRouter),type(uint256).max);

        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply
        _maxWalletAmount = _tTotal.div(1); // 100%
        _priceImpact = 100;

        bridge = _bridge;
        _balances[_bridge] = _tTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_bridge] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _bridge, _tTotal);
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
    
    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
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
        if (_marketingFee == 0 && _liquidityFee == 0 && _teamFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;

        
        _marketingFee = 0;
        _liquidityFee = 0;
        _teamFee = 0;
    }

    function setBotFee() private {
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;

        
        _marketingFee = 3;
        _liquidityFee = 20;
        _teamFee = 2;
    }
    
    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _teamFee = _previousTeamFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // calculate price based on pair reserves
    function getTokenPriceAVAX(uint256 amount) external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IJoePair(joePair).token0());//CATS
        IERC20Extented token1 = IERC20Extented(IJoePair(joePair).token1());//AVAX
        
        require(token0.decimals() != 0, "ERR: decimals cannot be zero");
        
        (uint112 Res0, uint112 Res1,) = IJoePair(joePair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IJoePair(joePair).token1());//CATS
            token1 = IERC20Extented(IJoePair(joePair).token0());//AVAX
            (Res1, Res0,) = IJoePair(joePair).getReserves();
        }

        uint res1 = Res1*(10**token0.decimals());
        return((amount*res1)/(Res0*(10**token0.decimals()))); // return amount of token1 needed to buy token0
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (from != owner() && to != owner() && !presale && from != address(this) && to != address(this) && from != bridge && to != bridge) {
            require(tradingOpen);
            if (from != presaleRouter && from != presaleAddress) {
                require(amount <= _maxTxAmount);
            }
            if (from == joePair && to != address(joeRouter)) {//buys

                if (block.timestamp <= _firstBlock.add(_botBlocks) && from != presaleRouter && from != presaleAddress) {
                    bots[to] = true;
                }
                
                uint256 avaxAmount = this.getTokenPriceAVAX(amount);
                
                require(avaxAmount >= _minBuyAVAX, "you must buy at least min AVAX worth of token");
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
            }
            
            if (!inSwap && from != joePair) { //sells, transfers
                require(!bots[from] && !bots[to]);
                
                uint256 avaxAmount = this.getTokenPriceAVAX(amount);
                
                require(avaxAmount >= _minSellAVAX, "you must sell at least the min AVAX worth of token");

                if (_AVAXsellLimitEnabled) {
                    
                    require(avaxAmount <= _maxSellAmountAVAX, "you cannot sell more than the max AVAX amount per transaction");

                }
                
                else if (_priceImpactSellLimitEnabled) {
                    
                    require(amount <= balanceOf(joePair).mul(_priceImpact).div(100)); // price impact limit

                }
                
                if(to != joePair) {
                    
                    require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");

                }

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > _minTokenBeforeSwap ) {

                    swapAndLiquify(contractTokenBalance);
                
                }
                uint256 contractAVAXBalance = address(this).balance;
                if (contractAVAXBalance > 0) {
                    sendAVAXToFee(address(this).balance);
                }
                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || presale) {
            takeFee = false;
        }

        else if (bots[from] || bots[to]) {
            setBotFee();
            takeFee = true;
        }

        if (presale) {
            require(from == owner() || from == presaleRouter || from == presaleAddress || from == bridge);
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForAVAX(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();
        _approve(address(this), address(joeRouter), tokenAmount);
        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 avaxAmount) private {
        _approve(address(this), address(joeRouter), tokenAmount);

        // add the liquidity
        joeRouter.addLiquidityAVAX{value: avaxAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              address(this),
              block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLPamount = _liquidityFee.mul(contractTokenBalance).div(_marketingFee.add(_teamFee).add(_liquidityFee));

        // split the contract balance into halves
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current AVAX balance.
        // this is so that we can capture exactly the amount of AVAX that the
        // swap creates, and not make the liquidity event include any AVAX that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for AVAX
        swapTokensForAVAX(otherHalf); // <- this breaks the AVAX -> HATE swap when swap+liquify is triggered

        // how much AVAX did we just swap into?
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);

        // add liquidity to pancakeswap
        addLiquidity(half, newBalance);
    }

    function sendAVAXToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _teamAddress.transfer(amount.mul(_teamPercent).div(100));
    }

    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForAVAX(contractBalance);
        }
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractAVAXBalance = address(this).balance;
        if (contractAVAXBalance > 0) {
            sendAVAXToFee(contractAVAXBalance);
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
        fees.tMarketing = amount.mul(_marketingFee).div(100);
        fees.tLiquidity = amount.mul(_liquidityFee).div(100);
        fees.tTeam = amount.mul(_teamFee).div(100);
        
        fees.tAmount = amount.sub(fees.tMarketing).sub(fees.tLiquidity).sub(fees.tTeam);
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tMarketing.add(fees.tLiquidity).add(fees.tTeam));
        
        emit Transfer(sender, recipient, fees.tAmount);
    }
    
    receive() external payable {}

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFees(account);
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
        emit IncludedInFees(account);
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
        emit MaxWalletAmountUpdated(_maxWalletAmount);
    }

    function setTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 teamFee) external onlyOwner() {
        uint256 totalFee = marketingFee.add(liquidityFee).add(teamFee);
        require(totalFee < 15, "Sum of fees must be less than 15%");

        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _teamFee = teamFee;
        
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        
        uint256 totalAVAXfees = _marketingFee.add(_teamFee);
        
        _marketingPercent = (_marketingFee.mul(100)).div(totalAVAXfees);
        _teamPercent = (_teamFee.mul(100)).div(totalAVAXfees);
        
        emit FeesUpdated(_marketingFee, _liquidityFee, _teamFee);
        emit PercentsUpdated(_marketingPercent,_teamPercent);
    }

    function updateMinTokenBeforeSwap(uint256 minTokenBeforeSwap) external onlyOwner() {
        _minTokenBeforeSwap = minTokenBeforeSwap;
        emit MinTokensBeforeSwapUpdated(_minTokenBeforeSwap);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function setPresaleRouterAndAddress(address router, address wallet) external onlyOwner() {
        presaleRouter = router;
        presaleAddress = wallet;
        excludeFromFee(presaleRouter);
        excludeFromFee(presaleAddress);
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
    
    function updateMinBuySellAVAX(uint256 minBuyAVAX, uint256 minSellAVAX) external onlyOwner() {
        require(minBuyAVAX <= 100000000000000000, "cant make the limit higher than 0.1 AVAX");
        require(minSellAVAX <= 100000000000000000, "cant make the limit higher than 0.1 AVAX");
        _minBuyAVAX = minBuyAVAX;
        _minSellAVAX = minSellAVAX;
    }
    
    function updateMaxSellAmountAVAX(uint256 maxSellAVAX) external onlyOwner() {
        require(maxSellAVAX >= 1000000000000000000, "cant make the limit lower than 1 AVAX");
        _maxSellAmountAVAX = maxSellAVAX;
    }
    
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
    }
    
    function updateTeamAddress(address payable teamAddress) external onlyOwner() {
        _teamAddress = teamAddress;
    }
    
    function enableAVAXsellLimit() external onlyOwner() {
        require(_AVAXsellLimitEnabled == false, "already enabled");
        _AVAXsellLimitEnabled = true;
        _priceImpactSellLimitEnabled = false;
    }
    
    function disableAVAXsellLimit() external onlyOwner() {
        require(_AVAXsellLimitEnabled == true, "already disabled");
        _AVAXsellLimitEnabled = false;
    }
    
    function enablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == false, "already enabled");
        _priceImpactSellLimitEnabled = true;
        _AVAXsellLimitEnabled = false;
    }
    
    function disablePriceImpactSellLimit() external onlyOwner() {
        require(_priceImpactSellLimitEnabled == true, "already disabled");
        _priceImpactSellLimitEnabled = false;
    }
}