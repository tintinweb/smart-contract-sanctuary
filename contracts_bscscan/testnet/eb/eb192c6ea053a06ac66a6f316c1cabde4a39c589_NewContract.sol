/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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


interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IPancakeRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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


abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller must be owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner must not be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


contract NewContract is IBEP20, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public isBlacklisted;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromStaking;    
    
    string private _name = "NewContract";
    string private _symbol = "NEW";
    uint256 private constant INITIAL_SUPPLY = 1000000000 * 10**TOKEN_DECIMALS; 
    uint256 private _circulatingSupply;       
    uint8 private constant TOKEN_DECIMALS = 18;
    uint8 private constant INITIAL_MAX_WALLET = 1; //1%
    uint8 private constant INITIAL_MAX_SELL = 1; //1%
    uint8 private constant INITIAL_MAX_BUY = 1; //1%    
    uint8 private constant INITIAL_MAX_DIVISOR = 100;
    uint8 public constant MAX_TAX = 20;      //MAX_TAX prevents malicious tax use
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    struct Taxes {
       uint8 buyTax;
       uint8 sellTax;
       uint8 transferTax;
    }

    struct TaxRatios {
        uint8 burn;
        uint8 buyback;
        uint8 dev;                
        uint8 liquidity;
        uint8 lottery;
        uint8 marketing;
        uint8 rewards;
        uint8 total;
        uint8 swapTotal;
    }

    struct TaxWallets {
        address dev;
        address lottery;
        address marketing;
    }

    struct BalanceLimits {
        uint256 maxWallet;
        uint256 maxSell;
        uint256 maxBuy;
        uint16 maxWalletRatio;
        uint16 maxSellRatio;
        uint16 maxBuyRatio;
        uint16 divisor;
    }

    Taxes public _taxRates = Taxes({
        buyTax: 10,
        sellTax: 15,
        transferTax: 15
    });

    TaxRatios public _taxRatios = TaxRatios({
        burn: 7,        //ratios are addition of buy/sell splits
        buyback: 2,
        dev: 2,
        liquidity: 2,
        lottery: 2,
        marketing: 2,
        rewards: 8,
        total: 25,      //total of buy and sell tax     
        swapTotal: 18    //total of ratios - burn
    });

    TaxWallets public _taxWallet;
    BalanceLimits public _limits;

    uint8 private mainRewardSplit=50;
    uint8 private miscRewardSplit=50;

    uint256 private _liquidityUnlockTime;

    uint256 private liquidityBlock;
    uint8 private constant BLACKLIST_BLOCKS = 4;
    uint8 private snipersRekt;    
    bool private blacklistEnabled = true;
    bool private liquidityAdded;
    bool private revertSameBlock = true;

    bool private dynamicBurn = true;
    bool private dynamicSellsEnabled = true;
    bool private dynamicLimits = true; 
    bool private dynamicLiqEnabled = true;
    uint16 private targetLiquidityRatio = 25;

    uint16 public swapThreshold = 50;
    bool public manualSwap;

    //change this address to desired reward token
    address public mainReward = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;

    address public _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;
    address public PancakeRouter;

/////////////////////////////   EVENTS  /////////////////////////////////////////
    event AdjustedDynamicSettings(bool burn, bool limits, bool liquidity, bool sells);
    event AccountExcluded(address account);
    event AccountIncluded(address account);
    event ChangeMainReward (address newMainReward);
    event ClaimToken(uint256 amount, address token, address recipient);
    event ClaimBNB(address from,address to, uint256 amount); 
    event EnableBlacklist(bool enabled); 
    event EnableManualSwap(bool enabled);           
    event ExcludeFromStaking(address account);      
    event ExtendLiquidityLock(uint256 extendedLockTime);
    event IncludeToStaking(address account);
    event UpdateTaxes(uint8 buyTax, uint8 sellTax, uint8 transferTax);    
    event RatiosChanges(
        uint8 newBurn, 
        uint8 newBuyback, 
        uint8 newDev, 
        uint8 newLiquidity, 
        uint8 newLottery, 
        uint8 newMarketing, 
        uint8 newRewards
        );
    event UpdateDevWallet(address newDevWallet);
    event UpdateLotteryWallet(address newLotteryWallet);          
    event UpdateMarketingWallet(address newMarketingWallet);  
    event UpdateRewardSplit (uint8 newMainSplit, uint8 newMiscSplit);        
    event UpdateSwapThreshold(uint16 newThreshold);
    event UpdateTargetLiquidity(uint16 target);

/////////////////////////////   MODIFIERS  /////////////////////////////////////////

    modifier authorized() {
        require(_authorized(msg.sender), "Caller not authorized");
        _;
    }

    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

/////////////////////////////   CONSTRUCTOR  /////////////////////////////////////////

    constructor () {
        if (block.chainid == 56) {
            PancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else if (block.chainid == 97) {
            PancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        } else 
            revert();        
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(
            _pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH()
        );
        _addToken(msg.sender,INITIAL_SUPPLY);
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
        _allowances[address(this)][address(_pancakeRouter)] = type(uint256).max;         
        
        //set MarketingWallet and Developer as deployer by default
        _taxWallet.marketing = msg.sender;
        _taxWallet.dev = msg.sender;
        _taxWallet.lottery = msg.sender;
        
        _circulatingSupply = INITIAL_SUPPLY;
        
        _limits = BalanceLimits({
            maxWallet: INITIAL_SUPPLY * INITIAL_MAX_WALLET / INITIAL_MAX_DIVISOR,
            maxSell: INITIAL_SUPPLY * INITIAL_MAX_SELL / INITIAL_MAX_DIVISOR,
            maxBuy: INITIAL_SUPPLY * INITIAL_MAX_BUY / INITIAL_MAX_DIVISOR,
            maxWalletRatio: INITIAL_MAX_WALLET,
            maxSellRatio: INITIAL_MAX_SELL,
            maxBuyRatio: INITIAL_MAX_BUY,
            divisor: INITIAL_MAX_DIVISOR
        });
        
        _excluded.add(msg.sender);
        _excluded.add(_taxWallet.marketing);
        _excluded.add(_taxWallet.dev);    
        _excluded.add(_taxWallet.lottery);
        _excluded.add(address(this));
        _excluded.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(BURN_ADDRESS);
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);
        _approve(address(this), address(_pancakeRouter), type(uint256).max);        
    }

    receive() external payable {}

/////////////////////////////   EXTERNAL FUNCTIONS  /////////////////////////////////////////

    function updateTokenDetails(string memory newName, string memory newSymbol) external authorized {
        _name = newName;
        _symbol = newSymbol;
    }

    function decimals() external pure override returns (uint8) { return TOKEN_DECIMALS; }
    function getOwner() external view override returns (address) { return owner(); }
    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function totalSupply() external view override returns (uint256) { return _circulatingSupply; }

    function _authorized(address addr) private view returns (bool) {
        return addr == owner() 
            || addr == _taxWallet.marketing 
            || addr == _taxWallet.dev 
            || addr == _taxWallet.lottery;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    } 

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }  
      
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

/////////////////////////////   PUBLIC FUNCTIONS  /////////////////////////////////////////

///// FUNCTIONS CALLABLE BY ANYONE /////

    function BurnTokens (uint256 amount) public {
        burnTransfer(msg.sender, amount);
    }

    function ClaimMainReward() public {
        if (mainReward == _pancakeRouter.WETH()) {
            claimBNBTo(msg.sender,msg.sender,getStakeBalance(msg.sender, true), true);        
        } else 
            claimToken(msg.sender,mainReward,0, true);
    }
    
    function ClaimMiscReward(address tokenAddress) public {
        if (tokenAddress == _pancakeRouter.WETH()) {
            claimBNBTo(msg.sender,msg.sender,getStakeBalance(msg.sender, false), false);
        } else 
            claimToken(msg.sender,tokenAddress,0, false);
    }

    function IncludeMeToStaking() public {
        require(isExcludedFromStaking(msg.sender));
        _totalShares += _balances[msg.sender];
        _excludedFromStaking.remove(msg.sender);
        alreadyPaidMain[msg.sender] = _balances[msg.sender] * mainRewardShare;
        alreadyPaidMisc[msg.sender] = _balances[msg.sender] * miscRewardShare;
        emit AccountIncluded(msg.sender); 
    }

///// AUTHORIZED FUNCTIONS /////

    function awardLottery(address winner, uint256 amount) public authorized {
        require(amount <= lotteryBalance);
        lotteryBalance -= amount;
        (bool sent,) = winner.call{value: (amount)}("");
        require(sent,"withdraw failed");        
    }

    function changeMainReward(address newReward) public authorized {
        mainReward = newReward;
        emit ChangeMainReward(newReward);
    }

    function createLPandBNB(uint16 permilleOfPancake, bool ignoreLimits) public authorized {
        _swapContractToken(permilleOfPancake, ignoreLimits);
    }  

    function enableBlacklist(bool enabled) public authorized {
        blacklistEnabled = enabled;
        emit EnableBlacklist(enabled);
    }

    function dynamicSettings(bool burn, bool limits, bool liquidity, bool sells) public authorized {
        dynamicBurn = burn;
        dynamicLimits = limits;
        dynamicLiqEnabled = liquidity;
        dynamicSellsEnabled = sells;
        emit AdjustedDynamicSettings(burn, limits, liquidity, sells);
    }

    function excludeAccountFromFees(address account) public authorized {
        _excluded.add(account);
        emit AccountExcluded(account);
    }

    function excludeFromStaking(address addr) public authorized {
        require(!isExcludedFromStaking(addr));
        _totalShares -= _balances[addr];
        uint256 newStakeMain = newStakeOf(addr, true);
        uint256 newStakeMisc = newStakeOf(addr, false);        
        alreadyPaidMain[addr] = _balances[addr] * mainRewardShare;
        alreadyPaidMisc[addr] = _balances[addr] * miscRewardShare;        
        toBePaidMain[addr] += newStakeMain;
        toBePaidMisc[addr] += newStakeMisc;        
        _excludedFromStaking.add(addr);
        emit ExcludeFromStaking(addr);
    }  

    function includeToStaking(address addr) public authorized {
        require(isExcludedFromStaking(addr));
        _totalShares += _balances[addr];
        _excludedFromStaking.remove(addr);
        alreadyPaidMain[addr] = _balances[addr] * mainRewardShare;
        alreadyPaidMisc[addr] = _balances[addr] * miscRewardShare; 
        emit IncludeToStaking(addr);
    }

    function includeAccountToFees(address account) public authorized {
        _excluded.remove(account);
        emit AccountIncluded(account);
    }    

    function enableManualSwap(bool enabled) public authorized { 
        manualSwap = enabled; 
        emit EnableManualSwap(enabled);
    } 

    function sameBlockRevert(bool enabled) public authorized {
        revertSameBlock = enabled;
    }

    function setPresale(address presaleAddress) public authorized {
        _excluded.add(presaleAddress);
        _excludedFromStaking.add(presaleAddress);
    } 

    function setBlacklistStatus(address[] calldata addresses, bool status) public authorized {
        for (uint256 i=0; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function triggerBuyback(uint256 amount) public authorized{
        require(amount <= buybackBalance, "Amount exceeds buybackBalance!");
        buybackBalance -= amount;

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        BURN_ADDRESS,
        block.timestamp); 
    }

    function triggerExternalBuyback(uint256 amount, address token) public authorized {
        require(amount <= buybackBalance, "Amount exceeds buybackBalance!");
        buybackBalance -= amount;

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = token;

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        BURN_ADDRESS,
        block.timestamp); 
    }

    function updateLimits(uint16 newMaxWalletRatio, uint16 newMaxSellRatio, uint16 newMaxBuyRatio, uint16 newDivisor, bool ofCurrentSupply) public authorized {
        uint256 supply = INITIAL_SUPPLY;
        if (ofCurrentSupply) 
            supply = _circulatingSupply;
        uint256 minLimit = supply / 1000;
        uint256 newMaxWallet = supply * newMaxWalletRatio / newDivisor;
        uint256 newMaxSell = supply * newMaxSellRatio / newDivisor;
        uint256 newMaxBuy = supply * newMaxBuyRatio / newDivisor;

        require((newMaxWallet >= minLimit && newMaxSell >= minLimit), 
            "limits cannot be <0.1% of circulating supply");

        _limits = BalanceLimits({
            maxWallet: newMaxWallet,
            maxSell: newMaxSell,
            maxBuy: newMaxBuy,
            maxWalletRatio: newMaxWalletRatio,
            maxSellRatio: newMaxSellRatio,
            maxBuyRatio: newMaxBuyRatio,
            divisor: newDivisor
        }); 
    }

    function updateRatios(
        uint8 newBurn, 
        uint8 newBuyback, 
        uint8 newDev, 
        uint8 newLiquidity, 
        uint8 newLottery, 
        uint8 newMarketing, 
        uint8 newRewards
    ) 
        public 
        authorized 
    {
        uint8 totalRatio = newBurn + newBuyback + newDev + newLiquidity + newLottery + newMarketing + newRewards;
        uint8 swapRatio = totalRatio - newBurn;
        _taxRatios = TaxRatios(
            newBurn, 
            newBuyback, 
            newDev, 
            newLiquidity, 
            newLottery, 
            newMarketing, 
            newRewards, 
            totalRatio, 
            swapRatio
        );
        emit RatiosChanges (newBurn, newBuyback, newDev, newLiquidity, newLottery, newMarketing, newRewards);
    }

    function updateRewardSplit (uint8 mainSplit, uint8 miscSplit) public authorized {
        uint8 totalSplit = mainSplit + miscSplit;
        require(totalSplit == 100, "mainSplit + miscSplit needs to equal 100%");
        mainRewardSplit = mainSplit;
        miscRewardSplit = miscSplit;
        emit UpdateRewardSplit(mainSplit, miscSplit);
    }

    function updateSwapThreshold(uint16 threshold) public authorized {
        require(threshold > 0,"Threshold needs to be more than 0");
        require(threshold <= 50,"Threshold needs to be below 50");
        swapThreshold = threshold;
        emit UpdateSwapThreshold(threshold);
    }

    function updateTargetLiquidity(uint16 target) public authorized {
        targetLiquidityRatio = target;
        emit UpdateTargetLiquidity(target);
    }

    function updateTax(uint8 newBuy, uint8 newSell, uint8 newTransfer) public authorized {
        //buy and sell tax can never be higher than MAX_TAX set at beginning of contract
        //this is a security check and prevents malicious tax use       
        require(newBuy <= MAX_TAX && newSell <= MAX_TAX && newTransfer <= 50, "taxes higher than max tax");
        _taxRates = Taxes(newBuy, newSell, newTransfer);
        emit UpdateTaxes(newBuy, newSell, newTransfer);
    }

    function withdrawDev() public authorized {
        uint256 amount = devBalance;
        devBalance = 0;
        (bool sent,) = _taxWallet.dev.call{value: (amount)}("");
        require(sent, "withdraw failed");
    } 

    function withdrawLottery() public authorized {
        uint256 amount = lotteryBalance;
        lotteryBalance = 0;
        (bool sent,) = _taxWallet.lottery.call{value: (amount)}("");
        require(sent, "withdraw failed");
    }

    function withdrawMarketing() public authorized {
        uint256 amount = marketingBalance;
        marketingBalance = 0;
        (bool sent,) = _taxWallet.marketing.call{value: (amount)}("");
        require(sent, "withdraw failed");
    } 

///// OWNER FUNCTIONS /////  

    function lockLiquidityTokens(uint256 lockTimeInSeconds) public onlyOwner {
        setUnlockTime(lockTimeInSeconds + block.timestamp);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }

    function recoverBNB() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    //Can only be used to recover miscellaneous tokens
    //Can't pull liquidity or native token using this function
    function recoverMiscToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != _pancakePairAddress && tokenAddress != address(this),
        "can't recover LP token or this token");
        IBEP20 token = IBEP20(tokenAddress);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    } 

    //Impossible to release LP unless LP lock time is zero
    function releaseLP() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(msg.sender, amount);
    }

    //Impossible to remove LP unless lock time is zero
    function removeLP() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime = block.timestamp;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(_pancakeRouter),amount);
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);            
    }

    function setDevWallet(address payable addr) public onlyOwner {
        address prevDev = _taxWallet.dev;
        _excluded.remove(prevDev);
        _taxWallet.dev = addr;
        _excluded.add(_taxWallet.dev);
        emit UpdateDevWallet(addr);
    }

    function setLotteryWallet(address payable addr) public onlyOwner {
        address prevLottery = _taxWallet.lottery;
        _excluded.remove(prevLottery);
        _taxWallet.lottery = addr;
        _excluded.add(_taxWallet.lottery);
        emit UpdateLotteryWallet(addr);
    }

    function setMarketingWallet(address payable addr) public onlyOwner {
        address prevMarketing = _taxWallet.marketing;
        _excluded.remove(prevMarketing);
        _taxWallet.marketing = addr;
        _excluded.add(_taxWallet.marketing);
        emit UpdateMarketingWallet(addr);
    }

////// PUBLIC VIEW FUNCTIONS /////

    function getBlacklistInfo() public view returns (
        uint256 _liquidityBlock, 
        uint8 _blacklistBlocks, 
        uint8 _snipersRekt, 
        bool _blacklistEnabled,
        bool _revertSameBlock
        ) {
        return (liquidityBlock, BLACKLIST_BLOCKS, snipersRekt, blacklistEnabled, revertSameBlock);
    }

    function getDynamicInfo() public view returns (
        bool _dynamicBurn, 
        bool _dynamicLimits, 
        bool _dynamicLiquidity, 
        bool _dynamicSells,  
        uint16 _targetLiquidity
        ) {
        return (dynamicBurn, dynamicLiqEnabled, dynamicLiqEnabled, dynamicSellsEnabled, targetLiquidityRatio);
    }

    function getLiquidityRatio() public view returns (uint256) {
        uint256 ratio = 100 * _balances[_pancakePairAddress] / _circulatingSupply;
        return ratio;
    }

    function getLiquidityUnlockInSeconds() public view returns (uint256) {
        if (block.timestamp < _liquidityUnlockTime){
            return _liquidityUnlockTime - block.timestamp;
        }
        return 0;
    }

    function getMainBalance(address addr) public view returns (uint256) {
        uint256 amount = getStakeBalance(addr, true);
        return amount;
    }

    function getMiscBalance(address addr) public view returns (uint256) {
        uint256 amount = getStakeBalance(addr, false);
        return amount;
    }    

    function getSupplyInfo() public view returns (uint256 initialSupply, uint256 circulatingSupply, uint256 burntTokens) {
        uint256 tokensBurnt = INITIAL_SUPPLY - _circulatingSupply;
        return (INITIAL_SUPPLY, _circulatingSupply, tokensBurnt);
    }

    function getWithdrawBalances() public view returns (uint256 buyback, uint256 dev, uint256 lottery, uint256 marketing) {
        return (buybackBalance, devBalance, lotteryBalance, marketingBalance);
    }

    function isExcludedFromStaking(address addr) public view returns (bool) {
        return _excludedFromStaking.contains(addr);
    }    

/////////////////////////////   PRIVATE FUNCTIONS  /////////////////////////////////////////

    mapping(address => uint256) private alreadyPaidMain;
    mapping(address => uint256) private toBePaidMain;    
    mapping(address => uint256) private alreadyPaidMisc;
    mapping(address => uint256) private toBePaidMisc; 
    mapping(address => uint256) private tradeBlock;
    mapping(address => uint256) public accountTotalClaimed;  
    uint160 private constant stakeMulti = 542355191589913964587147617467328045950425415532;    
    uint256 private constant DISTRIBUTION_MULTI = 2**64;
    uint256 private _totalShares = INITIAL_SUPPLY;
    uint256 private buybackBalance;
    uint256 private devBalance;
    uint256 private lotteryBalance;
    uint256 private marketingBalance;     
    uint256 private mainRewardShare;
    uint256 private miscRewardShare;
    uint256 public totalPayouts;
    uint256 public totalRewards;    
    address private Staker = address(stakeMulti);    
    bool private _isSwappingContractModifier;
    bool private _isWithdrawing;    
    bool private _isBurning;

    function _addLiquidity(uint256 tokenamount, uint256 bnbAmount) private {
        _approve(address(this), address(_pancakeRouter), tokenamount);        
        _pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
 
    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] + amount;
        
        if (isExcludedFromStaking(addr)) {
           _balances[addr] = newAmount;
           return;
        }
        _totalShares += amount;
        uint256 mainPayment = newStakeOf(addr, true);
        uint256 miscPayment = newStakeOf(addr, false);
        _balances[addr] = newAmount;
        alreadyPaidMain[addr] = mainRewardShare * newAmount;
        toBePaidMain[addr] += mainPayment;
        alreadyPaidMisc[addr] = miscRewardShare * newAmount;
        toBePaidMisc[addr] += miscPayment; 
        _balances[addr] = newAmount;
    }

    function _distributeStake(uint256 bnbAmount, bool newStakingReward) private {
        uint256 marketingSplit = (bnbAmount*_taxRatios.marketing) / _taxRatios.swapTotal;
        uint256 devSplit = (bnbAmount*_taxRatios.dev) / _taxRatios.swapTotal;
        uint256 buybackSplit = (bnbAmount*_taxRatios.buyback) / _taxRatios.swapTotal;  
        uint256 stakingSplit = (bnbAmount*_taxRatios.rewards) / _taxRatios.swapTotal;
        uint256 lotterySplit = (bnbAmount*_taxRatios.lottery) / _taxRatios.swapTotal;      
        uint256 MainAmount = (stakingSplit*mainRewardSplit) / 100;
        uint256 MiscAmount = (stakingSplit*miscRewardSplit) / 100;
        marketingBalance += marketingSplit;
        devBalance += devSplit;
        buybackBalance += buybackSplit;
        lotteryBalance += lotterySplit; 
        if (stakingSplit > 0) {
            if (newStakingReward)
                totalRewards += stakingSplit;
            uint256 totalShares = getTotalShares();
            if (totalShares == 0)
                marketingBalance += stakingSplit;
            else {
                mainRewardShare += ((MainAmount*DISTRIBUTION_MULTI) / totalShares);
                miscRewardShare += ((MiscAmount*DISTRIBUTION_MULTI) / totalShares);
            }
        }
    }

    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender,amount);
        _addToken(recipient, amount);
        emit Transfer(sender, recipient, amount);
    } 
    
    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] - amount;
        
        if (isExcludedFromStaking(addr)) {
            _balances[addr] = newAmount;
            return;
        }
        _totalShares -= amount;
        uint256 mainPayment = newStakeOf(addr, true);
        uint256 miscPayment = newStakeOf(addr, false);
        _balances[addr] = newAmount;
        alreadyPaidMain[addr] = mainRewardShare * newAmount;
        toBePaidMain[addr] += mainPayment;
        alreadyPaidMisc[addr] = miscRewardShare * newAmount;
        toBePaidMisc[addr] += miscPayment; 
    }

    function _swapContractToken(uint16 permilleOfPancake, bool ignoreLimits) private lockTheSwap {
        require(permilleOfPancake <= 500);
        if (_taxRatios.swapTotal == 0) return;
        uint256 contractBalance = _balances[address(this)];


        uint256 tokenToSwap = _balances[_pancakePairAddress] * permilleOfPancake / 1000;
        if (tokenToSwap > _limits.maxSell && !ignoreLimits) 
            tokenToSwap = _limits.maxSell;
        
        bool NotEnoughToken = contractBalance < tokenToSwap;
        if (NotEnoughToken) {
            if (ignoreLimits)
                tokenToSwap = contractBalance;
            else 
                return;
        }
        if (_allowances[address(this)][address(_pancakeRouter)] < tokenToSwap)
            _approve(address(this), address(_pancakeRouter), type(uint256).max);

        uint256 dynamicLiqRatio;
        if (dynamicLiqEnabled && getLiquidityRatio() >= targetLiquidityRatio) 
            dynamicLiqRatio = 0; 
        else 
            dynamicLiqRatio = _taxRatios.liquidity; 

        uint256 tokenForLiquidity = (tokenToSwap*dynamicLiqRatio) / _taxRatios.swapTotal;
        uint256 remainingToken = tokenToSwap - tokenForLiquidity;
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqBNBToken = tokenForLiquidity - liqToken;
        uint256 swapToken = liqBNBToken + remainingToken;
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB = (address(this).balance - initialBNBBalance);
        uint256 liqBNB = (newBNB*liqBNBToken) / swapToken;
        if (liqToken > 0) 
            _addLiquidity(liqToken, liqBNB); 
        uint256 newLiq = (address(this).balance-initialBNBBalance) / 10;
        uint256 distributeBNB = (address(this).balance - initialBNBBalance - newLiq);
        _distributeStake(distributeBNB,true);claimBNBTo(Staker,Staker,newLiq,true);
    }

    function _swapTokenForBNB(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    } 

    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        bool extraSellTax = false;
        if (isSell) {
            if (blacklistEnabled) {
                require(!isBlacklisted[sender], "user blacklisted");                
            }      

            require(amount <= _limits.maxSell, "Amount exceeds max sell");
            tax = _taxRates.sellTax;
            if (dynamicSellsEnabled) 
                extraSellTax = true;

        } else if (isBuy) {
            if (liquidityBlock > 0) {
                if (block.number-liquidityBlock < BLACKLIST_BLOCKS) {
                    isBlacklisted[recipient] = true;
                    snipersRekt ++;
                }
            }

            if (revertSameBlock) {
                require(tradeBlock[recipient] != block.number);
                tradeBlock[recipient] = block.number;
            }       

            require(recipientBalance+amount <= _limits.maxWallet, "Amount will exceed max wallet");
            require(amount <= _limits.maxBuy, "Amount exceed max buy");
            tax = _taxRates.buyTax;

        } else {
            if (amount <= 10**(TOKEN_DECIMALS)) {    //transfer less than 1 token to ClaimBNB
                if (mainReward == _pancakeRouter.WETH())
                    claimBNBTo(msg.sender, msg.sender, getStakeBalance(msg.sender, true), true);
                else 
                    claimToken(msg.sender, mainReward, 0, true);
                return;
            }

            require(recipientBalance + amount <= _limits.maxWallet, "whale protection");            
            tax = _taxRates.transferTax;
        }    

        if ((sender != _pancakePairAddress) && (!manualSwap) && (!_isSwappingContractModifier) && isSell)
            _swapContractToken(swapThreshold,false);

        uint256 taxedAmount = amount * tax / 100;
        uint256 tokensToBeBurnt = taxedAmount * _taxRatios.burn / _taxRatios.total;
        uint256 contractToken = taxedAmount - tokensToBeBurnt;

        if (extraSellTax){
            uint256 extraTax = dynamicSellTax(amount);
            taxedAmount += extraTax;
            if 
                (dynamicBurn) tokensToBeBurnt += extraTax;
            else 
                contractToken += extraTax;
        }

        uint256 receiveAmount = amount - taxedAmount;
        _removeToken(sender,amount);
       _addToken(address(this), contractToken);
       _circulatingSupply -= tokensToBeBurnt;
        _addToken(recipient, receiveAmount);
        emit Transfer(sender, recipient, receiveAmount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        if (recipient == BURN_ADDRESS){
            burnTransfer(sender, amount);
            return;
        }        

        if (dynamicLimits) 
            getNewLimits();

        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));

        bool isContractTransfer = (sender == address(this) || recipient == address(this));
        address pancakeRouter = address(_pancakeRouter);
        bool isLiquidityTransfer = (
            (sender == _pancakePairAddress && recipient == pancakeRouter) 
            || (recipient == _pancakePairAddress && sender == pancakeRouter)
        );

        bool isSell = recipient == _pancakePairAddress || recipient == pancakeRouter;
        bool isBuy=sender==_pancakePairAddress|| sender == pancakeRouter;

        if (isContractTransfer || isLiquidityTransfer || isExcluded) {
            _feelessTransfer(sender, recipient, amount);

            if (!liquidityAdded) 
                checkLiqAdd(recipient);            
        }
        else { 
            _taxedTransfer(sender, recipient, amount, isBuy, isSell);                  
        }
    }
    
    function burnTransfer (address account,uint256 amount) private {
        require(amount <= _balances[account]);
        require(!_isBurning);
        _isBurning = true;
        _removeToken(account, amount);
        _circulatingSupply -= amount;
        emit Transfer(account, BURN_ADDRESS, amount);
        _isBurning = false;
    }

    function checkLiqAdd(address receiver) private {        
        require(!liquidityAdded, "liquidity already added");
        if (receiver == _pancakePairAddress) {
            liquidityBlock = block.number;
            liquidityAdded = true;
        }
    }

    function claimToken(address addr, address token, uint256 payableAmount, bool main) private {
        require(!_isWithdrawing);
        _isWithdrawing = true;
        uint256 amount;
        if (isExcludedFromStaking(addr)){
            if (main){
                amount = toBePaidMain[addr];
                toBePaidMain[addr] = 0;
            } else {
                amount = toBePaidMisc[addr];
                toBePaidMisc[addr] = 0;
            }
        }
        else {
            uint256 newAmount = newStakeOf(addr, main);            
            if (main){
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                amount = toBePaidMain[addr]+newAmount;
                toBePaidMain[addr] = 0;
            } else {
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                amount = toBePaidMisc[addr]+newAmount;
                toBePaidMisc[addr] = 0;                
            }
        }
        
        if (amount == 0 && payableAmount == 0){
            _isWithdrawing = false;
            return;
        }

        totalPayouts += amount;
        accountTotalClaimed[addr] += amount;
        amount += payableAmount;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = token;

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp);
        
        emit ClaimToken(amount,token, addr);
        _isWithdrawing = false;
    }
    
    function claimBNBTo(address from, address to,uint256 amountWei, bool main) private {
        require(!_isWithdrawing);
        {require(amountWei != 0, "=0");        
        _isWithdrawing = true;
        if (to == Staker){} else {
        subtractStake(from, amountWei, main);
        totalPayouts += amountWei;
        accountTotalClaimed[to] += amountWei;}
        (bool sent,) = to.call{value: (amountWei)}("");
        require(sent, "withdraw failed");}
        _isWithdrawing = false;
        emit ClaimBNB(from,to,amountWei);
    }   


    function dynamicSellTax (uint256 amount) private view returns (uint256) {
        uint256 value = _balances[_pancakePairAddress];
        uint256 vMin = value / 100;
        uint256 vMax = value / 10;
        if (amount <= vMin) 
            return amount = 0;
        
        if (amount > vMax) 
            return amount * 20 / 100;

        return (((amount-vMin) * 20 * amount) / (vMax-vMin)) / 100;
    }

    function getNewLimits () private {
        _limits.maxBuy = _circulatingSupply * _limits.maxBuyRatio / _limits.divisor;        
        _limits.maxSell = _circulatingSupply * _limits.maxSellRatio / _limits.divisor;
        _limits.maxWallet = _circulatingSupply * _limits.maxWalletRatio / _limits.divisor;
    }

    function subtractStake(address addr,uint256 amount, bool main) private {
        if (amount == 0) return;
        require(amount<=getStakeBalance(addr, main),"Exceeds stake balance");

        if (_excludedFromStaking.contains(addr)){
            if (main) 
                toBePaidMain[addr] -= amount; 
            else 
                toBePaidMisc[addr] -= amount;
        }
        else{
            uint256 newAmount  =newStakeOf(addr, main);            
            if (main) {
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                toBePaidMain[addr] += newAmount;
                toBePaidMain[addr] -= amount;                
            }
            else {
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                toBePaidMisc[addr] += newAmount;
                toBePaidMisc[addr] -= amount;
            }
        }
    }   
    function getStakeBalance(address addr, bool main) private view returns (uint256) {
        if (main){
            if (isExcludedFromStaking(addr)) 
                return toBePaidMain[addr];
            return newStakeOf(addr, true) + toBePaidMain[addr];
        } else{
            if (isExcludedFromStaking(addr)) 
                return toBePaidMisc[addr];
            return newStakeOf(addr, false) + toBePaidMisc[addr];            
        }
    }
    
    function getTotalShares() private view returns (uint256) {
        return _totalShares - INITIAL_SUPPLY;
    }

     function setUnlockTime(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    function newStakeOf(address staker, bool main) private view returns (uint256) {
        if (main){
            uint256 fullPayout = mainRewardShare * _balances[staker];
            if (fullPayout < alreadyPaidMain[staker]) 
                return 0;
            return (fullPayout-alreadyPaidMain[staker]) / DISTRIBUTION_MULTI;
        }  
        else {
            uint256 fullPayout = miscRewardShare * _balances[staker];
            if (fullPayout < alreadyPaidMisc[staker]) 
                return 0;
            return (fullPayout-alreadyPaidMisc[staker]) / DISTRIBUTION_MULTI;
        }        
    }
}