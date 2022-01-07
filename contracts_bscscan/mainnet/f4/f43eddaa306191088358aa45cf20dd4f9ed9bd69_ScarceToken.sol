// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Context.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter.sol";

// SRC Token with Governance.
contract ScarceToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned; //balances
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;

    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    address public _feeAddress;
    address public _tokenDistContract;

    uint256 private _tTotal = 50000*10**18;
    uint256 private _tFeeTotal;

    string private constant _name     = "Scarce Protocol";
    string private constant _symbol   = "SRC";
    uint8  private constant _decimals = 18;

    // transfer fee
    uint256 public  _taxFee       = 0; // tax fee is reflections
    uint256 public  _liquidityFee = 0; // ZERO tax for transfering tokens
    uint256 public  _burnFee = 0;

    // buy fee
    uint256 public  _taxFeeBuy       = 0;
    uint256 public  _liquidityFeeBuy = 0;
    uint256 public  _burnFeeBuy = 0;

    // sell fee
    uint256 public  _taxFeeSell       = 10;
    uint256 public  _liquidityFeeSell = 4;
    uint256 public  _burnFeeSell = 1;

    uint256 public  _minTokenBalance = _tTotal.div(200);
    
    // auto liquidity
    IPancakeRouter02 public PancakeRouter;
    address public PancakePair;
    address public PancakePairBusd;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // Tracker for one time setting of Pancakerouter if things go wrong during deployment.
    bool public RouterInit;
    // Tracker for one time setting of Pancakepairs.
    bool public PairsInit;

    constructor (
        address feeAddress,
        address tokenDistContract
    ) public {
        _tOwned[_msgSender()] = _tTotal;
        _feeAddress = feeAddress;
        _tokenDistContract = tokenDistContract;
        
        // pancakeswap
        IPancakeRouter02 _PancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        PancakePair = IPancakeFactory(_PancakeRouter.factory()).createPair(address(this), _PancakeRouter.WETH());
        PancakeRouter = _PancakeRouter;
        
        // exclude system contracts
        _isExcludedFromFee[owner()]       = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_tokenDistContract] = true;

        _isExcludedFromAutoLiquidity[PancakePair]            = true;
        _isExcludedFromAutoLiquidity[PancakePairBusd]            = true;
        _isExcludedFromAutoLiquidity[address(PancakeRouter)] = true;
        _isExcludedFromAutoLiquidity[_tokenDistContract] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        // to reflect burned amount in total supply
        // return _tTotal - balanceOf(_burnAddress);

        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance'));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function setExcludedFromFee(address account, bool e) external onlyOwner {
        _isExcludedFromFee[account] = e;
    }

    function setMinTokenBalance(uint256 minTokenBalance) external onlyOwner {
        _minTokenBalance = minTokenBalance;
    }

    function setFeesTransfer(uint taxFee, uint liquidityFee, uint burnFee) external onlyOwner {
        require(taxFee <= 15, "invalid deposit tax fee basis points");
        require(liquidityFee <= 10, "invalid deposit liquidity fee basis points");
        require(burnFee <= 5, "invalid deposit burn fee basis points");
        _taxFee       = taxFee;
        _liquidityFee = liquidityFee;
        _burnFee      = burnFee;
        
    }

    function setFeesBuy(uint taxFee, uint liquidityFee, uint burnFee) external onlyOwner {
        require(taxFee <= 15, "invalid deposit tax fee basis points");
        require(liquidityFee <= 10, "invalid deposit liquidity fee basis points");
        require(burnFee <= 5, "invalid deposit burn fee basis points");
        _taxFeeBuy       = taxFee;
        _liquidityFeeBuy = liquidityFee;
        _burnFeeBuy      = burnFee;
    }

    function setFeesSell(uint taxFee, uint liquidityFee, uint burnFee) external onlyOwner {
        require(taxFee <= 15, "invalid deposit tax fee basis points");
        require(liquidityFee <= 10, "invalid deposit liquidity fee basis points");
        require(burnFee <= 5, "invalid deposit burn fee basis points");
        _taxFeeSell       = taxFee;
        _liquidityFeeSell = liquidityFee;
        _burnFeeSell      = burnFee;
    }

    function setAddresses(address feeAddress, address tokenDistContract) external onlyOwner {
        _feeAddress       = feeAddress;
        _tokenDistContract = tokenDistContract;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    receive() external payable {}

    function setPancakeRouter(address r) external onlyOwner {
    require (RouterInit == false,"Already initialized!");
        IPancakeRouter02 _PancakeRouter = IPancakeRouter02(r);
        PancakeRouter = _PancakeRouter;
        RouterInit = true;
    }

    function setPancakePairs(address p, address pbusd) external onlyOwner {
        require (PairsInit == false,"Already initialized!");
        PancakePair = p;
        PancakePairBusd = pbusd;
        PairsInit = true;
    }

    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedFromAutoLiquidity[a] = b;
    }
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee       = calculateFee(tAmount, _taxFee);
        uint256 tLiquidity = calculateFee(tAmount, _liquidityFee);
        uint256 tBurn      = calculateFee(tAmount, _burnFee);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }
    
    function takeTransactionFee(address sender, address to, uint256 tAmount) private {
        if (tAmount == 0) { return; }

        _tOwned[to] = _tOwned[to].add(tAmount);

        emit Transfer(sender, to, tAmount);
    }
    
    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
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

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is Pancake pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool isOverMinTokenBalance = contractTokenBalance >= _minTokenBalance;
        if (
            isOverMinTokenBalance &&
            !inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _minTokenBalance;
            swapAndLiquify(contractTokenBalance);
        }

        
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 half      = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForBnb(half);

        uint256 bnbForLiquidity = address(this).balance.sub(initialBalance);
        
        (uint256 tokenAdded, uint256 bnbAdded) = addLiquidity(otherHalf, bnbForLiquidity);
        
        emit SwapAndLiquify(half, bnbAdded, tokenAdded);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeRouter.WETH();

        _approve(address(this), address(PancakeRouter), tokenAmount);

        // make the swap
        PancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private returns (uint256, uint256) {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(PancakeRouter), tokenAmount);

        // add the liquidity
        (uint amountToken, uint amountETH, ) = PancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _feeAddress,
            block.timestamp
        );
        return (uint256(amountToken), uint256(amountETH));
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 previousTaxFee       = _taxFee;
        uint256 previousLiquidityFee = _liquidityFee;
        uint256 previousBurnFee      = _burnFee;
        
        bool isBuy  = (sender == PancakePair || sender == PancakePairBusd) && recipient != address(PancakeRouter);
        bool isSell = recipient == PancakePair || recipient == PancakePairBusd;
        
        if (!takeFee) {
            _taxFee       = 0;
            _liquidityFee = 0;
            _burnFee      = 0;

        } else if (isBuy) { 
            _taxFee       = _taxFeeBuy;
            _liquidityFee = _liquidityFeeBuy;
            _burnFee      = _burnFeeBuy;

        } else if (isSell) { 
            _taxFee       = _taxFeeSell;
            _liquidityFee = _liquidityFeeSell;
            _burnFee      = _burnFeeSell;
        }
        
        _transferStandard(sender, recipient, amount);
        
        if (!takeFee || isBuy || isSell) {
            _taxFee       = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
            _burnFee      = previousBurnFee;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        takeTransactionFee(sender, _tokenDistContract, tFee);
        takeTransactionFee(sender, address(this), tLiquidity);
        takeTransactionFee(sender, _burnAddress, tBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }   
}