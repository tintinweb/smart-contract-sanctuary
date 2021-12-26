/**
 *Submitted for verification at snowtrace.io on 2021-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function Ownershiplock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }

    function Ownershipunlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }
}

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingTokenInterface {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  IDEXRouter router;

  uint256 constant internal magnitude = 2**128;
  
  uint256 internal magnifiedDividendPerShare;
  
  mapping (address => uint256) public holderBalance;
  mapping (address => uint256) public holderBNBPercentage;
  mapping(address => bool) public userHasCustomPercentage;

  mapping (address => uint256) public holderBNBTotalRewarded;
  uint256 public totalBalance;
  
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  
  mapping(address => address) public userCurrentRewardToken;
  mapping(address => bool) public userHasCustomRewardToken;

  mapping(address => uint256) public rewardTokenSelectionCount;
  mapping(address => bool) public blackListRewardTokens;
  
  
  uint256 public totalDividendsDistributed;

  constructor () Ownable(msg.sender){
      router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    }

  receive() external payable {
    distributeDividends();
  }
 
  function swapAVAXForTokens(address recipient,uint256 AVAXAmount) private returns (uint256) {
        
        bool swapSuccess;
        IBEP20 token = IBEP20(userCurrentRewardToken[recipient]);
        
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = address(token);
        
        try router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: AVAXAmount}(
            1, path, address(recipient), block.timestamp + 360 ){swapSuccess = true; }
        catch {swapSuccess = false;}
        
        if(!swapSuccess){(bool success,) = recipient.call{value: AVAXAmount, gas: 3000}("");   
            if(!success) {withdrawnDividends[recipient] = withdrawnDividends[recipient].sub(AVAXAmount); return 0;}
            }
        return AVAXAmount;
    }
  
  function setBlacklistToken(address tokenAddress, bool isBlacklisted) external onlyOwner {
      blackListRewardTokens[tokenAddress] = isBlacklisted;
  }
  
  function setBNBPercentage(uint256 BNBPercentage, address holder) external onlyOwner {
      require(BNBPercentage <= 100, "May not set value higher than 100");
      userHasCustomPercentage[holder] = true;
      holderBNBPercentage[holder] = BNBPercentage;
  }
   
  function isBlacklistedToken(address tokenAddress) public view returns (bool){
      return blackListRewardTokens[tokenAddress];
  }
  
  function getBNBDividends(address holder) external view returns (uint256){
      return withdrawnDividends[holder];
  }
    
  function setRewardToken(address holder, address rewardTokenAddress) external onlyOwner {
    require(!blackListRewardTokens[rewardTokenAddress], "Cannot set reward token as this token its blacklisted.");
    if(userHasCustomRewardToken[holder] == true){
        if(rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0){
            rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1;
        }
    }
    userHasCustomRewardToken[holder] = true;
    userCurrentRewardToken[holder] = rewardTokenAddress;
    rewardTokenSelectionCount[rewardTokenAddress] += 1;
  }
  
  function unsetRewardToken(address holder) external onlyOwner {
    userHasCustomRewardToken[holder] = false;
    if(rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0){
        rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1;
    }
    userCurrentRewardToken[holder] = address(0);
  }
  
  function distributeDividends() public override payable {
    require(totalBalance > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalBalance
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }
  
  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
 
    bool success;
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    uint256 BNBPercentage;
    uint256 amountForHolder;
    
    if (userHasCustomPercentage[user]){
        BNBPercentage = _withdrawableDividend * holderBNBPercentage[user] / 100;
        amountForHolder = _withdrawableDividend - BNBPercentage;
        } else {
            BNBPercentage = _withdrawableDividend * 50 / 100;
            amountForHolder = _withdrawableDividend - BNBPercentage;
        }
     
    if (_withdrawableDividend > 0) {
        if (BNBPercentage > 0){
            (success,) = user.call{value: BNBPercentage}("");
            holderBNBTotalRewarded[user] += BNBPercentage;
        }
        
        if(!userHasCustomRewardToken[user] || isBlacklistedToken(userCurrentRewardToken[user])){
        
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          (success,) = user.call{value: amountForHolder, gas: 3000}("");
    
          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
          return _withdrawableDividend;

        } else { 
            
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          return swapAVAXForTokens(user, amountForHolder);
        }
    }
    return 0;
  }


  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;

    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    }
    
    else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}

contract DividendTracker is DividendPayingToken {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
  
    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

     
    constructor() DividendPayingToken() {
        claimWait = 1200;
        minimumTokenBalanceForDividends = 2500 * 10 ** 9  ;
    }

    function withdrawDividend() pure external override {
        require(false, "WithdrawDividend disabled. Use the 'claim' function on the main contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account) external onlyOwner {
        require(excludedFromDividends[account]);
        excludedFromDividends[account] = false;

        emit IncludeInDividends(account);
    }
    
    function updateDividendMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        minimumTokenBalanceForDividends = minimumToEarnDivs;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }
        
        return block.timestamp - (lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) external returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed + (gasLeft - (newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
      
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TEST is IBEP20, Ownable {

    IDEXRouter public router;
    address public pair;

    string constant _name = "TEST";
    string constant _symbol = "FKPANGOLIN";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    DividendTracker public dividendTracker;   

    address public marketingFeeReceiver = 0xe41Ef23CD7019e6901b89ff6d216E58f32f53aA7;
    address public liquidityWallet = 0xe41Ef23CD7019e6901b89ff6d216E58f32f53aA7;
    
    uint256 public swapTokensAtAmount = _totalSupply * 3 / 1000;

    uint256 public rewardsFee;
    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public totalFees;

    // sell fees
    uint256 public sellRewardsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellMarketingFee;
    uint256 public sellTotalFees;
    
    // buy fees
    uint256 public buyRewardsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyMarketingFee;
    uint256 public buyTotalFees;

    uint256 public maxTransactionAmount = _totalSupply /10000 * 125;
  
    uint256 public maxWallet = _totalSupply /100 * 2;
    
    address public defaultToken = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    bool public tradingActive;
    bool public swapEnabled;

    uint256 public gasForProcessing = 500000;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    
    event ExcludedMaxTransactionAmount(address indexed account, bool isExcluded);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyBackWithNoFees(address indexed holder, uint256 indexed bnbSpent);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event FeesUpdated(uint256 indexed newBNBRewardsFee, uint256 indexed newLiquidityFee, uint256 newOperationsFee, uint256 newBuyBackFee);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 AVAXReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(router. WAVAX (), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        // sell fees
        sellRewardsFee = 5;
        sellLiquidityFee = 5;
        sellMarketingFee = 5;
        sellTotalFees = sellRewardsFee + sellLiquidityFee + sellMarketingFee ; // 15%
        
        // buy fees
        buyRewardsFee = 9;
        buyLiquidityFee = 5;
        buyMarketingFee = 5;
        buyTotalFees = buyRewardsFee + buyLiquidityFee + buyMarketingFee ; // 19%

        dividendTracker = new DividendTracker();
        
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner);
        dividendTracker.excludeFromDividends(address(router));
        dividendTracker.excludeFromDividends(address(0xdead));
  
        excludeFromMaxTransaction(owner, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(dividendTracker), true);
        excludeFromMaxTransaction(address(router), true);
        excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(owner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }

        return _transferFrom(sender, recipient, amount);
    }
    
     function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require((newNum * (10 **_decimals)) > (_totalSupply / 100), "Cannot set maxWallet lower than 1%");
        maxWallet = newNum * (10 **_decimals);
    }

    function updateMaxAmount(uint256 newNum) external onlyOwner {
        require((newNum * (10 **_decimals)) > (_totalSupply / 200), "Cannot set maxTransactionAmount lower than 0.5%");
        maxTransactionAmount = newNum * (10 **_decimals);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
        emit ExcludedMaxTransactionAmount(updAds, isEx);
    }
    
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }
    
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
    
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount < _totalSupply, "Swap amount cannot be higher than total supply.");
        require(newAmount >= _totalSupply * 5 / 100000, "Swap amount cannot be lower than 0.005% total supply.");
        require(newAmount <= _totalSupply * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    function getHolderBNBPercentage (address holder) external view returns (uint256) {
        return dividendTracker.holderBNBPercentage(holder);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }
    
    function setDefaultToken (address newdefault) external onlyOwner {
    defaultToken = newdefault;
    }
      
    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "$HEIST: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != marketingFeeReceiver, "$HEIST: The operations wallet is already this address");
        excludeFromFees(marketingFeeReceiver, true);
        marketingFeeReceiver = newMarketingWallet;
    }

    function updateBuyFees(uint256 _marketingFee, uint256 _rewardsFee, uint256 _liquidityFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyRewardsFee = _rewardsFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyRewardsFee + buyLiquidityFee + buyMarketingFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }
    
    function updateSellFees(uint256 _marketingFee, uint256 _rewardsFee, uint256 _liquidityFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellRewardsFee = _rewardsFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellRewardsFee + sellLiquidityFee + sellMarketingFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner returns (bool){
        dividendTracker.updateClaimWait(claimWait);
        return true;
    }   

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function getUserCurrentRewardToken(address holder) external view returns (address){
        return dividendTracker.userCurrentRewardToken(holder);
    }
    
    function getUserHasCustomRewardToken(address holder) external view returns (bool){
        return dividendTracker.userHasCustomRewardToken(holder);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }
    
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) external view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) external view returns (uint256) {
        return dividendTracker.holderBalance(account);
    }  
   
    function getBNBDividends(address holder) public view returns (uint256){
        return dividendTracker.getBNBDividends(holder);
    }
        
    function setRewardToken(address rewardTokenAddress) external returns (bool) {
        require(isContract(rewardTokenAddress), "Address is a wallet, not a contract.");
        require(rewardTokenAddress != address(this), "Cannot set reward token as this token due to Router limitations.");
        dividendTracker.setRewardToken(msg.sender, rewardTokenAddress);
        return true;
    }
        
    function unsetRewardToken() external returns (bool){
        dividendTracker.unsetRewardToken(msg.sender);
        return true;
    }
    
    function claim() external {
         dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    
    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(from, to, amount); }
                
        if(!tradingActive){
            require(_isExcludedFromFees[from], "Trading is not active.");
        }   
        
        // Buy
        if (from == pair) {setBuy();} 
        // Sell
        if (to == pair) {setSell();}

        if(shouldSwapBack(to)){ swapBack(); }

        _balances[from] = _balances[from] - (amount);

        uint256 amountReceived = shouldTakeFee(from) ? takeFee(from, amount) : amount;
        _balances[to] = _balances[to] + (amountReceived);

            if (from == pair && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Unable to exceed Max Wallet");
                } 
    
        _transferFrom(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        bool fromCustomCheck = dividendTracker.userHasCustomRewardToken(from);
            if(!fromCustomCheck){
        try  dividendTracker.setRewardToken(from, defaultToken) {} catch {}
        }
        
        bool toCustomCheck = dividendTracker.userHasCustomRewardToken(to);
            if(!toCustomCheck){
        try  dividendTracker.setRewardToken(to, defaultToken) {} catch {}        
        }

        if(!inSwap) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin); } catch {}
        }
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function setBuy() private {
        rewardsFee = buyRewardsFee;
        liquidityFee = buyLiquidityFee;
        marketingFee = buyMarketingFee;
        totalFees = rewardsFee + liquidityFee + marketingFee;
    }

    function setSell() private {
        rewardsFee = sellRewardsFee;
        liquidityFee = sellLiquidityFee;
        marketingFee = sellMarketingFee;
        totalFees = rewardsFee + liquidityFee + marketingFee;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapTokensAtAmount
        && recipient == pair;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isExcludedFromFees[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * (totalFees) / (100);

        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        
        uint256 tokensForLiquidity = contractBalance * liquidityFee / totalFees / 2;
        uint256 amountToSwapForBNB = contractBalance - tokensForLiquidity;

        swapTokensForBNB(amountToSwapForBNB); 
        
        uint256 bnbBalance = address(this).balance;
        uint256 totalBNBFee = totalFees - (liquidityFee / (2));
        
        uint256 bnbForMarketing = bnbBalance * marketingFee / (totalBNBFee);
        uint256 bnbForRewards = bnbBalance * rewardsFee / (totalBNBFee);
        uint256 bnbForLiquidity = bnbBalance - bnbForMarketing - bnbForRewards;
        
        (bool success,) = address(marketingFeeReceiver).call{value: bnbForMarketing}("");
        (success,) = address(dividendTracker).call{value: bnbForRewards}("");
        
        addLiquidity(tokensForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensForLiquidity);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router. WAVAX ();

        approve(address(router), tokenAmount);

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 AVAXAmount) private {   
        approve(address(router), tokenAmount);

        router.addLiquidityAVAX{value: AVAXAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
}