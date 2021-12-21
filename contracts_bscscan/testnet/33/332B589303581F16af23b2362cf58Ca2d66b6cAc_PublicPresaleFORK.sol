/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


/* ---------- START OF IMPORT IERC20.sol ---------- */




/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
/* ------------ END OF IMPORT IERC20.sol ---------- */


/* ---------- START OF IMPORT ICreamery.sol ---------- */




interface ICreamery {
    function initialize(address ownableNewOlypmus) external;

    // onlyOwnable
    function burnItAllDown_OO() external;

    // onlyNewOlypmusToken
    function launch_OFT() external;
    function weSentYouSomething_OFT(uint256 amount) external;

    // onlyAdmin
    function updateOwnable_OAD(address new_ownableNewOlypmus) external;

    function deposit(string memory note) external payable;
    // authorized
    function spiltMilk(uint256 value) external;
}
/* ------------ END OF IMPORT ICreamery.sol ---------- */


/* ---------- START OF IMPORT INewOlypmus.sol ---------- */




interface INewOlypmus {

  function presaleClaim(address presaleContract, uint256 amount) external returns (bool);
  function spiltMilk(uint256 amount) external;
  function creamAndFreeze() external payable;

  //onlyBridge
  function setBalance_OB(address holder,uint256 amount) external returns (bool);
  function addBalance_OB(address holder,uint256 amount) external returns (bool);
  function subBalance_OB(address holder,uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;

  //onlyOwnableNewOlypmus
  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;

  //function updateBridge_OAD(address new_bridge,bool bridgePaused) external;
  function decimals() external view returns (uint8);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function symbol() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

  function fees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function gas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}
/* ------------ END OF IMPORT INewOlypmus.sol ---------- */


/* ---------- START OF IMPORT SafeMath.sol ---------- */




// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
/* ------------ END OF IMPORT SafeMath.sol ---------- */


/* ---------- START OF IMPORT Context.sol ---------- */




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    // @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;// silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* ------------ END OF IMPORT Context.sol ---------- */


contract NewOlypmusAccess is Context {
    address internal iceCreamMan;
    address internal pendingICM;
    address internal newOlypmusToken;
    address internal creamery;
    mapping(address => bool) private authorizations;
    function grantAuthorization_OICM(address authorizedAddress)
        external
        onlyIceCreamMan
    {
        _grantAuthorization(authorizedAddress);
    }

    function _grantAuthorization(address authorizedAddress)
        internal
    {
        authorizations[authorizedAddress] = true;
    }

    function revokeAuthorization_OICM(address revokedAddress)
        external
        onlyIceCreamMan
    {
        _revokeAuthorization(revokedAddress);
    }

    function _revokeAuthorization(address revokedAddress)
        internal
    {
        authorizations[revokedAddress] = false;
    }

    function isAuthorized(address addr) internal view returns (bool) {
        return authorizations[addr];
    }

    function transferRoleICM_OICM(
        address new_iceCreamMan
    )
        external
        onlyIceCreamMan
    {
        _transferICM(new_iceCreamMan);
    }

    function _transferICM(address new_iceCreamMan) internal {
        pendingICM = new_iceCreamMan;
    }

    function acceptIceCreamMan_OPICM() external onlyPendingIceCreamMan {
        _acceptIceCreamMan();
    }

    function _acceptIceCreamMan() internal {
        iceCreamMan = pendingICM;
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
    }

    modifier onlyAuthorized() {
        require(
            isAuthorized(_msgSender()),
            "PRESALE FORK: onlyAuthorized() - caller not authorized"
        );
        _;
    }

    modifier onlyPendingIceCreamMan() {
        require(
            pendingICM == _msgSender(),
            "PRESALE FORK: onlyPendingIceCreamMan() - caller not pendingICM"
        );
        _;
    }

    modifier onlyCreamery() {
        require(
            creamery == _msgSender(),
            "PRESALE FORK: onlyCreamery() - caller not creamery"
        );
        _;
    }

    modifier onlyNewOlypmusToken() {
        require(
            newOlypmusToken == _msgSender(),
            "PRESALE FORK: onlyNewOlypmusToken() - caller not newOlypmusToken"
        );
        _;
    }

    modifier onlyIceCreamMan() {
        require(
            iceCreamMan == _msgSender(),
            "PRESALE FORK: onlyIceCreamMan() - caller not iceCreamMan"
        );
        _;
    }
 }

    /**
        @title NewOlypmusTimedPresale
        @author newOlypmusDev
        @notice inheritable extension contract for the main newOlypmus presale
            contract. adds timed features to the presale. start time, end
            time, duration.
        @dev Usage: 
            - at the start of any 'contribute()' function add the line:
                timedPresale()
        @dev 'overridesAllowed_timedPresale' NOTE: set to true/false to
                enable/disable modifications to the initial settings after
                presale contract launch.
        @dev 'presaleTimestampSTART' NOTE: UNIX timestamp in seconds since
            epoch example: 1634379625 = 
                GMT: October 16, 2021 10:20:42 AM
                Your time zone: October 16, 2021 3:20:42 AM GMT-07:00 DST
            calculate the timestamp here => https://www.epochconverter.com/            
        @dev 'presaleDuration' NOTE: can be pre-set using plain language.
            example:    for a 1 day long presale, enter '1 days'
                        for a 4 hour presale, enter '4 hours'
            all available time paramaters:
                'seconds', 'hours', 'days', 'weeks'
            can be combined like this: '3 days + 4 hours'
        @dev 'presaleTimestampEND' NOTE: can be pre-set to UNIX timestamp in
            seconds since epoch or can be calculated from duration.
        @dev after deployment use 'setPresaleTime_OICM()' to initialize the
            start and end times. this will override a setting that the
            contract was deployed with. may be used only once unless 
            'overridesAllowed_timedPresale' is set to 'true'
    */
contract NewOlypmusTimedPresale is NewOlypmusAccess {
    using SafeMath for uint256;
    
    bool timedPresaleEnabled = true;
    bool timedPresaleInitialized;
    bool overridesAllowed_timedPresale = true;
    uint256 internal presaleDuration = 30 minutes;
    // Tue Oct 19 2021 21:00:00 GMT-0700 (Pacific Daylight Time)
    string internal startTimeString 
        = 'Mon Dec 20 2021 11:00:00 GMT-0700 (Pacific Daylight Time)';
    uint256 internal presaleTimestampSTART = 1640026800;
    uint256 internal presaleTimestampEND = presaleTimestampSTART
        + presaleDuration;



    // functions
    // getter function
    /**
        @notice simple countdown timer to the START of the presale
        @return seconds until START of presale or 0 if presale has started
     */
    function countdownToPresaleSTART() internal view returns (uint256) {
        if(block.timestamp > presaleTimestampSTART) {
            return 0;
        } else {
            return presaleTimestampSTART.sub(block.timestamp);
        }
     }

    /**
        @notice simple countdown timer to the END of the presale
        @return seconds until END of presale or 0 if presale has ended
     */
    function countdownToPresaleEND() internal view returns (uint256) {
        if(block.timestamp > presaleTimestampEND) {
            return 0;
        } else {
            return presaleTimestampEND.sub(block.timestamp);
        }
     }
    
    // setter functions
    /**
        @notice disable timed presale after contract launch by calling
            this function. Enables or Disables the timed presale feature.
        @dev bypasses all time related checks for the presale. does not
            disable the timer output.
        @dev this function is disabled when 'overridesAllowed_timedPresale'
            is set to 'false'
     */
    function toggleTimedPresale_OICM()
        external
        onlyIceCreamMan
        checkOverrides_timedPresale
     {
        timedPresaleEnabled
            ? timedPresaleEnabled = false
            : timedPresaleEnabled = true;
     }

    /**
        @notice manually set the presale START, END, and DURATION
        @notice Can only set END timestamp or DURATION. One must be 0
        @dev sets the presale START time.
        @dev may be called by the iceCreamMan
        @dev this function is ONE-TIME-USE unless
            'overridesAllowed_timedPresale' is set to 'true'
        @param presaleTimestampSTART_ the START timestamp of the presale in
            Unix epoch time in seconds since epoch.
            example: 1634379625 = 
                GMT: October 16, 2021 10:20:42 AM
                Your time zone: October 16, 2021 3:20:42 AM GMT-07:00 DST
            calculate the timestamp here => https://www.epochconverter.com/
        @param presaleTimestampEND_ the END timestamp of the presale in
            Unix epoch time in seconds since epoch.
            example: 1634379625 = 
                GMT: October 16, 2021 10:20:42 AM
                Your time zone: October 16, 2021 3:20:42 AM GMT-07:00 DST
            calculate the timestamp here => https://www.epochconverter.com/
            NOTE: if using presaleTimestampEND_
                then set presaleDuration_ to '0'
        @param presaleDuration_ the total duration of the presale in seconds.
            note: 1 hour = 3600 seconds
            note: 1 day  = 86400 seconds
            note: 2 days = 172800 seconds
            NOTE: if using 'presaleDuration_' 
                then set presaleTimestampEND_ to '0'
     */
    function setPresaleTime_OICM(
        uint256 presaleTimestampSTART_,
        uint256 presaleTimestampEND_,
        uint256 presaleDuration_,
        string memory startTimeString_
     )
        external 
        onlyIceCreamMan
        checkOverrides_timedPresale
    {
        checkEndOrDurationAreZero(presaleDuration_, presaleTimestampEND_);
        // store the time string
        startTimeString = startTimeString_;
        // set the start time
        presaleTimestampSTART = presaleTimestampSTART_;
        // if we are setting duration
        if(presaleDuration_ != 0) {
            // add the duration to the start time and save it as the end time
            presaleTimestampEND = presaleTimestampSTART.add(presaleDuration_);
            presaleDuration = presaleDuration_;
        // if we made it here then we must be setting the end time
        } else {
            // 1.21 gigaWatts?
            checkFluxCapacitor(presaleTimestampSTART_, presaleTimestampEND_);
            // save the end time
            presaleTimestampEND = presaleTimestampEND_;
            presaleDuration = presaleTimestampEND.sub(presaleTimestampSTART);
        }
        // enable the timed presale
        timedPresaleEnabled = true;
        timedPresaleInitialized = true;
     }

    function checkFluxCapacitor(uint256 start, uint256 end) internal pure {
        // make sure the end time is after the start time
        require(
            start < end,
            "PRESALE FORK: Hey, McFly! END must be after START!"
        );
    }

    function checkEndOrDurationAreZero(uint256 duration, uint256 end) internal pure {
        require(
            // make sure we are only setting end or duration
            end == 0 || duration == 0,
            "PRESALE FORK: Can only set END or DURATION, not both"
        );
    }
    
    
    /**
        @notice add this function inside the 'contribute' function to 
            make this a timed presale.
        @dev presale timer can be overridden after launch by calling
            'toggleTimedPresale()'.
        @dev make sure to set 'presaleTimestampSTART' &
            'presaleTimestampEND' values properly
     */
    function timedPresale() internal view{
        if(timedPresaleEnabled) {
            checkTooEarly();
            checkTooLate();
        }
     }

    function checkTooLate() internal view {
        // require countdown to presale END is not 0
        require(
            countdownToPresaleEND() != 0,
            "PRESALE FORK: checkTooLate() - Too Late! Presale has ended."
        );
    }

    function checkTooEarly() internal view {
        // require countdown to presale START is at 0
        require(
            countdownToPresaleSTART() == 0,
            "PRESALE FORK: checkToEarly() - Too Early! Presale has not started."
        );
    }

    /**
        @notice modifier to globally allow or disallow modifications of any
            timed presale parameters after the contract launch
        @dev enforces the one-time-use of 'setPresaleTime()' unless
            'overridesAllowed_timedPresale' is set to 'true'
        @dev if 'overridesAllowed_timedPresale' is set to 'false' at launch,
            then the following functions are permanently disabled:
                toggleTimedPresale_OICM()
                setPresaleTime() [sets it as one-time-use]
     */
    modifier checkOverrides_timedPresale() {
        if(!overridesAllowed_timedPresale){
            checkTimedPresaleIsNotInitialized();
        } else {
            checkOverridesAllowedTimedPresale();
        }
        _;
     }

    function checkOverridesAllowedTimedPresale() internal view {
        require(
            overridesAllowed_timedPresale,
            "PRESALE FORK: Overrides After Contract Launch Are Disabled."
        );
    }

    function checkTimedPresaleIsNotInitialized() internal view {
        require(
            timedPresaleInitialized == false,
            "PRESALE FORK: Presale has already been initialized."
        );
    }

}



contract PublicPresaleFORK is NewOlypmusTimedPresale {
    using SafeMath for uint256;
    
    // type declarations
    INewOlypmus internal FORK;
    ICreamery internal Creamery;


    // state variables
    bool internal capReached;
    bool internal cappedPresaleEnabled = true;
    bool internal cappedPresaleInitialized;

    // NOTE: 'overridesAllowed_cappedPresale' set to true/false to 
    // enable/disable modifications to the initial cap settings after
    // presale contract launch.
    bool internal overridesAllowed_cappedPresale = true;

    bool internal softCapMissedRefundEnabled = false;

    uint256 internal globalTotal_refunds;

    bool internal enforceWhitelist = true;
    bool internal firstClaimsToggle = true;
    bool internal initialized = false;
    bool internal claimsEnabled;
    bool internal contributionsEnabled;
    bool internal useTokensInContract = false;
    uint16 internal maxBatchLength = 100;
    uint8 constant DECIMALS_BNB = 18;
    uint8 constant DECIMALS_FORK = 9;
    uint64 constant BLOCKS_PER_DAY = 28800;
    uint256 internal globalTotal_claims;
    uint256 internal globalTotal_contributions;
    // The presale rate. 1 bnb equals this many FORK
    // discounted 5% off the dxSale rate of 100,000 per BNB
    // 100,000/.95 = 105,263
    uint256 internal forkPerNativeCoin = 100_000 * (10**DECIMALS_FORK);
    uint256 internal claimsEnabledOnBlockNumber = 12011339;
    // initialize addresses and contracts
    
    
    


    uint256 internal timestampClaimsEnabled;
    
    // the sum of all whitelisted addresses max possible contribution
    // just a report of the sum if all whitelisted addresses contributed max,
    // not a limit or enforced cap
    uint256 internal globalTotal_maxContribution = 0;

    uint256 internal minHolderContribution = .01 ether;
    // the max contribution to the private presale
    uint256 internal maxHolderContribution = 2 ether;

    uint256 internal softCap = 325 ether;

    uint256 internal hardCap = 650 ether;

    
    // refunded amount, if soft cap is missed
    mapping(address => uint256) internal claimedRefund;
    // whitelist
    mapping(address => bool) internal whitelist;
    // blacklist
    mapping(address => bool) internal blacklist;
    // The amount of BNB the holder has contributed
    mapping(address => uint256) internal contributions;
    // The amount of FORK the holder has claimed
    mapping(address => uint256) internal claimedFORK;
    // True / False to check if the holder has maxed out their claims
    mapping(address => bool) internal completedClaims;
    // True / False to check if the holder has maxed out their contributions
    mapping(address => bool) internal completedContributions;

    // events
    /**
        @notice log fires on every address added to whitelist
        @param holder the holder's address who was just whitelisted
    */
    event WhitelistedHolder(address holder);

    /**
        @notice AdminTokenWithdrawal => Triggers on any successful call to
            adminTokenWithdrawal().
        @param withdrawalBy: The admin initiating the withdrawal
        @param amount: The quantity of token withdrawn
        @param token: The address of the token withdrawn
     */
    event AdminTokenWithdrawal(
        address indexed withdrawalBy,
        uint256 amount,
        address indexed token
    );

    /**
        @dev ContributionReceived => Triggers on any successful call to
            contribute().
        @param from: The address donating to the ICO.
        @param amount: The quantity in BNB of the contribution.
        @param holderTotalContributions:
        @param holderRemainingContributions:
        @param globalTotal_contributions:
        @param note:
     */
    event ContributionReceived(
        address indexed from,
        uint256 amount,
        uint256 holderTotalContributions,
        uint256 holderRemainingContributions,
        uint256 globalTotal_contributions,
        string note
    );

    /**
        @dev HolderAdded => Triggers on any successful call to
            addHolder().
        @param holder: The address of the holder added
     */
    event HolderAdded(address indexed holder);

    /**
        @notice 'setRefundsEnabled_OICM' In the event the soft cap is not
            reached, then this is to be called manually by dev after the
            completion of the presale. Setting this to 'true' modifies the
            payment to the contributor by the 'claim()' function. Instead of
            sending the contributor minted newOlypmus tokens, the contributor is
            returned their BNB contribution.
        @param refundsEnabled set to 'true' and contributors will be refunded
            BNB. leave 'false' and contributors will be sent minted bnb.
     */
    function setRefundsEnabled_OICM(
        bool refundsEnabled
    ) 
        external
        onlyIceCreamMan
    {
        softCapMissedRefundEnabled = refundsEnabled;
    }

    /**
        @notice disable capped presale after contract launch by calling
            this function. Enables or Disables the enforcement of the cap.
        @dev bypasses all cap related checks for the presale, however the
            total contributed towards the cap is still being calculated in
            the background.
        @dev this function is disabled when 'overridesAllowed_cappedPresale'
            is set to 'false'
     */
    function toggleCappedPresale_OICM()
        external
        onlyIceCreamMan
        checkOverrides_cappedPresale
     {
        
        cappedPresaleEnabled
            ? cappedPresaleEnabled = false
            : cappedPresaleEnabled = true;
    }
    

     /**
        @dev after deployment use 'setCap_OICM()' to initialize the
            cap. this will override a setting that the contract was deployed
            with. may be used only once unless 'overridesAllowed_cappedPresale'
            is set to 'true'
      */
    function setCap_OICM(uint256 newHardCap, uint256 newSoftCap)
        external
        onlyIceCreamMan
        checkOverrides_cappedPresale
    {
        checkNewHardCap(newHardCap);
        checkNewSoftCap(newHardCap, newSoftCap);
        // save the cap values
        softCap = newSoftCap;
        hardCap = newHardCap;
        // enable the cap
        capReached = false;
        cappedPresaleInitialized = true;
    }


//        @return true if capped presale checks pass. Reverts with error message
//         on all failures
    /**
        @notice add this function in a require statement at the top of any
            'contribute()' function to make this a capped presale.
        @dev presale cap can be overridden one time after launch by calling
            'setCap_OICM()', unless .
        @param value the amount this holder is attempting to contribute
     */
    function cappedPresale(uint256 value) internal{        
        globalTotal_contributions = globalTotal_contributions.add(value);
        if(cappedPresaleEnabled) {
            checkHardCapHit();
        }
     }

    /**
        @notice modifier to globally allow or disallow modifications of any
            capped presale parameters after the contract launch
        @dev enforces the one-time-use of 'setCap()' unless
            'overridesAllowed_cappedPresale' is set to 'true'
        @dev if 'overridesAllowed_cappedPresale' is set to 'false' at launch,
            then the following functions are permanently disabled:
                toggleCappedPresale()
                setCap() [sets it as one-time-use]
     */


     function softCapHit() internal view returns (bool) {
        if(globalTotal_contributions >= softCap){
            return true;
        } else {
            return false;
        }
     }

    /**
        @notice checks if the hard cap has been hit or not.
        @dev takes into consideration if the remaining difference from
            'hardCap' to 'globalTotal_contributions' is less than the
            'minHolderContribution'. This way if we show .009 is left to
            deposit, we still consider that as the hard cap being hit,
            since the minimum contribution is more than that.
     */
    function hardCapHit() internal view returns (bool) {
        if(cappedPresaleEnabled){
            if(hardCap.sub(globalTotal_contributions) < minHolderContribution){
               return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    bool shouldCheckContributionsEnabled = true;
    function toggleShouldCheckContributionsEnabled_OICM()
        external
        onlyIceCreamMan
        returns (bool)
    {
        shouldCheckContributionsEnabled
            ? shouldCheckContributionsEnabled = false
            : shouldCheckContributionsEnabled = true;
        return shouldCheckContributionsEnabled;
    }
    

    function getMaxClaimableFORK() internal view returns (uint256) {
        // multiply, then apply decimals => (a*b)/(10^d)
        return
            (maxHolderContribution.mul(forkPerNativeCoin))
                .div(10**DECIMALS_BNB);
    }

    function getRemainingBNBcontribution(address holder)
        internal
        view
        returns (uint256)
    {   
        if (enforceWhitelist){
            if (whitelist[holder]) {
                // subtract => a-b
                return maxHolderContribution.sub(contributions[holder]);
            } else {
                return 0;
            }
        } else {
            // subtract => a-b
            return maxHolderContribution.sub(contributions[holder]);
        }
    }

    function getRemainingMaxClaimableFORK(address holder)
        internal
        view
        returns (uint256)
    {
        if (enforceWhitelist){
            if (whitelist[holder]) {
                // subtract => a-b
                return getMaxClaimableFORK().sub(claimedFORK[holder]);
            } else {
                return 0;
            }
        } else {
            return getMaxClaimableFORK().sub(claimedFORK[holder]);
        }
    }

    function getHoldersClaimableFORK(address holder)
        internal
        view
        returns (uint256)
    {
        // multiply, multiply, divide, apply decimals,
        // then subtract => (a*b*c/d/(10^e))-f
        return (
            (contributions[holder].mul(forkPerNativeCoin)
                .div(10**DECIMALS_BNB))
                .sub(claimedFORK[holder])
        );
    }

    function getHoldersClaimableRefund(address holder)
        internal
        view
        returns (uint256)
    {
        // subtract => a-b
        return (
            contributions[holder].sub(claimedRefund[holder])
        );
    }

    /// NOTE DO NOT CHANGE, THIS IS REQUIRED BY THE TOKEN
    /// NOTE AND IS ALREADY DEPLOYED IN PRIVATE PRESALE CONTRACT
    function enableClaims_OFT() external onlyNewOlypmusToken {
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
            contributionsEnabled = false;
        }
        claimsEnabled = true;
    }
    /// NOTE DO NOT CHANGE, THIS IS REQUIRED BY THE TOKEN
    /// NOTE AND IS ALREADY DEPLOYED IN PRIVATE PRESALE CONTRACT


    function setClaimsEnabledBlockNumber_OICM(uint256 blockNumber)
        external
        onlyIceCreamMan
    {
        claimsEnabledOnBlockNumber = blockNumber;
    }

    function toggleClaims_OICM() external onlyIceCreamMan {
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
        }
        if(claimsEnabled){
            claimsEnabled = false;
        } else {
            claimsEnabled = true;
            contributionsEnabled = false;
        }
    }

    function toggleContributions_OICM() external onlyIceCreamMan {
        contributionsEnabled
            ? contributionsEnabled = false
            : contributionsEnabled = true;
    }

    function toggleEnforceWhitelist_OICM() external onlyIceCreamMan {
        enforceWhitelist
            ? enforceWhitelist = false
            : enforceWhitelist = true;
    }

    function initialize(address iceCreamMan_) external {
        checkNotInitialized();
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        iceCreamMan = iceCreamMan_;
        _grantAuthorization(iceCreamMan);
        _grantAuthorization(address(this));
        initialized = true;
    }


    function getTimes() 
        external 
        view 
        returns(
            uint256 presaleDuration_Seconds,
            string memory startTimeString_,
            uint256 presaleTimestampSTART_,
            uint256 presaleTimestampEND_,
            uint256 countdownToPresaleSTART_,
            uint256 countdownToPresaleEND_
        )
    {
        return (
            presaleDuration,
            startTimeString,
            presaleTimestampSTART,
            presaleTimestampEND,
            countdownToPresaleSTART(),
            countdownToPresaleEND()
        );
    }

    function getRules()
        external
        view
        returns (
            bool claimsEnabled_,
            bool enforceWhitelist_,
            bool useTokensInContract_,

            bool timedPresaleEnabled_,
            bool contributionsEnabled_,
            bool cappedPresaleEnabled_,
            bool softCapMissedRefundEnabled_,

            bool overridesAllowed_timedPresale_,
            bool overridesAllowed_cappedPresale_,
            bool shouldCheckContributionsEnabled_
        )
    {
        return (
            claimsEnabled,
            enforceWhitelist,
            useTokensInContract,

            timedPresaleEnabled,
            contributionsEnabled,
            cappedPresaleEnabled,
            softCapMissedRefundEnabled,
         
            overridesAllowed_timedPresale,
            overridesAllowed_cappedPresale,
            shouldCheckContributionsEnabled
        );
    }

    function getLimits()
        external
        view
        returns (
            uint256 softCap_,
            bool softCapHit_,
            uint256 hardCap_,
            bool hardCapHit_,
            uint256 minHolderContribution_,
            uint256 maxHolderContribution_
        )
    {
        return (
            softCap,
            softCapHit(),
            hardCap,
            hardCapHit(),
            minHolderContribution,
            maxHolderContribution
        );
    }
    
    function getAddresses()
        external
        view
        returns (
            address presaleFORK,
            address fork,
            address creamery,
            address iceCreamMan_,
            address pendingICM_
        )
    {
        return (
            address(this),
            address(FORK),
            address(Creamery),
            iceCreamMan,
            pendingICM
        );
    }
    
    function getInfo()
        external
        view
        returns (
            uint256 claimsEnabledOnBlockNumber_,
            uint256 globalTotal_maxContribution_,
            uint256 globalTotal_contributions_,
            uint256 globalTotal_claims_,
            uint256 globalTotal_refunds_,
            uint256 forkPerNativeCoin_,
            uint256 contractNativeCoinBalance_
        )
    {
        return (
            claimsEnabledOnBlockNumber,
            globalTotal_maxContribution,
            globalTotal_contributions,
            globalTotal_claims,
            globalTotal_refunds,
            forkPerNativeCoin,
            contractNativeCoinBalance()
        );
    }

    function getMyInfo()
        external
        view
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFORK,
            uint256 holderContributions_,
            uint256 claimedFORK_,
            bool completedContributions_,
            bool completedClaims_,
            uint256 claimedRefund_
        )
    {
        return _getHolderInfo(_msgSender());
    }

    function getHolderInfo(address holder)
        external
        view
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFORK,
            uint256 holderContributions_,
            uint256 claimedFORK_,
            bool completedContributions_,
            bool completedClaims_,
            uint256 claimedRefund_
        )
    {
        return _getHolderInfo(holder);
    }

    function _getHolderInfo(address holder)
        internal
        view        
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFORK,
            uint256 holderContributions_,
            uint256 claimedFORK_,
            bool completedContributions_,
            bool completedClaims_,
            uint256 claimedRefund_
        )
    {
        return (
            getRemainingBNBcontribution(holder),
            getHoldersClaimableFORK(holder),
            contributions[holder],
            claimedFORK[holder],
            completedContributions[holder],
            completedClaims[holder],
            claimedRefund[holder]
        );
    }

    /**
        @notice Contribute to the presale.
    */
    function contribute() external payable {
        address holder = _msgSender();
        uint256 value = _msgValue();

        checkContributionsEnabled();
        timedPresale();
        cappedPresale(value);
        checkBlacklist(holder);
        checkWhitelist(holder);
        checkHolderMinContribution(value);
        checkHolderMaxContribution(holder, value);

        _contribute(holder, value);
        // delete temp variables for a gas refund
        delete holder;
        delete value;
    }

    /**
     * @param holder: The address contributing to the presale
     * @param amount: The quantity in bnb of the contribution.
     */
    function _contribute(address holder, uint256 amount) internal {
        // for transfers IN handle the transfer FIRST and THEN update values
        contributions[holder] = contributions[holder].add(amount);
        if (getRemainingBNBcontribution(holder) == 0) {
            completedContributions[holder] = true;
        }
        emit ContributionReceived(
            holder,
            amount,
            contributions[holder],
            getRemainingBNBcontribution(holder),
            globalTotal_contributions,
            "PRESALE FORK: Contribution Received!"
        );
    }

    function claim_OWL() external {
        checkClaimsEnabled();
        address holder = _msgSender();
        checkBlacklist(holder);
        checkWhitelist(holder);
        checkHolderCompletedClaims(holder);
        // if the softcap has been hit
        if(softCapHit()){
            uint256 amount = checkHoldersClaimableFORK(holder);
            _claim(holder, amount);
        // if the softcap has not been hit
        } else {
            checkRefundsEnabled();
            uint256 value = checkHoldersClaimableRefund(holder);
            _claimRefund(holder,value);
        }
    }

    function _claimRefund(address holder, uint256 value) internal {
        // make sure the refund is less than or equal to the holders contributions
        checkValueIsLessThanContributed(holder, value);
        // update the values in the contract FIRST, then process the transfer
        contributions[holder] = contributions[holder].sub(value);
        claimedRefund[holder] = claimedRefund[holder].add(value);
        globalTotal_contributions = globalTotal_contributions.sub(value);
        globalTotal_refunds = globalTotal_refunds.add(value);
        processRefund(holder, value);
    }
    // the absolute last step in the refund process must be the actual transfer
    // with a require to revert on failure
    function processRefund(
        address holder,
        uint256 value
    )
        private
    {
        (bool success, ) = payable(address(holder)).call{value: value}("");
        checkTransferSuccess(success);
    }
    /**
        @dev updates the state variables for the claim BEFORE we transfer
            the claim.
        @notice Performs additional security checks on the claim.
        @notice requires amount is less than the holders remaining unclaimed
            amount
        @notice requires that, if the transfer is successful, the holders
            claimedFORK does not exceed the holders total claimable FORK
        @notice requires the transfer of claimed tokens is successful
        @notice After verification hands the verified amount and holder to the
            transfering function 'processClaim'
        @dev Internal function callable by functions within the contract
     */
    function _claim(address holder, uint256 amount) internal {
        require(
            amount <= getRemainingMaxClaimableFORK(holder),
            "PRESALE FORK: _claim() - claim exceeds remaining unclaimed FORK"
        );
        // update the values in the contract FIRST, then process the transfer
        globalTotal_claims = globalTotal_claims.add(amount);
        claimedFORK[holder] = claimedFORK[holder].add(amount);
        checkHoldersClaimedFORK(holder);
        
        if (getRemainingMaxClaimableFORK(holder) == 0) {
            completedClaims[holder] = true;
        }
        require(
            processClaim(holder, amount),
            "PRESALE FORK: _claim() - transfer of claimed tokens failed."
        );
    }

    /**
        @notice setUseTokensInContract_OICM selects the source of tokens for
            presale claims.
        @param useTokensInContract_ set to 'true' and the presale contract
            will fund the claims from tokens in this contract. they must be
            deposited prior to enabling claims. Set to 'false' and the tokens
            will be minted direct from the main token contract
     */
    function setUseTokensInContract_OICM(bool useTokensInContract_)
        external
        onlyIceCreamMan
    {
        useTokensInContract = useTokensInContract_;
    }

    /**
        @notice Handles the actual transfer of claimed FORK to the holder
        @dev Internal private function may be called by any function within
            this contract
        @param holder The holder address who will receive the FORK tokens
        @param amount The total amount of FORK to transfer to the holder
        @return returns true on a successful transfer
     */
    function processClaim(address holder, uint256 amount)
        private
        returns (bool)
    {
        // if 'useTokensInContract' is set to 'true', then we need to fund
        // the presale contract with tokens before allowing claims
        if (useTokensInContract) {
            return FORK.transfer(holder, amount);
        // if 'useTokensInContract' is set to 'false', then tokens are minted
        // then transfered to the presale contract, then the presale contract
        // transfers them to the holder. 
        } else {
            FORK.presaleClaim(address(this), amount);
            return FORK.transfer(holder, amount);
        }
    }

    /**
        @notice used to set the addresses of FORK and Creamery
        @dev External function callable by onlyIceCreamMan
        @param fork The NewOlypmus Contract address which we are contributing to
        @param creamery The address of the Creamery, the receiver of the
            funds contributed to the presale.
     */
    function setAddresses_OICM(
        address fork,
        address creamery
    )
        external
        onlyIceCreamMan
    {
        setAddressFORK(fork);
        setAddressCreamery(creamery);
    }    

    /**
        @notice used to set the min and max contribution limit of each wallet
        @param minHolderContribution_ The min contribution per holder in native
            coin. The decimals must be added. on bsc, the native coin BNB has 18
            decimal points of precision. so to set .01 BNB as the limit, we would
            need to enter 1 followed by 16 zeros. 10000000000000000
        @param maxHolderContribution_ The min contribution per holder in native
            coin. The decimals must be added. on bsc, the native coin BNB has 18
            decimal points of precision. so to set 2 BNB as the limit, we would
            need to enter 2 followed by 18 zeros. 2000000000000000000
    */
    function setContributionLimits_OICM(
        uint256 minHolderContribution_,
        uint256 maxHolderContribution_
    )
        external
        onlyIceCreamMan
    {        
        setMinHolderContribution(minHolderContribution_);
        setMaxHolderContribution(maxHolderContribution_);
    }

    /**
        @notice used to set the rate of tokens per native coin contributed        
        @param forkPerNativeCoin_ The rate for calculating claimed tokens.
            Input the value as a whole number. The decimals are removed later.
              So for 1,234,567 enter 1234567.
            The output value of the number when checked with the 'getInfo' 
            function will show the 9 decimals removed => 1234567000000000
     */
    function setRate_OICM(
        uint256 forkPerNativeCoin_
    )
        external
        onlyIceCreamMan
    {
        forkPerNativeCoin = forkPerNativeCoin_.mul(10**DECIMALS_FORK);
    }
    function setMaxHolderContribution(uint256 value) internal {
        maxHolderContribution = value;
    }
    function setMinHolderContribution(uint256 value) internal {
        minHolderContribution = value;
    }

    function setAddressCreamery(address creamery) internal {
        Creamery = ICreamery(creamery);
    }

    function setAddressFORK(address newOlypmusToken_) internal {
        newOlypmusToken = newOlypmusToken_;
        FORK = INewOlypmus(newOlypmusToken);
    }



    function setMaxBatchLength(uint16 maxBatchLength_) external onlyIceCreamMan {
        maxBatchLength = maxBatchLength_;
    }

    function toggleBlacklisted_OAUTH(address holder) external onlyAuthorized {
        blacklist[holder]
            ? setBlacklistedFalse(holder)
            : setBlacklistedTrue(holder);
    }

    function toggleWhitelisted_OAUTH(address holder) external onlyAuthorized {
        whitelist[holder]
            ? setWhitelistedFalse(holder)
            : setWhitelistedTrue(holder);
    }

    function setBlacklistedTrue(address holder) internal {
        if (!blacklist[holder]) {
            blacklist[holder] = true;
            globalTotal_maxContribution = globalTotal_maxContribution.sub(
                maxHolderContribution
            );
            if (whitelist[holder]) {
                setWhitelistedFalse(holder);
            }
        }
    }

    function setBlacklistedFalse(address holder) internal {
        if (blacklist[holder]) {
            blacklist[holder] = false;
        }
    }

    function setWhitelistedTrue(address holder) internal {
        if (!whitelist[holder]) {
            whitelist[holder] = true;
            globalTotal_maxContribution = globalTotal_maxContribution.add(
                maxHolderContribution
            );
            if (blacklist[holder]) {
                setBlacklistedFalse(holder);
            }
            emit WhitelistedHolder(holder);
        }
    }

    function setWhitelistedFalse(address holder) internal {
        if (whitelist[holder]) {
            whitelist[holder] = false;
            globalTotal_maxContribution = globalTotal_maxContribution.sub(
                maxHolderContribution
            );
        }
    }

    /**
        @notice whitelistMultiple allows an authorized
            wallet to whitelist up to 8 wallets per
            transaction. A tedious way to do it for someone
            with less technical know how it is the easiest
            using a tool like bscscan or ethersacan to do
            so as they don't have to worry about properly
            formatting the array input ["0x0123","0x123"]
            and only have to enter the address with no formating
     */

    function whitelistMultiple_OAUTH(
        address holder0,
        address holder1,
        address holder2,
        address holder3,
        address holder4,
        address holder5,
        address holder6,
        address holder7
    ) 
        external
        onlyAuthorized
    {
        _whitelistMultiple(
            holder0,
            holder1,
            holder2,
            holder3,
            holder4,
            holder5,
            holder6,
            holder7
        );
    }

    function _whitelistMultiple(
        address holder0,
        address holder1,
        address holder2,
        address holder3,
        address holder4,
        address holder5,
        address holder6,
        address holder7
    ) internal {
        if (holder0 != address(0)) {
            setWhitelistedTrue(holder0);
        }
        if (holder1 != address(0)) {
            setWhitelistedTrue(holder1);
        }
        if (holder2 != address(0)) {
            setWhitelistedTrue(holder2);
        }
        if (holder3 != address(0)) {
            setWhitelistedTrue(holder3);
        }
        if (holder4 != address(0)) {
            setWhitelistedTrue(holder4);
        }
        if (holder5 != address(0)) {
            setWhitelistedTrue(holder5);
        }
        if (holder6 != address(0)) {
            setWhitelistedTrue(holder6);
        }
        if (holder7 != address(0)) {
            setWhitelistedTrue(holder7);
        }
    }

    function whitelistBatch_OAUTH(
        address[] memory holders
    )
        external
        onlyAuthorized
    {
        checkBatchLength(holders.length);
        for (uint16 i = 0;i < holders.length;i++) {
            setWhitelistedTrue(holders[i]);
        }
    }

    /**
        @notice contractTokenBalance returns the balance of desired token held
            by the contract.
        @param token => the token address we want to check the balance of.
        @return balance => the requested token balance
     */
    function contractTokenBalance(address token)
        external
        view
        returns (uint256 balance)
    {
        return IERC20(token).balanceOf(address(this));
    }

    /**
        @notice contractNativeCoinBalance returns the balance of the native
            coin (ETH, BNB, etc) held by the contract.
        @return balance => the requested token balance
     */
    function contractNativeCoinBalance()
        internal
        view
        returns (uint256 balance)
    {
        return address(this).balance;
    }

    /** 
        @notice if tokens get stuck we can use this to retrieve them
        @param token the token to withdraw
        @param amount the amount to withdraw
        @param to the reciever of the withdrawn tokens
        @notice fires AdminTokenWithdrawal log
        @return true if successful
    */
    function adminTokenWithdrawal_OAUTH(
        address token,
        uint256 amount,
        address to
    )
        external
        onlyAuthorized
        returns (bool)
    {
        // initialize the ERC20 instance
        IERC20 ERC20Instance = IERC20(token);
        // make sure the contract holds the requested balance
        require(
            ERC20Instance.balanceOf(address(this)) > amount,
            "PRESALE FORK: adminTokenWithdrawal() - insufficient balance"
        );
        ERC20Instance.transfer(to, amount);
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
        return true;
    }

    /** 
        @notice transferClaimedBNB() sends the collected presale
            BNB to the creamery
     */
    function transferContributedBNB_OAUTH() external onlyAuthorized {
        if(cappedPresaleEnabled){
            checkSoftCapHit();
        }
        uint256 value = address(this).balance;
        (bool success, ) = payable(address(Creamery)).call{value: value}("");
        checkTransferSuccess(success);
    }

    /**
        @notice setHolder function is called by dev to fix an error in an
            account. most likely this function will enver need to be called.
        @param whitelist_ true/false, only addresses set to 'true' may partake
        @param blacklist_ true/false, addresses set to 'true' cannot partake
        @param completedClaims_ true/false has the holder maxed out their
            claims?
        @param completedContributions_ true/false has the holder maxed out
            their contributions?
        @param holder The wallet address of the holder
        @param claimedFORK_ the holders total claimed FORK
        @param contributions_ the holders total BNB contributions
    */
    function setHolder_OICM(
        bool blacklist_,
        bool whitelist_,
        bool completedClaims_,
        bool completedContributions_,
        address holder,
        uint256 claimedFORK_,
        uint256 contributions_
    )
        external
        onlyIceCreamMan
    {
        _setHolder(
            blacklist_,
            whitelist_,
            completedClaims_,
            completedContributions_,
            holder,
            claimedFORK_,
            contributions_
        );
    }

    function _setHolder(
        bool blacklist_,
        bool whitelist_,
        bool completedClaims_,
        bool completedContributions_,
        address holder,
        uint256 claimedFORK_,
        uint256 contributions_
    )
        internal
    {
        completedClaims[holder] = completedClaims_;
        completedContributions[holder] = completedContributions_;
        contributions[holder] = contributions_;
        claimedFORK[holder] = claimedFORK_;
        whitelist[holder] = whitelist_;
        blacklist[holder] = blacklist_;
    }
    
    modifier checkOverrides_cappedPresale() {
        if(!overridesAllowed_cappedPresale){
            checkCappedPresaleIsNotInitialized();
        } else {
            checkOverridesAllowedCappedPresale();
        }
        _;
     }

    function checkCappedPresaleIsNotInitialized() internal view {
        require(
            cappedPresaleInitialized == false,
            "PRESALE FORK: Presale has already been initialized."
        );
     }

    function checkOverridesAllowedCappedPresale() internal view {
        require(
            overridesAllowed_cappedPresale,
            "PRESALE FORK: Overrides After Contract Launch Are Disabled."
        );
     }

    function checkHoldersClaimedFORK(address holder) internal view {
        require(
            claimedFORK[holder] <= getMaxClaimableFORK(),
            "PRESALE FORK: _claim() - Claim exceeds total claimable FORK"
        );
     }

    function checkBatchLength(uint256 batchLength) internal view {
        require(
            batchLength <= maxBatchLength,
            "PRESALE FORK: batchAddHolder() - list length exceeds max"
        );
     }

    function checkValueIsLessThanContributed(
        address holder, 
        uint256 value
     )
        internal 
        view 
     {
        require(
            value <= contributions[holder],
            "PRESALE FORK: _claim() - Claim exceeds total claimable FORK"
        );
     }

    function checkTransferSuccess(bool success) internal pure {
        require(
            success,
            "PRESALE FORK: checkTransferSuccess() - transferFailed"
        );
     }

    function checkRefundsEnabled() internal view {
        require(
            softCapMissedRefundEnabled,
            "PRESALE FORK: The missed soft cap refunds have not been enabled"
        );
     }

    function checkHoldersClaimableRefund(
        address holder
     )
        internal
        view
        returns (uint256)
     {
        uint256 value = getHoldersClaimableRefund(holder);
        require(
            value > 0,
            "PRESALE FORK: checkHoldersClaimableRefund() - holder has no refund to claim"
        );
        return value;
     }

    function checkHoldersClaimableFORK(
        address holder
     )
        internal
        view
        returns (uint256)
     {
        uint256 amount = getHoldersClaimableFORK(holder);
        require(
            amount > 0,
            "PRESALE FORK: checkHoldersClaimableFORK() - holder has no tokens to claim"
        );
        return amount;
     }

    function checkHolderCompletedClaims(address holder) internal view {
        require(
            !completedClaims[holder],
            "PRESALE FORK: checkHolderCompletedClaims() - holder already hit max claims"
        );
     }

     /**
        @notice checks if holder is blacklisted
        @dev reverts if they are
     */     
    function checkBlacklist(address holder) internal view {
        require(
            !blacklist[holder],
            "PRESALE FORK: checkBlacklist() - WALLET BLACKLISTED! What did you do?"
        );
     }

     /**
        @notice checks if holder is whitelisted
        @dev reverts if they are not
     */
    function checkWhitelist(address holder) internal view {        
        if(enforceWhitelist){
            require(
                whitelist[holder],
                "PRESALE FORK: checkWhitelist() - NOT WHITELISTED! https://newOlypmusbsc.com/"
            );
        }
     }

     /**
        @notice checks to make sure the requested contribution is less than
            or equal to both the holders remaining contribution AND the global
            individual contribution limit
        @dev reverts on failure
     */
    function checkHolderMaxContribution(
        address holder,
        uint256 value
     ) internal view {
        require(
            value <= getRemainingBNBcontribution(holder),
            "PRESALE FORK: value exceeds holder's remaining allowed contribution"
        );
     }

     /**
        @notice checks to make sure the requested contribution is greater
            than or equal to the minimum contribution
        @dev reverts on failure
     */
    function checkHolderMinContribution(uint256 value) internal view {
        require(
            value >= minHolderContribution,
            "PRESALE FORK: value is less than the minimum contribution"
        );
     }

    function checkNotInitialized() internal view {
        require(
            !initialized,
            "PRESALE FORK: checkNotInitialized() - Already Initialized!"
        );
     }

    function checkContributionsEnabled() internal view {
        // if we should check 'contributionsEnabled'
        if(shouldCheckContributionsEnabled) {
            // check if contributions are enabled
            require(
                contributionsEnabled,
                "PRESALE FORK: checkContributionsEnabled() - Contributions not enabled."
            );
        }
     }
    function checkHardCapHit() internal view {        
        require(
            !hardCapHit(),
            "PRESALE FORK: Cap Reached! ...ask a dev to increase it"
        );
     }
    
    function checkNewHardCap(uint256 newHardCap) internal view {
        require(
            newHardCap > globalTotal_contributions,
            "PRESALE FORK: hardCap must be more than total contributions"
        );
     }

    function checkNewSoftCap(
        uint256 newHardCap,
        uint256 newSoftCap
     )
        internal
        pure
     {
        require(
            newSoftCap < newHardCap,
            "PRESALE FORK: checkNewSoftCap() - softCap must be less than hardCap"
        );
     }

    function checkClaimsEnabled() internal view {
        require(
            claimsEnabled,
            "PRESALE FORK: checkClaimsEnabled() - Claiming FORK is not enabled."
        );
     }

    function checkSoftCapHit() internal view {
        require(
            globalTotal_contributions > softCap,
            "PRESALE FORK: checkSoftCapHit() - Soft Cap Not Hit."
        );
     }

 }