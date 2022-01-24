/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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
    ) external payable returns (uint amountToken, uint amountSwapBNB, uint liquidity);

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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDividendForReward;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external override onlyToken {
        minPeriod = _minPeriod;
        minDividendForReward = _minDividendForReward;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        uint256 dividendAmount = amount;
        if(amount >= minDividendForReward && shares[shareholder].amount == 0){
            addShareholder(shareholder);
            dividendAmount = amount;
        }else if(amount < minDividendForReward){
            dividendAmount = 0;
            if(shares[shareholder].amount > 0)
                removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(dividendAmount);
        shares[shareholder].amount = dividendAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    receive() external payable { 
        deposit();
    }

    function deposit() public payable override {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > 0;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            (bool success,) = payable(shareholder).call{value: amount, gas: 3000}("");
            if(success){
                totalDistributed = totalDistributed.add(amount);
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }
        }
    }
    
    function claimDividend(address shareholder) external {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getLastTimeClaim(address shareholder)public view returns (uint256) {
        return shareholderClaims[shareholder];
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Zipanda is IBEP20, Ownable {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isDividendExempt;
    address[] private dividendExempt;
   
    string constant _name = "Zipanda";
    string constant _symbol = "ZIP";
    uint8 constant _decimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 325000000000 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tTokenDistributionTotal;

    bool public enabledFee = true;
    uint256 immutable public _PERCENR_NOMINATOR = 100; // 100%
    uint256 immutable public _buyFeeTokenDistribution = 0;
    uint256 immutable public _buyFeeLiquid = 4;
    uint256 immutable public _buyFeeMarketing = 5;
    uint256 immutable public _buyFeeBNBDistribution = 5;

    uint256 immutable public _sellFeeBNBDistribution = 5;
    uint256 immutable public _sellFeeLiquid = 4;
    uint256 immutable public _sellFeeBurn = 0;
    uint256 immutable public _sellFeeMarketing = 5;

    IDEXRouter public router;
    address public pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _swapThreshold = _tTotal / 100000;

    address public walletMarketing;

    // For contract internal usage    
    uint256 accumulatedAmountTokenForBNBDistribution;
    uint256 accumulatedAmountTokenForMarketing;
    uint256 accumulatedAmountTokenForLiquidity;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        distributor = new DividendDistributor();

        _rOwned[_msgSender()] = _rTotal;
        
    	IDEXRouter _router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    	//IDEXRouter _router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IDEXFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        // set the rest of the contract variables
        router = _router;

        walletMarketing = _msgSender();
        
        //exclude owner and this contract from fee
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        setDistributionCriteria(3600, _tTotal/1000);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isDividendExempt[account]) return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isDividendExempt[account];
    }

    function totalDistributedToken() public view returns (uint256) {
        return _tTokenDistributionTotal;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function setIsDividendExempt(address account, bool exempt) public onlyOwner() {
        if(exempt){
            require(!isDividendExempt[account], "Account is already excluded");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            distributor.setShare(account, 0);
            isDividendExempt[account] = true;
            dividendExempt.push(account);
        }else {
            require(isDividendExempt[account], "Account is already included");
            for (uint256 i = 0; i < dividendExempt.length; i++) {
                if (dividendExempt[i] == account) {
                    dividendExempt[i] = dividendExempt[dividendExempt.length - 1];
                    _tOwned[account] = 0;
                    isDividendExempt[account] = false;
                    dividendExempt.pop();
                    break;
                }
            }
            distributor.setShare(account, balanceOf(account));
        }
    }

    function setIsFeeExempt(address account, bool exempt) public onlyOwner {
        isFeeExempt[account] = exempt;
    }

    function setSwapThreshold(uint256 amount) external onlyOwner() {
        _swapThreshold = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to receive ETH from router when swapping
    receive() external payable {}

    function _reflectTokenDistribution(uint256 rTokenDistributionFee, uint256 tTokenDistributionFee) private {
        _rTotal = _rTotal.sub(rTokenDistributionFee);
        _tTokenDistributionTotal = _tTokenDistributionTotal.add(tTokenDistributionFee);
    }

    function _getValues(uint256 tAmount, bool takeFee, bool isSelling) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getTValues(tAmount, takeFee, isSelling);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee) = _getRValues(tAmount, tTokenDistributionFee, tTotalFeeExceptTokenDistribution, _getRate());
        return (rAmount, rTransferAmount, rTokenDistributionFee, tTransferAmount, tTokenDistributionFee, tTotalFeeExceptTokenDistribution);
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSelling) private pure returns (uint256, uint256, uint256) {
        uint256 tTokenDistributionFee = 0;
        uint256 tTotalFeeExceptTokenDistribution = 0;
        if(takeFee){
            if(isSelling){
                tTotalFeeExceptTokenDistribution = (_sellFeeBNBDistribution.add(_sellFeeBurn).add(_sellFeeLiquid).add(_sellFeeMarketing)).mul(tAmount).div(_PERCENR_NOMINATOR);
            }else {
                tTotalFeeExceptTokenDistribution = (_buyFeeLiquid.add(_buyFeeMarketing).add(_buyFeeBNBDistribution)).mul(tAmount).div(_PERCENR_NOMINATOR);
                tTokenDistributionFee = tAmount.mul(_buyFeeTokenDistribution).div(_PERCENR_NOMINATOR);
            }
        }
        uint256 tTransferAmount = tAmount.sub(tTokenDistributionFee).sub(tTotalFeeExceptTokenDistribution);
        return (tTransferAmount, tTokenDistributionFee, tTotalFeeExceptTokenDistribution);
    }

    function _getRValues(uint256 tAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTokenDistributionFee = tTokenDistributionFee.mul(currentRate);
        uint256 rTotalFeeExceptTokenDistribution = tTotalFeeExceptTokenDistribution.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTokenDistributionFee).sub(rTotalFeeExceptTokenDistribution);
        return (rAmount, rTransferAmount, rTokenDistributionFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < dividendExempt.length; i++) {
            if (_rOwned[dividendExempt[i]] > rSupply || _tOwned[dividendExempt[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[dividendExempt[i]]);
            tSupply = tSupply.sub(_tOwned[dividendExempt[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeAllFeeExceptTokenDistribution(address sender, uint256 tTotalFeeExceptTokenDistribution, bool isSelling) private {
        if(tTotalFeeExceptTokenDistribution > 0){
            if(isSelling){
                uint256 numBnbDistr = tTotalFeeExceptTokenDistribution.mul(_sellFeeBNBDistribution).div(_sellFeeBNBDistribution.add(_sellFeeBurn).add(_sellFeeLiquid).add(_sellFeeMarketing));
                uint256 numLiquid = tTotalFeeExceptTokenDistribution.mul(_sellFeeLiquid).div(_sellFeeBNBDistribution.add(_sellFeeBurn).add(_sellFeeLiquid).add(_sellFeeMarketing));
                uint256 numMarketing = tTotalFeeExceptTokenDistribution.mul(_sellFeeMarketing).div(_sellFeeBNBDistribution.add(_sellFeeBurn).add(_sellFeeLiquid).add(_sellFeeMarketing));
                uint256 numBurn = tTotalFeeExceptTokenDistribution.sub(numBnbDistr.add(numLiquid).add(numMarketing));

                accumulatedAmountTokenForBNBDistribution = accumulatedAmountTokenForBNBDistribution.add(numBnbDistr);
                accumulatedAmountTokenForLiquidity = accumulatedAmountTokenForLiquidity.add(numLiquid);
                accumulatedAmountTokenForMarketing = accumulatedAmountTokenForMarketing.add(numMarketing);
                
                sendToken(sender, DEAD, numBurn);

                //Token for BNB distribution, liquidity & buyback are kept in token contract
                sendToken(sender, address(this), numBnbDistr.add(numLiquid).add(numMarketing));

            }else {
                uint256 numLiquid = tTotalFeeExceptTokenDistribution.mul(_buyFeeLiquid).div(_buyFeeLiquid.add(_buyFeeMarketing).add(_buyFeeBNBDistribution));
                uint256 numBnbDis = tTotalFeeExceptTokenDistribution.mul(_buyFeeBNBDistribution).div(_buyFeeLiquid.add(_buyFeeMarketing).add(_buyFeeBNBDistribution));
                uint256 numMarketing = tTotalFeeExceptTokenDistribution.sub(numLiquid.add(numBnbDis));

                //Token for Liquidity, Marketing & Jackpot are kept in token contract
                accumulatedAmountTokenForBNBDistribution = accumulatedAmountTokenForBNBDistribution.add(numBnbDis);
                accumulatedAmountTokenForLiquidity = accumulatedAmountTokenForLiquidity.add(numLiquid);
                accumulatedAmountTokenForMarketing = accumulatedAmountTokenForMarketing.add(numMarketing);
                sendToken(sender, address(this), numLiquid.add(numBnbDis).add(numMarketing));
            }
        }
    }

    function sendToken(address from, address to, uint256 amount) internal{
        uint256 currentRate =  _getRate();
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if(isDividendExempt[to])
            _tOwned[to] = _tOwned[to].add(amount);

        emit Transfer(from, to, amount);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return isFeeExempt[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
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

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _swapThreshold;
        if (
            !inSwapAndLiquify &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            if(overMinTokenBalance){
                swapBack(contractTokenBalance);
            }
        }

        _tokenTransfer(from,to,amount);
    }

    function swapBack(uint256 contractTokenBalance) private lockTheSwap {

        uint256 amountLiquid = contractTokenBalance.mul(accumulatedAmountTokenForLiquidity).div(accumulatedAmountTokenForBNBDistribution  + accumulatedAmountTokenForLiquidity + accumulatedAmountTokenForMarketing);
        uint256 amountBNBDis = contractTokenBalance.mul(accumulatedAmountTokenForBNBDistribution).div(accumulatedAmountTokenForBNBDistribution + accumulatedAmountTokenForLiquidity + accumulatedAmountTokenForMarketing);
        uint256 amountMarketing = contractTokenBalance.sub(amountLiquid + amountBNBDis);
        // split the contract balance into halves
        uint256 halfLiquid = amountLiquid.div(2);
        uint256 otherHalfLiquid = amountLiquid.sub(halfLiquid);

        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(amountBNBDis + halfLiquid + amountMarketing); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 swapBalance = address(this).balance.sub(initialBalance);
        accumulatedAmountTokenForBNBDistribution = 0;
        accumulatedAmountTokenForLiquidity = 0;
        accumulatedAmountTokenForMarketing = 0;

        uint256 bnbLiqid = swapBalance.mul(halfLiquid).div(amountBNBDis + amountMarketing + halfLiquid);
        uint256 bnbReward = swapBalance.mul(amountBNBDis).div(amountBNBDis + amountMarketing + halfLiquid);
        uint256 bnbMarketing = swapBalance.sub(bnbLiqid + bnbReward);

        try distributor.deposit{value: bnbReward}() {} catch {}

        // Send marketing & jackpot fee
        payable(walletMarketing).transfer(bnbMarketing);

        // add liquidity to uniswap
        if(otherHalfLiquid > 0 && bnbLiqid > 0){
            addLiquidity(otherHalfLiquid, bnbLiqid);
            emit SwapAndLiquify(halfLiquid, bnbLiqid, otherHalfLiquid);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        //indicates if fee should be deducted from transfer
        bool takeFee = enabledFee;
        //if any account belongs to isFeeExempt account then remove the fee
        if(isFeeExempt[sender] || isFeeExempt[recipient]){
            takeFee = false;
        }

        bool isSelling = recipient == address(pair) ? true : false;
        
        if (isDividendExempt[sender] && !isDividendExempt[recipient]) {
            _transferFromExcluded(sender, recipient, amount, takeFee, isSelling);
        } else if (!isDividendExempt[sender] && isDividendExempt[recipient]) {
            _transferToExcluded(sender, recipient, amount, takeFee, isSelling);
        } else if (!isDividendExempt[sender] && !isDividendExempt[recipient]) {
            _transferStandard(sender, recipient, amount, takeFee, isSelling);
        } else if (isDividendExempt[sender] && isDividendExempt[recipient]) {
            _transferBothExcluded(sender, recipient, amount, takeFee, isSelling);
        } else {
            _transferStandard(sender, recipient, amount, takeFee, isSelling);
        }

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }

        try distributor.process(distributorGas) {} catch {}
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeAllFeeExceptTokenDistribution(sender, tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAllFeeExceptTokenDistribution(sender, tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeAllFeeExceptTokenDistribution(sender, tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSelling) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTokenDistributionFee, uint256 tTransferAmount, uint256 tTokenDistributionFee, uint256 tTotalFeeExceptTokenDistribution) = _getValues(tAmount, takeFee, isSelling);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeAllFeeExceptTokenDistribution(sender, tTotalFeeExceptTokenDistribution, isSelling);
        _reflectTokenDistribution(rTokenDistributionFee, tTokenDistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function getUnpaidEarnings(address account)  public view returns (uint256){
        return distributor.getUnpaidEarnings(account);
    }

    function getLastTimeClaim(address account)  public view returns (uint256){
        return distributor.getLastTimeClaim(account);
    }

    function claimReward() public {
        distributor.claimDividend(msg.sender);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokenForReceiveReward) public onlyOwner{
        distributor.setDistributionCriteria(_minPeriod, _minTokenForReceiveReward);
    }

    function enableFeeSystem(bool enabled) public onlyOwner{
        enabledFee =  enabled;
    }

    function updateWalletMarketing(address newMarketing) public onlyOwner {
        walletMarketing = newMarketing;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}