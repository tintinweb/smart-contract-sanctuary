/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// File: contracts/IHEOStaking.sol


pragma solidity >=0.6.1;

interface IHEOStaking {
    function increaseStake(uint256 _amount, address _token, address _voter) external;

    function reduceStake(uint256 _amount, address _token, address _voter) external;

    function isVoter(address _voter) external view returns(bool);

    function stakedTokensByVoter(address voter, address token) external view returns(uint256);

    function stakedVoterByToken(address token, uint256 index) external view returns(address);

    function numStakedVotersByToken(address token) external view returns(uint256);

    function voterStake(address voter) external view returns(uint256);

    function stakedTokens(address token) external view returns(uint256);

    function totalAmountStaked() external view returns (uint256);

    function numVoters() external view returns(uint256);

    function setParams(address params) external;

    function unstakeAll() external;
}

// File: contracts/HEOLib.sol


pragma solidity >=0.6.1;

library HEOLib {
    // Indexes of reserved integer parameters
    uint8 public constant ENABLE_PARAM_VOTER_WHITELIST = 0;
    uint8 public constant ENABLE_CONTRACT_VOTER_WHITELIST = 1;
    uint8 public constant ENABLE_BUDGET_VOTER_WHITELIST = 2;
    uint8 public constant MIN_VOTE_DURATION = 3; //259200
    uint8 public constant MAX_VOTE_DURATION = 4; //7889231
    uint8 public constant MIN_PASSING_VOTE = 5; //51
    uint8 public constant DONATION_YIELD = 6; //default value is 1,000,000
    uint8 public constant DONATION_YIELD_DECIMALS = 7; //default value is 10 * 10^18
    uint8 public constant FUNDRAISING_FEE = 8; //defaut value is 250, which corresponds to 0.025 or 2.5%
    uint8 public constant FUNDRAISING_FEE_DECIMALS = 9; //defaut value is 10,000
    uint8 public constant DONATION_VESTING_SECONDS = 10; //default value is 31536000, which represents 1 year in seconds
    uint8 public constant ENABLE_FUNDRAISER_WHITELIST = 11;
    uint8 public constant ANON_CAMPAIGN_LIMIT = 12;
    uint8 public constant ANON_DONATION_LIMIT = 13;
    uint8 public constant INVESTMENT_VESTING_SECONDS = 14;

    // Indexes of reserved addr parameters
    uint8 public constant PARAM_WHITE_LIST = 0;
    uint8 public constant CONTRACT_WHITE_LIST = 1;
    uint8 public constant BUDGET_WHITE_LIST = 2;
    uint8 public constant VOTING_TOKEN_ADDRESS = 3;
    uint8 public constant ACCEPTED_COINS = 4;
    uint8 public constant FUNDRAISER_WHITE_LIST = 5;

    // Indexes of contract addresses
    uint8 public constant CAMPAIGN_FACTORY = 0;
    uint8 public constant CAMPAIGN_REGISTRY = 1;
    uint8 public constant REWARD_FARM = 2;
    uint8 public constant DAO_ADDRESS = 3;
    uint8 public constant PRICE_ORACLE = 4;
    uint8 public constant PLATFORM_TOKEN_ADDRESS = 5;
    uint8 public constant TREASURER = 6;

    enum ProposalStatus { OPEN, EXECUTED, REJECTED }
    enum ProposalType { INTVAL, ADDRVAL, BUDGET, CONTRACT }
    // Types of votes
    enum ProposedOperation {
        OP_SET_VALUE,
        OP_DELETE_PARAM,
        OP_SEND_NATIVE,
        OP_SEND_TOKEN,
        OP_WITHDRAW_NATIVE,
        OP_WITHDRAW_TOKEN
    }
    struct Proposal {
        ProposalType propType;
        address proposer;
        ProposedOperation opType;
        uint256 key;
        address[] addrs; //array of proposed addresses
        uint256[] values; //array of proposed integer values
        uint256 totalVoters; //total number of voters in this proposal
        uint256 totalWeight; //total amount voted in this proposal
        uint256 percentToPass;
        mapping(address=>uint256) stakes; // Records amounts voted by each voter
        mapping(uint256=>uint256) votes; //Maps vote options to amount of staked votes for each option
    }

    function _generateProposalId(Proposal memory proposal) internal view returns(bytes32) {
        //check requirements for budget proposals
        if(proposal.propType == ProposalType.BUDGET) {
            require(proposal.addrs[0] != address(0), "_addrs[0] cannot be empty");
            if(proposal.opType == ProposedOperation.OP_SEND_TOKEN) {
                require(proposal.addrs[1] != address(0), "_addrs[1] cannot be empty");
            } else if (proposal.opType == ProposedOperation.OP_WITHDRAW_TOKEN) {
                require(proposal.addrs[1] != address(0), "_addrs[1] cannot be empty");
            }
            return keccak256(abi.encodePacked(proposal.addrs[0], proposal.addrs[1], proposal.proposer, proposal.values[0], block.timestamp));
        } else {
            return keccak256(abi.encodePacked(uint8(proposal.propType), uint8(proposal.opType), proposal.proposer, proposal.key, block.timestamp));
        }
    }
}

// File: contracts/IHEOBudget.sol


pragma solidity >=0.6.1;

interface IHEOBudget {
    function assignTreasurer(address _treasurer) external;
    function withdraw(address _token) external;
    function transferOwnership(address payable newOwner) external;
    function replenish(address _token, uint256 _amount) external;
}

// File: contracts/IHEORewardFarm.sol


pragma solidity >=0.6.1;


interface IHEORewardFarm is IHEOBudget {
    function addDonation(address donor, uint256 amount, address token) external;
    function fullReward(uint256 amount, uint256 heoPrice, uint256 priceDecimals) external view returns(uint256);
}

// File: contracts/IHEOCampaignFactory.sol



pragma solidity >=0.6.1;

interface IHEOCampaignFactory {
    function createCampaign(uint256 maxAmount, address token,
        address payable beneficiary, string memory metaData) external;

    function createRewardCampaign(uint256 maxAmount, address token,
        address payable beneficiary, string memory metaData) external;
}

// File: contracts/IHEOCampaignRegistry.sol


pragma solidity >=0.6.1;


interface IHEOCampaignRegistry {
    function registerCampaign(address campaign) external;
    function getOwner(address campaign) external view returns (address);
}

// File: contracts/IHEOCampaign.sol



pragma solidity >=0.6.1;

interface IHEOCampaign {
    function maxAmount() external view returns (uint256);
    function isActive() external view returns (bool);
    function beneficiary() external view returns (address);
    function heoLocked() external view returns (uint256);
    function raisedAmount() external view returns (uint256);
    function currency() external view returns (address);
    function close() external;
    function updateMaxAmount(uint256 newMaxAmount) external;
    function metaData() external view returns (string memory);
    function updateMetaData(string memory newMetaData) external;
    function update(uint256 newMaxAmount, string memory newMetaData) external;
}

// File: contracts/IHEOPriceOracle.sol



pragma solidity >=0.6.1;

interface IHEOPriceOracle {
    function getPrice(address token) external view returns(uint256 price, uint256 decimals);
}

// File: @openzeppelin/[email protected]/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/[email protected]/utils/Address.sol



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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol



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

// File: @openzeppelin/[email protected]/math/SafeMath.sol



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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/[email protected]/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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

// File: @openzeppelin/[email protected]/GSN/Context.sol



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

// File: @openzeppelin/[email protected]/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/HEOParameters.sol


pragma solidity >=0.6.1;




/**
@dev Parameter management module
*/
contract HEOParameters is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /**
    @dev an integer parameter is a single-value parameter.
    Reserved int parameter set:
    0 - enable parameter voter white list
    1 - enable contract voter white list
    2 - enable budget voter white list
    3 - minimum vote duration
    4 - maximum vote duration
    5 - minimum passing vote
    6 - donation yield coefficient
    7 - fundraising fee
    */
    struct IntParameter {
        uint256 key;
        uint256 value;
    }

    //this map contains integer type parameters
    mapping (uint256 => IntParameter) _intParameters;

    /**
    @dev an address parameter can have multiple values
    Reserved addr parameter set:
    0 - parameter voter whitelist
    1 - contract voter whitelist
    2 - treasure voter whitelist
    3 - platform token address
    4 - voting token address
    5 - coins accepted for donations
    */
    struct AddrParameter {
        uint256 key;
        mapping (address => uint256) addrMap;
        address[] addresses;
    }

    // This map contains address type parameters
    mapping (uint256 => AddrParameter) public _addrParameters;

    // This map contains addresses of contracts
    mapping(uint256 => address) _contracts;

    /**
    Methods that manage contract addresses
    */
    function setContractAddress(uint256 key, address addr) public onlyOwner {
        _contracts[key] = addr;
    }
    /**
    Methods that manage integer parameter values
    */
    function setIntParameterValue(uint256 _key, uint256 _val) public onlyOwner {
        _intParameters[_key].value = _val;
    }

    function deleteIntParameter(uint256 _key) public onlyOwner {
        delete _intParameters[_key];
    }

    /**
    Methods that manage address parameter values
    */
    function setAddrParameterValue(uint256 _key, address _addr, uint256 _val) public onlyOwner {
        // _val = 0 is equivalent to deleting the address from the map
        if(_val == 0 && _addrParameters[_key].addrMap[_addr] != 0) {
            uint256 deleteIndex = 0;
            //delete value from array
            for(uint256 i = 0; i < _addrParameters[_key].addresses.length; i++) {
                if(_addrParameters[_key].addresses[i] == _addr) {
                    delete _addrParameters[_key].addresses[i];
                    deleteIndex = i;
                }
            }
            //shift values left
            for(uint256 i = deleteIndex; i < _addrParameters[_key].addresses.length - 1; i++) {
                _addrParameters[_key].addresses[i] = _addrParameters[_key].addresses[i+1];
            }
        }
        if(_val != 0 && _addrParameters[_key].addrMap[_addr] == 0) {
            _addrParameters[_key].addresses.push(_addr);
        }
        _addrParameters[_key].addrMap[_addr] = _val;
    }

    function deleteAddParameter(uint256 _key) public onlyOwner {
        delete _addrParameters[_key];
    }

    /**
    Public view methods
    */
    function calculateFee(uint256 amount) public view  returns(uint256) {
        return amount.mul(_intParameters[HEOLib.FUNDRAISING_FEE].value).div(_intParameters[HEOLib.FUNDRAISING_FEE_DECIMALS].value);
    }

    function addrParameterValue(uint256 _key, address _addr) public view returns(uint256) {
        return _addrParameters[_key].addrMap[_addr];
    }
    function intParameterValue(uint256 _key) public view returns(uint256) {
        return _intParameters[_key].value;
    }
    function addrParameterAddressAt(uint256 _key, uint256 _index) public view returns (address) {
        return _addrParameters[_key].addresses[_index];
    }
    function addrParameterLength(uint256 _key) public view returns (uint256) {
        return _addrParameters[_key].addresses.length;
    }

    function paramVoterWhiteListEnabled() public view returns(uint256) {
        return _intParameters[HEOLib.ENABLE_PARAM_VOTER_WHITELIST].value;
    }
    function contractVoterWhiteListEnabled() public view returns(uint256) {
        return _intParameters[HEOLib.ENABLE_CONTRACT_VOTER_WHITELIST].value;
    }
    function budgetVoterWhiteListEnabled() public view returns(uint256) {
        return _intParameters[HEOLib.ENABLE_BUDGET_VOTER_WHITELIST].value;
    }
    function platformTokenAddress() public view returns(address) {
        return _contracts[HEOLib.PLATFORM_TOKEN_ADDRESS];
    }
    function fundraisingFee() public view returns(uint256) {
        return _intParameters[HEOLib.FUNDRAISING_FEE].value;
    }
    function fundraisingFeeDecimals() public view returns(uint256) {
        return _intParameters[HEOLib.FUNDRAISING_FEE_DECIMALS].value;
    }
    function isTokenAccepted(address tokenAddress) public view returns(uint256) {
        return _addrParameters[HEOLib.ACCEPTED_COINS].addrMap[tokenAddress];
    }
    function contractAddress(uint256 index) public view returns(address) {
        return _contracts[index];
    }
}

// File: @openzeppelin/[email protected]/token/ERC20/ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/HEOToken.sol


pragma solidity >=0.6.1;



contract HEOToken is ERC20, Ownable {
	/*
	* Token distribution controls
	*/
	uint256 private _maxSupply; //Maximum allowed supply of HEO tokens

	constructor(uint256 supply, string memory name_, string memory symbol_) ERC20(name_, symbol_) public {
		_maxSupply = supply;
		_mint(msg.sender, _maxSupply);
	}

	/*
    * Returns maximum allowed supply.
    */
	function maxSupply() public view returns (uint256) {
		return _maxSupply;
	}

	/*
	* Override default Ownable::renounceOwnership to make sure
	* this contract does not get orphaned.
	*/
	function renounceOwnership() public override {
		revert("HEOToken: Cannot renounce ownership");
	}
}

// File: contracts/HEODAO.sol


pragma solidity >=0.6.1;














contract HEODAO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for HEOToken;
    using SafeERC20 for IERC20;

    HEOParameters private _heoParams;
    IHEOStaking private _heoStaking;

    function setParams(address params) external onlyOwner {
        _heoParams = HEOParameters(params);
        if(address(_heoStaking) != address(0)) {
            _heoStaking.setParams(params);
        }
    }
    function setStaking(address staking) external onlyOwner {
        if(address(_heoStaking) != address(0)) {
            _heoStaking.unstakeAll();
            Ownable(address(_heoStaking)).transferOwnership(_msgSender());
        }
        _heoStaking = IHEOStaking(staking);
        if(address(_heoParams) != address(0)) {
            _heoStaking.setParams(address(_heoParams));
        }
    }
    function initVoters(address[] calldata voters) external onlyOwner {
        // set initial integer parameters
        _heoParams.setIntParameterValue(HEOLib.ENABLE_PARAM_VOTER_WHITELIST, 1);
        _heoParams.setIntParameterValue(HEOLib.ENABLE_CONTRACT_VOTER_WHITELIST, 1);
        _heoParams.setIntParameterValue(HEOLib.ENABLE_BUDGET_VOTER_WHITELIST, 1);
        _heoParams.setIntParameterValue(HEOLib.MIN_VOTE_DURATION, 259200);
        _heoParams.setIntParameterValue(HEOLib.MAX_VOTE_DURATION, 7889231);
        _heoParams.setIntParameterValue(HEOLib.MIN_PASSING_VOTE, 51);
        _heoParams.setIntParameterValue(HEOLib.DONATION_YIELD, 1000000);
        _heoParams.setIntParameterValue(HEOLib.DONATION_YIELD_DECIMALS, 10000000000000000000);
        _heoParams.setIntParameterValue(HEOLib.FUNDRAISING_FEE, 250);
        _heoParams.setIntParameterValue(HEOLib.FUNDRAISING_FEE_DECIMALS, 10000);
        _heoParams.setIntParameterValue(HEOLib.DONATION_VESTING_SECONDS, 31536000);
        // add founders to parameter voter white list
        for(uint256 i = 0; i < voters.length; i++) {
            _heoParams.setAddrParameterValue(HEOLib.PARAM_WHITE_LIST, voters[i], 1);
            _heoParams.setAddrParameterValue(HEOLib.CONTRACT_WHITE_LIST, voters[i], 1);
            _heoParams.setAddrParameterValue(HEOLib.BUDGET_WHITE_LIST, voters[i], 1);
        }
    }

    /**
    @dev initial supply should be 100000000000000000000000000
    */
    function deployPlatformToken(uint256 _supply, string calldata _name, string calldata _symbol) external onlyOwner {
        require(_heoParams.contractAddress(HEOLib.PLATFORM_TOKEN_ADDRESS) == address(0), "Platform token is already deployed");
        HEOToken token = new HEOToken(_supply, _name, _symbol);
        _heoParams.setContractAddress(HEOLib.PLATFORM_TOKEN_ADDRESS, address(token));
        if(_heoParams.addrParameterLength(HEOLib.VOTING_TOKEN_ADDRESS) == 0) {
            _heoParams.setAddrParameterValue(HEOLib.VOTING_TOKEN_ADDRESS, address(token), 1);
            // send 1 token to each of the whitelisted founders, so they can vote
            if(_heoParams.intParameterValue(HEOLib.ENABLE_PARAM_VOTER_WHITELIST) > 0) {
                for(uint256 i = 0; i < _heoParams.addrParameterLength(HEOLib.PARAM_WHITE_LIST); i++) {
                    token.safeTransfer(_heoParams.addrParameterAddressAt(HEOLib.PARAM_WHITE_LIST, i), 1000000000000000000);
                }
            }
        }
    }

    /**
    @dev Public view methods
    */
    function heoParams() public view returns(HEOParameters) {
        return _heoParams;
    }

    bytes32[] private _activeProposals; // IDs of active proposals
    mapping(bytes32=>HEOLib.Proposal) private _proposals; // Map of proposals
    mapping(bytes32=>HEOLib.ProposalStatus) private _proposalStatus; // Map of proposal statuses for easy checking
    mapping(bytes32=>uint256) private _proposalStartTimes; // Map of proposal start times
    mapping(bytes32=>uint256) private _proposalDurations; // Map of proposal durations

    event ProposalCreated (
        bytes32 indexed proposalId,
        address indexed proposer
    );

    event ProposalVoteCast(
        bytes32 indexed proposalId,
        address indexed voter,
        uint256 vote,
        uint256 amount
    );

    event ProposalExecuted(
        bytes32 indexed proposalId
    );
    event ProposalRejected(
        bytes32 indexed proposalId
    );

    modifier onlyVoter() {
        require(owner() == _msgSender() || _heoStaking.isVoter(_msgSender()), "Caller is not a voter");
        _;
    }

    function allowedToVote(address _voter, HEOLib.ProposalType _propType) internal view returns (bool) {
        if(owner() != _voter) {
            uint256 whiteListIndex;
            if(_propType == HEOLib.ProposalType.INTVAL || _propType == HEOLib.ProposalType.ADDRVAL) {
                whiteListIndex = HEOLib.PARAM_WHITE_LIST;
            } else if(_propType == HEOLib.ProposalType.BUDGET) {
                whiteListIndex = HEOLib.BUDGET_WHITE_LIST;
            } else if(_propType == HEOLib.ProposalType.CONTRACT) {
                whiteListIndex = HEOLib.CONTRACT_WHITE_LIST;
            } else {
                return false;
            }
            if(_heoParams.intParameterValue(whiteListIndex) > 0) {
                return (_heoParams.addrParameterValue(whiteListIndex, _voter) > 0);
            }
        }
        return true;
    }

    modifier isVotingToken(address _token) {
        require(_heoParams.addrParameterValue(HEOLib.VOTING_TOKEN_ADDRESS, _token) > 0, "token not allowed for staking");
        _;
    }
    /**
    @dev Register the caller to vote by locking voting token in the DAO.
    This function can also be used to increase the stake.
    @param _amount - amount of voting token to lock
    @param _token - address of voting token
    */
    function registerToVote(uint256 _amount, address _token) external isVotingToken(_token) nonReentrant {
        address voter = _msgSender();
        _heoStaking.increaseStake(_amount, _token, voter);
    }

    /**
    @dev Remove caller from the voting list or reduce stake. Returns staked tokens.
    @param _amount - amount of voting token to return
    @param _token - address of staked token
    */
    function deregisterVoter(uint256 _amount, address _token) external isVotingToken(_token) nonReentrant {
        _reduceStake(_amount, _token, _msgSender());
    }

    function _reduceStake(uint256 _amount, address _token, address _voter) private {
        uint256 remainingAmount = _heoStaking.voterStake(_voter).sub(_amount);
        //check that this voter is not withdrawing a stake locked in active vote
        for(uint256 i = 0; i < _activeProposals.length; i++) {
            require(_proposals[_activeProposals[i]].stakes[_voter] <= remainingAmount,
                "cannot reduce stake below amount locked in an active vote");
        }
        _heoStaking.reduceStake(_amount, _token, _voter);
    }
    /**
    @dev This method allows external callers to propose to set, delete, rename, or create an interger parameter.
    @param _opType - proposed operation (set, delete, rename, create) as defined in ProposedOperation
    @param _key - key of the parameter in _intParameters map
    @param _addrs[] - array of proposed addresses.
        When voting for address-type parameters, each address in _addrs array should have a corresponding
        integer value in _values[] array.
        When voting for budget allocations, the first address should point to IHEOBudget instance,
        the second address to address of an ERC20 token unless allocating native coins (BNB, ETH, NEAR).
    @param _values[] - array of proposed values
        * when voting, voters select the value that they vote for.
        * to reject the proposal, voters vote for option 0
        * to vote for the 1st proposed value (_values[0]), voters vote for option 1.
        * in budget proposals, the first address
    @param _duration - how long the proposal can be active until it expires
    @param _percentToPass = percentage of votes required to pass the proposal. Cannot be less than 51%.
    */
    function proposeVote(HEOLib.ProposalType _propType, HEOLib.ProposedOperation _opType, uint256 _key,
        address[] calldata _addrs, uint256[] calldata _values, uint256 _duration, uint256 _percentToPass) external
        onlyVoter {
        if(_propType == HEOLib.ProposalType.INTVAL && _key <= HEOLib.ENABLE_BUDGET_VOTER_WHITELIST) {
            require(owner() == _msgSender(), "only owner can modify white lists");
        }
        if(_propType == HEOLib.ProposalType.ADDRVAL && _key <= HEOLib.BUDGET_WHITE_LIST) {
            require(owner() == _msgSender(), "only owner can modify white lists");
        }
        require(allowedToVote(_msgSender(), _propType), "caller is not in the voter whitelist");
        if(_heoParams.intParameterValue(HEOLib.MIN_VOTE_DURATION) > 0) {
            require(_duration >= _heoParams.intParameterValue(HEOLib.MIN_VOTE_DURATION), "_duration is too short");
        }
        if(_heoParams.intParameterValue(HEOLib.MAX_VOTE_DURATION) > 0) {
            require(_duration <= _heoParams.intParameterValue(HEOLib.MAX_VOTE_DURATION), "_duration is too long");
        }
        require(_percentToPass >= HEOLib.MIN_PASSING_VOTE, "_percentToPass is too low");
        if(_key == HEOLib.PLATFORM_TOKEN_ADDRESS && _propType == HEOLib.ProposalType.CONTRACT) {
            revert("Cannot change platform token address");
        }
        HEOLib.Proposal memory proposal;
        proposal.propType = _propType;
        proposal.opType = _opType;
        proposal.key = _key;
        proposal.values = _values;
        proposal.addrs = _addrs;
        proposal.proposer = _msgSender();
        proposal.percentToPass = _percentToPass;

        bytes32 proposalId = HEOLib._generateProposalId(proposal);
        //Check that identical proposal does not exist
        if(_proposalStartTimes[proposalId] > 0) {
            revert("the same proposal already exists in this block");
        }

        _proposals[proposalId] = proposal;
        _proposalStatus[proposalId] = HEOLib.ProposalStatus.OPEN;
        _proposalStartTimes[proposalId] = block.timestamp;
        _proposalDurations[proposalId] = _duration;
        _activeProposals.push(proposalId);
        emit ProposalCreated(proposalId, proposal.proposer);
    }

    /**
    @dev vote for a parameter value proposal
    @param _proposalId bytes32 ID of the proposal
    @param _vote value to vote for. Setting _vote to 0 is equivalent to rejecting the proposal
            Setting _vote to 1 is voting for the 1st value in the array of proposed values
    @param _weight - how much of staked amount to use for this vote
    */
    function vote(bytes32 _proposalId, uint256 _vote, uint256 _weight) external onlyVoter {
        require(_proposalStatus[_proposalId] == HEOLib.ProposalStatus.OPEN, "proposal is not open");
        require(_heoStaking.voterStake(_msgSender()) >= _weight, "_weight exceeds staked amount");
        HEOLib.Proposal storage proposal = _proposals[_proposalId];
        require((block.timestamp.sub(_proposalStartTimes[_proposalId])) <=  _proposalDurations[_proposalId],
            "proposal has expired");
        require(allowedToVote(_msgSender(), proposal.propType), "caller is not in the voter whitelist");
        require(_vote <= proposal.values.length, "vote out of range");
        address voter = _msgSender();
        if(proposal.stakes[voter] > 0) {
            //If this voter has already staked his votes, unstake them first
            uint256 lastStake = proposal.stakes[voter];
            proposal.totalWeight = proposal.totalWeight.sub(lastStake);
            proposal.totalVoters = proposal.totalVoters.sub(1);
            proposal.votes[_vote] = proposal.votes[_vote].sub(lastStake);
        }
        //stake the votes for the selected option
        proposal.stakes[voter] = _weight;
        proposal.votes[_vote] = proposal.votes[_vote].add(_weight);
        proposal.totalWeight = proposal.totalWeight.add(_weight);
        proposal.totalVoters = proposal.totalVoters.add(1);
        emit ProposalVoteCast(_proposalId, voter, _vote, _weight);
    }

    /**
    @dev A proposal can be executed once it's duration time passes or everyone has voted
    */
    function executeProposal(bytes32 _proposalId) external onlyVoter nonReentrant {
        require(_proposalStatus[_proposalId] == HEOLib.ProposalStatus.OPEN, "proposal is not open");
        HEOLib.Proposal storage proposal = _proposals[_proposalId];
        require(allowedToVote(_msgSender(), proposal.propType), "caller is not whitelisted");
        if(proposal.totalVoters < _heoStaking.numVoters()) {
            require((block.timestamp.sub(_proposalStartTimes[_proposalId])) >  _proposalDurations[_proposalId],
                "proposal has more time");
        }
        uint256 winnerOption;
        uint256 winnerWeight;
        bool tie = false;
        uint256 minWeight = (proposal.totalWeight.div(100)).mul(proposal.percentToPass);
        for(uint256 i = 0; i <= proposal.values.length; i++) {
            if(proposal.votes[i] >= minWeight) {
                if(proposal.votes[i] > winnerWeight) {
                    winnerWeight = proposal.votes[i];
                    winnerOption = i;
                    tie = false;
                } else if (proposal.votes[i] == winnerWeight) {
                    tie = true;
                }
            }
        }
        bool success = false;
        if(!tie) {
            if(winnerOption > 0 && winnerOption <= proposal.values.length) {
                //valid winner
                uint256 winnerIndex = winnerOption.sub(1);
                if(proposal.propType == HEOLib.ProposalType.ADDRVAL || proposal.propType == HEOLib.ProposalType.INTVAL) {
                    success = _executeParamProposal(proposal, winnerIndex);
                } else if(proposal.propType == HEOLib.ProposalType.BUDGET) {
                    success = _executeBudgetProposal(proposal, winnerIndex);
                } else if(proposal.propType == HEOLib.ProposalType.CONTRACT) {
                    if(proposal.key == HEOLib.REWARD_FARM && _heoParams.contractAddress(HEOLib.REWARD_FARM) != address(0)) {
                        //withdraw tokens from current reward farm first
                        IHEOBudget(_heoParams.contractAddress(HEOLib.REWARD_FARM)).withdraw(_heoParams.contractAddress(HEOLib.PLATFORM_TOKEN_ADDRESS));
                    }
                    _heoParams.setContractAddress(proposal.key, proposal.addrs[winnerIndex]);
                    success = true;
                }
            }
        }

        if(success) {
            _proposalStatus[_proposalId] = HEOLib.ProposalStatus.EXECUTED;
            emit ProposalExecuted(_proposalId);
        } else {
            _proposalStatus[_proposalId] = HEOLib.ProposalStatus.REJECTED;
            emit ProposalRejected(_proposalId);
        }
        //delete from _activeProposals and shift
        uint256 i;
        for(i = 0; i < _activeProposals.length; i++) {
            if(_activeProposals[i] == _proposalId) {
                delete(_activeProposals[i]);
                break;
            }
        }
        for(uint256 k = i; k < _activeProposals.length - 1; k++) {
            _activeProposals[k] = _activeProposals[k+1];
        }
        _activeProposals.pop();
    }

    function _executeParamProposal(HEOLib.Proposal storage proposal, uint256 winnerIndex) private returns(bool) {
        if(proposal.opType == HEOLib.ProposedOperation.OP_DELETE_PARAM) {
            if(proposal.propType == HEOLib.ProposalType.INTVAL) {
                _heoParams.deleteIntParameter(proposal.key);
                return true;
            } else if(proposal.propType == HEOLib.ProposalType.ADDRVAL) {
                _heoParams.deleteAddParameter(proposal.key);
                return true;
            }
        } else if(proposal.opType == HEOLib.ProposedOperation.OP_SET_VALUE) {
            if(proposal.propType == HEOLib.ProposalType.INTVAL) {
                _heoParams.setIntParameterValue(proposal.key, proposal.values[winnerIndex]);
                return true;
            } else if(proposal.propType == HEOLib.ProposalType.ADDRVAL) {
                if(proposal.key == HEOLib.VOTING_TOKEN_ADDRESS && proposal.values[winnerIndex] == 0) {
                    //To remove one of the voting tokens, we have to unstake everyone, who staked it
                    uint256 numVoters = _heoStaking.numStakedVotersByToken(proposal.addrs[winnerIndex]);
                    for(uint256 i = 0; i < numVoters; i++) {
                        address _voter = _heoStaking.stakedVoterByToken(proposal.addrs[winnerIndex], i);
                        if(_heoStaking.stakedTokensByVoter(_voter, proposal.addrs[winnerIndex]) > 0) {
                            _reduceStake(_heoStaking.stakedTokensByVoter(_voter,
                                proposal.addrs[winnerIndex]), proposal.addrs[winnerIndex], _voter);
                        }
                    }
                }
                _heoParams.setAddrParameterValue(proposal.key, proposal.addrs[winnerIndex], proposal.values[winnerIndex]);
                return true;
            }
        }
        return false;
    }

    function _executeBudgetProposal(HEOLib.Proposal storage proposal, uint256 winnerIndex) private returns(bool) {
        IHEOBudget budget = IHEOBudget(payable(proposal.addrs[0]));
        if(proposal.opType == HEOLib.ProposedOperation.OP_SEND_TOKEN) {
            budget.assignTreasurer(_heoParams.contractAddress(HEOLib.TREASURER));
            IERC20(proposal.addrs[1]).approve(proposal.addrs[0], proposal.values[winnerIndex]);
            budget.replenish(proposal.addrs[1], proposal.values[winnerIndex]);
            return true;
        } else if(proposal.opType == HEOLib.ProposedOperation.OP_SEND_NATIVE) {
            budget.assignTreasurer(_heoParams.contractAddress(HEOLib.TREASURER));
            payable(proposal.addrs[0]).transfer(proposal.values[winnerIndex]);
            return true;
        } else if(proposal.opType == HEOLib.ProposedOperation.OP_WITHDRAW_NATIVE) {
            budget.withdraw(address(0));
            return true;
        } else if(proposal.opType == HEOLib.ProposedOperation.OP_WITHDRAW_TOKEN) {
            budget.withdraw(proposal.addrs[1]);
            return true;
        }
        return false;
    }

    //Public views
     function stakedForProposal(bytes32 _proposalId, address _voter) public view returns(uint256) {
        return _proposals[_proposalId].stakes[_voter];
    }
    function activeProposals() public view returns(bytes32[] memory proposals) {
        return _activeProposals;
    }
    function minWeightToPass(bytes32 _proposalId) public view returns(uint256) {
        uint256 minWeight = (_proposals[_proposalId].totalWeight.div(100)).mul(_proposals[_proposalId].percentToPass);
        return minWeight;
    }
    function proposalStatus(bytes32 _proposalId) public view returns(uint8) {
        return uint8(_proposalStatus[_proposalId]);
    }
    function proposalTime(bytes32 _proposalId) public view returns(uint256) {
        return _proposalStartTimes[_proposalId];
    }
    function proposalDuration(bytes32 _proposalId) public view returns(uint256) {
        return  _proposalDurations[_proposalId];
    }
    function proposalType(bytes32 _proposalId) public view returns(uint8) {
        return uint8(_proposals[_proposalId].propType);
    }
    function voteWeight(bytes32 _proposalId, uint256 _vote) public view returns(uint256) {
        return _proposals[_proposalId].votes[_vote];
    }
    function getProposal(bytes32 _proposalId) public view
    returns(address proposer, uint8 opType, uint256[] memory values, address[] memory addrs, uint256 key, uint256 totalWeight,
        uint256 totalVoters, uint256 percentToPass) {
        HEOLib.Proposal storage proposal = _proposals[_proposalId];
        proposer = proposal.proposer;
        opType = uint8(proposal.opType);
        values = proposal.values;
        addrs = proposal.addrs;
        key = proposal.key;
        totalWeight = proposal.totalWeight;
        totalVoters = proposal.totalVoters;
        percentToPass = proposal.percentToPass;
    }
    receive() external payable {}
}

// File: @openzeppelin/[email protected]/math/Math.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/HEOGrant.sol


pragma solidity >=0.6.1;












contract HEOGrant is IHEOBudget, Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    struct Grant {
        bytes32 key;
        uint256 amount; //amount granted
        address token; //currency token
        address grantee; //address that will receive vested tokens
        uint256 vesting_start_ts; //vesting commencement timestamp
        uint256 termination_ts; //date when vesting stops. This is to be used to terminate a vesting contract
        uint256 claimed; //how much HEO have been claimed
        uint256 vestingSeconds; //duration of vesting in seconds
    }

    address payable private _owner;
    address public treasurer;
    uint256 public tge; //timestamp for TGE
    HEODAO _dao;

    mapping(address => uint256) public tokensClaimed; //how much have been claimed by token address
    mapping(address => uint256) public tokensGranted; //how much have been granted by token address
    mapping(bytes32 => Grant) private grants;
    mapping(address => bytes32[]) private _grantsByGrantee; //maps grantees to grants

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "HEOGrant: caller is not the owner");
        _;
    }


    modifier onlyTreasurer() {
        require(treasurer == _msgSender(), "HEOGrant: caller is not the treasurer");
        _;
    }

    constructor(HEODAO dao) public {
        require(address(dao) != address(0), "DAO cannot be a zero address");
        _dao = dao;
        emit OwnershipTransferred(address(0), address(dao));
        _owner = payable(address(dao));
    }

    function vestedAmount(bytes32 key, uint256 toDate) public view returns (uint256) {
        require(grants[key].amount > 0, "HEOGrant: this grant has zero amount");
        uint256 endDate = toDate;
        if(endDate == 0) {
            endDate = block.timestamp;
        }
        if(tge == 0 || endDate < tge) {
            return 0;
        }

        //before vesting starts - return 0
        if(grants[key].vesting_start_ts >= endDate) {
            return 0;
        }
        uint256 vestingStartTS = Math.max(tge, grants[key].vesting_start_ts);
        uint256 vestingEnd = grants[key].vestingSeconds.add(vestingStartTS);

        //check if vesting was terminated early
        if(grants[key].termination_ts > 0 && grants[key].termination_ts < vestingEnd) {
            vestingEnd = grants[key].termination_ts;
        }

        if(endDate > vestingEnd) {
            endDate = vestingEnd;
        }

        return grants[key].amount.mul(endDate.sub(vestingStartTS)).div(grants[key].vestingSeconds);
    }

    function grantAmount(bytes32 key) external view returns(uint256) {
        return grants[key].amount;
    }

    function grantToken(bytes32 key) external view returns(address) {
        return grants[key].token;
    }

    function grantVestingSeconds(bytes32 key) external view returns(uint256) {
        return grants[key].vestingSeconds;
    }
    function grantVestingStart(bytes32 key) external view returns(uint256) {
        if(tge == 0) {
            return 0;
        }
        return Math.max(tge, grants[key].vesting_start_ts);
    }
    function grantsByGrantee(address grantee) external view returns (bytes32[] memory) {
        return _grantsByGrantee[grantee];
    }

    function claimedFromGrant(bytes32 key) public view returns (uint256) {
        return grants[key].claimed;
    }

    function remainsInGrant(bytes32 key) public view returns (uint256) {
        return vestedAmount(key, block.timestamp).sub(grants[key].claimed);
    }

    function claim(address destination, bytes32 key, uint256 amount) public {
        Grant storage grant = grants[key];
        require(grant.grantee == _msgSender(), "HEOGrant: caller is not the grantee");
        uint256 unClaimed = vestedAmount(key, block.timestamp).sub(grant.claimed);
        require(unClaimed >= amount, "HEOGrant: claim exceeds vested equity");
        if(amount == 0) {
            //claim the remainder
            amount = unClaimed;
        }
        require(amount > 0, "HEOGrant: no vested equity to claim");
        grant.claimed = grant.claimed.add(amount); //update claimed amount in the grant
        tokensClaimed[grant.token] = tokensClaimed[grant.token].add(amount); //update total claimed amount
        ERC20(grant.token).safeTransfer(destination, amount);
    }

    /**
    * Treasurer's methods
    */
    function setTGE(uint256 _tge) external onlyTreasurer {
        tge = _tge;
    }

    function createGrant(address grantee, uint256 amount, uint256 commencementTs, uint256 vestingSeconds, address token) external onlyTreasurer {
        bytes32 key = keccak256(abi.encodePacked(_msgSender(), amount, block.timestamp));
        require(grants[key].amount == 0, "HEOGrant: grant already exists");

        Grant memory grant;
        grant.key = key;
        grant.claimed = 0;
        grant.amount = amount; //amount granted
        grant.token = token; //vesting token
        grant.grantee = grantee; //address that will receive vested tokens
        grant.vesting_start_ts = commencementTs; //vesting commencement timestamp
        grant.vestingSeconds = vestingSeconds; //duration of vesting in seconds
        grant.termination_ts = 0;

        grants[key] = grant;
        _grantsByGrantee[grantee].push(key);
        tokensGranted[token] = tokensGranted[token].add(amount);
    }

    function terminateGrant(bytes32 key, uint256 termination_ts) external onlyTreasurer {
        grants[key].termination_ts = termination_ts;
        //reduce total granted amount of tokens by how much tokens are being un-granted
        uint256 vestableAmount = vestedAmount(key, termination_ts);
        uint256 amountToTerminate = grants[key].amount.sub(vestableAmount);
        tokensGranted[grants[key].token] = tokensGranted[grants[key].token].sub(amountToTerminate);
        grants[key].termination_ts = termination_ts;
    }


    /**
    * HEOBudget methods
    */
    /**
    @dev withdraw funds back to DAO
    */
    function withdraw(address _token) external override onlyOwner {
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "token balance is zero");
        if(balance > 0) {
            token.safeTransfer(address(_dao), balance);
        }
    }

    function replenish(address _token, uint256 _amount) external override onlyOwner {
        ERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
    }

    function assignTreasurer(address _treasurer) external override onlyOwner {
        require(_treasurer != address(0), "HEOGrant: _treasurer cannot be zero address");
        treasurer = _treasurer;
    }

    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public override onlyOwner {
        require(newOwner != address(0), "owner cannot be a zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}