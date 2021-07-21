/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/*

 ## MOON SHINE ## 
 ⁃ Total Supply: 200,000,000,000,000
 ⁃ 4% reflection to all holders
 - 8% to liquidity generation

 ⁃ 2.5% max wallet limit
 ⁃ 1.5% max tx limit
 ⁃ Double tax for any transaction higher than 0.8% of total supply

*/

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

library Address {
    /**
    * @dev Returns true if `account` is a contract.
    *
    * [IMPORTANT]
    * ====
    * It is unsafe to assume that an address for which this function returns
    * false is an externally-owned account (EOA) and not a contract.
    *
    * Among others, `isContract` will return false for the following
    * types of addresses:
    *
    *  - an externally-owned account
    *  - a contract in construction
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
    */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
    * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    * `recipient`, forwarding all available gas and reverting on errors.
    *
    * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
    * of certain opcodes, possibly making contracts go over the 2300 gas limit
    * imposed by `transfer`, making them unable to receive funds via
    * `transfer`. {sendValue} removes this limitation.
    *
    * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
    *
    * IMPORTANT: because control is transferred to `recipient`, care must be
    * taken to not create reentrancy vulnerabilities. Consider using
    * {ReentrancyGuard} or the
    * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
    * @dev Performs a Solidity function call using a low level `call`. A
    * plain`call` is an unsafe replacement for a function call: use this
    * function instead.
    *
    * If `target` reverts with a revert reason, it is bubbled up by this
    * function (like regular Solidity function calls).
    *
    * Returns the raw returned data. To convert to the expected return value,
    * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
    *
    * Requirements:
    *
    * - `target` must be a contract.
    * - calling `target` with `data` must not revert.
    *
    * _Available since v3.1._
    */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
    * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
    * `errorMessage` as a fallback revert reason when `target` reverts.
    *
    * _Available since v3.1._
    */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
    * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    * but also transferring `value` wei to `target`.
    *
    * Requirements:
    *
    * - the calling contract must have an ETH balance of at least `value`.
    * - the called Solidity function must be `payable`.
    *
    * _Available since v3.1._
    */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
    * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
    * with `errorMessage` as a fallback revert reason when `target` reverts.
    *
    * _Available since v3.1._
    */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

enum PairType {Common, LiquidityLocked, SweepableToken0, SweepableToken1}

interface IEmpirePair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function sweptAmount() external view returns (uint256);

    function sweepableToken() external view returns (address);

    function liquidityLocked() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        PairType,
        uint256
    ) external;

    function sweep(uint256 amount, bytes calldata data) external;

    function unsweep(uint256 amount) external;

    function getMaxSweepable() external view returns (uint256);
}

interface IEmpireFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function createPair(
        address tokenA,
        address tokenB,
        PairType pairType,
        uint256 unlockTime
    ) external returns (address pair);

    function createEmpirePair(
        address tokenA,
        address tokenB,
        PairType pairType,
        uint256 unlockTime
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IEmpireRouter {
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
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

contract MoonShine is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address[] private _confirmedSnipers;

    mapping (address => bool) private presaleAddresses;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isSniper;
    mapping (address => User) private cooldown;
   
    uint private startingSupply = 200_000_000_000_000; //200 Trillion, underscores aid readability
   
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Moonshine.so";
    string private _symbol = "SHINE";
    
    uint256 public _taxFee = 4;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingFee = 6; // 5%, divisor is 1000
    uint256 private _previousMarketingFee = _marketingFee;
    
    bool public tradingOpen = false; //once switched on, can never be switched off.
    bool public transferFees = true;
    IEmpireRouter public empireRouter;

    // EMPIRE ROUTER
    address private _empireRouter = 0x89C0DB631D2bB045cF020786798993a48c0F7b9d; //ETH MAINNET
    address public empirePair;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address payable private _shineWallet = payable(0xC32FfF8010DBeE8783b04A2c096539db0757d55c);
    address payable private _everapeWallet = payable(0xB8b792F0e567916f4d0A04988C875B77bC7B5C77);
    address payable private _marketingWallet = payable(0xbDa2A286529285C49aF713D3a29ba67E9b42b67e);
    address payable private _liquidityWallet = payable(0x000000000000000000000000000000000000dEaD);
    address payable private _prismWallet = payable(0x5ABBd94bb0561938130d83FdA22E672110e12528);
    
    uint256 public launchTime;
    uint256 private buyLimitEnd;
    uint private _maxBuyAmount;
    
    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    // Max TX amount is 1.5% of the total supply.
    uint256 private maxTxPercent = 15; // Less fields to edit
    uint256 private maxTxDivisor = 1000;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor; // Actual amount for UI's
    // Maximum wallet size is 2.5% of the total supply.
    uint256 private maxWalletPercent = 25; // Less fields to edit
    uint256 private maxWalletDivisor = 1000;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor; // Actual amount for UI's
    // Number to check for double sell tax
    // Set to 0.8%.
    uint256 private doubleTaxPercent = 8; // Less fields to edit
    uint256 private doubleTaxDivisor = 1000;
    uint256 private _doubleTaxAmt = (_tTotal * doubleTaxPercent) / doubleTaxDivisor;
    uint256 public doubleTaxAmtUI = (startingSupply * doubleTaxPercent) / doubleTaxDivisor; // Actual amount for UI's
    bool private doubleTaxBool = false;
    // 0.0005% of Total Supply
    uint256 public numTokensSellToAddToLiquidity = (_tTotal * 5) / 1000000;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private snipeBlockAmt = 2;
    uint256 public snipersCaught = 0;
    bool private _cooldownEnabled=true;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        _rOwned[_msgSender()] = _rTotal;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
    
    //to recieve ETH from empireRouter when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
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
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            100
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee.add(_liquidityFee.mul(10))).div(
            1000
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,        
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(!_liquidityHolders[from] && !_liquidityHolders[to])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if(!_liquidityHolders[from]
            && !_liquidityHolders[to]
            && to != _empireRouter 
            && to != empirePair
        ) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is empire pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance 
            && !inSwapAndLiquify
            && from != empirePair
            && swapAndLiquifyEnabled
            && !presaleAddresses[to]
            && !presaleAddresses[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 toMarketing = contractTokenBalance.mul(_marketingFee).div(_marketingFee.add(_liquidityFee.mul(10)));
        uint256 toLiquify = contractTokenBalance.sub(toMarketing);

        // split the contract balance into halves
        uint256 half = toLiquify.div(2);
        uint256 otherHalf = toLiquify.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        uint256 toSwapForEth = half.add(toMarketing);
        swapTokensForEth(toSwapForEth);

        // how much ETH did we just swap into?
        uint256 fromSwap = address(this).balance.sub(initialBalance);
        uint256 newBalance = fromSwap.mul(half).div(toSwapForEth);

        // add liquidity to empiredex
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
        
        if(fromSwap.sub(newBalance) > 0){
        
            uint256 toShineTeam = fromSwap.sub(newBalance).div(2);
            uint256 toMarketingTeam = toShineTeam.div(2);
            uint256 toEverapeTeam = toMarketingTeam.div(2);
            uint256 toPrismTeam = toEverapeTeam.div(2);
            
            transferToAddressETH(_shineWallet, toShineTeam);
            transferToAddressETH(_marketingWallet, toMarketingTeam);
            transferToAddressETH(_everapeWallet, toEverapeTeam);
            transferToAddressETH(_prismWallet, toPrismTeam);
        }

    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the empire pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = empireRouter.WETH();

        _approve(address(this), address(empireRouter), tokenAmount);

        // make the swap
        empireRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(empireRouter), tokenAmount);

        // add the liquidity
        empireRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet,
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (_liquidityHolders[from] && to == empirePair) {
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function checkDoubleTaxAmt(address recipient, uint256 amount) internal {
        if (recipient == empirePair) {
            if (amount > _doubleTaxAmt) {
                doubleTaxBool = true;

                _previousTaxFee = _taxFee;
                _previousLiquidityFee = _liquidityFee;
                _previousMarketingFee = _marketingFee;

                _taxFee = _taxFee.mul(2);
                _liquidityFee = _liquidityFee.mul(2);
                _marketingFee = _marketingFee.mul(2);
            }
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        // Failsafe, no snipers allowed.
        if (sniperProtection){
            // Check if this is the liquidity adding tx to startup.
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(sender, recipient);
            } else {
                if (_liqAddBlock > 0 
                    && sender == empirePair 
                    && !_liquidityHolders[sender]
                    && !_liquidityHolders[recipient]
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[recipient] = true;
                        snipersCaught ++;
                        emit SniperCaught(recipient); //pow
                    }
                    else if (_isSniper[sender]) {
                        _confirmedSnipers.push(address(sender));
                        snipersCaught ++;
                        emit SniperCaught(sender); //pow
                    }
                }
            }
        }
 
        if(sender != owner() && recipient != owner()) {
            
            if (!tradingOpen) {
                if (!(sender == address(this) || recipient == address(this)
                || sender == address(owner()) || recipient == address(owner())
                || isExcludedFromFee(sender) || isExcludedFromFee(recipient))) {
                    require(tradingOpen, "Trading is not enabled");
                }
            }

            if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }
        }
        
        //Launch protection
        if(sender == empirePair && recipient != address(empireRouter) && !_isExcludedFromFee[recipient]) {
            require(tradingOpen, "Trading not yet enabled.");
            
            if(_cooldownEnabled) {
                if(buyLimitEnd > block.timestamp) {
                    require(amount <= _maxBuyAmount);
                    require(cooldown[recipient].buy < block.timestamp, "Your buy cooldown has not expired.");
                    cooldown[recipient].buy = block.timestamp + (45 seconds);
                }
            }
        }
        
        // If sender is a sniper address, reject the sell.
        if (recipient == empirePair && isSniper(sender)) {
            revert("Sniper rejected pow.");
        }
        
        if(!takeFee)
            removeAllFee();
        else
            checkDoubleTaxAmt(recipient, amount); //when selling whale amount double tax fees
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee || doubleTaxBool)
            restoreAllFee();
            doubleTaxBool = false;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    //ADMIN COMMANDS
    
    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setSniperProtectionEnabled(bool enabled) external onlyOwner() {
        sniperProtection = enabled;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee <= 10); // Prevents owner from abusing fees.
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee <= 10); // Prevents owner from abusing fees.
        _liquidityFee = liquidityFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        require(marketingFee <= 10); // Prevents owner from abusing fees.
        _marketingFee = marketingFee;
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) external onlyOwner() {
        require(_numTokensSellToAddToLiquidity <= (_tTotal * 5) / 10000); // 0.05% of total supply max, prevents owner from abusing fees.
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    // Adjusted to allow for smaller than 1%'s, as low as 0.1%
    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 10000); // Cannot set lower than 0.01%
        _maxTxAmount = _tTotal.mul(percent).div(
            divisor // Division by divisor, makes it mutable.
        );
        maxTxAmountUI = startingSupply.mul(percent).div(divisor);
    }

    // Adjusted to allow for smaller than 1%'s, as low as 0.1%
    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 1000); // Cannot set lower than 0.1%
        _maxWalletSize = _tTotal.mul(percent).div(
            divisor // Division by divisor, makes it mutable.
        );
        maxWalletSizeUI = startingSupply.mul(percent).div(divisor);
    }

    function setDoubleTaxAmountCheck(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 1000); // Cannot set lower than 0.1%
        _doubleTaxAmt = _tTotal.mul(percent).div(
            divisor // Division by divisor, makes it mutable.
        );
        doubleTaxAmtUI = startingSupply.mul(percent).div(divisor);
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(_marketingWallet != newWallet, "Wallet already set!");
        _marketingWallet = newWallet;
    }
    
    function setLiquidityWallet(address payable newWallet) external onlyOwner {
        require(_liquidityWallet != newWallet, "Wallet already set!");
        _liquidityWallet = newWallet;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function excludePresaleAddresses(address presale) external onlyOwner {
        _liquidityHolders[presale] = true;
        presaleAddresses[presale] = true;
        excludeFromReward(presale);
        excludeFromFee(presale);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function includeInLiquidity(address account) external onlyOwner {
        _liquidityHolders[account] = false;
    }
    
    //Incase of a v2 router
    function migrateRouter(address router) external onlyOwner {
        _empireRouter = router;
    }
    
    function initContract() external onlyOwner() {
        IEmpireRouter _empireRouter = IEmpireRouter(_empireRouter);
        PairType pairType = address(this) < WETH
                ? PairType.SweepableToken1
                : PairType.SweepableToken0;
         // Create a empire pair for this new token
         // WETH sweepable enabled
         // LiquidityLocked for forever
        empirePair = IEmpireFactory(_empireRouter.factory())
            .createPair(_empireRouter.WETH(), address(this), pairType, 0);

        // set the rest of the contract variables
        empireRouter = _empireRouter;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _liquidityHolders[owner()] = true;
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
        _isExcluded[owner()] = true;
        _excluded.push(owner());
        _isExcluded[burnAddress] = true;
        _excluded.push(burnAddress);
        _isExcluded[empirePair] = true;
        _excluded.push(empirePair);
        
        _liquidityFee = 0;
        _marketingFee = 0;
        _taxFee = 0;
        
        _isSniper[address(0x7589319ED0fD750017159fb4E4d96C63966173C1)] = true;
        _isSniper[address(0x65A67DF75CCbF57828185c7C050e34De64d859d0)] = true;
        _isSniper[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        _isSniper[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        _isSniper[address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345)] = true;
        _isSniper[address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b)] = true;
        _isSniper[address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95)] = true;
        _isSniper[address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964)] = true;
        _isSniper[address(0xDC81a3450817A58D00f45C86d0368290088db848)] = true;
        _isSniper[address(0x45fD07C63e5c316540F14b2002B085aEE78E3881)] = true;
        _isSniper[address(0x27F9Adb26D532a41D97e00206114e429ad58c679)] = true;
        _isSniper[address(0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7)] = true;
        _isSniper[address(0xfad95B6089c53A0D1d861eabFaadd8901b0F8533)] = true;
        _isSniper[address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d)] = true;
        _isSniper[address(0x000000000000084e91743124a982076C59f10084)] = true;
        _isSniper[address(0x6dA4bEa09C3aA0761b09b19837D9105a52254303)] = true;
        _isSniper[address(0x323b7F37d382A68B0195b873aF17CeA5B67cd595)] = true;
        _isSniper[address(0x000000005804B22091aa9830E50459A15E7C9241)] = true;
        _isSniper[address(0xA3b0e79935815730d942A444A84d4Bd14A339553)] = true;
        _isSniper[address(0xf6da21E95D74767009acCB145b96897aC3630BaD)] = true;
        _isSniper[address(0x0000000000007673393729D5618DC555FD13f9aA)] = true;
        _isSniper[address(0x00000000000003441d59DdE9A90BFfb1CD3fABf1)] = true;
        _isSniper[address(0x59903993Ae67Bf48F10832E9BE28935FEE04d6F6)] = true;
        _isSniper[address(0x000000917de6037d52b1F0a306eeCD208405f7cd)] = true;
        _isSniper[address(0x7100e690554B1c2FD01E8648db88bE235C1E6514)] = true;
        _isSniper[address(0x72b30cDc1583224381132D379A052A6B10725415)] = true;
        _isSniper[address(0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE)] = true;
        _isSniper[address(0xfe9d99ef02E905127239E85A611c29ad32c31c2F)] = true;
        _isSniper[address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b)] = true;
        _isSniper[address(0xc496D84215d5018f6F53E7F6f12E45c9b5e8e8A9)] = true;
        _isSniper[address(0x59341Bc6b4f3Ace878574b05914f43309dd678c7)] = true;
        _isSniper[address(0xe986d48EfeE9ec1B8F66CD0b0aE8e3D18F091bDF)] = true;
        _isSniper[address(0x4aEB32e16DcaC00B092596ADc6CD4955EfdEE290)] = true;
        _isSniper[address(0x136F4B5b6A306091b280E3F251fa0E21b1280Cd5)] = true;
        _isSniper[address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b)] = true;
        _isSniper[address(0x5B83A351500B631cc2a20a665ee17f0dC66e3dB7)] = true;
        _isSniper[address(0xbCb05a3F85d34f0194C70d5914d5C4E28f11Cc02)] = true;
        _isSniper[address(0x22246F9BCa9921Bfa9A3f8df5baBc5Bc8ee73850)] = true;
        _isSniper[address(0x42d4C197036BD9984cA652303e07dD29fA6bdB37)] = true;
        _isSniper[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
        _isSniper[address(0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A)] = true;
        _isSniper[address(0xC6bF34596f74eb22e066a878848DfB9fC1CF4C65)] = true;
        _isSniper[address(0x20f6fCd6B8813c4f98c0fFbD88C87c0255040Aa3)] = true;
        _isSniper[address(0xD334C5392eD4863C81576422B968C6FB90EE9f79)] = true;
        _isSniper[address(0xFFFFF6E70842330948Ca47254F2bE673B1cb0dB7)] = true;
        _isSniper[address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a)] = true;
        
    }
    
    function enableTrading() external onlyOwner() {
        _maxBuyAmount = 20000000000 * 10**9; //0.1ETH
        _liquidityFee = 6;
        _marketingFee = 6;
        _taxFee = 0;
        swapAndLiquifyEnabled = true;
        tradingOpen = true;
        launchTime = block.timestamp;
        buyLimitEnd = block.timestamp + (240 seconds);
    }
    
    function completeSetup() external onlyOwner() {
        _maxBuyAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
        _liquidityFee = 2;
        _marketingFee = 5;
        _taxFee = 4;
    }
    
    //SWEEPABLE CONFIG
    modifier onlyPair() {
        require(
            msg.sender == empirePair,
            "Empire::onlyPair: Insufficient Privileges"
        );
        _;
    }
    
    function sweep(uint256 amount, bytes calldata data) external onlyOwner() {
        // uint256 getSweepable = IEmpirePair(empirePair).getMaxSweepable();
        // require(amount >= getSweepable, "Amount higher than available to sweep");

        IEmpirePair(empirePair).sweep(amount, data);
    }

    function empireSweepCall(uint256 amount, bytes calldata) external onlyPair() {
        IERC20(WETH).transfer(owner(), amount);
    }

    function unsweep(uint256 amount) external onlyOwner() {
        IERC20(WETH).approve(empirePair, amount);
        IEmpirePair(empirePair).unsweep(amount);
    }

}