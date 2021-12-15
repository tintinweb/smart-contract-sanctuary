/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT

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

interface IDividendPayingToken {
    function dividendOf(address _owner) external view returns(uint256);
    function withdrawDividend() external;
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

contract DividendPayingToken is ERC20, IDividendPayingToken {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;

    address public adminAddress = 0x9050B927006A9c86B7D1539452f1b439e522ed32;
    address internal onlyCaller;

    address public dividendToken;
    uint256 public minTokenBeforeSendDividend = 0;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
        dividendToken = _token;
    }

    receive() external payable {
    }

    function distributeDividends(uint256 amount) public {
        require(msg.sender == onlyCaller, "Only caller");
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function setOnlyCaller(address _newCaller) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        onlyCaller = _newCaller;
    }

    function setDividendTokenAddress(address newToken) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        dividendToken = newToken;
    }

    function setMinTokenBeforeSendDividend(uint256 newAmount) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        minTokenBeforeSendDividend = newAmount;
    }

    function retrieveTokens(address token, uint amount) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB(uint amount) external virtual {
        require(tx.origin == adminAddress, "Only admin");
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > minTokenBeforeSendDividend) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

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

contract TimoDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    constructor() DividendPayingToken("LOL_TIMO_Dividend_TrackerTEST", "LOL_TIMO_Dividend_TrackerTEST", 0xDDa7e91b748e43dBEA65bb523e16BF60724E05e2) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
    }

    function setDividendTokenAddress(address newToken) external override onlyOwner {
        dividendToken = newToken;
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        minimumTokenBalanceForDividends = _newMinimumBalance;
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "wrong");
        claimWait = newClaimWait;
    }

    function setBalance(address payable account, uint256 newBalance, bool isProcess) external onlyOwner {
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

        if(isProcess){
            processAccount(account, true);
        }
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(_canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "No allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "disabled");
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

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
        lastClaimTime.add(claimWait) :
        0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
        nextClaimTime.sub(block.timestamp) :
        0;
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
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function _canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    event ExcludeFromDividends(address indexed account);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
}

contract LolToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_FEE_RATE = 2500;

    bool private swapping;
    bool public tradingIsEnabled = false;

    bool public sendTimoInTx = false;
    bool public feesOnNormalTransfers = false;

    IDEXRouter public dexRouter;
    address dexPair;

    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public teamWallet = 0x42Da8ac95E2dB63400A2ed3c43Ef085Da30BC722;
    address public marketingWallet = 0xf1100398c282C3ed10671A2E0A05A9D80c6699DB;

    address public timoDividendToken = 0xDDa7e91b748e43dBEA65bb523e16BF60724E05e2;
    TimoDividendTracker public timoDividendTracker;

    address public wbnbReflectToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public wbnbReflectTracker = 0x69598137c32Bcdc83B847716a602f5252eaa862b;
    address public toBurnAllianceToken = 0xDDa7e91b748e43dBEA65bb523e16BF60724E05e2;
    address public gameTreasury = 0x4E433252C25bc01982805e533903B1624bAdA38e;

    uint256 public buyBackFee = 0;
    uint256 public liquidityFee = 0;
    uint256 public toBurnAllianceFee = 0;

    uint256 public toBurnTokenFee = 25;
    uint256 public wbnbReflectRewardsFee = 125;
    uint256 public timoDividendRewardsFee = 75;
    uint256 public marketingFee = 250;
    uint256 public gameTreasuryFee = 25;

    uint256 public sellFeeIncreaseFactor = 300;
    uint256 public gasForProcessing = 1000000;

    uint256 public totalFees;

    uint256 public maxBuyTransactionAmount = 1000000 * 10 ** 18;
    uint256 public maxSellTransactionAmount = 100000 * 10 ** 18;
    uint256 public swapTokensAtAmount = 50000 * 10 ** 18;
    uint256 public maxWalletToken = 1000000000 * 10 ** 18;

    uint256 public minBNBAfterBuyback = 1 * 10 ** 18;   //1 BNB
    uint256 public minSellToTriggerBuyback = 1000 * 10 ** 18;
    uint256 public buybackUpperLimitBNB = 1 * 10 ** 18;        //1 BNB

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) isBlacklisted;

    constructor() ERC20("Lol 3D NFTTEST", "LOLTEST") {


        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {
    }

    function afterPreSale() external onlyOwner {
        _updateTotalFee();
        tradingIsEnabled = true;
    }

    function prepareForPartner(address _partnerOrExchangeAddress) external onlyOwner {
        timoDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn;
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn;
    }

    function setTimoDividendToken(address _newContract) external onlyOwner {
        timoDividendToken = _newContract;
        timoDividendTracker.setDividendTokenAddress(_newContract);
    }

    function setMinTimoBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        timoDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function setSendTimoInTx(bool _newStatus) external onlyOwner {
        sendTimoInTx = _newStatus;
    }

    function setWbnbReflectToken(address _newContract) external onlyOwner {
        wbnbReflectToken = _newContract;
    }

    function setWbnbReflectTracker(address _newContract) external onlyOwner {
        wbnbReflectTracker = _newContract;
    }

    function setTeamWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        teamWallet = _newWallet;
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        marketingWallet = _newWallet;
    }

    function setBurnAllianceToken(address _newAddress) external onlyOwner {
        toBurnAllianceToken = _newAddress;
    }

    function setToBurnAllianceFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        toBurnAllianceFee = newFee;
        _updateTotalFee();
    }

    function setToBurnTokenFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        toBurnTokenFee = newFee;
        _updateTotalFee();
    }

    function setGameTreasuryFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        gameTreasuryFee = newFee;
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

    function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
    }

    function setMinBNBAfterBuyback(uint256 _newAmount) public onlyOwner {
        require(_newAmount >= 0, "newAmount error");
        minBNBAfterBuyback = _newAmount;
    }

    function setMinSellToTriggerBuyback(uint256 _newAmount) public onlyOwner {
        require(_newAmount > 0, "newAmount error");
        minSellToTriggerBuyback = _newAmount;
    }

    function setBuyBackUpperLimitBNB(uint256 buyBackLimit) external onlyOwner() {
        require(buyBackLimit > 0, "buyBackLimit error");
        buybackUpperLimitBNB = buyBackLimit;
    }

    function setTimoDividendTracker(address newAddress) external onlyOwner {
        TimoDividendTracker newTimoDividendTracker = TimoDividendTracker(payable(newAddress));

        require(newTimoDividendTracker.owner() == address(this), "must be owned by Lol");

        newTimoDividendTracker.excludeFromDividends(address(newTimoDividendTracker));
        newTimoDividendTracker.excludeFromDividends(address(this));
        newTimoDividendTracker.excludeFromDividends(address(dexRouter));
        newTimoDividendTracker.excludeFromDividends(address(deadAddress));

        timoDividendTracker = newTimoDividendTracker;
    }

    function setTimoDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        timoDividendRewardsFee = newFee;
        _updateTotalFee();
    }

    function setWbnbReflectRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        wbnbReflectRewardsFee = newFee;
        _updateTotalFee();
    }

    function setMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        marketingFee = newFee;
        _updateTotalFee();
    }

    function setBuyBackFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        buyBackFee = newFee;
        _updateTotalFee();
    }

    function setLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        liquidityFee = newFee;
        _updateTotalFee();
    }

    function setDexRouter(address newAddress) external onlyOwner {
        dexRouter = IDEXRouter(newAddress);
    }

    function setIsBlacklisted(address adr, bool blacklisted) external onlyOwner {
        isBlacklisted[adr] = blacklisted;
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
            timoDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
    }

    function setMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        timoDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function setClaimWait(uint256 claimWait) external onlyOwner {
        timoDividendTracker.updateClaimWait(claimWait);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Already excluded");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        timoDividendTracker.excludeFromDividends(address(account));
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 aIterations, uint256 aClaims, uint256 aLastProcessedIndex) = timoDividendTracker.process(gas);
        emit ProcessedTimoDividendTracker(aIterations, aClaims, aLastProcessedIndex, false, gas, tx.origin);
    }

    function manualBuyBackAndBurn(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= minBNBAfterBuyback.add(_amount), "amount is too big");

        if (!swapping) {
            _buyBackAndBurn(_amount);
        }
    }

    function retrieveTokens(address token, uint amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB(uint amount) external onlyOwner {
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function claim() external {
        timoDividendTracker.processAccount(payable(msg.sender), false);
    }

    function _updateTotalFee() internal {
        totalFees = buyBackFee
        .add(liquidityFee)
        .add(marketingFee)
        .add(timoDividendRewardsFee)
        .add(wbnbReflectRewardsFee)
        .add(toBurnAllianceFee)
        .add(toBurnTokenFee)
        .add(gameTreasuryFee);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "zero address");
        require(to != address(0), "zero address");
        require(!isBlacklisted[from], "Address is blacklisted");

        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading not started");

        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(amount <= maxBuyTransactionAmount, "Error amount");

            uint256 contractBalanceRecipient = balanceOf(to);
            require(contractBalanceRecipient + amount <= maxWalletToken, "Error amount");
        } else if (
            tradingIsEnabled &&
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
                        uint256 teamPortion = increaseAmount.mul(66).div(10**2);
                        uint256 marketingPortion = increaseAmount.sub(teamPortion);
                        _transferToWallet(payable(marketingWallet), marketingPortion);
                        _transferToWallet(payable(teamWallet), teamPortion);
                    }
                }

                if(buyBackFee > 0){
                    _swapTokensForBNB(contractTokenBalance.mul(buyBackFee).div(totalFees));
                }

                if(liquidityFee > 0){
                    _swapAndLiquify(contractTokenBalance.mul(liquidityFee).div(totalFees));
                }

                if(toBurnAllianceFee > 0){
                    uint256 swapTokensToBurnAlliance = contractTokenBalance.mul(toBurnAllianceFee).div(totalFees);
                    _buyBackAllianceTokenAndBurn(swapTokensToBurnAlliance);
                }

                if(toBurnTokenFee > 0){
                    uint256 tokensToBurn = contractTokenBalance.mul(toBurnTokenFee).div(totalFees);
                    super._transfer(address(this), deadAddress, tokensToBurn);
                }

                if(gameTreasuryFee > 0){
                    uint256 tokensToTreasury = contractTokenBalance.mul(gameTreasuryFee).div(totalFees);
                    super._transfer(address(this), gameTreasury, tokensToTreasury);
                }

                if (timoDividendRewardsFee > 0) {
                    uint256 sellTokens = contractTokenBalance.mul(timoDividendRewardsFee).div(totalFees);
                    _swapAndSendTimoDividends(sellTokens.sub(1300));
                }

                if (wbnbReflectRewardsFee > 0) {
                    uint256 sellTokens = contractTokenBalance.mul(wbnbReflectRewardsFee).div(totalFees);
                    _swapAndSendWbnbReflects(sellTokens.sub(1300));
                }

                swapping = false;
            }

            if (!swapping && buyBackFee > 0) {
                uint256 buyBackBalanceBNB = address(this).balance;
                if (buyBackBalanceBNB >= minBNBAfterBuyback && amount >= minSellToTriggerBuyback) {
                    swapping = true;

                    if (buyBackBalanceBNB > buybackUpperLimitBNB) {
                        buyBackBalanceBNB = buybackUpperLimitBNB;
                    }

                    _buyBackAndBurn(buyBackBalanceBNB.div(10**2));

                    swapping = false;
                }
            }
        }

        if(tradingIsEnabled && !swapping && !excludedAccount) {
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

        try timoDividendTracker.setBalance(payable(from), balanceOf(from), sendTimoInTx) {} catch {}
        try timoDividendTracker.setBalance(payable(to), balanceOf(to), sendTimoInTx) {} catch {}

        if(!swapping && to != deadAddress && sendTimoInTx && timoDividendRewardsFee > 0){
                uint256 gas = gasForProcessing;

                try timoDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                    emit ProcessedTimoDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                }
                catch {

                }
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForBNB(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp.add(300)
        );
    }

    function _buyBackAllianceTokenAndBurn(uint256 amount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        path[2] = toBurnAllianceToken;

        _approve(address(this), address(dexRouter), amount);

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            deadAddress,
            block.timestamp.add(300)
        );
    }

    function _buyBackAndBurn(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            deadAddress,
            block.timestamp.add(300)
        );
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp.add(300)
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

        _approve(address(this), address(dexRouter), _tokenAmount);

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _recipient,
            block.timestamp.add(300)
        );
    }

    function _swapAndSendTimoDividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(timoDividendToken).balanceOf(address(timoDividendTracker));

        _swapTokensForDividendToken(tokens, address(timoDividendTracker), timoDividendToken);

        uint256 timoDividends = IERC20(timoDividendToken).balanceOf(address(timoDividendTracker)).sub(beforeAmount);

        if(timoDividends > 0){
            timoDividendTracker.distributeDividends(timoDividends);
            emit SendTimoDividends(timoDividends);
        }
    }

    function _swapAndSendWbnbReflects(uint256 tokens) private {
        uint256 beforeAmount = IERC20(wbnbReflectToken).balanceOf(address(wbnbReflectTracker));

        _swapTokensForDividendToken(tokens, address(wbnbReflectTracker), wbnbReflectToken);

        uint256 wbnbDividends = IERC20(wbnbReflectToken).balanceOf(address(wbnbReflectTracker)).sub(beforeAmount);

        if(wbnbDividends > 0){
            emit SendWbnbDividends(wbnbDividends);
        }
    }

    function _transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event SendTimoDividends(uint256 amount);
    event SendWbnbDividends(uint256 amount);
    event ProcessedTimoDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);
}