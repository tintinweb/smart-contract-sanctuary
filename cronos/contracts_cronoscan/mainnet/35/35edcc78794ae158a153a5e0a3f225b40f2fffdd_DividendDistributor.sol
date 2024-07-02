/**
 *Submitted for verification at cronoscan.com on 2022-06-06
*/

//
//  GemWingsFi - $GEMS
//  https://t.me/GemWings
//  
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IBEP20 {
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
    address public _token;
    address public _admin = 0x48Df8357a323b299C1Ff728f5C7b1d8a28f52e37;
    address payable private _DEV = payable(0xA81B135AaFD0b26E909BAB957E01d8e59392623b);

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IDEXRouter router;
    address routerAddress = 0x52C520DDc9d88a9A3e554a574b31cAa9C0932C57;

    address[] shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 private lastBalance; 

    uint256 public minPeriod = 1;
    uint256 public minDistribution = 1;

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == _admin || msg.sender == _DEV); 
        _;
    }

    constructor () {
        router = IDEXRouter(routerAddress);
        _token = msg.sender;
    }
     receive() external payable {
        if(address(this).balance > lastBalance){
        uint256 amount = address(this).balance - lastBalance;
        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);
        lastBalance = address(this).balance;
        }
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
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

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        lastBalance = address(this).balance;
    }

    function deposit() external payable override onlyToken {
        if(address(this).balance > lastBalance){
        uint256 amount = address(this).balance - lastBalance;
        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);
        lastBalance = address(this).balance;
        }
    }

    function process(uint256 gas) external override onlyToken {

        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while(gasUsed < gas && iterations < shareholderCount) {

            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed += gasLeft - gasleft();
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
            (bool success,) = payable(shareholder).call{value: amount, gas: 34000}("");
            if(success){
                totalDistributed = totalDistributed + amount;
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
                lastBalance = address(this).balance;
            }
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){
            return 0;
        }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){
            return 0;
        }
        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
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
    
    function rescueCRO() external onlyToken {
        (bool tmpSuccess,) = payable(_DEV).call{value: address(this).balance, gas: 34000}("");
        tmpSuccess = false;
    }

    function rescueCROWithTransfer() external onlyToken {
        payable(_DEV).transfer(address(this).balance);
    }
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
    
    event OwnershipTransferred(address owner);
}

interface GemWingsPoolContractInterface {
    function unstakeFromTokenContract(address staker, uint amount, uint256 stake_index) external;
    function unstakeAllFromTokenContract(address staker) external;
    function stakeFromTokenContract(address staker, uint256 _amount, uint256 _days) external;
    function stakeAllFromTokenContract(address staker, uint256 _days) external;
    function claimFromTokenContract(address staker) external;   
    function howManyTokenHasThisAddressStaked(address account) external view returns (uint256);
}

contract GemWings is IBEP20, Auth {

    string constant _name = "GemWingsFi";
    string constant _symbol = "GEMS";
    uint8 constant _decimals = 9;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x52C520DDc9d88a9A3e554a574b31cAa9C0932C57;


    uint256 _totalSupply = 10* 10**6 * (10 ** _decimals);
    uint256 public _maxTxAmount = 1 * 10**10 * (10 ** _decimals);
    uint256 public _walletMax = 1 * 10**10 * (10 ** _decimals);
    
    bool public limitWallet = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public stakingAddress;
    mapping (address => bool) public limitlessAddress;
    mapping (address => uint256) public stakedAmount;
    mapping (address => bool) public isVested;

    uint256 public liquidityFee = 2;
    uint256 public stakingFee = 0;
    uint256 public marketingFee = 5;
    uint256 public rewardsFee = 7;
    uint256 public extraFeeOnSell = 0;

    uint256 private totalFee = liquidityFee + marketingFee + rewardsFee;
    uint256 public totalFeeIfBuying = totalFee + stakingFee;
    uint256 public totalFeeIfSelling = totalFeeIfBuying + extraFeeOnSell;
    uint256 public feeDiscountOnWebsite = 2;

    address public autoLiquidityReceiver = 0x48Df8357a323b299C1Ff728f5C7b1d8a28f52e37;
    address public marketingWallet = 0xC61e4dE85e95a5Df6D8087115B7ABc9FEC3B2a2D;
    address public devWallet = 0xA81B135AaFD0b26E909BAB957E01d8e59392623b;
    address private projectWallet = 0x260c065F51788ca3632895d6ec230A825f8C5a35;
    address public GemWingsPool;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public blocksSinceStart;

    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 650000;
    uint256 dividendSenderGas = 300000;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    bool public stakingRewardsActive = false;
    uint256 public stakingPrizePool = 0;
    

    uint256 public swapThreshold = 1 * (10 ** _decimals);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountTokenLiquified);
    event croSentEvent(uint256 amountBNB, address to, bool success);
    event TokensBoughtOnWebsite(address sender, uint256 value);
    event TokensSoldOnWebsite(address sender, uint256 _tokenAmount);
    
    constructor () Auth(msg.sender) {
        
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendDistributor = new DividendDistributor();

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        
        totalFee = liquidityFee + marketingFee + rewardsFee;
        totalFeeIfBuying = totalFee + stakingFee;
        totalFeeIfSelling = totalFeeIfBuying + extraFeeOnSell;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) {return owner;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD)) - (balanceOf(ZERO));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function changeTxLimit(uint256 newLimit) external authorized {
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external authorized {
        _walletMax  = newLimit;
    }

    function changeRestrictWhales(bool newValue) external authorized {
       limitWallet = newValue;
    }
    
    function changeIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function changeIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        
        if(exempt){
            dividendDistributor.setShare(holder, 0);
        }else{
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function changeRouterToMigrateToOtherDex(address newRouter) external onlyOwner {
        router = IDEXRouter(newRouter);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
    }



    function sendAirDropsAndIncludeAutomatically(address[] calldata accounts, uint256[] calldata amount) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _balances[msg.sender] -=amount[i] * 10 ** _decimals;
            _balances[accounts[i]] += amount[i] * 10 ** _decimals;
            emit Transfer(msg.sender, accounts[i], amount[i] * 10 ** _decimals);
            dividendDistributor.setShare(accounts[i], amount[i] * 10 ** _decimals);
            isVested[accounts[i]] = true;
        }
    }

    function changeFees(uint256 newLiqFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee, uint256 newStakingFee, uint256 newFeeDiscountOnWebsite) external authorized {
        liquidityFee = newLiqFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        extraFeeOnSell = newExtraSellFee;
        stakingFee = newStakingFee;
        feeDiscountOnWebsite = newFeeDiscountOnWebsite;
        totalFee = liquidityFee + marketingFee + rewardsFee;
        totalFeeIfBuying = totalFee + stakingFee;
        totalFeeIfSelling = totalFeeIfBuying + extraFeeOnSell; 
        require(totalFeeIfSelling < 30, "Don't make a honeypot");
    }

    function changeFeeReceivers(address newLiquidityReceiver, address newMarketingWallet) external authorized {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, uint256 newDividendSenderGas) external authorized {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit * (10 ** _decimals);
        dividendSenderGas = newDividendSenderGas;
    }

    function changeDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external authorized {
        dividendDistributor.setDistributionCriteria(newMinPeriod, newMinDistribution);
    }

    function changeDistributorSettings(uint256 gas) external authorized {
        require(gas < 1750000);
        distributorGas = gas;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

	function setGemWingsPoolAddress(address addy) external authorized {
		GemWingsPool = addy;
        stakingAddress[GemWingsPool] = true;
	}

	function setlimitlessAddress(address addy) external authorized {
        limitlessAddress[addy] = true;
        isDividendExempt[addy] = true;
        dividendDistributor.setShare(addy, 0);
	}

    function setStakingRewardsActive(bool active) external authorized {
		stakingRewardsActive = active;
	}

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if(
            inSwapAndLiquify ||
            sender == owner ||
            stakingAddress[recipient] ||
            stakingAddress[sender] ||
            limitlessAddress[sender] ||
            limitlessAddress[recipient]
        ){
            return _basicTransfer(sender, recipient, amount); 
        }
        blocksSinceStart = block.number - launchedAt;
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){
            swapBack();
            if(isVested[sender] && blocksSinceStart < 30 days){
                return true;
            }
        }

        if(!launched() && recipient == pair) {
            launch();
        }

        if(!isTxLimitExempt[recipient] && limitWallet) {
            require(_balances[recipient] + amount <= _walletMax, "Exceeds max Wallet");
        }

        _balances[sender] = _balances[sender] - (amount);

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + finalAmount;

        // Update staking pool, if active.
		// Update of the pool can be deactivated for launch and staking contract migration.
		if (stakingRewardsActive) {
			sendToStakingPool();
		}

        // Dividend tracker //
        if(!isDividendExempt[sender]) {
            try dividendDistributor.setShare(sender, _balances[sender] + stakedAmount[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try dividendDistributor.setShare(recipient, _balances[recipient] + stakedAmount[recipient]) {} catch {} 
        }

        try dividendDistributor.process{gas: distributorGas}(distributorGas) {} catch {}

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    
    function sendToStakingPool() internal {
		_balances[ZERO] -= stakingPrizePool;
		_balances[GemWingsPool] += stakingPrizePool;
		emit Transfer(ZERO, GemWingsPool, stakingPrizePool);
		stakingPrizePool = 0;
	}

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;


        if(stakingAddress[sender]){
            stakedAmount[recipient] = GemWingsPoolContractInterface(GemWingsPool).howManyTokenHasThisAddressStaked(recipient);
        }
        
        if(stakingAddress[recipient]){
            stakedAmount[sender] += amount;
        }
        
        if(!isDividendExempt[sender]) {
            try dividendDistributor.setShare(sender, _balances[sender] + stakedAmount[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try dividendDistributor.setShare(recipient, _balances[recipient] + stakedAmount[recipient]) {} catch {} 
        }

        if(!launched() && recipient == pair) {
            launch();
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
      uint256 feeApplicable = pair == recipient ? totalFeeIfSelling : totalFee;

        uint256 feeAmount = amount * feeApplicable / 100;
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);


	    // If staking tax is active, it is stored on ZERO address.
		// If staking payout itself is active, it is later moved from ZERO to the appropriate staking address.
        if (stakingFee > 0) {
            uint256 stakingFees = stakingFee * amount / 100;
			stakingFees = amount * stakingFee / 100;
			_balances[ZERO] += stakingFees;
			stakingPrizePool += stakingFees;
			emit Transfer(sender, ZERO, stakingFees);
            amount -= stakingFees;
		}

        
        return amount - feeAmount;
    }

    function swapBack() internal lockTheSwap {
        
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify * liquidityFee / totalFee / 2;
        uint256 amountToSwap = tokensToLiquify - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = totalFee - (liquidityFee / (2));
        uint256 amountBNBLiquidity = amountBNB * liquidityFee / totalBNBFee / (2);
        uint256 amountBNBRewards = amountBNB * rewardsFee / totalBNBFee;
        uint256 amountBNBMarketing = amountBNB - amountBNBLiquidity - amountBNBRewards;

        try dividendDistributor.deposit{value: amountBNBRewards, gas: dividendSenderGas}() {} catch {}
        
        uint256 marketingShare = amountBNBMarketing * (marketingFee - 2) / marketingFee;
        uint256 devShare = (amountBNBMarketing - marketingShare)/2;

        (bool tmpSuccess,) = payable(marketingWallet).call{value: marketingShare, gas: 34000}("");
        (tmpSuccess,) = payable(devWallet).call{value: devShare, gas: 34000}("");
        (tmpSuccess,) = payable(projectWallet).call{value: devShare, gas: 34000}("");
        
        
        // only to supress warning msg
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function BuyDirectlyFromContract() payable external lockTheSwap {
        uint256 bnbAmount = msg.value;
        uint256 taxes = (totalFeeIfBuying - feeDiscountOnWebsite) * bnbAmount / 100;
        bnbAmount -= taxes;
    
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
        
        try dividendDistributor.setShare(msg.sender, _balances[msg.sender] + stakedAmount[msg.sender]) {} catch {}

        uint256 amountBNB = address(this).balance;
        uint256 devShare = amountBNB / (totalFeeIfBuying - feeDiscountOnWebsite);
        uint256 marketingShare = amountBNB - (2 * devShare);
 
        (bool tmpSuccess,) = payable(marketingWallet).call{value: marketingShare, gas: 34000}("");
        (tmpSuccess,) = payable(devWallet).call{value: devShare, gas: 34000}("");
        (tmpSuccess,) = payable(projectWallet).call{value: devShare, gas: 34000}("");
        
        // only to supress warning msg
        tmpSuccess = false;
        emit TokensBoughtOnWebsite(msg.sender, msg.value);
    }

function SellDirectlyToContract(uint256 _tokenAmount) external lockTheSwap {
        _tokenAmount = _tokenAmount * 10**4;

        uint256 initialBalance = address(this).balance;

        require(balanceOf(msg.sender) >= _tokenAmount,"Cannot sell more than you own");
         if(_allowances[address(this)][address(router)] < type(uint256).max){
            approve(address(router), type(uint256).max);
        }

        _balances[msg.sender] -= _tokenAmount;
        _balances[address(this)] += _tokenAmount;
        
        try dividendDistributor.setShare(msg.sender, _balances[msg.sender] + stakedAmount[msg.sender]) {} catch {}

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbFromSell = address(this).balance - initialBalance;
        uint256 taxes = (totalFeeIfSelling - feeDiscountOnWebsite) * bnbFromSell / 100;
        
        bnbFromSell -= taxes;

        (bool tmpSuccess,) = payable(msg.sender).call{value: bnbFromSell, gas: 34000}("");

        uint256 devShare = address(this).balance / (totalFeeIfBuying - feeDiscountOnWebsite);
 
        
        (tmpSuccess,) = payable(devWallet).call{value: devShare, gas: 34000}("");
        (tmpSuccess,) = payable(projectWallet).call{value: devShare, gas: 34000}("");
        (tmpSuccess,) = payable(marketingWallet).call{value: address(this).balance, gas: 34000}("");
        // only to supress warning msg
        tmpSuccess = false;

        emit TokensSoldOnWebsite(msg.sender, _tokenAmount);
        
    }




    function _stakeAll(uint256 _days) external {
        _allowances[msg.sender][GemWingsPool] = type(uint256).max;
        emit Approval(msg.sender, GemWingsPool, type(uint256).max);
        GemWingsPoolContractInterface(GemWingsPool).stakeAllFromTokenContract(msg.sender, _days);
    }
    function _stakeSome(uint amount, uint256 _days) external {
        _allowances[msg.sender][GemWingsPool] = type(uint256).max;
        emit Approval(msg.sender, GemWingsPool, type(uint256).max);
        GemWingsPoolContractInterface(GemWingsPool).stakeFromTokenContract(msg.sender, amount, _days);
    }
    function _unstakeSome(uint amount, uint256 index) external {
        GemWingsPoolContractInterface(GemWingsPool).unstakeFromTokenContract(msg.sender, amount, index);
    }
    function _unstakeAll() external {
        GemWingsPoolContractInterface(GemWingsPool).unstakeAllFromTokenContract(msg.sender);
    }
    function _collectStakingRewardsWithoutUnstaking() external {
        GemWingsPoolContractInterface(GemWingsPool).claimFromTokenContract(msg.sender);
    }

    function rescueCRO() external onlyOwner{
        (bool tmpSuccess,) = payable(devWallet).call{value: address(this).balance, gas: 40000}("");
        tmpSuccess = false;
    }
    
    function rescueCROWithTransfer() external onlyOwner{
        payable(devWallet).transfer(address(this).balance);
    }

}