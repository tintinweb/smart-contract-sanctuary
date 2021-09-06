/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
// File: contracts/IPancakeFactory.sol


pragma solidity ^0.8.3;


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
// File: contracts/IPancakeRouter01.sol


pragma solidity ^0.8.3;

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
// File: contracts/IPancakeRouter02.sol


pragma solidity ^0.8.3;


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
// File: contracts/Structs.sol


pragma solidity ^0.8.3;

struct Vaults {
    address devVault;
    address marketingVault;
    address rewardsVault;
}

struct Balances {
    uint256 reflection;
    uint256 tokens;
    uint256 cashbackRate;
    uint256 totalCashBackClaim;
    bool isBusiness;
    bool isRegistered;
    bool isProcessed;
    bool isExcluded;
    bool isExcludedFromFee;
}

struct TokenRates {
    uint256 rewards;
    uint256 marketing;
    uint256 liquidity;
    uint256 totalTaxRate;
}

struct TokenInfo {
    uint256 totalReflection;
    uint256 totalTokens;
    uint256 totalFees;
    uint256 totalExcludedReflection;
    uint256 totalExcludedTokens;
    uint256 liquidityTokens;
}

struct ComputeData {
    uint256 reflectionAmount;
    uint256 reflectionTransferAmount;
    uint256 tokenTransferAmount;
}

struct TaxData {
    uint256 rewardsValue;
    uint256 rewardsReflectionValue;
    uint256 marketingValue;
    uint256 marketingReflectionValue;
    uint256 liquidityValue;
    uint256 liquidityReflectionValue;
    uint256 tokenTaxSum;
    uint256 reflectionTaxSum;
}
// File: contracts/util/SafeMath.sol


pragma solidity ^0.8.3;

//"https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/Context.sol


pragma solidity ^0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;

    }
}

// File: contracts/util/Ownable.sol


pragma solidity ^0.8.3;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

    }
}

// File: contracts/IBEP20.sol


pragma solidity ^0.8.3;

//https://docs.binance.org/smart-chain/developer/IBEP20.sol
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/NomadTravelToken.sol


pragma solidity ^0.8.3;






                               

contract NomadTravelToken is IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => Balances) private _token_balance;
    mapping(address => mapping(address => uint256)) private _hodler_allowances;

    bool internal _saleFinish = true;
    bool internal _vaultSet = false;
    bool internal _liquifyLock = false;
    bool private _isAlowingLiquidity = false;
    string internal _symbol = "NTT";
    string internal _name = "NomadTravelToken";
    uint8 internal _decimals = 18;
    uint256 internal _totalSupply = 1 * 10**15 * 10**18;
    uint256 internal tokensPerEth = 22500000000e18;
    uint256 internal totalDistributed = 0;
    uint256 internal _tokenLiquidityTax = 2;
    uint256 internal _tokenRewardsTax = 1;
    uint256 internal _tokenMarketingTax = 1;
    uint256 internal _maxTokenTransfer = 4000000000000e18;
    uint256 internal _liquidThreshold = 45000000000e18;
    uint256 internal constant _minCost = 1 ether / 10; // 0.1 Ether
    uint256 internal constant _maxCost = 100 ether;
    uint256 private constant _MAX_UINT = ~uint256(0);
    uint256 private _total_reflected_token = (_MAX_UINT - _MAX_UINT.mod(_totalSupply));
    uint8 private constant _HUNDRED_PERCENT = 100;

    IPancakeRouter02 public immutable router;
    address public immutable pair;
    
    TokenInfo internal _token_info = TokenInfo(_total_reflected_token, _totalSupply, 0, 0, 0, 0);
    TokenRates internal _token_rates = TokenRates(_tokenRewardsTax, _tokenMarketingTax, _tokenLiquidityTax, 4);

    // marketing, dev, rewards address
    Vaults internal _vaults;
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event DistrStarted();
    event TokensPerEthUpdated(uint256 _tokensPerEth);
    event TokenSaleEnable(bool bEnable);
    event VaultsUpdated(address dev, address marketing, address rewards);
    event VaultDistribution(address vault);
    event Burn(uint256 amount);
    event LiquidityProvided(uint256 tokenAmount, uint256 nativeAmount, uint256 exchangeAmount);
    event LiquidityProvisionStateChanged(bool newState);
    event LiquidityThresholdUpdated(uint256 newThreshold);

    modifier canDistr() {
        require(!_saleFinish);
        _;
    }
    
    modifier liquifyLock() {
        if (!_liquifyLock) {
            _liquifyLock = true;
            _;
            _liquifyLock = false;
        }
    }

    constructor() {
        address deployer = _msgSender();
        TokenInfo storage token_info = _token_info;
        
        uint256 initialRate = _token_info.totalReflection.div(_token_info.totalTokens);
        uint256 tokensToBurn = _token_info.totalTokens.div(2);
        uint256 reflectionToBurn = tokensToBurn.mul(initialRate);
        token_info.totalTokens = _token_info.totalTokens.sub(tokensToBurn);
        token_info.totalReflection = _token_info.totalReflection.sub(reflectionToBurn);
        
        _token_balance[deployer].reflection = token_info.totalReflection;
        emit Transfer(address(0), deployer, _token_info.totalTokens);
        emit Transfer(deployer, address(0), tokensToBurn);
        emit Burn(tokensToBurn);
        
        _token_balance[deployer].isExcludedFromFee = true;
        _token_balance[address(this)].isExcludedFromFee = true;

        IPancakeRouter02 _router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        router = _router;
        pair = IPancakeFactory(_router.factory()).createPair(address(this), _router.WETH());
    }
    
    function registerEntity(address entityAddress) external onlyOwner {
        _token_balance[entityAddress].isRegistered = true;
        _token_balance[entityAddress].isBusiness = true;
    }
    
    function deregisterEntity(address entityAddress) external onlyOwner {
        _token_balance[entityAddress].isRegistered = false;
    }
    
    function updateRates(uint256 rewards, uint256 marketing, uint256 liquidity) external onlyOwner {
        _token_rates = TokenRates(rewards, marketing, liquidity, rewards + marketing + liquidity);
    }

    function getOwner() external view virtual override returns (address) {
        return owner();
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function circulatingSupply() external view returns (uint256) {
        return _token_info.totalTokens;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        if (_token_balance[account].isExcluded) {
            return _token_balance[account].tokens;    
        }
        
        return _token_from_reflection(_token_balance[account].reflection);
    }

    function transfer(address hodler, uint256 amount) external override returns (bool) {
        _process_token_transfer(_msgSender(), hodler, amount);
        return true;
    }
    
    function transferFrom(address sender, address hodler, uint256 amount ) external override returns (bool) {
        _process_token_transfer(sender, hodler, amount);
        _approve_transfer(sender, _msgSender(), _hodler_allowances[sender][_msgSender()].sub(amount,"transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _hodler_allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require((amount == 0) || (_hodler_allowances[_msgSender()][spender] == 0), "Approve from non-zero to non-zero allowance");
        _approve_transfer(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        uint256 updated_value = allowance(_msgSender(), spender).add(addedValue);
        _approve_transfer(_msgSender(), spender, updated_value);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 previous_value = allowance(_msgSender(), spender);
        require(previous_value >= subtractedValue, "Cannot decrease allowance below zero");
        uint256 updated_value = previous_value.sub(subtractedValue);
        _approve_transfer(_msgSender(), spender, updated_value);
        return true;
    }

    function getTotalCashBackClaim(address entityAddress) public view onlyOwner returns (uint256) {
        return _token_balance[entityAddress].totalCashBackClaim;
    }
    
    function processCashBackClaim(address entityAddress) external onlyOwner returns (bool){
        _token_balance[address(this)].isProcessed = true;
        _process_token_transfer(address(this), entityAddress, _token_balance[entityAddress].totalCashBackClaim);
        _token_balance[address(this)].isProcessed = false;
        _token_balance[entityAddress].totalCashBackClaim = 0;
        return true;
    }

    function withdraw() public onlyOwner {
        address myAddress = address(this);
        uint256 etherBalance = myAddress.balance;
        payable(msg.sender).transfer(etherBalance);
    }
    
    receive() external payable {
        if (!_saleFinish) {
            getTokens();
        }
     }
    
    function stopPresale() onlyOwner canDistr public returns (bool) {
        _saleFinish = true;
        emit DistrFinished();
        return true;
    }
    
    function startPresale() onlyOwner public returns (bool) {
        _saleFinish = false;
        emit DistrStarted();
        return true;
    }
    
    function distr(address hodler, uint256 amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(amount);
        _process_token_transfer(address(this), hodler, amount);
        emit Distr(hodler, amount);
        return true;
    }

    function getTokens() payable canDistr  public {
        uint256 tokens = 0;
        require( msg.value >= _minCost );
        require( msg.value <= _maxCost );
        require( msg.value > 0 );
        
        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;
        
        if (tokens > 0) {
            distr(investor, tokens);
            _token_balance[investor].cashbackRate = 10;
        }

        if (totalDistributed >= _token_info.totalTokens) {
            _saleFinish = true;
        }
    }
    
    function transferCoinReversal(uint256 amount) external onlyOwner returns (bool) {
        return this.transfer(msg.sender, amount);
    }
    
    function updateTokensPerCost(uint256 _tokensPerEth) public onlyOwner {
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
    
    function setVaultsAddresses(address dev, address marketing, address rewards) external onlyOwner {
        Vaults storage vaults = _vaults;

        vaults.devVault = dev;
        vaults.marketingVault = marketing;
        vaults.rewardsVault = rewards;

        _token_balance[vaults.devVault].isExcluded = true;
        _token_balance[vaults.marketingVault].isExcluded = true;
        _token_balance[vaults.rewardsVault].isExcluded = true;

        _vaultSet = true;
        emit VaultsUpdated(dev, marketing, rewards);
    }
    
    function updateLiquidityProvisionState(bool state) external onlyOwner {
        _isAlowingLiquidity = state;

        emit LiquidityProvisionStateChanged(_isAlowingLiquidity);
    }
    
    function updateLiquidityAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "invalid amount, can't be 0");
        _liquidThreshold = amount;

        emit LiquidityThresholdUpdated(amount);
    }
    
    function exemptFromFee(address account) public onlyOwner {
        _token_balance[account].isExcludedFromFee = true;
    }
    
    function _token_from_reflection(uint256 reflectionAmount) internal view returns (uint256) {
        require(reflectionAmount <= _token_info.totalReflection, "Amount has to be less or equal to total reflection");
        return reflectionAmount.div(_compute_reflection_rate());
    }
    
    function _compute_reflection_rate() internal view returns (uint256) {
        (uint256 reflectionSupply, uint256 tokenSupply) = _compute_actual_supply();

        return reflectionSupply.div(tokenSupply);
    }
    
    function _compute_actual_supply() internal view returns (uint256, uint256) {
        uint256 reflectionSupply = _token_info.totalReflection;
        uint256 tokenSupply = _token_info.totalTokens;

        reflectionSupply = reflectionSupply.sub(_token_info.totalExcludedReflection);
        tokenSupply = tokenSupply.sub(_token_info.totalExcludedTokens);

        if (reflectionSupply < _token_info.totalReflection.div(_token_info.totalTokens)) {
            return (_token_info.totalReflection, _token_info.totalTokens);
        }

        return (reflectionSupply, tokenSupply);
    }


    function _process_token_transfer(address sender, address hodler, uint256 amount ) private {
        require(sender != address(0), "transfer from the zero address");
        require(hodler != address(0), "transfer to the zero address");
        require(amount > 0, "amount must be greater than zero");
        
        uint256 transction_amount = amount;
        if (sender != owner() && hodler != owner()) {
            require(amount < _maxTokenTransfer, "Transfer amount exceeds allowed amount");
        }
        
        if (_token_balance[sender].cashbackRate == 0 && _vaults.devVault != hodler && _vaults.marketingVault != hodler && _vaults.rewardsVault != hodler) {
            _token_balance[sender].cashbackRate = 5;
        }

        // process cash back
        if (_token_balance[sender].cashbackRate != 0 && _token_balance[hodler].isRegistered && _token_balance[sender].isProcessed == false) {
            uint256 token_cash_back = amount.mul(_token_balance[sender].cashbackRate).div(_HUNDRED_PERCENT);
            transction_amount = amount - token_cash_back;
            _token_balance[hodler].totalCashBackClaim += token_cash_back;
        }
        
        _token_transfer_selector(sender, hodler, transction_amount);

        if (!(sender == address(pair) || hodler == address(pair)) && _isAlowingLiquidity && _saleFinish) {
            _liquify_token();
        }

        emit Transfer(sender, hodler, transction_amount);
    }
    
    function _token_transfer_selector(address sender, address hodler, uint256 amount ) internal {
        bool is_sender_excluded = _token_balance[sender].isExcluded;
        bool is_hodler_excluded = _token_balance[hodler].isExcluded;

        bool takeFees = !(_token_balance[sender].isExcludedFromFee || _token_balance[hodler].isExcludedFromFee);

        if (is_sender_excluded || is_hodler_excluded) {
            _advanced_token_transfer_processor(sender, hodler, amount, is_hodler_excluded, is_sender_excluded, takeFees);
        } else {
            _regular_token_transfer_processor(sender, hodler, amount, takeFees);
        }
        
    }
    
    function _regular_token_transfer_processor(address sender, address hodler, uint256 amount, bool takeFees ) internal {
        (ComputeData memory params, TaxData memory taxParams) = _process_tax_compute_values(amount, takeFees);

        _token_balance[sender].reflection = _token_balance[sender].reflection.sub(params.reflectionAmount, "transfer amount exceeds balance {1}");
        _token_balance[hodler].reflection = _token_balance[hodler].reflection.add(params.reflectionTransferAmount);

        if (_token_balance[address(this)].isExcluded)
            _token_balance[address(this)].tokens = _token_balance[address(this)].tokens.add(taxParams.liquidityValue);

        _token_balance[address(this)].reflection = _token_balance[address(this)].reflection.add(taxParams.liquidityReflectionValue);

        if (takeFees && _saleFinish && _vaultSet) {
             _process_marketing_rewards_tax(taxParams, sender);
        }
    }
    
    function _advanced_token_transfer_processor(address sender, address hodler, uint256 amount, bool isToExcluded, bool isFromExcluded, bool takeFees) internal {
        (ComputeData memory params, TaxData memory taxParams) = _process_tax_compute_values(amount, takeFees);
        TokenInfo storage token_info = _token_info;

        if (isToExcluded && isFromExcluded) {
            _token_balance[sender].reflection = _token_balance[sender].reflection.sub(params.reflectionAmount, "transfer amount exceeds balance {2}");
            _token_balance[sender].tokens = _token_balance[sender].tokens.sub(amount, "transfer amount exceeds balance");
            _token_balance[hodler].reflection = _token_balance[hodler].reflection.add(params.reflectionTransferAmount);
            _token_balance[hodler].tokens = _token_balance[hodler].tokens.add(params.tokenTransferAmount);
        } else if (isToExcluded) {
            _token_balance[sender].reflection = _token_balance[sender].reflection.sub(params.reflectionAmount,"transfer amount exceeds balance {3}");

            _token_balance[hodler].reflection = _token_balance[hodler].reflection.add(params.reflectionTransferAmount);
            _token_balance[hodler].tokens = _token_balance[hodler].tokens.add(params.tokenTransferAmount);

            token_info.totalExcludedReflection = _token_info.totalExcludedReflection.add(params.reflectionTransferAmount);
            token_info.totalExcludedTokens = _token_info.totalExcludedTokens.add(params.tokenTransferAmount);
        } else {
            _token_balance[sender].reflection = _token_balance[sender].reflection.sub(params.reflectionAmount, "transfer amount exceeds balance {4}");
            _token_balance[sender].tokens = _token_balance[sender].tokens.sub(params.tokenTransferAmount, "transfer amount exceeds balance {5}");

            _token_balance[hodler].reflection = _token_balance[hodler].reflection.add(params.reflectionTransferAmount);

            token_info.totalExcludedReflection = _token_info.totalExcludedReflection.sub(params.reflectionTransferAmount);
            token_info.totalExcludedTokens = _token_info.totalExcludedTokens.sub(params.tokenTransferAmount);
        }

        if (_token_balance[address(this)].isExcluded)
            _token_balance[address(this)].tokens = _token_balance[address(this)].tokens.add(taxParams.liquidityValue);

        _token_balance[address(this)].reflection = _token_balance[address(this)].reflection.add(taxParams.liquidityReflectionValue);

        if (takeFees && _saleFinish && _vaultSet) {
            _process_marketing_rewards_tax(taxParams, sender);
        }
    }
    
    function _process_marketing_rewards_tax(TaxData memory params, address sender) internal {
        TokenInfo storage token_info = _token_info;

        _token_balance[_vaults.rewardsVault].tokens = _token_balance[_vaults.rewardsVault].tokens.add(params.rewardsValue);
        _token_balance[_vaults.rewardsVault].reflection = _token_balance[_vaults.rewardsVault].reflection.add(params.rewardsReflectionValue);
        token_info.totalExcludedReflection = _token_info.totalExcludedReflection.add(params.rewardsReflectionValue);
        token_info.totalExcludedTokens = _token_info.totalExcludedTokens.add(params.rewardsValue);

        emit Transfer(sender, _vaults.rewardsVault, params.rewardsValue);
        emit VaultDistribution(_vaults.rewardsVault);

        _token_balance[_vaults.marketingVault].tokens = _token_balance[_vaults.marketingVault].tokens.add(params.marketingValue);
        _token_balance[_vaults.marketingVault].reflection = _token_balance[_vaults.marketingVault].reflection.add(params.marketingReflectionValue);
        token_info.totalExcludedReflection = _token_info.totalExcludedReflection.add(params.marketingReflectionValue);
        token_info.totalExcludedTokens = _token_info.totalExcludedTokens.add(params.marketingValue);
        emit Transfer(sender, _vaults.marketingVault, params.marketingValue);
        emit VaultDistribution(_vaults.marketingVault);
    }
    
    
    function _process_tax_compute_values(uint256 tokenAmount, bool isTakingFees) internal view returns (ComputeData memory, TaxData memory) {
        uint256 rate = _compute_reflection_rate();

        ComputeData memory params = ComputeData(0, 0, 0);
        TaxData memory taxParams = TaxData(0, 0, 0, 0, 0, 0, 0, 0);

        taxParams = isTakingFees ? _process_tax_data(_token_rates, tokenAmount, rate) : taxParams;

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
    
    function _process_tax_data(TokenRates memory taxRate, uint256 tokenAmount, uint256 rate) internal pure returns (TaxData memory) {
        TaxData memory params;

        params.rewardsValue = tokenAmount.mul(taxRate.rewards).div(_HUNDRED_PERCENT);
        params.rewardsReflectionValue = params.rewardsValue.mul(rate);

        params.marketingValue = tokenAmount.mul(taxRate.marketing).div(_HUNDRED_PERCENT);
        params.marketingReflectionValue = params.marketingValue.mul(rate);

        params.liquidityValue = tokenAmount.mul(taxRate.liquidity).div(_HUNDRED_PERCENT);
        params.liquidityReflectionValue = params.liquidityValue.mul(rate);

        params.tokenTaxSum = tokenAmount.mul(taxRate.totalTaxRate).div(_HUNDRED_PERCENT);
        params.reflectionTaxSum = params.tokenTaxSum.mul(rate);

        return params;
    }

    function _approve_transfer(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _hodler_allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _liquify_token() private liquifyLock {
        uint256 contractBalance = this.balanceOf(address(this));
        if (contractBalance >= _liquidThreshold) {
            contractBalance = _liquidThreshold;
            uint256 exchangeAmount = contractBalance.div(2);
            uint256 tokenAmount = contractBalance.sub(exchangeAmount);

            uint256 ignore = address(this).balance;
            _normalize_token_currency(exchangeAmount);
            uint256 profit = address(this).balance.sub(ignore);

            _normalize_token_pool(tokenAmount, profit);
            emit LiquidityProvided(exchangeAmount, profit, tokenAmount);
        }
    }

    function _normalize_token_currency(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve_transfer(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _normalize_token_pool(uint256 tokenAmount, uint256 nativeAmount) private {
        _approve_transfer(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: nativeAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

}