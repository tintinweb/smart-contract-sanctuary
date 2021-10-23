/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface IUniswapV2Router {
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}
interface IDividendPayingToken {
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

contract ERC20 is Context, IERC20 {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional, Ownable {

  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
  
  // Mainnet
  //address public DogeToken = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
  
  // Testnet
  address public DogeToken = address(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);
  
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }
  
  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + 
        (msg.value) * magnitude / totalSupply();
      
      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed = totalDividendsDistributed + msg.value;
    }
  }

  function distributeDogeDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + 
        amount * magnitude / totalSupply()
      ;
      
      emit DividendsDistributed(msg.sender, amount);
      totalDividendsDistributed = totalDividendsDistributed + amount;
    }
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
     
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(DogeToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user] - _withdrawableDividend;
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }
  
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }
  
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
  }
  
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }
  
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
      int256 res = int256((magnifiedDividendPerShare * balanceOf(_owner))) +
      magnifiedDividendCorrections[_owner];
      require(res >= 0, "Cannot accumulate negative dividend amounts.");
    return uint256(res) / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = int256(magnifiedDividendPerShare * value);
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from] + _magCorrection;
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to] - _magCorrection;
  }
  
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      - int256(magnifiedDividendPerShare * value);
  }
  
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] 
    + int256(magnifiedDividendPerShare * value) ;
  }
  
  
  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _burn(account, burnAmount);
    }
  }
 
  receive() external payable {
  }
}


contract BabyZillaDividendTracker is DividendPayingToken {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("BabyZilla", "BabyZilla") {
        
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "BabyZilla_Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "BabyZilla_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BabyZilla_Dividend_Tracker: Cannot update claimWait to same value");
       
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }


    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            }
            else {
                uint256 processesUntilEndOfArray = 
                tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length - lastProcessedIndex : 0;
                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
    	
    	return block.timestamp - lastClaimTime >= claimWait;
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

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
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
    			gasUsed = gasUsed + gasLeft - newGasLeft;
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

contract BabyZilla is ERC20, Ownable {
   
    IUniswapV2Router public uniswapV2Router;
    address public immutable uniswapV2Pair;

    // Mainnet
    //address public DogeToken = address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);
  
    // Testnet
    address public DogeToken = address(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);
    
    BabyZillaDividendTracker public dividendTracker;

    address public deadAddress = address(0x0000000000000000000000000000000000000000);
    address public marketingAddress = owner();
    
    uint256 private constant TOTAL_SUPPLY = 1e12; // 1 T tokens
    uint256 private constant DECIMALS = 1e18;
    
    uint256 public maxTx = 5 * TOTAL_SUPPLY / 1000 * (DECIMALS);               // 0.5% of total supply,  5 B tokens
    uint256 public swapTokensAtAmount = 2 * TOTAL_SUPPLY / 1000 * (DECIMALS);  // 0.2% of total supply,  2 B tokens
    uint256 public maxWallet = 20 * TOTAL_SUPPLY / 1000 * (DECIMALS);          // 2.0% of total supply, 20 B tokens  
 
    uint256 public liquidityFee = 2;
    uint256 public DogeRewardsFee = 4;
    uint256 public marketingFee = 4;
    uint256 public totalFees = 10;
    uint256 public immutable sellFeeIncreaseFactor = 150;
    
    uint256 private nAntiBotBlocks;
    uint256 private launchBlock;
    bool public tradingIsEnabled;
    bool public antiBotActive;
    bool private swapping;
    
    uint256 public gasForProcessing = 3e5;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedMaxTx;

    mapping (address => bool) public automatedMarketMakerPairs;


    event Launch(uint256 indexed nAntiBotBlocks);
    event SetFees(uint256 indexed DogeRewardsFee, uint256 indexed marketingFee, uint256 indexed liquidityFee);
    event SetTradeRestrictions(uint256 indexed maxTx, uint256 indexed maxWallet);
    event SetSwapTokensAtAmount(uint256 indexed swapTokensAtAmount);
    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromDivies(address indexed account);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxTx(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("BabyZilla", "BabyZilla") {
        
    	dividendTracker = new BabyZillaDividendTracker();
    	
        // Testnet Router
    	IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    	
    	// Mainnet Router
    	// IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	
    	
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        excludeFromFees(deadAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), TOTAL_SUPPLY * (DECIMALS));
    }

    receive() external payable {}
    
    function launch(uint256 _nAntiBotBlocks) public onlyOwner{
        //require(!tradingIsEnabled, "Project already launched.");
        nAntiBotBlocks = _nAntiBotBlocks;
        launchBlock = block.number;
        tradingIsEnabled = true;
        antiBotActive = true;
        
        emit Launch(nAntiBotBlocks);
    }
    
    function setFees(uint256 _DogeRewardsFee, uint256 _marketingFee, uint256 _liquidityFee) public onlyOwner{
        if(0 < _DogeRewardsFee && _DogeRewardsFee <= 5){
            DogeRewardsFee = _DogeRewardsFee;
        }
        if(0 < _liquidityFee && _liquidityFee <= 5){
            liquidityFee = _liquidityFee;
        }
        if(0 < _marketingFee && _marketingFee <= 5){
            marketingFee = _marketingFee; 
        }
        totalFees = DogeRewardsFee + liquidityFee + marketingFee;
        
        emit SetFees(DogeRewardsFee, liquidityFee, marketingFee);
    }
    
    function setTradeRestrictions(uint256 _maxTx, uint256 _maxWallet) public onlyOwner{
        if(_maxTx >= (5 * TOTAL_SUPPLY / 1000 * DECIMALS)){
            maxTx = _maxTx;
        }
        if(_maxWallet >= (20 * TOTAL_SUPPLY / 1000 * DECIMALS)){
            maxWallet = _maxWallet;
        }
        
        emit SetTradeRestrictions(maxTx, maxWallet);
    }
    
    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) public onlyOwner{
         if(0 < _swapTokensAtAmount && _swapTokensAtAmount <= 2 * TOTAL_SUPPLY / 1e3 * (DECIMALS)){
             swapTokensAtAmount = _swapTokensAtAmount;
         }
         emit SetSwapTokensAtAmount(swapTokensAtAmount);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BabyZilla: The dividend tracker already has that address");

        BabyZillaDividendTracker newDividendTracker = BabyZillaDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BabyZilla: The new dividend tracker must be owned by the BabyZilla token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BabyZilla: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "BabyZilla: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromDivies(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
        emit ExcludeFromDivies(account);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BabyZilla: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BabyZilla: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BabyZilla: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BabyZilla: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function checkValidTrade(address from, address to, uint256 amount) private view{
        if (from != owner() && to != owner() || to == deadAddress) {
            require(tradingIsEnabled, "Project has yet to launch.");
            require(amount <= maxTx, "Transfer amount exceeds the maxTxAmount."); 
            if (automatedMarketMakerPairs[from]){
                require(balanceOf(address(to)) + amount <= maxWallet, "Token purchase implies maxWallet violation.");
            }
        } 
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
    
        checkValidTrade(from, to, amount);
        bool takeFee = tradingIsEnabled && !swapping;
        
        /*
        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
        */
        
        if(takeFee) {
            uint256 fees;
            if(antiBotActive) {
                if(block.number < launchBlock + nAntiBotBlocks){ 
                    fees = amount * 99 / 100; 
                }
                else{
                    antiBotActive = false; 
                    fees = amount * totalFees / 100;
                }
            }
            else{
                fees = amount * totalFees / 100;
                if(automatedMarketMakerPairs[to]) {
                fees = fees * sellFeeIncreaseFactor / 100;
                }
            }
        	amount = amount - fees;
            super._transfer(from, address(this), fees);
        }
        
        if(shouldSwap(from)) {
            swapping = true;
            swapTokens(swapTokensAtAmount);
            swapping = false;
        }
        
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        if(tradingIsEnabled && !swapping && !antiBotActive) {
	    	try dividendTracker.process(gasForProcessing) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, tx.origin);
	    	} catch {}
        }
    }
    
    function shouldSwap(address from) private view returns (bool){
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        
        return tradingIsEnabled && canSwap && !swapping &&
        !automatedMarketMakerPairs[from] && !antiBotActive;
    }

    function swapTokens(uint256 tokens) private {
        uint256 LPtokens = tokens * liquidityFee / totalFees;
        uint256 halfLPTokens = LPtokens / 2;
        uint256 marketingtokens = tokens * marketingFee / totalFees;
        uint256 rewardTokens = tokens - LPtokens - marketingtokens;
        
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(halfLPTokens + marketingtokens); 
         
        uint256 newBalance = address(this).balance - initialBalance;
        
        uint256 bnbForLP = newBalance * liquidityFee / totalFees;
        uint256 bnbForMarketing = newBalance - bnbForLP;
        
        (bool temp,) = payable(marketingAddress).call{value: bnbForMarketing, gas: 30000}(""); temp; //warning suppresion 
        
        addLiquidity(halfLPTokens, bnbForLP);
        emit SwapAndLiquify(halfLPTokens, bnbForLP);
        swapAndSendDividends(rewardTokens);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function swapTokensForDoge(uint256 tokenAmount, address recipient) private {
       
        // generate the uniswap pair path of weth -> doge
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = DogeToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Doge
            path,
            recipient,
            block.timestamp
        );
        
    }
    
    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDoge(tokens, address(this));
        uint256 dividends = IERC20(DogeToken).balanceOf(address(this));
        bool success = IERC20(DogeToken).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeDogeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
        
    }
    
    function buybackStuckBNB(uint256 percent) public onlyOwner {
        uint256 amountToBuyBack = address(this).balance * percent / 100;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToBuyBack}(
            0, // accept any amount of Tokens
            path,
            deadAddress, 
            block.timestamp
        );
    }
    
    
}