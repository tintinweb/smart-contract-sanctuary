/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
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

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x584B7d84b2cea5E0bc2A52A1df5B5b70b3EF86a5;
        emit OwnershipTransferred(address(0), _owner);
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
    event Paused(address account);
    event Unpaused(address account);    
}    

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
    event Mint(address indexed sender, uint amount0, uint amount1);
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

contract ThePeoplesToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address private _developmentWalletAddress = 0x03Ac06188932A0BEeB6626B9DdE33A8627eFDA2b;
    address public _burnWalletAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "ThePeoplesToken";
    string private _symbol = "TPT";
    uint8 private _decimals = 18;
    uint256 public _buyTaxFee = 120;
    uint256 private _previousBuyTaxFee = _buyTaxFee;
    uint256 public _sellTaxFee = 120;
    uint256 private _previousSellTaxFee = _sellTaxFee;
    uint256 public _buyDevelopmentFee = 20;
    uint256 private _previousBuyDevelopmentFee = _buyDevelopmentFee;
    uint256 public _sellDevelopmentFee = 50;
    uint256 private _previousSellDevelopmentFee = _sellDevelopmentFee;
    uint256 public _buyLiquidityFee = 40;
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
    uint256 public _sellLiquidityFee = 40;
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;

        struct BuyFee{
        uint256 _buyTaxFee;
        uint256 _developmentFee;
        uint256 _liquidityFee;
    }
        
        struct SellFee{
        uint256 _sellTaxFee;
        uint256 _developmentFee;
        uint256 _liquidityFee;

    }
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
    require(!paused);
    _;
    }
    modifier whenPaused() {
    require(paused);
    _;
    }
    function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
    }
    function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
    }

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = 10000000000 * 10**18;
    uint256 private numTokensSellToAddToLiquidity = 1000000000 * 10**18;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor () {
        _rOwned[owner()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), owner(), _tTotal);
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
        (uint256 rAmount,,,,,,) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    function reflectionFromTokenBuy(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValuesBuy(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValuesBuy(tAmount);
            return rTransferAmount;
        }
    }
    function reflectionFromTokenSell(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValuesSell(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValuesSell(tAmount);
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
        require(_isExcluded[account], "Account is already included");
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
    function _transferBothExcludedBuy(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rBuyTaxFee, uint256 tTransferAmount, uint256 tBuyTaxFee, uint256 tBuyLiquidity, uint256 tBuyDevelopment) = _getValuesBuy(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeBuyLiquidity(tBuyLiquidity);
        _takeBuyDevelopment(tBuyDevelopment);
        _reflectFee(rBuyTaxFee, tBuyTaxFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcludedSell(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rSellTaxFee, uint256 tTransferAmount, uint256 tSellTaxFee, uint256 tSellLiquidity, uint256 tSellDevelopment) = _getValuesSell(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeSellLiquidity(tSellLiquidity);
        _takeSellDevelopment(tSellDevelopment);
        _reflectFee(rSellTaxFee, tSellTaxFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }
    function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function setBuyTaxFeePercent(uint256 buyTaxFee) external onlyOwner() {
        _buyTaxFee = buyTaxFee;        
    }
    function setSellTaxFeePercent(uint256 sellTaxFee) external onlyOwner() {
        _sellTaxFee = sellTaxFee;
    }
    function setBuyDevelopmentFeePercent(uint256 buyDevelopmentFee) external onlyOwner() {
        _buyDevelopmentFee = buyDevelopmentFee;
    }
    function setSellDevelopmentFeePercent(uint256 sellDevelopmentFee) external onlyOwner() {
        _sellDevelopmentFee = sellDevelopmentFee;
    }
    function setBuyLiquidityFeePercent(uint256 buyLiquidityFee) external onlyOwner() {
        _buyLiquidityFee = buyLiquidityFee;
    }
    function setSellLiquidityFeePercent(uint256 sellLiquidityFee) external onlyOwner() {
        _sellLiquidityFee = sellLiquidityFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**3
        );
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    receive() external payable {}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValuesBuy(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tBuyTaxFee, uint256 tBuyLiquidity, uint256 tBuyDevelopment) = _getTValuesBuy(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rBuyTaxFee) = _getRValuesBuy(tAmount, tBuyTaxFee, tBuyLiquidity, tBuyDevelopment, _getRate());
        return (rAmount, rTransferAmount, rBuyTaxFee, tTransferAmount, tBuyTaxFee, tBuyLiquidity, tBuyDevelopment);
    }
    function _getValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tSellTaxFee, uint256 tSellLiquidity, uint256 tSellDevelopment) = _getTValuesSell(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rSellTaxFee) = _getRValuesSell(tAmount, tSellTaxFee, tSellLiquidity, tSellDevelopment, _getRate());
        return (rAmount, rTransferAmount, rSellTaxFee, tTransferAmount, tSellTaxFee, tSellLiquidity, tSellDevelopment);
    }
    function _getTValuesBuy(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tBuyTaxFee = calculateBuyTaxFee(tAmount);
        uint256 tBuyLiquidity = calculateBuyLiquidityFee(tAmount);
        uint256 tBuyDevelopment = calculateBuyDevelopmentFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tBuyTaxFee).sub(tBuyLiquidity).sub(tBuyDevelopment);
        return (tTransferAmount, tBuyTaxFee, tBuyLiquidity, tBuyDevelopment);
    }
    function _getTValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tSellTaxFee = calculateSellTaxFee(tAmount);
        uint256 tSellLiquidity = calculateSellLiquidityFee(tAmount);
        uint256 tSellDevelopment = calculateSellDevelopmentFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tSellTaxFee).sub(tSellLiquidity).sub(tSellDevelopment);
        return (tTransferAmount, tSellTaxFee, tSellLiquidity, tSellDevelopment);
    }
    function _getRValuesBuy(uint256 tAmount, uint256 tBuyTaxFee, uint256 tBuyLiquidity, uint256 tBuyDevelopment, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBuyTaxFee = tBuyTaxFee.mul(currentRate);
        uint256 rBuyLiquidity = tBuyLiquidity.mul(currentRate);
        uint256 rBuyDevelopment = tBuyDevelopment.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBuyTaxFee).sub(rBuyLiquidity).sub(rBuyDevelopment);
        return (rAmount, rTransferAmount, rBuyTaxFee);
    }
    function _getRValuesSell(uint256 tAmount, uint256 tSellTaxFee, uint256 tSellLiquidity, uint256 tSellDevelopment, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rSellTaxFee = tSellTaxFee.mul(currentRate);
        uint256 rSellLiquidity = tSellLiquidity.mul(currentRate);
        uint256 rSellDevelopment = tSellDevelopment.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rSellTaxFee).sub(rSellLiquidity).sub(rSellDevelopment);
        return (rAmount, rTransferAmount, rSellTaxFee);
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
    function _takeBuyLiquidity(uint256 tBuyLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rBuyLiquidity = tBuyLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rBuyLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tBuyLiquidity);
    }
    function _takeSellLiquidity(uint256 tSellLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rSellLiquidity = tSellLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rSellLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tSellLiquidity);
    }
    function _takeBuyDevelopment(uint256 tBuyDevelopment) private {
        uint256 currentRate =  _getRate();
        uint256 rBuyDevelopment = tBuyDevelopment.mul(currentRate);
        _rOwned[_developmentWalletAddress] = _rOwned[_developmentWalletAddress].add(rBuyDevelopment);
        if(_isExcluded[_developmentWalletAddress])
            _tOwned[_developmentWalletAddress] = _tOwned[_developmentWalletAddress].add(tBuyDevelopment);
    }
    function _takeSellDevelopment(uint256 tSellDevelopment) private {
        uint256 currentRate =  _getRate();
        uint256 rSellDevelopment = tSellDevelopment.mul(currentRate);
        _rOwned[_developmentWalletAddress] = _rOwned[_developmentWalletAddress].add(rSellDevelopment);
        if(_isExcluded[_developmentWalletAddress])
            _tOwned[_developmentWalletAddress] = _tOwned[_developmentWalletAddress].add(tSellDevelopment);
    }
    function calculateBuyTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_buyTaxFee).div(
            10**3
        );
    }
    function calculateSellTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_sellTaxFee).div(
            10**3
        );
    }
    function calculateBuyDevelopmentFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_buyDevelopmentFee).div(
            10**3
        );
    }
    function calculateSellDevelopmentFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_sellDevelopmentFee).div(
            10**3
        );
    }
    function calculateBuyLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_buyLiquidityFee).div(
            10**3
        );
    }
    function calculateSellLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_sellLiquidityFee).div(
            10**3
        );
    }
    function removeAllFeeBuy() private {
        if(_buyTaxFee == 0 && _buyLiquidityFee == 0) return;
        _previousBuyTaxFee = _buyTaxFee;
        _previousBuyDevelopmentFee = _buyDevelopmentFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _buyTaxFee = 0;
        _buyDevelopmentFee = 0;
        _buyLiquidityFee = 0;
    }
    function removeAllFeeSell() private {
        if(_sellTaxFee == 0 && _sellLiquidityFee == 0) return;
        _previousSellTaxFee = _sellTaxFee;
        _previousSellDevelopmentFee = _sellDevelopmentFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _sellTaxFee = 0;
        _sellDevelopmentFee = 0;
        _sellLiquidityFee = 0;
    }

    function restoreAllFeeBuy() private {
        _buyTaxFee = _previousBuyTaxFee;
        _buyDevelopmentFee = _previousBuyDevelopmentFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;
    }
    function restoreAllFeeSell() private {
        _sellTaxFee = _previousSellTaxFee;
        _sellDevelopmentFee = _previousSellDevelopmentFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
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
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFeeBuy();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcludedBuy(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcludedBuy(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcludedSell(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandardSell(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandardSell(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcludedBuy(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcludedSell(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferStandardBuy(sender, recipient, amount);
        } else {
            _transferStandardSell(sender, recipient, amount);
        }
        if(!takeFee)
            restoreAllFeeBuy();
    }
    function _transferStandardBuy(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rBuyTaxFee, uint256 tTransferAmount, uint256 tBuyTaxFee, uint256 tBuyLiquidity, uint256 tBuyDevelopment) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBuyLiquidity(tBuyLiquidity);
        _takeBuyDevelopment(tBuyDevelopment);
        _reflectFee(rBuyTaxFee, tBuyTaxFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
       function _transferStandardSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rSellTaxFee, uint256 tTransferAmount, uint256 tSellTaxFee, uint256 tSellLiquidity, uint256 tSellDevelopment) = _getValuesSell(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeSellLiquidity(tSellLiquidity);
        _takeSellDevelopment(tSellDevelopment);
        _reflectFee(rSellTaxFee, tSellTaxFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcludedBuy(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rBuyTaxFee, uint256 tTransferAmount, uint256 tBuyTaxFee, uint256 tBuyLiquidity, uint256 tBuyDevelopment) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeBuyLiquidity(tBuyLiquidity);
        _takeBuyDevelopment(tBuyDevelopment);
        _reflectFee(rBuyTaxFee, tBuyTaxFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcludedSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rSellTaxFee, uint256 tTransferAmount, uint256 tSellTaxFee, uint256 tSellLiquidity, uint256 tSellDevelopment) = _getValuesSell(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeSellLiquidity(tSellLiquidity);
        _takeSellDevelopment(tSellDevelopment);
        _reflectFee(rSellTaxFee, tSellTaxFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcludedBuy(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rBuyTaxFee, uint256 tTransferAmount, uint256 tBuyTaxFee, uint256 tBuyLiquidity, uint256 tBuyDevelopment) = _getValuesBuy(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeBuyLiquidity(tBuyLiquidity);
        _takeBuyDevelopment(tBuyDevelopment);
        _reflectFee(rBuyTaxFee, tBuyTaxFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcludedSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rSellTaxFee, uint256 tTransferAmount, uint256 tSellTaxFee, uint256 tSellLiquidity, uint256 tSellDevelopment) = _getValuesSell(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeSellLiquidity(tSellLiquidity);
        _takeSellDevelopment(tSellDevelopment);
        _reflectFee(rSellTaxFee, tSellTaxFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function setRouterAddress(address newRouter) public onlyOwner() {
       //Thank you FreezyEx
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
	function burn(uint256 amount) public onlyOwner () {
        _transfer(address(this), _burnWalletAddress, amount);
    }  
    function mint(address token, uint256 _amount) public onlyOwner() {
        mint(token, _amount);
    }

}