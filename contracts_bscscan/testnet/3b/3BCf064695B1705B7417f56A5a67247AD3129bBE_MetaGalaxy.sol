/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^ 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IBEP20 {
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

    constructor () {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeV2Router  {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract MetaGalaxy is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }

    mapping(address => User) private cooldown;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => mapping(address => uint256)) private _allowances;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Meta Galaxy";
    string private _symbol = "MGY";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 9; //(2% liquidityAddition + 3% rewardsDistribution + 5% devExpenses)
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private minTokensBeforeSwap = 8;

    address[] public tokenHolder;
    uint256 public numberOfTokenHolders;
    mapping(address => bool) public exist;

    mapping(address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;

    // limit
    uint256 public _maxTxAmount;
    address payable wallet;
    address payable rewardsWallet;
    IPancakeV2Router public pancakeV2Router;
    address public pancakePair;
    uint256 private buyLimitEnd;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool tradingOpen;
    bool private _cooldownEnabled;
    
    address private constant PANCAKE_SWAP_ADDR = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event CooldownEnabledUpdated(bool _cooldown);
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

   constructor (address payable addr1, address payable addr2, address payable addr3)  {
        _rOwned[_msgSender()] = _rTotal;

        wallet = addr1;
        rewardsWallet = addr2;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[addr3] = true;
        _isExcludedFromFee[wallet] = true;
        _isExcludedFromFee[rewardsWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");

        IPancakeV2Router _pancakeRouter = IPancakeV2Router(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //* Test router
        pancakeV2Router = _pancakeRouter;
        _approve(address(this), address(pancakeV2Router), _tTotal);
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        pancakeV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxTxAmount =  250000000000 * 10 ** 9; //.5% after 95% burn
        swapAndLiquifyEnabled = true;
        _cooldownEnabled = true;
        
        tradingOpen = true;
        IBEP20(pancakePair).approve(address(pancakeV2Router), type(uint).max);
    }

    // @dev set Router
    
    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    // Black List Management
    // function isBlackListed(address account) public view returns(bool) {
    //     return _isBlackListedBot[account];
    // }

    // // Bots/Blacklist  management
    // function addBotToBlackList(address account) public onlyOwner() {
    //     require(account != PANCAKE_SWAP_ADDR, "Can't blacklist router.");
    //     _isBlackListedBot[account] = true;
    //     _blackListedBots.push(account);
    // }

    // function removeBotFromBlackList(address account) external onlyOwner() {
    //     require(_isBlackListedBot[account], "Account is not blacklisted");
    //     _isBlackListedBot[account] = false;
    //     _blackListedBots.pop();
    // }
    // function blacklistMultipleWallets(address[] calldata addresses) public onlyOwner(){
    //     for (uint256 i; i < addresses.length; ++i) {
    //         addBotToBlackList(addresses[i]);
    //     }
    // }

    // function unBlacklistSingleWallet(address addresses) external onlyOwner(){
    //     _isBlackListedBot[addresses] = false;
    // }

    // function unBlacklistMultipleWallets(address[] calldata addresses) public onlyOwner(){
    //     for (uint256 i; i < addresses.length; ++i) {
    //         _isBlackListedBot[addresses[i]] = false;
    //     }
    // }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: amount exceeds")); // amount exceeds allowance
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: allowance < 0")); // decreased allowance below zero
        return true;
    }

    function isExcludedFromReward(address account) public view returns(bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns(uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses no allowed");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, "We can not exclude pancake router.");
        require(!_isExcluded[account], "Account already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account already excluded");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    bool public limit = true;
    function changeLimit() public onlyOwner(){
        require(limit == true, "limit is already false");
        limit = false;
        buyLimitEnd = block.timestamp + (60 seconds);
    }

    function expectedRewards(address _sender) external view returns(uint256){
        uint256 _balance = address(this).balance;
        address sender = _sender;
        uint256 holdersBal = balanceOf(sender);
        uint totalExcludedBal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            totalExcludedBal = balanceOf(_excluded[i]).add(totalExcludedBal);
        }
        uint256 rewards = holdersBal.mul(_balance).div(_tTotal.sub(balanceOf(pancakePair)).sub(totalExcludedBal));
        return rewards;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: No zero address allowed");
        require(to != address(0), "BEP20:  No zero address allowed");
        require(amount > 0, "Tranfer amount<= 0");
        require(!_isBlackListedBot[to], "Not Allowed!");
        require(!_isBlackListedBot[from], "Not Allowed!");

        if (limit == true && from != owner() && to != owner() && !_isExcludedFromFee[to]) {
            if (to != pancakePair) {
                require(((balanceOf(to).add(amount)) <= 500 ether));
            }
            require(amount <= 100 ether, "Amount must be < 100 tokens");
        }
        if (from != owner() && to != owner() && !_isExcludedFromFee[to]) {
            if (_cooldownEnabled) {
                if (!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0, 0, true);
                }
            }
        }

        // buy
        if (from == pancakePair && to != address(pancakeV2Router) && !_isExcludedFromFee[to]) {
            if (buyLimitEnd > block.timestamp) {
                require(amount <= _maxTxAmount);
                require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                cooldown[to].buy = block.timestamp + (30 seconds);
            }
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don"t get caught in a circular liquidity event.
        // also, don"t swap & liquify if sender is pancake pair.
        if (!exist[to]) {
            tokenHolder.push(to);
            numberOfTokenHolders++;
            exist[to] = true;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;

        if ( overMinTokenBalance &&  !inSwapAndLiquify &&
            from != pancakePair &&  swapAndLiquifyEnabled) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 forLiquidity = contractTokenBalance.div(3);
        uint256 devExp = contractTokenBalance.div(3);
        uint256 forRewards = contractTokenBalance.div(3);
        // split the liquidity
        uint256 half = forLiquidity.div(2);
        uint256 otherHalf = forLiquidity.sub(half);
        // capture the contract"s current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half.add(devExp).add(forRewards)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 Balance = address(this).balance.sub(initialBalance);
        uint256 oneThird = Balance.div(3);
        wallet.transfer(oneThird);
        rewardsWallet.transfer(oneThird);

        // add liquidity to pancake
        addLiquidity(otherHalf, oneThird);

        emit SwapAndLiquify(half, oneThird, otherHalf);
    }

    function BNBBalance() external view returns(uint256){
        return address(this).balance;
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // add the liquidity
        pancakeV2Router.addLiquidityETH{ value: ethAmount } (
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
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns(uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns(uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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

    function calculateTaxFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_taxFee).div(
            10 ** 2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee <= 10, "Max limit is 10%");
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee <= 10, "Max fee is 10%");
        _liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent <= 10, "Max tax 10%");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10 ** 2
        );
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function manualswap() external {
        require(_msgSender() == rewardsWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        uint256 contractETHBalance = address(this).balance;
        sendETHToMarketing(contractETHBalance);
    }

    function sendETHToMarketing(uint256 amount) private {
        wallet.transfer(amount.div(2));
        rewardsWallet.transfer(amount.div(2));
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function timeToBuy(address buyer) public view returns(uint) {
        return block.timestamp - cooldown[buyer].buy;
    }

    //to recieve ETH from pancakeV2Router when swaping
    receive() external payable { }
}