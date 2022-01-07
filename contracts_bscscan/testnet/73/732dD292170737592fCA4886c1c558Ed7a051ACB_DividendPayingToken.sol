pragma solidity >= 0.8.7;

// SPDX-License-Identifier: UNLICENSED

import "./ERC20.sol";
import "./SafeMathInt.sol";
import "./IterableMapping.sol";
import "./UniSwap.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";

// Dividends Interfaces
interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    
    event DividendsDistributed(
        address indexed from,
        uint256 weimount
    );
    
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns (uint256);
    function withdrawnDividendOf(address _owner) external view returns (uint256);
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}



/// @title Dividend Paying Contract
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
  
  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  uint256 public totalDividendsDistributed;
  
  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
  
  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }
  
  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalSupply() > 0);
    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }
  
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }
  
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");
      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
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
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }
  
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }
  
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }
  
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);
    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }
  
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}





// Main Contract
contract ThePeoplesToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    TPTDividendTracker public dividendTracker;
    
    string private _name = "The Peoples Token";
    string private _symbol = "TPT";
    uint8 private _decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000000 * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    bool private _swapping;
    uint256 public gasForProcessing = 300000;
    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _buyBackTokensToSwap;
    uint256 private _salaryTokensToSwap;
    uint256 private _holdersTokensToSwap;
    
    address public marketingWallet;
    address public liquidityWallet;
    address public buyBackWallet;
    address public salaryWallet;

    
    // Base taxes
    uint256 public liquidityFeeOnBuy = 3;
    uint256 public marketingFeeOnBuy = 2;
    uint256 public holdersFeeOnBuy = 12;
    uint256 public salaryFeeOnBuy = 1;
    
    uint256 public liquidityFeeOnSell = 3;
    uint256 public marketingFeeOnSell = 2;
    uint256 public holdersFeeOnSell = 12;
    uint256 public salaryFeeOnSell = 1;
    
    uint256 public nativeTokensForHoldersFee = 3;
    
    
    uint256 private _blacklistTimeLimit = 21600;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private _buyTimesInLaunch;
    
    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event DividendTrackerChange(address indexed newAddress, address indexed oldAddress);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event LiquidityWalletChange(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletChange(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event SalaryWalletChange(address indexed newSalaryWallet, address indexed oldSalaryWallet);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeOnSellChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event FeeOnBuyChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
    event nativeTokensForHoldersFeeChange(uint256 indexed newValue, uint256 oldValue, string indexed taxType);
    event BlacklistChange(address indexed holder, bool indexed status);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event MinTokenAmountForDividendsChange(uint256 indexed newValue, uint256 indexed oldValue);
    
    event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
    event DividendsSent(uint256 tokensSwapped);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    
    constructor(address _liquidityWalletAddress, address _marketingWalletAddress, address _salaryWalletAddress) ERC20(_name, _symbol) {
        liquidityWallet = address(_liquidityWalletAddress);
    	marketingWallet = address(_marketingWalletAddress); 
    	salaryWallet = address(_salaryWalletAddress);

    	dividendTracker = new TPTDividendTracker();
    
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Mainnet
        
        
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        
    
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
        dividendTracker.excludeFromDividends(owner());
        

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    
    }
    
    receive() external payable {}
    
    // Setters
    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }
    
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "The Peoples Token: The dividend tracker already has that address");
        TPTDividendTracker newDividendTracker = TPTDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "The Peoples Token: The new dividend tracker must be owned by the TPT token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit DividendTrackerChange(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "The Peoples Token: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "The Peoples Token: Account is already the value of 'excluded'");
        require(!_isExcluded[account], "Account is already excluded");
        _isExcludedFromFee[account] = excluded;
        
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeFromFeesChange(account, excluded);
    }
    
    function excludeFromDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }
    

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        require(_isExcludedFromFee[account], "The Peoples Token: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function blacklistAccount(address account) public onlyOwner {
        require(!_isBlacklisted[account], "The Peoples Token: Account is already blacklisted");

        _isBlacklisted[account] = true;
        emit BlacklistChange(account, true);
    }
    
    function unBlacklistAccount(address account) public onlyOwner {
        require(_isBlacklisted[account], "The Peoples Token: Account is not blacklisted");
        _isBlacklisted[account] = false;
        emit BlacklistChange(account, false);
    }
    
    function setLiquidityWallet(address newAddress) public onlyOwner {
        require(liquidityWallet != newAddress, "The Peoples Token: The liquidityWallet is already that address");
        emit LiquidityWalletChange(newAddress, liquidityWallet);
        liquidityWallet = newAddress;
    }
    
    function setMarketingWallet(address newAddress) public onlyOwner {
        require(marketingWallet != newAddress, "The Peoples Token: The marketingWallet is already that address");
        emit MarketingWalletChange(newAddress, marketingWallet);
        marketingWallet = newAddress;
    }
  
    function setSalaryWallet(address newAddress) public onlyOwner {
        require(salaryWallet != newAddress, "The Peoples Token: The salaryWallet is already that address");
        emit SalaryWalletChange(newAddress, salaryWallet);
        salaryWallet = newAddress;
    }
    
    function setLiquidityFeeOnBuy(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnBuy != newvalue, "The Peoples Token: The liquidityFeeOnBuy is already that value");
        require(0 <= newvalue && newvalue <= 100, "The Peoples Token: The Value Must Be Between 0 and 100.");
        emit FeeOnBuyChange(newvalue, liquidityFeeOnBuy, "liquidityFeeOnBuy");
        liquidityFeeOnBuy = newvalue;
    }
    
    function setLiquidityFeeOnSell(uint256 newvalue) public onlyOwner {
        require(liquidityFeeOnSell != newvalue, "The Peoples Token: The liquidityFeeOnSell is already that value");
        require(0 <= newvalue && newvalue <= 100, "The Peoples Token: The Value Must Be Between 0 and 100.");
        emit FeeOnSellChange(newvalue, liquidityFeeOnSell, "liquidityFeeOnSell");
        liquidityFeeOnSell = newvalue;
    }
    
    function setMarketingFeeOnSell(uint256 newvalue) public onlyOwner {
        require(marketingFeeOnSell != newvalue, "The Peoples Token: The marketingFeeOnSell is already that value");
        require(0 <= newvalue && newvalue <= 100, "The Peoples Token: The Value Must Be Between 0 and 100.");
        emit FeeOnSellChange(newvalue, marketingFeeOnSell, "marketingFeeOnSell");
        marketingFeeOnSell = newvalue;
    }
    
    function setHolderFeeOnSell(uint256 newvalue) public onlyOwner {
        require(holdersFeeOnSell != newvalue, "The Peoples Token: The holdersFeeOnSell is already that value");
        require(0 <= newvalue && newvalue <= 100, "The Peoples Token: The Value Must Be Between 0 and 100.");
        emit FeeOnSellChange(newvalue, holdersFeeOnSell, "holdersFeeOnSell");
        holdersFeeOnSell = newvalue;
    }
    
    function setSalaryFeeOnSell(uint256 newvalue) public onlyOwner {
        require(salaryFeeOnSell != newvalue, "The Peoples Token: The salaryFeeOnSell is already that value");
        require(0 <= newvalue && newvalue <= 100, "The Peoples Token: The Value Must Be Between 0 and 100.");
        emit FeeOnSellChange(newvalue, salaryFeeOnSell, "salaryFeeOnSell");
        salaryFeeOnSell = newvalue;
    }
    
    function setNativeTokensFee(uint256 newvalue) public onlyOwner {
        require(nativeTokensForHoldersFee != newvalue, "The Peoples Token: The salaryFeeOnSell is already that value");
        require(0 <= newvalue && newvalue <= 100, "The Peoples Token: The Value Must Be Between 0 and 100.");
        emit nativeTokensForHoldersFeeChange(newvalue, nativeTokensForHoldersFee, "nativeTokensForHoldersFee");
        nativeTokensForHoldersFee = newvalue;
    }
    
    function setUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The Peoples Token: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    
    function setGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "The Peoples Token: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "The Peoples Token: Cannot update gasForProcessing to same value");
        emit GasForProcessingChange(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }
    
    function setMinimumTokenBalanceForDividends(uint256 newValue) public onlyOwner {
        dividendTracker.setTokenBalanceForDividends(newValue);
    }
    
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    
    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    
    // Getters
    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
    
    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }
    
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    
    
    // Main
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        bool isBuyFromLp = automatedMarketMakerPairs[from];


        if(from != owner() && to != owner()) {
            require(!_isBlacklisted[to], "The Peoples Token: Account is blacklisted");
            require(!_isBlacklisted[from], "The Peoples Token: Account is blacklisted");
        }

        if (
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet && to != liquidityWallet &&
            from != marketingWallet && to != marketingWallet &&
            from != salaryWallet && to != salaryWallet
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }
        
        bool takeFee = !_swapping;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        if (takeFee) {
            (uint256 returnAmount, uint256 fee) = _getCurrentTotalFee(isBuyFromLp, amount);
            amount = returnAmount;
            super._transfer(from, address(this), fee);
        }
        
        
        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }

        
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        if(!_swapping) {
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {}
        }
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(nativeTokensForHoldersFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }
    
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    
    function _getCurrentTotalFee(bool isBuyFromLp, uint256 amount) internal returns (uint256 returnAmount, uint256 fee) {
        uint256 _liquidityFee = isBuyFromLp ? liquidityFeeOnBuy : liquidityFeeOnSell;
        uint256 _marketingFee = isBuyFromLp ? marketingFeeOnBuy : marketingFeeOnSell;
        uint256 _salaryFee = isBuyFromLp ? salaryFeeOnBuy : salaryFeeOnSell;
        uint256 _holdersFee = isBuyFromLp ? holdersFeeOnBuy : holdersFeeOnSell;

        uint256 _totalFee = _liquidityFee.add(_marketingFee).add(_salaryFee).add(_holdersFee);

        fee = amount.mul(_totalFee).div(100);
    	returnAmount = amount.sub(fee);
    	_updateTokensToSwap(amount, _liquidityFee,_marketingFee, _salaryFee, _holdersFee);
    	return (returnAmount, fee);
    }
    
    function _updateTokensToSwap(uint256 amount, uint256 liquidityFee,uint256 marketingFee, uint256 salaryFee, uint256 holdersFee) private {
        _liquidityTokensToSwap = _liquidityTokensToSwap.add(amount.mul(liquidityFee).div(100));
    	_marketingTokensToSwap = _marketingTokensToSwap.add(amount.mul(marketingFee).div(100));
    	_salaryTokensToSwap = _salaryTokensToSwap.add(amount.mul(salaryFee).div(100));
    	_holdersTokensToSwap = _holdersTokensToSwap.add(amount.mul(holdersFee).div(100));
    }
    
    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_marketingTokensToSwap).add(_salaryTokensToSwap).add(_buyBackTokensToSwap).add(_holdersTokensToSwap);
        
        // Halve the amount of liquidity tokens
        uint256 tokensInTptForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForBNB = contractBalance.sub(tokensInTptForLiquidity);
        
        // initial BNB balance
        uint256 initialBNBBalance = address(this).balance;
        // Swap the TPT for BNB
        _swapTokensForBNB(amountToSwapForBNB); 
        // Get the balance, minus what we started with
        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);
        // Divvy up the BNB based on accrued tokens as % of total accrued
        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForSalary = bnbBalance.mul(_salaryTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForHolders = bnbBalance.mul(_holdersTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForLiquidity = bnbBalance.sub(bnbForMarketing).sub(bnbForSalary).sub(bnbForHolders);
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _salaryTokensToSwap = 0;
        _holdersTokensToSwap = 0;
        
        payable(salaryWallet).transfer(bnbForSalary);
        payable(marketingWallet).transfer(bnbForMarketing);
        
        _addLiquidity(tokensInTptForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensInTptForLiquidity);
        
        (bool success,) = address(dividendTracker).call{value: bnbForHolders}("");
        if(success) {
   	 		emit DividendsSent(bnbForHolders);
        }
    }
    
    
    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}



contract TPTDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    
    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    
    constructor() DividendPayingToken("TPT_Dividend_Tracker", "TPT_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 5000000 * (10**18); // Should Replace For Min. Treshold
    }
    
    function _transfer(address, address, uint256) pure internal override {
        require(false, "TPT_Dividend_Tracker: No transfers allowed");
    }
    
    function withdrawDividend() pure public override {
        require(false, "TPT_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TPT contract.");
    }
    
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }
    
    function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        require(minimumTokenBalanceForDividends != newValue, "TPT_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'.");
        minimumTokenBalanceForDividends = newValue;
    } 
    
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TPT_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "TPT_Dividend_Tracker: Cannot update claimWait to same value");
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
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
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
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
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
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
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