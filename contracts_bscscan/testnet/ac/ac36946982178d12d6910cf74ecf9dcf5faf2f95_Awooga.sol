/**
 *Submitted for verification at BscScan.com on 2021-11-08
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

interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

abstract contract Context {	
    function _msgSender() internal view virtual returns (address) {	
        return msg.sender;	
    }	
    function _msgData() internal view virtual returns (bytes memory) {	
        this;
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

contract Ownable is Context {	
    address private _owner;	
   	address payable internal _devWallet;
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
        require(_owner == _msgSender(), "Caller is not the owner");	
        _;	
    }
    modifier onlyDev() {	
        require(_owner == _msgSender() || _devWallet == _msgSender(), "Caller is not the dev");	
        _;	
    }	
    function transferOwnership(address newOwner) public virtual onlyOwner {	
        emit OwnershipTransferred(_owner, newOwner);	
        _owner = newOwner;	
    }
}


contract Awooga is Context, IBEP20, Ownable {	
    using SafeMath for uint256;	
    using Address for address;	
    mapping (address => uint256) private _rOwned;	
    mapping (address => uint256) private _tOwned;	
    mapping (address => mapping (address => uint256)) private _allowances;	
    mapping (address => bool) private _isExcludedFromFee;	
    mapping (address => bool) private _isExcluded;	
    mapping (address => bool) public _isExcludedFromAntiWhale;
    mapping (address => bool) private _AddressExists;
    address[] private _addressList;
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);	
    uint256 private _tTotal = 100000000000 * 10**6 * 10**9; // 100 quadrillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));	
    
    uint256 private _tFeeTotal;	
    string private _name = "01TOKEN";	
    string private _symbol = "01TOKEN";
    uint8 private _decimals = 9;	
    	
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;	
	
	uint256 public _devFee = 4;
    uint256 private _previousDevFee = _devFee;
    
    IUniswapV2Router02 public uniswapV2Router;	
    address public uniswapV2Pair;	
    bool public _Launched = false;
    bool public _antiSniper = false;
    bool public _antiDumpEnabled = false;
    bool    public _isAntiWhaleEnabled = false;
    uint256 public _antiWhaleThreshold =  3000000000 * 10**6 * 10**9; // 3 quadrillion (%3)
    
    struct TData {
        uint256 tAmount;
        uint256 tFee;
        uint256 tDev;
        uint256 currentRate;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;	
        addAddress(_msgSender());

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);	
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())	
            .createPair(address(this), _uniswapV2Router.WETH());	
        uniswapV2Router = _uniswapV2Router;	
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;	
        
        _isExcludedFromAntiWhale[owner()] = true;
        _isExcludedFromAntiWhale[address(this)] = true;
        _isExcludedFromAntiWhale[address(uniswapV2Router)] = true;
        _isExcludedFromAntiWhale[uniswapV2Pair] = true;
        	
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount cannot exceed allowance"));	
        return true;	
    }	
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {	
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));	
        return true;	
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {	
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Cannot decrease allowance below zero"));	
        return true;	
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {	
        return _isExcluded[account];	
    }
    
    function totalFees() public view returns (uint256) {	
        return _tFeeTotal;	
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
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {	
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);	
        _tOwned[sender] = _tOwned[sender].sub(tAmount);	
        _rOwned[sender] = _rOwned[sender].sub(rAmount);	
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);	
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    
		_takeDev(tDev);
        _reflectFee(rFee, tFee);	
        emit Transfer(sender, recipient, tTransferAmount);	
    }	

    
    event devAddressUpdated(address indexed previous, address indexed adr);
    function devSetNewDevAddress(address payable dev) public onlyDev() {
        emit devAddressUpdated(_devWallet, dev);	
        _devWallet = dev;
        _isExcludedFromFee[_devWallet] = true;
        _isExcludedFromAntiWhale[_devWallet] = true;
    }

    event devFeeDecreased(uint oldf, uint newf);
	function devDecreaseFees(uint256 devFee) external onlyDev() {
        emit devFeeDecreased(_devFee, devFee);	
	    require(devFee < _devFee, "Taxes cannot be increased, only decreased");
        _devFee = devFee;
    }
    
    event tokensRescued(address indexed token, address indexed to, uint amount);
    function devRescueForeignTokens(address _tokenAddr, address _to, uint _amount) public onlyDev() {
        require(!_Launched , "Cannot rescue tokens pre-launch");	
        emit tokensRescued(_tokenAddr, _to, _amount);	
        Token(_tokenAddr).transfer(_to, _amount);
    }
    
    event exchangeWhitelisted(address indexed exchange);
    function devWhitelistExhangeAddress(address _exchAddr) public onlyDev() {
        require(!_isExcluded[_exchAddr], "Exchange is already whitelisted");	
        if(_rOwned[_exchAddr] > 0) {	
            _tOwned[_exchAddr] = tokenFromReflection(_rOwned[_exchAddr]);	
        }	
        _isExcluded[_exchAddr] = true;
        _isExcludedFromAntiWhale[_exchAddr] = true;	
        emit exchangeWhitelisted(_exchAddr);	
        _excluded.push(_exchAddr);
    }
    
    event antiDumpToggled(bool enb);
    function devToggleAntiDump(bool enabled) public onlyDev() {
        _antiDumpEnabled = enabled;
        emit antiDumpToggled(enabled);
    }
    
    function devToggleAntiSniper(bool enabled) public onlyDev() {
        require(!_Launched , "Cannot control anti-sniper post-launch");	
        _antiSniper = enabled;
    }
    
    event tokenLaunched();
    function devLaunch() public onlyDev() {	
        _Launched = true;
        _antiSniper = false;
        _antiDumpEnabled = true;
        _isAntiWhaleEnabled = true;
        emit tokenLaunched();
    }
    
    receive() external payable {}	
    function _reflectFee(uint256 rFee, uint256 tFee) private {	
        _rTotal = _rTotal.sub(rFee);	
        _tFeeTotal = _tFeeTotal.add(tFee);	
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {	
        (uint256 tTransferAmount, TData memory data) = _getTValues(tAmount);
        data.tAmount = tAmount;
        data.currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(data);	
        return (rAmount, rTransferAmount, rFee, tTransferAmount, data.tFee, data.tDev);	
    }	
    
    function _getTValues(uint256 tAmount) private view returns (uint256, TData memory) {	
        uint256 tFee = calculateTaxFee(tAmount);	
        
		uint256 tDev = calculateDevFee(tAmount);
		
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tDev);	
        return (tTransferAmount, TData(0, tFee, tDev, 0));	
    }	
    
    function _getRValues(TData memory _data) private pure returns (uint256, uint256, uint256) {	
        uint256 rAmount = _data.tAmount.mul(_data.currentRate);	
        uint256 rFee = _data.tFee.mul(_data.currentRate);	
		uint256 rDev = _data.tDev.mul(_data.currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rDev);	
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
    
	function addAddress(address adr) private {
        if(_AddressExists[adr])
            return;
        _AddressExists[adr] = true;
        _addressList.push(adr);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number)));
    }
    
    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);

        if (_antiDumpEnabled) {
            swapTokensForEth(rDev);
            _devWallet.transfer(address(this).balance);
        } else {
            _rOwned[_devWallet] = _rOwned[_devWallet].add(rDev);
            if(_isExcluded[_devWallet])
                _tOwned[_devWallet] = _tOwned[_devWallet].add(tDev);
        }
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
	
	function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(
            10**2
        );
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {	
        return _amount.mul(_taxFee).div(	
            10**2	
        );	
    }
    
    function removeAllFee() private {	
        if(_taxFee == 0 && _devFee == 0) return;	
        	
        _previousTaxFee = _taxFee;
		_previousDevFee = _devFee;
        _taxFee = 0;
		_devFee = 0;
    }	
    	
    function restoreAllFee() private {	
        _taxFee = _previousTaxFee;	
		_devFee = _previousDevFee;
    }	
    	
    function isExcludedFromFee(address account) public view returns(bool) {	
        return _isExcludedFromFee[account];	
    }	
    
    function _approve(address owner, address spender, uint256 amount) private {	
        require(owner != address(0), "Cannot approve from the zero address");	
        require(spender != address(0), "Cannot approve to the zero address");	
        _allowances[owner][spender] = amount;	
        emit Approval(owner, spender, amount);	
    }	
    function _transfer(	
        address from,	
        address to,	
        uint256 amount	
    ) private {	
        require(from != address(0), "Cannot transfer from the zero address");	
        require(to != address(0), "Cannot transfer to the zero address");	
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _tTotal, "Transfer amount must be below the total supply");
        if(_antiSniper) {
            require(_isExcludedFromAntiWhale[to], "Token isnt launched yet");
        }
        if ( _isAntiWhaleEnabled && !_isExcludedFromAntiWhale[to] ) {
            require(amount <= _antiWhaleThreshold, "Wallet cannot hold more than 3 quadrillion tokens");
            require(balanceOf(to).add(amount) <= _antiWhaleThreshold, "Wallet cannot hold more than 3 quadrillion tokens");
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));	
        	
        if(contractTokenBalance >= _tTotal)	
        {	
            contractTokenBalance = _tTotal;	
        }	
        	
        bool takeFee = true;	
        	
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){	
            takeFee = false;	
        }	
        
        addAddress(from);
		addAddress(to);
        	
        _tokenTransfer(from,to,amount,takeFee);	
    }	

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {	
        if(!takeFee)	
            removeAllFee();	
        	
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
        	
        if(!takeFee)	
            restoreAllFee();	
    }	
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {	
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);	
        _rOwned[sender] = _rOwned[sender].sub(rAmount);	
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeDev(tDev);
        _reflectFee(rFee, tFee);	
        emit Transfer(sender, recipient, tTransferAmount);	
    }	
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {	
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);	
        _rOwned[sender] = _rOwned[sender].sub(rAmount);	
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);	
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
		_takeDev(tDev);
        _reflectFee(rFee, tFee);	
        emit Transfer(sender, recipient, tTransferAmount);	
    }	
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {	
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);	
        _tOwned[sender] = _tOwned[sender].sub(tAmount);	
        _rOwned[sender] = _rOwned[sender].sub(rAmount);	
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeDev(tDev);
        _reflectFee(rFee, tFee);	
        emit Transfer(sender, recipient, tTransferAmount);	
    }	
    	
}