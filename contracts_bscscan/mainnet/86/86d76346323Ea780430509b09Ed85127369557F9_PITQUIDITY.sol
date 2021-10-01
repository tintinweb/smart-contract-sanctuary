/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

/**
     *Submitted for verification at BscScan.com on 2021-10-01
    */
    
    // SPDX-License-Identifier: Unlicensed
    
    pragma solidity ^0.8.6;
    
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
        function getOwner() external view returns (address);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address _owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
    /**
     * Allows for contract ownership along with multi-address authorization
     */
    abstract contract Auth {
        address internal owner;
    
        constructor(address _owner) {
            owner = _owner;
        }
    
        /**
         * Function modifier to require caller to be contract deployer
         */
        modifier onlyOwner() {
            require(isOwner(msg.sender), "!Owner"); _;
        }
    
        /**
         * Check if address is owner
         */
        function isOwner(address account) public view returns (bool) {
            return account == owner;
        }
    
        /**
         * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
         */
        function transferOwnership(address payable adr) public onlyOwner {
            owner = adr;
            emit OwnershipTransferred(adr);
        }
    
        event OwnershipTransferred(address owner);
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
        function setDividendToken(address dividendToken) external;
    }
    
    contract DividendDistributor is IDividendDistributor {
        using SafeMath for uint256;
    
        address _token;
    
        struct Share {
            uint256 amount;
            uint256 totalExcluded;
            uint256 totalRealised;
        }
    
        IBEP20 dividendToken;
        IDEXRouter router;
        
        address WETH;
    
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
        uint256 public minDistribution = 1000000* (10 ** 9); //0.0001
    
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
        
        event DividendTokenUpdate(address dividendToken);
    
        constructor (address _router, address _dividendToken) {
            router = _router != address(0)
                ? IDEXRouter(_router)
                : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            _token = msg.sender;
            dividendToken = IBEP20(_dividendToken);
            WETH = router.WETH();
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
    
        function deposit() external payable override onlyToken {
            uint256 amount = msg.value;
    
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
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
                (bool successShareholder, /* bytes memory data */) = payable(shareholder).call{value: amount, gas: 30000}("");
                require(successShareholder, "Shareholder rejected BNB transfer");
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
        
        function setDividendToken(address _dividendToken) external override onlyToken {
            dividendToken = IBEP20(_dividendToken);
            emit DividendTokenUpdate(_dividendToken);
        }
        
        function getDividendToken() external view returns (address) {
            return address(dividendToken);
        }
    }
    
    contract PITQUIDITY is IBEP20, Auth {
        using SafeMath for uint256;
    
        address WETH;
        address DEAD = 0x000000000000000000000000000000000000dEaD;
        address ZERO = 0x0000000000000000000000000000000000000000;
    
        string constant _name = "PIQUIDITY";
        string constant _symbol = "PITQD";
        uint8 constant _decimals = 9;
    
        uint256 _totalSupply = 5000000000 * (10 ** _decimals);
        uint256 public _maxTxAmountBuy = _totalSupply;
        uint256 public _maxTxAmountSell = _totalSupply;
        
        uint256 public _maxWalletToken = 13 * 10**6 * (10 ** _decimals);
    
        mapping (address => uint256) _balances;
        mapping (address => mapping (address => uint256)) _allowances;
    
        mapping (address => bool) isFeeExempt;
        mapping (address => bool) isTxLimitExempt;
        mapping (address => bool) isDividendExempt;
        mapping (address => bool) isBot;
    
        uint256 initialBlockLimit = 60;
        
        uint256 reflectionFee = 50;
        uint256 teamFee1 = 9;
        uint256 teamFee2 = 9;
        uint256 teamFee3 = 5;
        uint256 teamFee4 = 27;
        uint256 public totalFee = 100;
        uint256 public feeDenominator = 1000;
    
        address public teamWallet1;
        address public teamWallet2;
        address public teamWallet3;
        address public teamWallet4;
    
        IDEXRouter public router;
        address public pair;
    
        uint256 public launchedAt;
    
        DividendDistributor distributor;
        uint256 distributorGas = 500000;
    
        bool public swapEnabled = true;
        uint256 public swapThreshold = _totalSupply / 5000; // 1M
        bool inSwap;
        modifier swapping() { inSwap = true; _; inSwap = false; }
    
        constructor () Auth(msg.sender) {
            router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
                
            address _presaler = msg.sender;
                
            WETH = router.WETH();
            
            pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
            
            _allowances[address(this)][address(router)] = type(uint256).max;
    
            distributor = new DividendDistributor(address(router), WETH);
    
            isFeeExempt[_presaler] = true;
            isTxLimitExempt[_presaler] = true;
            isTxLimitExempt[DEAD] = true;
            isDividendExempt[pair] = true;
            isDividendExempt[address(this)] = true;
            isDividendExempt[DEAD] = true;
    
            teamWallet1 = 0x2E45E6FfDa9bC25339BeEe5ac8c22c270ab8e422;
            teamWallet2 = 0x78882E25b600593D9E1a940dc829D28C3fe6f71d;
            teamWallet3 = 0x55D1CF911b56D7c7fc36FB5A21E3e7cAD8Cb25D9;
            teamWallet4 = 0x04A2270932FEcAeBFEd682aCcfC3349B9d1B1Beb;
            
            _balances[_presaler] = _totalSupply;
            emit Transfer(address(0), _presaler, _totalSupply);
        }
    
        receive() external payable { }
    
        function totalSupply() external view override returns (uint256) { return _totalSupply; }
        function decimals() external pure override returns (uint8) { return _decimals; }
        function symbol() external pure override returns (string memory) { return _symbol; }
        function name() external pure override returns (string memory) { return _name; }
        function getOwner() external view override returns (address) { return owner; }
        function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
        function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
        function approve(address spender, uint256 amount) public override returns (bool) {
            _allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }
    
        function approveMax(address spender) external returns (bool) {
            return approve(spender, type(uint256).max);
        }
    
        function transfer(address recipient, uint256 amount) external override returns (bool) {
            return _tF(msg.sender, recipient, amount);
        }
    
        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
            if(_allowances[sender][msg.sender] != type(uint256).max){
                _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
            }
    
            return _tF(sender, recipient, amount);
        }
    
        function _tF(address s, address r, uint256 amount) internal returns (bool) {
            if(inSwap){ return _basicTransfer(s, r, amount); }
            
            checkTxLimit(s, r, amount);
    
            if(shouldSwapBack()){ swapBack(); }
    
            if(!launched() && r == pair){ require(_balances[s] > 0); launch(); }
    
            _balances[s] = _balances[s].sub(amount, "Insufficient Balance");
    
            uint256 amountReceived = shouldTakeFee(s) ? takeFee(s, amount) : amount;
            
            if(r != pair && !isTxLimitExempt[r]){
                uint256 contractBalanceRecepient = balanceOf(r);
                require(contractBalanceRecepient + amountReceived <= _maxWalletToken, "Exceeds maximum wallet token amount"); 
            }
            
            _balances[r] = _balances[r].add(amountReceived);
    
            if(!isDividendExempt[s]){ try distributor.setShare(s, _balances[s]) {} catch {} }
            if(!isDividendExempt[r]){ try distributor.setShare(r, _balances[r]) {} catch {} }
    
            try distributor.process(distributorGas) {} catch {}
    
            emit Transfer(s, r, amountReceived);
            return true;
        }
        
        function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return true;
        }
        
        function manualBurn(uint256 amount) external onlyOwner returns (bool) {
            return _basicTransfer(address(this), DEAD, amount);
        }
    
        function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
            sender == pair
                ? require(amount <= _maxTxAmountBuy || isTxLimitExempt[receiver], "Buy TX Limit Exceeded")
                : require(amount <= _maxTxAmountSell || isTxLimitExempt[sender], "Sell TX Limit Exceeded");
        }
    
        function shouldTakeFee(address sender) internal view returns (bool) {
            return !isFeeExempt[sender];
        }
    
        function getTotalFee(bool bot) public view returns (uint256) {
            // Anti-bot, fees as 99% for the first block
            if(launchedAt + initialBlockLimit >= block.number || bot){ return feeDenominator.sub(1); }
            return totalFee;
        }
    
        function takeFee(address sender, uint256 amount) internal returns (uint256) {
            uint256 feeAmount = amount.mul(getTotalFee(isBot[sender])).div(feeDenominator);
    
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
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
            uint256 amountToSwap = swapThreshold;
    
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
    
            uint256 balanceBefore = address(this).balance;
    
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            
            uint256 amountBNBTeam1 = amountBNB.mul(teamFee1).div(totalFee);
            uint256 amountBNBTeam2 = amountBNB.mul(teamFee2).div(totalFee);
            uint256 amountBNBTeam3 = amountBNB.mul(teamFee3).div(totalFee);
            uint256 amountBNBTeam4 = amountBNB.mul(teamFee4).div(totalFee);
            
            uint256 amountBNBReflection = amountBNB.sub(amountBNBTeam1).sub(amountBNBTeam2).sub(amountBNBTeam3).sub(amountBNBTeam4);
    
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            
            (bool successTeam1, /* bytes memory data */) = payable(teamWallet1).call{value: amountBNBTeam1, gas: 30000}("");
            require(successTeam1, "Team1 rejected BNB transfer");
            
            (bool successTeam2, /* bytes memory data */) = payable(teamWallet2).call{value: amountBNBTeam2, gas: 30000}("");
            require(successTeam2, "Team2 rejected BNB transfer");
            
            (bool successTeam3, /* bytes memory data */) = payable(teamWallet3).call{value: amountBNBTeam3, gas: 30000}("");
            require(successTeam3, "Team3 rejected BNB transfer");
            
            (bool successTeam4, /* bytes memory data */) = payable(teamWallet4).call{value: amountBNBTeam4, gas: 30000}("");
            require(successTeam4, "Team4 rejected BNB transfer");
        }
    
        function launched() internal view returns (bool) {
            return launchedAt != 0;
        }
    
        function launch() internal {
            launchedAt = block.number;
        }
        
        function setInitialBlockLimit(uint256 blocks) external onlyOwner {
            require(blocks > 0, "Blocks should be greater than 0");
            initialBlockLimit = blocks;
        }
    
        function setBuyTxLimit(uint256 amount) external onlyOwner {
            _maxTxAmountBuy = amount;
        }
        
        function setSellTxLimit(uint256 amount) external onlyOwner {
            _maxTxAmountSell = amount;
        }
        
        function setMaxWalletToken(uint256 amount) external onlyOwner {
            _maxWalletToken = amount;
        }
        
        function setBot(address _address, bool toggle) external onlyOwner {
            isBot[_address] = toggle;
            _setIsDividendExempt(_address, toggle);
        }
        
        function isInBot(address _address) public view onlyOwner returns (bool) {
            return isBot[_address];
        }
    
        function _setIsDividendExempt(address holder, bool exempt) internal {
            require(holder != address(this) && holder != pair);
            isDividendExempt[holder] = exempt;
            if(exempt){
                distributor.setShare(holder, 0);
            }else{
                distributor.setShare(holder, _balances[holder]);
            }
        }
        
        function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
            _setIsDividendExempt(holder, exempt);
        }
    
        function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
            isFeeExempt[holder] = exempt;
        }
    
        function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
            isTxLimitExempt[holder] = exempt;
        }
    
        function setFees(uint256 _reflectionFee, uint256 _teamFee1, uint256 _teamFee2, uint256 _teamFee3, uint256 _teamFee4) external onlyOwner {
            reflectionFee = _reflectionFee;
            teamFee1 = _teamFee1;
            teamFee2 = _teamFee2;
            teamFee3 = _teamFee3;
            teamFee4 = _teamFee4;
            totalFee = _reflectionFee.add(_teamFee1).add(_teamFee2).add(_teamFee3).add(_teamFee4);
            //Total fees has to be less than 50%
            require(totalFee < feeDenominator/2, "Total Fee cannot be more than 50%");
        }
        
        function setFeeReceivers(address _teamWallet1, address _teamWallet2, address _teamWallet3, address _teamWallet4) external onlyOwner {
            teamWallet1 = _teamWallet1;
            teamWallet2 = _teamWallet2;
            teamWallet3 = _teamWallet3;
            teamWallet4 = _teamWallet4;
        }
        
        function getFees() public view onlyOwner returns (uint256, uint256, uint256, uint256, uint256) {
            return (reflectionFee, teamFee1, teamFee2, teamFee3, teamFee4);
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
    }