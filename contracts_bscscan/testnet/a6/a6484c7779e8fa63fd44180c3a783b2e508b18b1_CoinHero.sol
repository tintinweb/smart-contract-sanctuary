/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

pragma abicoder v2;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

 
    function allowance(address owner, address spender) external view returns (uint256);

  
    function approve(address spender, uint256 amount) external returns (bool);

 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

   
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

  
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

  
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

 
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
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

struct Balances {
    uint256 reflection;
    uint256 tokens;
}

struct TokenStats {
    uint256 totalReflection;
    uint256 totalTokens;
    uint256 totalFees;
    uint256 totalExcludedReflection;
    uint256 totalExcludedTokens;
    uint256 liquidityTokens;
}

struct ExemptionStats {
    bool isExcluded;
    bool isExcludedFromFee;
}

struct TaxRates {
    uint32 instantBoost;
    uint32 charity;
    uint32 marketing;
    uint32 liquidity;
    uint32 burn;
    uint32 communityBoost;
    uint32 totalTaxRate;
}

struct Vaults {
    address charityVault;
    address marketingVault;
    address communityBoostVault;
}

struct CalculationParameters {
    uint256 reflectionAmount;
    uint256 reflectionTransferAmount;
    uint256 tokenTransferAmount;
}

struct TaxCalculationParameters {
    uint256 instantBoostValue;
    uint256 instantBoostReflectionValue;
    uint256 charityValue;
    uint256 charityReflectionValue;
    uint256 marketingValue;
    uint256 marketingReflectionValue;
    uint256 liquidityValue;
    uint256 liquidityReflectionValue;
    uint256 burnValue;
    uint256 burnReflectionValue;
    uint256 communityBoostValue;
    uint256 communityBoostReflectionValue;
    uint256 tokenTaxSum;
    uint256 reflectionTaxSum;
}

interface IPancakeRouter01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface ICommunityBooster {
    function transferCallback(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

contract CoinHero is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    string public constant name = "miniBabyDoge";
    string public constant symbol = "MBD";
    uint8 public constant decimals = 9;
    uint256 public constant TOTAL_SUPPLY = 10e23;
    uint256 private constant _MAX_UINT = ~uint256(0);
    uint8 private constant _HUNDRED_PERCENT = 100;
    uint256 private _TOTAL_REFLECTION = (_MAX_UINT - _MAX_UINT.mod(TOTAL_SUPPLY));

    TokenStats internal _stats = TokenStats(_TOTAL_REFLECTION, TOTAL_SUPPLY, 0, 0, 0, 0);
    TaxRates internal _taxRates = TaxRates(2, 2, 2, 2, 2, 0, 10);
    Vaults internal _vaults;

    uint256 internal tokenLiquidityThreshold = 50e14;
    bool private _isProvidingLiquidity = true;
    bool private _liquidityMutex = false;
    bool private _isUpdatingHolderCount = false;
    uint256 startDate;
    uint256 private additionalLaunchTax = 15;
    uint256 private dayScale = 15;


    IPancakeRouter02 public immutable router;
    address public immutable pair;

    ICommunityBooster public communityBooster;

    mapping(address => Balances) private _balances;
    mapping(address => ExemptionStats) private _exemptions;
    mapping(address => mapping(address => uint256)) private _allowances;

    event LiquidityProvided(uint256 tokenAmount, uint256 nativeAmount, uint256 exchangeAmount);
    event LiquidityProvisionStateChanged(bool newState);
    event LiquidityThresholdUpdated(uint256 newThreshold);
    event AccountExclusionStateChanged(address account, bool excludeFromReward, bool excludeFromFee);
    event CountingHoldersStateChanged(bool newState);
    event TaxRatesUpdated(uint256 newTotalTaxRate);
    event VaultsUpdated(address charityVault, address marketingVault, address communityBoostVault);
    event VaultDistribution(address vault);
    event CommunityBoosterUpdated(address newCommunityBooster);
    event Burn(uint256 amount);

    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

    // constructor
    constructor() {
        address deployer = _msgSender();
        TokenStats storage stats = _stats;
        address pancakeRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

        uint256 initialRate = _stats.totalReflection.div(_stats.totalTokens);
        uint256 tokensToBurn = _stats.totalTokens.div(2);
        uint256 reflectionToBurn = tokensToBurn.mul(initialRate);
        stats.totalTokens = _stats.totalTokens.sub(tokensToBurn);
        stats.totalReflection = _stats.totalReflection.sub(reflectionToBurn);

        _balances[deployer].reflection = stats.totalReflection;
        emit Transfer(address(0), deployer, _stats.totalTokens);
        emit Burn(tokensToBurn);

        IPancakeRouter02 _router = IPancakeRouter02(pancakeRouter);
        router = _router;

        _exemptions[deployer].isExcludedFromFee = true;
        _exemptions[address(this)].isExcludedFromFee = true;

        pair = IPancakeFactory(_router.factory()).createPair(address(this), _router.WETH());
    }

    // fallbacks
    receive() external payable {}

    // external
    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function circulatingSupply() external view returns (uint256) {
        return _stats.totalTokens;
    }

    function totalFees() external view returns (uint256) {
        return _stats.totalFees;
    }
    

    function additionalTaxAmount() external view returns (uint256) {
        uint256 dayCount = (block.timestamp - startDate) / 86400;
        uint256 earlyAddon = 0;
        
        if (dayCount <= dayScale) {
            earlyAddon = (dayScale - dayCount) * additionalLaunchTax.div(dayScale);
        }
        
        return earlyAddon;

    }


    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "MBD error transfer"));
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require((amount == 0) || (_allowances[_msgSender()][spender] == 0), "MBD: approve from non-zero to non-zero allowance");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 value) external returns (bool) {
        uint256 newValue = allowance(_msgSender(), spender).add(value);
        _approve(_msgSender(), spender, newValue);
        return true;
    }

    function setStartDate(uint256 _startDate) public onlyOwner() {
        require(startDate == 0, "startDate");
        startDate = _startDate;
    }
    
    function setAdditionalTaxValue(uint256 _launchTax, uint256 _dayscale) public onlyOwner() {
        additionalLaunchTax = _launchTax;
        dayScale = _dayscale;
    }


    function decreaseAllowance(address spender, uint256 value) external returns (bool) {
        uint256 oldValue = allowance(_msgSender(), spender);
        require(oldValue >= value, "MBD: not 0");
        uint256 newValue = oldValue.sub(value);
        _approve(_msgSender(), spender, newValue);
        return true;
    }

    function setVaultsAddresses(
        address charity,
        address marketing,
        address community
    ) external onlyOwner {
        Vaults storage vaults = _vaults;

        vaults.charityVault = charity;
        vaults.marketingVault = marketing;
        vaults.communityBoostVault = community;

        _exemptions[vaults.charityVault].isExcluded = true;
        _exemptions[vaults.marketingVault].isExcluded = true;
        _exemptions[vaults.communityBoostVault].isExcluded = true;

        emit VaultsUpdated(charity, marketing, community);
    }

    function updateTaxes(TaxRates calldata newTaxRates) external onlyOwner {
        _taxRates = newTaxRates;

        emit TaxRatesUpdated(_taxRates.totalTaxRate);
    }

    function setCommunityBooster(address booster) external onlyOwner {
        communityBooster = ICommunityBooster(booster);

        emit CommunityBoosterUpdated(booster);
    }

    function updateLiquidityThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 0, "MBD: Cannot set threshold to zero");
        tokenLiquidityThreshold = threshold;

        emit LiquidityThresholdUpdated(tokenLiquidityThreshold);
    }

    function updateLiquidityProvisionState(bool state) external onlyOwner {
        _isProvidingLiquidity = state;

        emit LiquidityProvisionStateChanged(_isProvidingLiquidity);
    }

    function updateHolderStatisticState(bool state) external onlyOwner {
        _isUpdatingHolderCount = state;

        emit CountingHoldersStateChanged(_isUpdatingHolderCount);
    }

    function updateAccountExclusionState(
        address account,
        bool excludeFromReward,
        bool excludeFromFees
    ) external onlyOwner {
        TokenStats storage stats = _stats;
        if (excludeFromReward && !_exemptions[account].isExcluded) {
            _balances[account].tokens = tokenFromReflection(_balances[account].reflection);
            stats.totalExcludedReflection = _stats.totalExcludedReflection.add(_balances[account].reflection);
            stats.totalExcludedTokens = _stats.totalExcludedTokens.add(_balances[account].tokens);
        }
        if (!excludeFromReward && _exemptions[account].isExcluded) {
            stats.totalExcludedReflection = _stats.totalExcludedReflection.sub(_balances[account].reflection);
            stats.totalExcludedTokens = _stats.totalExcludedTokens.sub(_balances[account].tokens);

            _balances[account].tokens = 0;
        }

        _exemptions[account].isExcludedFromFee = excludeFromFees;
        _exemptions[account].isExcluded = excludeFromReward;

        emit AccountExclusionStateChanged(account, excludeFromReward, excludeFromFees);
    }

    // public

    function balanceOf(address account) public view override returns (uint256) {
        if (_exemptions[account].isExcluded) return _balances[account].tokens;
        return tokenFromReflection(_balances[account].reflection);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function reflectionFromToken(uint256 amountTokens, bool deductFees) public view returns (uint256) {
        require(amountTokens <= _stats.totalTokens, "MBD: < total supply");
        (CalculationParameters memory params, ) = calculateValues(amountTokens, deductFees, address(0));
        return params.reflectionTransferAmount;
    }

    // internal
    function tokenFromReflection(uint256 reflectionAmount) internal view returns (uint256) {
        require(reflectionAmount <= _stats.totalReflection, "MBD: <= total reflection");
        uint256 rate = calculateReflectionRate();

        return reflectionAmount.div(rate);
    }

    function calculateValues(uint256 tokenAmount, bool isTakingFees, address from)
    internal
    view
    returns (CalculationParameters memory, TaxCalculationParameters memory)
    {
        uint256 rate = calculateReflectionRate();

        CalculationParameters memory params = CalculationParameters(0, 0, 0);
        TaxCalculationParameters memory taxParams = TaxCalculationParameters(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        taxParams = isTakingFees ? calculateTaxes(_taxRates, tokenAmount, rate, from) : taxParams;

        params.reflectionAmount = tokenAmount.mul(rate);

        if (isTakingFees) {
            params.tokenTransferAmount = tokenAmount.sub(taxParams.tokenTaxSum);
            params.reflectionTransferAmount = params.reflectionAmount.sub(taxParams.reflectionTaxSum);
        } else {
            params.tokenTransferAmount = tokenAmount;
            params.reflectionTransferAmount = params.reflectionAmount;
        }

        return (params, taxParams);
    }

    function calculateReflectionRate() internal view returns (uint256) {
        (uint256 reflectionSupply, uint256 tokenSupply) = calculateActualSupply();

        return reflectionSupply.div(tokenSupply);
    }

   function calculateTaxes(
        TaxRates memory taxes,
        uint256 tokenAmount,
        uint256 rate,
        address from
    ) internal view returns (TaxCalculationParameters memory) {
        TaxCalculationParameters memory params;


        uint256 dayCount = (block.timestamp - startDate) / 86400;
        uint256 earlyAddon;
        
        if (from != address(pair) && dayCount <= dayScale) {
            earlyAddon = (dayScale - dayCount) * additionalLaunchTax.div(dayScale);
        }
       
        params.instantBoostValue = tokenAmount.mul(taxes.instantBoost).div(_HUNDRED_PERCENT);
        params.instantBoostReflectionValue = params.instantBoostValue.mul(rate);

        params.charityValue = tokenAmount.mul(taxes.charity).div(_HUNDRED_PERCENT);
        params.charityReflectionValue = params.charityValue.mul(rate);

        params.marketingValue = tokenAmount.mul(taxes.marketing).div(_HUNDRED_PERCENT);
        params.marketingReflectionValue = params.marketingValue.mul(rate);

        params.liquidityValue = tokenAmount.mul(taxes.liquidity).div(_HUNDRED_PERCENT);
        params.liquidityReflectionValue = params.liquidityValue.mul(rate);

        params.burnValue = tokenAmount.mul(taxes.burn).div(_HUNDRED_PERCENT);
        params.burnReflectionValue = params.burnValue.mul(rate);

        params.communityBoostValue = tokenAmount.mul(taxes.communityBoost).div(_HUNDRED_PERCENT);
        params.communityBoostReflectionValue = params.communityBoostValue.mul(rate);

        params.tokenTaxSum = tokenAmount.mul(taxes.totalTaxRate+earlyAddon).div(_HUNDRED_PERCENT);
        params.reflectionTaxSum = params.tokenTaxSum.mul(rate);

        return params;
    }
    
    function calculateActualSupply() internal view returns (uint256, uint256) {
        uint256 reflectionSupply = _stats.totalReflection;
        uint256 tokenSupply = _stats.totalTokens;

        reflectionSupply = reflectionSupply.sub(_stats.totalExcludedReflection);
        tokenSupply = tokenSupply.sub(_stats.totalExcludedTokens);

        if (reflectionSupply < _stats.totalReflection.div(_stats.totalTokens)) return (_stats.totalReflection, _stats.totalTokens);

        return (reflectionSupply, tokenSupply);
    }

    function extendedTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        bool isFromExcluded = _exemptions[sender].isExcluded;
        bool isToExcluded = _exemptions[recipient].isExcluded;

        bool takeFees = !(_exemptions[sender].isExcludedFromFee || _exemptions[recipient].isExcludedFromFee);

        if (isFromExcluded || isToExcluded) {
            extendedTransferExcluded(sender, recipient, amount, isToExcluded, isFromExcluded, takeFees);
        } else {
            extendedTransferStandard(sender, recipient, amount, takeFees);
        }
    }

    function extendedTransferStandard(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFees
    ) internal {

        (CalculationParameters memory params, TaxCalculationParameters memory taxParams) = calculateValues(amount, takeFees, sender);

        _balances[sender].reflection = _balances[sender].reflection.sub(
            params.reflectionAmount,
            "MBD error transfer"
        );
        _balances[recipient].reflection = _balances[recipient].reflection.add(params.reflectionTransferAmount);

        if (_exemptions[address(this)].isExcluded)
            _balances[address(this)].tokens = _balances[address(this)].tokens.add(taxParams.liquidityValue);

        _balances[address(this)].reflection = _balances[address(this)].reflection.add(taxParams.liquidityReflectionValue);

        if (takeFees) {
            collectTaxes(taxParams);
            collectVaultTaxes(taxParams, sender);
        }
    }

    function extendedTransferExcluded(
        address sender,
        address recipient,
        uint256 amount,
        bool isToExcluded,
        bool isFromExcluded,
        bool takeFees
    ) internal {
        (CalculationParameters memory params, TaxCalculationParameters memory taxParams) = calculateValues(amount, takeFees, sender);
        TokenStats storage stats = _stats;

        if (isToExcluded && isFromExcluded) {
            _balances[sender].reflection = _balances[sender].reflection.sub(
                params.reflectionAmount,
                "MBD error transfer"
            );
            _balances[sender].tokens = _balances[sender].tokens.sub(amount, "MBD error transfer");
            _balances[recipient].reflection = _balances[recipient].reflection.add(params.reflectionTransferAmount);
            _balances[recipient].tokens = _balances[recipient].tokens.add(params.tokenTransferAmount);
        } else if (isToExcluded) {
            _balances[sender].reflection = _balances[sender].reflection.sub(
                params.reflectionAmount,
                "MBD error transfer"
            );

            _balances[recipient].reflection = _balances[recipient].reflection.add(params.reflectionTransferAmount);
            _balances[recipient].tokens = _balances[recipient].tokens.add(params.tokenTransferAmount);

            // since the transfer is to an excluded account, we have to keep account of the total excluded reflection amount (add)
            stats.totalExcludedReflection = _stats.totalExcludedReflection.add(params.reflectionTransferAmount);
            stats.totalExcludedTokens = _stats.totalExcludedTokens.add(params.tokenTransferAmount);
        } else {
            _balances[sender].reflection = _balances[sender].reflection.sub(
                params.reflectionAmount,
                "MBD error transfer"
            );
            _balances[sender].tokens = _balances[sender].tokens.sub(
                params.tokenTransferAmount,
                "MBD error transfer"
            );

            _balances[recipient].reflection = _balances[recipient].reflection.add(params.reflectionTransferAmount);

            // since the transfer is from an excluded account, we have to keep account of the total excluded reflection amount (remove)
            stats.totalExcludedReflection = _stats.totalExcludedReflection.sub(params.reflectionTransferAmount);
            stats.totalExcludedTokens = _stats.totalExcludedTokens.sub(params.tokenTransferAmount);
        }

        if (_exemptions[address(this)].isExcluded)
            _balances[address(this)].tokens = _balances[address(this)].tokens.add(taxParams.liquidityValue);

        _balances[address(this)].reflection = _balances[address(this)].reflection.add(taxParams.liquidityReflectionValue);

        if (takeFees) {
            collectTaxes(taxParams);
            collectVaultTaxes(taxParams, sender);
        }
    }

    bool _sendNative = true;
    
    function setSendNative(bool _v) public onlyOwner {
        _sendNative = _v;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "MBD: transfer to the zero address");
        require(from != address(0), "MBD: transfer from the zero address");
        require(amount > 0, "MBD: Transfer amount must be greater than zero");
        
        if(!_exemptions[from].isExcludedFromFee && !_exemptions[to].isExcludedFromFee && !_exemptions[tx.origin].isExcludedFromFee) {
            require(amount <= (TOTAL_SUPPLY) / (10**3), "Transfer amount exceeds 0.1% of the supply.");
        }

        if (from != address(pair) && !_liquidityMutex) {
            if (_isProvidingLiquidity) {
                provideLiquidity();
            }
            if (_sendNative) {
                sendNative(_vaults.charityVault);
                sendNative(_vaults.marketingVault);
            }
        }

        if (_isUpdatingHolderCount) communityBooster.transferCallback(from, to, amount);

        extendedTransfer(from, to, amount);

        emit Transfer(from, to, amount);
    }

    function collectTaxes(TaxCalculationParameters memory params) internal {
        TokenStats storage stats = _stats;
        stats.totalReflection = _stats.totalReflection.sub(params.instantBoostReflectionValue);
        stats.totalFees = _stats.totalFees.add(params.instantBoostValue);

        burn(params.burnValue, params.burnReflectionValue);
    }

    function collectVaultTaxes(TaxCalculationParameters memory params, address sender) internal {
        TokenStats storage stats = _stats;

        _balances[_vaults.charityVault].tokens = _balances[_vaults.charityVault].tokens.add(params.charityValue);
        _balances[_vaults.charityVault].reflection = _balances[_vaults.charityVault].reflection.add(params.charityReflectionValue);
        stats.totalExcludedReflection = _stats.totalExcludedReflection.add(params.charityReflectionValue);
        stats.totalExcludedTokens = _stats.totalExcludedTokens.add(params.charityValue);

        emit Transfer(sender, _vaults.charityVault, params.charityValue);
        emit VaultDistribution(_vaults.charityVault);

        _balances[_vaults.marketingVault].tokens = _balances[_vaults.marketingVault].tokens.add(params.marketingValue);
        _balances[_vaults.marketingVault].reflection = _balances[_vaults.marketingVault].reflection.add(params.marketingReflectionValue);
        stats.totalExcludedReflection = _stats.totalExcludedReflection.add(params.marketingReflectionValue);
        stats.totalExcludedTokens = _stats.totalExcludedTokens.add(params.marketingValue);
        emit Transfer(sender, _vaults.marketingVault, params.marketingValue);
        emit VaultDistribution(_vaults.marketingVault);

        if (params.communityBoostValue > 0) {
            _balances[_vaults.communityBoostVault].tokens = _balances[_vaults.communityBoostVault].tokens.add(params.communityBoostValue);
            _balances[_vaults.communityBoostVault].reflection = _balances[_vaults.communityBoostVault].reflection.add(
                params.communityBoostReflectionValue
            );
            stats.totalExcludedReflection = _stats.totalExcludedReflection.add(params.communityBoostReflectionValue);
            stats.totalExcludedTokens = _stats.totalExcludedTokens.add(params.communityBoostValue);
            
            emit Transfer(sender, _vaults.communityBoostVault, params.communityBoostValue);
            emit VaultDistribution(_vaults.communityBoostVault);
        }
    }

    function burn(uint256 tokenAmount, uint256 reflectionAmount) internal {
        TokenStats storage stats = _stats;
        stats.totalTokens = _stats.totalTokens.sub(tokenAmount);
        stats.totalReflection = _stats.totalReflection.sub(reflectionAmount);
        emit Burn(tokenAmount);
    }

    //private
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(spender != address(0), "MBD: approve to the zero address");
        require(owner != address(0), "MBD: approve from the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function provideLiquidity() private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            contractBalance = tokenLiquidityThreshold;
            uint256 exchangeAmount = contractBalance.div(2);
            uint256 tokenAmount = contractBalance.sub(exchangeAmount);

            uint256 ignore = address(this).balance;
            exchangeTokenToNativeCurrency(exchangeAmount);
            uint256 profit = address(this).balance.sub(ignore);

            addToLiquidityPool(tokenAmount, profit);
            emit LiquidityProvided(exchangeAmount, profit, tokenAmount);
        }
    }

    function sendNative(address account) internal mutexLock {
        uint256 balance = balanceOf(account);
        
        if (balance >= tokenLiquidityThreshold) {
            _allowances[account][address(this)] = balance;   
            extendedTransfer(account, address(this), balance);
    
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();
            _approve(address(this), address(router), balance);
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, path, account, block.timestamp);
        }
    }

    function exchangeTokenToNativeCurrency(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addToLiquidityPool(uint256 tokenAmount, uint256 nativeAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: nativeAmount}(address(this), tokenAmount, 0, 0, address(0), block.timestamp);
    }
}