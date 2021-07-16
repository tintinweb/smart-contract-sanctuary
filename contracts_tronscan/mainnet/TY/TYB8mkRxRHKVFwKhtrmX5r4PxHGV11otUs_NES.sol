//SourceUnit: NES-FINAL.sol

pragma solidity 0.5.10;
/*
*Copyright NES Tokens
*Any unauthorized use of copy this contract is subject to local and federal copyright laws.
*/

contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}
interface TRC20 {
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
        // Solidity only automatically asserts when dividing by 0
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
contract ERC20 is Context, TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 5000000 * (10 ** 8);

    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract GlobalsAndUtility is ERC20 {

    /*  XfLobbyEnter
    */
    event XfLobbyEnter(
        uint256 timestamp,
        uint256 EnterDay,
        uint256 indexed entryIndex,
        uint256 indexed rawAmount
    );

    /*  XfLobbyExit 
    */
    event XfLobbyExit(
        uint256 timestamp,
        uint256 EnterDay,
        uint256 indexed entryIndex,
        uint256 indexed xfAmount,
        address indexed referrerAddr
    );

    /*  DailyDataUpdate
    */
    event DailyDataUpdate(
        address indexed updaterAddr,
        uint256 timestamp,
        uint256 beginDay,
        uint256 endDay
    );

    /*  StakeStart
    */
    event StakeStart(
        uint40 indexed stakeId,
        address indexed stakerAddr,
        uint256 stakedSuns,
        uint256 stakedDays
    );
    
    /*  StakeEnd 
    */
    event StakeEnd(
        uint40 indexed stakeId,
        address indexed stakerAddr,
        uint256 lockedDay,
        uint256 servedDays,
        uint256 stakedSuns,
        uint256 dividends,
        uint256 penalty,
        uint256 stakeReturn
    );

    /*Constructor Addresses and Launch Time */
    address payable internal constant FLUSH_ADDR = 0x9CeC5AF3C786cf15E2AC590EE67AF0ddCebBC7A8;
    uint256 LAUNCH_TIME;
    uint256 CURRENT_DAY = 0;

    uint8 internal LAST_FLUSHED_DAY = 1;
    uint256 internal NEXT_DAY_UPDATE = 1;

    uint256 public bigDay = 0;
    uint256 internal bigCycle = 1;

    /* ERC20 constants */
    string public constant name = "New Era Staking";
    string public constant symbol = "NES";
    uint8 public constant decimals = 8;

    /* auction stuff */
    uint256 internal constant PRE_CLAIM_DAYS = 1;
    uint256 internal constant CLAIM_STARTING_AMOUNT = 100000 * (10 ** 8);
    uint256 internal constant CLAIM_LOWEST_AMOUNT = 10000* (10 ** 8);
    uint256 internal constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS;

    uint256 internal constant XF_LOBBY_DAY_WORDS = ((1 + (50 * 7)) + 255) >> 8;

    /* Stake timings */
    uint256 internal constant MIN_STAKE_DAYS = 1;

    uint256 internal constant MAX_STAKE_DAYS = 30;
	
    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        uint256 _stakePenaltyTotal;
        uint256 _dailyDataCount;
        uint40 _latestStakeId;
        uint256 _currentDay;
    }

    struct GlobalsStore {
        uint72 stakePenaltyTotal;
        uint16 dailyDataCount;
        uint40 latestStakeId;
    }

    GlobalsStore public globals;

    /* Daily data */
    struct DailyDataStore {
		uint256 activeStakesEarningDivsToday;
        uint256 dayDividends;
		uint256 newStakesAddedToTomorrow;
        uint256 endedStakesRemovedFromTomorrow;
        uint256 bigDayDivsAddedToday;
        uint256 bigDayCycle;
		uint256 manualUserAdditionsToBigDay;
		bool isTodayUpdated;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _stakedSuns;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
    }

    struct StakeStore {
        uint40 stakeId;
        uint256 stakedSuns;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }

    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }

    mapping(uint256 => uint256) public xfLobby;
    mapping(uint256 => mapping(address => XfLobbyQueueStore)) public xfLobbyMembers;

    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * @return Fixed array of values
     */
    function globalInfo()
        external
        view
        returns (uint256[7] memory)
    {

        return [
            globals.stakePenaltyTotal,
            globals.dailyDataCount,
            globals.latestStakeId,
            block.timestamp,
            totalSupply(),
			_currentDay(),
            xfLobby[_currentDay()]
        ];
    }
    function allocatedSupply()
        external
        view
        returns (uint256)
    {
        return totalSupply() + dailyData[_currentDay()].activeStakesEarningDivsToday;
    }
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }
    function _currentDay()
        internal
        view
        returns (uint256)
    {
        if (block.timestamp < LAUNCH_TIME){	
             return 0;	
        }else{	
             return (block.timestamp - LAUNCH_TIME) / 1 days;	
        }
    }
	
    function _dailyDataUpdateAuto(GlobalsCache memory g)
        internal
    {
        _dailyDataUpdate(g, _currentDay());
    }
	
    function _dailyDataUpdate(GlobalsCache memory g, uint256 today)
        private
    {
        if (dailyData[today].isTodayUpdated == true) {
            /* Already up-to-date */
            return;
        }else{
			for(uint256 i = NEXT_DAY_UPDATE; i <= today; i++){
				dailyData[i].activeStakesEarningDivsToday += dailyData[i-1].activeStakesEarningDivsToday;
				if(dailyData[i-1].endedStakesRemovedFromTomorrow > 0)
					dailyData[i].activeStakesEarningDivsToday -= dailyData[i-1].endedStakesRemovedFromTomorrow;
				bigDayCalc(i);
				dailyData[i].isTodayUpdated = true;
			}
			
			emit DailyDataUpdate(
				msg.sender,
				block.timestamp,
				g._dailyDataCount, 
				today
			);
			NEXT_DAY_UPDATE = today+1;
			g._dailyDataCount = today;
		}
    }
	
	function bigDayCalc(uint256 day)
		internal
	{
			uint256 cycle = ((day-1) / 3);
			
			if(cycle >= bigCycle){
				dailyData[day-1].dayDividends += bigDay;
				dailyData[day-1].bigDayDivsAddedToday = bigDay;
				bigDay = 0;
				bigCycle++;
			}
			dailyData[day].bigDayCycle = bigCycle;
	}
	
    function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        view
    {
        g._stakePenaltyTotal = globals.stakePenaltyTotal;
        g._dailyDataCount = globals.dailyDataCount;
        g._latestStakeId = globals.latestStakeId;

        _globalsCacheSnapshot(g, gSnapshot);
    }

    function _globalsCacheSnapshot(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
        pure
    {
        gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
        gSnapshot._dailyDataCount = g._dailyDataCount;
        gSnapshot._latestStakeId = g._latestStakeId;
    }

    function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot)
        internal
    {
        if (g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal) {
            globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
        }
        if (g._dailyDataCount != gSnapshot._dailyDataCount
            || g._latestStakeId != gSnapshot._latestStakeId) {
            globals.dailyDataCount = uint16(g._dailyDataCount);
            globals.latestStakeId = g._latestStakeId;
        }
    }

    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st)
        internal
        view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "NES: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._stakedSuns = stRef.stakedSuns;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
    }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
        internal
    {
        stRef.stakeId = st._stakeId;
        stRef.stakedSuns = st._stakedSuns;
        stRef.lockedDay = uint16(st._lockedDay);
        stRef.stakedDays = uint16(st._stakedDays);
        stRef.unlockedDay = uint16(st._unlockedDay);
    }

    function _stakeAdd(
        StakeStore[] storage stakeListRef,
        uint40 newStakeId,
        uint256 newStakedSuns,
        uint256 newLockedDay,
        uint256 newStakedDays
    )
        internal
    {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                newStakedSuns,
                uint16(newLockedDay),
                uint16(newStakedDays),
                uint16(0) // unlockedDay
            )
        );
    }
    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }

        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }
}

contract StakeableToken is GlobalsAndUtility {
    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedSuns Number of Suns to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedSuns, uint256 newStakedDays)
        external
    {
		require(_currentDay() > 1, "NES: Cannot start stake on day zero or day one.");
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Enforce the minimum stake time */
        require(newStakedDays >= MIN_STAKE_DAYS, "NES: newStakedDays lower than minimum");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        _stakeStart(g, newStakedSuns, newStakedDays);

        /* Remove staked Suns from balance of staker */
        _burn(msg.sender, newStakedSuns);

        _globalsSync(g, gSnapshot);
    }
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        StakeStore[] storage stakeListRef = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "NES: Empty stake list");
        require(stakeIndex < stakeListRef.length, "NES: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        uint256 servedDays = 0;
        uint256 stakeReturn = 0;
        uint256 dividends = 0;
        uint256 penalty = 0;

        if (_currentDay() >= st._lockedDay) { //currentDay >= lockedDay means not a same day cancellation

			st._unlockedDay = _currentDay();
			servedDays = _currentDay() - st._lockedDay;
			if (servedDays > st._stakedDays) {
				servedDays = st._stakedDays;
			}
			(stakeReturn, dividends, penalty) = _stakePerformance(g, st, servedDays, false);
			if(dividends > 0)
				msg.sender.transfer(dividends);
				
        }else
			(stakeReturn, dividends, penalty) = _stakePerformance(g, st, servedDays, true);

        emit StakeEnd(
            stakeIdParam, 
            msg.sender,
            st._lockedDay,
            servedDays, 
            st._stakedSuns, 
            dividends,
            penalty,
            stakeReturn
        );

        if (penalty != 0) { //add penalty to bigDay pot
			bigDay += penalty; //add penalalized divs to current bigDay
            g._stakePenaltyTotal += penalty;
        }

        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);
        }
			
        _stakeRemove(stakeListRef, stakeIndex);

        _globalsSync(g, gSnapshot);
    }
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return stakeLists[stakerAddr].length;
    }
    function _stakeStart(
        GlobalsCache memory g,
        uint256 newStakedSuns,
        uint256 newStakedDays
    )
        internal
    {
        /* Enforce the maximum stake time */
        require(newStakedDays <= MAX_STAKE_DAYS, "NES: newStakedDays higher than maximum");

        /* Ensure newStakedSuns is more than zero*/
        require(newStakedSuns > 0, "NES: Must be more than 0");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newLockedDay = _currentDay() + 1;
		uint256 lastDay = newLockedDay + newStakedDays - 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId;
        _stakeAdd(
            stakeLists[msg.sender],
            newStakeId,
            newStakedSuns,
            newLockedDay,
            newStakedDays
        );

        emit StakeStart(
            newStakeId, 
            msg.sender,
            newStakedSuns, 
            newStakedDays
        );
        /* Track day's new staked Suns for div calculations */
		dailyData[_currentDay()].newStakesAddedToTomorrow += newStakedSuns;
		dailyData[_currentDay() + 1].activeStakesEarningDivsToday += newStakedSuns;
		dailyData[lastDay].endedStakesRemovedFromTomorrow += newStakedSuns;
    }
    function _calcDividends(
        uint256 beginDay,
        uint256 endDay,
		uint256 stakedSuns
    )
        private
        view
        returns (uint256 payout)
    {

		payout = 0;

        for (uint256 day = beginDay; day < endDay; day++) {

            /* 90% of the day's dividends go to stakers. 5% goes to dev fund, 5% to "big day" */
			payout += ( ( ( (dailyData[day].dayDividends * stakedSuns) / dailyData[day].activeStakesEarningDivsToday) * 90) / 100); //90%
        }

        return payout;
    }
    function _stakePerformance(GlobalsCache memory g, StakeCache memory st, uint256 servedDays, bool sameDayCancellation)
        private
        returns (uint256 stakeReturn, uint256 dividends, uint256 penalty)
    {
		uint256 lastDay = st._lockedDay + st._stakedDays - 1;
        if(servedDays < st._stakedDays){
			if(sameDayCancellation){
				dailyData[lastDay].endedStakesRemovedFromTomorrow -= st._stakedSuns;
				dailyData[_currentDay()].newStakesAddedToTomorrow -= st._stakedSuns;
				dailyData[_currentDay()+1].activeStakesEarningDivsToday -= st._stakedSuns;

				return (st._stakedSuns, 0, 0);		//no burn for same day cancellations
			}else{
				stakeReturn = st._stakedSuns / 5; 			//80% burn, same burn as full 30 day stake completion.	
				dividends = _calcDividends(st._lockedDay, st._lockedDay + servedDays, st._stakedSuns);
				dailyData[lastDay].endedStakesRemovedFromTomorrow -=  st._stakedSuns;
				dailyData[_currentDay()].activeStakesEarningDivsToday -= st._stakedSuns;
			}
        }else{
            dividends = _calcDividends(st._lockedDay, st._lockedDay + servedDays, st._stakedSuns);
            stakeReturn = ((st._stakedSuns * 4) / 5) - ( (servedDays * st._stakedSuns * 2) / 100); 		//20% intial burn + 2% burn per day staked
        }
		
		/*
		* if user is more than 3 days late collecting their ended stake, then upon collection
		* 	20% of their divs will be penalized and put into the current "big day"
		*/
		if(_currentDay() > lastDay + 1)
			if( (_currentDay() - lastDay + 1) > 3){
				penalty = dividends / 5;
				dividends = (dividends * 4) /5;
			}else 
				penalty = 0;

        return (stakeReturn, dividends, penalty);
    }

}


/** 
    Contract for the Auction Functionality.
*/

contract TransformableToken is StakeableToken {
    function xfLobbyEnter(address referrerAddr)
        external
        payable
    {
		require(_currentDay() > 0, "NUI: Auction has not begun yet");

        uint256 enterDay = _currentDay();

        uint256 rawAmount = msg.value;
        require(rawAmount != 0, "NUI: Amount required");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

        uint256 entryIndex = qRef.tailIndex++;

        qRef.entries[entryIndex] = XfLobbyEntryStore(uint96(rawAmount), referrerAddr);

        xfLobby[enterDay] += rawAmount;

        emit XfLobbyEnter(
            block.timestamp, 
            enterDay, 
            entryIndex, 
            rawAmount
        );
		
		if(LAST_FLUSHED_DAY < enterDay){
			_shareSend();
		}
		if(enterDay > 2){
			bigDay += (rawAmount * 5) / 100;
		}
			
		dailyData[enterDay].dayDividends += rawAmount;
		
    }
	function addToBigDay()
		external
		payable
	{
		require(msg.value > 0, "Must be more than 0.");
        require(msg.sender.balance > msg.value, "Not enough TRX ot add to bigDay" );
		uint256 toBigDay = msg.value;
		bigDay += toBigDay;
		dailyData[_currentDay()].manualUserAdditionsToBigDay += toBigDay;
	}
    function xfLobbyExit(uint256 EnterDay, uint256 count)
        external
    {
        require(EnterDay < _currentDay(), "NES: Round is not complete");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[EnterDay][msg.sender];

        uint256 headIndex = qRef.headIndex;
        uint256 endIndex;

        if (count != 0) {
            require(count <= qRef.tailIndex - headIndex, "NES: count invalid");
            endIndex = headIndex + count;
        } else {
            endIndex = qRef.tailIndex;
            require(headIndex < endIndex, "NES: count invalid");
        }

        uint256 waasLobby = _waasLobby(EnterDay);
        uint256 _xfLobby = xfLobby[EnterDay];
        uint256 totalXfAmount = 0;

        do {
            uint256 rawAmount = qRef.entries[headIndex].rawAmount;
            address referrerAddr = qRef.entries[headIndex].referrerAddr;

            delete qRef.entries[headIndex];

            uint256 xfAmount = waasLobby * rawAmount / _xfLobby;

            if (referrerAddr == address(0) || referrerAddr == msg.sender) {
                /* No referrer or Self-referred */
                _emitXfLobbyExit(EnterDay, headIndex, xfAmount, referrerAddr);
            } else {
                /* Referral bonuses*/
                uint256 bonus = (xfAmount * 5) / 100; //5% bonus for using ref
                uint256 referrerBonus = (xfAmount * 15) / 100; //15% bonus of referred's token collection
				
                xfAmount += bonus;

                _emitXfLobbyExit(EnterDay, headIndex, xfAmount, referrerAddr);
                _mint(referrerAddr, referrerBonus);
            }

            totalXfAmount += xfAmount;
        } while (++headIndex < endIndex);

        qRef.headIndex = uint40(headIndex);

        if (totalXfAmount != 0) {
            _mint(msg.sender, totalXfAmount);
        }
		if(LAST_FLUSHED_DAY < _currentDay()){
			_shareSend();
		}
    }
    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list)
    {
        require(
            beginDay < endDay && endDay <= _currentDay(),
            "NES: invalid range"
        );

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            list[dst++] = uint256(xfLobby[src++]);
        } while (src < endDay);

        return list;
    }
    function _shareSend() private
    {
         GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        
        require(address(this).balance != 0, "NUI: No value");
        require(LAST_FLUSHED_DAY < _currentDay(), "NUI: Invalid day");
		
         _dailyDataUpdateAuto(g);
		
		if(LAST_FLUSHED_DAY > 2){ //day 1 and 2 are special
			FLUSH_ADDR.transfer((dailyData[LAST_FLUSHED_DAY].dayDividends * 5) / 100);
		}else{ //day 1 and 2 50% mods
			FLUSH_ADDR.transfer((dailyData[LAST_FLUSHED_DAY].dayDividends * 50) / 100);
			bigDay += (dailyData[LAST_FLUSHED_DAY].dayDividends * 50) / 100;
		}
		
        LAST_FLUSHED_DAY++;
        _globalsSync(g, gSnapshot);
    }
	
	function shareSend() external{
		_shareSend();
	}
    function xfLobbyEntry(address memberAddr, uint256 EnterDay, uint256 entryIndex)
        external
        view
        returns (uint256 rawAmount, address referrerAddr)
    {
        XfLobbyEntryStore storage entry = xfLobbyMembers[EnterDay][memberAddr].entries[entryIndex];

        require(entry.rawAmount != 0, "NES: Param invalid");

        return (entry.rawAmount, entry.referrerAddr);
    }
    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[XF_LOBBY_DAY_WORDS] memory words)
    {
        uint256 day = _currentDay() + 1;

        while (day-- != 0) {
            if (xfLobbyMembers[day][memberAddr].tailIndex > xfLobbyMembers[day][memberAddr].headIndex) {
                words[day >> 8] |= 1 << (day & 255);
            }
        }

        return words;
    }   
    // Can be Used at Front End to Calculate the NES pool.
    function _waasLobby(uint256 EnterDay)
        private
        returns (uint256 waasLobby)
    {
        if (EnterDay > 0 && EnterDay <= 45) {                                     
            waasLobby = CLAIM_STARTING_AMOUNT - ( (EnterDay - 1) * 2000 * ( 10 ** 8) );
        } else {
            waasLobby = CLAIM_LOWEST_AMOUNT;
        }

        return waasLobby;
    }
    function _emitXfLobbyExit(uint256 EnterDay, uint256 entryIndex, uint256 xfAmount, address referrerAddr)
        private
    {
        emit XfLobbyExit(block.timestamp, EnterDay, entryIndex, xfAmount, referrerAddr);
    }
}

contract NES is TransformableToken {

     constructor(uint256 _timestamp)
        public
    {
        LAUNCH_TIME = _timestamp;
    }
    function() external payable {}
}