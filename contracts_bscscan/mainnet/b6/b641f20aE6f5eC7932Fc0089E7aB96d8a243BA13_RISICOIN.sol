/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/**
    ██████╗ ██╗███████╗██╗ ██████╗ ██████╗ ██╗███╗   ██╗
    ██╔══██╗██║██╔════╝██║██╔════╝██╔═══██╗██║████╗  ██║
    ██████╔╝██║███████╗██║██║     ██║   ██║██║██╔██╗ ██║
    ██╔══██╗██║╚════██║██║██║     ██║   ██║██║██║╚██╗██║
    ██║  ██║██║███████║██║╚██████╗╚██████╔╝██║██║ ╚████║
    ╚═╝  ╚═╝╚═╝╚══════╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ 
*/

/* Tokenomics:
    * 10% Airdrop - Convert to BNB
    * 3% Marketing - Convert to BNB
    * 2% Liquidity Pool
        
    * 2% Sell fee (send in Marketing Wallet)
    * 0.2% of Market Cap in Max Sell
    * Number of Tokens: 100,000,000,000
    * Number of Tokens for AirDrop eligibility: 1,000,000
*/


//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address payable msgSender = _msgSender();
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
        function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    //Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
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
        uint currRewardId;
    }

    address WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

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

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable override {
        
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        if(totalShares > 0) {
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
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
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).call{value: amount, gas: 30000}("");
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
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

contract RISICOIN is IERC20, Ownable {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    address marketingFeeReceiver = 0xda44Da59bB1A5ef108106160c5d2161E021D5B33;
    address airdropFeeReceiver = 0x5a62b1633F6683d18A887ac92a99B53C50B23f42;

    string constant _name = "RISICOIN";
    string constant _symbol = "RISICOIN";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100; // 1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    
    struct AddressFee {
        bool enable;
        uint256 _airdropFee;
        uint256 _marketingFee;
        uint256 _liquidityFee;
        uint256 _buyAirDropFee;
        uint256 _buyMarketingFee;
        uint256 _buyLiquidityFee;
        uint256 _sellAirDropFee;
        uint256 _sellMarketingFee;
        uint256 _sellLiquidityFee;
    }
    
    // Fee per address
    mapping (address => AddressFee) public _addressFees;

    uint256 public _airdropFee = 10;
    uint256 private _previousAirDropFee = _airdropFee;
    
    uint256 public _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;
    
    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    
    uint256 public _buyAirDropFee = 10;
    uint256 public _buyMarketingFee = 3;
    uint256 public _buyLiquidityFee = 2;
    
    uint256 public _sellAirDropFee = 10;
    uint256 public _sellMarketingFee = 5;
    uint256 public _sellLiquidityFee = 2;

    address private autoLiquidityReceiver;

    IDEXRouter public router;
    address public pair;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = 1000000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event AutoLiquify(uint256 amountBNB, uint256 amount);

    constructor (){
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        
        autoLiquidityReceiver = owner();

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);    
        
        restoreAllFee();

        // Buy
        if (sender == pair) {
            removeAllFee();
            _airdropFee = _buyAirDropFee;
            _marketingFee = _buyMarketingFee;
            _liquidityFee = _buyLiquidityFee;
        }
        // Sell
        else if (recipient == pair) {
            removeAllFee();
            _airdropFee = _sellAirDropFee;
            _marketingFee = _sellMarketingFee;
            _liquidityFee = _sellLiquidityFee;
        }
        
        // If send account has a special fee 
        if (_addressFees[sender].enable) {
            removeAllFee();
            
            // Sell
            if (recipient == pair) {
                _airdropFee = _addressFees[sender]._sellAirDropFee;
                _marketingFee = _addressFees[sender]._sellMarketingFee;
                _liquidityFee = _addressFees[sender]._sellLiquidityFee;
            }
            else {
                _airdropFee = _addressFees[sender]._airdropFee;
                _marketingFee = _addressFees[sender]._marketingFee;
                _liquidityFee = _addressFees[sender]._liquidityFee;
            }
        }
        else {
            // If buy account has a special fee
            if (_addressFees[recipient].enable) {
                removeAllFee();

                //buy
                if (sender == pair) {
                    _airdropFee = _addressFees[recipient]._buyAirDropFee;
                    _marketingFee = _addressFees[recipient]._buyMarketingFee;
                    _liquidityFee = _addressFees[recipient]._buyLiquidityFee;
                }
                else {
                    _airdropFee = _addressFees[recipient]._airdropFee;
                    _marketingFee = _addressFees[recipient]._marketingFee;
                    _liquidityFee = _addressFees[recipient]._liquidityFee;
                }
            }
        }

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        

        uint256 amountReceived = (shouldTakeFee(sender) && shouldTakeFee(recipient)) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        //if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        //if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        //try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(_airdropFee + _marketingFee).div(100);
        uint256 liquidityAmount = amount.mul(_liquidityFee).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        
        inSwap = true;
        
        _balances[address(this)] = _balances[address(this)].add(liquidityAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            liquidityAmount.div(2),
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        router.addLiquidityETH{value: amountBNB}(
            address(this),
            liquidityAmount.div(2),
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        );
        emit AutoLiquify(amountBNB, liquidityAmount.div(2));
        inSwap = false;
        
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        inSwap = true;
        uint256 amountToSwap = swapThreshold;
        //amountToSwap = amountToSwap.sub(halfLiquid);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 amountBNBReflection = amountBNB.mul(_airdropFee).div(_airdropFee + _marketingFee);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(_airdropFee + _marketingFee);
        
        //try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(airdropFeeReceiver).call{value: amountBNBReflection, gas: 30000}("");
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        
        inSwap = false;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000, "Check minimum MaxTx amount");
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 airdropFee, uint256 markingFee, uint256 liquidFee) external onlyOwner {
        _airdropFee = airdropFee;
        _liquidityFee = liquidFee;
        _marketingFee = markingFee;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    
    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    
    function removeAllFee() private {
        if (_airdropFee == 0 && _marketingFee == 0 && _liquidityFee == 0) return;
        
        _previousAirDropFee = _airdropFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        
        _airdropFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _airdropFee = _previousAirDropFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
    }
}