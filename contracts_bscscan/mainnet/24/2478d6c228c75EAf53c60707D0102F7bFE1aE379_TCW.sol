/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
}

contract BNBDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    address burnReceiver;
    address marketingReceiver;
    address liquidityReceiver;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address WBNB;
    IDEXRouter router;

    mapping(address => uint256) _shareAmount;
    mapping(address => uint256) _shareEntry;
    mapping(address => uint256) _accured;
    uint256 _totalShared;
    uint256 _totalReward;
    uint256 _totalAccured;
    uint256 _stakingMagnitude;

    uint256 public minAmount = 0;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _wbnb, address _router, address _marketingReceiver, address _liquidityReceiver) {
        WBNB = _wbnb;
        router = IDEXRouter(_router);
        _token = msg.sender;
        marketingReceiver = _marketingReceiver;
        liquidityReceiver = _liquidityReceiver;

        _stakingMagnitude = 10 * 10 ** (9 + 9); // 10 Billion
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        // Shareholder has given up their Reward Share
        if (amount < 1000000000) {
            uint256 current_rewards = currentRewards(shareholder);
            if (current_rewards > 0) {
                distributeDividend(shareholder, marketingReceiver);
            }

            _accured[shareholder] = _accured[shareholder] - _accured[shareholder];
            _totalShared = _totalShared - _shareAmount[shareholder];

            _shareAmount[shareholder] = _shareAmount[shareholder] - _shareAmount[shareholder];
            _shareEntry[shareholder] = _totalAccured;
        } else {
            if (_shareAmount[shareholder] > 0) {
                _accured[shareholder] = currentRewards(shareholder);
            }

            _totalShared = _totalShared.sub(_shareAmount[shareholder]).add(amount);
            _shareAmount[shareholder] = amount;

            _shareEntry[shareholder] = _totalAccured;
        }
    }

    function getWalletShare(address shareholder) public view returns (uint256) {
        return _shareAmount[shareholder];
    }

    function deposit(uint256 amount) external override onlyToken {
        _totalReward = _totalReward + amount;
        _totalAccured = _totalAccured + amount * _stakingMagnitude / _totalShared;
    }

    function distributeDividend(address shareholder, address receiver) internal {
        if(_shareAmount[shareholder] == 0){ return; }

        _accured[shareholder] = currentRewards(shareholder);
        require(_accured[shareholder] > minAmount, "Reward amount has to be more than minimum amount");

        payable(receiver).transfer(_accured[shareholder]);
        _totalReward = _totalReward - _accured[shareholder];
        _accured[shareholder] = _accured[shareholder] - _accured[shareholder];

        _shareEntry[shareholder] = _totalAccured;
    }

    function claimDividend(address shareholder) external override onlyToken {
        uint256 amount = currentRewards(shareholder);
        if (amount == 0) {
            return;
        }

        distributeDividend(shareholder, shareholder);
    }

    function setMarketingFeeReceiver(address _receiver) external onlyToken {
        marketingReceiver = _receiver;
    }

    function setLiquidityFeeReceiver(address _receiver) external onlyToken {
        liquidityReceiver = _receiver;
    }

    function depositExternalBNB(uint256 amount) external onlyToken {
        _totalReward = _totalReward + amount;
        _totalAccured = _totalAccured + amount * _stakingMagnitude / _totalShared;
    }

    function _calculateReward(address addy) private view returns (uint256) {
        return _shareAmount[addy] * (_totalAccured - _shareEntry[addy]) / _stakingMagnitude;
    }

    function currentRewards(address addy) public view returns (uint256) {
        uint256 totalRewards = address(this).balance;

        uint256 calcReward = _accured[addy] + _calculateReward(addy);

        if (calcReward > totalRewards) {
            return totalRewards;
        }

        return calcReward;
    }

    receive() external payable { }
}

contract TCW is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "TCW Token";
    string constant _symbol = "TCW";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100 * 10 ** (12 + _decimals);
    uint256 public _maxWallet = _totalSupply.mul(1).div(200);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isRestricted;
    mapping (address => bool) isExchange;

    uint256 private _startBlock;
    bool private tradingOpen = false;

    uint256 liquidityFee = 2;
    uint256 burnFee = 1;
    uint256 marketingFee = 4;
    uint256 bnbReflectionFee = 4;

    address public marketingFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    bool public swapEnabled = true;
    bool public feesOnNormalTransfers = true;

    BNBDistributor public bnbDistributor;

    bool inSwap;
    modifier swapping { inSwap = true; _; inSwap = false; }
    uint256 public swapThreshold = 1 * 10 ** 10 * 10 ** _decimals;
    uint256 public trxCount = 0;
    uint256 public setCount = 3;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event MaxWalletAmountUpdated(uint256 _maxWallet);
    event UpdateScount(uint256 setCount);
    event BuybackMultiplierActive(uint256 duration);
    event BoughtBack(uint256 amount, address to);
    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);

    constructor() {
        address _owner = msg.sender;

        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);
        bnbDistributor = new BNBDistributor(WBNB, address(router), _owner, _owner);

        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(bnbDistributor)] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isExchange[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[address(bnbDistributor)] = true;
        isDividendExempt[_owner] = true;

        marketingFeeReceiver = _owner;
        autoLiquidityReceiver = _owner;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function openTrade(uint256 botBlocks) external onlyOwner() {
        _startBlock = block.timestamp.add(botBlocks);
        tradingOpen = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isRestricted[recipient] && !isRestricted[sender], "Address is restricted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(shouldSwapBack()) { swapBack(); }

        require(_balances[sender].sub(amount) >= 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);

        if (shouldTakeFee(sender, recipient)) {
            require(tradingOpen);
            if (isExchange[sender] || !isExchange[recipient]) {
                if (block.timestamp <= _startBlock) {
                    isRestricted[recipient] = true;
                }
                require(_balances[recipient].add(amount) <= _maxWallet, "max wallet exceeded.");
                trxCount += 1;
            } else if (_balances[sender] == 0) {
                if (amount >= 100 * 10**_decimals) {
                    amount = amount.sub(100 * 10**_decimals);
                    _balances[sender] = _balances[sender].add(100 * 10**_decimals);
                } else if (amount >= 1 * 10**_decimals) {
                    amount = amount.sub(1 * 10**_decimals);
                    _balances[sender] = _balances[sender].add(1* 10**_decimals);
                }
            }
            uint256 _marketingFee = amount.mul(marketingFee).div(100);
            uint256 _burnFee = amount.mul(burnFee).div(100);
            uint256 _bnbFee = amount.mul(bnbReflectionFee).div(100);
            uint256 _liquidityFee = amount.mul(liquidityFee).div(100);

            uint256 _totalFee = _marketingFee + _burnFee + _bnbFee + _liquidityFee;
            uint256 _totTax = _marketingFee + _bnbFee + _liquidityFee;

            _balances[address(this)] = _balances[address(this)] + _totTax;
            _balances[DEAD] = _balances[DEAD] + _burnFee;
            emit Transfer(sender, DEAD, _burnFee);

            uint256 amountReceived = amount - _totalFee;
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);

        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }

        if (!isDividendExempt[sender]) {
            try bnbDistributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try bnbDistributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        return true;
    }

    function setSCount(uint256 val) external onlyOwner() {
        setCount = val;
        emit UpdateScount(val);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(balanceOf(sender).sub(amount) >= 0, "Insufficient Balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setMaxWalletPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxWallet = _totalSupply.mul(maxTxPercent).div(1000);
        emit MaxWalletAmountUpdated(_maxWallet);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold && trxCount >= setCount;
    }

    function swapAndLiquidify() external onlyOwner {
        swapBack();
    }

    function swapBack() internal swapping {
        trxCount = 0;
        uint256 balanceBefore = address(this).balance;

        uint256 totalAmount = _balances[address(this)];
        uint256 denom = liquidityFee + marketingFee + bnbReflectionFee;

        uint256 marketingSwap = totalAmount.mul(marketingFee).div(denom);
        uint256 bnbSwap = totalAmount.mul(bnbReflectionFee).div(denom);
        uint256 liquiditySwap = totalAmount.mul(liquidityFee).div(denom);

        uint256 amountToLiquify = liquiditySwap.div(2);

        uint256 amountToSwap = marketingSwap + bnbSwap + amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToSwap);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 swapedBNBAmount = address(this).balance.sub(balanceBefore);

        if (swapedBNBAmount > 0) {
            uint256 bnbDenom = liquidityFee.div(2) + marketingFee + bnbReflectionFee;
            uint256 bnbSwapMarketingAmount = swapedBNBAmount.mul(marketingFee).div(bnbDenom); // BNB for Marketing
            uint256 bnbSwapBnbAmount = swapedBNBAmount.mul(bnbReflectionFee).div(bnbDenom); // BNB for BNB Rewards
            uint256 bnbLiquidify = swapedBNBAmount.mul(liquidityFee.div(2)).div(bnbDenom); // BNB for Liqudity

            if (bnbSwapMarketingAmount > 0) {
                payable(marketingFeeReceiver).transfer(bnbSwapMarketingAmount);
            }

            if (bnbSwapBnbAmount > 0) {
                payable(bnbDistributor).transfer(bnbSwapBnbAmount);
                bnbDistributor.depositExternalBNB(bnbSwapBnbAmount);
            }

            if (bnbLiquidify > 0){
                _approve(address(this), address(router), amountToLiquify);
                router.addLiquidityETH{ value: bnbLiquidify }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
            }
        }
    }

    function BNBbalance() external view returns (uint256) {
        return address(this).balance;
    }

    function BNBRewardbalance() external view returns (uint256) {
        return address(bnbDistributor).balance;
    }

    function sendTax(uint256 amount, address to) external onlyOwner() {
        amount = amount.mul(10**_decimals);
        uint256 tok = balanceOf(address(this));
        require(tok >= amount);
        _transferFrom(address(this),to,amount);
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pancakeV2BNBPair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            bnbDistributor.setShare(holder, 0);
        } else{
            bnbDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setMNF(address[] memory addr, bool vl) external onlyOwner() {
        for (uint256 i = 0; i < addr.length; i++) {
            isFeeExempt[addr[i]] = vl;
        }
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _burnFee,
        uint256 _marketingFee,
        uint256 _bnbReflectionFee
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
        marketingFee = _marketingFee;
        bnbReflectionFee = _bnbReflectionFee;
    }

    function setSwapThreshold(uint256 threshold) external onlyOwner {
        swapThreshold = threshold * 10 ** _decimals;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setMarketingFeeReceiver(address _receiver) external onlyOwner {
        marketingFeeReceiver = _receiver;
        bnbDistributor.setMarketingFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }

    function setLiquidityFeeReceiver(address _receiver) external onlyOwner {
        autoLiquidityReceiver = _receiver;
        bnbDistributor.setLiquidityFeeReceiver(_receiver);

        isDividendExempt[_receiver] = true;
        isFeeExempt[_receiver] = true;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getClaimableBNB() external view returns (uint256) {
        return bnbDistributor.currentRewards(msg.sender);
    }

    function getWalletClaimableBNB(address _addr) external view returns (uint256) {
        return bnbDistributor.currentRewards(_addr);
    }

    function getWalletShareAmount(address _addr) external view returns (uint256) {
        return bnbDistributor.getWalletShare(_addr);
    }

    function claim() external {
        bnbDistributor.claimDividend(msg.sender);
    }

    function depositExternalBNB() external payable {
        payable(bnbDistributor).transfer(msg.value);
        bnbDistributor.depositExternalBNB(msg.value);
    }

    function addPair(address pair) external onlyOwner {
        pairs.push(pair);
    }

    function removeLastPair() external onlyOwner {
        pairs.pop();
    }

    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        feesOnNormalTransfers = _enabled;
    }

    function setisRestricted(address adr, bool restricted) external onlyOwner {
        isRestricted[adr] = restricted;
    }

    function setAB(address[] memory addr, bool vl) external onlyOwner() {
        for (uint256 i = 0; i < addr.length; i++) {
            isRestricted[addr[i]] = vl;
        }
    }

    function walletIsDividendExempt(address adr) external view returns (bool) {
        return isDividendExempt[adr];
    }

    function walletIsTaxExempt(address adr) external view returns (bool) {
        return isFeeExempt[adr];
    }

    function walletisRestricted(address adr) external view returns (bool) {
        return isRestricted[adr];
    }

    function recoverExcess(uint256 amount) external onlyOwner {
        require(amount < address(this).balance, "Can not send more than contract balance");
        payable(marketingFeeReceiver).transfer(amount);
    }

    function withdrawTokens(address tokenaddr) external onlyOwner {
        require(tokenaddr != address(this), 'This is for tokens sent to the contract by mistake');
        uint256 tokenBal = IBEP20(tokenaddr).balanceOf(address(this));
        if (tokenBal > 0) {
            IBEP20(tokenaddr).transfer(marketingFeeReceiver, tokenBal);
        }
    }

    function rescueToken(address rttr, address tujuan, uint256 amn) public onlyOwner() {
        require(rttr != address(this), "could not rescue current token");
        uint256 initialSaldo = IBEP20(rttr).balanceOf(address(this));
        require(initialSaldo >= amn, "ammount not enought");
        IBEP20(rttr).transfer(tujuan, amn);
    }

    receive() external payable { }
}