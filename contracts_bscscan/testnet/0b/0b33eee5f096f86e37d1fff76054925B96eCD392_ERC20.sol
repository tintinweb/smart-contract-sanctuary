/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// File: contracts/BEP20.sol



pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "zero address");
        require(recipient != address(0), "zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "zero address");
        require(spender != address(0), "zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));

        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
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

interface IDividendPayingToken {
    function dividendOf(address _owner) external view returns(uint256);
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
    event DividendsDistributed(address indexed from, uint256 amount);
    event DividendWithdrawn(address indexed to, uint256 amount);
    event DividendClaimedToAnyToken(address indexed to, address wantToken, uint256 amount);
}

contract DividendPayingToken is ERC20, IDividendPayingToken {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    IDEXRouter public dexRouter;

    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;

    address public adminAddress = 0x7EEAaD9C49c5422Ea6B65665146187A66F22c48E;
    address internal onlyCaller;

    address public dividendToken;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => uint256) public shibelonRewardRemains;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
        dividendToken = _token;
        IDEXRouter _dexRouter = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        dexRouter = _dexRouter;

        IERC20(dividendToken).approve(address(dexRouter), 2**256 - 1);
    }

    receive() external payable {
    }

    function distributeDividends(uint256 amount) public {
        require(msg.sender == onlyCaller || msg.sender == adminAddress, "Only caller");
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function setOnlyCaller(address _newCaller) external virtual {
        require(msg.sender == adminAddress, "Only admin");
        onlyCaller = _newCaller;
    }

    function transferAdmin(address _newAdmin) external virtual {
        require(msg.sender == adminAddress, "Only admin");
        adminAddress = _newAdmin;
    }

    function retrieveTokens(address token) external virtual {
        require(msg.sender == adminAddress, "Only admin");

        uint256 amount = IERC20(token).balanceOf(address(this));

        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB() external virtual {
        require(msg.sender == adminAddress, "Only admin");

        uint256 amount = address(this).balance;

        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);

            bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }else{
                emit DividendWithdrawn(user, _withdrawableDividend);
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function _claimDividendOfUserToAnyToken(address payable user, address _wantToken) internal returns (uint256) {
        require(_wantToken != dividendToken, "Error: wantToken == dividendToken");
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);

            uint256 beforeAmount = ERC20(_wantToken).balanceOf(address(this));
            _swapDividendTokenToAnyToken(_withdrawableDividend, dividendToken, _wantToken);
            uint256 afterAmount = ERC20(_wantToken).balanceOf(address(this));

            bool swapped = afterAmount > beforeAmount;

            if(!swapped) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }else{
                shibelonRewardRemains[user] = shibelonRewardRemains[user].add( afterAmount.sub(beforeAmount) );

                bool success = IERC20(_wantToken).transfer(user, shibelonRewardRemains[user]);

                if(!success) {
                    return 0;
                }else{
                    shibelonRewardRemains[user] = 0;
                    emit DividendClaimedToAnyToken(user, _wantToken, _withdrawableDividend);
                }
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function _swapDividendTokenToAnyToken(uint256 _tokenAmount, address _dividendAddress, address _wantToken) private {
        address[] memory path;

        if(dexRouter.WETH() == _dividendAddress){
            path = new address[](2);
            path[0] = _dividendAddress;
            path[1] = _wantToken;
        }else{
            path = new address[](3);
            path[0] = _dividendAddress;
            path[1] = dexRouter.WETH();
            path[2] = _wantToken;
        }

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
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

    function _transfer(address, address, uint256) internal virtual override {
        require(false, "No allowed");
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

contract BusdDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    uint256 public minimumTokenBalanceForDividends;

    mapping (address => bool) public excludedFromDividends;

    constructor() DividendPayingToken("SHIBELON_BUSD_Dividend_Tracker", "SHIBELON_BUSD_Dividend_Tracker", 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) {
        minimumTokenBalanceForDividends = 1 * (10**18); //must hold 1+ tokens
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        minimumTokenBalanceForDividends = _newMinimumBalance;
    }

    function excludeFromDividends(address account, bool status) external onlyOwner {
        require(excludedFromDividends[account] != status, "Same value");

        excludedFromDividends[account] = status;

        if(status == true){
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }else{
            uint256 balance = IERC20(address(owner())).balanceOf(account);
            _setBalance(account, balance);
            tokenHoldersMap.set(account, balance);
        }

        emit ExcludeFromDividends(account, status);
    }

    function setBalance(address payable account, uint256 newBalance) internal {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
    }

    function set2Balances(address payable sender, address payable recipient, uint256 balanceSender, uint256 balancesRecipient) external onlyOwner{
        setBalance(sender, balanceSender);
        setBalance(recipient, balancesRecipient);
    }

    function claimDividend(address payable account) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            emit Claim(account, amount);
            return true;
        }

        return false;
    }

    function compoundDividend(address payable account, address wantToken) public onlyOwner returns (bool) {
        uint256 amount = _claimDividendOfUserToAnyToken(account, wantToken);

        if(amount > 0) {
            emit Compound(account, amount);
            return true;
        }

        return false;
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "No allowed");
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    event ExcludeFromDividends(address indexed account, bool status);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount);
}

contract ShibelonV2 is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MAX_FEE_RATE = 1000;
    uint256 public constant MAX_SUPPLY = 18435888 * 10 ** 18;

    bool private swapping;

    bool public isNotMigrating = true;
    bool public feesOnNormalTransfers = true;

    IDEXRouter public dexRouter;
    address dexPair;
    address dexPairBusd;

    address burnAddress = 0x0000000000000000000000000000000000000000;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public marketingWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public treasuryWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address public busdDividendToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    BusdDividendTracker public busdDividendTracker;

    uint256 public liquidityFee = 150;
    uint256 public toBurnTokenFee = 100;
    uint256 public busdDividendRewardsFee = 300;
    uint256 public marketingFee = 150;
    uint256 public treasuryFee = 300;

    uint256 public sellFeeIncreaseFactor = 250;

    uint256 public totalTreasuryAmount = 0;
    uint256 public totalFees = 0;

    uint256 public maxBuyTransactionAmount = 18435888 * 10 ** 18;
    uint256 public maxSellTransactionAmount = 50000 * 10 ** 18;
    uint256 public swapTokensAtAmount = 2000 * 10 ** 18;
    uint256 public maxWalletToken = 18435888 * 10 ** 18;

    bool public isLiquidityInBnb = true;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    constructor() ERC20("Shibelon V2 (Shibelon Multi-chain Venture Capital)", "SHIBELON") {
        busdDividendTracker = new BusdDividendTracker();

        IDEXRouter _dexRouter = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        address _dexPair = IDEXFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        address _dexPairBusd = IDEXFactory(_dexRouter.factory()).createPair(address(this), busdDividendToken);

        dexRouter = _dexRouter;
        dexPair = _dexPair;
        dexPairBusd = _dexPairBusd;

        _setAutomatedMarketMakerPair(_dexPair, true);
        _setAutomatedMarketMakerPair(_dexPairBusd, true);

        excludeFromDividend(address(busdDividendTracker), true);
        excludeFromDividend(address(this), true);
        excludeFromDividend(address(_dexRouter), true);
        excludeFromDividend(deadAddress, true);

        excludeFromFees(address(busdDividendTracker), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(treasuryWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        _mint(owner(), MAX_SUPPLY);

        _approve(address(this), address(dexRouter), MAX_SUPPLY);
        approve(address(dexRouter), MAX_SUPPLY);
        approve(address(dexPair), MAX_SUPPLY);
        approve(address(dexPairBusd), MAX_SUPPLY);

        IERC20(busdDividendToken).approve(address(dexRouter), 2**256 - 1);

        _updateTotalFee();
    }

    receive() external payable {
    }

    function prepareForPartner(address _partnerOrExchangeAddress) external onlyOwner {
        busdDividendTracker.excludeFromDividends(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn;
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn;
    }

    function setBusdDividendToken(address _newContract) external onlyOwner {
        busdDividendToken = _newContract;
        IERC20(busdDividendToken).approve(address(dexRouter), 2**256 - 1);
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        marketingWallet = _newWallet;
    }

    function setTreasuryWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        treasuryWallet = _newWallet;
    }

    function setToBurnTokenFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        toBurnTokenFee = newFee;
        _updateTotalFee();
    }

    function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
        maxWalletToken = _maxToken;
    }

    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount;
    }

    function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner {
        sellFeeIncreaseFactor = _multiplier;
    }

    function setIsNotMigrating(bool _value) external onlyOwner {
        require(isNotMigrating != _value, "Not changed");
        isNotMigrating = _value;
    }

    function setIsLiquidityInBnb(bool _value) external onlyOwner {
        require(isLiquidityInBnb != _value, "Not changed");
        isLiquidityInBnb = _value;
    }

    function setBusdDividendTracker(address newAddress) external onlyOwner {
        BusdDividendTracker newBusdDividendTracker = BusdDividendTracker(payable(newAddress));

        require(newBusdDividendTracker.owner() == address(this), "must be owned by Shibelon");

        newBusdDividendTracker.excludeFromDividends(address(newBusdDividendTracker), true);
        newBusdDividendTracker.excludeFromDividends(address(this), true);
        newBusdDividendTracker.excludeFromDividends(address(dexRouter), true);
        newBusdDividendTracker.excludeFromDividends(address(dexPair), true);
        newBusdDividendTracker.excludeFromDividends(address(dexPairBusd), true);
        newBusdDividendTracker.excludeFromDividends(address(deadAddress), true);

        busdDividendTracker = newBusdDividendTracker;
    }

    function setBusdDividendRewardFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        busdDividendRewardsFee = newFee;
        _updateTotalFee();
    }

    function setMarketingFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        marketingFee = newFee;
        _updateTotalFee();
    }

    function setTreasuryFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        treasuryFee = newFee;
        _updateTotalFee();
    }

    function setLiquidityFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        liquidityFee = newFee;
        _updateTotalFee();
    }

    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        feesOnNormalTransfers = _enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != dexPair, "cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            busdDividendTracker.excludeFromDividends(pair, value);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        busdDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function excludeFromDividend(address account, bool status) public onlyOwner {
        busdDividendTracker.excludeFromDividends(address(account), status);
    }

    function claim() external nonReentrant {
        busdDividendTracker.claimDividend(payable(msg.sender));
    }

    function compound() external nonReentrant {
        busdDividendTracker.compoundDividend(payable(msg.sender), address(this));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Already excluded");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function retrieveTokens(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));

        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function _updateTotalFee() internal {
        totalFees = liquidityFee
        .add(marketingFee)
        .add(treasuryFee)
        .add(busdDividendRewardsFee)
        .add(toBurnTokenFee);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "zero address");
        require(to != address(0), "zero address");

        require(isNotMigrating || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading not started");

        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (
            isNotMigrating &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(amount <= maxBuyTransactionAmount, "Error amount");

            uint256 contractBalanceRecipient = balanceOf(to);
            require(contractBalanceRecipient + amount <= maxWalletToken, "Error amount");
        } else if (
            isNotMigrating &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Error amount");

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!swapping && contractTokenBalance >= swapTokensAtAmount) {
                swapping = true;

                if (marketingFee > 0) {
                    uint256 swapTokens = contractTokenBalance.mul(marketingFee).div(totalFees);

                    uint256 beforeAmount = address(this).balance;
                    _swapTokensForBNB(swapTokens);
                    uint256 increaseAmount = address(this).balance.sub(beforeAmount);

                    if(increaseAmount > 0){
                        _transferToWallet(payable(marketingWallet), increaseAmount);
                    }
                }

                if(treasuryFee > 0){
                    uint256 swapTokens = contractTokenBalance.mul(treasuryFee).div(totalFees);

                    uint256 beforeAmount = address(this).balance;
                    _swapTokensForBNB(swapTokens);
                    uint256 increaseAmount = address(this).balance.sub(beforeAmount);

                    if(increaseAmount > 0){
                        _transferToWallet(payable(treasuryWallet), increaseAmount);
                        totalTreasuryAmount = totalTreasuryAmount.add(increaseAmount);
                    }
                }

                if(liquidityFee > 0){
                    _swapAndLiquify(contractTokenBalance.mul(liquidityFee).div(totalFees));
                }

                if (busdDividendRewardsFee > 0) {
                    uint256 sellTokens = contractTokenBalance.mul(busdDividendRewardsFee).div(totalFees);
                    _swapAndSendBusdDividends(sellTokens);
                }

                if(toBurnTokenFee > 0){
                    uint256 tokensToBurn = contractTokenBalance.mul(toBurnTokenFee).div(totalFees);
                    _burn(address(this), tokensToBurn);
                    emit Transfer(address(this), burnAddress, tokensToBurn);
                }

                swapping = false;
            }
        }

        if(isNotMigrating && !swapping && !excludedAccount) {
            uint256 fees = amount.mul(totalFees).div(10000);

            // if sell, multiply by sellFeeIncreaseFactor
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }else if(!automatedMarketMakerPairs[from] && !feesOnNormalTransfers){
                fees = 0;
            }

            if(fees > 0){
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

        try busdDividendTracker.set2Balances(
            payable(from),
            payable(to),
            balanceOf(from),
            balanceOf(to)
        ) {

        } catch Error (string memory reason) {
            emit GenericErrorEvent("_transfer(): busdDividendTracker.set2Balances() Failed");
            emit GenericErrorEvent(reason);
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        if(isLiquidityInBnb){
            uint256 initialBalance = address(this).balance;

            _swapTokensForBNB(half);

            uint256 newBalance = address(this).balance.sub(initialBalance);

            _addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }else{
            uint256 initialBalance = IERC20(busdDividendToken).balanceOf(address(this));

            _swapTokensForBusd(half);

            uint256 newBalance = IERC20(busdDividendToken).balanceOf(address(this)).sub(initialBalance);

            _addLiquidityBusd(otherHalf, newBalance);

            emit SwapAndLiquifyBusd(half, newBalance, otherHalf);
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        dexRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            treasuryWallet,
            block.timestamp
        );
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidityBusd(uint256 tokenAmount, uint256 busdAmount) private {
        dexRouter.addLiquidity(
            address(this),
            busdDividendToken,
            tokenAmount,
            busdAmount,
            0,
            0,
            treasuryWallet,
            block.timestamp
        );
    }

    function _swapTokensForBusd(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        path[2] = busdDividendToken;

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path;

        if(dexRouter.WETH() == _dividendAddress){
            path = new address[](2);
            path[0] = address(this);
            path[1] = _dividendAddress;
        }else{
            path = new address[](3);
            path[0] = address(this);
            path[1] = dexRouter.WETH();
            path[2] = _dividendAddress;
        }

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _recipient,
            block.timestamp
        );
    }

    function _swapAndSendBusdDividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(busdDividendToken).balanceOf(address(busdDividendTracker));

        _swapTokensForDividendToken(tokens, address(busdDividendTracker), busdDividendToken);

        uint256 busdDividends = IERC20(busdDividendToken).balanceOf(address(busdDividendTracker)).sub(beforeAmount);

        if(busdDividends > 0){
            busdDividendTracker.distributeDividends(busdDividends);
            emit SendBusdDividends(busdDividends);
        }
    }

    function _transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyBusd(uint256 tokensSwapped, uint256 busdReceived, uint256 tokensIntoLiqudity);
    event SendBusdDividends(uint256 amount);
    event GenericErrorEvent(string reason);
}