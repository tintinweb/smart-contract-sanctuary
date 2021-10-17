// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.0;

/* Pikachu Inu:
* 1 Quadrillion supply
*
*Fees on tx: 10%
*Reflections: 2%
*Liquidity: 3%
*Marketing (in eth) : 5%
*
*Maxtx on buy: 0.1% of supply
*MaxTx on sell: 0.1% of supply
* 
*(fees and maxtx amounts can be changed after deployment, check the values of their variables on read section) 
*/

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Address.sol";

contract PikachuInu is Context, IERC20, Ownable {

    using Address for address payable;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 10**15 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTxAmountBuy = _tTotal/1000; // 0.1% of supply (1T tokens)
    uint256 public maxTxAmountSell = _tTotal/1000; // 0.1% of supply (1T tokens)


    address payable public marketingAddress;

    mapping (address => bool) public isAutomatedMarketMakerPair;

    string private constant _name = "Pikachu Inu";
    string private constant _symbol = "PIKACHU";

    bool private inSwapAndLiquify;

    IUniswapV2Router02 public UniswapV2Router;
    address public uniswapPair;
    bool public swapAndLiquifyEnabled = true;
    uint256 public numTokensSellToAddToLiquidity = _tTotal/500;

    struct feeRatesStruct {
      uint8 rfi;
      uint8 marketing;
      uint8 autolp;
      uint8 toSwap;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {
      rfi: 2,    //autoreflection rate, in %
      marketing: 5, //marketing fee in % (in ETH)
      autolp: 3, // autolp rate in %
      toSwap: 8 // marketing + autolp
    });

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 toSwap;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rToSwap;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tToSwap;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ETHReceived, uint256 tokensIntotoSwap);
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);


    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_UniswapV2Router.factory())
                            .createPair(address(this), _UniswapV2Router.WETH());
        isAutomatedMarketMakerPair[uniswapPair] = true;
        emit SetAutomatedMarketMakerPair(uniswapPair, true);
        UniswapV2Router = _UniswapV2Router;
        _rOwned[owner()] = _rTotal;
        marketingAddress= payable(msg.sender);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingAddress]=true;
        _isExcludedFromFee[address(this)]=true;        

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
      swapAndLiquifyEnabled = _enabled;
      emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //  @dev receive ETH from UniswapV2Router when swapping
    receive() external payable {}

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeToSwap(uint256 rToSwap,uint256 tToSwap) private {
        _rOwned[address(this)] +=rToSwap;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] += tToSwap;
        totFeesPaid.toSwap+=tToSwap;
        
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rToSwap) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*feeRates.rfi/100;
        s.tToSwap = tAmount*feeRates.toSwap/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tToSwap;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rToSwap) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rToSwap = s.tToSwap*currentRate;
        rTransferAmount =  rAmount-rRfi-rToSwap;
        return (rAmount, rTransferAmount, rRfi,rToSwap);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -=_rOwned[_excluded[i]];
            tSupply -=_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        if(takeFee)
        {
            if(isAutomatedMarketMakerPair[from])
            {
                require(amount<=maxTxAmountBuy, "amount must be <= maxTxAmountBuy");
            }
            else
            {
                require(amount<=maxTxAmountSell, "amount must be <= maxTxAmountSell");
            }
        }

        if (balanceOf(address(this)) >= numTokensSellToAddToLiquidity  && !inSwapAndLiquify && !isAutomatedMarketMakerPair[from] && swapAndLiquifyEnabled) {
            //add liquidity
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender]) {
                _tOwned[sender] -= tAmount;
        } 
        if (_isExcluded[recipient]) {
                _tOwned[recipient] += s.tTransferAmount;
        }

        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] += s.rTransferAmount;
        if(takeFee)
        {
        _reflectRfi(s.rRfi, s.tRfi);
        _takeToSwap(s.rToSwap,s.tToSwap);
        emit Transfer(sender, address(this), s.tToSwap);
        }
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 denominator = feeRates.toSwap*2;
        uint256 tokensToAddLiquidityWith = contractTokenBalance*feeRates.autolp/denominator;
        uint256 toSwap = contractTokenBalance-tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance -initialBalance;
        uint256 ETHToAddLiquidityWith = deltaBalance*feeRates.autolp/ (denominator- feeRates.autolp);
        
        // add liquidity to  Uniswap
        addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        
        marketingAddress.sendValue(address(this).balance); //we give the remaining tax to marketing (5/8 of the toSwap tax)
    }

    function swapTokensForETH(uint256 tokenAmount) private {

        // generate the Pancakeswap pair path of token -> wETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        if(allowance(address(this), address(UniswapV2Router)) < tokenAmount) {
          _approve(address(this), address(UniswapV2Router), ~uint256(0));
        }

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {

        // add the liquidity
        UniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, ETHAmount);
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) external onlyOwner{
        require(isAutomatedMarketMakerPair[_pair] != value, "Automated market maker pair is already set to that value");
        isAutomatedMarketMakerPair[_pair] = value;
        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    function setFees(uint8 _rfi,uint8 _marketing,uint8 _autolp) external onlyOwner
    {
     feeRates.rfi=_rfi;
     feeRates.marketing=_marketing;
     feeRates.autolp=_autolp;
     feeRates.toSwap= _marketing+_autolp;
    }

    function setMaxTransactionAmountsPerK(uint256 _maxTxAmountBuyPer10K, uint256 _maxTxAmountSellPer10K) external onlyOwner
    {
     maxTxAmountBuy = _tTotal*_maxTxAmountBuyPer10K/10000;
     maxTxAmountSell = _tTotal*_maxTxAmountSellPer10K/10000;
    }
    
    function setNumTokensSellToAddToLiq(uint256 amountTokens) external onlyOwner
    {
     numTokensSellToAddToLiquidity = amountTokens*10**_decimals;
    }

    function setMarketingAddress(address payable _marketingAddress) external onlyOwner
    {
        marketingAddress = _marketingAddress;
    }

}