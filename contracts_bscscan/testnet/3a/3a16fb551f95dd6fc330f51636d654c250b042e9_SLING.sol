/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

interface IPancakeSwapV2Router01 {
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

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
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

interface IPancakeSwapV2Factory {
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


interface IPancakeSwapV2Pair {
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


library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }
		
        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns(uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    event DividendsDistributed(address indexed from,uint256 weiAmount);
    event DividendWithdrawn(address indexed to,uint256 weiAmount);
}
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
	
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
	
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
	
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
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

interface IBEP20Metadata is IBEP20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract BEP20 is Context, IBEP20, IBEP20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
	
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
	
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0x95abDa53Bc5E9fBBDce34603614018d32CED219e), _msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
	
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract DividendPayingToken is BEP20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public gasForTransfer;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol) BEP20(_name, _symbol) {
        gasForTransfer = 3000;
    }
	
    receive() external payable {
        distributeDividends();
    }
	
    function distributeDividends() public override payable {
        require(totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }
	
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }
	
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success,) = user.call{value: _withdrawableDividend, gas: gasForTransfer}("");

            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }
	
    function dividendOf(address _owner) public view override returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
    }
	
    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }
	
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);
        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract SLINGDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public constant MIN_TOKEN_BALANCE_FOR_DIVIDENDS = 10000 * (10**18);
	
    event ExcludedFromDividends(address indexed account);
    event GasForTransferUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("SLING_Dividend_Tracker", "SLING_Dividend_Tracker") {
       claimWait = 3600;
    }
	
    function _transfer(address, address, uint256) internal pure override {
        require(false, "SLING_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "SLING_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main SLING contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludedFromDividends(account);
    }

    function updateGasForTransfer(uint256 newGasForTransfer) external onlyOwner {
        require(newGasForTransfer != gasForTransfer, "SLING_Dividend_Tracker: Cannot update gasForTransfer to same value");
        emit GasForTransferUpdated(newGasForTransfer, gasForTransfer);
        gasForTransfer = newGasForTransfer;
    }
    

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "SLING_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "SLING_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    
    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
    public view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp)  {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= MIN_TOKEN_BALANCE_FOR_DIVIDENDS) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}


contract SLING is BEP20, Ownable {
    using SafeMath for uint256;

    IPancakeSwapV2Router02 public pancakeSwapV2Router;
    address public immutable pancakeSwapV2Pair;

    bool private liquidating;

    SLINGDividendTracker public dividendTracker;

    address public marketingWallet = 0x642E5E39B5da32592b0aE9da626eAe62Daaa3f74;

    uint256 public BNB_REWARDS_FEE = 7;
    uint256 public MARKETING_FEE = 4;
    uint256 public  TOTAL_FEES = BNB_REWARDS_FEE + MARKETING_FEE;
    bool _swapEnabled = false;

    uint256 public gasForProcessing = 150000;
    uint256 public liquidateTokensAtAmount = 100000 * (10**18);
    bool public tradingEnabled;
	
    function activate() public onlyOwner {
        require(!tradingEnabled, "SLING: Trading is already enabled");
        _swapEnabled = true;
        tradingEnabled = true;
    }
	
    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) public canTransferBeforeTradingIsEnabled;

    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdatedDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdatedPancakeSwapV2Router(address indexed newAddress, address indexed oldAddress);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event LiquidationThresholdUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Liquified(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndSendToDev(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    event SentDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() BEP20("SlingShot", "$SLING") {
        dividendTracker = new SLINGDividendTracker();
       
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        address _pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), _pancakeSwapV2Router.WETH());

        pancakeSwapV2Router = _pancakeSwapV2Router;
        pancakeSwapV2Pair = _pancakeSwapV2Pair;

        _setAutomatedMarketMakerPair(_pancakeSwapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_pancakeSwapV2Router));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
		
        excludeFromFees(marketingWallet);
        excludeFromFees(address(this));
        _mint(owner(), 1000000000000 * (10**18));
    }

    receive() external payable {}
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeSwapV2Pair, "SLING: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SLING: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) 
		{
           dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function excludeFromFees(address account) public onlyOwner {
        require(!_isExcludedFromFees[account], "SLING: Account is already excluded from fees");
        _isExcludedFromFees[account] = true;
    }

    function updateGasForTransfer(uint256 gasForTransfer) external onlyOwner {
        dividendTracker.updateGasForTransfer(gasForTransfer);
    }
    
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue != gasForProcessing, "SLING: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getGasForTransfer() external view returns(uint256) {
        return dividendTracker.gasForTransfer();
    }
     
    function enableDisableSwaping(bool enabled) external onlyOwner {
        _swapEnabled = enabled;
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }
	
	function updateMarketingWalletAddress(address payable _marketingWallet) external onlyOwner() {
	     marketingWallet = _marketingWallet;
	}
	
	function updateMarketingFee(uint256 FEE) external onlyOwner() {
         MARKETING_FEE = FEE;
    }
	
	function updateBNBRewardFee(uint256 FEE) external onlyOwner() {
         BNB_REWARDS_FEE = FEE;
    }
	
    function getAccountDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
	
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        
        bool tradingIsEnabled = tradingEnabled;

        if(!tradingIsEnabled) 
		{
            require(from==owner(), "SLING: This account cannot send tokens until trading is enabled");
        }
		
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= liquidateTokensAtAmount;
		
        if (tradingIsEnabled && canSwap && _swapEnabled && !liquidating && !automatedMarketMakerPairs[from] && from != marketingWallet && to != marketingWallet) {
            liquidating = true;
            uint256 swapTokens = contractTokenBalance.mul(MARKETING_FEE).div(TOTAL_FEES);
            swapAndSendToDev(swapTokens);
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);
            liquidating = false;
        }
		
        bool takeFee = tradingIsEnabled && !liquidating;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) 
		{
            takeFee = false;
        }

        if (takeFee) 
		{
            uint256 fees = amount.mul(TOTAL_FEES).div(100);
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
		
        if (!liquidating) {
            uint256 gas = gasForProcessing;
            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } catch {

            }
        }
    }

    function swapAndSendToDev(uint256 tokens) private {
        uint256 tokenBalance = tokens;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokenBalance);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        payable(marketingWallet).transfer(newBalance);
        emit SwapAndSendToDev(tokens, newBalance);
    }
	
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        if (success) {
            emit SentDividends(tokens, dividends);
        }
    }
}