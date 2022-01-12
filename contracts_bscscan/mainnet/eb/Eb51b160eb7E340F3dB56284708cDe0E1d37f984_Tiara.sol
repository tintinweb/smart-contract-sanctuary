/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        
    }
}


// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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


// pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract Tiara is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    //REPLACE ADDRESSES
    // Multisig Protocol Wallets
    address payable public marketingAddress = payable(0x693B8B09eEab2818956F1a09cFedE20707D7f60E); 
    address payable public developmentAddress = payable(0x693B8B09eEab2818956F1a09cFedE20707D7f60E); 
    address payable public charityAddress = payable(0x693B8B09eEab2818956F1a09cFedE20707D7f60E); 
    address payable public vaultRewardAddress = payable(0x693B8B09eEab2818956F1a09cFedE20707D7f60E); 
    address payable public liquidityWallet = payable(0x693B8B09eEab2818956F1a09cFedE20707D7f60E); 
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000 * 10**2;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Tiara";
    string private constant _symbol = "TTI";
    uint8 private constant _decimals = 2;

    struct AddressFee {
        bool enable;
        uint256 _taxFee;
        uint256 _liquidityFee;
        uint256 _vaultFee;
        uint256 _buyTaxFee;
        uint256 _buyVaultFee;
        uint256 _buyLiquidityFee;
        uint256 _sellTaxFee;
        uint256 _sellVaultFee;
        uint256 _sellLiquidityFee;
    }

    uint256 public _taxFee = 0;
    uint256 public _vaultFee = 0;
    uint256 public _liquidityFee = 0; // liquidity + all team fees

    // Used in variable fee calculations
    uint256 private _tempTaxFee = 0;
    uint256 private _tempVaultFee = 0;
    uint256 private _tempLiquidityFee = 0;
    
    uint256 public _buyTaxFee = 0;
    uint256 public _buyVaultFee = 0;
    uint256 public _buyLiquidityFee = 0;
    
    uint256 public _sellTaxFee = 0;
    uint256 public _sellVaultFee = 0;
    uint256 public _sellLiquidityFee = 0;

    uint256 public _startTimeForSwap;
    uint256 public _intervalMinutesForSwap = 1 * 1 minutes;
    
    uint256 public _buyBackRangeRate = 80;

    // Fee per address
    mapping (address => AddressFee) public _addressFees;
    
    // Protocol Fees
    uint256 public marketingDivisor = 2;
    uint256 public developmentDivisor = 2;
    uint256 public charityDivisor = 1;
    uint256 public _bMaxTxAmount = 1000000  * 10**2;
    uint256 public _sMaxTxAmount = 1000000  * 10**2;
    uint256 private _trigger = 1000000  * 10**2;
    uint256 private minimumTokensBeforeSwap = 5000  * 10**2; 
    uint256 public buyBackSellLimit = 1 * 10**8;

    bool private _abmode = false;
    bool private _cooldownMode = false;
    uint256 public _buyBackDivisor = 10;
    uint256 public _buyBackTimeInterval = 5 minutes;
    bool public tradingOpen = true;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = true;
    bool public _isEnabledBuyBackAndBurn = true;
    
    event RewardLiquidityProviders(uint256 tokenAmount);
    event BuyBackEnabledUpdated(bool enabled);
    event AutoBuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event ABMode(bool enabled);
    event CooldownMode(bool enabled);
    event SwapAndLiquifyBNB(
        uint256 BNBSwapped,
        uint256 TokensReceived,
        uint256 tokensIntoLiqudity
    );


    event SwapAndLiquifyTokens(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        _rOwned[_msgSender()] = _rTotal;
        
        // MAINNET PCS Router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // TESTNET PCS Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        // Protocol Multisig Wallets
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[liquidityWallet] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[developmentAddress] = true;
        _isExcludedFromFee[vaultRewardAddress] = true;
        _isExcludedFromFee[charityAddress] = true;

        excludeFromReward(uniswapV2Pair);
        excludeFromReward(deadAddress);

        _startTimeForSwap = block.timestamp;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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
    
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }
    
    function buyBackSellLimitAmount() public view returns (uint256) {
        return buyBackSellLimit;
    }

    //Use when new router is released but pair hasnt been created yet.
    //Make sure to add initial liquidity manually after pair is made! Otherwise swapAndLiquify will fail.
    function setRouterAddressAndCreatePair(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
    
    //Use when new router is released and pair HAS been created already.
    function setRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Router = _newPancakeRouter;
    }
    
    //Use when new router is released and pair HAS been created already.
    function setPairAddress(address newPair) public onlyOwner() {
        uniswapV2Pair = newPair;
    }

    //Used for changing DEXs completely, used in case PCS goes down or new DEX become more popular/liquidity splitting between multiple exchanges.
    function setLiquidityAddress(address payable newLiquidityWallet) public onlyOwner() {
        liquidityWallet = newLiquidityWallet;
        _isExcludedFromFee[liquidityWallet] = true;
    }
    
    // Using vault to distribute rewards instead
    function airdrop(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
  

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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
        if(tradingOpen == true){
            require(amount > 0, "Transfer amount must be greater than zero");
        }
        if(from != owner() && to != owner() && ! _isExcludedFromFee[to] && ! _isExcludedFromFee[from]) {
            if(_abmode == true){
                require(bots[from] != true, "No bot transactions during antibotmode.");
            }
            if(tradingOpen == false){
                require( _isExcludedFromFee[to] || _isExcludedFromFee[from], "trading paused temporarily.");
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(amount <= _bMaxTxAmount, "Transfer amount exceeds max buy amount.");
                if(_cooldownMode == true){
                    if(cooldown[to] > block.timestamp){
                        if(cooldown[to] > block.timestamp + 28 minutes){
                            cooldown[to] = cooldown[to] + 24 hours;
                            if (cooldown[to] > block.timestamp + 22 hours){
                                require(amount <= _bMaxTxAmount/4, "Antibot/whale mode for first few hours: Transfer amount exceeds max tx amount.");
                            }
                        }
                        else {
                            cooldown[to] = cooldown[to] + 10 minutes;
                        }
                    }
                    else {
                        cooldown[to] = block.timestamp + 10 minutes;
                    }
                    if (amount > _trigger){
                        if(cooldown[to] > block.timestamp){
                            cooldown[to] = cooldown[to] + 48 hours;
                        }
                        else {
                            cooldown[to] = block.timestamp + 48 hours;
                        }
                    }  
                }
            }
            if (to == uniswapV2Pair && ! _isExcludedFromFee[from]){
                if(_cooldownMode == true){
                    if(cooldown[from] > 10 minutes){
                        require(cooldown[from] < block.timestamp, "Antibotmode active for first few hours: sell cooldown for your address is not elapsed. Sell cooldown is caused by repeat purchases, if you did not repeat purchase just wait 10 minutes.");
                    }
                }
                require(amount <= _sMaxTxAmount, "Transfer amount exceeds the max sell amount.");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;    

        // Sell tokens for ETH
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0) {
            if (to == uniswapV2Pair) {
                if (overMinimumTokenBalance && _startTimeForSwap + _intervalMinutesForSwap <= block.timestamp) {
                    _startTimeForSwap = block.timestamp;
                    contractTokenBalance = minimumTokensBeforeSwap;
                    swapTokens(contractTokenBalance);    
                }  

                uint256 balance = address(this).balance;
                if (buyBackEnabled && balance > 0) {

                    if (_buyBackDivisor > 0) {
                        buyBackSellLimit = balance.div(_buyBackDivisor);
                    }

                    // Min = 80% of max
                    uint256 _bBSLimitMin = buyBackSellLimit.mul(_buyBackRangeRate).div(100);

                    // IMPORTANT - make sure you understand this line or your contract wont work!
                    uint256 _bBSLimit = _bBSLimitMin + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (buyBackSellLimit - _bBSLimitMin + 1);

                    // Executes buyback
                    if (balance > _bBSLimit) {
                        buyBackTokens(_bBSLimit);
                    } 
                }
            }
            
        }
        
        // If any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            _tempTaxFee = 0;
            _tempVaultFee = 0;
            _tempLiquidityFee = 0;
        }
        else{
            // defaults tx fees:
            _tempTaxFee = _taxFee;
            _tempVaultFee = _vaultFee;
            _tempLiquidityFee = _liquidityFee;

            // Buy
            if(from == uniswapV2Pair){
                _tempTaxFee = _buyTaxFee;
                _tempVaultFee = _buyVaultFee;
                _tempLiquidityFee = _buyLiquidityFee;
            }
            // Sell
            if(to == uniswapV2Pair){
                _tempTaxFee = _sellTaxFee;
                _tempVaultFee = _sellVaultFee;
                _tempLiquidityFee = _sellLiquidityFee;
            }
            
            // If send account has a special fee 
            if(_addressFees[from].enable){
                _tempTaxFee = _addressFees[from]._taxFee;
                _tempVaultFee = _addressFees[from]._vaultFee;
                _tempLiquidityFee = _addressFees[from]._liquidityFee;

                // Sell
                if(to == uniswapV2Pair){
                    _tempTaxFee = _addressFees[from]._sellTaxFee;
                    _tempVaultFee = _addressFees[from]._sellVaultFee;
                    _tempLiquidityFee = _addressFees[from]._sellLiquidityFee;
                }
            }
            else{
                // If buy account has a special fee
                if(_addressFees[to].enable){
                    //buy
                    _tempTaxFee = _addressFees[to]._taxFee;
                    _tempVaultFee = _addressFees[to]._vaultFee;
                    _tempLiquidityFee = _addressFees[to]._liquidityFee;

                    if(from == uniswapV2Pair){
                        _tempTaxFee = _addressFees[to]._buyTaxFee;
                        _tempVaultFee = _addressFees[to]._buyVaultFee;
                        _tempLiquidityFee = _addressFees[to]._buyLiquidityFee;
                    }
                }
            }
        }
        
        _tokenTransfer(from,to,amount);
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
       
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 convertedBalance = address(this).balance.sub(initialBalance);

        // Send to Charity address
        transferToAddressETH(charityAddress, convertedBalance.div(_liquidityFee).mul(charityDivisor));
        // Send to Development address 
        transferToAddressETH(developmentAddress, convertedBalance.div(_liquidityFee).mul(developmentDivisor));
        // Send to Marketing address 
        transferToAddressETH(marketingAddress, convertedBalance.div(_liquidityFee).mul(marketingDivisor));
        
    }
    

    function buyBackTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {
    	    swapETHForTokensAndBurn(amount);
	    }
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function swapETHForTokensAndBurn(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // Make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

    function swapETHForTokensToHere(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // Make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of Tokens
            path,
            address(this), // Contract address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(), //Contract Owner
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tVault) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeVault(tVault);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tVault) = _getValues(tAmount);
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeVault(tVault);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tVault) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeVault(tVault);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tVault) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeVault(tVault);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tVault) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tVault, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tVault);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tVault = calculateVaultFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tVault);
        return (tTransferAmount, tFee, tLiquidity, tVault);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tVault, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rVault = tVault.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rVault);
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
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[liquidityWallet] = _rOwned[liquidityWallet].add(rLiquidity);
        if(_isExcluded[liquidityWallet])
            _tOwned[liquidityWallet] = _tOwned[liquidityWallet].add(tLiquidity);
    }

    function _takeVault(uint256 tVault) private {
        uint256 rVault = tVault.mul(_getRate());
        _rOwned[vaultRewardAddress] = _rOwned[vaultRewardAddress].add(rVault);
        if(_isExcluded[vaultRewardAddress])
            _tOwned[vaultRewardAddress] = _tOwned[vaultRewardAddress].add(tVault);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tempTaxFee).div(
            10**2
        );
    }

    function calculateVaultFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tempVaultFee).div(
            10**2
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tempLiquidityFee).div(
            10**2
        );
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
            cooldown[bots_[i]] = block.timestamp + 7 days;
        }
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function checkIfOnBotList(address _address) view public onlyOwner returns(bool){
        return bots[_address];
    }

    function _getSellBnBAmount(uint256 tokenAmount) private view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint[] memory amounts = uniswapV2Router.getAmountsOut(tokenAmount, path);

        return amounts[1];
    }

    function SetBuyBackDivisor(uint256 newDivisor) external onlyOwner {
        _buyBackDivisor = newDivisor;
    }

    function SetBuyBackRangeRate(uint256 newPercent) external onlyOwner {
        require(newPercent <= 100, "The value must not be larger than 100.");
        _buyBackRangeRate = newPercent;
    }

    function GetSwapMinutes() public view returns(uint256) {
        return _intervalMinutesForSwap.div(60);
    }

    function SetSwapMinutes(uint256 newMinutes) external onlyOwner {
        _intervalMinutesForSwap = newMinutes * 1 minutes;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setVaultFeePercent(uint256 vaultFee) external onlyOwner() {
        _vaultFee = vaultFee;
    }
        
    function setBuyFee(uint256 buyTaxFee, uint256 buyVaultFee, uint256 buyLiquidityFee) external onlyOwner {
        _buyTaxFee = buyTaxFee;
        _buyVaultFee = buyVaultFee;
        _buyLiquidityFee = buyLiquidityFee;
    }
   
    function setSellFee(uint256 sellTaxFee, uint256 sellVaultFee, uint256 sellLiquidityFee) external onlyOwner {
        _sellTaxFee = sellTaxFee;
        _sellVaultFee = sellVaultFee;
        _sellLiquidityFee = sellLiquidityFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setBuyBackSellLimit(uint256 buyBackSellSetLimit) external onlyOwner {
        buyBackSellLimit = buyBackSellSetLimit;
    }

    function setBuyMaxTxAmount(uint256 bMaxTxAmount) external onlyOwner {
        _bMaxTxAmount = bMaxTxAmount;
    }

    function setSellMaxTxAmount(uint256 sMaxTxAmount) external onlyOwner {
        _sMaxTxAmount = sMaxTxAmount;
    }

    function setTriggerAmount(uint256 trigger) external onlyOwner {
        _trigger = trigger;
    }
    
    function setMarketingDivisor(uint256 divisor) external onlyOwner {
        marketingDivisor = divisor;
    }

    function setDevelopmentDivisor(uint256 divisor) external onlyOwner {
        developmentDivisor = divisor;
    }

    function setCharityDivisor(uint256 divisor) external onlyOwner {
        charityDivisor = divisor;
    }

    function setNumTokensSellToAddToBuyBack(uint256 _minimumTokensBeforeSwap) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
    }

    function setDevelopmentAddress(address _developmentAddress) external onlyOwner {
        developmentAddress = payable(_developmentAddress);
        _isExcludedFromFee[developmentAddress] = true;
    }

    function setCharityAddress(address _charityAddress) external onlyOwner {
        charityAddress = payable(_charityAddress);
        _isExcludedFromFee[charityAddress] = true;
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultRewardAddress = payable(_vaultAddress);
        _isExcludedFromFee[vaultRewardAddress] = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setABMode(bool _enabled) public onlyOwner {
        _abmode = _enabled;
        emit ABMode(_enabled);
    }

    function setCooldownMode(bool _enabled) public onlyOwner {
        _cooldownMode = _enabled;
        emit CooldownMode(_enabled);
    }
    
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function prepareForPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(false);
        setABMode(false);
        setCooldownMode(false);
        setTradingOpen(false);
        _taxFee = 0;
        _vaultFee = 0;
        _liquidityFee = 0;
        _bMaxTxAmount = 1000000 * 10**2; // 1000000
        _sMaxTxAmount = 1000000 * 10**2;
    }
    
    function afterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
        setABMode(true);
        setCooldownMode(true);
        _taxFee = 0;
        _vaultFee = 0;
        _liquidityFee = 0;
        _bMaxTxAmount = 1000000 * 10**2;
        _sMaxTxAmount = 1000000 * 10**2;
        setTradingOpen(true);
    }

    function setTradingOpen(bool _status) public onlyOwner {
        tradingOpen = _status;
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function changeRouterVersion(address _router) public onlyOwner returns(address _pair) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        
        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }
        uniswapV2Pair = _pair;

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }
    


     // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    // for stuck tokens of other types
    function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    //Create additional liquidity using BNB tokens in contract
    function manualSwapAndLiquifyBNB(uint256 bnbLiquifyAmount) public lockTheSwap onlyOwner {
        // split the contract balance into halves
        uint256 half = bnbLiquifyAmount.div(2); // WBNB
        uint256 otherHalf = bnbLiquifyAmount.sub(half); // WBNB not swapped

        // capture the contract's current Token balance.
        // this is so that we can capture exactly the amount of Tokens that the
        // swap creates, and not make the liquidity event include any Tokens that
        // has been manually sent to the contract
        uint256 initialTokenBalance = balanceOf(address(this));

        // swap ETH for Tokens
        swapETHForTokensToHere(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much Tokens did we just swap into?
        uint256 newTokenBalance = balanceOf(address(this)).sub(initialTokenBalance);

        // add liquidity to uniswap
        addLiquidity(newTokenBalance, otherHalf);
        
        emit SwapAndLiquifyBNB(half, newTokenBalance, otherHalf);
    }



    //Create additional liquidity using Airbridge tokens in contract
    function manualSwapAndLiquifyTokens(uint256 tokenLiquifyAmount) public lockTheSwap onlyOwner{
        // split the contract balance into halves
        uint256 half = tokenLiquifyAmount.div(2); //staking tokens to be swaped
        uint256 otherHalf = tokenLiquifyAmount.sub(half); //staking tokens not swapped

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquifyTokens(half, newBalance, otherHalf);
    }
    
    // Recommended to add by certik: For stuck tokens (as a result of slight miscalculations/rounding errors) 
    function SweepStuck(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }



    function setAddressFee(address _address, bool _enable, uint256 _addressTaxFee, uint256 _addressVaultFee, uint256 _addressLiquidityFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._taxFee = _addressTaxFee;
        _addressFees[_address]._vaultFee = _addressVaultFee;
        _addressFees[_address]._liquidityFee = _addressLiquidityFee;
    }
    
    function setBuyAddressFee(address _address, bool _enable, uint256 _addressTaxFee, uint256 _addressVaultFee, uint256 _addressLiquidityFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._buyTaxFee = _addressTaxFee;
        _addressFees[_address]._buyVaultFee = _addressVaultFee;
        _addressFees[_address]._buyLiquidityFee = _addressLiquidityFee;
    }
    


    function setSellAddressFee(address _address, bool _enable, uint256 _addressTaxFee, uint256 _addressVaultFee, uint256 _addressLiquidityFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._sellTaxFee = _addressTaxFee;
        _addressFees[_address]._sellTaxFee = _addressVaultFee;
        _addressFees[_address]._sellLiquidityFee = _addressLiquidityFee;
    }
    
}