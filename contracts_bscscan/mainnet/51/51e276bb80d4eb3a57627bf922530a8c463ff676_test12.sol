/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
interface IBEP20 {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
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
contract test12 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isFeeListed;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    string private _name;
    string private _symbol;
    uint8 private _decimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**9 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public _maxBuyTxAmount = _tTotal * 5 / (10**3); // 0.5%
    uint256 public _maxSellTxAmount = _tTotal * 5 / (10**3); // 0.5%
    //buy

    uint256 private _taxFeeAmount = 0;
    uint256 private _previousTaxFeeAmount = 0;
    uint256 public _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _marketFee;
    uint256 private _previousMarketFee = _marketFee;
    address private _marketingWalletAddress;
    //sell
    uint256 public _gameFee;
    uint256 private _previousGameFee = _gameFee;
    address private _gameWalletAddress;
 
    uint256 public _resAndDevFee;
    uint256 private _previousResAndDevFee = _resAndDevFee;
    address private _resAndDevWalletAddress;

    uint256 public _nftFee;
    uint256 private _previousNftFee = _nftFee;
    address private _nftWalletAddress;

    uint256 public _totalFee;
    uint256 public _buyTotalFee;
    uint256 public _sellTotalFee;
  
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    bool inSwap = false;
    bool public swapEnabled = true;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
constructor (string memory Name, string memory Symbol, uint256 taxFee, uint256 marketFee, uint256 gameFee, uint256 resAndDevFee, uint256 nftFee,
                address marketingWalletAddress, address payable gameWalletAddress, address payable resAndDevWalletAddress, address payable nftWalletAddress ) {
        _name = Name;
        _symbol = Symbol;

        _marketFee = marketFee;
        _taxFee = taxFee;
        _gameFee = gameFee;
        _resAndDevFee = resAndDevFee;
        _nftFee = nftFee;
        _previousMarketFee = _marketFee;
        _previousTaxFee = _taxFee;
        _previousGameFee = _gameFee;
        _previousResAndDevFee = _resAndDevFee;
        _previousNftFee = _nftFee;
        _buyTotalFee = _marketFee.add(_taxFee);
        _sellTotalFee = _nftFee.add(_gameFee).add(_resAndDevFee);
        _totalFee = _buyTotalFee.add(_sellTotalFee);

        _marketingWalletAddress = marketingWalletAddress;
        _gameWalletAddress = gameWalletAddress;
        _resAndDevWalletAddress = resAndDevWalletAddress;
        _nftWalletAddress = nftWalletAddress;

        _rOwned[_msgSender()] = _rTotal;
        // MAINNET PCS Router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // TESTNET Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWalletAddress] = true;
        _isExcludedFromFee[_gameWalletAddress] = true;
        _isExcludedFromFee[_resAndDevWalletAddress] = true;
        _isExcludedFromFee[_nftWalletAddress] = true;
        
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
    function totalTaxFees() public view returns (uint256) {
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
    function excludeFromReward(address account) public onlyOwner() {
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
    function setExcludeFromFee(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[account] = excluded;
    } 
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function setFees(uint256 marketFee, uint256 taxFee, uint256 resAndDevFee, uint256 gameFee, uint256 nftFee) external onlyOwner() {
        _marketFee = marketFee;
        _taxFee = taxFee;
        _gameFee = gameFee;
        _resAndDevFee = resAndDevFee;
        _nftFee = nftFee;
        setTotalFee();
    }
    function setSellTotalFee() private{
        _sellTotalFee = _nftFee.add(_gameFee).add(_resAndDevFee);
    }
    function setBuyTotalFee() private{
        _buyTotalFee = _marketFee.add(_taxFee);
    }
    function setTotalFee() private{
        setBuyTotalFee();
        setSellTotalFee();
        _totalFee = _buyTotalFee.add(_sellTotalFee);
    }
    function setMarketFeePercent(uint256 marketFee) external onlyOwner() {
        _marketFee = marketFee;
        setBuyTotalFee();
    }    
    function setMarketWallet(address marketWallet) external onlyOwner() {
        _marketingWalletAddress = marketWallet;
        setExcludeFromFee(_marketingWalletAddress, true);
    }   
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
        setBuyTotalFee();
    }    
    function setGameFeePercent(uint256 gameFee) external onlyOwner() {
        _gameFee = gameFee;
        setSellTotalFee();
    }    
    function setGameWallet(address payable gameWallet) external onlyOwner() {
        _gameWalletAddress = gameWallet;
        setExcludeFromFee(_gameWalletAddress, true);
    }
    function setResAndDevFeePercent(uint256 resAndDevFee) external onlyOwner() {
        _resAndDevFee = resAndDevFee;
        setSellTotalFee();
    }    
    function setResAndDevWallet(address payable resAndDevWallet) external onlyOwner() {
        _resAndDevWalletAddress = resAndDevWallet;
        setExcludeFromFee(_resAndDevWalletAddress, true);
    }    
    function setNftFeePercent(uint256 nftFee) external onlyOwner() {
        _nftFee = nftFee;
        setSellTotalFee();
    }    
    function setNftWallet(address payable nftWallet) external onlyOwner() {
        _nftWalletAddress = nftWallet;
        setExcludeFromFee(_nftWalletAddress, true);
    }     
    function setBuyMaxTxPercent(uint256 maxBuyTxPercent) external onlyOwner() {
        _maxBuyTxAmount = _tTotal.mul(maxBuyTxPercent).div(10**2);
    }     
    function setSellMaxTxPercent(uint256 maxSellTxPercent) external onlyOwner() {
        _maxSellTxAmount = _tTotal.mul(maxSellTxPercent).div(10**2);
    }
    function airDrop(address[] calldata addresses, uint256 amount) external onlyOwner() {
        amount = amount.mul(10 ** _decimals);
        uint256 addressCount = addresses.length;
        uint256 tokenBalance = balanceOf(_msgSender());
        uint256 totalWantSendToken = addressCount.mul(amount);
        require(totalWantSendToken <= tokenBalance, "Total amount must be less than your total token amount.");
        for (uint256 i = 0; i < addressCount; i++) {
            address sendAddress = addresses[i];
            _transferStandard(_msgSender(), sendAddress, amount);
        }
    }
    function setFeeListAddress(address account, bool value) external onlyOwner{
        _isFeeListed[account] = value;
    }
    function addOrSubToFeeList(address[] calldata addresses, bool value) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isFeeListed[addresses[i]] = value;
      }
    }
    function isFeeListed(address account) public view returns(bool) {
        return _isFeeListed[account];
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function removeAllFee() private {
        if(_marketFee == 0 && _gameFee == 0 && _taxFee==0 && _resAndDevFee==0 && _nftFee==0) return;
        
        _previousMarketFee = _marketFee;
        _previousTaxFee = _taxFee;
        _previousGameFee = _gameFee;
        _previousResAndDevFee = _resAndDevFee;
        _previousNftFee = _nftFee;
        
        _marketFee = 0;
        _taxFee = 0;
        _gameFee = 0;
        _resAndDevFee = 0;
        _nftFee = 0;

        setTotalFee();
    }
    function restoreAllFee() private {
        _marketFee = _previousMarketFee;
        _taxFee = _previousTaxFee;
        _gameFee = _previousGameFee;
        _resAndDevFee = _previousResAndDevFee;
        _nftFee = _previousNftFee;
        setTotalFee();
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
    function _takeFee(uint256 tFee) private {
        uint256 currentRate = _getRate();
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function swapBack(uint256 tokensToLiquify) internal lockTheSwap {
        uint256 amountToSwap = tokensToLiquify;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();


        _approve(address(this), address(uniswapV2Router), tokensToLiquify);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbBalance = address(this).balance;
        
        uint256 bnbForGame = bnbBalance.mul(_gameFee).div(_sellTotalFee);
        uint256 bnbForResAndDev = bnbBalance.mul(_resAndDevFee).div(_sellTotalFee);
        uint256 bnbForNft = bnbBalance.mul(_nftFee).div(_sellTotalFee);

        payable(_gameWalletAddress).transfer(bnbForGame);
        payable(_resAndDevWalletAddress).transfer(bnbForResAndDev);
        payable(_nftWalletAddress).transfer(bnbForNft);
    }
    function checkMaxTXAmount(address sender,address recipient, uint256 amount, bool isBuy) internal view{
        if(sender != owner() || recipient != owner() || ! _isExcludedFromFee[recipient] || ! _isExcludedFromFee[sender]) {
            if (!isBuy) {
                require(amount <= _maxSellTxAmount,"Transfer amount exceeds the maxSellTxAmount");
            } else {
                require(amount <= _maxBuyTxAmount,"Transfer amount exceeds the maxBuyTxAmount");
            }
        }
    }
    function checkFeeList(address sender,address recipient) internal view{
        require(!_isFeeListed[sender] && !_isFeeListed[recipient], 'FeeListed address');
    }
    function feeAmountCalculator(uint256 amount, uint256 fee) private pure returns(uint256){
        return amount.mul(fee).div(10**2);
    }
    function _takeBuyFee(address sender, uint256 amount) private returns (uint256) {
        if(_buyTotalFee == 0 || amount == 0)
            return amount;

        uint256 taxAmt = calculateTaxFee(amount);
        uint256 marketAmt = 0;

        if(_marketFee != 0){
             marketAmt = feeAmountCalculator(amount, _marketFee);
            _transferStandard(sender, _marketingWalletAddress, marketAmt);
        }
        _taxFeeAmount = taxAmt;
        amount = amount.sub(marketAmt).sub(_taxFeeAmount);
        return amount;
    }
    function _takeSellFee(address sender, uint256 amount) private returns (uint256) {
        if (_sellTotalFee != 0 || amount != 0){
            if(_gameFee != 0){
                uint256 gameAmt = feeAmountCalculator(amount, _gameFee);
                _transferStandard(sender, _gameWalletAddress, gameAmt);
            }
            if(_resAndDevFee != 0){
                uint256 resAndDevAmt = feeAmountCalculator(amount, _resAndDevFee);
                _transferStandard(sender, _resAndDevWalletAddress, resAndDevAmt);
            }
            if(_nftFee != 0){
                uint256 _nftAmt = feeAmountCalculator(amount, _nftFee);
                _transferStandard(sender, _nftWalletAddress, _nftAmt);
            }
            amount = amount.sub(feeAmountCalculator(amount, _sellTotalFee));
        }
        return amount;
    }
    // If you need more features, you can contact to @frknlkn (any social platform)
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        checkFeeList(sender, recipient);

        _tokenTransfer(sender, recipient, amount);
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        bool takeFee = true; 
         
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
        if (!takeFee) removeAllFee();
        else{
            // Sell
            if (recipient == uniswapV2Pair) {
                checkMaxTXAmount(sender, recipient, amount, false);
                amount = _takeSellFee(sender, amount);
            }
            else 
            {
                checkMaxTXAmount(sender, recipient, amount, true);
                amount = _takeBuyFee(sender, amount);
            }                                 
        }        
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        } 
        _taxFeeAmount = _previousTaxFeeAmount;
        if (!takeFee) restoreAllFee();

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
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = _taxFeeAmount;
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
     //New Pancakeswap router version?s
    function setRouterAddress(address newRouter) public onlyOwner() {
         IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
         uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
         uniswapV2Router = _newPancakeRouter;
     }
}