/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * BEP20 standard interface.
 */
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend() external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 CAKE = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 6 hours; // min 1 hour delay
    uint256 public minDistribution = 1 * (10 ** 17); // 0.1 CAKE minimum auto send
    uint256 public minimumTokenBalanceForDividends = 222222 * (10**9); // user must hold 1,000 token

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > minimumTokenBalanceForDividends && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount <= minimumTokenBalanceForDividends && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function getAccount(address _account) public view returns(
        address account,
        uint256 pendingReward,
        uint256 totalRealised,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable){
        account = _account;
        pendingReward = getUnpaidEarnings(account);
        totalRealised = shares[_account].totalRealised;
        lastClaimTime = shareholderClaims[_account];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = CAKE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(CAKE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = CAKE.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            CAKE.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external override {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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


contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == safeManager);
        IBEP20(_token).transfer(safeManager, _amount);
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

contract JackPot {
    using SafeMath for uint256;
    // User data Lottery
    struct userData {
        address userAddress;
        uint256 totalWon;
        uint256 lastWon;
        uint256 index;
        bool tokenOwner;
    }
    // Last person who won, and the amount.
    uint256 private lastWinner_value;
    address private lastWinner_address;

    // -- Global stats --
    uint256 private _allWon;
    uint256 private _countUsers = 0;
    uint8 private w_rt = 0;
    uint256 private _txCounter = 0;

    address immutable CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    // Lottery
    mapping(address => bool) public _isExcludedFromLottery;
    mapping(address => userData) private userByAddress;
    mapping(uint256 => userData) private userByIndex;

    // Lottery variables.
    uint256 private transactionsSinceLastLottery = 0;
    uint256 public winAmount;
    uint256 public minBalance;

    event LotteryWon(address winner, uint256 amount);
    event LotterySkipped(address skippedAddress, uint256 _potAmount);

    constructor () {
        _isExcludedFromLottery[address(this)] = true;
        winAmount = 100 * 10**18; // win amount 100 CAKE
        minBalance = 222222 * 10**9; // minimumhold 222222 LUCKYCLOVER
    }

    function random(uint256 _totalPlayers, uint8 _w_rt)
        internal
        view
        returns (uint256)
    {
        uint256 w_rnd_c_1 = block.number.add(_txCounter).add(_totalPlayers);
        uint256 w_rnd_c_2 = _allWon;
        uint256 _rnd = 0;
        if (_w_rt == 0) {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number.sub(1)),
                        w_rnd_c_1,
                        blockhash(block.number.sub(2)),
                        w_rnd_c_2
                    )
                )
            );
        } else if (_w_rt == 1) {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number.sub(1)),
                        blockhash(block.number.sub(2)),
                        blockhash(block.number.sub(3)),
                        w_rnd_c_1
                    )
                )
            );
        } else if (_w_rt == 2) {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number.sub(1)),
                        blockhash(block.number.sub(2)),
                        w_rnd_c_1,
                        blockhash(block.number.sub(3))
                    )
                )
            );
        } else if (_w_rt == 3) {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        w_rnd_c_1,
                        blockhash(block.number.sub(1)),
                        blockhash(block.number.sub(3)),
                        w_rnd_c_2
                    )
                )
            );
        } else if (_w_rt == 4) {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        w_rnd_c_1,
                        blockhash(block.number.sub(1)),
                        w_rnd_c_2,
                        blockhash(block.number.sub(2)),
                        blockhash(block.number.sub(3))
                    )
                )
            );
        } else if (_w_rt == 5) {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number.sub(1)),
                        w_rnd_c_2,
                        blockhash(block.number.sub(3)),
                        w_rnd_c_1
                    )
                )
            );
        } else {
            _rnd = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number.sub(1)),
                        w_rnd_c_2,
                        blockhash(block.number.sub(2)),
                        w_rnd_c_1,
                        blockhash(block.number.sub(2))
                    )
                )
            );
        }
        _rnd = _rnd % _totalPlayers;
        return _rnd;
    }

    function _checkLottery(address recipient) internal returns (bool) {
        if (!isUser(recipient)) {
            insertUser(recipient, 0);
        }

        if (_countUsers == 1) {
            return false;
        }

        // Increment counter
        transactionsSinceLastLottery = transactionsSinceLastLottery.add(1);
        _txCounter = _txCounter.add(1);

        uint256 _pot = IBEP20(CAKE).balanceOf(address(this));
        // Lottery time, but for real this time though
        if (_pot > winAmount) {
            return true;
        }
        return false;
    }

    function randomWinner() internal view returns(address){
        uint256 _randomWinner = random(_countUsers, w_rt);
        address _winnerAddress = getUserAtIndex(_randomWinner);
        return _winnerAddress;
    }

    function distributeLottery(address _winnerAddress, uint256 _balanceWinner) internal returns(bool) {
        if(_balanceWinner >= minBalance) {
            // Reward the winner handsomely.
            IBEP20(CAKE).transfer(_winnerAddress, winAmount);

            emit LotteryWon(_winnerAddress, winAmount);
            uint256 winnings = userByAddress[_winnerAddress].totalWon;
            uint256 totalWon = winnings.add(winAmount);

            // Update user stats
            userByAddress[_winnerAddress].lastWon = winAmount;
            userByAddress[_winnerAddress].totalWon = totalWon;
            uint256 _index = userByAddress[_winnerAddress].index;
            userByIndex[_index].lastWon = winAmount;
            userByIndex[_index].totalWon = totalWon;

            // Update global stats
            addWinner(_winnerAddress, winAmount);
            _allWon = _allWon.add(winAmount);

            // Reset count and lottery pool.
            transactionsSinceLastLottery = 0;
            return true;
        } else {
            // No one won, and the next winner is going to be even richer!
            emit LotterySkipped(_winnerAddress, winAmount);
        }
        return false;
    }

    function isUser(address userAddress) private view returns (bool isIndeed) {
        return userByAddress[userAddress].tokenOwner;
    }

    function getUserAtIndex(uint256 index)
        private
        view
        returns (address userAddress)
    {
        return userByIndex[index].userAddress;
    }

    function getTotalWon(address userAddress)
        external
        view
        returns (uint256 totalWon)
    {
        return userByAddress[userAddress].totalWon;
    }

    function getLastWon(address userAddress)
        external
        view
        returns (uint256 lastWon)
    {
        return userByAddress[userAddress].lastWon;
    }

    function getTotalWon() external view returns (uint256) {
        return _allWon;
    }

    function addWinner(address userAddress, uint256 _lastWon) internal {
        lastWinner_value = _lastWon;
        lastWinner_address = userAddress;
    }

    function getLastWinner() external view returns (address, uint256) {
        return (lastWinner_address, lastWinner_value);
    }

    function insertUser(address userAddress, uint256 winnings)
        internal
        returns (uint256 index)
    {
        if (_isExcludedFromLottery[userAddress]) {
            return index;
        }

        userByAddress[userAddress] = userData(
            userAddress,
            winnings,
            winnings,
            _countUsers,
            true
        );
        userByIndex[_countUsers] = userData(
            userAddress,
            winnings,
            winnings,
            _countUsers,
            true
        );
        index = _countUsers;
        _countUsers += 1;

        return index;
    }
}
contract LUCKYCLOVER is Ownable, IBEP20, SafeToken, LockToken, JackPot {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "LUCKY CLOVER";
    string constant _symbol = "LUCKYCLOVER";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 44444444 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.mul(100).div(100);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint256 potFee = 500;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 300;
    uint256 totalBuyFee = potFee.add(reflectionFee).add(marketingFee);
    uint256 totalSellFee = 1300;
    uint256 feeDenominator = 10000;

    address public marketingFeeReceiver;

    IDEXRouter public router;
    address pancakeV2BNBPair;
    address[] public pairs;

    uint256 public launchedAt;

    bool public feesOnNormalTransfers = true;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);

        pairs.push(pancakeV2BNBPair);
        distributor = new DividendDistributor();

        address owner_ = msg.sender;

        isFeeExempt[owner_] = true;
        isTxLimitExempt[owner_] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        marketingFeeReceiver = owner_;

        _isExcludedFromLottery[pancakeV2BNBPair] = true;
        _isExcludedFromLottery[DEAD] = true;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal open(sender, recipient) returns (bool) {
        require(!isBlacklisted[sender], "Address is blacklisted");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && recipient == pancakeV2BNBPair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}
        _handleLottery(recipient);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _handleLottery(address recipient) internal returns(bool){
        if(_checkLottery(recipient)) {
            address winner = randomWinner();
            return distributeLottery(winner, balanceOf(winner));
        }
        return false;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;

        address[] memory liqPairs = pairs;

        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return feesOnNormalTransfers;
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        return selling ? totalSellFee : totalBuyFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(isSell(recipient))).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
        
    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        ) {

            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBuyFee);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBuyFee);

            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
            swapBnbToCake();
            emit SwapBackSuccess(swapThreshold);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from pancakeSwap");
        }
    }


    function swapBnbToCake() internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(CAKE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pancakeV2BNBPair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _potFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _totalSellFee) external onlyOwner {
        potFee = _potFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalBuyFee = _potFee.add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _totalSellFee;
        require(totalBuyFee <= feeDenominator / 5, "Buy fee too high");
        require(totalSellFee <= feeDenominator / 4, "Sell fee too high");
    }

    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minimumTokenBalanceForDividends) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _minimumTokenBalanceForDividends);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas <= 1000000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pancakeV2BNBPair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function claimDividend() external {
        distributor.claimDividend();
    }
    
    function addPair(address pair) external onlyOwner {
        pairs.push(pair);
    }
    
    function removeLastPair() external onlyOwner {
        pairs.pop();
    }
    
    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        feesOnNormalTransfers = _enabled;
    }
        
    function setIsBlacklisted(address adr, bool blacklisted) external onlyOwner {
        isBlacklisted[adr] = blacklisted;
    }

    function setLaunchedAt(uint256 launched_) external onlyOwner {
        launchedAt = launched_;
    }

    event Launched(uint256 blockNumber, uint256 timestamp);
    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
}