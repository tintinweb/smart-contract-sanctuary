/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

/*
Ascend $ASND

Web: https://ascendtoken.com
Telegram: https://t.me/AscendChat

*/

// SPDX-License-Identifier: MIT

/*
C U ON THE MOON
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface InterfaceLP {
    function sync() external;
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IMaster {
    function rebase() external;
}

interface IDistributor {
    function startDistribution() external;
    function setDistributionParameters(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external;
    function setShares(address shareholder, uint256 amount) external;
    function process() external;
    function deposit() external payable;
    function claim(address shareholder) external;
    function getUnpaidRewards(address shareholder) external view returns (uint256);
    function getPaidRewards(address shareholder) external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function getTotalRewards() external view returns (uint256);
    function getTotalRewarded() external view returns (uint256);
    function migrate(address distributor) external;
    function rebase(uint256 _percent, bool up) external;
}

interface IAntiSnipe {
    function transferCheck(address from, address to, uint256 amount) external returns (bool checked);
}

contract Ascend is ERC20Detailed, Ownable {
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    address public master;

    InterfaceLP public pairContract;

    bool public initialDistributionFinished;

    mapping(address => bool) allowTransfer;
    mapping(address => bool) _isFeeExempt;
    mapping(address => bool) _isMaxWalletExempt;

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                allowTransfer[msg.sender]
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**12 * 10**DECIMALS;
    uint256 public gonMaxWallet = (TOTAL_GONS / 100) * 5;
    uint256 public gonMaxTx = (TOTAL_GONS / 400);
    mapping (address => uint256) lastTransaction;
    uint256 public rateLimit = 20 seconds;

    uint256 public devFee = 2;
    uint256 public buyBackFee = 0;
    uint256 public marketingFee = 5;
    uint256 public rewardsFee = 5;
    uint256 public liquidityFee = 2;
    uint256 public totalFee = devFee + marketingFee + buyBackFee + rewardsFee + liquidityFee;
    uint256 public feeDenominator = 100;
    uint256 public sellBias = 0;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address payable public marketingFeeReceiver;
    address payable public devFeeReceiver;

    IDEXRouter public router;
    address public pair;
    
    mapping (address => bool) isDividendExempt;
    IDistributor public distributor;
    bool public processEnabled = false;
    IAntiSnipe public antisnipe;
    bool public protectionEnabled = true;
    
    mapping (address => bool) teamMember;

    bool public swapEnabled = true;
    uint256 private gonSwapThreshold = (TOTAL_GONS  / 10000) * 10;
    bool public capSwap = false;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    modifier onlyTeam() {
        require(teamMember[msg.sender] || isOwner(), "Caller is not a team member");
        _;
    }
    
    modifier onlyMaster() {
        require(msg.sender == master || isOwner() || teamMember[msg.sender]);
        _;
    }

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = type(uint128).max;

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;

    uint256 public start;
    
    bool public autoRebase = false;
    uint256 public autoRebasePercent = 5;
    uint256 autoRebaseTimer = 3 hours;
    uint256 lastRebase = 0;
    
    function setTeamMember(address _team, bool _enabled) external onlyOwner {
        teamMember[_team] = _enabled;
    }
    
    function runAutoRebase() public {
        if (autoRebase && !inSwap && lastRebase + autoRebaseTimer <= block.timestamp) {
            rebase(0, -int256((_totalSupply * autoRebasePercent) / 100));
            distributor.rebase(autoRebasePercent, false);
            lastRebase = block.timestamp;
        }
    }
    
    function rebasePercent(uint256 _percent, bool up) external onlyMaster returns (uint256) {
        require(_percent < 20);
        require(!inSwap, "Try again");
        distributor.rebase(_percent, up);
        if (up) {
            return rebase(0, int256((_totalSupply * _percent) / 100));
        } else {
            return rebase(0, -int256((_totalSupply * _percent) / 100));
        }
    }

    function rebase(uint256 epoch, int256 supplyDelta)
        internal
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply -= uint256(-supplyDelta);
        } else {
            _totalSupply += uint256(supplyDelta);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor() ERC20Detailed("Ascend", "ASND", uint8(DECIMALS)) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PCS 0x10ED43C718714eb63d5aA57B78B54704E256024E // Test 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3

        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        
        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _allowedFragments[msg.sender][address(router)] = type(uint256).max;
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        initialDistributionFinished = false;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;

        _isMaxWalletExempt[pair] = true;
        _isMaxWalletExempt[DEAD] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[msg.sender] = true;
        
        isDividendExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        marketingFeeReceiver = payable(0x5017bFfeBcFaebf4abDbBa224974D7dfF53B3f5e);
        devFeeReceiver = payable(0x9Fdc4F9807c33e694372a9ae05CDd372ff85175C);
        
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }
    
    function setAutoRebase(bool _auto, uint256 _percent) external onlyTeam {
        autoRebase = _auto;
        autoRebasePercent = _percent;
    }
    
    function setAutoRebaseTimer(uint256 _timer) external onlyTeam {
        autoRebaseTimer = _timer;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        _isFeeExempt[_address];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who] / _gonsPerFragment;
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != type(uint256).max) {
            _allowedFragments[from][msg.sender] -= value;
        }

        _transferFrom(from, to, value);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount * _gonsPerFragment;

        if (sender != owner() && !_isMaxWalletExempt[recipient]) {
            uint256 heldGonBalance = _gonBalances[recipient];
            require(
                gonAmount <= gonMaxTx,
                "Max purchase is currently limited, you can not buy that much."
            );
            require(
                (heldGonBalance + gonAmount) <= gonMaxWallet,
                "Total Holding is currently limited, you can not hold that much."
            );
            require(lastTransaction[recipient] + rateLimit <= block.timestamp, "Purchase rate limit exceeded.");
            lastTransaction[recipient] = block.timestamp;
        }

        if (shouldSwapBack(recipient)) {
            swapBack();
        }

        _gonBalances[sender] -= gonAmount;

        uint256 gonAmountReceived = shouldTakeFee(sender)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
        _gonBalances[recipient] += gonAmountReceived;
        
        if(!isDividendExempt[sender]){ try distributor.setShares(sender, _gonBalances[sender]/_gonsPerFragment) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShares(recipient, _gonBalances[recipient]/_gonsPerFragment) {} catch {} }
        
        if (processEnabled)
            try distributor.process() {} catch {}
        
        if (protectionEnabled)
            antisnipe.transferCheck(sender, recipient, amount);
        
        emit Transfer(
            sender,
            recipient,
            gonAmountReceived / _gonsPerFragment
        );
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[from] -= gonAmount;
        _gonBalances[to] += gonAmount;
        return true;
    }
    
    function startDistribution() external onlyOwner {
        distributor.startDistribution();
    }
    
    function checkSnipe() internal view returns(bool){
        return block.number <= start;
    }

    function takeFee(address sender, address recipient, uint256 gonAmount)
        internal
        returns (uint256)
    {

        uint256 feeAmount = (gonAmount * (checkSnipe() ? feeDenominator - 1 : (recipient == pair ? totalFee + sellBias : totalFee - sellBias))) / feeDenominator;

        _gonBalances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount / _gonsPerFragment);

        return gonAmount - feeAmount;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _gonBalances[address(this)] / _gonsPerFragment;
        if (capSwap) contractTokenBalance = gonSwapThreshold / _gonsPerFragment;
        uint256 amountToLiquify = (contractTokenBalance * liquidityFee / 2) / totalFee;
        contractTokenBalance -= amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 totalBNBFee = totalFee - (liquidityFee / 2);

        uint256 amountBNBLiquidity = (amountBNB * liquidityFee / 2) / totalBNBFee;
        uint256 amountBNBMarketing = (amountBNB * marketingFee) / totalBNBFee;
        uint256 amountBNBDev = (amountBNB * devFee) / totalBNBFee;
        uint256 amountBNBRewards = (amountBNB * rewardsFee) / totalBNBFee;
        
        if (amountBNBMarketing > 0) {
            marketingFeeReceiver.transfer(amountBNBMarketing);
        }
        if (amountBNBDev > 0)
            devFeeReceiver.transfer(amountBNBDev);
        
        if (amountBNBRewards > 0)
            try distributor.deposit{value: amountBNBRewards}() {} catch {}
        
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
        }
    }
    
    function setProtection(IAntiSnipe _protection) external onlyOwner {
        antisnipe = _protection;
    }
    
    function setProtection(bool _enable) external onlyOwner {
        protectionEnabled = _enable;
    }
    
    function updateDistributor(address _distributor, bool _migrate) external onlyOwner {
        if(_migrate) distributor.migrate(_distributor);
        distributor = IDistributor(_distributor);
    }
    
    function setIsDividendExempt(address holder, bool exempt) external onlyTeam {
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShares(holder, 0);
        }else{
            distributor.setShares(holder, _gonBalances[holder]);
        }
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributor.setDistributionParameters(_minPeriod, _minDistribution, gas);
    }
    
    function getPoolStatistics() external view returns (uint256 totalAmount, uint256 totalClaimed, uint256 holders) {
        totalAmount = distributor.getTotalRewards();
        totalClaimed = distributor.getTotalRewarded();
        holders = distributor.countShareholders();
    }
    
    function getWalletStatistics(address wallet) external view returns (uint256 pending, uint256 claimed) {
	    pending = distributor.getUnpaidRewards(wallet);
	    claimed = distributor.getPaidRewards(wallet);
	}

	function claimDividends() external {
	    require(!isDividendExempt[msg.sender], "Exempt from Dividends");
	    distributor.claim(msg.sender);
	    runAutoRebase();
	    if (processEnabled)
	        try distributor.process() {} catch {}
	}

    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] += addedValue;
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        if (subtractedValue >= _allowedFragments[msg.sender][spender]) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] -= subtractedValue;
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function setInitialDistributionFinished(uint256 x) external onlyOwner {
        require(x < 10);
        initialDistributionFinished = true;
        start = block.number + x;
    }

    function enableTransfer(address _addr) external onlyTeam {
        allowTransfer[_addr] = true;
    }
    
    function excludePresaleAddresses(address presaleAddress) external onlyOwner {
        _isFeeExempt[presaleAddress] = true;
        _isMaxWalletExempt[presaleAddress] = true;
        allowTransfer[presaleAddress] = true;
        isDividendExempt[presaleAddress] = true;
    }

    function setFeeExempt(address _addr, bool _exempt) external onlyTeam {
        _isFeeExempt[_addr] = _exempt;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }
    
    function checkDividendExempt(address _addr) external view returns (bool) {
        return isDividendExempt[_addr];
    }

    function setMaxWalletExempt(address _addr, bool _exempt) external onlyTeam {
        _isMaxWalletExempt[_addr] = _exempt;
    }

    function checkMaxWalletExempt(address _addr) external view returns (bool) {
        return _isMaxWalletExempt[_addr];
    }

    function setMaxWalletToken(uint256 _num, uint256 _denom) external onlyOwner
    {
        gonMaxWallet = (TOTAL_GONS / _denom) * _num;
    }
    
    function setMaxTx(uint256 _num, uint256 _denom) external onlyOwner
    {
        gonMaxTx = (TOTAL_GONS / _denom) * _num;
    }
    
    function setRateLimit(uint256 _rate) external onlyOwner
    {
        rateLimit = _rate;
    }

    function checkMaxWalletToken() external view returns (uint256) {
        return gonMaxWallet / _gonsPerFragment;
    }
    
    function checkMaxTx() external view returns (uint256) {
        return gonMaxTx / _gonsPerFragment;
    }

    function shouldTakeFee(address from) internal view returns (bool) {
        return !_isFeeExempt[from];
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold &&
            recipient == pair && 
            totalFee > 0;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom,
        bool _capSwap
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = (TOTAL_GONS / _denom) * _num;
        capSwap = _capSwap;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold / _gonsPerFragment;
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }

    function setFees(
        uint256 _devFee,
        uint256 _buyBackFee,
        uint256 _marketingFee,
        uint256 _rewardsFee,
        uint256 _liquidityFee,
        uint256 _sellBias,
        uint256 _feeDenominator
    ) external onlyOwner {
        devFee = _devFee;
        buyBackFee = _buyBackFee;
        marketingFee = _marketingFee;
        rewardsFee = _rewardsFee;
        liquidityFee = _liquidityFee;
        sellBias = _sellBias;
        totalFee = devFee + marketingFee + buyBackFee + rewardsFee + liquidityFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }
    
    function setFeeReceivers(
        address _marketingFeeReceiver,
        address _devFeeReceiver
    ) external onlyOwner {
        marketingFeeReceiver = payable(_marketingFeeReceiver);
        devFeeReceiver = payable(_devFeeReceiver);
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }
    
    function buyBack(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = (address(this).balance * amountPercentage) / 100;
        
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer((amountETH * amountPercentage) / 100);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS - (_gonBalances[DEAD] + _gonBalances[ZERO])) / _gonsPerFragment;
    }

    function sendPresale(address[] calldata recipients, uint256[] calldata values) external onlyOwner
    {
      for (uint256 i = 0; i < recipients.length; i++) {
        _transferFrom(msg.sender, recipients[i], values[i] * (10 ** DECIMALS));
      }
    }

    receive() external payable {}
}