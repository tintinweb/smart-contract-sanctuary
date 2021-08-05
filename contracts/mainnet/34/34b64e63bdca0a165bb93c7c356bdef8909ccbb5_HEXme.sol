/**
 *Submitted for verification at Etherscan.io on 2020-09-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.8;

/*
 *	HEXme.io contract - Get +20% bonus HEX on your ETH to HEX transforms!
 *
 *      _   _  _______   __                 _
 *     | | | ||  ___\ \ / /                (_)
 *     | |_| || |__  \ V / _ __ ___   ___   _  ___
 *     |  _  ||  __| /   \| '_ ` _ \ / _ \ | |/ _ \
 *     | | | || |___/ /^\ \ | | | | |  __/_| | (_) |
 *     \_| |_/\____/\/   \/_| |_| |_|\___(_)_|\___/
 *
 *
 *  HEXme.io is truly & solely built, as a service, on top of the original HEX contract!
 *  That means it only uses HEX original function calls and simply wraps HEX as a service layer.
 *
 *  It enhances the HEX ecosystem and doesn't split it!
 *  Thus we DO NOT use an own obsolete token!
 *  DO NOT trade any token which is not HEX itself, if you want to use the HEX ecosystem,
 *  unless you clearly understand the risk of the actions you are taking!
 *
 *  Verify over trust!
 *
 *  READ COMPLETELY & CAREFULLY BEFORE YOU USE THIS CONTRACT!
 *  THERE IS NO ONE ELSE IN CHARGE OF YOUR ACTIONS THAN YOURSELF!
 *
 *  DISCLAIMER:
 *
 *  Use at your own risk. Verify the code you want to execute.
 *  You are solely responsible for your decisions.
 *  Don't consider things as financial advice, unless they're labeled as such.
 *  Be responsible, take only reasonable risks.
 *  DYOR! - Do your own research!
 *
 *  The HEX code, which HEXme is building on top of, cannot be changed.
 *  The HEXme code cannot be changed either.
 *  Nobody is in charge of any of these contracts!
 *
 *  The HEXme contract uses the original HEX contract at the given address:
 *      0x2b591e99afe9f32eaa6214f7b7629768c40eeb39
 *
 *  The HEXme contracts address is:
 *      0x34b64e63Bdca0A165bb93C7C356BDef8909ccbb5
 *
 *  However HEXme does have very little configuration abilities, which only can be executed by the so called ORIGIN_ADDR.
 *  Those configuration functions use the onlyOrigin modifier.
 *  They neither give the ORIGIN_ADDR or any other entity any power to switch off any functionalities of the HEXme contract,
 *  nor give they the ORIGIN_ADDR or any other entity the power to control any users funds at any given time and state.
 *
 *  HEXme has no off switch. Anyone can run the code at any given time and state.
 *
 *  HEXme offers its users the ability to enter ETH to a HEX AA Lobby and to receive, not just +10% bonus HEX, as they would
 *  do with any casual referral link on the original go.HEX.com page, but +20% bonus on top of the basic HEX/ETH ratio
 *  of any given lobbyDay.
 *  That means HEXme users get the best deal for their bucket than at any other given place,
 *  if they wanna transform ETH into HEX, using HEXs AA lobby system.
 *
 *  HEXme also offers an internal referral system, which pays the referring address at maximum of 6%
 *  of the referred users originally transformed HEX. Those 6% are subtracted from the marginShares,
 *  which the ORIGIN_ADDR would receive otherwise. The user will always get its userShares, which are initially set
 *  to 120% and cannot be reduced, whether it refers another address or not.
 *
 *  The referral system therefore is self sustainable and doesn't promise any returns that doesn't actually exist
 *  in the HEX smart contract. This means any funds can be payed out at any given time, when the user simply exits its
 *  open HEX LobbyDay via HEXme.
 *
 *  HOW TO USE:
 *
 *      - enterLobby()
 *          - Call this payable method with at least minimumEntryAmount of wei, which is defined in globals,
 *            to enter a Lobby via HEXme and to reserve your +20% bonus from the given days basic HEX/ETH ratio.
 *          - The minimumEntryAmount initially is set to 0.025 ETH and can only be between 0.01 ETH & 0.05 ETH.
 *      - enterLobbyWithReferrer(address referrer)
 *          - Equally as enterLobby() with the possibility to note a referrer address, which will receive another +6%
 *            bonus on top of the users +20%.
 *      - exitLobby(uint256 lobbyDay)
 *          - Exits the given lobbyDay, if the user (the sending address) has entered any ETH in that day, didn't exit
 *            it yet and the given lobbyDay already has closed.
 *          - The user will receive its userShares HEX (initially set to 120%, can't be reduced) of the basic ratio,
 *            of the given lobbyDays ratio.
 *          - If any referral address was noted by the user at any previous lobbyDay entry, via enterLobbyWithReferrer()
 *            now this referral address also receives its marginShares percentage of the basic HEX/ETH ratio on top.
 *      - exitLobbyOnBehalf(address userAddress, uint256 lobbyDay)
 *          - From HEXs day 345 on, also other incentivized users, which describes a users referrer or the ORIGIN_ADDR,
 *            can exit a lobbyDay on behalf of the user, to be able to receive their marginShares HEX before
 *            HEXs BIG_PAY_DAY, which is the contract day 352.
 *          - Before day 345 only the user itself, who entered a lobby day is able to exit it, once it has closed.
 *
 *  FURTHER INFORMATION:
 *
 *  What happens if someone sends ETH to HEXme:
 *      - If anyone sends ETH directly to HEXme, it will automatically be forwarded to the enterLobby() method and
 *        therefore will behave exactly as if the sender would had called the enterLobby() directly with the sent ETH amount.
 *        This means the user will be able to exit the lobbyDay at which he sent the ETH to HEXme, once it has closed.
 *        Simply by using the exitLobby(uint256 lobbyDay) method.
 *
 *  The so called configuration abilities solely break down to:
 *      - changeMinimumEntryAmount()
 *          - in the range from 0.01 ETH to 0.05 ETH. #noexpectation
 *      - raiseUserShares()
 *          - userShares only can go up. At maximum to 30% bonus.
 *          - This in return would reduce the marginShares.
 *          - It might be used to assure market competitiveness and stay attractive for HEXmes users.
 *          - Do not expect of this ever happening. #noexpectation
 *      - moveExitLobbyPointer()
 *          - This could be called to gas optimize HEXmes internal state behaviour for the users.
 *          - It doesn't affect the ability for any user to use HEXme at any given time, at any given state.
 *      - flushExceedingHEX()
 *          - If HEX externally got send to HEXme, whether on purpose or on accident,
 *            this method gives the ORIGIN_ADDR the ability to flush those externally added funds to itself.
 *          - It also assures, that HEXme always has covered its required HEX liquidity, needed to serve all users exits,
 *            who ever entered any lobbyDay via HEXme.
 *          - It solely flushes exceeding HEX on the contract, to the ORIGIN_ADDR, which weren't minted by any users entry.
 *          - The ORIGIN_ADDR can do whatever it does with the exceeding HEX, if it ever was to receive any.
 *          - It might be possible, that if sent accidentally, the ORIGIN_ADDR could also decide to send those funds
 *            back to the address, the HEX originated from. #noexpectation
 *      - flushERC20()
 *          - If any other ERC20 than HEX (determined by the HEX contracts address) might land on that contract,
 *            the ORIGIN_ADDR is free to flush those tokens to itself and to do whatever it does with those assets.
 *            #noexpectation
 *
 *  Another publicly callable method:
 *      - exitContractLobbyDay(uint256 lobbyDay, uint40 count)
 *          - This method simply internally exits a HEXme contracts LobbyDay from the original HEX contract,
 *            to provide a higher instant liquidity and therefore to lower the gas fees for users
 *            to exit their HEXme entries.
 *          - It doesn't change any behaviour of the contract and can be called by anyone who wants to optimize
 *            the HEXmes users gas costs.
 *            #noexpectation
 *
 *  HAVE NO EXPECTATIONS:
 *
 *  DO NOT HAVE ANY EXPECTATIONS FROM ANYONE REGARDING HEX/HEXME/ETHEREUM OR ANY OTHER ENTITY!
 *  IF YOU DECIDE TO USE THOSE OPEN SOURCE, PUBLICLY ACCESSIBLE SYSTEMS, IT IS SOLELY ON YOU TO KNOW WHAT YOU ARE DOING.
 *  THERE IS NO ONE TO CALL FOR HELP, IF YOU USE THOSE TRULY DECENTRALIZED SYSTEMS WRONGLY.
 *  YOU ARE FULLY AND SOLELY RESPONSIBLE FOR YOUR ACTIONS.
 *  TAKE CARE! AND ENJOY THE DECENTRALIZED WORLD OF TODAY!
 *
 *  BEST REGARDS,
 *  HEXme.io
 *
 */


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SM: ADD OVF");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SM: SUB OVF");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SM: MUL OVF");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SM: DIV/0");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SM: MOD 0");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 *	HEX interface of required functionalities
 */

interface IHEX {

    struct DailyDataStore {
        uint72 dayPayoutTotal;
        uint72 dayStakeSharesTotal;
        uint56 dayUnclaimedSatoshisTotal;
    }

    function currentDay() external view returns (uint256);

    function globalInfo() external view returns (uint256[13] memory);

    function dailyData(uint256 lobbyDay) external view returns
        (uint72 dayPayoutTotal, uint72 dayStakeSharesTotal, uint56 dayUnclaimedSatoshisTotal);

    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }

    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }

    function xfLobby(uint256 lobbyDay) external view returns (uint256 rawAmount);

    function xfLobbyMembers(uint256 i, address _XfLobbyQueueStore) external view returns
        (uint40 headIndex, uint40 tailIndex, uint96 rawAmount, address referrerAddr);

    function xfLobbyEnter(address referrerAddr) external payable;

    function xfLobbyExit(uint256 enterDay, uint256 count) external;

    function dailyDataUpdate(uint256 beforeDay) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// HEXme contract code:
// We strongly suggest you, to verify the code you are executing!

contract HEXme {

    // SAFEMATH:

    using SafeMath for uint256;
    using SafeMath for uint40;

    // CONSTANTS - HEX specific:

    uint256 private constant HEARTS_PER_HEX = 10 ** uint256(8);
    uint256 private constant HEARTS_PER_SATOSHI = HEARTS_PER_HEX / 1e8 * 1e4;
    uint256 private constant WAAS_LOBBY_SEED_HEARTS = 1e9 * HEARTS_PER_HEX;

    uint256 private constant CLAIM_PHASE_START_DAY = 1;
    uint256 private constant CLAIM_PHASE_DAYS = 50 * 7;
    uint256 private constant CLAIM_PHASE_END_DAY = CLAIM_PHASE_START_DAY + CLAIM_PHASE_DAYS;
    uint256 private constant BIG_PAY_DAY = CLAIM_PHASE_END_DAY + 1;

    // STATE VARIABLES - HEXme specific:

    // HEX CONTRACT:
    IHEX public constant HEX = IHEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);

    // ORIGIN ADDRESS:
    address public constant ORIGIN_ADDR = 0x63Cbc7d47dfFE12C2B57AD37b8458944ad4121Ee;

    // SHARES:

    uint256 constant private totalShares = 1320;
    // 1000‰ representing the AAs basic ETH/HEX ratio
    uint256 constant public basicShares = 1000;
    // 1200‰ representing the users 200‰ bonus shares - 2x of the normal referee bonus
    // it might increase if a higher competitiveness is desired for HEXme - 1300‰ hard cap - no expectations
    uint256 public userShares = 1200;
    // 60‰ representing the split in half margin shares, that go equally to the origin & the referrer (if exists)
    // it might decrease counter accordingly to a possible user share increase - 10‰ min cap - no expectations
    uint256 public marginShares = 60;

    // GLOBALS:

    struct GlobalsStore {
        uint256 initDay;
        uint256 exitLobbyPointer;
        uint256 minimumEntryAmount;
        uint256 totalContractsExitedHEX;
        uint256 totalUsersExitedHEX;
    }

    GlobalsStore public globals;

    struct HEXmeLobbyEntryQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
    }

    // MAPPINGS:

    // Day --> HEXme Lobby ETH amount
    mapping(uint256 => uint256) public HEXmeLobbyETHperDay;
    // Day --> HEXme Lobby HEX amount
    mapping(uint256 => uint256) public HEXmeLobbyHEXperDay;
    // Day --> HEXme Lobby ETH amount per entry
    mapping(uint256 => uint256[]) public HEXmeLobbyETHperDayEntries;
    // Address --> Day --> HEXme Users Lobby ETH amount
    mapping(address => mapping(uint256 => uint256)) public HEXmeUsersLobbyETHperDay;
    // Day --> LobbyQueueStore
    mapping(uint256 => HEXmeLobbyEntryQueueStore) public HEXmeLobbyEntryQueue;

    // user --> referrer
    mapping(address => address) private referredForever;
    // referee --> day since referral exists
    mapping(address => uint256) private referredSince;

    // EVENTS:

    event EnteredLobby(uint256 lobbyDay, address indexed user, address indexed referrer, uint256 enteredETH);
    event ExitedLobby(uint256 lobbyDay, address indexed user, address indexed referrer, uint256 usersHEX, uint256 referrersHEX, uint256 exitedETH);
    event ExitedOnBehalf(uint256 lobbyDay, address indexed user, address indexed sender);
    event NewReferral(address indexed referrer, address referee, uint256 currentDay);

    event ContractFullyExitedLobbyDay(uint256 lobbyDay, uint256 currentDay);
    event MovedExitLobbyPointer(uint256 from, uint256 to, uint256 currentDay);
    event ChangedMinimumEntryAmount(uint256 from, uint256 to, uint256 currentDay);
    event RaisedUserShares(uint256 userShares, uint256 marginShares, uint256 currentDay);
    event FlushedExceedingHEX(uint256 exceedingHEX, uint256 currentDay);

    // ONLY ORIGIN MODIFIER:

    modifier onlyOrigin {
        require(msg.sender == ORIGIN_ADDR, "HEXme: only ORIGIN_ADDR");
        _;
    }

    constructor() public payable {
        uint256 initBufferEntryAmount = 1000000000000000;
        require(msg.value == initBufferEntryAmount);

        globals.minimumEntryAmount = initBufferEntryAmount;
        globals.initDay = HEX.currentDay();
        globals.exitLobbyPointer = globals.initDay;

        _enterLobby(address(0));

        globals.minimumEntryAmount = 25000000000000000;
    }

    receive() external payable {
        _enterLobby(ORIGIN_ADDR);
    }

    function enterLobby() external payable {
        _enterLobby(address(0));
    }

    function enterLobbyWithReferrer(address referrer) external payable {
        _enterLobby(referrer);
    }

    function _enterLobby(address referrer) private {
        require(msg.value >= globals.minimumEntryAmount, "HEXme: below minimumEntryAmount");

        HEX.xfLobbyEnter{value : msg.value}(address(this));

        uint256 currentDay = HEX.currentDay();

        _updateReferrer(referrer, currentDay);

        HEXmeLobbyETHperDay[currentDay] += msg.value;
        HEXmeUsersLobbyETHperDay[msg.sender][currentDay] += msg.value;
        HEXmeLobbyETHperDayEntries[currentDay].push(msg.value);
        HEXmeLobbyEntryQueue[currentDay].tailIndex++;

        emit EnteredLobby(currentDay, msg.sender, referredForever[msg.sender], msg.value);
    }

    function _updateReferrer(address referrer, uint256 currentDay) private {
        if (referrer != address(0) && referrer != msg.sender && !_isReferred(msg.sender)) {
            referredForever[msg.sender] = referrer;
            referredSince[msg.sender] = currentDay;
            emit NewReferral(referrer, msg.sender, currentDay);
        }
    }

    function _isReferred(address userAddress) private view returns (bool){
        return (referredForever[userAddress] != address(0));
    }

    function exitLobby(uint256 lobbyDay) external {
        uint256 currentDay = HEX.currentDay();
        _exitLobby(msg.sender, lobbyDay, currentDay);
    }

    function exitLobbyOnBehalf(address userAddress, uint256 lobbyDay) external {
        uint256 currentDay = HEX.currentDay();
        require(
            msg.sender == userAddress ||
            (
                (currentDay > CLAIM_PHASE_END_DAY.sub(7)) &&
                (
                    msg.sender == ORIGIN_ADDR ||
                    (msg.sender == referredForever[userAddress] && lobbyDay >= referredSince[userAddress])
                )
            ),
            "HEXme: Only for incentivized users, from day 345 on"
        );
        _exitLobby(userAddress, lobbyDay, currentDay);
    }

    function _exitLobby(address userAddress, uint256 lobbyDay, uint256 currentDay) private {
        uint256 ETHtoExit = HEXmeUsersLobbyETHperDay[userAddress][lobbyDay];

        require(lobbyDay < currentDay, "HEXme: Day not complete");
        require(ETHtoExit > 0, "HEXme: No entry from this user, this day");

        uint256 HEXtoExit = _getUsersHEXtoExit(userAddress, lobbyDay);
        delete HEXmeUsersLobbyETHperDay[userAddress][lobbyDay];
        globals.totalUsersExitedHEX += HEXtoExit;

        _exitTillLiquidity(HEXtoExit, currentDay);
        _payoutHEX(userAddress, HEXtoExit, ETHtoExit, lobbyDay);
    }

    function _getUsersHEXtoExit(address userAddress, uint256 lobbyDay) private returns (uint256 HEXtoExit){
        _updateHEXmeLobbyHEXperDay(lobbyDay);
        return ((HEXmeUsersLobbyETHperDay[userAddress][lobbyDay]
            .mul(HEXmeLobbyHEXperDay[lobbyDay])).div(HEXmeLobbyETHperDay[lobbyDay]));
    }

    function _updateHEXmeLobbyHEXperDay(uint256 lobbyDay) private {
        if (HEXmeLobbyHEXperDay[lobbyDay] == 0) {
            uint256 HEXinLobby = _getHEXinLobby(lobbyDay);
            if (HEXinLobby == 0) {
                HEX.dailyDataUpdate(lobbyDay + 1);
                HEXinLobby = _getHEXinLobby(lobbyDay);
            }
            uint256 basicHEXperDay =
                (HEXinLobby.mul(HEXmeLobbyETHperDay[lobbyDay])).div(HEX.xfLobby(lobbyDay));
                HEXmeLobbyHEXperDay[lobbyDay] = (basicHEXperDay.mul(totalShares)).div(basicShares);
        }
    }

    function _getHEXinLobby(uint256 lobbyDay) private view returns (uint256 HEXinLobby){
        if (lobbyDay >= 1) {
            (,,uint256 dayUnclaimedSatoshisTotal) = HEX.dailyData(lobbyDay);
            if (lobbyDay == HEX.currentDay()) {
                dayUnclaimedSatoshisTotal = HEX.globalInfo()[7];
            }
            return dayUnclaimedSatoshisTotal * HEARTS_PER_SATOSHI / CLAIM_PHASE_DAYS;
        } else {
            // poor branch is never gonna see the daylight ;)
            return WAAS_LOBBY_SEED_HEARTS;
        }
    }

    function _exitTillLiquidity(uint256 liquidity, uint256 currentDay) private {
        uint256 cachedExitLobbyPointer = globals.exitLobbyPointer;
        uint40 cachedHeadIndex = HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex;

        uint256 startIndex = HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex;
        uint256 startLiquidity = HEX.balanceOf(address(this));
        uint256 currentLiquidity = startLiquidity;

        while (currentLiquidity < liquidity) {
            if (cachedHeadIndex < HEXmeLobbyEntryQueue[cachedExitLobbyPointer].tailIndex) {
                uint256 addedLiquidity =
                    (HEXmeLobbyETHperDayEntries[cachedExitLobbyPointer][cachedHeadIndex]
                    .mul(HEXmeLobbyHEXperDay[cachedExitLobbyPointer])).div(HEXmeLobbyETHperDay[cachedExitLobbyPointer]);

                currentLiquidity = currentLiquidity.add(addedLiquidity);
                cachedHeadIndex++;
            } else {
                if (cachedHeadIndex.sub(startIndex) > 0) {
                    HEX.xfLobbyExit(cachedExitLobbyPointer, cachedHeadIndex.sub(startIndex));

                    if (cachedHeadIndex == HEXmeLobbyEntryQueue[cachedExitLobbyPointer].tailIndex)
                        emit ContractFullyExitedLobbyDay(cachedExitLobbyPointer, currentDay);
                }

                if(cachedHeadIndex != HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex)
                    HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex = cachedHeadIndex;

                cachedExitLobbyPointer++;

                if (cachedExitLobbyPointer >= currentDay || cachedExitLobbyPointer >= CLAIM_PHASE_END_DAY)
                    cachedExitLobbyPointer = globals.initDay;

                cachedHeadIndex = HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex;
                startIndex = cachedHeadIndex;
            }
        }

        if (cachedHeadIndex.sub(startIndex) > 0) {
            HEX.xfLobbyExit(cachedExitLobbyPointer, cachedHeadIndex.sub(startIndex));

            if (cachedHeadIndex == HEXmeLobbyEntryQueue[cachedExitLobbyPointer].tailIndex)
                emit ContractFullyExitedLobbyDay(cachedExitLobbyPointer, currentDay);
        }

        globals.totalContractsExitedHEX = globals.totalContractsExitedHEX.add(
            HEX.balanceOf(address(this)).sub(startLiquidity));

        if (HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex != cachedHeadIndex)
            HEXmeLobbyEntryQueue[cachedExitLobbyPointer].headIndex = cachedHeadIndex;

        if (globals.exitLobbyPointer != cachedExitLobbyPointer)
            globals.exitLobbyPointer = cachedExitLobbyPointer;
    }

    function _payoutHEX(address userAddress, uint256 HEXtoExit, uint256 exitedETH, uint256 lobbyDay) private {
        uint256 usersHEX = (HEXtoExit.mul(userShares)).div(totalShares);
        uint256 marginHEX = HEXtoExit.sub(usersHEX);
        uint256 referrersHEX = (_isReferred(userAddress) && lobbyDay >= referredSince[userAddress]) ?
            (marginHEX.mul(marginShares)).div(totalShares.sub(userShares)) : 0;
        uint256 originsHEX = marginHEX.sub(referrersHEX);

        if (originsHEX > 0)
            HEX.transfer(address(ORIGIN_ADDR), originsHEX);

        if (referrersHEX > 0)
            HEX.transfer(address(referredForever[userAddress]), referrersHEX);

        if (usersHEX > 0)
            HEX.transfer(userAddress, usersHEX);

        emit ExitedLobby(lobbyDay, userAddress, referredForever[userAddress], usersHEX, referrersHEX, exitedETH);

        if (msg.sender != userAddress)
            emit ExitedOnBehalf(lobbyDay, userAddress, msg.sender);
    }

    function exitContractLobbyDay(uint256 lobbyDay, uint40 count) external {
        uint256 startLiquidity = HEX.balanceOf(address(this));

        HEX.xfLobbyExit(lobbyDay, count);

        globals.totalContractsExitedHEX = globals.totalContractsExitedHEX.add(
            HEX.balanceOf(address(this)).sub(startLiquidity));

        if (count > 0)
            HEXmeLobbyEntryQueue[lobbyDay].headIndex += count;
        else
            HEXmeLobbyEntryQueue[lobbyDay].headIndex = HEXmeLobbyEntryQueue[lobbyDay].tailIndex;

        if (HEXmeLobbyEntryQueue[lobbyDay].headIndex == HEXmeLobbyEntryQueue[lobbyDay].tailIndex)
            emit ContractFullyExitedLobbyDay(lobbyDay, HEX.currentDay());
    }

    function changeMinimumEntryAmount(uint256 newMinimumEntryAmount) external onlyOrigin {
        require(10000000000000000 <= newMinimumEntryAmount && newMinimumEntryAmount <= 50000000000000000, "HEXme: INV VAL");

        emit ChangedMinimumEntryAmount(globals.minimumEntryAmount, newMinimumEntryAmount, HEX.currentDay());

        globals.minimumEntryAmount = newMinimumEntryAmount;
    }

    function raiseUserShares(uint256 newUserSharesInPerMill) external onlyOrigin {
        require(newUserSharesInPerMill.add(20) <= totalShares, "HEXme: 1300 CAP");
        require(newUserSharesInPerMill > userShares, "HEXme: INCREASE");

        marginShares = (totalShares.sub(newUserSharesInPerMill)).div(2);
        userShares = totalShares.sub(marginShares.mul(2));

        emit RaisedUserShares(userShares, marginShares, HEX.currentDay());
    }

    function moveExitLobbyPointer(uint256 newLobbyPointerDay) external onlyOrigin {
        require(newLobbyPointerDay >= globals.initDay && newLobbyPointerDay < HEX.currentDay(), "HEXme: INV VAL");

        emit MovedExitLobbyPointer(globals.exitLobbyPointer, newLobbyPointerDay, HEX.currentDay());

        globals.exitLobbyPointer = newLobbyPointerDay;
    }

    function flushExceedingHEX() external onlyOrigin {
        uint256 currentLiquidity = HEX.balanceOf(address(this));
        uint256 reservedLiquidity = globals.totalContractsExitedHEX.sub(globals.totalUsersExitedHEX);
        uint256 exceedingLiquidity = (currentLiquidity.sub(reservedLiquidity)).sub(HEARTS_PER_HEX);

        require(exceedingLiquidity > 0, "HEXme: 0 Exceeding");

        HEX.transfer(ORIGIN_ADDR, exceedingLiquidity);
        emit FlushedExceedingHEX(exceedingLiquidity, HEX.currentDay());
    }

    function flushERC20(IERC20 _token) external onlyOrigin {
        require(_token.balanceOf(address(this)) > 0, "HEXme: 0 BAL");
        require(address(_token) != address(HEX), "HEXme: !HEX");
        _token.transfer(ORIGIN_ADDR, _token.balanceOf(address(this)));
    }

    // EXTERNAL VIEW HELPERS:

    function getCurrentDay() external view returns (uint256) {
        return HEX.currentDay();
    }

    function getHEXinLobby(uint256 lobbyDay) external view returns (uint256){
        return _getHEXinLobby(lobbyDay);
    }

    function getHistoricLobby(bool getHEXInsteadETH) external view returns (uint256[] memory){
        uint256 tillDay = HEX.currentDay();
        tillDay = (tillDay <= CLAIM_PHASE_END_DAY) ? tillDay : CLAIM_PHASE_END_DAY;
        uint256[] memory historicLobby = new uint256[](tillDay + 1);
        for (uint256 i = 0; i <= tillDay; i++) {
            if (getHEXInsteadETH)
                historicLobby[i] = _getHEXinLobby(i);
            else
                historicLobby[i] = HEX.xfLobby(i);
        }
        return historicLobby;
    }
}