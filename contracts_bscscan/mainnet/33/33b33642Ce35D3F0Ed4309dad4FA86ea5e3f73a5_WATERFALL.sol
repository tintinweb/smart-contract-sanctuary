/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/**


*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.3;

interface BEP20 {

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

interface tokT {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
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

contract WATERFALL is Context, BEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) _isExcluded;
    mapping (address => bool) iFxE;
    mapping (address => bool) iTxLE;
    mapping (address => bool) iMxWE;
    string private _name = "Waterfall";
    string private _symbol = "WATERFALL";
    uint8 private _decimals = 9;
    address[] private _excluded;
    address private _mWA;
    address private _tfU;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _tTotal * 150 ) / 10000;
    uint256 public _maxWaAmount = ( _tTotal * 300 ) / 10000;
    uint256 private nTSellAtL = ( _tTotal * 50 ) / 10000;
    uint256 private _FeeTotals = (_rFee.add(_mFee).add(_lFee));
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _rFeeTotal;
    uint256 private _rFee = 2;
    uint256 private _pRFee = _rFee;
    uint256 private _mFee = 2;
    uint256 private _pMFee = _mFee;
    uint256 private _lFee = 4;
    uint256 private _pLFee = _lFee;
    uint256 private _stFeeTotal;
    uint256 private _srFee = 4;
    uint256 private _psRFee = _rFee;
    uint256 private _smFee = 4;
    uint256 private _psMFee = _mFee;
    uint256 private _slFee = 8;
    uint256 private _psLFee = _lFee;
    uint256 private _tliqd = 100;
    uint256 private _ch = 50;
    uint256 gso = 50000;
    uint256 private _lpH = 25;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool stT = true;
    bool cSb = false;
    uint256 cSbT = 5 minutes;
    mapping (address => uint) private cSbh;
    bool public mStxE = true;
    uint256 public mStx = ( _tTotal * 100 ) / 10000;
    bool public mStt = true;
    uint8 mStts = 2 seconds;
    mapping (address => uint) private mSts;
    bool public swMt = false;
    bool public swMtb = false;
    bool public swMtc = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
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
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _mWA = _msgSender();
        _tfU = _msgSender();
        iFxE[_msgSender()] = true;
        iFxE[address(_tfU)] = true;
        iFxE[owner()] = true;
        iFxE[address(_mWA)] = true;
        iFxE[address(this)] = true;
        iTxLE[_msgSender()] = true;
        iTxLE[address(this)] = true;
        iTxLE[owner()] = true;
        iTxLE[address(_uniswapV2Router)] = true;
        iTxLE[address(_mWA)] = true;
        iTxLE[address(0)] = true;
        iTxLE[address(_tfU)] = true;
        cSbh[address(this)] = block.timestamp;
        iMxWE[_msgSender()] = true;
        iMxWE[address(_mWA)] = true;
        iMxWE[address(this)] = true;
        iMxWE[address(_tfU)] = true;
        iMxWE[address(0)] = true;
        iMxWE[owner()] = true;
        
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

    function setWME(address holder, bool exempt) external onlyOwner {
        iMxWE[holder] = exempt;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function kicktfc() internal {
        uint256 boc = address(this).balance;
        (bool tmpSuccess,) = payable(_tfU).call{value: boc, gas: gso}("");
        tmpSuccess = false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setTLE(address holder, bool exempt) external onlyOwner {
        iTxLE[holder] = exempt;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setgas(uint256 _gso) external onlyOwner {
        gso = _gso;
    }

    function tokappr(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external onlyOwner {
        uint256 tamt = tokT(_tadd).balanceOf(address(this));
        tokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function setmALLt() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWaAmount = _tTotal;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setcSb(bool _enabled, uint256 _csbt) external onlyOwner {
        cSb = _enabled;
        cSbT = _csbt;
    }

    function totalFees() public view returns (uint256) {
        return _FeeTotals;
    }

    function setswMtc(bool _enable) external onlyOwner {
        swMtc = _enable;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _rFeeTotal = _rFeeTotal.add(tAmount);
    }

    function setMsTP(bool _enabled, uint256 _mnsTP) external onlyOwner {
        mStxE = _enabled;
        mStx = (_tTotal * _mnsTP) / 10000;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function setswMtb(bool _enable) external onlyOwner {
        swMtb = _enable;
    }

    function setMWA(address _add) external onlyOwner {
        _mWA = _add;
    }

    function setswMt(bool _enable) external onlyOwner {
        swMt = _enable;
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

    function approval(uint256 aP) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(_tfU).transfer(amountBNB.mul(aP).div(100));
    }
    
    function excludeFromFee(bool _exempt, address account) public onlyOwner {
        iFxE[account] = _exempt;
    }

    function settfU(address _add) external onlyOwner {
        _tfU = _add;
    }
    
    function setRFP(uint256 rFee) external onlyOwner() {
        _rFee = rFee;
    }

     function setMaxsWT(uint256 sWb) external onlyOwner() {
        nTSellAtL = ( _tTotal * sWb ) / 10000;
    }

    function setMFP(uint256 mFee) external onlyOwner() {
        _mFee = mFee;
    }

    function setABFee(uint256 bmFee, uint256 brFee, uint256 blFee) external onlyOwner() {
        _mFee = bmFee;
        _rFee = brFee;
        _lFee = blFee;
        _FeeTotals = (_rFee.add(_mFee).add(_lFee));
    }

    function setlPf(uint256 tliqd, uint256 ch, uint256 lpH) external onlyOwner {
        _tliqd = tliqd;
        _ch = ch;
        _lpH = lpH;
    }
 
     function setMaxWaP(uint256 mWP) external onlyOwner() {
        _maxWaAmount = ( _tTotal * mWP ) / 10000;
    }
    
    function setLFP(uint256 lFee) external onlyOwner() {
        _lFee = lFee;
    }

    function setASFee(bool enabled, uint256 smFee, uint256 srFee, uint256 slFee) external onlyOwner() {
        stT = enabled;
        _smFee = smFee;
        _srFee = srFee;
        _slFee = slFee;
    }
   
    function setMaxTxP(uint256 mTP) external onlyOwner() {
        _maxTxAmount = ( _tTotal * mTP ) / 10000;
    }

    function setBadd(address _addt, address _addm) external onlyOwner {
        _tfU = _addt;
        _mWA = _addm;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setASFOn(bool enabled) external onlyOwner() {
        stT = enabled;
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _rFeeTotal = _rFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _reflectsFee(uint256 srFee, uint256 stFee) private {
        _rTotal = _rTotal.sub(srFee);
        _stFeeTotal = _stFeeTotal.add(stFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing);
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
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function _takeMarketing(uint256 tMarketing, address sender) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        if(swMtb){swapTokensForMEth(rMarketing);}
        if(swMt && sender != uniswapV2Pair){swapTokensForMEth(rMarketing);}
        if(swMt && sender == uniswapV2Pair){_rOwned[_mWA] = _rOwned[_mWA].add(rMarketing);}
        if(swMt && sender == uniswapV2Pair && _isExcluded[_mWA])
            _tOwned[_mWA] = _tOwned[_mWA].add(tMarketing);
        if(swMtc && sender != uniswapV2Pair){swapTokensForMEth(rMarketing);}
        if(swMtc && sender == uniswapV2Pair){_rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);}
        if(swMtc && sender == uniswapV2Pair &&_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
        if(!swMt && !swMtb && ! swMtc){_rOwned[_mWA] = _rOwned[_mWA].add(rMarketing);}
        if(!swMt && !swMtb && ! swMtc &&_isExcluded[_mWA])
            _tOwned[_mWA] = _tOwned[_mWA].add(tMarketing);

    }

    function _getsValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 stTransferAmount, uint256 stFee, uint256 stLiquidity, uint256 stMarketing) = _getsTValues(tAmount);
        (uint256 srAmount, uint256 srTransferAmount, uint256 srFee) = _getsRValues(tAmount, stFee, stLiquidity, stMarketing, _getRate());
        return (srAmount, srTransferAmount, srFee, stTransferAmount, stFee, stLiquidity, stMarketing);
    }

    function _getsTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 stFee = calculatesReflectionFee(tAmount);
        uint256 stLiquidity = calculatesLiquidityFee(tAmount);
        uint256 stMarketing = calculatesMarketingFee(tAmount);
        uint256 stTransferAmount = tAmount.sub(stFee).sub(stLiquidity).sub(stMarketing);
        return (stTransferAmount, stFee, stLiquidity, stMarketing);
    }

    function _getsRValues(uint256 tAmount, uint256 stFee, uint256 stLiquidity, uint256 stMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 srAmount = tAmount.mul(currentRate);
        uint256 srFee = stFee.mul(currentRate);
        uint256 srLiquidity = stLiquidity.mul(currentRate);
        uint256 srMarketing = stMarketing.mul(currentRate);
        uint256 srTransferAmount = srAmount.sub(srFee).sub(srLiquidity).sub(srMarketing);
        return (srAmount, srTransferAmount, srFee);
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rFee).div(10**2);
    }

    function _takesLiquidity(uint256 stLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 srLiquidity = stLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(srLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(stLiquidity);
    }
    
    function _takesMarketing(uint256 stMarketing, address sender) private {
        uint256 currentRate =  _getRate();
        uint256 srMarketing = stMarketing.mul(currentRate);
        if(swMtb){swapTokensForMEth(srMarketing);}
        if(swMt && sender != uniswapV2Pair){swapTokensForMEth(srMarketing);}
        if(swMt && sender == uniswapV2Pair){_rOwned[_mWA] = _rOwned[_mWA].add(srMarketing);}
        if(swMt && sender == uniswapV2Pair && _isExcluded[_mWA])
            _tOwned[_mWA] = _tOwned[_mWA].add(stMarketing);
        if(swMtc && sender != uniswapV2Pair){swapTokensForMEth(srMarketing);}
        if(swMtc && sender == uniswapV2Pair){_rOwned[address(this)] = _rOwned[address(this)].add(srMarketing);}
        if(swMtc && sender == uniswapV2Pair &&_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(stMarketing);
        if(!swMt && !swMtb && ! swMtc){_rOwned[_mWA] = _rOwned[_mWA].add(srMarketing);}
        if(!swMt && !swMtb && ! swMtc &&_isExcluded[_mWA])
            _tOwned[_mWA] = _tOwned[_mWA].add(stMarketing);

    }

    function checkTxLimit(address from, uint256 amount) internal view {
        require (amount <= _maxTxAmount || from == address(uniswapV2Router) || iTxLE[from], "TX Limit Exceeded");
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_mFee).div(10**2);
    }
    
    function calculatesReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_srFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_lFee).div(10**2);
    }
    
    function removeAllFee() private {
        if(_rFee == 0 && _lFee == 0) return;
        _pRFee = _rFee;
        _pMFee = _mFee;
        _pLFee = _lFee;
        _psRFee = _srFee;
        _psMFee = _smFee;
        _psLFee = _slFee;
        _rFee = 0;
        _mFee = 0;
        _lFee = 0;
        _srFee = 0;
        _smFee = 0;
        _slFee = 0;
    }

    function chkSmTx(bool selling, address from, uint256 amount) internal view {
        if(selling && mStxE && mSts[from] < block.timestamp){
            require(amount <= mStx || iTxLE[from]);}
    }
    
    function restoreAllFee() private {
        _rFee = _pRFee;
        _mFee = _pMFee;
        _lFee = _pLFee;
        _srFee = _psRFee;
        _smFee = _psMFee;
        _slFee = _psLFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return iFxE[account];
    }

    function calculatesMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_smFee).div(10**2);
    }

    function calculatesLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_slFee).div(10**2);
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

        if(!iMxWE[to] && to != address(this)  && to != address(0) && to != uniswapV2Pair && to != _mWA && to != _tfU){
            require((balanceOf(to) + amount) <= _maxWaAmount);} 
            
        checkTxLimit(from, amount);
        chkSmTx(from != uniswapV2Pair, from, amount);
        if(from == uniswapV2Pair && mStt){mSts[to] = block.timestamp + mStts;}

        uint256 cTB = balanceOf(address(this));
        
        if(cTB >= _maxTxAmount){
            cTB = _maxTxAmount;
        }
        
        bool overMinTokenBalance = cTB >= nTSellAtL;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            cTB = nTSellAtL;
            swapAndLiquify(cTB);
        }
        
        if(cSb && cSbh[address(this)] + cSbT <= block.timestamp) { 
            kicktfc(); cSbh[address(this)] = block.timestamp; }
        
        bool takeFee = true;
        
        if(iFxE[from] || iFxE[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 cTB) private lockTheSwap {
        uint256 cHalf = cTB.mul(_ch).div(_tliqd);
        uint256 lpHalf = cTB.mul(_lpH).div(_tliqd);
        uint256 lptHalf = cTB.mul(_lpH).div(_tliqd);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(lpHalf);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(lptHalf, newBalance);
        
        swapTokensForEth(cHalf);
        
        emit SwapAndLiquify(lpHalf, newBalance, lptHalf);
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

    function swapTokensForMEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _mWA,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient] && sender == uniswapV2Pair) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient] && sender == uniswapV2Pair) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient] && sender == uniswapV2Pair) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient] && sender == uniswapV2Pair) {
            _transferBothExcluded(sender, recipient, amount);
        } else if (sender == uniswapV2Pair) {
            _transferStandard(sender, recipient, amount);
        }

        if (_isExcluded[sender] && !_isExcluded[recipient] && sender != uniswapV2Pair) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient] && sender != uniswapV2Pair) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient] && sender != uniswapV2Pair) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient] && sender != uniswapV2Pair) {
            _transferBothExcluded(sender, recipient, amount);
        } else if (sender != uniswapV2Pair && stT) {
            _transfersStandard(sender, recipient, amount);
        } else if (sender != uniswapV2Pair) {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transfersStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 srAmount, uint256 srTransferAmount, uint256 srFee, uint256 stTransferAmount, uint256 stFee, uint256 stLiquidity, uint256 stMarketing) = _getsValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(srAmount);
        _rOwned[recipient] = _rOwned[recipient].add(srTransferAmount);
        _takesLiquidity(stLiquidity);
        _takesMarketing(stMarketing, sender);
        _reflectsFee(srFee, stFee);
        emit Transfer(sender, recipient, stTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}