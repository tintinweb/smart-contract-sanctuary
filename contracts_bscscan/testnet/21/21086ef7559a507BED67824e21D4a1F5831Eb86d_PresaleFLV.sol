/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
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
    function initialize(address ownableFlavors) external;

    // onlyOwnable
    function burnItAllDown_OO() external;

    // onlyFlavorsToken
    function launch_OFT() external;
    function weSentYouSomething_OFT(uint256 amount) external;

    // onlyAdmin
    function updateOwnable_OAD(address new_ownableFlavors) external;

    function deposit(string memory note) external payable;
    // authorized
    function spiltMilk(uint256 value) external;
}
/* ------------ END OF IMPORT ICreamery.sol ---------- */


/* ---------- START OF IMPORT IFlavors.sol ---------- */




interface IFlavors {

  function presaleClaim(address presaleContract, uint256 amount) external;
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

  //onlyOwnableFlavors
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
/* ------------ END OF IMPORT IFlavors.sol ---------- */


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


contract FlavorsAccess is Context {
    address internal iceCreamMan;
    address internal pendingICM;
    address internal flavorsToken;
    address internal creamery;
    mapping(address => bool) private authorizations;
    function grantAuthorization_OICM(address authorizedAddress)
        external
        onlyIceCreamMan
    {
        require(
            _grantAuthorization(authorizedAddress),
            "PRESALE FLV: grantAuthorization() = internal call failed"
        );
    }

    function _grantAuthorization(address authorizedAddress)
        internal
        returns (bool)
    {
        authorizations[authorizedAddress] = true;
        return true;
    }

    function revokeAuthorization_OICM(address revokedAddress)
        external
        onlyIceCreamMan
    {
        require(
            _revokeAuthorization(revokedAddress),
            "PRESALE FLV: revokeAuthorization() = internal call failed"
        );
    }

    function _revokeAuthorization(address revokedAddress)
        internal
        returns (bool)
    {
        authorizations[revokedAddress] = false;
        return true;
    }

    function isAuthorized(address addr) internal view returns (bool) {
        return authorizations[addr];
    }

    function transferICM_OICM(address new_iceCreamMan) external onlyIceCreamMan {
        require(
            _transferICM(new_iceCreamMan),
            "PRESALE FLV: transferICM() = internal call to _transferICM failed"
        );
    }

    function _transferICM(address new_iceCreamMan) internal returns (bool) {
        pendingICM = new_iceCreamMan;
        return true;
    }

    function acceptIceCreamMan_OPICM() external onlyPendingIceCreamMan {
        require(
            _acceptIceCreamMan(),
            "PRESALE FLV: acceptIceCreamMan() = internal call failed"
        );
    }

    function _acceptIceCreamMan() internal returns (bool) {
        iceCreamMan = pendingICM;
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        return true;
    }

    modifier onlyAuthorized() {
        require(
            isAuthorized(_msgSender()),
            "PRESALE FLV: onlyAuthorized() = caller not authorized"
        );
        _;
    }

    modifier onlyPendingIceCreamMan() {
        require(
            pendingICM == _msgSender(),
            "PRESALE FLV: onlyPendingIceCreamMan() = caller not pendingICM"
        );
        _;
    }

    modifier onlyCreamery() {
        require(
            creamery == _msgSender(),
            "PRESALE FLV: onlyCreamery() = caller not creamery"
        );
        _;
    }

    modifier onlyFlavorsToken() {
        require(
            flavorsToken == _msgSender(),
            "PRESALE FLV: onlyFlavorsToken() = caller not flavorsToken"
        );
        _;
    }

    modifier onlyIceCreamMan() {
        require(
            iceCreamMan == _msgSender(),
            "PRESALE FLV: onlyIceCreamMan() = caller not iceCreamMan"
        );
        _;
    }
}

contract PresaleFLV is FlavorsAccess {
    using SafeMath for uint256;
    
    // type declarations
    IFlavors internal FLV;
    ICreamery internal Creamery;

    // state variables
    bool internal firstClaimsToggle = true;
    bool internal initialized = false;
    bool internal claimsEnabled;
    bool internal contributionsEnabled;
    bool internal useTokensInContract = false;
    uint16 internal maxBatchLength = 100;
    uint8 constant DECIMALS_BNB = 18;
    uint8 constant DECIMALS_FLV = 9;
    uint64 constant BLOCKS_PER_DAY = 28800;
    uint256 internal globalTotal_claims;
    uint256 internal globalTotal_contributions;
    // The presale rate. 1 bnb equals this many FLV
    // discounted 5% off the dxSale rate of 100,000 per BNB
    // 100,000/.95 = 105,263
    uint256 internal flvPerNativeCoin = 105_000 * (10**DECIMALS_FLV);
    uint256 internal claimsEnabledOnBlockNumber;
    // initialize addresses and contracts
    uint256 public timestampContributionsEnabled = 1634169600;
    uint256 public timestampContributionsDisabled = timestampContributionsEnabled + 2 days;
    
    uint256 internal timestampClaimsEnabled;
    // the sum of all whitelisted addresses max possible contribution
    uint256 internal globalTotal_maxContribution = 0;
    // the max contribution to the private presale
    uint256 internal maxHolderContribution = 8 ether;
    mapping(address => bool) internal _isOG;
    // whitelist
    mapping(address => bool) internal whitelist;
    // blacklist
    mapping(address => bool) internal blacklist;
    // The amount of BNB the holder has contributed
    mapping(address => uint256) internal contributions;
    // The amount of FLV the holder has claimed
    mapping(address => uint256) internal claimedFLV;
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
        string indexed note
    );

    /**
        @dev HolderAdded => Triggers on any successful call to
            addHolder().
        @param holder: The address of the holder added
     */
    event HolderAdded(address indexed holder);

    // modifiers
    modifier checkClaimsEnabled() {       
        require(
            claimsEnabled,
            "PRESALE FLV: checkClaimsEnabled() = Claiming FLV is not enabled."
        );
        _;
    }

    bool shouldCheckContributionsEnabled = true;
    function toggleShouldCheckContributionsEnabled_OICM() external onlyIceCreamMan returns (bool){
        shouldCheckContributionsEnabled
            ? shouldCheckContributionsEnabled = false
            : shouldCheckContributionsEnabled = true;
        return shouldCheckContributionsEnabled;
    }
    
    modifier checkContributionsEnabled() {
        if(shouldCheckContributionsEnabled) {
            if(block.timestamp > timestampContributionsEnabled){
                contributionsEnabled = true;
            }
            if(block.timestamp > timestampContributionsDisabled){
                contributionsEnabled = false;
            }
            require(
                contributionsEnabled,
                "PRESALE FLV: checkContributionsEnabled() = Contributions not enabled."
            );
        }
        _;
    }

    // functions
    function timeUntilContributionsEnabled() external view returns (uint256) {
        if(block.timestamp > timestampContributionsEnabled) {
            return 0;
        } else {
            return timestampContributionsEnabled.sub(block.timestamp);
        }
    }


    function isOG_OFT(
        address
        holder
    )
        external
        view
        onlyFlavorsToken
        returns(bool isOG_)
    {
        return _isOG[holder];
    }

    function canISell() external view returns (bool canISell_) {
        if (1 <= getHoldersMaxSellAfterAlreadySold(_msgSender())) {
            return true;
        } else {
            return false;
        }
    }

    function canHolderSell_OFT(address holder, uint256 amount)
        external
        view
        onlyFlavorsToken
        returns (bool canHolderSell_)
    {
        return _canHolderSell(holder, amount);
    }

    function _canHolderSell(address holder, uint256 amount)
        internal
        view
        returns (bool canHolderSell_)
    {
        if (amount <= getHoldersMaxSellAfterAlreadySold(holder)) {
            return true;
        } else {
            return false;
        }
    }

    /**
        @notice calculates the day number since claims were enabled
            at the time of the pancakeswap launch. We start
            with day 1, allowing presale/migrate holders to sell
            up to 10% immediately.
        @dev used to calculate if a presale / migrate wallet
            can sell according the the 10% per day schedule
        @return dayNumber_ The day number since the pancake launch    
     */
    function dayNumber() internal view returns (uint256 dayNumber_) {
        // subtract, divide, then add => ((a-b)/c)+d
        if (claimsEnabled) {
            return (
                (
                    ((block.number).sub(claimsEnabledOnBlockNumber)).div(
                        BLOCKS_PER_DAY
                    )
                ).add(1)
            );
        } else {
            return 0;
        }
    }

    /**
        @notice calculates holders maximum sellable amount for the number
            of days passed.
        @dev multiplies the number of days by 10% of the total claimed flv
        @param holder the holders wallet address
        @return maximum claimed flv allowed to sell on this day.
     */
    function getHoldersMaxSell(address holder) internal view returns (uint256) {
        // multiply, multiply, then divide => a*b*10/100
        return claimedFLV[holder].mul(dayNumber()).mul(10).div(100);
    }

    /**
        @notice calculates the number of tokens obtained from the presale
            or migration the holder has sold. NOTE this is done by 
            subtracting the current balance from the claimed balance.
        @dev NOTE does not take into account the possibility the holder
            bought additional tokens since the presale/migration or has
            transferred any in or out. As a result we will stress to everyone
            to not use their presale/migration wallet to buy additional FLV
            during the first 10 days. Doing this would require additional gas
            on every single transaction for every single holder forever
            because we would need to update the presale/migration contract
            with every buy/transfer/sell. So if a holder has claimed for
            example, 100,000 tokens, and bought another 50,000, they would not
            be able to sell any during the remainder of the first 10 days.
        @param holder the holders wallet address
        @return the amount of tokens the holder has sold (assuming no
            transfers or buys)
    */
    function getHoldersClaimsAlreadySold(address holder)
        internal
        view
        returns (uint256)
    {
        if (address(FLV) == address(0)) {
            return 0;
        } else if (FLV.balanceOf(holder) > claimedFLV[holder]) {
            return 0;
        } else {
            // subtract => a-b
            return claimedFLV[holder].sub(FLV.balanceOf(holder));
        }
    }

    /**
        @notice calculates the amount the holder is currently able to sell
            by checking their current balance, comparing it to their calimed
            balance, and the current day since luanch
        @dev NOTE does not take into account buys/transfers. see note above
        @param holder the holders wallet address    
    */
    function getHoldersMaxSellAfterAlreadySold(address holder)
        internal
        view
        returns (uint256)
    {
        // subtract => a-b
        uint256 holdersMaxSell = getHoldersMaxSell(holder);
        uint256 holdersClaimsAlreadySold = getHoldersClaimsAlreadySold(holder);
        if (holdersClaimsAlreadySold > holdersMaxSell) {
            return 0;
        } else {
            return (holdersMaxSell.sub(holdersClaimsAlreadySold));
        }
    }

    function getMaxClaimableFLV() internal view returns (uint256) {
        // multiply, then apply decimals => (a*b)/(10^d)
        return
            (maxHolderContribution.mul(flvPerNativeCoin)).div(10**DECIMALS_BNB);
    }

    function getRemainingBNBcontribution(address holder)
        internal
        view
        returns (uint256)
    {
        if (whitelist[holder]) {
            // subtract => a-b
            return maxHolderContribution.sub(contributions[holder]);
        } else {
            return 0;
        }
    }

    function getRemainingMaxClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {
        if (whitelist[holder]) {
            // subtract => a-b
            return getMaxClaimableFLV().sub(claimedFLV[holder]);
        } else {
            return 0;
        }
    }

    function getHoldersClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {
        // multiply, multiply, divide, apply decimals,
        // then subtract => (a*b*c/d/(10^e))-f
        return (
            (contributions[holder].mul(flvPerNativeCoin).div(10**DECIMALS_BNB))
                .sub(claimedFLV[holder])
        );
    }

    function enableClaims_OFT() external onlyFlavorsToken {
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
        }
        claimsEnabled = true;
    }

    function forceClaimsEnabledBlockNumber_OICM(uint256 blockNumber)
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
        claimsEnabled ? claimsEnabled = false : claimsEnabled = true;
    }

    function toggleContributions_OICM() external onlyIceCreamMan {
        contributionsEnabled
            ? contributionsEnabled = false
            : contributionsEnabled = true;
    }

    function initialize(address iceCreamMan_) external {
        require(
            !initialized,
            "PRESALE FLV: initialize() = Already Initialized!"
        );
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        iceCreamMan = iceCreamMan_;
        _grantAuthorization(iceCreamMan);
        _grantAuthorization(address(this));
        initialized = true;
    }
    
    function getAddresses()
        external
        view
        returns (
            address presaleFLV,
            address flv,
            address creamery,
            address iceCreamMan_,
            address pendingICM_
        )
    {
        return (
            address(this),
            address(FLV),
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
            uint256 dayNumber_,
            uint256 globalTotal_maxContribution_,
            uint256 globalTotal_contributions_,
            uint256 globalTotal_claims_,
            uint256 flvPerNativeCoin_,
            bool claimsEnabled_,
            bool contributionsEnabled_
        )
    {
        return (
            claimsEnabledOnBlockNumber,
            dayNumber(),
            globalTotal_maxContribution,
            globalTotal_contributions,
            globalTotal_claims,
            flvPerNativeCoin,
            claimsEnabled,
            contributionsEnabled
        );
    }

    function getMyInfo()
        external
        view
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFLV,
            uint256 holdersCurrentMaxSell,
            uint256 holderContributions_,
            uint256 claimedFLV_,
            bool completedContributions_,
            bool completedClaims_
        )
    {
        return _getHolderInfo(_msgSender());
    }

    function getHolderInfo(address holder)
        external
        view
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFLV,
            uint256 holdersCurrentMaxSell,
            uint256 holderContributions_,
            uint256 claimedFLV_,
            bool completedContributions_,
            bool completedClaims_
        )
    {
        return _getHolderInfo(holder);
    }

    function _getHolderInfo(address holder)
        internal
        view        
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFLV,
            uint256 holdersCurrentMaxSell,
            uint256 holderContributions_,
            uint256 claimedFLV_,
            bool completedContributions_,
            bool completedClaims_
        )
    {
        if (_isOG[holder]) {
            return (
                maxHolderContribution.sub(contributions[holder]),
                getHoldersClaimableFLV(holder),
                getHoldersMaxSellAfterAlreadySold(holder),
                contributions[holder],
                claimedFLV[holder],
                completedContributions[holder],
                completedClaims[holder]
            );
        } else {
            return (0, 0, 0, 0, 0, false, false);
        }
    }

    /**
        @notice Contribute to the presale.
    */
    function contribute_OWL() external payable checkContributionsEnabled {
        address holder = _msgSender();
        uint256 value = _msgValue();
        require(
            !blacklist[holder],
            "PRESALE FLV: contribute() = holder BLACKLISTED! What did you do?"
        );
        require(
            whitelist[holder],
            "PRESALE FLV: contribute() = NOT WHITELISTED! For info https://flavorsbsc.com/"
        );
        // check if the holder has already maxed out
        require(
            !completedContributions[holder],
            "PRESALE FLV: contribute() = holder already hit max contribution"
        );
        // check the holders remaining contribution
        require(
            value <= getRemainingBNBcontribution(holder),
            "PRESALE FLV: contribute() = exceeds holder's allowed contribution"
        );
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
        globalTotal_contributions = globalTotal_contributions.add(amount);
        if (getRemainingBNBcontribution(holder) == 0) {
            completedContributions[holder] = true;
        }
        emit ContributionReceived(
            holder,
            amount,
            contributions[holder],
            getRemainingBNBcontribution(holder),
            globalTotal_contributions,
            "PRESALE FLV: Contribution Received"
        );
    }

    /**
        @notice Called by holders to claim their FLV once enabled
        @notice requires holder is not blacklisted
        @notice requires holder has not completed their claims
     */

    function claim_OWL() external checkClaimsEnabled {
        address holder = _msgSender();
        require(
            !blacklist[holder],
            "PRESALE FLV: claim() = WALLET BLACKLISTED! What did you do?"
        );
        require(
            whitelist[holder],
            "PRESALE FLV: claim() = NOT WHITELISTED! https://flavorsbsc.com/"
        );
        require(
            !completedClaims[holder],
            "PRESALE FLV: claim() = holder already hit max claims"
        );
        uint256 amount = getHoldersClaimableFLV(holder);
        require(
            amount > 0,
            "PRESALE FLV: claim() = holder has no tokens to claim"
        );

        _claim(holder, amount);
    }

    /**
        @notice updates the state variables for the claim BEFORE we transfer
            the claim.
        @notice Performs additional security checks on the claim.
        @notice requires amount is less than the holders remaining unclaimed
            amount
        @notice requires that, if the transfer is successful, the holders
            claimedFLV does not exceed the holders total claimable FLV
        @notice requires the transfer of claimed tokens is successful
        @notice After verification hands the verified amount and holder to the
            transfering function 'processClaim'
        @dev Internal function callable by functions within the contract
     */
    function _claim(address holder, uint256 amount) internal {
        require(
            amount <= getRemainingMaxClaimableFLV(holder),
            "PRESALE FLV: _claim() = claim exceeds remaining unclaimed FLV"
        );
        // update the values in the contract FIRST, then process the transfer
        globalTotal_claims = globalTotal_claims.add(amount);
        claimedFLV[holder] = claimedFLV[holder].add(amount);
        require(
            claimedFLV[holder] <= getMaxClaimableFLV(),
            "PRESALE FLV: _claim() = Claim exceeds total claimable FLV"
        );
        if (getRemainingMaxClaimableFLV(holder) == 0) {
            completedClaims[holder] = true;
        }
        require(
            processClaim(holder, amount),
            "PRESALE FLV: _claim() = transfer of claimed tokens failed."
        );
    }

    /**
        @notice setUseTokensInContract selects the source of tokens for presale claims.
        @param useTokensInContract_ set to true and the presale contract will fund the
        claims from tokens in this contract. they must be deposited prior. Set to
        false and the tokens will be minted direct from the main token contract
     */
    function useTokensInContract_OICM(bool useTokensInContract_)
        external
        onlyIceCreamMan
    {
        useTokensInContract = useTokensInContract_;
    }

    /**
        @notice Handles the actual transfer of claimed FLV to the holder
        @dev Internal private function may be called by any function within
            this contract
        @param holder The holder address who will receive the FLV tokens
        @param amount The total amount of FLV to transfer to the holder
        @return returns true on a successful transfer
     */
    function processClaim(address holder, uint256 amount)
        private
        returns (bool)
    {
        if (!useTokensInContract) {
            FLV.presaleClaim(address(this), amount);
        }
        return FLV.transfer(holder, amount);
    }

    /**
        @notice call to update multiple contract parameters
        @dev External function callable by onlyIceCreamMan
        @param flv The Flavors Contract address which we are contributing to
        @param creamery The address of the Creamery, the receiver of the
            funds contributed to the presale.
        @param flvPerNativeCoin_ The rate for calculating claimed tokens.
            Input the value as a whole number. The decimals are removed later.
              So for 1,234,567 enter 1234567.
            The output value of the number when checked with the 'getInfo' 
            function will show the 9 decimals removed => 1234567000000000
        @param maxHolderContribution_ The max contribution per holder in whole
            native coin example: for 8 BNB enter 8 NOTE cannot do decimals
            with this method.
     */
    function set_OICM(
        address flv,
        address creamery,
        uint16 maxBatchLength_,
        uint256 maxHolderContribution_,
        uint256 flvPerNativeCoin_
    )
        external
        onlyIceCreamMan
    {
        setAddressFLV(flv);
        setAddressCreamery(creamery);
        setRateFLV(flvPerNativeCoin_);
        setMaxBatchLength(maxBatchLength_);
        setMaxHolderContribution(maxHolderContribution_);
    }

    function setMaxHolderContribution(uint256 value) internal {
        maxHolderContribution = value * 1 ether;
    }

    function setAddressCreamery(address creamery) internal {
        Creamery = ICreamery(creamery);
    }

    function setAddressFLV(address flavorsToken_) internal {
        flavorsToken = flavorsToken_;
        FLV = IFlavors(flavorsToken);
    }

    function setRateFLV(uint256 flvPerNativeCoin_) internal {
        flvPerNativeCoin = flvPerNativeCoin_.mul(10**DECIMALS_FLV);
    }

    function setMaxBatchLength(uint16 maxBatchLength_) internal {
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
            _isOG[holder] = true;
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
            _isOG[holder] = false;
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
        require(
            holders.length <= maxBatchLength,
            "PRESALE FLV: batchAddHolder() = list length exceeds max"
        );

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
    function contractNativeCoinBalance() external view returns (uint256 balance) {
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
            "PRESALE FLV: adminTokenWithdrawal() = insufficient balance"
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
        uint256 value = address(this).balance;
        (bool success, ) = payable(address(Creamery)).call{value: value}("");
        require(success, "PRESALE FLV: transferContributedBNB() = fail");
    }

    /**
        @notice setHolder function is called by dev to fix an error in an
            account. most likely this function will enver need to be called.
        @param isOG_ true/false, quick check for flavors token to check 
            vesting. all whitelisted presale contributers should be set
            to true.
        @param whitelist_ true/false, only addresses set to 'true' may partake
        @param blacklist_ true/false, addresses set to 'true' cannot partake
        @param completedClaims_ true/false has the holder maxed out their
            claims?
        @param completedContributions_ true/false has the holder maxed out
            their contributions?
        @param holder The wallet address of the holder
        @param claimedFLV_ the holders total claimed FLV
        @param contributions_ the holders total BNB contributions
    */
    function setHolder_OICM(
        bool isOG_,
        bool blacklist_,
        bool whitelist_,
        bool completedClaims_,
        bool completedContributions_,
        address holder,
        uint256 claimedFLV_,
        uint256 contributions_
    )
        external
        onlyIceCreamMan
    {
        _setHolder(
            isOG_,
            blacklist_,
            whitelist_,
            completedClaims_,
            completedContributions_,
            holder,
            claimedFLV_,
            contributions_
        );
    }

    function _setHolder(
        bool isOG_,
        bool blacklist_,
        bool whitelist_,
        bool completedClaims_,
        bool completedContributions_,
        address holder,
        uint256 claimedFLV_,
        uint256 contributions_
    )
        internal
    {
        completedClaims[holder] = completedClaims_;
        completedContributions[holder] = completedContributions_;
        contributions[holder] = contributions_;
        claimedFLV[holder] = claimedFLV_;
        _isOG[holder] = isOG_;
        whitelist[holder] = whitelist_;
        blacklist[holder] = blacklist_;
    }

}