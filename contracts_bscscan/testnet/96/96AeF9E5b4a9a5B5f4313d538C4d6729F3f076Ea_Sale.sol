pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ISwapStakingContract.sol";
import "./interface/IWhiteList.sol";
/**
 * @dev core contract for making token sale process:
 * I   Register stage - init 'sale event' with respected params
 * II  Approve stage - register sale memebers (wallets) with sale share
 * III Sale stage - reveive approved memebers payments
 * IV  Claim stage - calc sold tokens, allow members to claim sold tokens
 */

contract Sale is Ownable, AccessControl {   

    bytes32 private constant CREATE_SALE_ROLE = keccak256("CREATE_SALE_ROLE");
    string constant INCORRECTSTATE = "Sale:incorrect state";
    enum stages {
        UNKNOWN,
        REGISTER,
        APPROVE,
        SALE,
        CLAIM
    }
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct saleRecord {
        address saleOwner; // sale owner
        IERC20 token; // token for sale
        uint256 tokenAmount; // amount of tokens for sale
        string name; // sale event name
        IERC20 paymentToken; // payment token, stable coin or other
        ISwapStakingContract staking; // staking contract, by default used base staking contract
        uint256[6] dates; // sale date start/stop conditions {0 - APPROVE, 1 - SALE, 2 - CLAIM}
        uint256 tokenPrice; // sale token price in payment tokens (Rate), 1 paymentToken = 1000, to get real need to divide by 1000
        uint256 maxUserStakeAmount; // max possible ammunt of stake per user
        uint256 stakeAllocationAmount; // allocation for stake wallets
        uint256 receivedPayments; // total payments received from users
        uint256 soldTokens; // total sold tokens
        uint256[2] participants; // 0-max participants, 1-participants
    }

    // struct for staked allocation for user and claimed flag
    struct stakedallocs {
        uint256 staked; // staked allocations values
        bool claimed; // is claimed purchased tokens
    }

    
    uint256 public minStakeForRegister;
    address public whiteList;

    // sales list
    mapping(uint256 => saleRecord) public sales;
    uint256 public totalSales;

    // allocation lists by sales
    // saleID => wallet => stakedallocs {staked_value, is_claimed}
    mapping(uint256 => mapping(address => stakedallocs)) saleAllocations;

    // payment from the user by sale, need to check only one payment by user
    // saleID => wallet => payment
    mapping(uint256 => mapping(address => uint256)) salePayments;

    ISwapStakingContract public baseStaking;

    // Events
    event SaleCreated(address owner, uint256 saleid);
    event SaleAllocAdded(address owner, uint256 saleid, uint256 amount);

    modifier onlySaleOperator() {
        require(hasRole(CREATE_SALE_ROLE, msg.sender), "sale:incorrect sale role");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sale:incorrect admin role");
        _;
    }

    constructor(address _stakingContract) public {
        require(_stakingContract != address(0), "Sale: need staking contract!");
        totalSales = 0;
        baseStaking = ISwapStakingContract(_stakingContract);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATE_SALE_ROLE, _msgSender());
    }

    /**
     * @dev create new sale, using default staking contract
     * @param token token for sale event
     * @param tokenAmount amount of tokens for sale event
     * @param name some text value
     * @param paymentToken the payment token
     * @param tokenPrice token price in paymentTokens
     * @param dates 0-approveBlockStart 1-approveBlockStop 2-saleBlockStart 3-saleBlockStop 4-claimBlockStart 5-claimBlockStop
     * @param maximumParticipants maximum count of wallets (unique) allowed for the sale
     */

    function createSale(
        IERC20 token,
        uint256 tokenAmount,
        string memory name,
        IERC20 paymentToken,
        uint256 tokenPrice,
        uint256[6] memory dates,
        uint256 maximumParticipants,
        uint256 _maxStakeAmount
    ) public onlySaleOperator {
        require(tokenAmount > 0, "Sale:0 amount");
        require(
            dates[0] < dates[1] &&
                dates[1] < dates[2] &&
                dates[2] < dates[3] &&
                dates[3] < dates[4] &&
                dates[4] < dates[5],
            "Sale: date issue!"
        );
        totalSales++;

        uint256[2] memory participantsArr;

        participantsArr[0] = maximumParticipants;

        sales[totalSales] = saleRecord({
            saleOwner: msg.sender,
            token: token,
            tokenAmount: tokenAmount,
            name: name,
            paymentToken: paymentToken,
            staking: baseStaking,
            dates: dates,
            tokenPrice: tokenPrice,
            maxUserStakeAmount: _maxStakeAmount,  //MAX user TAKE
            stakeAllocationAmount: 0,
            receivedPayments: 0,
            soldTokens: 0,
            participants: participantsArr
        });
        // get token amount for sale event
        token.transferFrom(msg.sender, address(this), tokenAmount);
        emit SaleCreated(msg.sender, totalSales);
    }

    /**
     * @dev changeMaxParticipants - allowed only at APPROVE stage. Change maxParticipants limit for the sale
     * @param saleID - id of sales list
     * @param maximumParticipants - maxParticipants limit for the sale
     */

    /* function changeMaxParticipants(uint256 saleID, uint256 maximumParticipants) public onlySaleOperator {
        require(getSalestage(saleID) == stages.APPROVE, INCORRECTSTATE);
        require(maximumParticipants > 0);
        sales[saleID].maxParticipants = maximumParticipants;
    } */

    /**
     * @dev sale owner withdraw sale results in all payment tokens, and the rest of not sold tokens
     * @param saleID saleID in Sales
     */

    function withdraw(uint256 saleID) public {
        require(sales[saleID].saleOwner == msg.sender, "Only owner");
        require(getSalestage(saleID) == stages.CLAIM, INCORRECTSTATE);

        // withdraw all not sold tokens
        sales[saleID].token.transfer(msg.sender, sales[saleID].tokenAmount.sub(sales[saleID].soldTokens));

        if (sales[saleID].tokenAmount > 0) {
            sales[saleID].paymentToken.transfer(msg.sender, sales[saleID].receivedPayments);
        }
    }

    /**
     * @dev changeStaking - allowed only for Owner. Change base staking contract for all sales.
     * @dev created sales will not affected, because each sale's remember staking at creation time
     * @param _newStaking - new base staking contract for all sales
     */

    function changeStaking(address _newStaking) public onlyOwner {
        require(_newStaking != address(0));
        baseStaking = ISwapStakingContract(_newStaking);
    }

    function setMinStakeRegAmount(uint256 _minStakeRegAmount) external onlyOwner {
        minStakeForRegister = _minStakeRegAmount;
    }

    function setWhiteListAddress(address _wl) external onlyOwner {
        whiteList = _wl;
    }

    /**
     * @dev changeStakingOnSale - allowed only at UNKNOWN stage (when sale just created and not started).
     * @param saleID - id of sales list
     */

    /* commented out because not scheduled feature
    function changeStakingOnSale(uint256 saleID, address _newStaking) public onlySaleOperator {
        require(getSalestage(saleID) == stages.UNKNOWN, INCORRECTSTATE);
        sales[saleID].staking = ISwapStakingContract(_newStaking);
    } */

    /**
     * @dev registerStake - allowed only at APPROVE stage. Checks staked tokens, if ok, save staked amount for allocation calcs
     * @param saleID - id of sales list
     */

    function registerStake(uint256 saleID, bytes32 _msgForSign, bytes memory _signature) public {
        require(getSalestage(saleID) == stages.APPROVE, INCORRECTSTATE);
        // Get current stake
        //uint256 curStake = sales[saleID].staking.getCurrentStake(msg.sender);
        (uint256 curStake, ) = sales[saleID].staking.userStakes(msg.sender);
        
        require(curStake > 0, "Sale:have no stake!");
        require(curStake >= minStakeForRegister, "Too little stake for register");
        
        // Get current allocation
        uint256 curAllocation = saleAllocations[saleID][msg.sender].staked;
        require(curStake > curAllocation, "Sale:only add stake!");

        if (whiteList != address(0)) {
            require(IWhiteList(whiteList).enabledForCampaign(msg.sender, saleID, _msgForSign, _signature), "Only whitelisted users");
        }

        //count new participant in total sale participants
        if (saleAllocations[saleID][msg.sender].staked == 0) {
            sales[saleID].participants[1] = sales[saleID].participants[1] + 1;
        }
        // check maxParticipants after possible adding
        require(sales[saleID].participants[0] >= sales[saleID].participants[1], "Sale: participants exceeded");

        uint staked; // final amount of stake in this function call
        //Check MAX Stake per user per campaign
        if (sales[saleID].maxUserStakeAmount > 0
            && saleAllocations[saleID][msg.sender].staked.add(
            curStake.sub(curAllocation)) > sales[saleID].maxUserStakeAmount ) {
                if(curStake.sub(curAllocation) >= sales[saleID].maxUserStakeAmount) {
                    saleAllocations[saleID][msg.sender].staked = sales[saleID].maxUserStakeAmount;
                    staked = sales[saleID].maxUserStakeAmount;
                }
                else {
                    saleAllocations[saleID][msg.sender].staked = saleAllocations[saleID][msg.sender].staked
                        .add(sales[saleID].maxUserStakeAmount.sub(curAllocation));
                    staked = sales[saleID].maxUserStakeAmount.sub(curAllocation);
                }
        }
        else {
            saleAllocations[saleID][msg.sender].staked = saleAllocations[saleID][msg.sender].staked.add(
            curStake.sub(curAllocation)
            );
            staked = curStake.sub(curAllocation);    
        }
        // increase total allocations
        sales[saleID].stakeAllocationAmount = sales[saleID].stakeAllocationAmount.add(staked);
        emit SaleAllocAdded(msg.sender, saleID, staked);
    }

    /**
     * @dev register token sale, can be done multiple times, accumulated at salePayments[saleID][msg.sender] respects stake limits
     * @param saleID id of sales
     * @param paymentAmount amount of payment token to get from user
     */

    function registerSale(uint256 saleID, uint256 paymentAmount) public {
        require(getSalestage(saleID) == stages.SALE, INCORRECTSTATE);
        require(
            salePayments[saleID][msg.sender].add(paymentAmount) <=
                (saleAllocations[saleID][msg.sender].staked.mul(1e9).div(sales[saleID].stakeAllocationAmount))
                    .mul(sales[saleID].tokenAmount)
                    .mul(sales[saleID].tokenPrice)
                    .div(1e12), // 10**3 * 10**9
            "Sale:payment exceeds"
        );

        salePayments[saleID][msg.sender] = salePayments[saleID][msg.sender].add(paymentAmount);
        sales[saleID].receivedPayments = sales[saleID].receivedPayments.add(paymentAmount);
        sales[saleID].paymentToken.transferFrom(msg.sender, address(this), paymentAmount);
        sales[saleID].soldTokens = sales[saleID].soldTokens.add(paymentAmount.mul(1e3).div(sales[saleID].tokenPrice));
    }

    /**
     * @dev view sale balance available
     * @param saleID id of sales
     * @param userID user's wallet
     * @return balanceRest rest balance for the sale
     * @return payments total users payments done at the sale
     */

    function getSaleBalanceRest(uint256 saleID, address userID)
        public
        view
        returns (uint256 balanceRest, uint256 payments)
    {
        balanceRest = saleAllocations[saleID][userID].staked.mul(1e9).div(sales[saleID].stakeAllocationAmount);
        payments = salePayments[saleID][userID];
        return (
            balanceRest.mul(sales[saleID].tokenAmount).mul(sales[saleID].tokenPrice).div(1e12).sub(
                salePayments[saleID][userID]
            ),
            payments
        );
    }

    /**
     * @dev withdraw purchased tokens
     * @param saleID id of sales
     */

    function claim(uint256 saleID) public {
        require(getSalestage(saleID) == stages.CLAIM && !saleAllocations[saleID][msg.sender].claimed, INCORRECTSTATE);
        (uint256 purchasedTokens, , ) = viewSale(saleID, msg.sender);
        if (purchasedTokens > 0) {
            saleAllocations[saleID][msg.sender].claimed = true;
            sales[saleID].token.transfer(msg.sender, purchasedTokens);
        }
    }

    /**
     * @dev grantSaleRole runs accesscontrol grantRole for create sales only by owner
     */

    function grantSaleRole(address salesman) public onlyOwner {
        grantRole(CREATE_SALE_ROLE, salesman);
    }

    /**
     * @dev revokeRole runs accesscontrol revokeRole for create sales only by owner
     */

    function revokeSaleRole(address salesman) public onlyOwner {
        revokeRole(CREATE_SALE_ROLE, salesman);
    }

    /**
     * @dev revokeRole runs accesscontrol revokeRole for create sales only by owner
     */

    function getSaleRoleList() public view onlyOwner returns (address[] memory saleAdmins) {
        saleAdmins = new address[](getRoleMemberCount(CREATE_SALE_ROLE));
        for (uint256 index = 0; index < saleAdmins.length; index++) {
            saleAdmins[index] = getRoleMember(CREATE_SALE_ROLE, index);
        }
    }

    /**
     * @dev preview sold token amount for the wallet by saleID
     * @param saleID id of sales
     * @param wallet wallet
     * @return previewTokens number of payed tokens
     * @return claimed returns true when tokens are claimed
     * @return currAllocation registered allocation (registered amount of staked tokens)
     */

    function viewSale(uint256 saleID, address wallet)
        public
        view
        returns (
            uint256 previewTokens,
            bool claimed,
            uint256 currAllocation
        )
    {
        if (getSalestage(saleID) == stages.SALE || getSalestage(saleID) == stages.CLAIM) {
            return (
                salePayments[saleID][wallet].mul(1e3).div(sales[saleID].tokenPrice),
                saleAllocations[saleID][wallet].claimed,
                saleAllocations[saleID][wallet].staked
            );
        } else {
            return (0, saleAllocations[saleID][wallet].claimed, saleAllocations[saleID][wallet].staked);
        }
    }

    /**
     * @dev get sale participants: limit and actual count
     * @param saleID saleID in Sales
     * @return maxParticipant - limit of participants for the sale
     * @return totalParticipants - actual participants count for the sale
     */

    function getSaleParticipants(uint256 saleID)
        public
        view
        returns (uint256 maxParticipant, uint256 totalParticipants)
    {
        return (sales[saleID].participants[0], sales[saleID].participants[1]);
    }

    /**
     * @dev get stage from saleId
     * @param saleId saleID in Sales
     */

    function getSalestage(uint256 saleId) public view virtual returns (stages) {
        if (
            saleId == 0 ||
            sales[saleId].dates[0] == 0 ||
            block.number < sales[saleId].dates[0] ||
            block.number > sales[saleId].dates[5]
        ) {
            return (stages.UNKNOWN);
        } else if (block.number >= sales[saleId].dates[0] && block.number <= sales[saleId].dates[1]) {
            return (stages.APPROVE);
        } else if (block.number >= sales[saleId].dates[2] && block.number <= sales[saleId].dates[3]) {
            return (stages.SALE);
        } else if (block.number >= sales[saleId].dates[4] && block.number <= sales[saleId].dates[5]) {
            return (stages.CLAIM);
        }
    }

    function getSaleRecord(uint256 saleID)
        public
        view
        returns (
            address,
            IERC20,
            // removed by `Stake too deep` issue
            string memory,
            IERC20,
            ISwapStakingContract,
            uint256[6] memory,
            uint256
        )
    {
        return (
            sales[saleID].saleOwner,
            sales[saleID].token,
            sales[saleID].name,
            sales[saleID].paymentToken,
            sales[saleID].staking,
            sales[saleID].dates,
            sales[saleID].tokenPrice
        );
    }

    function getSaleRecord2(uint256 saleID)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            sales[saleID].maxUserStakeAmount, 
            sales[saleID].stakeAllocationAmount,
            sales[saleID].receivedPayments,
            salePayments[saleID][msg.sender]
        );
    }

    function getSaleAllocations(uint saleID, address user) public view returns(uint) {
        stakedallocs memory stakedData = saleAllocations[saleID][user];
        return stakedData.staked;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity 0.6.2;

interface ISwapStakingContract {
    function getCurrentTotalStake() external view returns (uint256);

    function getCurrentStake(address account) external view returns (uint256);

    //  for proxy stake implementation 
    function userStakes(address user) external view returns (uint256, uint256);
}

pragma solidity 0.6.2;

interface IWhiteList {

    function enabledForCampaign(address user, uint256 campaignId, bytes32 _msgForSign, bytes calldata _signature) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}