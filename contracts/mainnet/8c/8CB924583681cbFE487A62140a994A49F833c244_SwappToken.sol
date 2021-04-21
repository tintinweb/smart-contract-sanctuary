/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

contract Context {
    /**
     * @dev returns address executing the method
     */
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    /**
     * @dev returns data passed into the method
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

contract ERC20 is Context {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply = 0.404 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of specific address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount );

        return true;
    }

    /**
     * @dev Returns approved balance to be spent by another address
     * by using transferFrom method
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets the token allowance to another spender
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    /**
     * @dev Allows to transfer tokens on senders behalf
     * based on allowance approved for the executer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Emits a {Transfer} event.
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0x0));
        require(recipient != address(0x0));

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0x0));

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0x0), account, amount);
    }

    /**
     * @dev Allows to burn tokens if token sender
     * wants to reduce totalSupply() of the token
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0x0));

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0x0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0x0));
        require(spender != address(0x0));

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}

contract Events {
    event StakeStart(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        address indexed referralAddress,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint256 referralShares,
        uint256 startDay,
        uint256 lockDays,
        uint256 daiEquivalent
    );

    event StakeEnd(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        address indexed referralAddress,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint256 referralShares,
        uint256 rewardAmount,
        uint256 closeDay,
        uint256 penaltyAmount
    );

    event InterestScraped(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 scrapeAmount,
        uint256 scrapeDay,
        uint256 stakersPenalty,
        uint256 referrerPenalty,
        uint256 currentSwappDay
    );

    event ReferralCollected(
        address indexed staker,
        bytes16 indexed stakeID,
        address indexed referrer,
        bytes16 referrerID,
        uint256 rewardAmount
    );

    event NewGlobals(
        uint256 totalShares,
        uint256 totalStaked,
        uint256 shareRate,
        uint256 referrerShares,
        uint256 indexed currentSwappDay
    );

    event NewSharePrice(
        uint256 newSharePrice,
        uint256 oldSharePrice,
        uint64 currentSwappDay
    );

    event LiquidityGuardStatus(
        bool isActive
    );
}

abstract contract Global is ERC20, Events {
    using SafeMath for uint256;

    struct Globals {
        uint256 totalStaked;
        uint256 totalShares;
        uint256 sharePrice;
        uint256 currentSwappDay;
        uint256 referralShares;
        uint256 liquidityShares;
    }

    Globals public globals;

    constructor() {
        globals.sharePrice = 100E15;
    }

    function _increaseGlobals(
        uint256 _staked,
        uint256 _shares,
        uint256 _rshares
    ) internal {
        globals.totalStaked = globals.totalStaked.add(_staked);
        globals.totalShares = globals.totalShares.add(_shares);

        if (_rshares > 0) {
            globals.referralShares = globals.referralShares.add(_rshares);
        }

        _logGlobals();
    }

    function _decreaseGlobals(
        uint256 _staked,
        uint256 _shares,
        uint256 _rshares
    ) internal {
        globals.totalStaked = globals.totalStaked > _staked ? globals.totalStaked - _staked : 0;
        globals.totalShares = globals.totalShares > _shares ? globals.totalShares - _shares : 0;

        if (_rshares > 0) {
            globals.referralShares = globals.referralShares > _rshares ? globals.referralShares - _rshares : 0;
        }

        _logGlobals();
    }

    function _logGlobals() private {
        emit NewGlobals(
            globals.totalShares,
            globals.totalStaked,
            globals.sharePrice,
            globals.referralShares,
            globals.currentSwappDay
        );
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (
        address pair
    );
}

interface IUniswapRouterV2 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token1() external view returns (address);
}

interface ILiquidityGuard {
    function getInflation(uint32 _amount) external view returns (uint256);
}

interface TokenInterface {
    function transferFrom(address _from, address _to, uint256 _value)  external returns (bool success);
    function approve(address _spender, uint256 _value)  external returns (bool success);
}

abstract contract Declaration is Global {

    uint256 constant _decimals = 18;
    uint256 constant TESLAS_PER_SWAPP = 10 ** _decimals;

    uint32 constant SECONDS_IN_DAY = 86400 seconds;
    uint16 constant MIN_LOCK_DAYS = 1;
    uint16 constant FORMULA_DAY = 65;
    uint16 constant MAX_LOCK_DAYS = 15330;
    uint16 constant MAX_BONUS_DAYS_A = 1825;
    uint16 constant MAX_BONUS_DAYS_B = 13505;
    uint16 constant MIN_REFERRAL_DAYS = 365;

    uint32 constant MIN_STAKE_AMOUNT = 1000000; // TESLA
    uint32 constant REFERRALS_RATE = 366816973; // 1.000% (direct value, can be used right away)

    uint32 public INFLATION_RATE = 103000; // 3.000% (indirect -> checks throgh LiquidityGuard)

    uint64 constant PRECISION_RATE = 1E18;

    uint96 constant THRESHOLD_LIMIT = 10000E18; // $10,000 DAI

    uint96 constant DAILY_BONUS_A = 13698630136986302; // 25%:1825 = 0.01369863013 per day;
    uint96 constant DAILY_BONUS_B = 370233246945575;   // 5%:13505 = 0.00037023324 per day;

    uint256 public LAUNCH_TIME;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapRouterV2 public constant UNISWAP_ROUTER = IUniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    IUniswapV2Factory public constant UNISWAP_FACTORY = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );

    ILiquidityGuard public LIQUIDITY_GUARD = ILiquidityGuard(
        0xECd13A6c13A97483deA1e31101e63718FcBd6b73
    );

    IUniswapV2Pair public UNISWAP_PAIR;
    bool public isLiquidityGuardActive;

    uint256 public latestDaiEquivalent;
    address[] internal _path = [address(this), WETH, DAI];

    constructor() {
        LAUNCH_TIME = 1620518400; // 2021.05.09 GMT
    }

    function createPair() external {
        UNISWAP_PAIR = IUniswapV2Pair(
            UNISWAP_FACTORY.createPair(
                WETH, address(this)
            )
        );
    }

    struct Stake {
        uint256 stakesShares;
        uint256 stakedAmount;
        uint256 rewardAmount;
        uint64 startDay;
        uint64 lockDays;
        uint64 finalDay;
        uint64 closeDay;
        uint256 scrapeDay;
        uint256 daiEquivalent;
        uint256 referrerShares;
        address referrer;
        bool isActive;
    }

    struct ReferrerLink {
        address staker;
        bytes16 stakeID;
        uint256 rewardAmount;
        uint256 processedDays;
        bool isActive;
    }

    struct CriticalMass {
        uint256 totalAmount;
        uint256 activationDay;
    }

    mapping(address => uint256) public stakeCount;
    mapping(address => uint256) public referralCount;

    mapping(address => CriticalMass) public criticalMass;
    mapping(address => mapping(bytes16 => uint256)) public scrapes;
    mapping(address => mapping(bytes16 => Stake)) public stakes;
    mapping(address => mapping(bytes16 => ReferrerLink)) public referrerLinks;

    mapping(uint256 => uint256) public scheduledToEnd;
    mapping(uint256 => uint256) public referralSharesToEnd;
    mapping(uint256 => uint256) public totalPenalties;

    mapping(address => uint256) public userStakedAmount;
}

abstract contract Helper is Declaration {

    using SafeMath for uint256;

    function currentSwappDay() public view returns (uint64) {
        return getNow() >= LAUNCH_TIME ? _currentSwappDay() : 0;
    }

    function _currentSwappDay() internal view returns (uint64) {
        return swappDayFromStamp(getNow());
    }

    function nextSwappDay() public view returns (uint64) {
        return _currentSwappDay() + 1;
    }

    function previousSwappDay() public view returns (uint64) {
        return _currentSwappDay() - 1;
    }

    function swappDayFromStamp(uint256 _timestamp) public view returns (uint64) {
        return uint64((_timestamp - LAUNCH_TIME) / SECONDS_IN_DAY);
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly { size := extcodesize(_addr) }
        return (size == 0);
    }

    function toBytes16(uint256 x) internal pure returns (bytes16 b) {
       return bytes16(bytes32(x));
    }

    function generateID(address x, uint256 y, bytes1 z) public pure returns (bytes16 b) {
        b = toBytes16(uint256(keccak256(abi.encodePacked(x, y, z))));
    }

    function generateStakeID(address _staker) internal view returns (bytes16 stakeID) {
        return generateID(_staker, stakeCount[_staker], 0x01);
    }

    function generateReferralID(address _referrer) internal view returns (bytes16 referralID) {
        return generateID(_referrer, referralCount[_referrer], 0x02);
    }

    function stakesPagination(
        address _staker,
        uint256 _offset,
        uint256 _length
    ) external view returns (bytes16[] memory _stakes) {
        uint256 start = _offset > 0 &&
            stakeCount[_staker] > _offset ?
            stakeCount[_staker] - _offset : stakeCount[_staker];

        uint256 finish = _length > 0 &&
            start > _length ?
            start - _length : 0;

        uint256 i;

        _stakes = new bytes16[](start - finish);

        for (uint256 _stakeIndex = start; _stakeIndex > finish; _stakeIndex--) {
            bytes16 _stakeID = generateID(_staker, _stakeIndex - 1, 0x01);
            if (stakes[_staker][_stakeID].stakedAmount > 0) {
                _stakes[i] = _stakeID; i++;
            }
        }
    }

    function referralsPagination(
        address _referrer,
        uint256 _offset,
        uint256 _length
    ) external view returns (bytes16[] memory _referrals) {
        uint256 start = _offset > 0 &&
            referralCount[_referrer] > _offset ?
            referralCount[_referrer] - _offset : referralCount[_referrer];

        uint256 finish = _length > 0 &&
            start > _length ?
            start - _length : 0;

        uint256 i;

        _referrals = new bytes16[](start - finish);

        for (uint256 _rIndex = start; _rIndex > finish; _rIndex--) {
            bytes16 _rID = generateID(_referrer, _rIndex - 1, 0x02);
            if (_nonZeroAddress(referrerLinks[_referrer][_rID].staker)) {
                _referrals[i] = _rID; i++;
            }
        }
    }

    function latestStakeID(address _staker) external view returns (bytes16) {
        return stakeCount[_staker] == 0 ? bytes16(0) : generateID(_staker, stakeCount[_staker].sub(1), 0x01);
    }

    function latestReferralID(address _referrer) external view returns (bytes16) {
        return referralCount[_referrer] == 0 ? bytes16(0) : generateID(_referrer, referralCount[_referrer].sub(1), 0x02);
    }

    function _increaseStakeCount(address _staker) internal {
        stakeCount[_staker] = stakeCount[_staker] + 1;
    }

    function _increaseReferralCount(address _referrer) internal {
        referralCount[_referrer] = referralCount[_referrer] + 1;
    }

    function _isMatureStake(Stake memory _stake) internal view returns (bool) {
        return _stake.closeDay > 0
            ? _stake.finalDay <= _stake.closeDay
            : _stake.finalDay <= _currentSwappDay();
    }

    function _notCriticalMassReferrer(address _referrer) internal view returns (bool) {
        return criticalMass[_referrer].activationDay == 0;
    }

    function _stakeNotStarted(Stake memory _stake) internal view returns (bool) {
        return _stake.closeDay > 0
            ? _stake.startDay > _stake.closeDay
            : _stake.startDay > _currentSwappDay();
    }

    function _stakeEnded(Stake memory _stake) internal view returns (bool) {
        return _stake.isActive == false || _isMatureStake(_stake);
    }

    function _daysLeft(Stake memory _stake) internal view returns (uint256) {
        return _stake.isActive == false
            ? _daysDiff(_stake.closeDay, _stake.finalDay)
            : _daysDiff(_currentSwappDay(), _stake.finalDay);
    }

    function _daysDiff(uint256 _startDate, uint256 _endDate) internal pure returns (uint256) {
        return _startDate > _endDate ? 0 : _endDate.sub(_startDate);
    }

    function _calculationDay(Stake memory _stake) internal view returns (uint256) {
        return _stake.finalDay > globals.currentSwappDay ? globals.currentSwappDay : _stake.finalDay;
    }

    function _startingDay(Stake memory _stake) internal pure returns (uint256) {
        return _stake.scrapeDay == 0 ? _stake.startDay : _stake.scrapeDay;
    }

    function _notFuture(uint256 _day) internal view returns (bool) {
        return _day <= _currentSwappDay();
    }

    function _notPast(uint256 _day) internal view returns (bool) {
        return _day >= _currentSwappDay();
    }

    function _nonZeroAddress(address _address) internal pure returns (bool) {
        return _address != address(0x0);
    }

    function _getLockDays(Stake memory _stake) internal pure returns (uint256) {
        return
            _stake.lockDays > 1 ?
            _stake.lockDays - 1 : 1;
    }

    function _preparePath(
        address _tokenAddress,
        address _swappAddress
    ) internal pure returns (address[] memory _path) {
        _path = new address[](3);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
        _path[2] = _swappAddress;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

abstract contract Snapshot is Helper {
    using SafeMath for uint;

    // regular shares
    struct SnapShot {
        uint256 totalShares;
        uint256 inflationAmount;
        uint256 scheduledToEnd;
    }

    // referral shares
    struct rSnapShot {
        uint256 totalShares;
        uint256 inflationAmount;
        uint256 scheduledToEnd;
    }

    mapping(uint256 => SnapShot) public snapshots;
    mapping(uint256 => rSnapShot) public rsnapshots;
    
    modifier snapshotTrigger() {
        _dailySnapshotPoint(_currentSwappDay());
        _;
    }

    /**
     * @notice allows to activate/deactivate
     * liquidity guard manually based on the
     * liquidity in UNISWAP pair contract
     */
    function liquidityGuardTrigger() public {
        (
            uint112 reserveA,
            uint112 reserveB,
        ) = UNISWAP_PAIR.getReserves();

        uint256 onUniswap = UNISWAP_PAIR.token1() == WETH
            ? reserveA
            : reserveB;

        uint256 ratio = totalSupply() == 0
            ? 0
            : onUniswap
                .mul(200)
                .div(totalSupply());

        if (ratio < 40 && isLiquidityGuardActive == false) enableLiquidityGuard();
        if (ratio > 60 && isLiquidityGuardActive == true) disableLiquidityGuard();

        emit LiquidityGuardStatus(isLiquidityGuardActive);
    }

    function enableLiquidityGuard() private {
        isLiquidityGuardActive = true;
    }

    function disableLiquidityGuard() private {
        isLiquidityGuardActive = false;
    }

    /**
     * @notice allows volunteer to offload snapshots
     * to save on gas during next start/end stake
     */
    function manualDailySnapshot() external {
        _dailySnapshotPoint(_currentSwappDay());
    }

    /**
     * @notice allows volunteer to offload snapshots
     * to save on gas during next start/end stake
     * in case manualDailySnapshot reach block limit
     */
    function manualDailySnapshotPoint(uint64 _updateDay) external {
        require(_updateDay > 0 && _updateDay < _currentSwappDay());
        require(_updateDay > globals.currentSwappDay);

        _dailySnapshotPoint(_updateDay);
    }

    /**
     * @notice internal function that offloads
     * global values to daily snapshots
     * updates globals.currentSwappDay
     */
    function _dailySnapshotPoint(uint64 _updateDay) private {
        liquidityGuardTrigger();

        uint256 scheduledToEndToday;
        uint256 totalStakedToday = globals.totalStaked;

        for (uint256 _day = globals.currentSwappDay; _day < _updateDay; _day++) {

            // ------------------------------------
            // prepare snapshot for regular shares
            // reusing scheduledToEndToday variable

            scheduledToEndToday = scheduledToEnd[_day] + snapshots[_day - 1].scheduledToEnd;

            SnapShot memory snapshot = snapshots[_day];
            snapshot.scheduledToEnd = scheduledToEndToday;

            snapshot.totalShares =
                globals.totalShares > scheduledToEndToday ?
                globals.totalShares - scheduledToEndToday : 0;

            snapshot.inflationAmount =  snapshot.totalShares
                .mul(PRECISION_RATE)
                .div(
                    _inflationAmount(
                        totalStakedToday,
                        totalSupply(),
                        totalPenalties[_day],
                        LIQUIDITY_GUARD.getInflation(
                            INFLATION_RATE
                        )
                    )
                );

            // store regular snapshot
            snapshots[_day] = snapshot;

            // ------------------------------------
            // prepare snapshot for referrer shares
            // reusing scheduledToEndToday variable

            scheduledToEndToday = referralSharesToEnd[_day] + rsnapshots[_day - 1].scheduledToEnd;

            rSnapShot memory rsnapshot = rsnapshots[_day];
            rsnapshot.scheduledToEnd = scheduledToEndToday;

            rsnapshot.totalShares =
                globals.referralShares > scheduledToEndToday ?
                globals.referralShares - scheduledToEndToday : 0;

            rsnapshot.inflationAmount = rsnapshot.totalShares
                .mul(PRECISION_RATE)
                .div(
                    _referralInflation(
                        totalStakedToday,
                        totalSupply()
                    )
                );

            // store referral snapshot
            rsnapshots[_day] = rsnapshot;

            adjustLiquidityRates();
            globals.currentSwappDay++;
        }
    }

    /**
     * @notice moves inflation up and down by 0.006%
     * from regular shares to liquidity shares
     * if the liquidityGuard is active (visa-versa)
     */
    function adjustLiquidityRates() private {
        if (isLiquidityGuardActive ==  true) {
            INFLATION_RATE = INFLATION_RATE - 6;
            return;
        }
        if (isLiquidityGuardActive == false) {
            INFLATION_RATE = INFLATION_RATE + 6;
            return;
        }
    }

    function _inflationAmount(
        uint256 _totalStaked,
        uint256 _totalSupply,
        uint256 _totalPenalties,
        uint256 _INFLATION_RATE
    ) private pure returns (uint256) {
        return (_totalStaked + _totalSupply) * 10000 / _INFLATION_RATE + _totalPenalties;
    }

    function _referralInflation(
        uint256 _totalStaked,
        uint256 _totalSupply
    ) private pure returns (uint256) {
        return (_totalStaked + _totalSupply) * 10000 / REFERRALS_RATE;
    }
}

abstract contract ReferralToken is Snapshot {
    using SafeMath for uint256;

    function _addReferrerSharesToEnd(uint256 _finalDay, uint256 _shares) internal {
        referralSharesToEnd[_finalDay] =
        referralSharesToEnd[_finalDay].add(_shares);
    }

    function _removeReferrerSharesToEnd(uint256 _finalDay, uint256 _shares) internal {
        if (_notPast(_finalDay)) {
            referralSharesToEnd[_finalDay] =
            referralSharesToEnd[_finalDay] > _shares ?
            referralSharesToEnd[_finalDay] - _shares : 0;
        } else {
            uint256 _day = previousSwappDay();
            rsnapshots[_day].scheduledToEnd =
            rsnapshots[_day].scheduledToEnd > _shares ?
            rsnapshots[_day].scheduledToEnd - _shares : 0;
        }
    }

    function _belowThresholdLevel(address _referrer) private view returns (bool) {
        return criticalMass[_referrer].totalAmount < THRESHOLD_LIMIT;
    }

    function _addCriticalMass(address _referrer, uint256 _daiEquivalent) internal {
        criticalMass[_referrer].totalAmount =
        criticalMass[_referrer].totalAmount.add(_daiEquivalent);
        criticalMass[_referrer].activationDay = _determineActivationDay(_referrer);
    }

    function _removeCriticalMass(
        address _referrer,
        uint256 _daiEquivalent,
        uint256 _startDay
    ) internal {
        if (
            _notFuture(_startDay) == false &&
            _nonZeroAddress(_referrer)
        ) {
            criticalMass[_referrer].totalAmount =
            criticalMass[_referrer].totalAmount > _daiEquivalent ?
            criticalMass[_referrer].totalAmount - _daiEquivalent : 0;
            criticalMass[_referrer].activationDay = _determineActivationDay(_referrer);
        }
    }

    function _determineActivationDay(address _referrer) private view returns (uint256) {
        return _belowThresholdLevel(_referrer) ? 0 : _activationDay(_referrer);
    }

    function _activationDay(address _referrer) private view returns (uint256) {
        return
            criticalMass[_referrer].activationDay > 0 ?
            criticalMass[_referrer].activationDay : _currentSwappDay();
    }

    function _updateDaiEquivalent() internal returns (uint256) {
        try UNISWAP_ROUTER.getAmountsOut(
            TESLAS_PER_SWAPP, _path
        ) returns (uint256[] memory results) {
            latestDaiEquivalent = results[2];
            return latestDaiEquivalent;
        } catch Error(string memory) {
            return latestDaiEquivalent;
        } catch (bytes memory) {
            return latestDaiEquivalent;
        }
    }

    function referrerInterest(
        bytes16 _referralID,
        uint256 _scrapeDays
    ) external snapshotTrigger {
        _referrerInterest(
            msg.sender,
            _referralID,
            _scrapeDays
        );
    }

    function referrerInterestBulk(
        bytes16[] memory _referralIDs,
        uint256[] memory _scrapeDays
    ) external snapshotTrigger {
        for(uint256 i = 0; i < _referralIDs.length; i++) {
            _referrerInterest(
                msg.sender,
                _referralIDs[i],
                _scrapeDays[i]
            );
        }
    }

    function _referrerInterest(
        address _referrer,
        bytes16 _referralID,
        uint256 _processDays
    ) internal {
        ReferrerLink memory link =
        referrerLinks[_referrer][_referralID];

        require(link.isActive == true);

        address staker = link.staker;
        bytes16 stakeID = link.stakeID;

        Stake memory stake = stakes[staker][stakeID];

        uint256 startDay = _determineStartDay(stake, link);
        uint256 finalDay = _determineFinalDay(stake);

        if (_stakeEnded(stake)) {
            if (
                _processDays > 0 &&
                _processDays < _daysDiff(startDay, finalDay)
                )
            {
                link.processedDays =
                link.processedDays.add(_processDays);

                finalDay =
                startDay.add(_processDays);
            } else {
                link.isActive = false;
            }
        } else {
            _processDays = _daysDiff(startDay, _currentSwappDay());

            link.processedDays =
            link.processedDays.add(_processDays);

            finalDay =
            startDay.add(_processDays);
        }

        uint256 referralInterest = _checkReferralInterest(
            stake,
            startDay,
            finalDay
        );

        link.rewardAmount = link.rewardAmount.add(referralInterest);

        referrerLinks[_referrer][_referralID] = link;

        _mint(_referrer, referralInterest);

        emit ReferralCollected(
            staker,
            stakeID,
            _referrer,
            _referralID,
            referralInterest
        );
    }

    function checkReferralsByID(
        address _referrer,
        bytes16 _referralID
    ) external view returns (
        address staker,
        bytes16 stakeID,
        uint256 referrerShares,
        uint256 referralInterest,
        bool isActiveReferral,
        bool isActiveStake,
        bool isMatureStake,
        bool isEndedStake
    ) {
        ReferrerLink memory link = referrerLinks[_referrer][_referralID];

        staker = link.staker;
        stakeID = link.stakeID;
        isActiveReferral = link.isActive;

        Stake memory stake = stakes[staker][stakeID];
        referrerShares = stake.referrerShares;

        referralInterest = _checkReferralInterest(
            stake,
            _determineStartDay(stake, link),
            _determineFinalDay(stake)
        );

        isActiveStake = stake.isActive;
        isEndedStake = _stakeEnded(stake);
        isMatureStake = _isMatureStake(stake);
    }

    function _checkReferralInterest(
        Stake memory _stake,
        uint256 _startDay,
        uint256 _finalDay
    ) internal view returns (uint256 _referralInterest) {
        return _notCriticalMassReferrer(_stake.referrer) ? 0 : _getReferralInterest(_stake, _startDay, _finalDay);
    }

    function _getReferralInterest(
        Stake memory _stake,
        uint256 _startDay,
        uint256 _finalDay
    ) private view returns (uint256 _referralInterest) {
        for (uint256 _day = _startDay; _day < _finalDay; _day++) {
            _referralInterest += _stake.stakesShares * PRECISION_RATE / rsnapshots[_day].inflationAmount;
        }
    }

    function _determineStartDay(
        Stake memory _stake,
        ReferrerLink memory _link
    ) internal view returns (uint256) {
        return (
            criticalMass[_stake.referrer].activationDay > _stake.startDay ?
            criticalMass[_stake.referrer].activationDay : _stake.startDay
        ).add(_link.processedDays);
    }

    function _determineFinalDay(
        Stake memory _stake
    ) internal view returns (uint256) {
        return
            _stake.closeDay > 0 ?
            _stake.closeDay : _calculationDay(_stake);
    }
}

abstract contract StakingToken is ReferralToken {
    using SafeMath for uint256;

    /**
     * @notice A method for a staker to create multiple stakes
     * @param _stakedAmount amount of SWAPP staked.
     * @param _lockDays amount of days it is locked for.
     * @param _referrer address of the referrer
     */
    function createStakeBulk(
        uint256[] memory _stakedAmount,
        uint64[] memory _lockDays,
        address[] memory _referrer
    ) external {
        for(uint256 i = 0; i < _stakedAmount.length; i++) {
            createStake(_stakedAmount[i], _lockDays[i], _referrer[i]);
        }
    }

    /**
     * @notice A method for a staker to create a stake
     * @param _stakedAmount amount of SWAPP staked.
     * @param _lockDays amount of days it is locked for.
     * @param _referrer address of the referrer
     */
    function createStake(
        uint256 _stakedAmount,
        uint64 _lockDays,
        address _referrer
    )  public returns (bytes16, uint256, bytes16 referralID) {
        require(msg.sender != _referrer && notContract(_referrer));
        require(_lockDays >= MIN_LOCK_DAYS && _lockDays <= MAX_LOCK_DAYS);
        require(_stakedAmount >= MIN_STAKE_AMOUNT);

        (
            Stake memory newStake,
            bytes16 stakeID,
            uint256 _startDay
        ) = _createStake(msg.sender, _stakedAmount, _lockDays, _referrer);

        if (newStake.referrerShares > 0) {

            ReferrerLink memory referrerLink;

            referrerLink.staker = msg.sender;
            referrerLink.stakeID = stakeID;
            referrerLink.isActive = true;

            referralID = generateReferralID(_referrer);
            referrerLinks[_referrer][referralID] = referrerLink;

            _increaseReferralCount(_referrer);
            _addReferrerSharesToEnd(newStake.finalDay, newStake.referrerShares);
        }

        stakes[msg.sender][stakeID] = newStake;

        _increaseStakeCount(msg.sender);

        _increaseGlobals(
            newStake.stakedAmount,
            newStake.stakesShares,
            newStake.referrerShares
        );

        _addScheduledShares(newStake.finalDay, newStake.stakesShares);

        emit StakeStart(
            stakeID,
            msg.sender,
            _referrer,
            newStake.stakedAmount,
            newStake.stakesShares,
            newStake.referrerShares,
            newStake.startDay,
            newStake.lockDays,
            newStake.daiEquivalent
        );

        return (stakeID, _startDay, referralID);
    }

    function getStakingShare(
        uint256 _stakedAmount,
        uint64 _lockDays,
        address _referrer
    ) external view returns (uint256 stakingShare) {
        return _stakesShares(
            _stakedAmount,
            _lockDays,
            _referrer,
            globals.sharePrice
        );
    }

    /**
    * @notice A method for a staker to start a stake
    * @param _staker ...
    * @param _stakedAmount ...
    * @param _lockDays ...
    */
    function _createStake(
        address _staker,
        uint256 _stakedAmount,
        uint64 _lockDays,
        address _referrer
    ) private returns (Stake memory _newStake, bytes16 _stakeID, uint64 _startDay) {
        _burn(_staker, _stakedAmount);

        userStakedAmount[_staker] = userStakedAmount[_staker].add(_stakedAmount);

        _startDay = nextSwappDay();
        _stakeID = generateStakeID(_staker);

        _newStake.lockDays = _lockDays;
        _newStake.startDay = _startDay;
        _newStake.finalDay = _startDay + _lockDays;
        _newStake.isActive = true;

        _newStake.stakedAmount = _stakedAmount;
        _newStake.stakesShares = _stakesShares(
            _stakedAmount,
            _lockDays,
            _referrer,
            globals.sharePrice
        );

        _updateDaiEquivalent();

        _newStake.daiEquivalent = latestDaiEquivalent
            .mul(_newStake.stakedAmount)
            .div(TESLAS_PER_SWAPP);

        if (_nonZeroAddress(_referrer)) {
            _newStake.referrer = _referrer;
            _addCriticalMass(_newStake.referrer, _newStake.daiEquivalent);
            _newStake.referrerShares = _referrerShares(
                _stakedAmount,
                _lockDays,
                _referrer
            );
        }
    }

    /**
    * @notice A method for a staker to remove a stake
    * belonging to his address by providing ID of a stake.
    * @param _stakeID unique bytes sequence reference to the stake
    */
    function endStake(bytes16 _stakeID) snapshotTrigger external returns (uint256) {
        (
            Stake memory endedStake,
            uint256 penaltyAmount
        ) = _endStake(msg.sender, _stakeID);

        _decreaseGlobals(
            endedStake.stakedAmount,
            endedStake.stakesShares,
            endedStake.referrerShares
        );

        _removeScheduledShares(endedStake.finalDay, endedStake.stakesShares);
        _removeReferrerSharesToEnd(endedStake.finalDay, endedStake.referrerShares);

        _removeCriticalMass(
            endedStake.referrer,
            endedStake.daiEquivalent,
            endedStake.startDay
        );

        _storePenalty(endedStake.closeDay, penaltyAmount);

        _sharePriceUpdate(
            endedStake.stakedAmount > penaltyAmount ?
            endedStake.stakedAmount - penaltyAmount : 0,
            endedStake.rewardAmount + scrapes[msg.sender][_stakeID],
            endedStake.referrer,
            endedStake.lockDays,
            endedStake.stakesShares
        );

        emit StakeEnd(
            _stakeID,
            msg.sender,
            endedStake.referrer,
            endedStake.stakedAmount,
            endedStake.stakesShares,
            endedStake.referrerShares,
            endedStake.rewardAmount,
            endedStake.closeDay,
            penaltyAmount
        );

        return endedStake.rewardAmount;
    }

    function _endStake(
        address _staker,
        bytes16 _stakeID
    ) private returns (Stake storage _stake, uint256 _penalty) {
        require(stakes[_staker][_stakeID].isActive);

        _stake = stakes[_staker][_stakeID];
        _stake.closeDay = _currentSwappDay();
        _stake.rewardAmount = _calculateRewardAmount(_stake);
        _penalty = _calculatePenaltyAmount(_stake);

        _stake.isActive = false;

        userStakedAmount[_staker] = userStakedAmount[_staker].sub(_stake.stakedAmount);

        _mint(
            _staker,
            _stake.stakedAmount > _penalty ?
            _stake.stakedAmount - _penalty : 0
        );

        _mint(_staker, _stake.rewardAmount);
    }

    /**
    * @notice alloes to scrape interest from active stake
    * @param _stakeID unique bytes sequence reference to the stake
    * @param _scrapeDays amount of days to proccess, 0 = all
    */
    function scrapeInterest(
        bytes16 _stakeID,
        uint64 _scrapeDays
    ) external snapshotTrigger returns (
        uint256 scrapeDay,
        uint256 scrapeAmount,
        uint256 remainingDays,
        uint256 stakersPenalty,
        uint256 referrerPenalty
    ) {
        require(stakes[msg.sender][_stakeID].isActive);

        Stake memory stake = stakes[msg.sender][_stakeID];

        scrapeDay = _scrapeDays > 0
            ? _startingDay(stake).add(_scrapeDays)
            : _calculationDay(stake);

        scrapeDay = scrapeDay > stake.finalDay
            ? _calculationDay(stake)
            : scrapeDay;

        scrapeAmount = _loopRewardAmount(
            stake.stakesShares,
            _startingDay(stake),
            scrapeDay
        );

        if (_isMatureStake(stake) == false) {

            remainingDays = _daysLeft(stake);

            stakersPenalty = _stakesShares(
                scrapeAmount,
                remainingDays,
                msg.sender,
                globals.sharePrice
            );

            stake.stakesShares = stake.stakesShares.sub(stakersPenalty);

            _removeScheduledShares(stake.finalDay, stakersPenalty);

            if (stake.referrerShares > 0) {
                referrerPenalty = _stakesShares(
                    scrapeAmount,
                    remainingDays,
                    address(0x0),
                    globals.sharePrice
                );

                stake.referrerShares = stake.referrerShares.sub(referrerPenalty);
                _removeReferrerSharesToEnd(stake.finalDay, referrerPenalty);
            }

            _decreaseGlobals(0, stakersPenalty, referrerPenalty);

            _sharePriceUpdate(
                stake.stakedAmount,
                scrapeAmount,
                stake.referrer,
                stake.lockDays,
                stake.stakesShares
            );
        }
        else {
            scrapes[msg.sender][_stakeID] = scrapes[msg.sender][_stakeID].add(scrapeAmount);
            _sharePriceUpdate(
                stake.stakedAmount,
                scrapes[msg.sender][_stakeID],
                stake.referrer,
                stake.lockDays,
                stake.stakesShares
            );
        }

        stake.scrapeDay = scrapeDay;
        stakes[msg.sender][_stakeID] = stake;

        _mint(msg.sender, scrapeAmount);

        emit InterestScraped(
            _stakeID,
            msg.sender,
            scrapeAmount,
            scrapeDay,
            stakersPenalty,
            referrerPenalty,
            _currentSwappDay()
        );
    }

    function _addScheduledShares(uint256 _finalDay, uint256 _shares) internal {
        scheduledToEnd[_finalDay] = scheduledToEnd[_finalDay].add(_shares);
    }

    function _removeScheduledShares(uint256 _finalDay, uint256 _shares) internal {
        if (_notPast(_finalDay)) {
            scheduledToEnd[_finalDay] =
            scheduledToEnd[_finalDay] > _shares ?
            scheduledToEnd[_finalDay] - _shares : 0;
        } else {
            uint256 _day = previousSwappDay();
            snapshots[_day].scheduledToEnd =
            snapshots[_day].scheduledToEnd > _shares ?
            snapshots[_day].scheduledToEnd - _shares : 0;
        }
    }

    function _sharePriceUpdate(
        uint256 _stakedAmount,
        uint256 _rewardAmount,
        address _referrer,
        uint256 _lockDays,
        uint256 _stakeShares
    ) private {
        if (_stakeShares > 0 && _currentSwappDay() > FORMULA_DAY) {
            uint256 newSharePrice = _getNewSharePrice(
                _stakedAmount,
                _rewardAmount,
                _stakeShares,
                _lockDays,
                _referrer
            );

            if (newSharePrice > globals.sharePrice) {
                newSharePrice = newSharePrice < globals.sharePrice.mul(110).div(100) ?
                    newSharePrice : globals.sharePrice.mul(110).div(100);

                emit NewSharePrice(
                    newSharePrice,
                    globals.sharePrice,
                    _currentSwappDay()
                );

                globals.sharePrice = newSharePrice;
            }

            return;
        }

        if (_currentSwappDay() == FORMULA_DAY) {
            globals.sharePrice = 110E15;
        }
    }

    function _getNewSharePrice(
        uint256 _stakedAmount,
        uint256 _rewardAmount,
        uint256 _stakeShares,
        uint256 _lockDays,
        address _referrer
    ) private pure returns (uint256) {
        uint256 _bonusAmount = _getBonus(
            _lockDays, _nonZeroAddress(_referrer) ? 11E9 : 10E9
        );

        return 
            _stakedAmount
                .add(_rewardAmount)
                .mul(_bonusAmount)
                .mul(1E8)
                .div(_stakeShares);
    }

    function checkMatureStake(
        address _staker,
        bytes16 _stakeID
    ) external view returns (bool isMature) {
        Stake memory stake = stakes[_staker][_stakeID];
        isMature = _isMatureStake(stake);
    }

    function checkStakeByID(address _staker, bytes16 _stakeID) external view
        returns (
            uint256 startDay,
            uint256 lockDays,
            uint256 finalDay,
            uint256 closeDay,
            uint256 scrapeDay,
            uint256 stakedAmount,
            uint256 stakesShares,
            uint256 rewardAmount,
            uint256 penaltyAmount,
            bool isActive,
            bool isMature
        )
    {
        Stake memory stake = stakes[_staker][_stakeID];
        startDay = stake.startDay;
        lockDays = stake.lockDays;
        finalDay = stake.finalDay;
        closeDay = stake.closeDay;
        scrapeDay = stake.scrapeDay;
        stakedAmount = stake.stakedAmount;
        stakesShares = stake.stakesShares;
        rewardAmount = _checkRewardAmount(stake);
        penaltyAmount = _calculatePenaltyAmount(stake);
        isActive = stake.isActive;
        isMature = _isMatureStake(stake);
    }

    function _stakesShares(
        uint256 _stakedAmount,
        uint256 _lockDays,
        address _referrer,
        uint256 _sharePrice
    ) private pure returns (uint256) {
        return _nonZeroAddress(_referrer)
            ? _sharesAmount(_stakedAmount, _lockDays, _sharePrice, 11E9)
            : _sharesAmount(_stakedAmount, _lockDays, _sharePrice, 10E9);
    }

    function _sharesAmount(
        uint256 _stakedAmount,
        uint256 _lockDays,
        uint256 _sharePrice,
        uint256 _extraBonus
    ) private pure returns (uint256) {
        return _baseAmount(_stakedAmount, _sharePrice)
            .mul(_getBonus(_lockDays, _extraBonus))
            .div(10E9);
    }

    function _getBonus(
        uint256 _lockDays,
        uint256 _extraBonus
    ) private pure returns (uint256) {
        return
            _regularBonus(_lockDays, DAILY_BONUS_A, MAX_BONUS_DAYS_A) +
            _regularBonus(
                _lockDays > MAX_BONUS_DAYS_A ?
                _lockDays - MAX_BONUS_DAYS_A : 0, DAILY_BONUS_B, MAX_BONUS_DAYS_B
            ) + _extraBonus;
    }

    function _regularBonus(
        uint256 _lockDays,
        uint256 _daily,
        uint256 _maxDays
    ) private pure returns (uint256) {
        return (
            _lockDays > _maxDays
                ? _maxDays.mul(_daily)
                : _lockDays.mul(_daily)
            ).div(10E9);
    }

    function _baseAmount(
        uint256 _stakedAmount,
        uint256 _sharePrice
    ) private pure returns (uint256) {
        return _stakedAmount.mul(PRECISION_RATE).div(_sharePrice);
    }

    function _referrerShares(
        uint256 _stakedAmount,
        uint256 _lockDays,
        address _referrer
    ) private view returns (uint256) {
        return
            _notCriticalMassReferrer(_referrer) ||
            _lockDays < MIN_REFERRAL_DAYS
                ? 0
                : _sharesAmount(
                    _stakedAmount,
                    _lockDays,
                    globals.sharePrice,
                    10E9
                );
    }

    function _checkRewardAmount(Stake memory _stake) private view returns (uint256) {
        return _stake.isActive ? _detectReward(_stake) : _stake.rewardAmount;
    }

    function _detectReward(Stake memory _stake) private view returns (uint256) {
        return _stakeNotStarted(_stake) ? 0 : _calculateRewardAmount(_stake);
    }

    function _storePenalty(uint64 _storeDay, uint256 _penalty) private {
        if (_penalty > 0) {
            totalPenalties[_storeDay] =
            totalPenalties[_storeDay].add(_penalty);
        }
    }

    function _calculatePenaltyAmount(Stake memory _stake) private view returns (uint256) {
        return _stakeNotStarted(_stake) || _isMatureStake(_stake) ? 0 : _getPenalties(_stake);
    }

    function _getPenalties(Stake memory _stake) private view returns (uint256) {
        return _stake.stakedAmount * (100 + (800 * (_daysLeft(_stake) - 1) / (_getLockDays(_stake)))) / 1000;
    }

    function _calculateRewardAmount(Stake memory _stake) private view returns (uint256) {
        return _loopRewardAmount(
            _stake.stakesShares,
            _startingDay(_stake),
            _calculationDay(_stake)
        );
    }

    function _loopRewardAmount(
        uint256 _stakeShares,
        uint256 _startDay,
        uint256 _finalDay
    ) private view returns (uint256 _rewardAmount) {
        for (uint256 _day = _startDay; _day < _finalDay; _day++) {
            _rewardAmount += _stakeShares * PRECISION_RATE / snapshots[_day].inflationAmount;
        }
    }
}

contract SwappToken is StakingToken {
    address public LIQUIDITY_TRANSFORMER;
    address public YIELD_FARM_STABLE;
    address public YIELD_FARM_LP;
    address public tokenMinterDefiner;

    modifier onlyMinter() {
        require(
            msg.sender == LIQUIDITY_TRANSFORMER ||
            msg.sender == YIELD_FARM_STABLE ||
            msg.sender == YIELD_FARM_LP,
            'SWAPP: Invalid token minter'
        );
        _;
    }

    constructor() ERC20("Swapp Token", "SWAPP") {
        tokenMinterDefiner = msg.sender;

        _mint(0x0d970a04d46c73B6d20d9a0B2B07C35F2495ca9c, 162500000E18); // SWAPP FOUNDATION - Contract Owner Wallet
        _mint(0x915D99375Ba8EDbbee46bE1AD045718a05A6655b, 3307862E18);   // MM-PRESALE Investors Wallet
        _mint(0x7Db4456a73a9C94a381d244E9dfC76E83C05913E, 58364082E18);  // Employee Pool Including Founders MM Wallet
        _mint(0x62F16a5bA06693B1E96a656d46e66A8CdaE17C69, 13328056E18);  // Swapp Previous Investors MM Wallet
        _mint(0x94dc2f1823AbfdC2fb9BB8Ae10162b65D2Cf1c65, 250000000E18); // Rewards Wallet
        _mint(0x2a8eA8a4842DA268FA4180b1a99B7876f820ECC1, 35000000E18);  // Future Development Wallet
        _mint(0x000baFB91ED6436ad2888C2418197aFDB85785C5, 5000000E18);   // Reserved Funding Wallet
        _mint(0xd4041e1c24A54134Fb9657e8DA85e75001D7Ea44, 5000000E18);   // Bounty, Advisors, Partnership Wallet
    }

    receive() external payable {
        revert();
    }

    function setMinters(
        address _transformer,
        address _yieldFarmStable,
        address _yieldFarmLP
    ) external {
        require(tokenMinterDefiner == msg.sender);
        LIQUIDITY_TRANSFORMER = _transformer;
        YIELD_FARM_STABLE = _yieldFarmStable;
        YIELD_FARM_LP = _yieldFarmLP;
    }

    function burnMinterDefiner() external {
        require(tokenMinterDefiner == msg.sender);
        tokenMinterDefiner = address(0x0);
    }

    /**
     * @notice allows liquidityTransformer to mint supply
     * @dev executed from liquidityTransformer upon UNISWAP transfer
     * and during reservation payout to contributors and referrers
     * @param _investorAddress address for minting SWAPP tokens
     * @param _amount of tokens to mint for _investorAddress
     */
    function mintSupply(address _investorAddress, uint256 _amount) external onlyMinter {
        _mint(_investorAddress, _amount);
    }

    /**
     * @notice allows to grant permission to CM referrer status
     * @dev called from liquidityTransformer if user referred 50 ETH
     * @param _referrer - address that becomes a CM reffer
     */
    function giveStatus(address _referrer) external onlyMinter {
        criticalMass[_referrer].totalAmount = THRESHOLD_LIMIT;
        criticalMass[_referrer].activationDay = nextSwappDay();
    }

    /**
     * @notice allows to create stake directly with ETH
     * if you don't have SWAPP tokens method will convert
     * and use amount returned from UNISWAP to open a stake
     * @param _lockDays amount of days it is locked for.
     * @param _referrer referrer address for +10% bonus
     */
    function createStakeWithETH(
        uint64 _lockDays,
        address _referrer
    ) external payable returns (bytes16, uint256, bytes16 referralID) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        uint256[] memory amounts = UNISWAP_ROUTER.swapExactETHForTokens{value: msg.value}(
            1,
            path,
            msg.sender,
            block.timestamp
        );

        return createStake(amounts[1], _lockDays, _referrer);
    }

    /**
     * @notice allows to create stake with another token
     * if you don't have SWAPP tokens method will convert
     * and use amount returned from UNISWAP to open a stake
     * @dev the token must have WETH pair on UNISWAP
     * @param _tokenAddress any ERC20 token address
     * @param _tokenAmount amount to be converted to SWAPP
     * @param _lockDays amount of days it is locked for.
     * @param _referrer referrer address for +10% bonus
     */
    function createStakeWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _lockDays,
        address _referrer
    ) external returns (bytes16, uint256, bytes16 referralID) {
        TokenInterface token = TokenInterface(_tokenAddress);

        token.transferFrom(msg.sender, address(this), _tokenAmount);
        token.approve(address(UNISWAP_ROUTER), _tokenAmount);

        address[] memory path = _preparePath(_tokenAddress, address(this));

        uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
            _tokenAmount,
            1,
            path,
            msg.sender,
            block.timestamp
        );

        return createStake(amounts[2], _lockDays, _referrer);
    }
}