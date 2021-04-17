/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: SafeMath

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

// File: Crowdsale.sol

contract Crowdsale {
    using SafeMath for uint256;

    /// @notice MISOMarket template id for the factory contract.
    uint256 public constant marketTemplate = 1;

    /// @notice The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /** 
    * @notice rate - How many token units a buyer gets per token or wei.
    * The rate is the conversion between wei and the smallest and indivisible token unit.
    * So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    * 1 wei will give you 1 unit, or 0.001 TOK.
    */
    /// @notice goal - Minimum amount of funds to be raised in weis or tokens.
    struct MarketPrice {
        uint128 rate;
        uint128 goal; 
    }
    MarketPrice public marketPrice;

    /// @notice Starting time of crowdsale.
    /// @notice Ending time of crowdsale.
    /// @notice Total number of tokens to sell.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime; 
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    /// @notice Amount of wei raised.
    /// @notice Whether crowdsale has been initialized or not.
    /// @notice Whether crowdsale has been finalized or not.
    struct MarketStatus {
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
    }
    MarketStatus public marketStatus;

    /// @notice The token being sold.
    address public auctionToken;
    /// @notice Address where funds are collected.
    address payable private wallet;
    /// @notice The currency the crowdsale accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    /// @notice Address that manages auction approvals.
    address public pointList;

    /// @notice The commited amount of accounts.
    mapping(address => uint256) public commitments;
    /// @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    /// @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime); 
    /// @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 rate, uint256 goal); 
    /// @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet); 

    /// @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);
    
    /// @notice Event for finalization of the crowdsale
    event AuctionFinalized();

    /**
     * @notice Initializes main contract variables and transfers funds for the sale.
     * @dev Init function.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _admin Address that can finalize auction.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initCrowdsale(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(_startTime < 10000000000, 'Crowdsale: enter an unix timestamp in seconds, not miliseconds');
        require(_endTime < 10000000000, 'Crowdsale: enter an unix timestamp in seconds, not miliseconds');
        require(_startTime >= block.timestamp, "Crowdsale: start time is before current time");
        require(_endTime > _startTime, "Crowdsale: start time is not before end time");
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(_admin != address(0), "Crowdsale: admin is the zero address");
        require(_totalTokens > 0, "Crowdsale: total tokens is 0");
        require(_goal > 0, "Crowdsale: goal is 0");

        marketPrice.rate = uint128(_rate);
        marketPrice.goal = uint128(_goal);

        marketInfo.startTime = uint64(_startTime);
        marketInfo.endTime = uint64(_endTime);
        marketInfo.totalTokens = uint128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        wallet = _wallet;

    }


    ///--------------------------------------------------------
    /// Commit to buying tokens!
    ///--------------------------------------------------------

    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /** 
     * @dev Attribution to the awesome delta.financial contracts
    */  
    function marketParticipationAgreement() public pure returns (string memory) {
        return "I understand that I'm interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I reviewed code of the smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }
    /** 
     * @dev Not using modifiers is a purposeful choice for code readability.
    */ 
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert("No agreement provided, please review the smart contract before interacting with it");
    }


}