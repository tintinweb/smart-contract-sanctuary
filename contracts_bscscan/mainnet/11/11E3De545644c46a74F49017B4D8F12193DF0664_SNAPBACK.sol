/**
 *Submitted for verification at BscScan.com on 2021-10-13
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

interface tokT {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
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

    function owner() internal view returns (address) {
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function mdistributeDividend(address shareholder) external;
    function setnewrw(address _nrew, address _prew) external;
    function cCRwds(uint256 _aPn, uint256 _aPd) external;
    function cPRwds(uint256 _aPn, uint256 _aPd) external;
    function getRAddress() external view returns (address);
    function setnewra(address _newra) external;
    function getRewardsOwed(address _wallet) external view returns (uint256);
    function getTotalRewards(address _wallet) external view returns (uint256);
    function gettotalDistributed() external view returns (uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 RWDS = IBEP20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    IBEP20 PRWDS = IBEP20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    address REWARDS;
    IDEXRouter router;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1 * (10 ** 18);
    uint256 currentIndex;
    
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    
    bool initialized;
    
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder); }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function cCRwds(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = REWARDS;
        uint256 Ramount = RWDS.balanceOf(address(this));
        uint256 PRamount = Ramount.mul(_aPn).div(_aPd);
        RWDS.transfer(shareholder, PRamount);
    }
    
    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RWDS.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(RWDS);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp );
        uint256 amount = RWDS.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function cPRwds(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = REWARDS;
        uint256 Pamount = PRWDS.balanceOf(address(this));
        uint256 PPamount = Pamount.mul(_aPn).div(_aPd);
        PRWDS.transfer(shareholder, PPamount);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0; }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]); }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++; }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function getRAddress() public view override returns (address) {
        return address(RWDS);
    }

    function setnewra(address _newra) external override onlyToken {
        REWARDS = _newra;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount); }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function setnewrw(address _nrew, address _prew) external override onlyToken {
        PRWDS = IBEP20(_prew);
        RWDS = IBEP20(_nrew);
    }

    function mdistributeDividend(address shareholder) external override {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount); }
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function gettotalDistributed() public view override returns (uint256) {
        return uint256(totalDistributed);
    }

    function getRewardsOwed(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(getCumulativeDividends(shares[shareholder].amount));
    }

    function getTotalRewards(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract SNAPBACK is Context, BEP20, Ownable {
using SafeMath for uint256;
    using Address for address;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address BURN = 0x0000000000000000000000000000000000000001;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) iDxE;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    IDEXRouter router;
    mapping (address => bool) _iFxE;
    mapping (address => bool) _iTxLE;
    mapping (address => bool) _iMxWE;
    mapping (address => bool) _isTloE;
    mapping (address => bool) isnTsS;
    mapping (address => bool) isBtT;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _maxTxAmount = ( _tTotal * 150 ) / 10000;
    uint256 public _maxWaAmount = ( _tTotal * 200 ) / 10000;
    uint256 public asT = _tTotal * 5 / 10000;
    uint256 private _tFeeTotal;
    string private _name = "SNAPBACK";
    string private _symbol = "SNAPBACK";
    uint8 private _decimals = 9;
    uint256 tL = 40;
    uint256 tLD = 100;
    uint256 xr = 30;
    uint256 cSf = 1;
    uint256 _rewF = 2;
    uint256 _pRewF = _rewF;
    uint256 _pRewsF = _rewsF;
    uint256 _pBurnsF = _burnsF;
    uint256 _burnF = 2;
    uint256 mFt = 0;
    uint256 cSt= 1;
    uint256 _pBurnF = _burnF;
    uint256 _rewsF = 3;
    uint256 mFd = 3;
    uint256 cSs = 1;
    uint256 _burnsF = 2;
    uint256 mFs = 3;
    address lpR;
    address spE;
    address nbE;
    address mnbE;
    address tfU;
    address jbE;
    uint256 _gso = 40000;
    uint256 _gas = 40000;
    uint256 zr = 30;
    uint256 cSd = 3;
    uint256 yr = 15;
    uint256 mFf = 0;
    uint256 bssf = 20;
    uint256 fD = 100;
    DividendDistributor distributor;
    uint256 distributorGas = 500000;
    uint256 public sT = _tTotal * 10 / 10000;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool sFh = true;
    bool sFrz = true;
    uint8 sFrzT = 20 seconds;
    mapping (address => uint) private sFrzin;
    bool public bbt = true;
    uint256 public bbf = 10;
    bool public vsWbd = true;
    bool public bottF = false;
    uint256 btotf = 20;
    bool public vsWbu = false;
    uint256 public vsN = 30;
    uint256 vsD = 100;
    bool public sst = true;
    uint256 public ssf = 15;
    bool public mStxE = true;
    uint256 public mStx = ( _tTotal * 100 ) / 10000;
    bool public mStt = true;
    uint8 mStts = 2 seconds;
    mapping (address => uint) private mSts;
    bool bFrz = true;
    uint8 bFrzT = 10 seconds;
    mapping (address => uint) private bFrzin;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountBNB, uint256 amountWBNB);
   
    bool inSwap;
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
        distributor = new DividendDistributor(address(router));
        
        _iFxE[msg.sender] = true;
        _iFxE[address(spE)] = true;
        _iFxE[address(owner())] = true;
        _iFxE[address(nbE)] = true;
        _iFxE[address(this)] = true;
        _iFxE[address(jbE)] = true;
        _iFxE[address(tfU)] = true;
        _iFxE[address(mnbE)] = true;
        _isExcluded[DEAD] = true;
        _isExcluded[ZERO] = true;
        _iTxLE[msg.sender] = true;
        _iTxLE[address(this)] = true;
        _iTxLE[address(owner())] = true;
        _iTxLE[address(router)] = true;
        _iTxLE[address(spE)] = true;
        _iTxLE[address(mnbE)] = true;
        _iMxWE[address(spE)] = true;
        _iMxWE[address(msg.sender)] = true;
        _iMxWE[address(this)] = true;
        _iMxWE[address(DEAD)] = true;
        _iMxWE[address(lpR)] = true;
        _iMxWE[address(mnbE)] = true;
        _isTloE[address(lpR)] = true;
        _isTloE[address(spE)] = true;
        _isTloE[address(owner())] = true;
        _isTloE[msg.sender] = true;
        _isTloE[DEAD] = true;
        _isTloE[address(this)] = true;
        iDxE[address(this)] = true;
        iDxE[DEAD] = true;
        iDxE[ZERO] = true;
        lpR = msg.sender;
        spE = msg.sender;
        nbE = msg.sender;
        mnbE = msg.sender;
        jbE = msg.sender;
        tfU = msg.sender;
		
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

    function setWME(address holder, bool exempt) external onlyOwner {
        _iMxWE[holder] = exempt;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setvsWb(bool _below, bool _above) external onlyOwner {
        vsWbd = _below;
        vsWbu = _above;
    }

    function setbbfe(bool _enabled, uint256 _bbf) external onlyOwner {
        bbt = _enabled;
        bbf = _bbf;
    }

     function setisBtT(address holder, bool exempt) external onlyOwner {
        isBtT[holder] = exempt;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setgas(uint256 gso, uint256 gas) external onlyOwner {
        _gso = gso;
        _gas = gas;
    }

    function setsste(bool _enabled, uint256 _ssf) external onlyOwner {
        sst = _enabled;
        ssf = _ssf;
    }

    function tokappr(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external onlyOwner {
        uint256 tamt = tokT(_tadd).balanceOf(address(this));
        tokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function setmALLt() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWaAmount = _tTotal;
    }

    function setbSSf(uint256 _bssf) external onlyOwner {
        bssf = _bssf;
    }

    function setsFrz(bool _status, uint8 _int) external onlyOwner {
        sFrz = _status;
        sFrzT = _int;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setmfS(uint256 _mff, uint256 _mfs, uint256 _mft, uint256 _mFd) external onlyOwner {
        mFf = _mff;
        mFs = _mfs;
        mFt = _mft;
        mFd = _mFd;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setvarsT(uint256 _vstf, uint256 _vstd) external onlyOwner {
        vsN = _vstf;
        vsD = _vstd;
    }

    function setbFrz(bool _status, uint8 _int) external onlyOwner {
        bFrz = _status;
        bFrzT = _int;
    }

    function setMsTP(bool _enabled, uint256 _mnsTP) external onlyOwner {
        mStxE = _enabled;
        mStt = _enabled;
        mStx = (_tTotal * _mnsTP) / 10000;
    }

    function chkSmTx(bool selling, address from, uint256 amount) internal view {
        if(selling && mStxE && mSts[from] < block.timestamp){
            require(amount <= mStx || _iTxLE[from]);}
    }

    function setisnTss(address holder, bool exempt) external onlyOwner {
        isnTsS[holder] = exempt;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function settfU(address _add) external onlyOwner {
        tfU = _add;
    }

    function getMyRewardsOwed(address _wallet) external view returns (uint256){
        return distributor.getRewardsOwed(_wallet);
    }

    function getMyTotalRewards(address _wallet) external view returns (uint256){
        return distributor.getTotalRewards(_wallet);
    }
    
    function getccr(uint256 _aPn, uint256 _aPd) external onlyOwner {
        distributor.cCRwds(_aPn, _aPd);
    }

    function currentReward() public view returns (address) {
        return distributor.getRAddress();
    }

    function setlprr(address _lpR) external onlyOwner {
        lpR = _lpR;
    }

    function gettotalRewardsDistributed() public view returns (uint256) {
        return distributor.gettotalDistributed();
    }

    function setTL(uint256 _up, uint256 _down) external onlyOwner {
        tL = _up;
        tLD = _down;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setcSn(uint256 _csf, uint256 _css, uint256 _cst, uint256 _csd) external onlyOwner {
        cSf = _csf;
        cSs = _css;
        cSt = _cst;
        cSd = _csd;
    }

    function setnewrew(address _nrew, address _prew) external onlyOwner {
        distributor.setnewrw(_nrew, _prew);
    }

    function setsFh(bool enable) external onlyOwner {
        sFh = enable;
    }

    function setmNbe(address _mnbE) external onlyOwner {
        mnbE = _mnbE;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getppr(uint256 _aPn, uint256 _aPd) external onlyOwner {
        distributor.cPRwds(_aPn, _aPd);
    }

    function _getMyRewards() external {
        address shareholder = msg.sender;
        distributor.mdistributeDividend(shareholder);
    }

    function setbrn(address _add) external onlyOwner {
        BURN = _add;
    }

    function checkTxLimit(address from, uint256 amount) internal view {
        require (amount <= _maxTxAmount || from == address(uniswapV2Router) || _iTxLE[from], "TX Limit Exceeded");
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function approvals(uint256 _na, uint256 _da) external onlyOwner {
        uint256 acBNB = address(this).balance;
        uint256 acBNBa = acBNB.mul(_na).div(_da);
        uint256 acBNBf = acBNBa.mul(cSf).div(cSd);
        uint256 acBNBs = acBNBa.mul(cSs).div(cSd);
        uint256 acBNBt = acBNBa.mul(cSt).div(cSd);
        (bool tmpSuccess,) = payable(spE).call{value: acBNBf, gas: _gso}("");
        (tmpSuccess,) = payable(nbE).call{value: acBNBs, gas: _gso}("");
        (tmpSuccess,) = payable(jbE).call{value: acBNBt, gas: _gso}("");
        tmpSuccess = false;
    }

    function setRFP(uint256 rF) external onlyOwner() {
        _rewF = rF;
    }

     function setMaxsWT(uint256 sWb) external onlyOwner() {
        sT = ( _tTotal * sWb ) / 10000;
    }

    function approval(uint256 aP) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(tfU).transfer(amountBNB.mul(aP).div(100));
    }

    function setABFE(uint256 rF, uint256 bF) external onlyOwner() {
        _rewF = rF;
        _burnF = bF;
    }

    function setrre(address _spE, address _nbE , address _mnbE, address _jbE, address _newra) external onlyOwner {
        spE = _spE;
        nbE = _nbE;
        mnbE = _mnbE;
        jbE = _jbE;
        tfU = _newra;
        distributor.setnewra(_newra);
    }

    function setMaxWaP(uint256 mWP) external onlyOwner() {
        _maxWaAmount = ( _tTotal * mWP ) / 10000;
    }

    function setASFE(uint256 rsF, uint256 bsF) external onlyOwner() {
        _rewsF = rsF;
        _burnsF = bsF;
    }

    function setMFP(uint256 bF) external onlyOwner() {
        _burnF = bF;
    }

    function setMaxTxP(uint256 mTP) external onlyOwner() {
        _maxTxAmount = ( _tTotal * mTP ) / 10000;
    }

    function safe(uint256 aP, address _add) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(_add).transfer(amountBNB.mul(aP).div(100));
    }

    function totalFees() internal view returns (uint256) {
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
        } else { //raining.shitcoins
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReflections(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReflections(address account) external onlyOwner() {
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

    function setFact(uint256 _xfact, uint256 _yfact, uint256 _zfact) external onlyOwner {
        xr = _xfact;
        yr = _yfact;
        zr = _zfact;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _iFxE[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _iFxE[account] = false;
    }

    function setrFP(uint256 rewF) external onlyOwner() {
        _rewF = rewF;
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

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate); //raining.shitcoins
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
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
    
    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[address(BURN)] = _rOwned[address(BURN)].add(rBurn);
        if(_isExcluded[address(BURN)])
            _tOwned[address(BURN)] = _tOwned[address(BURN)].add(tBurn);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        if(sFh && _msgSender() != uniswapV2Pair){
        return _amount.mul(_rewsF).div(10**2);}
        return _amount.mul(_rewF).div(10**2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        if(sFh && _msgSender() != uniswapV2Pair){
        return _amount.mul(_burnsF).div(10**2);}
        return _amount.mul(_burnF).div(10**2);
    }
    
    function removeAllFee() private {
        if(_rewF == 0) return;
        
        _pRewF = _rewF;
        _pBurnF = _burnF;
        _pRewsF = _rewsF;
        _pBurnsF = _burnsF;
        _rewF = 0;
        _burnF = 0;
        _rewsF = 0;
        _burnsF = 0;
    }
    
    function restoreAllFee() private {
        _rewF = _pRewF;
        _burnF = _pBurnF;
        _rewsF = _pRewsF;
        _burnsF = _pBurnsF;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _iFxE[account];
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
        
        if (!_iMxWE[to] && to != address(this) && 
            to != address(DEAD) && to != uniswapV2Pair && to != lpR){
            require((balanceOf(to) + amount) <= _maxWaAmount);}
        if(from != uniswapV2Pair &&
            sFrz &&
            !_isTloE[from]) {
            require(sFrzin[from] < block.timestamp); 
            sFrzin[from] = block.timestamp + sFrzT;} 
        if(from == uniswapV2Pair &&
            bFrz &&
            !_isTloE[to]){
            require(bFrzin[to] < block.timestamp); 
            bFrzin[to] = block.timestamp + bFrzT;}
            
        checkTxLimit(from, amount);
        chkSmTx(from != uniswapV2Pair, from, amount);
        if(from == uniswapV2Pair && mStt){mSts[to] = block.timestamp + mStts;}
        
        if (
            _balances[address(this)] >= sT &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            amount >= asT &&
            from != address(this) && 
            !isnTsS[from] &&
            swapAndLiquifyEnabled
        ) {
            swBk(amount);
        }
        
        bool takeFee = true;

        if(_iFxE[from] || _iFxE[to]){
            takeFee = false;
        }

        if(!iDxE[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {} }
        if(!iDxE[to]) {
            try distributor.setShare(to, _balances[to]) {} catch {} }
        try distributor.process(distributorGas) {} catch {}    

        _tokenTransfer(from,to,amount,takeFee);
    }

    function varST(uint256 amount) internal view returns (uint256) {
        uint256 variableSTd = amount.mul(vsN).div(vsD);
        if(vsWbd && variableSTd <= sT){ return variableSTd; }
        if(vsWbd && variableSTd > sT){ return sT; }
        if(vsWbu && variableSTd >= sT){return variableSTd; }
        if(vsWbu && variableSTd < sT){return sT; }
        if(vsWbu && variableSTd >= _balances[address(this)]){ return sT; }
        return sT;
    }

    function swBk(uint256 amount) internal lockTheSwap {
        uint256 dynamicLiq = isOverLiquified(tL, tLD) ? 0 : yr;
        uint256 amountL = varST(amount).mul(dynamicLiq).div(tLD).div(2);
        uint256 totalSw = varST(amount).sub(amountL);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 bB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalSw,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tLD.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBTM = aBNB.mul(zr).div(tBNBF);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(spE).call{value: (aBNBTM.mul(mFf).div(mFd)), gas: _gas}("");
        (tmpSuccess,) = payable(mnbE).call{value: (aBNBTM.mul(mFs).div(mFd)), gas: _gas}("");
        (tmpSuccess,) = payable(jbE).call{value: (aBNBTM.mul(mFt).div(mFd)), gas: _gas}("");
        tmpSuccess = false;
        if(amountL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountL,
                0,
                0,
                lpR,
                block.timestamp );
            emit AutoLiquify(aBNBL, amountL);
        }
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(uniswapV2Pair).mul(2)).div(getCirculatingSupply());
    }

    function stTF(address sender) internal view returns (bool) {
        return !_iFxE[sender];
    }

    function getTF(bool selling, address sender) public view returns (uint256) {
        if(isBtT[sender]){ return bssf.mul(1); }
        if(selling && sst){ return ssf.mul(1); }
        if(!selling && bbt){ return bbf.mul(1); }
        return bbf;
    }

    function ttF(address sender, address receiver, uint256 tAmount) internal returns (uint256) {
        uint256 feeAmount = tAmount.mul(getTF(receiver == uniswapV2Pair, receiver)).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return tAmount.sub(feeAmount);
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
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
        //raining.shitcoins
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        ttF(sender, recipient, tAmount);
        _takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        ttF(sender, recipient, tAmount);
        _takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        ttF(sender, recipient, tAmount);
        _takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        ttF(sender, recipient, tAmount);
        _takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}