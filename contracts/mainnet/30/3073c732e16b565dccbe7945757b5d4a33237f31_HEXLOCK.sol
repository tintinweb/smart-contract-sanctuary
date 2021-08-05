//HEXLOCK.sol
//
//

pragma solidity ^0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./HEX.sol";

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////
contract Events {

//when a user starts staking
    event StakeStarted(
        uint heartValue,
        uint indexed dayLength,
        uint hexStakeId
    );

//when a user ends stake
    event StakeEnded(
        uint heartValue,
        uint stakeProfit,
        uint indexed dayLength,
        uint hexStakeId
    );

}

contract TokenEvents {

//when a user locks tokens
    event TokenLock(
        address indexed user,
        uint value
    );

//when a user unlocks tokens
    event TokenUnlock(
        address indexed user,
        uint value
    );
}

//////////////////////////////////////
//////////LOCK TOKEN CONTRACT////////
////////////////////////////////////
contract LOCK is IERC20, TokenEvents{

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 internal _totalSupply;
    string public constant name = "HEXLOCK";
    string public constant symbol = "LOCK";
    uint public constant decimals = 8;

    //LOCKING
    uint public totalLocked;
    mapping (address => uint) public tokenLockedBalances;//balance of LOCK locked mapped by user

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) override public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) override public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) override public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) override public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
          _totalSupply = _totalSupply.add(amount);
          _balances[account] = _balances[account].add(amount);
          emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);//from address(0) for minting

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //mint LOCK to msg.sender
    function mintLock(uint hearts)
        internal
        returns(bool)
    {
        uint amt = hearts.div(1000);
        address minter = msg.sender;
        _mint(minter, amt);//mint LOCK
        return true;
    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - LOCK CONTROL//////////
    //////////////////////////////////////////////////////

    //lock LOCK tokens to contract
    function LockTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(tokenBalance() >= amt, "Error: insufficient balance");//ensure user has enough funds
        tokenLockedBalances[msg.sender] = tokenLockedBalances[msg.sender].add(amt);
        totalLocked = totalLocked.add(amt);
        _transfer(msg.sender, address(this), amt);//make transfer
        emit TokenLock(msg.sender, amt);
    }

    //unlock LOCK tokens from contract
    function UnlockTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(tokenLockedBalances[msg.sender] >= amt,"Error: unsufficient frozen balance");//ensure user has enough locked funds
        tokenLockedBalances[msg.sender] = tokenLockedBalances[msg.sender].sub(amt);//update balances
        totalLocked = totalLocked.sub(amt);
        _transfer(address(this), msg.sender, amt);//make transfer
        emit TokenUnlock(msg.sender, amt);
    }

    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //total LOCK frozen in contract
    function totalLockedTokenBalance()
        public
        view
        returns (uint256)
    {
        return totalLocked;
    }

    //LOCK balance of caller
    function tokenBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }
}

contract HEXLOCK is LOCK, Events {

    ///////////////////////////////////////////////////////////////////////
    ////////////////////////////////CONTRACT SETUP///////////////////////
    ////////////////////////////////////////////////////////////////////
    using SafeMath for uint256;

    HEX hexInterface;

    //HEXLOCK
    address payable constant hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;

    address payable devAddress;//set in constructor
    address payable devAddress2 = 0xD30BC4859A79852157211E6db19dE159673a67E2;
    uint constant fee = 1000; //0.1%;
    uint constant devFee = 2; // 50% of 0.1% @ 0.05%;
    uint constant refFee = 2; // 50% of 0.1% @ 0.05%
    
    uint public last_stake_id;// stake id
    uint public userCount; 
    uint public lifetimeHeartsStaked;
    
    mapping (address => UserInfo) public users;
    mapping (uint => StakeInfo) public stakes;
    mapping (address => uint[]) internal userStakeIds;

    bool locked;

    struct UserInfo {
        uint     totalHeartsStaked;
        address  userAddress;
    }

    struct StakeInfo {
        uint     heartValue;
        uint     dayLength;
        address payable userAddress;
        address payable refferer;
        uint     stakeId;
        uint     hexStakeIndex;
        uint40   hexStakeId;
        bool     isStaking;
        uint256  stakeStartTimestamp;
        uint     stakeValue;
        uint     stakeProfit;
        bool     stakeEnded;
    }

    modifier onlyOwner {
        require(msg.sender == devAddress, "notOwner");
        _;
    }

    modifier canStake(uint hearts) {
        require(hearts > 0, "Error: value must be greater than 0");
        _;
    }

    modifier synchronized {
        require(!locked, "Sync lock");
        locked = true;
        _;
        locked = false;
    }

    constructor() public {
        devAddress = msg.sender;
        hexInterface = HEX(hexAddress);
        mintLock(100000000000000000);
    }

    receive() external payable {
        devAddress.transfer(msg.value);//assume any eth sent to contract as donation.
    }

    ///////////////////////////////////////////////////////////////////////
    ////////////////////////////////HEXLOCK CORE//////////////////////////
    ////////////////////////////////////////////////////////////////////

    //stakes hex - transfers HEX from user to contract - approval needed
    function stakeHex(uint hearts, uint dayLength, address payable ref)
        internal
        returns(bool)
    {
        //send
        require(hexInterface.transferFrom(msg.sender, address(this), hearts), "Transfer failed");//send hex from user to contract
        //user info
        updateUserData(hearts);
        //stake HEX
        hexInterface.stakeStart(hearts, dayLength);
        //get the most recent stakeIndex
        uint hexStakeIndex = hexInterface.stakeCount(address(this)).sub(1);
        //update stake info
        updateStakeData(hearts, dayLength, ref, hexStakeIndex);
        //mint bonus LOCK tokens relative to HEX amount and stake length (stake for more than 20 days and get larger bonus)
        if(dayLength < 10){
            dayLength = 10;
        }
        require(mintLock(hearts * (dayLength / 10)), "Error: could not mint tokens");
        return true;
    }


    //end a stake - cannot emergency unstake
    function endStake(uint stakeId)
        internal
        returns (bool)
    {
        require(stakeId <= last_stake_id, "Error: stakeId out of range");
        StakeInfo storage stake = stakes[stakeId];
        require(stake.userAddress == msg.sender, "cannot end another users stake. If this was intentional, use the HEX good accounting function.");
        require(!stake.stakeEnded, "Stake has already been ended");
        require(stake.heartValue > 0, "Stake has either already ended, or does not exist");
        require(isStakeFinished(stakeId), "Error: cannot early unstake");

        uint256 oldBalance = getContractBalance();
        //find the stake index then
        //end stake
        hexInterface.stakeEnd(getStakeIndexById(address(this), stake.hexStakeId), stake.hexStakeId);
        stake.isStaking = false;
        stake.stakeEnded = true;
        //calc stakeValue and stakeProfit
        uint256 stakeValue = getContractBalance().sub(oldBalance);
        uint _fee; 
        uint _devFee;
        uint _refFee;
        uint _profit;
        uint _principal;
        if(stakeValue < stake.heartValue)//late penalties cut into principal
        {
            stake.stakeValue = stakeValue;//remaining principal
            stake.stakeProfit = 0;//interest
            //calc fee from remaining principal
            _fee = stakeValue.div(fee);
            _devFee = _fee.div(devFee);
            _refFee = _fee.div(refFee);
            _profit = 0;
            _principal = stakeValue.sub(_fee);//sub fee from remaining principal
        }
        else{
            stake.stakeValue = stakeValue;//principal + interest
            stake.stakeProfit = stakeValue.sub(stake.heartValue);//interest
            //calc fee from staking interest
            _fee = stake.stakeProfit.div(fee);
            _devFee = _fee.div(devFee);
            _refFee = _fee.div(refFee);
            _profit = stake.stakeProfit.sub(_fee);//sub fee from interest profit
            _principal = stake.heartValue;
        }
        if(stake.refferer == address(0)){//no ref
            require(hexInterface.transfer(devAddress, _refFee), "Dev transfer failed");//send hex to dev
        }
        else{//ref
            require(hexInterface.transfer(stake.refferer, _refFee), "Ref transfer failed");//send hex to refferer
        }
        uint dFee = _devFee.mul(9).div(10);//90% of 0.05%
        require(hexInterface.transfer(devAddress, dFee), "Dev transfer failed");//send hex to dev
        require(hexInterface.transfer(devAddress2, _devFee.sub(dFee)), "Dev transfer failed");//send hex to dev2
        require(hexInterface.transfer(msg.sender, _principal.add(_profit)), "Transfer failed");//transfer funds to user endstake
        emit StakeEnded(
            stake.stakeProfit,
            stake.heartValue,
            stake.dayLength,
            stake.hexStakeId
        );
        stake.heartValue = 0;
        return true;
    }

    //updates user data
    function updateUserData(uint hearts)
        internal
    {
        UserInfo storage user = users[msg.sender];
        lifetimeHeartsStaked += hearts;
        if(user.totalHeartsStaked == 0){
            userCount++;
        }
        user.totalHeartsStaked = user.totalHeartsStaked.add(hearts);//total amount of hearts staked by this user after fees
        user.userAddress = msg.sender;
    }

    //updates stake data
    function updateStakeData(uint hearts, uint dayLength, address payable ref, uint index)
        internal
    {
        uint _stakeId = _next_stake_id();//new stake id
        userStakeIds[msg.sender].push(_stakeId);//update userStakeIds
        StakeInfo memory stake;
        stake.heartValue = hearts;//amount of hearts staked
        stake.dayLength = dayLength;//length of days staked
        stake.userAddress = msg.sender;//staker
        stake.refferer = ref;//referrer
        stake.hexStakeIndex = index;//hex contract stakeIndex
        SStore memory _stake = getStakeByIndex(address(this), stake.hexStakeIndex); //get stake from address and stakeindex
        stake.hexStakeId = _stake.stakeId;//hex contract stake id
        stake.stakeId = _stakeId;//hexlock contract stake id
        stake.stakeStartTimestamp = now;//timestamp stake started
        stake.isStaking = true;//stake is now staking
        stakes[_stakeId] = stake;//update data
        emit StakeStarted(
            hearts,
            dayLength,
            stake.hexStakeId
        );
    }

    //get next stake id
    function _next_stake_id()
        internal
        returns (uint)
    {
        last_stake_id++;
        return last_stake_id;
    }

    //////////////////////////////////////////////////////////////////
    ////////////////////////PUBLIC FACING HEXLOCK////////////////////
    ////////////////////////////////////////////////////////////////

    //stake HEX
    function StakeHex(uint _hearts, uint _dayLength, address payable _ref)
        public
        canStake(_hearts)
        synchronized
    {
        require(stakeHex(_hearts, _dayLength, _ref), "Error: could not stake");
    }

    //ends a stake then returns HEX + interest to msg.sender
    function EndStake(uint _stakeId)
        public
        synchronized
    {
        require(endStake(_stakeId), "Error: could not endstake");
    }


    //////////////////////////////////////////
    ////////////VIEW ONLY/////////////////////
    //////////////////////////////////////////


    //
    function isStaking(uint _stakeId)
        public
        view
        returns(bool)
    {
        return stakes[_stakeId].isStaking;
    }

    //
    function isStakeFinished(uint _stakeId)
        public
        view
        returns(bool)
    {
        //add 1 to staking dayLength to account for stake pending time
        return stakes[_stakeId].stakeStartTimestamp.add((stakes[_stakeId].dayLength.add(1)).mul(86400)) <= now;
    }

    //
    function isStakeEnded(uint _stakeId)
        public
        view
        returns(bool)
    {
        return stakes[_stakeId].stakeEnded;
    }

    //general user info
    function getUserInfo(address addr)
        public
        view
        returns(
        uint    totalHeartsStaked,
        uint[] memory _stakeIds,
        address userAddress
        )
    {
        return(users[addr].totalHeartsStaked, userStakeIds[addr], users[addr].userAddress);
    }

    //general stake info
    function getStakeInfo(uint stakeId)
        public
        view
        returns(
        uint     heartValue,
        uint     stakeDayLength,
        uint     hexStakeId,
        uint     hexStakeIndex,
        address payable userAddress,
        address payable refferer,
        uint    stakeStartTimestamp
        )
    {
        return(stakes[stakeId].heartValue, stakes[stakeId].dayLength, stakes[stakeId].hexStakeId, stakes[stakeId].hexStakeIndex, stakes[stakeId].userAddress, stakes[stakeId].refferer, stakes[stakeId].stakeStartTimestamp);
    }

    //returns amount of users by address to ever stake via the contract
    function getUserCount()
        public
        view
        returns(uint)
    {
        return userCount;
    }

    //returns contract HEX balance
    function getContractBalance()
        public
        view
        returns(uint)
    {
        return hexInterface.balanceOf(address(this));
    }

    ///////////////////////////////////////////////
    ///////////////////HEX UTILS///////////////////
    ///////////////////////////////////////////////
    //credits to kyle bahr @ https://gist.github.com/kbahr/80e61ab761053849f7fdc6226b85a354

    struct SStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    struct DailyDataCache {
        uint256 dayPayoutTotal;
        uint256 dayStakeSharesTotal;
        uint256 dayUnclaimedSatoshisTotal;
    }
    uint256 private constant HEARTS_UINT_SHIFT = 72;
    uint256 private constant HEARTS_MASK = (1 << HEARTS_UINT_SHIFT) - 1;
    uint256 private constant SATS_UINT_SHIFT = 56;
    uint256 private constant SATS_MASK = (1 << SATS_UINT_SHIFT) - 1;

    function decodeDailyData(uint256 encDay)
    private
    pure
    returns (DailyDataCache memory)
    {
        uint256 v = encDay;
        uint256 payout = v & HEARTS_MASK;
        v = v >> HEARTS_UINT_SHIFT;
        uint256 shares = v & HEARTS_MASK;
        v = v >> HEARTS_UINT_SHIFT;
        uint256 sats = v & SATS_MASK;
        return DailyDataCache(payout, shares, sats);
    }

    function interestForRange(DailyDataCache[] memory dailyData, uint256 myShares)
    private
    pure
    returns (uint256)
    {
        uint256 len = dailyData.length;
        uint256 total = 0;
        for(uint256 i = 0; i < len; i++){
            total += interestForDay(dailyData[i], myShares);
        }
        return total;
    }

    function interestForDay(DailyDataCache memory dayObj, uint256 myShares)
    private
    pure
    returns (uint256)
    {
        return myShares * dayObj.dayPayoutTotal / dayObj.dayStakeSharesTotal;
    }

    function getDataRange(uint256 b, uint256 e)
    private
    view
    returns (DailyDataCache[] memory)
    {
        uint256[] memory dataRange = hexInterface.dailyDataRange(b, e);
        uint256 len = dataRange.length;
        DailyDataCache[] memory data = new DailyDataCache[](len);
        for(uint256 i = 0; i < len; i++){
            data[i] = decodeDailyData(dataRange[i]);
        }
        return data;
    }

    function getLastDataDay()
    private
    view
    returns(uint256)
    {
        uint256[13] memory globalInfo = hexInterface.globalInfo();
        uint256 lastDay = globalInfo[4];
        return lastDay;
    }

    function getInterestByStake(SStore memory s)
    private
    view
    returns (uint256)
    {
        uint256 b = s.lockedDay;
        uint256 e = getLastDataDay(); // ostensibly "today"

        if (b >= e) {
            //not started - error
            return 0;
        } else {
            DailyDataCache[] memory data = getDataRange(b, e);
            return interestForRange(data, s.stakeShares);
        }
    }

    function getInterestByStakeId(address addr, uint40 stakeId)
    public
    view
    returns (uint256)
    {
        SStore memory s = getStakeByStakeId(addr, stakeId);

        return getInterestByStake(s);
    }

    function getTotalValueByStakeId(address addr, uint40 stakeId)
    public
    view
    returns (uint256)
    {
        SStore memory stake = getStakeByStakeId(addr, stakeId);

        uint256 interest = getInterestByStake(stake);
        return stake.stakedHearts + interest;
    }

    function getStakeByIndex(address addr, uint256 idx)
    private
    view
    returns (SStore memory)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;

        (stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake) = hexInterface.stakeLists(addr, idx);

        return SStore(stakeId,
                        stakedHearts,
                        stakeShares,
                        lockedDay,
                        stakedDays,
                        unlockedDay,
                        isAutoStake);
    }

    function getStakeByStakeId(address addr, uint40 sid)
    private
    view
    returns (SStore memory)
    {

        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;

        uint256 stakeCount = hexInterface.stakeCount(addr);
        for(uint256 i = 0; i < stakeCount; i++){
            (stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake) = hexInterface.stakeLists(addr, i);

            if(stakeId == sid){
                return SStore(stakeId,
                                stakedHearts,
                                stakeShares,
                                lockedDay,
                                stakedDays,
                                unlockedDay,
                                isAutoStake);
            }
        }
    }

    function getStakeIndexById(address addr, uint40 sid)
        private
        view
        returns (uint)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;

        uint256 stakeCount = hexInterface.stakeCount(addr);
        for(uint256 i = 0; i < stakeCount; i++){
            (stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake) = hexInterface.stakeLists(addr, i);

            if(stakeId == sid){
                return i;
            }
        }
    }
}
