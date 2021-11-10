/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}


interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address private _token;
    address private _distributor;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;
    mapping (address => uint256) private shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 private currentIndex;

    event DividendsDistributed(uint256 amountDistributed);

    modifier onlyToken() {
        require(msg.sender == _token, "can only be called by the parent token");
        _;
    }
    
    modifier onlyDistributor() {
        require(msg.sender == _distributor, "can only be called by the tax distributor");
        _;
    }

    constructor (address distributor) {
        _token = msg.sender;
        _distributor = distributor;
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

    function deposit() external payable override onlyDistributor {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 iterations;
        uint256 distributed;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributed += distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        
        emit DividendsDistributed(distributed);
    }

    function shouldDistribute(address shareholder) private view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) private returns (uint256){
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
        return amount;
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

    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract TaxDistributor {
    using SafeMath for uint256;

    address public tokenPair;
    address private _token;
    address private _wbnb;
    IDEXRouter private _router;
    DividendDistributor private _dividendDistributor;
    
    bool public inSwap;
    uint256 public lastSwapTime;
    
    uint256 public pendingRewardPool;
    uint256 public pendingLiquidityPool;
    uint256 public pendingMarketingPool;
    uint256 public pendingCommunityPool;
    
    uint256 public sellRewardTax = 500;
    uint256 public sellLiquidityTax = 300;
    uint256 public sellMarketingTax = 300;
    uint256 public sellCommunityTax = 300;
    uint256 public buyRewardTax = 500;
    uint256 public buyLiquidityTax = 300;
    uint256 public buyMarketingTax = 200;
    uint256 public buyCommunityTax = 200;

    address public marketingWallet;
    address public communityWallet;
    bool private _walletsSet;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }
    
    modifier walletsSet() {
        require(_walletsSet, "wallets not set");
        _;
    }
    
    modifier notInSwap() {
        require(inSwap == false, "already swapping");
        _;
    }
    
    constructor (address router, address pair, address wbnb) {
        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        tokenPair = pair;
    }
    
    function setDividendDistributor(address dividends) public onlyToken {
        _dividendDistributor = DividendDistributor(dividends);
    }
    
    function setWallets(address marketing, address community) public onlyToken {
        require(marketing != address(0) && community != address(0), "must not be 0 address");
        marketingWallet = marketing;
        communityWallet = community;
        _walletsSet = true;
    }
    
    function distribute() public onlyToken walletsSet notInSwap {
        inSwap = true;

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;
        
        uint256 halfLiquidityPool = pendingLiquidityPool.div(2);
        uint256 totalTokens = pendingRewardPool + pendingCommunityPool + pendingMarketingPool + pendingLiquidityPool.sub(halfLiquidityPool);
        uint256 balanceBefore = address(this).balance;
        IERC20(_token).approve(address(_router), totalTokens);
        _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 rewardShare = amountBNB.mul(pendingRewardPool).div(totalTokens);
        uint256 communityShare = amountBNB.mul(pendingCommunityPool).div(totalTokens);
        uint256 marketingShare = amountBNB.mul(pendingMarketingPool).div(totalTokens);
        uint256 liquidityShare = amountBNB.sub(rewardShare).sub(communityShare).sub(marketingShare);
        
        payable(communityWallet).transfer(communityShare);
        payable(marketingWallet).transfer(marketingShare);
        _dividendDistributor.deposit{value: rewardShare}();
        
        if(liquidityShare > 0){
            _router.addLiquidityETH{value: liquidityShare}(
                address(this),
                halfLiquidityPool,
                0,
                0,
                CanadaCoin(_token).owner(),
                block.timestamp
            );
        }

        pendingRewardPool = 0;
        pendingCommunityPool = 0;
        pendingMarketingPool = 0;
        pendingLiquidityPool = 0;
        
        emit TaxesDistributed(totalTokens, amountBNB);
        
        lastSwapTime = block.timestamp;
        inSwap = false;
    }
    
    function getSellTax() public onlyToken view returns (uint256) {
        uint256 taxAmount;
        taxAmount += sellRewardTax;
        taxAmount += sellLiquidityTax;
        taxAmount += sellMarketingTax;
        taxAmount += sellCommunityTax;
        return taxAmount;
    }
    
    function getBuyTax() public onlyToken view returns (uint256) {
        uint256 taxAmount;
        taxAmount += buyRewardTax;
        taxAmount += buyLiquidityTax;
        taxAmount += buyMarketingTax;
        taxAmount += buyCommunityTax;
        return taxAmount;
    }
    
    function setSelltax(uint256 rewardTax, uint256 liquidityTax, uint256 marketingTax, uint256 communityTax) public onlyToken {
        sellRewardTax = rewardTax;
        sellLiquidityTax = liquidityTax;
        sellMarketingTax = marketingTax;
        sellCommunityTax = communityTax;
    }
    
    function setBuytax(uint256 rewardTax, uint256 liquidityTax, uint256 marketingTax, uint256 communityTax) public onlyToken {
        buyRewardTax = rewardTax;
        buyLiquidityTax = liquidityTax;
        buyMarketingTax = marketingTax;
        sellCommunityTax = communityTax;
    }
    
    function takeSellTax(uint256 value) public onlyToken returns (uint256) {
        if (sellRewardTax > 0) {
            uint256 rewardTax = value.mul(sellRewardTax).div(10000);
            pendingRewardPool += rewardTax;
            value = value.sub(rewardTax);
        }
        if (sellLiquidityTax > 0) {
            uint256 liquidityTax = value.mul(sellLiquidityTax).div(10000);
            pendingLiquidityPool += liquidityTax;
            value = value.sub(liquidityTax);
        }
        if (sellMarketingTax > 0) {
            uint256 marketingTax = value.mul(sellMarketingTax).div(10000);
            pendingMarketingPool += marketingTax;
            value = value.sub(marketingTax);
        }
        if (sellCommunityTax > 0) {
            uint256 communityTax = value.mul(sellCommunityTax).div(10000);
            pendingCommunityPool += communityTax;
            value = value.sub(communityTax);
        }
        return value;
    }
    
    function takeBuyTax(uint256 value) public onlyToken returns (uint256) {
        if (buyRewardTax > 0) {
            uint256 rewardTax = value.mul(buyRewardTax).div(10000);
            pendingRewardPool += rewardTax;
            value = value.sub(rewardTax);
        }
        if (buyLiquidityTax > 0) {
            uint256 liquidityTax = value.mul(buyLiquidityTax).div(10000);
            pendingLiquidityPool += liquidityTax;
            value = value.sub(liquidityTax);
        }
        if (buyMarketingTax > 0) {
            uint256 marketingTax = value.mul(buyMarketingTax).div(10000);
            pendingMarketingPool += marketingTax;
            value = value.sub(marketingTax);
        }
        if (buyCommunityTax > 0) {
            uint256 communityTax = value.mul(buyCommunityTax).div(10000);
            pendingCommunityPool += communityTax;
            value = value.sub(communityTax);
        }
        return value;
    }
}


contract CanadaCoin is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string public symbol;
    string public  name;
    uint8 public decimals;

    address public owner;
    bool public isTradingEnabled;
    
    // Swap
    mapping (address => bool) public exchanges;
    uint256 public minimumTimeBetweenSwaps;
    uint256 public minimumTokensBeforeSwap;
    
    // Taxes & Dividends
    TaxDistributor taxDistributor;
    DividendDistributor dividendDistributor;
    bool autoDistributeDividends;
    mapping (address => bool) public excludedFromSelling;
    mapping (address => bool) public excludedFromTax;
    mapping (address => bool) public excludedFromDividends;
    uint256 distributorGas;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    modifier tradingEnabled() {
        require(isTradingEnabled || msg.sender == owner, "trading not enabled");
        _;
    }

    constructor () {
        owner = msg.sender;
        symbol = "CADA";
        name = "Canada Coin";
        decimals = 9;

        address pancakeSwap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // TESTNET
        //address pancakeSwap = ; // MAINNET
        IDEXRouter router = IDEXRouter(pancakeSwap);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;

        minimumTimeBetweenSwaps = 60000;
        minimumTokensBeforeSwap = 100;
        distributorGas = 500000;

        taxDistributor = new TaxDistributor(pancakeSwap, pair, WBNB);
        dividendDistributor = new DividendDistributor(address(taxDistributor));
        taxDistributor.setDividendDistributor(address(dividendDistributor));
        taxDistributor.setWallets(address(1), address(1));

        excludedFromTax[owner] = true;
        excludedFromTax[address(taxDistributor)] = true;
        excludedFromTax[address(dividendDistributor)] = true;
        
        excludedFromDividends[pair] = true;
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[address(taxDistributor)] = true;
        excludedFromDividends[address(dividendDistributor)] = true;
        
        _totalSupply = _totalSupply.add(400000000 * 10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) public override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override tradingEnabled returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override tradingEnabled returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override tradingEnabled returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public tradingEnabled returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public tradingEnabled returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function sellTax() public view returns (uint256) {
        return taxDistributor.getSellTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() public view returns (uint256) {
        return taxDistributor.getBuyTax();
    }


    // Admin methods

    /*function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }*/

    function changeOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
    
    function removeBnb() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function transferTokens(address token, address to) public onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, balance);
    }

    function setTradingEnabled(bool enabled) public onlyOwner {
        isTradingEnabled = enabled;
    }
    
    function setSelltax(uint256 rewardTax, uint256 liquidityTax, uint256 marketingTax, uint256 communityTax) public onlyOwner {
        require(rewardTax + liquidityTax + marketingTax + communityTax < 10000, "tax cannot be more than 100%");
        taxDistributor.setSelltax(rewardTax, liquidityTax, marketingTax, communityTax);
    }
    
    function setBuytax(uint256 rewardTax, uint256 liquidityTax, uint256 marketingTax, uint256 communityTax) public onlyOwner {
        require(rewardTax + liquidityTax + marketingTax + communityTax < 10000, "tax cannot be more than 100%");
        taxDistributor.setBuytax(rewardTax, liquidityTax, marketingTax, communityTax);
    }
    
    function setExchange(address who, bool isExchange) public onlyOwner {
        exchanges[who] = isExchange;
        excludedFromDividends[who] = isExchange;
    }
    
    function setExcludedFromTax(address who, bool enabled) public onlyOwner {
        excludedFromTax[who] = enabled;
    }
    
    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) public onlyOwner {
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
    }
    
    function setDividendDistributionThresholds(uint256 minAmount, uint256 minTime, uint256 gas) public onlyOwner {
        distributorGas = gas;
        dividendDistributor.setDistributionCriteria(minTime, minAmount);
    }
    
    function setWallets(address marketingWallet, address communityWallet) public onlyOwner {
        taxDistributor.setWallets(marketingWallet, communityWallet);
    }
    
    function setAutoDistributeDividends(bool enabled) public onlyOwner {
        autoDistributeDividends = enabled;
    }
    
    function setIsDividendExempt(address who, bool isExempt) public onlyOwner {
        require(who != address(this) && who != address(taxDistributor) && who != address(dividendDistributor) && exchanges[who] == false, "this address cannot receive shares");
        excludedFromDividends[who] = isExempt;
        if (isExempt){
            dividendDistributor.setShare(who, 0);
        } else {
            dividendDistributor.setShare(who, _balances[who]);
        }
    }
    
    function setExcludedFromSelling(address who, bool isExcluded) public onlyOwner {
        require(who != address(this) && who != address(taxDistributor) && who != address(dividendDistributor) && exchanges[who] == false, "this address cannot be excluded");
        excludedFromSelling[who] = isExcluded;
    }

    function runSwapManually() public onlyOwner {
        taxDistributor.distribute();
    }
    
    function runDividendsManually(uint256 gas) public onlyOwner {
        dividendDistributor.process(gas);
    }



    // Private methods
    
    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");
        require(excludedFromSelling[from] == false, "address is not allowed to sell");

        uint256 taxAmount;

        if (excludedFromTax[from] == false) {
            if (exchanges[from]) {
                // we are BUYING
                taxAmount = taxDistributor.takeBuyTax(value);
            }  else {
                // we are SELLING
                taxAmount = taxDistributor.takeSellTax(value);
            }
        }
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value.sub(taxAmount));
        _balances[address(taxDistributor)] = _balances[address(taxDistributor)].add(taxAmount);

        if (excludedFromDividends[from] == false) { 
            dividendDistributor.setShare(from, _balances[from]);
        }
        if (excludedFromDividends[to] == false) { 
            dividendDistributor.setShare(to, _balances[to]);
        }
        if (autoDistributeDividends) {
            try dividendDistributor.process(distributorGas) {} catch {}
        }

        uint256 timeSinceLastSwap = block.timestamp - taxDistributor.lastSwapTime();
        if (taxDistributor.inSwap() == false && 
            timeSinceLastSwap >= minimumTimeBetweenSwaps && 
            _balances[address(taxDistributor)] >= minimumTokensBeforeSwap) {
            try taxDistributor.distribute() {} catch {}
        }

        emit Transfer(from, to, value);
    }
    
}