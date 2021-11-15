pragma solidity >=0.6.2 <0.9.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

abstract contract feedInterface  {
     function latestAnswer() virtual public view returns (uint);
}

abstract contract liquidityPool {
     function balanceOf(address holder) virtual public view returns (uint256);
     function totalSupply() virtual public view returns (uint256);
     
     function transfer (address to, uint value) public virtual returns (bool ok);
     function transferFrom (address from, address to, uint value) public virtual returns (bool ok);
     function allowance(address owner, address spender) public view virtual returns (uint remaining);
    
     function token0() virtual public view returns (address);
     function token1() virtual public view returns (address);
     function getReserves() virtual public view returns (uint112 reserve0, uint112 reserve1, uint32 timeStampLast);
}

abstract contract ERC20 {
    function totalSupply() public view virtual returns (uint supply);
    function balanceOf(address who) public view virtual returns (uint value);
    function allowance(address owner, address spender) public view virtual returns (uint remaining);

    function transfer (address to, uint value) public virtual returns (bool ok);
    function transferFrom (address from, address to, uint value) public virtual returns (bool ok);
    function approve(address spender, uint value) public virtual returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract hashToken is ERC20{
    using SafeMath for uint256;
    
    feedInterface internal priceFeed;
    liquidityPool internal pool;

    address public poolAddress;
    address public priceFeedAddress;

    uint8 public constant decimals = 18;
    uint256 _totalSupply;
    bool public crowdSale;
    uint256 public totalDividends;
    uint256 public crowdSaleStart;
    uint256 public constant initialUsdPrice = 13;
    uint256 public currentDividendsRound;
    uint256 public bonus;

    string public constant name = "hashToken";
    string public constant symbol = "HASH";

    address payable public teamAddress;

    mapping (address => uint256) public lastClaimedRound;
    mapping (address => uint256) public lastMergedRound;
    mapping (address => uint256) public dividendsAccumulated;
    mapping (uint256 => uint256) public dividendsRounds; //round->valuePerToken
    mapping (uint256 => uint256) public dividendsTimestamps; //round->timestamp
    mapping (address => uint256) balances;
    
    mapping (address => uint256) public lockedBalances;
    mapping (address => uint256) public unlockTimeStamp;
    
    mapping (address => mapping (address => uint256)) allowed;

    event SetBonus(uint value);
    event ChangedPriceFeed(address indexed to);
    event Minted(address indexed to, uint value);
    event DividendsTransfered(address indexed to, uint value);
        
    modifier onlyTeam {
        if (msg.sender == teamAddress) {
            _;
        }
    }
    
    function switchCrowdSale() public onlyTeam {
        if (crowdSale)
            crowdSale = false;
        else
            crowdSale = true;
    }
    
    function setPool(address newPoolAddress) public onlyTeam {
        pool = liquidityPool(newPoolAddress);
        require (pool.token1()==address(this) || pool.token0()==address(this), 'pool should provide liquidity for this token');
        poolAddress = newPoolAddress;
    }
    
    function changedPriceFeed(address newAddress) public onlyTeam {
        priceFeedAddress = newAddress;
        priceFeed = feedInterface(priceFeedAddress);
        emit ChangedPriceFeed(priceFeedAddress);
    }
    
    function setBonus(uint256 _bonus) public onlyTeam {
        bonus = _bonus;
        emit SetBonus(_bonus);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256 balance) {
        return balances[owner];
    }
 
    function allowance(address owner, address spender) public view override returns (uint remaining) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public override returns (bool success) {
        if (balances[msg.sender] >= value) {
            mergeDividends(msg.sender);
            mergeDividends(to);
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[to] = balances[to].add(value);
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value) {
            mergeDividends(from);
            mergeDividends(to);
            balances[to] = balances[to].add(value);
            balances[from] = balances[from].sub(value);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public override returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    constructor () payable {
        teamAddress = payable(msg.sender);
        crowdSale = true;
        crowdSaleStart = block.timestamp;
        dividendsTimestamps[0] = block.timestamp;
        priceFeedAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        priceFeed = feedInterface(priceFeedAddress); //chainLink priceFeed 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        uint256 initialSupply = 300*10**uint256(decimals);
        mint(teamAddress, initialSupply);
        bonus = 0;
        poolAddress = address(0);
    }
    
    function daysFromStart() public view returns (uint256 daysCount) {
        return (block.timestamp.sub(crowdSaleStart)).div(1 days);
    }
    
    function secondsBetweenLastRounds() public view returns (uint256 secondsCount) {
        if (currentDividendsRound>0) {
            return (dividendsTimestamps[currentDividendsRound] - dividendsTimestamps[currentDividendsRound-1]).div(1 seconds);
        }
        return 0;
    }
    
    function currentPrice() public view returns (uint256 price) {
        uint256 dfs = daysFromStart();
        return initialUsdPrice.mul(dfs.mul(10**5).div(365).add(10**5));
    }
    
    function latestUSDPrice() public view returns (uint256 currentETHprice) {
        return priceFeed.latestAnswer();
    }

    function claimDividends() public {
        mergeDividends(msg.sender);
        lastClaimedRound[msg.sender] = currentDividendsRound;
        payable(msg.sender).transfer(dividendsAccumulated[msg.sender]);
        emit DividendsTransfered(msg.sender, dividendsAccumulated[msg.sender]);
        dividendsAccumulated[msg.sender] = 0;
    }
    
    function getPooledTokens(address tokenHolder) public view returns (uint256 pooled) {
        if (poolAddress == address(0)) return 0;
        uint112 res0;
        (res0,,) = pool.getReserves();
        uint256 _totalLPBalance = pool.balanceOf(tokenHolder).add(lockedBalances[tokenHolder]);
        return _totalLPBalance.mul(res0).div(pool.totalSupply());
    }
    
    function getLockedTokens(address tokenHolder) public view returns (uint256 pooled) {
        if (poolAddress == address(0)) return 0;
        uint112 res0;
        (res0,,) = pool.getReserves();
        return lockedBalances[tokenHolder].mul(res0).div(pool.totalSupply());
    }
    
    function mergeDividends(address tokenHolder) public returns (uint256 _dividendsAccumulated){
        uint256 mergedAmount = getMergedDividends(tokenHolder);
        dividendsAccumulated[tokenHolder] = dividendsAccumulated[tokenHolder].add(mergedAmount);
        lastMergedRound[tokenHolder] = currentDividendsRound;
        return dividendsAccumulated[tokenHolder];
    }
    
    function getCurrentDividends(address tokenHolder) public view returns (uint256 currentDividends){
        return dividendsAccumulated[tokenHolder].add(getMergedDividends(tokenHolder));
    }
    
    function getMergedDividends(address tokenHolder) public view returns (uint256 currentDividends){
        uint256 mergedAmount = 0;
        uint256 _lastMergedRound = lastMergedRound[tokenHolder];
        uint256 overallBalance = balances[tokenHolder].add(getPooledTokens(tokenHolder));
        for (uint256 round = currentDividendsRound; round > _lastMergedRound; round--) {
            mergedAmount = mergedAmount.add(overallBalance.mul(dividendsRounds[round]));
            mergedAmount = mergedAmount.add(getLockedTokens(tokenHolder).mul(dividendsRounds[round]).mul(bonus).div(100));
        }
        return mergedAmount.div(10**decimals);
    } 

    receive() external payable {
        if (msg.value < 10**16) {
            teamAddress.transfer(msg.value);
        }
        else {
        currentDividendsRound++;
        totalDividends = totalDividends.add(msg.value);
        uint256 perToken = msg.value.mul(10**decimals).div(_totalSupply);
        dividendsRounds[currentDividendsRound] = perToken;
        dividendsTimestamps[currentDividendsRound] = block.timestamp;
        }//spread dividends
    }
    
    function tokensForEther(uint value) public view returns (uint tokens){
        return value.mul(priceFeed.latestAnswer()).div(10**3).div(currentPrice());
    }
    
    function topUp() payable public{
    }
    
    function buyTokens() payable public{
        require(crowdSale);
        if (balances[msg.sender]>0)
            mergeDividends(msg.sender);
        uint256 tokensToSend = tokensForEther(msg.value);
        mint(msg.sender,tokensToSend);
        teamAddress.transfer(msg.value);
    }
    
    function depositLP(uint256 _minutes) public {
        uint256 _amount = pool.allowance(address(msg.sender), address(this));
        require(_amount>0, 'allow tokens first');
        mergeDividends(msg.sender);
        pool.transferFrom(address(msg.sender), address(this), _amount);
        lockedBalances[msg.sender] = lockedBalances[msg.sender].add(_amount);
        uint256 timeToRelease = block.timestamp.add(_minutes.mul (1 minutes));
        if (timeToRelease > unlockTimeStamp[msg.sender])
            unlockTimeStamp[msg.sender] = timeToRelease;
    }
    
    function withdrawLP() public {
        require (block.timestamp > unlockTimeStamp[msg.sender], 'you need to wait');
        mergeDividends(msg.sender);
        pool.transfer(address(msg.sender), lockedBalances[msg.sender]);
        lockedBalances[msg.sender] = 0; 
    }
    
    function getWholeBalance() public{
        if (balances[msg.sender] == _totalSupply){
            payable(msg.sender).transfer(address(this).balance);
            lastMergedRound[msg.sender] = currentDividendsRound;
            lastClaimedRound[msg.sender] = currentDividendsRound;
        }
    }
    
    function mint(address to, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Minted(to, amount);
    }
}

