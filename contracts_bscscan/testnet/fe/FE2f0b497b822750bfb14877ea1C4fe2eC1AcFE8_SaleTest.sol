// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IUniswapV2.sol";

interface IPancakeSwap {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract SaleTest is Ownable {
    IERC20 public token;
    bool public test = true; //test

    struct Stage {
        // deposit info
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 hardCapInTokens;
        uint256 totalDistributedTokens;
        uint256 thousandTokensPriceInUSDT;
        uint256 minDepositInUSDT;
        uint256 maxDepositInUSDT;

        // vesting conditions
        uint256 firstReleasePercent;
        uint256 minPeriod;
        uint256 percentPerPeriod;
        uint256 offsetTime;
    }

    struct Lock {
        uint256 totalLockedTokens;
        // vesting conditions
        uint256 firstReleasePercent;
        uint256 minPeriod;
        uint256 percentPerPeriod;
        uint256 offsetTime;
        uint256 totalClaimed;
    }

    bool public isListed;

    struct User {
        uint256 totalTokens;
        uint256 totalClaimed;
    }

    struct Locker {
        uint256 totalTokens;
        uint256 totalClaimed;
    }

    uint256 public tgeTimestamp;

    //      account    =>    stageIndex => data
    mapping(address => User[]) public users;
    mapping(address => Locker[]) public lockers;

    Stage[] public stages;
    Lock[] public locks;


    mapping(address => bool) public whitelist;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant PRICE_DENOMINATOR = 1000;

//    address USDTAddress = 0x55d398326f99059fF775485246999027B3197955; // mainnet
    address USDTAddress = 0x40D7c8F55C25f448204a140b5a6B0bD8C1E48b13; // testnet
    IPancakeSwap public router;

    constructor() {
//        token = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); //Cake token mainnet
        token = IERC20(0x2ea8c131b84a11f8CCC7bfdC6abE6A96341b8673); //test token testnet
//        initDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet bsc
        initDEXRouter(0x14e9203E14EF89AB284b8e9EecC787B1743AD285); // testnet bsc
        whitelist[msg.sender] = true;
    }
    function initDEXRouter(address _router) public onlyOwner {
        IPancakeSwap _pancakeV2Router = IPancakeSwap(_router);
        router = _pancakeV2Router;
    }

    function addStage(
        uint256 startTimestamp, uint256 endTimestamp,
        uint256 hardCapInTokens, uint256 thousandTokensPriceInUSDT,
        uint256 minDepositInUSDT, uint256 maxDepositInUSDT,
        uint256 firstReleasePercent, uint256 minPeriod, uint256 percentPerPeriod, uint256 offsetTime
    ) public onlyOwner {
        require(stages.length < 3);
        require(startTimestamp < endTimestamp);
        require(minDepositInUSDT < maxDepositInUSDT);
        require(firstReleasePercent > 100 && firstReleasePercent <= DENOMINATOR, "Should be passed with DENOMINATOR");
        require(minPeriod > 0 && percentPerPeriod > 0);

        stages.push(
            Stage(
                startTimestamp,
                endTimestamp,
                hardCapInTokens,
                0,
                thousandTokensPriceInUSDT,
                minDepositInUSDT,
                maxDepositInUSDT,
                firstReleasePercent,
                minPeriod,
                percentPerPeriod,
                offsetTime
            )
        );
    }

    function addLock(
        uint256 firstReleasePercent, uint256 minPeriod, uint256 percentPerPeriod, uint256 offsetTime
    ) public onlyOwner {
        require(firstReleasePercent > 100 && firstReleasePercent <= DENOMINATOR, "Should be passed with DENOMINATOR");
        require(minPeriod > 0 && percentPerPeriod > 0);

        locks.push(
            Lock(
                0,
                firstReleasePercent,
                minPeriod,
                percentPerPeriod,
                offsetTime,
                0
            )
        );
    }

    receive() payable external {
        deposit();
    }

    // 0 - private sale, 1,2 - public sale, 3 -> finished or not started
    function currentStage() view public returns (uint256) {
        for (uint256 i = 0; i < stages.length; i++) {
            if (block.timestamp > stages[i].startTimestamp && block.timestamp < stages[i].endTimestamp) {
                return i;
            }
        }
        return 3;
    }

    function reachedHardCap() view public returns (bool) {
        require(currentStage() < 3, 'Sales finished or not started');
        return stages[currentStage()].hardCapInTokens == stages[currentStage()].totalDistributedTokens;
    }

    function remainTokensOfAddress(address account) view public returns (uint256) {
        User[] memory user = users[account];
        uint256 amount;
        for (uint256 i = 0; i < stages.length; i++) {
            amount += user[i].totalTokens - user[i].totalClaimed;
        }
        return amount;
    }

    function claimable(address account, uint256 time) view external returns (uint256) {
        uint256 amount;
        for (uint256 i = 0; i < stages.length; i++) {
            amount += claimableByStageIndex(i, account, time);
        }
        return amount;
    }

    function claimableByStageIndex(uint256 stageIndex, address account, uint256 time) view public returns (uint256) {
        require(stageIndex < stages.length);
        if (!isListed) {
            return 0;
        }

        User memory user = users[account][stageIndex];
        uint256 absolutePercent = _absolutePercentageByStageIndex(stageIndex, time);
        uint256 absoluteAmount = user.totalTokens * absolutePercent / DENOMINATOR;
        if (absoluteAmount < user.totalClaimed) {
            return 0;
        }
        uint256 claimableAmount = absoluteAmount - user.totalClaimed;
        return claimableAmount;
    }

    function claimableByLockIndex(uint256 lockIndex, address account, uint256 time) view public returns (uint256) {
        require(lockIndex < locks.length);
        if (!isListed) {
            return 0;
        }

        Locker memory locker = lockers[account][lockIndex];
        uint256 absolutePercent = _absolutePercentageByLockIndex(lockIndex, time);
        uint256 absoluteAmount = locker.totalTokens * absolutePercent / DENOMINATOR;
        if (absoluteAmount < locker.totalClaimed) {
            return 0;
        }
        uint256 claimableAmount = absoluteAmount - locker.totalClaimed;
        return claimableAmount;
    }

    function _absolutePercentageByStageIndex(uint256 stageIndex, uint256 time) view private returns (uint256) {
        Stage memory stage = stages[stageIndex];

        uint256 totalPercent = stage.firstReleasePercent;

        if (time == 0) {
            time = block.timestamp;
        }

        if (stage.offsetTime < time - tgeTimestamp) {
            uint256 deltaTime = time - tgeTimestamp - stage.offsetTime;
            uint256 periods = deltaTime / stage.minPeriod;
            if (periods == 0) {
                return totalPercent;
            }

            totalPercent += periods * stage.percentPerPeriod;
            if (totalPercent > DENOMINATOR) {
                return DENOMINATOR;
            }
        }

        return totalPercent;
    }

    function _absolutePercentageByLockIndex(uint256 lockIndex, uint256 time) view private returns (uint256) {
        Lock memory lock = locks[lockIndex];

        uint256 totalPercent = lock.firstReleasePercent;

        if (time == 0) {
            time = block.timestamp;
        }

        if (lock.offsetTime < time - tgeTimestamp) {
            uint256 deltaTime = time - tgeTimestamp - lock.offsetTime;
            uint256 periods = deltaTime / lock.minPeriod;
            if (periods == 0) {
                return totalPercent;
            }

            totalPercent += periods * lock.percentPerPeriod;
            if (totalPercent > DENOMINATOR) {
                return DENOMINATOR;
            }
        }

        return totalPercent;
    }

    function claim() external {
        require(isListed, 'Not listed');
        uint256 amountByStage;
        uint256 toSendAmount;
        User[] storage userStages = users[msg.sender];
        for (uint256 i = 0; i < stages.length; i++) {
            amountByStage = claimableByStageIndex(i, msg.sender, block.timestamp);
            if (amountByStage > 0) {
                if (amountByStage > userStages[i].totalTokens - userStages[i].totalClaimed) {
                    amountByStage = userStages[i].totalTokens - userStages[i].totalClaimed;
                }
                userStages[i].totalClaimed += amountByStage;
                toSendAmount += amountByStage;
            }
        }
        if (toSendAmount > 0) {
            token.transfer(msg.sender, toSendAmount);
            emit Claimed(msg.sender, toSendAmount);
        }
    }

    function claimTeamVesting(uint256 lockIndex) external {
        require(isListed, 'Not listed');
        uint256 amountByLock;
        Locker[] storage userLocks = lockers[msg.sender];
        amountByLock = claimableByLockIndex(lockIndex, msg.sender, block.timestamp);
        if (amountByLock > 0) {
            if (amountByLock > userLocks[lockIndex].totalTokens - userLocks[lockIndex].totalClaimed) {
                amountByLock = userLocks[lockIndex].totalTokens - userLocks[lockIndex].totalClaimed;
            }
            userLocks[lockIndex].totalClaimed += amountByLock;
            locks[lockIndex].totalClaimed += amountByLock;
        }
        if (amountByLock > 0) {
            token.transfer(msg.sender, amountByLock);
            emit Claimed(msg.sender, amountByLock);
        }
    }

    function calculateUSDTFromBNB(uint256 BNBAmount) public view returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = USDTAddress;

        uint256 usdtAmount = router.getAmountsOut(BNBAmount, path)[1];

        return usdtAmount;
    }

    function deposit() public payable {
        require(msg.value > 0, 'Insufficient amount');
        require(whitelist[msg.sender] == true, "Account is not in whitelist");
        require(!reachedHardCap(), "Hard Cap is already reached");
        uint256 stageIndex = currentStage();
        Stage storage stage = stages[stageIndex];
        uint256 userStages = users[msg.sender].length;
        uint256 stagesAmount = stages.length;
        if (userStages < stagesAmount) {
            for (uint256 i = 0; i < stagesAmount-userStages; i++) {
                users[msg.sender].push(User(0,0));
            }
        }
        User storage userByStageIndex = users[msg.sender][stageIndex];

        uint256 usdtAmount = calculateUSDTFromBNB(msg.value);

        require(usdtAmount >= stage.minDepositInUSDT && usdtAmount <= stage.maxDepositInUSDT, 'Deposited amount is less or grater than allowed range.');

        uint256 tokensAmount = usdtAmount * PRICE_DENOMINATOR / stage.thousandTokensPriceInUSDT;
        uint256 tokensToSend = tokensAmount;

        if (tokensAmount + stage.totalDistributedTokens > stage.hardCapInTokens) {
            tokensToSend = stage.hardCapInTokens - stage.totalDistributedTokens;
            uint256 sendBackBNBAmount = msg.value * (tokensAmount - tokensToSend) / tokensAmount;
            (bool success, ) = msg.sender.call{value: sendBackBNBAmount}("");
            require(success, 'Cant send back bnb');
        }

        stage.totalDistributedTokens += tokensToSend;
        userByStageIndex.totalTokens += tokensToSend;

        emit Deposited(msg.sender, tokensToSend);
    }

    function lockTokens(uint256 lockIndex, address account, uint256 amount) public onlyOwner {
        Lock storage  lock = locks[lockIndex];
        uint256 lockerLocks = lockers[account].length;
        uint256 locksAmount = locks.length;
        if (lockerLocks < locksAmount) {
            for (uint256 i = 0; i < locksAmount-lockerLocks; i++) {
                lockers[account].push(Locker(0,0));
            }
        }
        Locker storage lockerByLockIndex = lockers[account][lockIndex];

        lock.totalLockedTokens += amount;
        lockerByLockIndex.totalTokens += amount;
        emit Locked(lockIndex, account, amount);
    }

    function setListed(uint256 _timestamp) external onlyOwner {
        require(stages[0].endTimestamp != 0, "Sales not started");
        require(currentStage() == 3, "Presale not finished");
        isListed = true;
        if (_timestamp < block.timestamp) {
            _timestamp = block.timestamp;
        }
        tgeTimestamp = _timestamp;
        emit Listed(tgeTimestamp);
    }

    function releaseFunds(uint256 bnbAmount) external onlyOwner {
        if (bnbAmount == 0) {
            bnbAmount = address(this).balance;
        }

        require(bnbAmount > 0, "Insufficient amount");
        (bool success, ) = msg.sender.call{value: bnbAmount}("");
        require(success, 'Cant release');
    }

    function lockedTokensAmount() public view returns(uint256) {
        uint256 result;
        for (uint256 i = 0; i < locks.length; i++) {
            result += locks[i].totalLockedTokens - locks[i].totalClaimed;
        }
        return result;
    }

    function releaseTokens(uint256 tokensAmount) external onlyOwner {
        uint256 locked = lockedTokensAmount();
        uint256 balance = token.balanceOf(address(this));
        uint256 releasable = locked < balance ? (balance - locked) : 0;

        if (tokensAmount == 0 || tokensAmount > releasable) {
            tokensAmount = releasable;
        }

        require(tokensAmount > 0, "Insufficient amount");
        token.transfer(msg.sender, tokensAmount);
    }

    function addWhiteList(address payable _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeWhiteList(address payable _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function addWhiteListMulti(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeWhiteListMulti(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(IERC20(tokenAddress) != token, "Can't recover sale token");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    // usdt decimals needed
    function setMinDepositAmount(uint256 stageIndex, uint256 usdtAmount) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(usdtAmount < stage.maxDepositInUSDT, "Min value should be less than max value");
        emit UpdateMinDepositAmount(stageIndex, stage.minDepositInUSDT, usdtAmount);
        stage.minDepositInUSDT = usdtAmount;
    }

    function setMaxDepositAmount(uint256 stageIndex, uint256 usdtAmount) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(usdtAmount > stage.minDepositInUSDT, "Max value should be greater than min value");
        emit UpdateMinDepositAmount(stageIndex, stage.maxDepositInUSDT, usdtAmount);
        stage.maxDepositInUSDT = usdtAmount;
    }

    function setThousandTokensPriceInUSDT(uint256 stageIndex, uint256 usdtAmountForThousandTokens) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(usdtAmountForThousandTokens > 0, "USDT amount should be greater than zero");
        emit UpdateThousandTokensPriceInUSDT(stageIndex, stage.thousandTokensPriceInUSDT, usdtAmountForThousandTokens);
        stage.thousandTokensPriceInUSDT = usdtAmountForThousandTokens;
    }

    function setHardCapInTokens(uint256 stageIndex, uint256 tokensAmount) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(stage.totalDistributedTokens <= tokensAmount, "Hard cap should be greater");
        emit UpdateHardCapInTokens(stageIndex, stage.hardCapInTokens, tokensAmount);
        stage.hardCapInTokens = tokensAmount;
    }

    function setSaleTime(uint256 stageIndex, uint256 start, uint256 end) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(start < end && start > 0 && end > block.timestamp);

        if (start < block.timestamp) {
            start = block.timestamp;
        }

        emit UpdateSaleTime(stageIndex, stage.startTimestamp, stage.endTimestamp, start, end);
        stage.startTimestamp = start;
        stage.endTimestamp = end;
    }

    // 100% == 10000
    function setFirstReleasePercent(uint256 stageIndex, uint256 percent) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(percent <= DENOMINATOR, "Percent should be less(equal) than 100");
        emit UpdateFirstReleasePercent(stageIndex, stage.firstReleasePercent, percent);
        stage.firstReleasePercent = percent;
    }

    function setClaimConditions(uint256 stageIndex, uint256 minPeriod, uint256 percentPerPeriod, uint256 offsetTime) external onlyOwner {
        Stage storage stage = stages[stageIndex];
        require(minPeriod > 0 && percentPerPeriod > 0);

        emit UpdateClaimConditions(stageIndex,
            stage.minPeriod, stage.percentPerPeriod, stage.offsetTime,
            minPeriod, percentPerPeriod, offsetTime);

        stage.minPeriod = minPeriod;
        stage.percentPerPeriod = percentPerPeriod;
        stage.offsetTime = offsetTime;
    }


    event UpdateMinDepositAmount(uint256 stageIndex, uint256 oldValue, uint256 newValue);
    event UpdateMaxDepositAmount(uint256 stageIndex, uint256 oldValue, uint256 newValue);
    event UpdateThousandTokensPriceInUSDT(uint256 stageIndex, uint256 oldValue, uint256 newValue);
    event UpdateHardCapInTokens(uint256 stageIndex, uint256 oldValue, uint256 newValue);
    event UpdateSaleTime(uint256 stageIndex, uint256 oldStart, uint256 oldEnd, uint256 newStart, uint256 newEnd);
    event UpdateFirstReleasePercent(uint256 stageIndex, uint256 oldPercent, uint256 newPercent);
    event UpdateClaimConditions(uint256 stageIndex,
        uint256 oldMinPeriod, uint256 oldPercentPerPeriod, uint256 oldOffsetTime,
        uint256 minPeriod, uint256 percentPerPeriod, uint256 offsetTime);
    event Deposited(address indexed user, uint256 usdtAmount);
    event Locked(uint256 lockIndex,address indexed account, uint256 amount);
    event SendBack(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event Claimed(address account, uint256 amount);
    event Listed(uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}